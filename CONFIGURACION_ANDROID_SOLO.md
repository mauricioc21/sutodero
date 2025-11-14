# 🤖 Configuración Android CI/CD - SU TODERO

## 🎯 Plan: Solo Android Automático (Gratis)

Vamos a configurar compilación automática **solo para Android**. iOS lo haremos después cuando te inscribas en Apple Developer.

---

## ✅ Lo Que Tendrás

### Con Esta Configuración:

✅ **Cada push a GitHub** → APK compilado automáticamente  
✅ **3 tipos de APK** generados (universal + optimizados)  
✅ **App Bundle (AAB)** listo para Google Play  
✅ **Notificaciones por email** cuando termine  
✅ **Descarga directa** de APKs desde Codemagic  
✅ **100% GRATIS** (sin costos de Apple Developer)  

### iOS Por Ahora:

⏳ **Compilación manual** en tu Mac cuando necesites  
⏳ **Scripts listos** para compilar fácilmente  
⏳ **Cuando pagues Apple** ($99/año), activamos CI/CD  

---

## 🔑 PASO 1: Crear Keystore Android (5 minutos)

El keystore es necesario para firmar tus APKs. Lo necesitas **una sola vez**.

### Opción A: Yo lo Creo por Ti (Recomendado)

**Dame esta información:**
```
Nombre de tu empresa/app: SU TODERO
Tu nombre completo: [tu nombre]
Email: [tu email]
Ciudad: [tu ciudad]
País: Colombia (o el tuyo)
```

Y yo genero el keystore con todos los datos correctos.

### Opción B: Créalo Tú Mismo

En tu Mac, ejecuta:

```bash
cd ~/Desktop/sutodero
keytool -genkey -v -keystore sutodero-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sutodero

# Te preguntará:
# - Password del keystore: [elige uno seguro, ANÓTALO]
# - Nombre y apellido: Tu nombre
# - Organización: SU TODERO
# - Ciudad: Tu ciudad
# - Estado: Tu estado/departamento
# - País: CO
# - Password del alias: [mismo que antes, ANÓTALO]
```

**⚠️ IMPORTANTE:** Guarda estos datos en un lugar seguro:
- Password del keystore
- Archivo `sutodero-release.jks`
- Si los pierdes, NO podrás actualizar la app en Google Play

---

## 🚀 PASO 2: Configurar Codemagic (10 minutos)

### 2.1 Crear Cuenta (2 minutos)

1. Ve a: **https://codemagic.io/signup**
2. Click en **"Sign up with GitHub"**
3. Autoriza a Codemagic acceso a tu GitHub
4. Confirma tu email

### 2.2 Conectar Repositorio (2 minutos)

1. En Codemagic, click en **"Add application"**
2. Selecciona **"GitHub"**
3. Busca y selecciona: **mauricioc21/sutodero**
4. Click en **"Finish: Add application"**

### 2.3 Configurar Keystore (5 minutos)

1. En Codemagic, ve a tu app
2. Click en **"Settings"** (engranaje arriba derecha)
3. En el menú lateral: **"Code signing identities"**
4. Sección **"Android"**, click en **"Upload keystore"**

5. **Sube tu archivo:**
   - Click en "Upload keystore file"
   - Selecciona `sutodero-release.jks`

6. **Completa los datos:**
   ```
   Keystore password: [el password que elegiste]
   Key alias: sutodero
   Key password: [mismo password]
   ```

7. Click en **"Save"**

### 2.4 Configurar Workflow Android (1 minuto)

1. En tu app de Codemagic, ve a la pestaña **"Workflows"**
2. Verás el workflow **"🤖 Android Build & Deploy"**
3. Click en el switch para **activarlo**
4. Asegúrate que diga **"Enabled"**

---

## ✨ PASO 3: Primer Build Automático (5 minutos)

### Opción A: Build Manual para Probar

1. En Codemagic, click en **"Start new build"**
2. Selecciona workflow: **"Android Build & Deploy"**
3. Branch: **main**
4. Click en **"Start new build"**
5. Espera 10-15 minutos
6. Recibirás email cuando termine

### Opción B: Trigger Automático con Push

1. Haz cualquier cambio en tu código
2. Commit y push:
   ```bash
   cd ~/Desktop/sutodero
   git add .
   git commit -m "test: probar CI/CD Android"
   git push origin main
   ```
3. Codemagic detecta el push automáticamente
4. Compila Android
5. Recibes email con resultado

---

## 📱 PASO 4: Descargar e Instalar APK (2 minutos)

### Después del Build Exitoso:

1. En Codemagic, click en el build completado
2. Ve a la sección **"Artifacts"**
3. Verás varios APKs disponibles:

```
📦 app-release.apk (Universal - ~25MB)
   ↪ Funciona en todos los Android

📦 app-armeabi-v7a-release.apk (~15MB)
   ↪ Para Android viejos (32-bit)

📦 app-arm64-v8a-release.apk (~15MB) ⭐ MÁS COMÚN
   ↪ Para Android modernos (64-bit)

📦 app-x86_64-release.apk (~15MB)
   ↪ Para emuladores y tablets Intel

📦 app-release.aab (App Bundle)
   ↪ Para subir a Google Play Store
```

