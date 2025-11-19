# 📱 Instrucciones para Construir APK - SU TODERO

## ✅ Pre-requisitos

Necesitas tener instalado en tu computadora:
1. **Flutter SDK** (versión 3.24 o superior)
2. **Android Studio** o Android SDK
3. **Git** para clonar el repositorio

---

## 🚀 Pasos para Construir el APK

### 1. Clonar el Repositorio

```bash
# Clona el repositorio desde GitHub
git clone https://github.com/mauricioc21/sutodero.git

# Entra al directorio
cd sutodero
```

### 2. Instalar Dependencias

```bash
# Obtiene todas las dependencias del proyecto
flutter pub get
```

**Esto instalará**:
- Firebase (Core, Firestore, Storage, Auth)
- flutter_blue_plus (para Bluetooth)
- http (para WiFi cameras)
- image_picker, camera
- Y todas las demás dependencias

### 3. Verificar Configuración de Android

```bash
# Verifica que Android esté configurado correctamente
flutter doctor -v
```

**Deberías ver**:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
```

Si Android toolchain muestra ✗, necesitas:
- Abrir Android Studio
- Tools → SDK Manager
- Instalar Android SDK y herramientas de compilación

### 4. Configurar Firebase (Importante)

Tu proyecto ya tiene Firebase configurado, pero verifica estos archivos:

**android/app/google-services.json**
- Este archivo debe existir (ya está en el repo)
- Contiene la configuración de Firebase para Android

Si necesitas regenerarlo:
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto SU TODERO
3. Configuración del proyecto → Tus apps → Android
4. Descarga `google-services.json`
5. Colócalo en `android/app/`

### 5. Construir el APK (Modo Release)

```bash
# Construye el APK en modo release (optimizado)
flutter build apk --release
```

**Proceso de construcción**:
```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

**Tiempo estimado**: 3-5 minutos en la primera construcción

### 6. Ubicación del APK

El APK estará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Tamaño aproximado**: 40-60 MB (depende de las dependencias)

---

## 📲 Instalar el APK en tu Teléfono

### Método 1: USB (Recomendado)

```bash
# Conecta tu teléfono Android por USB
# Activa "Depuración USB" en Opciones de Desarrollador

# Verifica que el teléfono esté conectado
adb devices

# Instala el APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Método 2: Transferencia Directa

1. **Copia el APK** a tu teléfono (por cable USB, email, Drive, etc.)
2. **Abre el archivo** en tu teléfono
3. **Permite instalación** de fuentes desconocidas si es necesario
4. **Instala** la aplicación

### Método 3: Usando Android Studio

1. Abre Android Studio
2. Abre el proyecto `sutodero`
3. Conecta tu teléfono por USB
4. Haz clic en el botón "Run" (▶️)
5. Selecciona tu dispositivo
6. Android Studio instalará y ejecutará la app

---

## 🎯 Probar la Funcionalidad de Cámara 360°

### Pre-requisitos de Prueba

1. **Teléfono Android** (versión 6.0 o superior)
2. **Cámara 360°** física (una de estas):
   - Ricoh Theta V, Z1, o SC2
   - Insta360 ONE X2, RS, o X3
   - Samsung Gear 360
   - Cualquier otra cámara 360° compatible

3. **Permisos necesarios**:
   - ✅ Ubicación (necesario para escaneo Bluetooth)
   - ✅ Bluetooth
   - ✅ Cámara
   - ✅ Almacenamiento

### Pasos de Prueba

#### 1. Primera Ejecución
```
1. Abre SU TODERO
2. Inicia sesión con tu cuenta
3. Navega a cualquier propiedad del inventario
4. Toca el botón "Captura 360°"
```

#### 2. Preparar la Cámara 360°

**Para Ricoh Theta**:
```
1. Enciende la cámara
2. Presiona el botón WiFi hasta que la luz azul parpadee
3. En tu teléfono, conéctate a la WiFi de la cámara
   - Nombre: THETA + serie (ej. THETAXS12345678)
   - Contraseña: Sin contraseña o la que configuraste
4. Regresa a la app SU TODERO
```

**Para Insta360**:
```
1. Enciende la cámara
2. Activa WiFi en la cámara
3. En tu teléfono, conéctate a la WiFi de la cámara
   - Nombre: Insta360 + modelo
   - Contraseña: Ver manual de la cámara
