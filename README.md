# 🏢 SU TODERO - Sistema de Gestión de Propiedades

## 📱 Descripción

**SU TODERO** es una aplicación móvil Flutter completa para la gestión de inventarios de propiedades inmobiliarias, con énfasis en la generación de actas de entrega y recibido con firmas digitales táctiles.

### ✨ Características Principales

- 🔐 **Autenticación de Usuarios**: Login/Registro con Firebase Authentication
- 📦 **Gestión de Inventario**: CRUD completo de propiedades con fotos
- 📄 **Actas Digitales**: Generación de Actas de Entrega y Recibido
- ✍️ **Firmas Táctiles**: Captura de firmas digitales en canvas táctil
- 📑 **Generación de PDF**: PDFs nativos con firmas embebidas
- ☁️ **Almacenamiento en la Nube**: Firebase Storage para PDFs e imágenes
- 📱 **Multiplataforma**: Android (APK) y Web

---

## 🛠️ Stack Tecnológico

### Frontend
- **Framework**: Flutter 3.35.4
- **Lenguaje**: Dart 3.9.2
- **UI**: Material Design 3
- **State Management**: Provider

### Backend & Servicios
- **Autenticación**: Firebase Authentication
- **Base de Datos**: Cloud Firestore
- **Almacenamiento**: Firebase Storage
- **Hosting Web**: Python HTTP Server

### Dependencias Clave
```yaml
dependencies:
  flutter: sdk: flutter
  
  # Firebase Core
  firebase_core: 3.6.0
  cloud_firestore: 5.4.3
  firebase_storage: 12.3.2
  firebase_auth: 5.3.1
  
  # UI & Multimedia
  image_picker: 1.1.2
  camera: 0.11.0+2
  video_player: 2.9.2
  fl_chart: 0.69.0
  
  # PDF & Firmas
  pdf: 3.11.1
  signature: 5.5.0
  printing: 5.13.3
  
  # State Management
  provider: 6.1.5+1
  
  # Storage Local
  hive: 2.2.3
  hive_flutter: 1.1.0
  shared_preferences: 2.5.3
```

---

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                    # Entry point de la aplicación
├── models/                      # Modelos de datos
│   ├── acta_model.dart         # Modelo para Actas
│   ├── inventory_property.dart # Modelo para Propiedades
│   └── user_model.dart         # Modelo de Usuario
├── screens/                     # Pantallas de la app
│   ├── auth/                   # Autenticación
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── actas/                  # Módulo de Actas
│   │   ├── acta_entrega_screen.dart
│   │   ├── acta_recibido_screen.dart
│   │   ├── acta_entrega_form_screen.dart
│   │   └── acta_recibido_form_screen.dart
│   └── inventory/              # Gestión de Inventario
│       ├── inventory_screen.dart
│       └── inventory_detail_screen.dart
├── services/                    # Lógica de negocio
│   ├── auth_service.dart       # Servicio de autenticación
│   ├── acta_service.dart       # Servicio de Actas (CRUD + PDF)
│   └── inventory_service.dart  # Servicio de Inventario
├── widgets/                     # Widgets reutilizables
│   ├── signature_pad_dialog.dart  # Widget de firma táctil
│   └── custom_app_bar.dart
└── theme/                       # Tema y estilos
    └── app_theme.dart

android/
├── app/
│   ├── build.gradle.kts        # Configuración Android
│   ├── google-services.json    # ⚠️ NO INCLUIDO (Firebase config)
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/sutodero/app/
│           └── MainActivity.kt
└── key.properties              # ⚠️ NO INCLUIDO (Firma del APK)

assets/
├── assets/
│   ├── images/
│   │   └── logo.png
│   └── videos/
│       └── splash_video.mp4    # Video intro
└── fonts/
```

---

## 🚀 Instalación y Configuración

### 1️⃣ Prerrequisitos

- Flutter SDK 3.35.4
- Dart 3.9.2
- Android Studio / VS Code
- Cuenta de Firebase
- Git

### 2️⃣ Clonar el Repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd flutter_app
```

### 3️⃣ Instalar Dependencias

```bash
flutter pub get
```

### 4️⃣ Configurar Firebase

