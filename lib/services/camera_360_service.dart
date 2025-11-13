import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

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

  /// Método 1: Seleccionar foto 360° desde galería
  /// Este es el método más simple y funciona inmediatamente
  Future<String?> pickFrom360Gallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Máxima calidad para fotos 360°
      );

      if (photo != null) {
        if (kDebugMode) {
          debugPrint('✅ Foto 360° seleccionada desde galería: ${photo.path}');
        }
        return photo.path;
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
  /// Útil si no hay cámara 360° disponible
  Future<String?> captureWithPhoneCamera() async {
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
        return photo.path;
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
  /// Detecta automáticamente cámaras como Insta360, Ricoh Theta, etc.
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

  /// Capturar foto con cámara 360° conectada
  /// NOTA: Requiere implementación específica para cada modelo de cámara
  /// Por ahora, devuelve instrucciones para captura manual
  Future<CaptureResult> captureWith360Camera(Camera360Device camera) async {
    // En una implementación real, aquí se enviarían comandos BLE específicos
    // a la cámara para disparar la captura
    
    return CaptureResult(
      success: false,
      message: '''
📸 Para capturar con ${camera.name}:

1. Usa la app oficial de la cámara para capturar
2. Transfiere la foto a tu teléfono
3. Usa el botón "Seleccionar desde Galería" en SU TODERO

💡 O usa el botón "Capturar con Cámara del Teléfono" para una foto panorámica.
      ''',
      requiresManualCapture: true,
    );
  }
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

  CaptureResult({
    required this.success,
    required this.message,
    this.photoPath,
    this.requiresManualCapture = false,
  });
}

/// Excepciones específicas para Bluetooth 360°

/// Error de permisos denegados
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => message;
}

/// Error de servicios de ubicación desactivados
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  
  @override
  String toString() => message;
}

/// Error de Bluetooth no soportado
class BluetoothNotSupportedException implements Exception {
  final String message;
  BluetoothNotSupportedException(this.message);
  
  @override
  String toString() => message;
}

/// Error de Bluetooth apagado
class BluetoothOffException implements Exception {
  final String message;
  BluetoothOffException(this.message);
  
  @override
  String toString() => message;
}