4. **Descarga** el que necesites (recomiendo el universal o arm64-v8a)

### Instalar en Android:

**Método 1: Desde tu Mac**
```bash
# Conecta Android con cable USB
# Activa "Depuración USB" en el teléfono

adb install app-release.apk
```

**Método 2: Compartir APK**
1. Envía el APK por WhatsApp/Email a tu Android
2. Abre el archivo en tu teléfono
3. Si pregunta "Fuentes desconocidas", permite
4. Toca "Instalar"
5. ¡Listo!

---

## 🔄 Uso Diario

### Cada Vez que Quieras Actualizar:

```bash
# 1. Cambias código en tu Mac
cd ~/Desktop/sutodero
code .  # O tu editor preferido

# 2. Pruebas localmente (opcional)
flutter run

# 3. Commit y push
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main

# 4. ☕ Espera 10-15 minutos

# 5. Recibes email de Codemagic

# 6. Descargas nuevo APK

# 7. Distribuyes a usuarios
```

**¡Sin tocar configuraciones! Todo automático.**

---

## 📊 Monitoreo de Builds

### Ver Estado en Tiempo Real:

1. Ve a: **https://codemagic.io/apps**
2. Click en **"sutodero"**
3. Verás lista de builds:
   - 🟢 **Success** → Todo bien
   - 🔴 **Failed** → Hubo error (revisa logs)
   - 🟡 **In progress** → Compilando...
   - ⚪ **Queued** → Esperando turno

### Notificaciones por Email:

Configuradas para:
- ✉️ mauricioc21@gmail.com
- ✉️ info@c21sutodero.com

Recibes email para:
- ✅ Build exitoso con link de descarga
- ❌ Build fallido con detalles del error

---

## 💰 Costos

### Con Esta Configuración:

```
Codemagic Free Plan:
- 500 minutos/mes GRATIS
- ~30-40 builds Android/mes
- 1 build simultáneo

Android Development:
- $0 (completamente gratis)
- No necesitas pagar nada

Google Play Console (OPCIONAL):
- $25 USD pago único
- Solo si quieres publicar en Play Store
- Puedes distribuir APKs sin esto
```

**Total: $0/mes** 🎉

### Cuando Agregues iOS:

```
Apple Developer Program:
- $99 USD/año
- Necesario para App Store y TestFlight

Codemagic Pro (opcional):
- $30/mes
- Más minutos y builds simultáneos
```

---

## 🐛 Solución de Problemas

### ❌ Error: "Keystore not found"

**Solución:**
1. Ve a Codemagic → Settings → Code signing
2. Verifica que el keystore esté subido
3. Revisa passwords (distinguen mayúsculas/minúsculas)

### ❌ Error: "Build failed: Gradle"

**Solución:**
1. Revisa logs en Codemagic
2. Busca línea con "ERROR"
3. Usualmente es problema de dependencias
4. Prueba compilar localmente primero: `flutter build apk`

### ❌ Error: "App not installing"

**Solución:**
1. En Android: Ajustes → Seguridad
2. Activa "Fuentes desconocidas" o "Instalar apps desconocidas"
3. Intenta de nuevo

### ❌ Error: "Certificate expired"

**Solución:**
- Apps firmadas con Apple ID gratis expiran en 7 días
- No aplica para Android (nunca expiran)
- Solo reinstala si usas iOS sin Developer Account

---

## 🎯 Roadmap

### ✅ AHORA (Gratis)
- Android CI/CD automático
- Distribución de APKs
- Workflow optimizado

### ⏳ DESPUÉS (Cuando pagues Apple)
- iOS CI/CD automático
- TestFlight para beta testing
- App Store distribution
- Compilación simultánea iOS + Android

---

## 📞 ¿Necesitas Ayuda?

**Estoy aquí para:**
- ✅ Crear el keystore Android
- ✅ Configurar Codemagic paso a paso
- ✅ Resolver errores de build
- ✅ Optimizar configuración
- ✅ Lo que necesites

**Solo pregúntame y lo resuelvo.**

---

## ✅ Checklist de Configuración

Completa estos pasos:

- [ ] Keystore Android creado
- [ ] Password del keystore anotado (SEGURO)
- [ ] Cuenta Codemagic creada
- [ ] Repositorio conectado
- [ ] Keystore subido a Codemagic
- [ ] Workflow Android activado
- [ ] Primer build manual exitoso
- [ ] APK descargado e instalado
- [ ] ¡Todo funcionando!

---

## 🚀 Próximos Pasos

1. **Crea el keystore** (o dame los datos para crearlo)
2. **Configura Codemagic** (siguiendo esta guía)
3. **Primer build** manual para probar
4. **Workflow automático** activo
5. **Distribuye tu app** 🎉

---

**¿Listo para empezar? Dame los datos para el keystore o dime si prefieres crearlo tú.**