#### **Paso A: Crear Proyecto Firebase**
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Habilita los siguientes servicios:
   - **Authentication** (Email/Password)
   - **Cloud Firestore**
   - **Firebase Storage**

#### **Paso B: Descargar Archivos de Configuración**

**Para Android:**
1. Registra tu app Android en Firebase
2. Package name: `sutodero.app`
3. Descarga `google-services.json`
4. Colócalo en: `android/app/google-services.json`

**Para Web:**
1. Registra tu app Web en Firebase
2. Copia la configuración Firebase
3. Actualiza `lib/firebase_options.dart` con tus credenciales

#### **Paso C: Configurar Reglas de Firestore**

Ve a **Firestore Database → Rules** y configura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas de desarrollo (CAMBIAR EN PRODUCCIÓN)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### **Paso D: Configurar Reglas de Storage**

Ve a **Storage → Rules** y configura:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Reglas de desarrollo (CAMBIAR EN PRODUCCIÓN)
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5️⃣ Generar Keystore para Release (Android)

```bash
keytool -genkey -v -keystore android/release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release \
  -storepass sutodero2024 \
  -keypass sutodero2024 \
  -dname "CN=SU TODERO, OU=Mobile, O=SU TODERO, L=Bogota, ST=Cundinamarca, C=CO"
```

Crea `android/key.properties`:
```properties
storePassword=sutodero2024
keyPassword=sutodero2024
keyAlias=release
storeFile=release-key.jks
```

---

## 🏗️ Compilación

### **Web Preview**
```bash
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```

### **Android APK**
```bash
# APK único (universal)
flutter build apk --release

# APK por arquitectura (tamaño optimizado)
flutter build apk --release --split-per-abi
```

### **Android App Bundle (AAB)**
```bash
flutter build appbundle --release
```

---

## 📱 Funcionalidades Detalladas

### 🔐 Módulo de Autenticación
- Login con email/password
- Registro de nuevos usuarios
- Recuperación de contraseña
- Persistencia de sesión
- Cierre de sesión

### 📦 Módulo de Inventario
- Listar propiedades del usuario
- Crear nueva propiedad con:
  - Dirección
  - Datos del cliente (nombre, teléfono, email)
  - Tipo de propiedad
  - Descripción
  - Fotos múltiples (cámara o galería)
- Editar/Eliminar propiedades
- Vista detallada de cada propiedad

### 📄 Módulo de Actas

#### **Acta de Entrega a Arrendatario**
1. Seleccionar propiedad del inventario
2. Completar formulario:
   - Nombre del arrendatario
   - Cédula
   - Fecha de entrega
   - Lista de novedades/observaciones
3. Capturar firmas digitales:
   - **Firma de quien Entrega** (propietario/administrador)
   - **Firma de quien Recibe** (arrendatario)
4. Guardar acta en Firestore
5. Generar PDF nativo con:
   - Información de la propiedad
   - Datos del arrendatario
   - Texto legal del acta
   - Lista de novedades
   - Firmas digitales embebidas
6. Subir PDF a Firebase Storage
7. Descargar PDF generado

#### **Acta de Recibido del Arrendatario**
- Mismo flujo que Acta de Entrega
- Texto legal adaptado para devolución de propiedad
- Firmas: quien recibe (propietario) y quien entrega (arrendatario)

### ✍️ Widget de Firma Digital
- Canvas táctil de 400x200px
- Dibujo en tiempo real con el dedo
- Captura de coordenadas precisas con GlobalKey
- Botones: Limpiar, Cancelar, Aceptar
- Conversión a imagen Base64 para PDF

---

## 🔥 Configuración Firebase Detallada

### **Estructura de Firestore**

#### **Colección: `users`**
```json
{
  "uid": "user123",
  "email": "usuario@ejemplo.com",
  "nombre": "Juan Pérez",
  "rol": "admin",
  "createdAt": "Timestamp"
}
```

#### **Colección: `inventory_properties`**
```json
{
  "id": "prop123",
  "userId": "user123",
  "direccion": "Calle 123 # 45-67",
  "clienteNombre": "María García",
  "clienteTelefono": "+57 300 123 4567",
  "clienteEmail": "maria@ejemplo.com",
  "tipo": "Apartamento",
  "descripcion": "Apartamento 3 habitaciones",
  "fotos": ["url1", "url2"],
  "fechaCreacion": "Timestamp"
}
```

