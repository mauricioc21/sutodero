# 🛠️ SU TODERO

**App profesional de gestión de inventarios, tickets de reparación y mantenimiento con captura 360° y planos arquitectónicos**

---

## 📱 Descripción

**SU TODERO** es una aplicación móvil y web desarrollada en Flutter que permite gestionar de forma profesional:

- 📦 **Inventarios de propiedades** - Gestión completa de espacios y propiedades
- 🔧 **Tickets de reparación y mantenimiento** - Sistema integral de gestión de servicios
- 📸 **Captura 360°** - Integración con cámaras 360° (Insta360, WiFi, Bluetooth)
- 🏗️ **Planos arquitectónicos** - Generación automática desde fotos 360°

---

## ✨ Características Principales

### 🎨 Diseño Profesional
- Logo personalizado con el maestro todero (personaje insignia)
- Colores corporativos: Amarillo dorado (#FFD700) y gris oscuro (#2C2C2C)
- Material Design 3
- Animaciones fluidas
- Responsive design

### 📦 Gestión de Inventarios
- Crear y editar propiedades
- Agregar espacios a cada propiedad
- Captura rápida de fotos (planas y 360°)
- Detección automática de tipo de cámara
- Estados de espacios (excelente, bueno, regular, malo, crítico)

### 🔧 Sistema de Tickets
- Crear tickets de reparación y mantenimiento
- Estados: Pendiente, En Progreso, Completado, Cancelado
- Prioridades: Baja, Media, Alta, Urgente
- Envío automático por email y WhatsApp
- Historial completo de tickets

### 📸 Captura 360° Avanzada
- **Captura remota WiFi** (Open Spherical Camera API)
- **Captura remota Bluetooth** (flutter_blue_plus)
- **Integración Insta360** - Navegación, descarga y visualización
- **Captura rápida** - Detección automática (Insta360/360°/Cámara normal)
- **Subida automática** a Firebase Storage

### 🏗️ Generación de Planos
- Planos individuales por espacio (desde foto 360°)
- Plano completo de la propiedad (combinando todos los espacios)
- Generación automática al capturar fotos 360°
- Visualización interactiva
- Exportación a PDF

---

## 🚀 Tecnologías

### Framework y Lenguaje
- **Flutter 3.35.4**
- **Dart 3.9.2**

### Backend y Base de Datos
- **Firebase Core 3.6.0**
- **Cloud Firestore 5.4.3** - Base de datos NoSQL
- **Firebase Storage 12.3.2** - Almacenamiento de fotos y documentos
- **Firebase Auth 5.3.1** - Autenticación de usuarios

### Principales Dependencias
- `provider: 6.1.5+1` - State management
- `go_router: 14.6.2` - Navegación
- `image_picker: 1.1.2` - Captura de fotos
- `camera: 0.11.0+2` - Control de cámara
- `flutter_blue_plus: 1.33.3` - Bluetooth
- `wifi_iot: 0.3.19+1` - WiFi
- `panorama: 0.4.1` - Visualización 360°
- `pdf: 3.11.1` - Generación de PDFs
- `shared_preferences: 2.5.3` - Almacenamiento local
- `hive: 2.2.3` + `hive_flutter: 1.1.0` - Base de datos local

---

## 📞 Información de Contacto

- **Email General**: info@c21sutodero.com
- **Email Reparaciones**: reparaciones.sycinmobiliaria@gmail.com
- **WhatsApp**: +57 313 816 0439

---

## 🛠️ Instalación y Desarrollo

### Requisitos Previos
- Flutter 3.35.4 o superior
- Dart 3.9.2 o superior
- Android SDK (para builds Android)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/mauricioc21/sutodero.git
cd sutodero

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Compilar para web
flutter build web --release

# Compilar APK para Android
flutter build apk --release
```

### Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Descarga `google-services.json` y colócalo en `android/app/`
3. Configura Firebase Storage y Firestore
4. Actualiza las reglas de seguridad de Firestore

---

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── models/                      # Modelos de datos
│   ├── user_model.dart
│   ├── inventory_property.dart
│   ├── property_room.dart
│   ├── ticket.dart
│   ├── floor_plan.dart
│   └── complete_floor_plan.dart
├── services/                    # Servicios y lógica de negocio
│   ├── auth_service.dart
│   ├── inventory_service.dart
│   ├── ticket_service.dart
│   ├── camera_service.dart
│   ├── insta360_service.dart
│   ├── quick_capture_service.dart
│   ├── floor_plan_generator_service.dart
│   └── complete_floor_plan_service.dart
├── screens/                     # Pantallas de la aplicación
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── auth/
│   ├── inventory/
│   ├── tickets/
│   └── camera/
├── widgets/                     # Widgets reutilizables
└── utils/                       # Utilidades y helpers

assets/
├── images/                      # Imágenes e iconos
│   ├── su_todero_logo.png
│   └── maestro_todero.png
└── icons/                       # Iconos de la app
```

---

## 🔐 Seguridad

- Autenticación de usuarios con Firebase Auth
- Roles de usuario (Admin, Técnico, Cliente)
- Reglas de seguridad de Firestore configuradas
- Datos sensibles protegidos

---

## 📝 Licencia

Copyright © 2024 SU TODERO - Todos los derechos reservados.

---

## 👨‍💻 Desarrollado por

**Equipo SU TODERO**

Eslogan: *"No existe reparación, mantenimiento o remodelación que no hagamos"*

---

## 🎯 Roadmap

- [x] Diseño e identidad visual
- [x] Sistema de splash screen
- [x] Navegación principal
- [ ] Sistema de autenticación completo
- [ ] Módulo de inventarios
- [ ] Sistema de tickets
- [ ] Captura 360° y servicios de cámara
- [ ] Generación automática de planos
- [ ] Sistema de notificaciones
- [ ] Modo offline
- [ ] Exportación de reportes PDF
- [ ] Panel de administración web

---

**Version**: 1.0.0  
**Última actualización**: Noviembre 2024
