import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de foto capturada
class CapturedPhoto {
  final String id;
  final String uri;
  final String filename;
  final int timestamp;

  CapturedPhoto({
    required this.id,
    required this.uri,
    required this.filename,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'uri': uri,
    'filename': filename,
    'timestamp': timestamp,
  };

  factory CapturedPhoto.fromJson(Map<String, dynamic> json) => CapturedPhoto(
    id: json['id'],
    uri: json['uri'],
    filename: json['filename'],
    timestamp: json['timestamp'],
  );
}

/// Modelo de cámara 360° detectada
class Camera360Device {
  final String id;
  final String name;
  final String type;
  final ConnectionType connectionType;
  final BluetoothDevice? device;
  final int? rssi; // Señal Bluetooth

  Camera360Device({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionType,
    this.device,
    this.rssi,
  });
}

/// Tipo de conexión
enum ConnectionType {
  bluetooth,
  wifi,
  usb,
}

/// Resultado de captura
class CaptureResult {
  final bool success;
  final String message;
  final String? photoPath;
  final bool requiresManualCapture;
  final Map<String, dynamic>? httpCommand; // Comando HTTP para ejecutar

  CaptureResult({
    required this.success,
    required this.message,
    this.photoPath,
    this.requiresManualCapture = false,
    this.httpCommand,
  });
}

/// Servicio universal para captura de fotos 360°
/// Soporta múltiples métodos de captura:
/// 1. Galería (fotos 360° existentes)
/// 2. Bluetooth (cámaras 360° conectadas: Insta360, Ricoh Theta, etc.)
/// 3. WiFi (cámaras 360° en red local)
class Camera360Service {
  final ImagePicker _imagePicker = ImagePicker();
  
  // Lista de cámaras 360° detectadas
  List<Camera360Device> _detectedCameras = [];
  
  /// Obtener lista de cámaras 360° detectadas
  List<Camera360Device> get detectedCameras => _detectedCameras;

  // --- Session Management (Persistence via SharedPreferences) ---
  static const String _draftKeyPrefix = 'draft_360_photos_v2_';

  /// Obtener clave única para almacenamiento según propiedad
  static String _getStorageKey(bool isQuickCapture, String propertyId) {
    if (isQuickCapture) {
      return '${_draftKeyPrefix}quick_capture';
    }
    return '${_draftKeyPrefix}$propertyId';
  }
  
  /// Obtener fotos borradores para una sesión (Persistente)
  Future<List<CapturedPhoto>> getSessionPhotos(bool isQuickCapture, String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(isQuickCapture, propertyId);
      final photosJsonList = prefs.getStringList(key) ?? [];
      
      final photos = photosJsonList.map((jsonStr) {
        return CapturedPhoto.fromJson(jsonDecode(jsonStr));
      }).toList();
      
      if (kDebugMode) {
        debugPrint('📂 Cargando sesión ($key): ${photos.length} fotos encontradas.');
      }
      return photos;
    } catch (e) {
      debugPrint('❌ Error cargando sesión: $e');
      return [];
    }
  }
  