#### **Colección: `actas`**
```json
{
  "id": "acta123",
  "propertyId": "prop123",
  "propertyAddress": "Calle 123 # 45-67",
  "tipoActa": "Entrega",
  "arrendatarioNombre": "Carlos López",
  "arrendatarioCedula": "123456789",
  "novedades": [
    "Pintura en buen estado",
    "Pequeño rayón en puerta principal"
  ],
  "firmaEntrega": "data:image/png;base64,...",
  "firmaRecibido": "data:image/png;base64,...",
  "pdfUrl": "https://storage.googleapis.com/.../acta_entrega_123.pdf",
  "pdfGenerado": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### **Estructura de Firebase Storage**

```
storage/
├── actas/
│   ├── acta_entrega_123.pdf
│   ├── acta_recibido_456.pdf
│   └── ...
├── inventory_photos/
│   ├── prop123_photo1.jpg
│   ├── prop123_photo2.jpg
│   └── ...
└── profile_images/
    └── user123_avatar.jpg
```

---

## 🐛 Solución de Problemas

### **Error: "Missing or insufficient permissions"**
**Causa**: Reglas de Firestore/Storage incorrectas
**Solución**: Configura las reglas como se indica en la sección 4️⃣

### **Error: "No Firebase App '[DEFAULT]' has been created"**
**Causa**: `firebase_options.dart` no configurado o inicialización incorrecta
**Solución**: 
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### **Firmas no se dibujan en el canvas**
**Causa**: Problema de coordenadas RenderBox
**Solución**: Ya implementado con GlobalKey en `signature_pad_dialog.dart`

### **APK no instala en Android**
**Causa**: Keystore no configurado o package name incorrecto
**Solución**: Verifica `android/key.properties` y `applicationId` en `build.gradle.kts`

### **Video splash no carga**
**Causa**: Archivo `splash_video.mp4` no existe en `assets/assets/videos/`
**Solución**: Coloca el video en la ruta correcta y decláralo en `pubspec.yaml`

---

## 📊 Versiones y Compatibilidad

| Componente | Versión | Notas |
|------------|---------|-------|
| Flutter | 3.35.4 | ⚠️ NO actualizar |
| Dart | 3.9.2 | ⚠️ NO actualizar |
| Android SDK | API 35 | Target Android 15 |
| Min Android | API 21 | Android 5.0+ |
| Firebase Core | 3.6.0 | Versión fija |
| Firestore | 5.4.3 | Versión fija |

---

## 🔐 Seguridad

### **Archivos Sensibles NO Incluidos en Git:**
- ❌ `google-services.json`
- ❌ `firebase-admin-sdk.json`
- ❌ `android/key.properties`
- ❌ `android/release-key.jks`

### **Recomendaciones de Producción:**
1. Implementar reglas de Firestore con validación de autenticación
2. Limitar tamaño máximo de archivos en Storage
3. Implementar rate limiting para operaciones sensibles
4. Usar variables de entorno para credenciales
5. Habilitar App Check de Firebase
6. Implementar ofuscación del código (`flutter build apk --obfuscate`)

---

## 📞 Soporte y Contacto

**Desarrollador**: Equipo SU TODERO
**Versión**: 1.0.0 (Build 1)
**Última Actualización**: Diciembre 2024

---

## 📄 Licencia

Este proyecto es de uso privado. Todos los derechos reservados.

---

## 🚀 Próximas Características (Roadmap)

- [ ] Notificaciones push con Firebase Cloud Messaging
- [ ] Modo offline con sincronización automática
- [ ] Exportar actas a otros formatos (Word, Excel)
- [ ] Dashboard de estadísticas
- [ ] Escaneo de documentos con OCR
- [ ] Integración con WhatsApp para envío de PDFs
- [ ] Versión iOS
- [ ] Sistema de roles avanzado
- [ ] Historial de cambios en actas
- [ ] Backup automático a Google Drive

---

**¡Gracias por usar SU TODERO!** 🏢✨