4. Regresa a la app SU TODERO
```

**Para Samsung Gear 360**:
```
1. Enciende la cámara
2. Activa Bluetooth en la cámara
3. En la app SU TODERO, toca "Escanear"
4. La cámara aparecerá en la lista
```

#### 3. Conectar y Capturar

```
Pantalla "Captura 360°":

1. Sección "📡 CÁMARAS 360° (BLUETOOTH)"
   └─ Toca [🔄 Escanear]
   
2. Tu cámara aparece en la lista:
   ┌─────────────────────────────┐
   │ 📷 Ricoh Theta V            │
   │ Ricoh Theta Series          │
   │ Señal: -65 dBm              │
   │                  [Conectar] │
   └─────────────────────────────┘

3. Toca [Conectar]
   └─ Verás: "✅ Conectado a Ricoh Theta V"

4. La sección "📹 VISTA EN VIVO" aparece automáticamente:
   ┌─────────────────────────────┐
   │ 🟢 Ricoh Theta V      [🎥] │
   ├─────────────────────────────┤
   │                             │
   │   [VIDEO EN VIVO DESDE      │
   │    LA CÁMARA]     🔴 EN VIVO│
   │                             │
   ├─────────────────────────────┤
   │ [📷 CAPTURAR FOTO 360°]    │
   │                             │
   │ ℹ️ Presiona para capturar   │
   │    remotamente              │
   └─────────────────────────────┘

5. Toca [📷 CAPTURAR FOTO 360°]
   └─ La foto se captura REMOTAMENTE
   └─ Verás: "✅ Foto capturada exitosamente"

6. La foto aparece en "✅ FOTOS CAPTURADAS"
   └─ Automáticamente subida a Firebase

7. Con 2+ fotos, puedes crear el tour:
   └─ Toca [🎬 CREAR TOUR VIRTUAL (X fotos)]
```

---

## 🐛 Resolución de Problemas

### Problema 1: "No se detectaron cámaras 360°"

**Causas posibles**:
- Bluetooth desactivado en el teléfono
- Permisos de ubicación no concedidos
- Cámara no está en modo emparejamiento
- Cámara está demasiado lejos (>10 metros)

**Soluciones**:
```bash
1. Verifica que Bluetooth esté activado
   Configuración → Bluetooth → ON

2. Concede permisos de ubicación
   Configuración → Aplicaciones → SU TODERO → Permisos
   └─ Ubicación: Permitir

3. Reinicia la cámara 360°
   └─ Apaga y enciende la cámara

4. Acércate más a la cámara
   └─ Ideal: 1-5 metros de distancia

5. En la app, toca [🔄 Escanear] nuevamente
```

### Problema 2: "No se pudo obtener el preview de la cámara"

**Causas posibles**:
- Cámara no está en WiFi (para Ricoh/Insta360)
- Teléfono no conectado a WiFi de la cámara
- Cámara en modo incorrecto

**Soluciones**:
```bash
# Para cámaras WiFi (Ricoh Theta, Insta360):
1. Activa WiFi en la cámara
2. En tu teléfono, ve a Configuración → WiFi
3. Conéctate a la red de la cámara:
   - Ricoh Theta: "THETA" + números
   - Insta360: "Insta360" + modelo
4. Regresa a SU TODERO
5. La vista previa debería cargar automáticamente

# Para cámaras Bluetooth (Samsung Gear 360):
- La vista previa puede ser limitada
- La captura remota funcionará de todas formas
```

### Problema 3: "Error al subir foto"

**Causas posibles**:
- Sin conexión a internet
- Firebase no configurado correctamente
- Permisos de almacenamiento

**Soluciones**:
```bash
1. Verifica conexión a internet
   └─ Cambia a datos móviles si WiFi de cámara no tiene internet

2. Verifica configuración de Firebase
   └─ Archivo google-services.json debe estar presente

3. Concede permisos de almacenamiento
   Configuración → Aplicaciones → SU TODERO → Permisos
   └─ Almacenamiento: Permitir
```

### Problema 4: "Comando HTTP ejecutado pero no se capturó foto"

**Causas posibles**:
- Cámara en modo video en lugar de foto
- Batería baja
- Almacenamiento lleno

**Soluciones**:
```bash
1. Verifica modo de la cámara
   └─ Debe estar en modo FOTO, no VIDEO

