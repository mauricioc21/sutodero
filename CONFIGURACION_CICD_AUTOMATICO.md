# 🚀 Configuración de CI/CD Automático - SU TODERO

## 🎯 Objetivo

**Compilar automáticamente iOS y Android en la nube SIN tocar tu Mac.**

Todo se hace desde el navegador web. Codemagic compila tu app automáticamente cada vez que hagas push a GitHub.

---

## ✨ Lo Que Obtendrás

Después de seguir esta guía:

✅ **Compilación automática** cada vez que hagas push a GitHub  
✅ **IPA para iOS** listo para TestFlight/App Store  
✅ **APK para Android** listo para instalar  
✅ **AAB para Android** listo para Google Play Store  
✅ **Notificaciones por email** cuando termine cada build  
✅ **Distribución automática** a TestFlight (beta testing iOS)

---

## 📋 Requisitos Previos

### Para iOS:
- [ ] **Apple Developer Account** ($99/año)
  - Crear en: https://developer.apple.com/programs/enroll/
- [ ] **App ID registrado** en Apple Developer Portal
- [ ] **Certificados de distribución** (Codemagic los puede crear automáticamente)

### Para Android:
- [ ] **Google Play Console** (opcional, $25 único)
  - Crear en: https://play.google.com/console/signup
- [ ] **Keystore para firma** (yo lo creo para ti si no lo tienes)

### General:
- [ ] **Cuenta GitHub** (ya la tienes)
- [ ] **Cuenta Codemagic** (gratis para empezar)
  - Crear en: https://codemagic.io/signup

---

## 🔧 PASO 1: Configurar Codemagic

### 1.1 Crear Cuenta en Codemagic

```
1. Ve a: https://codemagic.io/signup
2. Click en "Sign up with GitHub"
3. Autoriza a Codemagic acceso a tu cuenta GitHub
4. Confirma tu email
```

### 1.2 Conectar Repositorio

```
1. En Codemagic, click en "Add application"
2. Selecciona "GitHub"
3. Busca y selecciona: mauricioc21/sutodero
4. Click en "Finish: Add application"
```

### 1.3 Configurar Workflow

```
1. En la app, ve a "Start your first build"
2. Codemagic detectará automáticamente el archivo codemagic.yaml
3. Verás 3 workflows disponibles:
   - 🍎 iOS Build & Deploy
   - 🤖 Android Build & Deploy
   - 🌐 Web Build & Deploy
```

---

## 🍎 PASO 2: Configurar iOS (Apple)

### 2.1 Obtener Credenciales de Apple

#### A. Team ID

```
1. Ve a: https://developer.apple.com/account
2. Login con tu Apple ID
3. En la página principal, verás "Team ID: XXXXXXXXXX"
4. Copia ese Team ID (son 10 caracteres)
```

#### B. App Store Connect API Key

```
1. Ve a: https://appstoreconnect.apple.com/access/api
2. Click en el botón "+" para crear una nueva key
3. Nombre: "Codemagic CI"
4. Acceso: "Developer"
5. Click en "Generate"
6. DESCARGA el archivo .p8 (solo lo puedes descargar 1 vez)
7. Anota el Key ID y el Issuer ID
```

### 2.2 Agregar Credenciales en Codemagic

```
1. En Codemagic, ve a tu app > Settings > Environment variables
2. Click en "Add group"
3. Nombre del grupo: "app_store_credentials"
4. Agrega estas variables:

   Variable: CERTIFICATE_PRIVATE_KEY
   Value: [Pega el contenido del .p8 file]
   Secure: ✅ Sí
   Group: app_store_credentials

   Variable: APP_STORE_CONNECT_KEY_IDENTIFIER
   Value: [Tu Key ID]
   Secure: ✅ Sí
   Group: app_store_credentials

   Variable: APP_STORE_CONNECT_ISSUER_ID
   Value: [Tu Issuer ID]
   Secure: ✅ Sí
   Group: app_store_credentials

   Variable: APP_STORE_CONNECT_PRIVATE_KEY
   Value: [Contenido completo del archivo .p8]
   Secure: ✅ Sí
   Group: app_store_credentials

5. Click en "Save"
```

### 2.3 Configurar Code Signing (Firma de Código)

**Opción A: Automático (Recomendado)**

```
1. En Codemagic, ve a Settings > Code signing identities
2. Click en "iOS code signing"
3. Selecciona "Automatic code signing"
4. Ingresa tu Apple Developer Team ID
5. Codemagic creará automáticamente certificados y profiles
```

**Opción B: Manual (Si prefieres control total)**

```
1. Descarga certificados desde Apple Developer Portal
2. Sube .p12 file y mobile provisioning profiles a Codemagic
3. Configura password del certificado
```

### 2.4 Actualizar ExportOptions.plist

