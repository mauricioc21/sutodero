# 📷 Integración de Cámaras Insta360 con Flutter

## 🎯 Objetivo
Integrar cámaras de la serie Insta360 (Insta360 X3, X4, ONE RS, etc.) con la aplicación SU TODERO para capturar fotos 360° directamente desde la app.

---

## 🔍 Investigación de SDKs

### **1. SDK Oficial de Insta360**

#### **Disponibilidad**:
- **Android SDK**: ✅ Disponible (nativo Java/Kotlin)
- **iOS SDK**: ✅ Disponible (nativo Swift/Objective-C)
- **Flutter SDK**: ❌ No disponible oficialmente

#### **Proceso de Aplicación**:
1. Visitar: https://www.insta360.com/developer/home
2. Completar formulario de aplicación del SDK
3. Especificar modelo de cámara (X3, X4, ONE RS, etc.)
4. Esperar aprobación (puede tomar varios días)
5. Descargar SDK una vez aprobado

#### **Funcionalidades del SDK Oficial**:
- ✅ Control de cámara vía Bluetooth o WiFi
- ✅ Ajuste de configuración de cámara
- ✅ Captura de fotos y videos 360°
- ✅ Descarga de medios desde la cámara
- ✅ Previsualización en tiempo real
- ⚠️ Solo USB en desktop; Bluetooth y WiFi en Android/iOS

---

### **2. Conexión Bluetooth/WiFi**

#### **Paquetes Flutter Disponibles**:

**flutter_blue_plus** (✅ Ya instalado en el proyecto):
```yaml
flutter_blue_plus: 1.33.3
```
- Escaneo de dispositivos BLE
- Conexión y emparejamiento
- Comunicación bidireccional

**Protocolo de Comunicación**:
```dart
// Ejemplo de flujo de conexión BLE
1. Escanear dispositivos Insta360
2. Conectar vía Bluetooth
3. Autenticarse con la cámara
4. Enviar comandos (captura, configuración)
5. Recibir notificaciones de estado
```

---

## 🛠️ Estrategias de Implementación

### **Opción 1: SDK Nativo con Platform Channels** (⭐ Recomendado)

#### **Ventajas**:
- ✅ Acceso completo a funcionalidades del SDK oficial
- ✅ Estabilidad y soporte oficial de Insta360
- ✅ Actualizaciones regulares del SDK

#### **Desventajas**:
- ⚠️ Requiere código nativo (Java/Kotlin para Android)
- ⚠️ Mayor complejidad de desarrollo
- ⚠️ Proceso de aplicación del SDK puede tomar días

#### **Pasos de Implementación**:

**1. Solicitar SDK de Insta360**:
```
https://www.insta360.com/developer/home
- Completar formulario con información de la app
- Especificar modelos de cámara compatibles
- Esperar aprobación (3-7 días hábiles)
```

**2. Crear Plugin Flutter con Platform Channels**:

**Archivo: `android/app/src/main/kotlin/sutodero/app/Insta360Plugin.kt`**
```kotlin
package sutodero.app

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import com.arashivision.sdk.* // SDK de Insta360

class Insta360Plugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "sutodero.app/insta360")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "connectCamera" -> connectCamera(result)
                "capturePhoto360" -> capturePhoto360(result)
                "downloadPhoto" -> downloadPhoto(call.arguments, result)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun connectCamera(result: MethodChannel.Result) {
        // Implementación con SDK de Insta360
        try {
            // Escanear y conectar cámara
            InstaCameraManager.getInstance().openCamera(...)
            result.success(true)
        } catch (e: Exception) {
            result.error("CONNECTION_ERROR", e.message, null)
        }
    }
    
    private fun capturePhoto360(result: MethodChannel.Result) {
        // Capturar foto 360°
        InstaCameraManager.getInstance().takePhoto(...)
    }
    
    private fun downloadPhoto(args: Any?, result: MethodChannel.Result) {
        // Descargar foto desde cámara
    }
}
```

**3. Integrar en Flutter**:

**Archivo: `lib/services/insta360_service.dart`**
```dart
import 'package:flutter/services.dart';

class Insta360Service {
    static const platform = MethodChannel('sutodero.app/insta360');
    
    /// Conectar cámara Insta360
    Future<bool> connectCamera() async {
        try {
            final result = await platform.invokeMethod('connectCamera');
            return result as bool;
        } catch (e) {
            debugPrint('Error al conectar cámara: $e');
            return false;
        }
    }
    
    /// Capturar foto 360°
    Future<String?> capturePhoto360() async {
        try {
            final photoPath = await platform.invokeMethod('capturePhoto360');
            return photoPath as String?;
        } catch (e) {
            debugPrint('Error al capturar foto: $e');
            return null;
        }
    }
    
    /// Descargar foto desde cámara
    Future<String?> downloadPhoto(String photoId) async {
        try {
            final localPath = await platform.invokeMethod(
                'downloadPhoto',
                {'photoId': photoId},
            );
            return localPath as String?;
        } catch (e) {
            debugPrint('Error al descargar foto: $e');
            return null;
        }
    }
}
```