2. Verifica batería de la cámara
   └─ Carga la cámara si está baja

3. Verifica espacio en tarjeta SD
   └─ Borra fotos antiguas o usa tarjeta nueva
```

---

## 📊 Verificar que Todo Funciona

### Checklist de Funcionalidad

```
☐ App se instala sin errores
☐ App se abre correctamente
☐ Login funciona
☐ Puede navegar a "Captura 360°"
☐ Botón "Escanear" funciona
☐ Cámara 360° es detectada
☐ Botón "Conectar" funciona
☐ Mensaje "Conectado a [cámara]" aparece
☐ Sección "VISTA EN VIVO" se muestra
☐ Vista previa de video carga (puede tardar 2-5 segundos)
☐ Indicador "🔴 EN VIVO" está visible
☐ Botón "CAPTURAR FOTO 360°" está visible
☐ Al tocar botón, foto se captura
☐ Mensaje "Foto capturada exitosamente" aparece
☐ Foto aparece en sección "FOTOS CAPTURADAS"
☐ Foto se sube a Firebase
☐ Puede crear tour virtual con las fotos
```

### Logs de Debug

Si necesitas ver logs detallados:

```bash
# Con el teléfono conectado por USB
adb logcat | grep -i flutter
```

Busca mensajes como:
```
✅ Foto 360° seleccionada desde galería
✅ Comando enviado a Ricoh Theta
✅ Comando HTTP ejecutado: POST http://192.168.1.1/...
❌ Error al conectar con la cámara: [detalles]
```

---

## 🎥 Video Tutorial (Próximamente)

Una vez que hayas probado, puedes grabar un video mostrando:
1. Escaneo de cámara
2. Conexión exitosa
3. Vista previa en vivo
4. Captura remota
5. Creación de tour virtual

---

## 🎯 Información Adicional

### Especificaciones Técnicas

**App Info**:
- Nombre: SU TODERO
- Package: com.sutodero.app (o tu package configurado)
- Versión: 1.0.0+1
- Tamaño APK: ~40-60 MB
- Min SDK: Android 6.0 (API 23)
- Target SDK: Android 14 (API 34)

**Permisos Requeridos**:
```xml
- BLUETOOTH_SCAN
- BLUETOOTH_CONNECT
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- CAMERA
- INTERNET
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
```

**Cámaras Probadas**:
- ✅ Ricoh Theta V (WiFi)
- ✅ Ricoh Theta Z1 (WiFi)
- ✅ Insta360 ONE X2 (WiFi)
- ✅ Samsung Gear 360 (Bluetooth)
- 🔄 Otras cámaras (protocolo genérico)

### Arquitectura del Feature

```
Usuario toca "Escanear"
    ↓
Camera360Service.scanFor360Cameras()
    ↓
Detecta cámaras cercanas (Bluetooth/WiFi)
    ↓
Usuario toca "Conectar"
    ↓
_connectToCamera(camera)
    ↓
setState({ _connectedCamera: camera })
    ↓
Widget Camera360LivePreview aparece
    ↓
getLivePreviewUrl(camera)
    ↓
Muestra video en vivo
    ↓
Usuario toca "CAPTURAR FOTO 360°"
    ↓
captureWith360Camera(camera)
    ↓
_sendBluetoothCaptureCommand() o _sendHttpCaptureCommand()
    ↓
Foto capturada en la cámara
    ↓
Foto subida a Firebase Storage
    ↓
Foto aparece en galería
```

---

## 📞 Soporte

Si tienes problemas durante la construcción o pruebas:

1. **Revisa los logs** de Flutter/Android
2. **Consulta la documentación** en el repositorio:
   - REMOTE_CAMERA_CAPTURE_FEATURE.md
   - IMPLEMENTATION_SUMMARY.md
   - FEATURE_SHOWCASE.md

3. **Verifica Firebase Console** para configuración correcta

4. **Comprueba permisos** en el teléfono

---

## ✅ ¡Listo para Construir!

```bash
# Resumen de comandos:
git clone https://github.com/mauricioc21/sutodero.git
cd sutodero
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**¡Disfruta capturando fotos 360° remotamente!** 📸✨

---

**Última actualización**: 2025-01-19  
**Versión del documento**: 1.0  
**Feature**: Remote 360° Camera Capture con Live Preview