```
1. Edita el archivo: ios/ExportOptions.plist
2. Reemplaza YOUR_TEAM_ID con tu Team ID real
3. Commit y push:
   git add ios/ExportOptions.plist
   git commit -m "feat: configurar Team ID para iOS"
   git push origin main
```

---

## 🤖 PASO 3: Configurar Android (Google Play)

### 3.1 Crear Keystore (Firma de App)

**YO LO HAGO POR TI:**

Si no tienes un keystore, yo creo uno automáticamente. Solo dime:
- Nombre de tu empresa/app
- Tu email
- Tu ciudad/país

**O si prefieres hacerlo tú:**

```bash
# En tu Mac (solo una vez):
keytool -genkey -v -keystore sutodero-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sutodero

# Te pedirá password (anótalo bien!)
```

### 3.2 Configurar Keystore en Codemagic

```
1. En Codemagic, ve a Settings > Code signing identities
2. Click en "Android code signing"
3. Upload keystore file (.jks)
4. Ingresa:
   - Keystore password
   - Key alias: sutodero
   - Key password
5. Save
```

### 3.3 Configurar Google Play (Opcional)

**Para distribución automática a Google Play Store:**

```
1. Ve a: https://play.google.com/console
2. Settings > API access
3. Create new service account
4. Download JSON key
5. En Codemagic, agrega variable:
   - GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
   - Value: [Contenido del JSON]
   - Secure: ✅ Sí
```

---

## 🎮 PASO 4: Ejecutar Tu Primer Build

### 4.1 Build Manual (Para probar)

```
1. En Codemagic, ve a tu app
2. Click en "Start new build"
3. Selecciona workflow:
   - iOS Build & Deploy (para iPhone)
   - Android Build & Deploy (para Android)
   - Web Build & Deploy (para web)
4. Click en "Start new build"
5. Espera 15-30 minutos
6. Recibirás email cuando termine
```

### 4.2 Build Automático (Cada push)

```
Ya está configurado! Cada vez que hagas:

git push origin main

Se dispararán automáticamente los builds de iOS y Android.
```

---

## 📊 Monitorear Tus Builds

### Ver Estado en Tiempo Real

```
1. Ve a: https://codemagic.io/apps
2. Click en "sutodero"
3. Verás lista de builds con estados:
   - 🟢 Success
   - 🔴 Failed
   - 🟡 In progress
   - ⚪ Queued
```

### Descargar Artefactos

```
1. Click en un build exitoso
2. Ve a la sección "Artifacts"
3. Descarga:
   - iOS: build/ios/ipa/sutodero.ipa
   - Android: 
     - APK: build/app/outputs/flutter-apk/*.apk
     - AAB: build/app/outputs/bundle/release/*.aab
```

---

## 📱 PASO 5: Instalar App en Dispositivos

### 🍎 iOS - Instalar en iPhone

**Opción A: TestFlight (Recomendado)**

```
1. La app se sube automáticamente a TestFlight
2. Ve a: https://appstoreconnect.apple.com
3. My Apps > SU TODERO > TestFlight
4. Agrega testers (emails)
5. Los testers reciben link para instalar
6. Instalan "TestFlight" app desde App Store
7. Abren el link y descargan SU TODERO
```

**Opción B: Download directo desde Codemagic**

```
1. En Codemagic, descarga el .ipa
2. Envía el archivo por email/AirDrop a tu iPhone
3. En el iPhone:
   - Abre Archivos app
   - Toca el .ipa
   - Se instalará automáticamente
```

### 🤖 Android - Instalar APK

**Opción A: Download directo**

```
1. En Codemagic, descarga el APK
2. Envía el APK a tu Android (email, WhatsApp, etc.)
3. En el Android:
   - Abre el archivo APK
   - Permite "Instalar apps de fuentes desconocidas"
   - Instala la app
```

**Opción B: Google Play (Internal Testing)**

```
1. Sube el AAB a Google Play Console
2. Configura "Internal Testing" track
3. Agrega testers
4. Envía link de testing
5. Instalan desde Play Store
```

---

## 🔄 Flujo de Trabajo Diario

### Desarrollo Normal

```bash
# 1. Haces cambios en tu código localmente

# 2. Commit tus cambios
git add .
git commit -m "feat: nueva funcionalidad"

# 3. Push a GitHub
git push origin main

# 4. Codemagic compila automáticamente
#    - iOS build (15-20 min)
#    - Android build (10-15 min)
#    - Web build (5-10 min)

# 5. Recibes email con resultados

# 6. Si exitoso, la app se sube a:
#    - iOS: TestFlight
#    - Android: Artifacts (o Google Play si configuraste)

# 7. Testers reciben actualización automáticamente
```

### Solo Quieres Compilar Sin Deploy