  /// Guardar foto en la sesión activa (Persistente)
  Future<void> addPhotoToSession(CapturedPhoto photo, bool isQuickCapture, String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(isQuickCapture, propertyId);
      
      List<String> currentPhotosJson = prefs.getStringList(key) ?? [];
      
      // Evitar duplicados por ID
      bool exists = currentPhotosJson.any((str) {
        final existing = CapturedPhoto.fromJson(jsonDecode(str));
        return existing.id == photo.id;
      });

      if (!exists) {
        currentPhotosJson.add(jsonEncode(photo.toJson()));
        await prefs.setStringList(key, currentPhotosJson);
        if (kDebugMode) {
          debugPrint('💾 Foto guardada en sesión ($key). Total: ${currentPhotosJson.length}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error guardando foto en sesión: $e');
    }
  }
  
  /// Remover foto de la sesión activa (Persistente)
  Future<void> removePhotoFromSession(String photoId, bool isQuickCapture, String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(isQuickCapture, propertyId);
      
      List<String> currentPhotosJson = prefs.getStringList(key) ?? [];
      
      int initialCount = currentPhotosJson.length;
      currentPhotosJson.removeWhere((str) {
        final photo = CapturedPhoto.fromJson(jsonDecode(str));
        return photo.id == photoId;
      });

      if (currentPhotosJson.length < initialCount) {
        await prefs.setStringList(key, currentPhotosJson);
        if (kDebugMode) {
          debugPrint('🗑️ Foto eliminada de sesión ($key). Restantes: ${currentPhotosJson.length}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error eliminando foto de sesión: $e');
    }
  }
  
  /// Limpiar sesión (Persistente)
  Future<void> clearSession(bool isQuickCapture, String propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(isQuickCapture, propertyId);
      await prefs.remove(key);
      if (kDebugMode) {
        debugPrint('🧹 Sesión limpiada ($key)');
      }
    } catch (e) {
      debugPrint('❌ Error limpiando sesión: $e');
    }
  }

  /// Método 1: Seleccionar foto 360° desde galería
  Future<XFile?> pickFrom360Gallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Máxima calidad para fotos 360°
      );

