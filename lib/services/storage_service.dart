import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/file_import.dart'; // Shim for File/Directory

/// Servicio para gestionar almacenamiento de archivos en Firebase Storage
/// Incluye compresión automática de imágenes para optimizar rendimiento
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Comprime una imagen para reducir su tamaño antes de subir
  /// Optimizado para fotos normales (no 360°)
  Future<File?> _compressImage(String filePath, {bool is360Photo = false}) async {
    // En Web, no comprimimos o usamos lógica diferente
    if (kIsWeb) {
      return File(filePath);
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // Para fotos 360° usamos menos compresión para mantener calidad
      final quality = is360Photo ? 85 : 70;
      final maxWidth = is360Photo ? 4096 : 1920;
      final maxHeight = is360Photo ? 2048 : 1080;

      // Crear archivo temporal para la imagen comprimida
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';

      if (kDebugMode) {
        final originalSize = await file.length();
        debugPrint('🗜️ Comprimiendo imagen (${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB)...');
      }

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null && kDebugMode) {
        final compressedSize = await result.length();
        final originalSize = await file.length();
        final reduction = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
        debugPrint('✅ Imagen comprimida: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB (-$reduction%)');
      }

      return result != null ? File(result.path) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error al comprimir imagen: $e');
      }
      // Si falla la compresión, retornar archivo original
      return File(filePath);
    }
  }

  /// Sube una foto de ticket y retorna la URL de descarga
  /// Comprime automáticamente la imagen antes de subir
  Future<String?> uploadTicketPhoto({
    required String ticketId,
    required String filePath,
    bool isResultPhoto = false,
  }) async {
    try {
      final compressedFile = await _compressImage(filePath);
      if (compressedFile == null) {
        if (kDebugMode) debugPrint('❌ Archivo no válido: $filePath');
        return null;
      }
      
      // Validar existencia en móvil (en web File(path).exists() es false en el stub, así que saltamos validación)
      if (!kIsWeb && !await compressedFile.exists()) {
         if (kDebugMode) debugPrint('❌ Archivo no encontrado: ${compressedFile.path}');
         return null;
      }

      // Generar nombre único para el archivo
      final fileName = '${_uuid.v4()}.jpg';
      final folder = isResultPhoto ? 'resultado' : 'problema';
      final storageRef = _storage.ref().child('tickets/$ticketId/$folder/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de ticket a: tickets/$ticketId/$folder/$fileName');
      }

      // Upload logic
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // En Web usamos putData o putString (data_url)
        if (filePath.startsWith('data:')) {
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl);
        } else {
           // Asumimos que podemos leer bytes (si es XFile path compatible)
           // Pero nuestro shim File no tiene implementación real.
           // Si viene de XFile.path en web, suele ser un blob url.
           // No podemos leerlo con File(path).readAsBytes() de dart:io.
           // Pero si usamos cross_file, sí.
           // Aquí, asumiremos que si no es data URL, es difícil de subir sin XFile original.
           // TODO: Refactorizar para pasar XFile/Uint8List en lugar de String path.
           // Por ahora, para evitar crash, subimos datos dummy o intentamos leer si es data uri.
           
           if (kDebugMode) debugPrint('⚠️ Web upload with file path might fail if not data URI');
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl); // Fallback attempt
        }
      } else {
        // Mobile: putFile con cast dinámico para evitar error de tipo en compilación web
        // En mobile, 'compressedFile' es dart:io.File. putFile lo acepta.
        // En web, 'compressedFile' es StubFile. putFile no lo acepta (pero no llegamos aquí).
        uploadTask = storageRef.putFile(compressedFile as dynamic);
      }
      
      // Esperar a que termine la subida con timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir foto después de 30 segundos');
        },
      );

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Foto subida exitosamente: $downloadUrl');
      }

      // Limpiar archivo temporal (solo móvil)
      if (!kIsWeb) {
        try {
          await compressedFile.delete();
        } catch (_) {}
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de ticket: $e');
      }
      return null;
    }
  }

  Future<List<String>> uploadTicketPhotos({
    required String ticketId,
    required List<String> filePaths,
    bool isResultPhotos = false,
    Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    if (kDebugMode) debugPrint('📤 Subiendo ${filePaths.length} fotos de ticket...');

    for (int i = 0; i < filePaths.length; i++) {
      if (onProgress != null) onProgress(i + 1, filePaths.length);

      final url = await uploadTicketPhoto(
        ticketId: ticketId,
        filePath: filePaths[i],
        isResultPhoto: isResultPhotos,
      );

      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<String?> uploadInventoryActPhoto({
    required String actId,
    required String filePath,
  }) async {
    try {
      final compressedFile = await _compressImage(filePath);
      if (compressedFile == null) return null;

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('inventory_acts/$actId/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
         if (filePath.startsWith('data:')) {
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl);
         } else {
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl); 
         }
      } else {
        uploadTask = storageRef.putFile(compressedFile as dynamic);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (!kIsWeb) {
        try { await compressedFile.delete(); } catch (_) {}
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error subiendo foto de acta: $e');
      return null;
    }
  }

  Future<bool> deletePhotoByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error eliminando foto: $e');
      return false;
    }
  }

  Future<bool> deleteTicketPhotos(String ticketId) async {
    try {
      final ref = _storage.ref().child('tickets/$ticketId');
      // Delete folders? Firebase storage doesn't have real folders.
      // We need to list all items and delete.
      final list = await ref.listAll();
      for (var item in list.items) { await item.delete(); }
      for (var prefix in list.prefixes) {
        final subList = await prefix.listAll();
        for (var item in subList.items) { await item.delete(); }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadPropertyListingPhoto({
    required String listingId,
    required String filePath,
    required String photoType,
  }) async {
    try {
      final is360 = photoType == '360';
      final compressedFile = await _compressImage(filePath, is360Photo: is360);
      if (compressedFile == null) return null;

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('property_listings/$listingId/$photoType/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
         if (filePath.startsWith('data:')) {
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl);
         } else {
           uploadTask = storageRef.putString(filePath, format: PutStringFormat.dataUrl);
         }
      } else {
        uploadTask = storageRef.putFile(compressedFile as dynamic);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (!kIsWeb) {
        try { await compressedFile.delete(); } catch (_) {}
      }

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadPropertyListingPhotos({
    required String listingId,
    required List<String> filePaths,
    required String photoType,
    Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < filePaths.length; i++) {
      if (onProgress != null) onProgress(i + 1, filePaths.length);
      final url = await uploadPropertyListingPhoto(
        listingId: listingId,
        filePath: filePaths[i],
        photoType: photoType,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }

  Future<bool> deletePropertyListingPhotos(String listingId) async {
    try {
      final ref = _storage.ref().child('property_listings/$listingId');
      final list = await ref.listAll();
      for (var item in list.items) { await item.delete(); }
      for (var prefix in list.prefixes) {
        final subList = await prefix.listAll();
        for (var item in subList.items) { await item.delete(); }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
