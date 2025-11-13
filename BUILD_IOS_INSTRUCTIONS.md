# 📱 Guía Completa de Build iOS para SU TODERO

## 🎯 Objetivo

Esta guía te ayudará a compilar la app **SU TODERO** para iPhone y iPad.

---

## 📋 Requisitos Previos

### Hardware:
- ✅ Mac con Apple Silicon (M1/M2/M3) o Intel
- ✅ iPhone o iPad (para testing en dispositivo real)
- ✅ Cable USB-C o Lightning

### Software:
- ✅ **macOS 12.0+** (Monterey o superior)
- ✅ **Xcode 14.0+** (gratis en App Store)
- ✅ **Flutter 3.35.4** (instalado y configurado)
- ✅ **CocoaPods** (para dependencias iOS)

### Cuenta Apple (opcional pero recomendado):
- ⚠️ **Apple ID gratuito**: Para testing en dispositivo personal (7 días)
- ✅ **Apple Developer Program** ($99/año): Para distribución y TestFlight

---

## 🚀 Guía Rápida (3 Pasos)

### Paso 1: Clonar el Repositorio

```bash
# Clonar desde GitHub
git clone https://github.com/mauricioc21/sutodero.git
cd sutodero

# O si ya lo tienes, actualiza
git pull origin main
```

### Paso 2: Configurar Firebase iOS

```bash
# 1. Ve a Firebase Console
open https://console.firebase.google.com/

# 2. Selecciona proyecto "su-todero"
# 3. Project Settings > iOS app > Add app
# 4. iOS bundle ID: sutodero.app
# 5. Descarga GoogleService-Info.plist
# 6. Reemplaza el archivo en ios/Runner/GoogleService-Info.plist
```

### Paso 3: Compilar

```bash
# Opción A: Simulador (no requiere firma)
./build_ios.sh simulator

# Opción B: Dispositivo físico
./build_ios.sh device

# Opción C: IPA para distribución
./build_ios.sh ipa
```

---

## 📖 Guía Detallada Paso a Paso

### 1️⃣ Instalar Flutter (si no lo tienes)

```bash
# Descargar Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Agregar a PATH (en ~/.zshrc o ~/.bash_profile)
export PATH="$PATH:$HOME/flutter/bin"

# Recargar shell
source ~/.zshrc

# Verificar instalación
flutter doctor -v
```

**Solucionar problemas con flutter doctor:**

```bash
# Si falta Xcode Command Line Tools
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Si falta CocoaPods
sudo gem install cocoapods

# Aceptar licencias de Xcode
sudo xcodebuild -license accept
```

---

### 2️⃣ Configurar Firebase para iOS

#### A. Crear App iOS en Firebase Console

1. **Abrir Firebase Console:**
   ```
   https://console.firebase.google.com/
   ```

2. **Seleccionar proyecto:** `su-todero`

3. **Ir a Project Settings** (ícono engranaje)

4. **Scroll hasta "Your apps"**

5. **Click en ícono iOS** (o "Add app" si no existe)

6. **Completar formulario:**
   - **iOS bundle ID:** `sutodero.app`
   - **App nickname:** `SU TODERO iOS`
   - **App Store ID:** (dejar vacío por ahora)

7. **Click "Register app"**

8. **Descargar `GoogleService-Info.plist`**

#### B. Instalar el Archivo en el Proyecto

```bash
# Opción 1: Mover el archivo descargado
mv ~/Downloads/GoogleService-Info.plist ios/Runner/

# Opción 2: O copiar si quieres mantener el original
cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

#### C. Verificar la Instalación

```bash
# El archivo debe existir y tener contenido real
cat ios/Runner/GoogleService-Info.plist | grep "GOOGLE_APP_ID"

# Debe mostrar algo como:
# <string>1:292635586927:ios:abc123def456</string>
```

---

### 3️⃣ Compilar para Simulador iOS

**Ventajas:**
- ✅ No requiere dispositivo físico
- ✅ No requiere Apple Developer Account
- ✅ No requiere certificados de firma
- ✅ Rápido para testing y desarrollo

**Pasos:**

```bash
# 1. Ejecutar script de build
./build_ios.sh simulator

# 2. Abrir Xcode
open ios/Runner.xcworkspace

# 3. En Xcode:
#    - Selecciona un simulador (iPhone 14 Pro, iPad Air, etc.)
#    - Presiona Cmd+R o click en el botón ▶️ Play

# 4. Espera a que el simulador inicie y la app se instale
```

**Simuladores disponibles:**

```bash
# Listar simuladores disponibles
xcrun simctl list devices available

# Crear un simulador nuevo (si necesitas)
xcrun simctl create "iPhone 14 Pro" "iPhone 14 Pro" iOS16.4
```

---

### 4️⃣ Compilar para Dispositivo Físico

**Requisitos adicionales:**
- ⚠️ Apple ID (gratuito o Developer Program)
- ⚠️ Dispositivo iOS con modo desarrollador activado

#### A. Preparar el Dispositivo

```bash
# 1. Conectar iPhone/iPad con cable USB