---

### **Opción 2: Integración BLE Directa** (⚠️ Complejidad Alta)

#### **Ventajas**:
- ✅ No requiere SDK oficial
- ✅ Control total del protocolo

#### **Desventajas**:
- ❌ Ingeniería inversa del protocolo BLE
- ❌ Sin soporte oficial
- ❌ Actualizaciones de firmware pueden romper compatibilidad

#### **Pasos (Solo para investigación)**:

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Insta360BLEService {
    // UUIDs de servicios BLE (deben ser descubiertos mediante ingeniería inversa)
    static const String INSTA360_SERVICE_UUID = "0000xxxx-0000-1000-8000-00805f9b34fb";
    static const String CAPTURE_CHAR_UUID = "0000yyyy-0000-1000-8000-00805f9b34fb";
    
    Future<void> connectAndCapture() async {
        // Escanear dispositivos
        await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
        
        // Buscar Insta360
        final devices = await FlutterBluePlus.scanResults.first;
        final insta360Device = devices.firstWhere(
            (d) => d.device.name.contains('Insta360'),
        );
        
        // Conectar
        await insta360Device.device.connect();
        
        // Descubrir servicios
        final services = await insta360Device.device.discoverServices();
        
        // Enviar comando de captura (protocolo específico)
        final captureService = services.firstWhere(
            (s) => s.uuid.toString() == INSTA360_SERVICE_UUID,
        );
        
        // Implementar protocolo de comunicación...
    }
}
```

---

## 📋 Requisitos para Implementación Completa

### **Hardware**:
- ✅ Cámara Insta360 (X3, X4, ONE RS, etc.)
- ✅ Dispositivo Android con Bluetooth 5.0+
- ✅ WiFi para transferencia de archivos grandes

### **Software**:
- ✅ SDK de Insta360 (requiere aplicación y aprobación)
- ✅ Android Studio para desarrollo nativo
- ✅ flutter_blue_plus para BLE
- ⚠️ Permisos: Bluetooth, Ubicación, Almacenamiento

### **Permisos Android (AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🚀 Roadmap de Implementación

### **Fase 1: Preparación** (1-2 semanas)
- [ ] Solicitar SDK oficial de Insta360
- [ ] Configurar proyecto Android Studio para plugin nativo
- [ ] Estudiar documentación del SDK

### **Fase 2: Desarrollo del Plugin** (2-3 semanas)
- [ ] Implementar Platform Channel
- [ ] Desarrollar funciones de conexión BLE/WiFi
- [ ] Implementar captura de fotos 360°
- [ ] Implementar descarga de medios

### **Fase 3: Integración Flutter** (1 semana)
- [ ] Crear servicio Insta360Service
- [ ] Integrar con pantalla de tour virtual
- [ ] Implementar UI de control de cámara

### **Fase 4: Testing y Optimización** (1-2 semanas)
- [ ] Probar con cámaras reales
- [ ] Optimizar transferencia de archivos
- [ ] Manejo de errores y edge cases

---

## 🔗 Enlaces Útiles

- **Developer Portal**: https://www.insta360.com/developer/home
- **GitHub Android SDK**: https://github.com/Insta360Develop/Android-SDK
- **Documentación**: https://onlinemanual.insta360.com/developer/en-us/resource/sdk
- **flutter_blue_plus**: https://pub.dev/packages/flutter_blue_plus

---

## ⚠️ Notas Importantes

1. **SDK Privado**: El SDK de Insta360 NO es público. Requiere aplicación y aprobación.
2. **Hardware Específico**: Solo funciona con cámaras Insta360 oficiales.
3. **Complejidad**: Implementación nativa requiere conocimientos de Android/iOS.
4. **Alternativas**: Para prototipo, usar galería de fotos 360° existentes.

---

## 📝 Estado Actual en SU TODERO

✅ **Implementado**:
- Visor de tours virtuales 360°
- Servicio de gestión de tours
- Integración con Firebase Storage

⚠️ **Pendiente**:
- Aprobación del SDK de Insta360
- Implementación de Platform Channel
- Desarrollo del plugin nativo
- Testing con hardware real

---

## 💡 Recomendación

Para desarrollo inicial, se recomienda:
1. Usar fotos 360° existentes o de prueba
2. Implementar flujo completo de tours virtuales
3. Solicitar SDK de Insta360 en paralelo
4. Integrar SDK cuando esté aprobado

Esta estrategia permite avanzar con la funcionalidad mientras se espera aprobación del SDK.