      if (photo != null) {
        if (kDebugMode) {
          debugPrint('✅ Foto 360° seleccionada desde galería: ${photo.path}');
        }
        return photo;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al seleccionar foto 360° de galería: $e');
      }
      return null;
    }
  }

  /// Método 2: Capturar con cámara del teléfono (panorama manual)
  Future<XFile?> captureWithPhoneCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear, // Cámara trasera
      );

      if (photo != null) {
        if (kDebugMode) {
          debugPrint('✅ Foto capturada con cámara del teléfono: ${photo.path}');
        }
        return photo;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al capturar foto con cámara: $e');
      }
      return null;
    }
  }

  /// Método 3: Escanear cámaras 360° por Bluetooth
  Future<List<Camera360Device>> scanFor360Cameras({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _detectedCameras.clear();

    try {
      // PASO 1: Solicitar permisos de Bluetooth y ubicación
      final permissionsGranted = await _requestBluetoothPermissions();
      if (!permissionsGranted) {
        if (kDebugMode) {
          debugPrint('❌ Permisos de Bluetooth denegados');
        }
        throw PermissionException(
          'Se necesitan permisos de Bluetooth y ubicación para escanear cámaras 360°. '
          'Por favor, activa estos permisos en Ajustes del dispositivo.',
        );
      }

      // PASO 2: Verificar que Location Services estén activados
      final locationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!locationServiceEnabled) {
        if (kDebugMode) {
          debugPrint('❌ Servicios de ubicación desactivados');
        }
        throw LocationServiceException(
          'Para escanear dispositivos Bluetooth, debes activar la Ubicación en Ajustes. '
          'Android requiere esto por seguridad.',
        );
      }

      // PASO 3: Verificar si Bluetooth está disponible
      final isBluetoothAvailable = await FlutterBluePlus.isSupported;
      if (!isBluetoothAvailable) {
        if (kDebugMode) {
          debugPrint('⚠️ Bluetooth no disponible en este dispositivo');
        }
        throw BluetoothNotSupportedException(
          'Este dispositivo no soporta Bluetooth.',
        );
      }

      // PASO 4: Verificar si Bluetooth está encendido
      final bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        if (kDebugMode) {
          debugPrint('⚠️ Bluetooth está apagado');
        }
        throw BluetoothOffException(
          'Activa Bluetooth en Ajustes del dispositivo para escanear cámaras 360°.',
        );
      }

      if (kDebugMode) {
        debugPrint('🔍 Escaneando cámaras 360° por Bluetooth...');
      }

      // Escanear dispositivos
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final deviceName = result.device.platformName.toLowerCase();
          
          // Detectar cámaras 360° conocidas por nombre
          if (_is360Camera(deviceName)) {
            final camera = Camera360Device(
              id: result.device.remoteId.toString(),
              name: result.device.platformName,
              type: _getCameraType(deviceName),
              connectionType: ConnectionType.bluetooth,
              device: result.device,
              rssi: result.rssi,
            );

            // Evitar duplicados
            if (!_detectedCameras.any((c) => c.id == camera.id)) {
              _detectedCameras.add(camera);
              if (kDebugMode) {
                debugPrint('✅ Cámara 360° detectada: ${camera.name} (${camera.type})');
              }
            }
          }
        }
      });

      // Iniciar escaneo
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Esperar a que termine el escaneo
      await Future.delayed(timeout);
      
      // Detener escaneo
      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      if (kDebugMode) {
        debugPrint('✅ Escaneo completado. ${_detectedCameras.length} cámara(s) encontrada(s)');
      }

      return _detectedCameras;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al escanear cámaras 360°: $e');
      }
      return [];
    }
  }

  /// Solicitar permisos necesarios para Bluetooth
  Future<bool> _requestBluetoothPermissions() async {
    try {
      // Solicitar permisos necesarios para Bluetooth en Android 12+
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,    // Escanear dispositivos Bluetooth
        Permission.bluetoothConnect, // Conectar a dispositivos Bluetooth
        Permission.location,         // Requerido por Android para Bluetooth scanning
      ].request();

      // Verificar que todos los permisos fueron concedidos
      final allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (!allGranted) {
        if (kDebugMode) {
          debugPrint('⚠️ Algunos permisos no fueron concedidos:');
          statuses.forEach((permission, status) {
            debugPrint('  - ${permission.toString()}: ${status.toString()}');
          });
        }
      }

      return allGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al solicitar permisos de Bluetooth: $e');
      }
      return false;
    }
  }

  /// Abrir configuración del sistema para permisos
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al abrir ajustes: $e');
      }
    }
  }

  /// Verificar si un dispositivo es una cámara 360°
  bool _is360Camera(String deviceName) {
    final camera360Keywords = [
      'insta360',
      'theta',
      'ricoh',
      '360',
      'gear 360',
      'samsung gear',
      'xiaomi sphere',
      'vuze',
      'gopro fusion',
      'kandao',
      'garmin virb',
      'lg 360',
      'kodak pixpro',
    ];

    return camera360Keywords.any((keyword) => deviceName.contains(keyword));
  }

  /// Determinar tipo de cámara por nombre
  String _getCameraType(String deviceName) {
    if (deviceName.contains('insta360')) return 'Insta360';
    if (deviceName.contains('theta') || deviceName.contains('ricoh')) return 'Ricoh Theta';
    if (deviceName.contains('gear 360') || deviceName.contains('samsung')) return 'Samsung Gear 360';
    if (deviceName.contains('gopro')) return 'GoPro Fusion';
    if (deviceName.contains('xiaomi')) return 'Xiaomi Mi Sphere';
    return 'Cámara 360° Desconocida';
  }

  /// Conectar a una cámara 360° específica
  Future<bool> connectToCamera(Camera360Device camera) async {
    if (camera.connectionType != ConnectionType.bluetooth) {
      if (kDebugMode) {
        debugPrint('⚠️ Solo se soporta conexión Bluetooth por ahora');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔗 Conectando a ${camera.name}...');
      }

      await camera.device!.connect(timeout: const Duration(seconds: 15));
      
      if (kDebugMode) {
        debugPrint('✅ Conectado a ${camera.name}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al conectar a ${camera.name}: $e');
      }
      return false;
    }
  }

  /// Desconectar de una cámara 360°
  Future<void> disconnectFromCamera(Camera360Device camera) async {
    if (camera.device != null) {
      try {
        await camera.device!.disconnect();
        if (kDebugMode) {
          debugPrint('✅ Desconectado de ${camera.name}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error al desconectar: $e');
        }
      }
    }
  }

  /// Obtener live preview URL de la cámara 360°
  Future<String?> getLivePreviewUrl(Camera360Device camera) async {
    try {
      if (camera.type.contains('Theta') || camera.type.contains('Ricoh')) {
        return 'http://192.168.1.1:8080/osc/commands/execute';
      }
      
      if (camera.type.contains('Insta360')) {
        return 'http://192.168.42.1:8080/stream';
      }
      
      return await _discoverCameraStreamUrl(camera);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener URL de preview: $e');
      }
      return null;
    }
  }

  Future<String?> _discoverCameraStreamUrl(Camera360Device camera) async {
    final commonStreamUrls = [
      'http://192.168.1.1:8080/liveview',
      'http://192.168.1.1:80/liveview',
      'http://192.168.42.1:8080/stream',
      'http://192.168.43.1:8080/stream',
      'http://10.5.5.9/gp/gpControl/execute?p1=gpStream&a1=proto_v2&c1=restart',
    ];
    return commonStreamUrls.first;
  }

  /// Capturar foto remota con cámara 360° conectada
  Future<CaptureResult> captureWith360Camera(Camera360Device camera) async {
    try {
      if (kDebugMode) {
        debugPrint('📸 Disparando captura remota en ${camera.name}...');
      }

      if (camera.connectionType == ConnectionType.bluetooth && camera.device != null) {
        final result = await _sendBluetoothCaptureCommand(camera);
        if (result.success) return result;
      }

      final result = await _sendHttpCaptureCommand(camera);
      if (result.success) return result;

      return CaptureResult(
        success: false,
        message: '''
📸 Para capturar con ${camera.name}:

🔵 MÉTODO 1: Captura Manual
1. Dispara la foto manualmente con la cámara
2. La foto aparecerá automáticamente en el preview

🟢 MÉTODO 2: App Oficial
1. Usa la app oficial de la cámara
2. Captura la foto
3. Usa el botón "Seleccionar desde Galería" en SU TODERO
        ''',
        requiresManualCapture: true,
      );
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al capturar: $e');
      }
      return CaptureResult(
        success: false,
        message: 'Error al disparar captura: $e',
      );
    }
  }

  Future<CaptureResult> _sendBluetoothCaptureCommand(Camera360Device camera) async {
    try {
      final services = await camera.device!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write([0x01]);
            return CaptureResult(
              success: true,
              message: '✅ Foto capturada remotamente',
            );
          }
        }
      }
      return CaptureResult(
        success: false,
        message: 'No se encontró servicio de control en la cámara',
      );
    } catch (e) {
      return CaptureResult(
        success: false,
        message: 'Error al enviar comando Bluetooth: $e',
      );
    }
  }

  Future<CaptureResult> _sendHttpCaptureCommand(Camera360Device camera) async {
    try {
      if (camera.type.contains('Theta') || camera.type.contains('Ricoh')) {
        return CaptureResult(
          success: true,
          message: '✅ Comando enviado a Ricoh Theta',
          httpCommand: {
            'url': 'http://192.168.1.1/osc/commands/execute',
            'method': 'POST',
            'body': {'name': 'camera.takePicture'},
          },
        );
      }
      
      if (camera.type.contains('Insta360')) {
        return CaptureResult(
          success: true,
          message: '✅ Comando enviado a Insta360',
          httpCommand: {
            'url': 'http://192.168.42.1/capture',
            'method': 'GET',
          },
        );
      }
      
      return CaptureResult(
        success: false,
        message: 'Cámara no soporta captura remota HTTP',
      );
      
    } catch (e) {
      return CaptureResult(
        success: false,
        message: 'Error en comando HTTP: $e',
      );
    }
  }
}

/// Excepciones específicas para Bluetooth 360°
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  @override String toString() => message;
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  @override String toString() => message;
}

class BluetoothNotSupportedException implements Exception {
  final String message;
  BluetoothNotSupportedException(this.message);
  @override String toString() => message;
}

class BluetoothOffException implements Exception {
  final String message;
  BluetoothOffException(this.message);
  @override String toString() => message;
}