```
1. Ve a Codemagic
2. Edita workflow
3. Desactiva "Publishing" section
4. Solo generará artifacts sin distribuir
```

---

## 🎯 Versiones y Builds

### Incrementar Versión

```yaml
# En pubspec.yaml:
version: 1.0.0+1
         ↑     ↑
         |     |
    Version  Build Number

# Ejemplos:
version: 1.0.0+1  # Primera versión
version: 1.0.1+2  # Bug fix
version: 1.1.0+3  # Nueva feature
version: 2.0.0+4  # Major release
```

### Build Number Automático

```
Codemagic incrementa automáticamente el build number usando:
$BUILD_NUMBER

Cada build tiene un número único.
```

---

## 🐛 Solución de Problemas

### ❌ Error: "No code signing identities found"

**Solución:**
```
1. Ve a Codemagic > Settings > Code signing
2. Configura certificados iOS
3. Verifica que el Team ID sea correcto
```

### ❌ Error: "Bundle identifier not found"

**Solución:**
```
1. Verifica que el Bundle ID coincida:
   - ios/Runner.xcodeproj/project.pbxproj
   - Debe ser: sutodero.app
2. Registra el Bundle ID en Apple Developer Portal:
   - https://developer.apple.com/account
   - Identifiers > App IDs > Register a new identifier
```

### ❌ Error: "Provisioning profile doesn't match"

**Solución:**
```
1. En Codemagic, usa "Automatic code signing"
2. O descarga nuevos provisioning profiles desde Apple
3. Sube a Codemagic manualmente
```

### ❌ Error: Android keystore not found

**Solución:**
```
1. Crea un keystore (ver PASO 3.1)
2. Súbelo a Codemagic Code signing
3. Verifica passwords
```

### ❌ Build muy lento

**Causas comunes:**
```
- CocoaPods cache
- Flutter pub cache
- Xcode indexing

Solución: Click en "Re-run build" con "Clean build" checked
```

---

## 📧 Notificaciones

### Configurar Emails

```
Ya está configurado en codemagic.yaml:

recipients:
  - mauricioc21@gmail.com
  - info@c21sutodero.com

Recibirás emails para:
✅ Build exitoso
❌ Build fallido
```

### Agregar Slack/Discord (Opcional)

```
1. En Codemagic, ve a Settings > Integrations
2. Conecta Slack o Discord
3. Selecciona canal para notificaciones
4. Recibirás mensajes en tiempo real
```

---

## 💰 Costos

### Codemagic

```
Plan Free:
- 500 minutos/mes
- 1 concurrent build
- Suficiente para empezar

Plan Pro ($30/mes):
- 4,000 minutos/mes
- 3 concurrent builds
- Recomendado para producción
```

### Apple

```
- Apple Developer: $99/año
- Necesario para TestFlight y App Store
```

### Google

```
- Google Play Console: $25 único
- Opcional (puedes distribuir APKs directamente)
```

---

## 🎉 Resultado Final

Después de configurar todo:

✅ **Push a GitHub** → Builds automáticos iOS + Android  
✅ **15-30 min después** → Recibes email con apps listas  
✅ **iOS en TestFlight** → Testers pueden instalar  
✅ **Android APK listo** → Instalar en cualquier dispositivo  
✅ **Sin tocar tu Mac** → Todo en la nube  

---

## 🔗 Links Importantes

- **Codemagic**: https://codemagic.io
- **Apple Developer**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **Google Play Console**: https://play.google.com/console
- **GitHub Repo**: https://github.com/mauricioc21/sutodero

---

## 📞 Soporte

Si tienes problemas:

1. **Revisa logs en Codemagic**: Cada build tiene logs detallados
2. **Documentación**: https://docs.codemagic.io
3. **Pregúntame**: Estoy aquí para ayudarte

---

## ✅ Checklist de Configuración

### Configuración Inicial (Una sola vez)

- [ ] Cuenta Codemagic creada
- [ ] Repositorio conectado
- [ ] Apple Developer Account ($99/año)
- [ ] Team ID obtenido
- [ ] App Store Connect API key creada
- [ ] Credenciales agregadas a Codemagic
- [ ] Code signing configurado (iOS)
- [ ] Keystore creado (Android)
- [ ] Keystore subido a Codemagic
- [ ] ExportOptions.plist actualizado
- [ ] Primer build manual exitoso

### Cada Release

- [ ] Actualizar version en pubspec.yaml
- [ ] Commit cambios
- [ ] Push a GitHub
- [ ] Monitorear build en Codemagic
- [ ] Descargar artifacts (si es necesario)
- [ ] Probar en TestFlight/dispositivos
- [ ] Distribuir a testers

---

**🚀 ¡Listo! Tu pipeline de CI/CD está configurado para trabajar automáticamente!**
