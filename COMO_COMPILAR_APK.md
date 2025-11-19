# 📱 Cómo Compilar el APK de SU TODERO

## 🎯 Método Recomendado: Android Studio

### Requisitos:
- Android Studio instalado
- Flutter SDK instalado
- Java JDK 11 o superior

### Pasos:

1. **Abrir el proyecto en Android Studio:**
   ```bash
   cd /ruta/a/sutodero
   code . # o abre con Android Studio
   ```

2. **Ejecutar el script de compilación optimizado:**
   ```bash
   ./compilar_apk_optimizado.sh
   ```

3. **El APK estará en:**
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🚀 Método Alternativo: Línea de Comandos

### Con Flutter instalado:

```bash
# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Compilar APK release
flutter build apk --release
```

### Sin Flutter (solo Gradle):

```bash
cd android

# Limpiar
./gradlew clean

# Compilar APK release
./gradlew assembleRelease

# El APK estará en:
# app/build/outputs/apk/release/app-release.apk
```

---

## 📦 APK Pre-compilado

Si no tienes las herramientas de desarrollo, puedes:

1. **Descargar el APK ya compilado** del repositorio GitHub (releases)
2. **Usar el servicio de CI/CD** (Codemagic) para compilar automáticamente
3. **Solicitar el APK** al equipo de desarrollo

---

## 🔐 Keystore y Firma

El proyecto ya está configurado con keystore de release:

- **Archivo**: `sutodero-release.jks`
- **Alias**: sutodero
- **Password**: Perro2011

**IMPORTANTE**: Para distribución en producción, genera un nuevo keystore con contraseña segura.

---

## ⚙️ Configuración Incluida

El APK compilado incluye todas las optimizaciones:

✅ Compresión automática de imágenes  
✅ Caché de imágenes optimizado  
✅ ProGuard/R8 activado (minificación)  
✅ Recursos no usados eliminados  
✅ Código ofuscado  

**Tamaño estimado del APK**: 65-75 MB (vs 106 MB sin optimizar)

---

## 📲 Instalación en Celular

### Método 1: Cable USB

```bash
# Habilitar "Depuración USB" en el celular
# Configuración → Opciones de desarrollador → Depuración USB

# Conectar celular por USB

# Instalar APK
adb install sutodero-v1.0.0.apk
```

### Método 2: Transferencia Directa

1. Copia el APK al celular (por cable, Bluetooth, email, etc.)
2. En el celular, abre el archivo APK
3. Si aparece "Origen desconocido", permite la instalación
4. Sigue las instrucciones en pantalla

### Método 3: Link de Descarga

1. Sube el APK a:
   - Google Drive
   - Dropbox
   - WeTransfer
   - Firebase Hosting
   - GitHub Releases

2. Genera link público de descarga

3. Comparte el link con los usuarios

4. Los usuarios abren el link en el celular y descargan el APK

---

## ⚠️ Advertencias de Seguridad

Al instalar APKs fuera de Google Play, el celular mostrará advertencias:

1. **"Archivo potencialmente peligroso"**: Normal para APKs no publicados
2. **"Bloqueo de instalación"**: Toca "Más información" → "Instalar de todas formas"
3. **"Google Play Protect"**: Toca "Instalar de todas formas"

Estas advertencias son estándar para apps no publicadas en Play Store.

---

## 🐛 Solución de Problemas

### Error: "No se puede instalar"

**Causa**: Ya existe una versión instalada con firma diferente

**Solución**: Desinstala la versión anterior primero

### Error: "App no compatible"

**Causa**: Versión de Android muy antigua

**Solución**: La app requiere Android 5.0 (API 21) o superior

### Error: "Almacenamiento insuficiente"

**Causa**: No hay espacio en el celular

**Solución**: Libera al menos 200 MB de espacio

---

## 🎉 Después de Instalar

1. **Permisos**: La app solicitará permisos necesarios
   - Cámara ✓
   - Almacenamiento ✓
   - Ubicación ✓
   - Bluetooth ✓

2. **Primera ejecución**: Puede tardar unos segundos en iniciar

3. **Login**: Usa las credenciales de tu cuenta

4. **¡Listo!**: La app está lista para usar

---

## 📧 Soporte

**Email**: reparaciones.sycinmobiliaria@gmail.com  
**GitHub**: https://github.com/mauricioc21/sutodero

---

**Versión de documento**: 1.0  
**Fecha**: Noviembre 2024
