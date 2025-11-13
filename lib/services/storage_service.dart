import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar almacenamiento de archivos en Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Sube una foto de ticket y retorna la URL de descarga
  /// 
  /// [ticketId] - ID del ticket al que pertenece la foto
  /// [filePath] - Ruta local del archivo a subir
  /// [isResultPhoto] - Si es foto de resultado (true) o problema (false)
  Future<String?> uploadTicketPhoto({
    required String ticketId,
    required String filePath,
    bool isResultPhoto = false,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Archivo no existe: $filePath');
        }
        return null;
      }

      // Generar nombre único para el archivo
      final fileName = '${_uuid.v4()}.jpg';
      final folder = isResultPhoto ? 'resultado' : 'problema';
      final storageRef = _storage.ref().child('tickets/$ticketId/$folder/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de ticket a: tickets/$ticketId/$folder/$fileName');
      }

      // Subir archivo con timeout de 30 segundos
      final uploadTask = storageRef.putFile(file);
      
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

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de ticket: $e');
      }
      return null;
    }
  }

  /// Sube múltiples fotos de ticket y retorna lista de URLs
  /// 
  /// [ticketId] - ID del ticket al que pertenecen las fotos
  /// [filePaths] - Lista de rutas locales de archivos a subir
  /// [isResultPhotos] - Si son fotos de resultado (true) o problema (false)
  /// [onProgress] - Callback opcional para reportar progreso
  Future<List<String>> uploadTicketPhotos({
    required String ticketId,
    required List<String> filePaths,
    bool isResultPhotos = false,
    Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    
    if (kDebugMode) {
      debugPrint('📤 Subiendo ${filePaths.length} fotos de ticket...');
    }

    for (int i = 0; i < filePaths.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, filePaths.length);
      }

      final url = await uploadTicketPhoto(
        ticketId: ticketId,
        filePath: filePaths[i],
        isResultPhoto: isResultPhotos,
      );

      if (url != null) {
        urls.add(url);
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo subir foto ${i + 1}: ${filePaths[i]}');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ ${urls.length}/${filePaths.length} fotos subidas exitosamente');
    }

    return urls;
  }

  /// Sube una foto de acta de inventario y retorna la URL de descarga
  Future<String?> uploadInventoryActPhoto({
    required String actId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Archivo no existe: $filePath');
        }
        return null;
      }

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('inventory_acts/$actId/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de acta: inventory_acts/$actId/$fileName');
      }

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir foto después de 30 segundos');
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Foto subida exitosamente: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de acta: $e');
      }
      return null;
    }
  }

  /// Elimina una foto de Firebase Storage por su URL
  Future<bool> deletePhotoByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      
      if (kDebugMode) {
        debugPrint('✅ Foto eliminada: $url');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando foto: $e');
      }
      return false;
    }
  }

  /// Elimina todas las fotos de un ticket
  Future<bool> deleteTicketPhotos(String ticketId) async {
    try {
      final ref = _storage.ref().child('tickets/$ticketId');
      await ref.delete();
      
      if (kDebugMode) {
        debugPrint('✅ Fotos del ticket eliminadas: $ticketId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando fotos del ticket: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // PROPERTY LISTING PHOTO MANAGEMENT
  // ============================================================================

  /// Sube una foto de captación de inmueble
  /// 
  /// [listingId] - ID de la captación
  /// [filePath] - Ruta local del archivo a subir
  /// [photoType] - Tipo de foto: 'regular', '360', 'plan2d', 'plan3d'
  Future<String?> uploadPropertyListingPhoto({
    required String listingId,
    required String filePath,
    required String photoType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Archivo no existe: $filePath');
        }
        return null;
      }

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('property_listings/$listingId/$photoType/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de captación: property_listings/$listingId/$photoType/$fileName');
      }

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir foto después de 30 segundos');
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Foto de captación subida: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de captación: $e');
      }
      return null;
    }
  }

  /// Sube múltiples fotos de captación
  /// 
  /// [listingId] - ID de la captación
  /// [filePaths] - Lista de rutas de archivos
  /// [photoType] - Tipo de foto: 'regular', '360', 'plan2d', 'plan3d'
  /// [onProgress] - Callback para reportar progreso (current, total)
  Future<List<String>> uploadPropertyListingPhotos({
    required String listingId,
    required List<String> filePaths,
    required String photoType,
    Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    
    if (kDebugMode) {
      debugPrint('📤 Subiendo ${filePaths.length} fotos de captación ($photoType)...');
    }

    for (int i = 0; i < filePaths.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, filePaths.length);
      }

      final url = await uploadPropertyListingPhoto(
        listingId: listingId,
        filePath: filePaths[i],
        photoType: photoType,
      );

      if (url != null) {
        urls.add(url);
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo subir foto ${i + 1}: ${filePaths[i]}');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ ${urls.length}/${filePaths.length} fotos de captación subidas');
    }

    return urls;
  }

  /// Elimina todas las fotos de una captación
  Future<bool> deletePropertyListingPhotos(String listingId) async {
    try {
      final ref = _storage.ref().child('property_listings/$listingId');
      await ref.delete();
      
      if (kDebugMode) {
        debugPrint('✅ Fotos de captación eliminadas: $listingId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando fotos de captación: $e');
      }
      return false;
    }
  }
}