# 2. En el dispositivo iOS:
#    Ajustes > Privacidad y Seguridad > Modo Desarrollador > ON
#    (Requiere reiniciar el dispositivo)

# 3. Confiar en esta computadora
#    (Aparecerá un popup en el dispositivo)

# 4. Verificar que Flutter detecta el dispositivo
flutter devices

# Deberías ver algo como:
# iPhone de Mauricio (mobile) • 00008110-xxxxxxxxxxxx • ios • iOS 17.0
```

#### B. Configurar Firma en Xcode

```bash
# 1. Abrir proyecto en Xcode
open ios/Runner.xcworkspace

# 2. En el Project Navigator (barra izquierda):
#    Click en "Runner" (el ícono azul)

# 3. En el panel central:
#    - Selecciona el TARGET "Runner" (no el PROJECT)
#    - Ve a la tab "Signing & Capabilities"

# 4. Configurar Team:
#    - Marca "Automatically manage signing"
#    - En "Team", selecciona tu Apple ID
#      (Si no aparece, click "Add Account" y agrega tu Apple ID)

# 5. Bundle Identifier:
#    - Déjalo como: sutodero.app
#    - O cámbialo a: com.tunombre.sutodero (si quieres personalizarlo)
```

#### C. Compilar e Instalar

**Opción 1: Desde el Script**

```bash
./build_ios.sh device
```

**Opción 2: Desde Xcode**

```bash
# 1. En Xcode, selecciona tu dispositivo en la barra superior
#    (junto al botón Play)

# 2. Presiona Cmd+R o click en el botón ▶️ Play

# 3. Primera instalación:
#    - En el dispositivo iOS, ve a:
#      Ajustes > General > Gestión de dispositivos > [Tu Apple ID]
#    - Toca "Confiar en [Tu Apple ID]"

# 4. Vuelve a ejecutar (Cmd+R en Xcode)
```

---

### 5️⃣ Generar IPA para Distribución

**Para qué sirve el IPA:**
- 📦 Subir a TestFlight (beta testing)
- 🍎 Subir a App Store (producción)
- 📱 Distribución Ad-Hoc (dispositivos específicos)

#### A. Configurar Signing para Release

```bash
# 1. Abrir Xcode
open ios/Runner.xcworkspace

# 2. Seleccionar TARGET "Runner" > "Signing & Capabilities"

# 3. Pestaña "Release":
#    - Team: Tu Apple Developer Account ($99/año requerido)
#    - Provisioning Profile: "Xcode Managed Profile"
#    - Signing Certificate: "Apple Distribution"

# 4. Si no tienes certificado de distribución:
#    - Ve a developer.apple.com > Certificates
#    - Crear "iOS Distribution Certificate"
```

#### B. Generar el IPA

```bash
# Opción 1: Con el script
./build_ios.sh ipa

# Opción 2: Comando Flutter directo
flutter build ipa --release

# El IPA se genera en:
# build/ios/ipa/sutodero.ipa
```

#### C. Validar el IPA

```bash
# Verificar que el IPA fue creado correctamente
ls -lh build/ios/ipa/sutodero.ipa

# Extraer información del IPA
unzip -l build/ios/ipa/sutodero.ipa | head -20
```

---

### 6️⃣ Subir a TestFlight

**TestFlight permite:**
- ✅ Distribuir la app a hasta 10,000 testers externos
- ✅ Testing antes de lanzar en App Store
- ✅ Feedback automático de usuarios

#### A. Subir el IPA

**Opción 1: Xcode (Recomendado)**

```bash
# 1. Abrir Xcode
open ios/Runner.xcworkspace

# 2. Menú: Product > Archive
#    (Tarda varios minutos)

# 3. Cuando termine, se abre "Organizer"

# 4. Click en "Distribute App"

# 5. Selecciona "TestFlight & App Store"

# 6. Siguiente > Upload

# 7. Espera a que termine el upload
```

**Opción 2: Transporter App**

```bash
# 1. Abrir App Store en tu Mac
# 2. Buscar "Transporter" y descargar
# 3. Abrir Transporter
# 4. Arrastra build/ios/ipa/sutodero.ipa
# 5. Click "Deliver"
```

#### B. Configurar en App Store Connect

```bash
# 1. Ve a App Store Connect
open https://appstoreconnect.apple.com/

# 2. My Apps > SU TODERO (o crear nueva app)

# 3. TestFlight tab

# 4. Sección "Builds":
#    - Espera a que aparezca tu build (5-10 minutos)
#    - Completa "Export Compliance" (si aparece)

