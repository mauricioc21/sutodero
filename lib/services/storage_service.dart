import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

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
      // Comprimir imagen antes de subir
      final compressedFile = await _compressImage(filePath);
      if (compressedFile == null || !await compressedFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error al comprimir/encontrar archivo: $filePath');
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

      // Subir archivo comprimido con timeout de 30 segundos
      final uploadTask = storageRef.putFile(compressedFile);
      
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

      // Limpiar archivo temporal
      try {
        await compressedFile.delete();
      } catch (_) {}

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
  /// Comprime automáticamente para optimizar rendimiento
  Future<String?> uploadInventoryActPhoto({
    required String actId,
    required String filePath,
  }) async {
    try {
      // Comprimir imagen antes de subir
      final compressedFile = await _compressImage(filePath);
      if (compressedFile == null || !await compressedFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error al comprimir/encontrar archivo: $filePath');
        }
        return null;
      }

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('inventory_acts/$actId/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de acta: inventory_acts/$actId/$fileName');
      }

      final uploadTask = storageRef.putFile(compressedFile);
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

      // Limpiar archivo temporal
      try {
        await compressedFile.delete();
      } catch (_) {}

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
  /// Comprime automáticamente (menos compresión para fotos 360°)
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
      // Comprimir imagen (menos compresión para fotos 360°)
      final is360 = photoType == '360';
      final compressedFile = await _compressImage(filePath, is360Photo: is360);
      if (compressedFile == null || !await compressedFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error al comprimir/encontrar archivo: $filePath');
        }
        return null;
      }

      final fileName = '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('property_listings/$listingId/$photoType/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de captación: property_listings/$listingId/$photoType/$fileName');
      }

      final uploadTask = storageRef.putFile(compressedFile);
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

      // Limpiar archivo temporal
      try {
        await compressedFile.delete();
      } catch (_) {}

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

  // ============================================================================
  // INVENTORY ROOM PHOTO MANAGEMENT
  // ============================================================================

  /// Sube una foto de un espacio/habitación del inventario
  /// Comprime automáticamente (menos compresión para fotos 360°)
  /// 
  /// [userId] - ID del usuario propietario
  /// [propertyId] - ID de la propiedad
  /// [roomId] - ID del espacio/habitación
  /// [filePath] - Ruta local del archivo a subir
  /// [is360] - true si es foto 360° (menos compresión, mayor calidad)
  Future<String?> uploadRoomPhoto({
    required String userId,
    required String propertyId,
    required String roomId,
    required String filePath,
    bool is360 = false,
  }) async {
    try {
      // Comprimir imagen (menos compresión para fotos 360°)
      final compressedFile = await _compressImage(filePath, is360Photo: is360);
      if (compressedFile == null || !await compressedFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error al comprimir/encontrar archivo: $filePath');
        }
        return null;
      }

      // Generar nombre único o fijo para 360°
      final fileName = is360 ? 'panorama_360.jpg' : '${_uuid.v4()}.jpg';
      final folder = is360 ? '360' : 'photos';
      final storageRef = _storage.ref().child(
        'users/$userId/properties/$propertyId/rooms/$roomId/$folder/$fileName'
      );

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de espacio${is360 ? ' 360°' : ''}: users/$userId/properties/$propertyId/rooms/$roomId/$folder/$fileName');
      }

      // Subir archivo comprimido con timeout de 30 segundos
      final uploadTask = storageRef.putFile(compressedFile);
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir foto después de 30 segundos');
        },
      );

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Foto de espacio${is360 ? ' 360°' : ''} subida exitosamente: $downloadUrl');
      }

      // Limpiar archivo temporal
      try {
        await compressedFile.delete();
      } catch (_) {}

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de espacio: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // FLOOR PLAN MANAGEMENT
  // ============================================================================

  /// Sube un plano (2D o 3D) de una propiedad
  /// 
  /// [userId] - ID del usuario propietario
  /// [propertyId] - ID de la propiedad
  /// [filePath] - Ruta local del archivo PDF a subir
  /// [planType] - Tipo de plano: '2d' o '3d'
  Future<String?> uploadFloorPlan({
    required String userId,
    required String propertyId,
    required String filePath,
    required String planType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error: Archivo no encontrado: $filePath');
        }
        return null;
      }

      // Usar nombre fijo para sobreescribir plano anterior
      final fileName = 'plano_$planType.pdf';
      final storageRef = _storage.ref().child(
        'users/$userId/properties/$propertyId/planos/$fileName'
      );

      if (kDebugMode) {
        debugPrint('📤 Subiendo plano $planType: users/$userId/properties/$propertyId/planos/$fileName');
      }

      // Subir archivo con timeout de 30 segundos
      final uploadTask = storageRef.putFile(file);
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir plano después de 30 segundos');
        },
      );

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Plano $planType subido exitosamente: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo plano $planType: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // USER PROFILE PHOTO MANAGEMENT
  // ============================================================================

  /// Sube una foto de perfil de usuario
  /// Comprime automáticamente la imagen antes de subir
  /// 
  /// [userId] - ID del usuario
  /// [filePath] - Ruta local del archivo a subir
  Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      // Comprimir imagen antes de subir (calidad normal)
      final compressedFile = await _compressImage(filePath);
      if (compressedFile == null || !await compressedFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Error al comprimir/encontrar archivo: $filePath');
        }
        return null;
      }

      // Usar nombre fijo para sobreescribir foto anterior
      final fileName = 'profile.jpg';
      final storageRef = _storage.ref().child('users/$userId/profile/$fileName');

      if (kDebugMode) {
        debugPrint('📤 Subiendo foto de perfil: users/$userId/profile/$fileName');
      }

      // Subir archivo comprimido con timeout de 30 segundos
      final uploadTask = storageRef.putFile(compressedFile);
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al subir foto después de 30 segundos');
        },
      );

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Foto de perfil subida exitosamente: $downloadUrl');
      }

      // Limpiar archivo temporal
      try {
        await compressedFile.delete();
      } catch (_) {}

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo foto de perfil: $e');
      }
      return null;
    }
  }
}