# 5. Sección "Internal Testing" o "External Testing":
#    - Agregar grupo de testers
#    - Agregar emails de testers
#    - Activar el build para ese grupo

# 6. Los testers recibirán un email con link de TestFlight
```

---

## 🔧 Solución de Problemas Comunes

### ❌ Error: "Unable to boot simulator"

**Solución:**

```bash
# Reiniciar servicio de simulador
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# O reiniciar el simulador específico
xcrun simctl shutdown all
xcrun simctl boot "iPhone 14 Pro"
```

### ❌ Error: "Signing for Runner requires a development team"

**Solución:**

```bash
# Abrir Xcode
open ios/Runner.xcworkspace

# Signing & Capabilities:
# 1. Marca "Automatically manage signing"
# 2. Selecciona tu Team (Apple ID)
# 3. Si no aparece, agrega tu Apple ID:
#    Xcode > Preferences > Accounts > Add (+)
```

### ❌ Error: "No provisioning profile found"

**Solución:**

```bash
# 1. Ve a developer.apple.com
# 2. Certificates, Identifiers & Profiles
# 3. Profiles > + (Create new)
# 4. Selecciona tipo (Development o Distribution)
# 5. Selecciona App ID: sutodero.app
# 6. Selecciona Devices (para Development)
# 7. Download el perfil
# 8. Doble-click para instalar
```

### ❌ Error: "Pod install failed"

**Solución:**

```bash
# Limpiar cache de CocoaPods
cd ios
rm -rf Pods
rm Podfile.lock
rm -rf ~/.cocoapods/repos/cocoapods/

# Reinstalar
pod install --repo-update

# Si sigue fallando, actualiza CocoaPods
sudo gem update cocoapods
```

### ❌ Error: "GoogleService-Info.plist not found"

**Solución:**

```bash
# Verificar que el archivo existe
ls -la ios/Runner/GoogleService-Info.plist

# Si no existe, descarga de Firebase Console:
open https://console.firebase.google.com/

# Proyecto > Settings > iOS app > Download config file
```

### ❌ Error: "Firebase module not found"

**Solución:**

```bash
# Reinstalar pods
cd ios
rm -rf Pods
pod install

# Verificar que Podfile tiene Firebase
cat Podfile | grep Firebase

# Si no está, agrégalo y reinstala
```

---

## 📊 Comparación de Opciones

| Opción | Requiere | Costo | Distribución | Testing |
|--------|----------|-------|--------------|---------|
| **Simulador** | Solo Mac | Gratis | Solo desarrollo | Funcional |
| **Dispositivo (Apple ID)** | Mac + iPhone | Gratis | 7 días | Completo |
| **TestFlight** | Mac + Dev Account | $99/año | 10,000 users | Completo |
| **App Store** | Mac + Dev Account | $99/año | Ilimitado | Completo |

---

## 🎯 Checklist Completo

### Antes de Compilar:
- [ ] Flutter 3.35.4 instalado
- [ ] Xcode 14.0+ instalado
- [ ] CocoaPods instalado
- [ ] Repositorio clonado
- [ ] GoogleService-Info.plist configurado

### Para Simulador:
- [ ] Ejecutar `./build_ios.sh simulator`
- [ ] Abrir Xcode
- [ ] Seleccionar simulador
- [ ] Cmd+R para ejecutar

### Para Dispositivo:
- [ ] Dispositivo conectado con USB
- [ ] Modo desarrollador activado
- [ ] Confianza en computadora establecida
- [ ] Apple ID configurado en Xcode
- [ ] Firma automática activada
- [ ] Ejecutar `./build_ios.sh device`

### Para TestFlight:
- [ ] Apple Developer Account ($99/año)
- [ ] Certificado de distribución creado
- [ ] Provisioning profile configurado
- [ ] Ejecutar `./build_ios.sh ipa`
- [ ] Subir a App Store Connect
- [ ] Configurar grupo de testers
- [ ] Enviar invitaciones

---

## 📞 Soporte y Recursos

### Documentación Oficial:
- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [TestFlight Guide](https://developer.apple.com/testflight/)

### Comandos Útiles:

```bash
# Ver logs en tiempo real
flutter logs

# Ver dispositivos conectados
flutter devices

# Información de Flutter
flutter doctor -v

# Ver simuladores disponibles
xcrun simctl list devices

# Limpiar todo y empezar de nuevo
flutter clean
cd ios && rm -rf Pods && pod install && cd ..
```

---

## ✅ Resultado Final

Cuando completes estos pasos, tendrás:

✅ App funcionando en iPhone/iPad
✅ Versión en TestFlight para beta testers
✅ Lista para enviar a App Store
✅ Firebase configurado y funcionando
✅ Todos los permisos iOS configurados

---

**¿Necesitas ayuda?** Abre un issue en GitHub:
https://github.com/mauricioc21/sutodero/issues
