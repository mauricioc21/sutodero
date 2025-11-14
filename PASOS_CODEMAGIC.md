# 🚀 Configurar Codemagic - Guía Paso a Paso

## ✅ Keystore Ya Creado

Ya tienes el keystore listo:
- ✅ Archivo: `sutodero-release.jks`
- ✅ Password: `Perro2011`
- ✅ Alias: `sutodero`

---

## 📋 PASO 1: Descargar Keystore a Tu Mac (2 minutos)

```bash
# En tu Mac, abre Terminal y ejecuta:
cd ~/Desktop/sutodero
git pull origin main
```

Verifica que el archivo esté ahí:
```bash
ls -lh sutodero-release.jks
# Deberías ver: -rw-r--r--  1 tu_usuario  staff   2.8K Nov 14 ... sutodero-release.jks
```

---

## 🔐 PASO 2: Crear Cuenta en Codemagic (3 minutos)

### 2.1 Abrir Codemagic

1. Ve a: **https://codemagic.io/signup**
2. Verás la página de registro

### 2.2 Registrarte con GitHub

1. Click en el botón grande **"Sign up with GitHub"**
2. Si no estás logueado en GitHub, ingresa tus credenciales
3. GitHub te pedirá autorizar a Codemagic
4. Click en **"Authorize codemagic-io"**
5. Espera unos segundos

### 2.3 Confirmar Email (si es necesario)

1. Revisa tu email (mauricio@parchefilms.com)
2. Si recibiste email de confirmación, haz click en el link
3. Si no, puedes continuar de todos modos

✅ **¡Cuenta creada!**

---

## 📦 PASO 3: Conectar Repositorio (2 minutos)

### 3.1 Agregar Aplicación

1. En Codemagic, verás un botón **"Add application"**
2. Click en ese botón
3. Te preguntará qué plataforma: Selecciona **"GitHub"**

### 3.2 Seleccionar Repositorio

1. Verás lista de tus repositorios
2. Busca: **"mauricioc21/sutodero"**
3. Click en ese repositorio
4. Click en **"Finish: Add application"**

### 3.3 Configuración Inicial

1. Codemagic detectará automáticamente que tienes `codemagic.yaml`
2. Verás mensaje: "Configuration found"
3. Click en **"Start your first build"** (NO lo ejecutes aún)

✅ **¡Repositorio conectado!**

---

## 🔑 PASO 4: Subir Keystore (5 minutos)

### 4.1 Ir a Settings

1. En tu app de Codemagic, arriba derecha verás un ícono de **engranaje ⚙️**
2. Click en ese ícono (Settings)
3. O ve directamente a la URL que te aparece

### 4.2 Code Signing Identities

1. En el menú lateral izquierdo, busca **"Code signing identities"**
2. Click ahí
3. Verás secciones para iOS, Android, etc.

### 4.3 Configurar Android

1. Busca la sección **"Android code signing"**
2. Verás un botón **"Upload keystore"**
3. Click en ese botón

### 4.4 Subir Archivo

1. Se abrirá un diálogo para seleccionar archivo
2. Navega a: `~/Desktop/sutodero/sutodero-release.jks`
3. Selecciona el archivo
4. Click en **"Open"**

### 4.5 Completar Datos

Ahora verás un formulario. Completa exactamente así:

```
Keystore password: Perro2011
Key alias: sutodero
Key password: Perro2011
```

⚠️ **IMPORTANTE**: 
- Copia y pega el password exactamente como está
- No agregues espacios extras
- Es case-sensitive (distingue mayúsculas/minúsculas)

### 4.6 Guardar

1. Click en el botón **"Save"**
2. Verás mensaje de confirmación
3. El keystore aparecerá en la lista

✅ **¡Keystore configurado!**

---

## ⚙️ PASO 5: Verificar Workflow Android (1 minuto)

### 5.1 Ir a Workflows

1. En el menú superior, click en **"Workflows"**
2. O en el menú lateral: **"Workflow editor"**

### 5.2 Verificar Android Workflow

1. Verás lista de workflows
2. Busca: **"🤖 Android Build & Deploy"**
3. Debe estar **habilitado** (switch en verde)
4. Si no está habilitado, actívalo

✅ **¡Workflow listo!**

---

## 🚀 PASO 6: Primer Build (15 minutos)

### 6.1 Iniciar Build Manual

1. En la página principal de tu app
2. Click en el botón grande **"Start new build"**
3. Se abrirá un diálogo

### 6.2 Configurar Build

```
Workflow: 🤖 Android Build & Deploy (selecciónalo)
Branch: main (debe estar seleccionado)
```

### 6.3 Ejecutar

1. Click en el botón **"Start new build"**
2. Verás la página del build en progreso
3. Puedes ver los logs en tiempo real

### 6.4 Esperar

⏱️ **Tiempo estimado: 10-15 minutos**

El build pasará por estas etapas:
1. 🟡 Queued (esperando)
2. 🟡 In progress (compilando)
3. 🟢 Success (¡completado!) o 🔴 Failed (error)

### 6.5 Durante la Espera

Mientras esperas:
- ☕ Puedes tomar un café
- 👀 Observar los logs (opcional)
- 📧 Esperar el email de notificación

---

## 📧 PASO 7: Recibir Notificación (Automático)

Cuando termine el build:

1. Recibirás email en: **mauricio@parchefilms.com**
2. Subject: "Build #1 succeeded" (o "failed" si hubo error)
3. El email tendrá link directo al build

---

## 📦 PASO 8: Descargar APKs (2 minutos)

### 8.1 Ver Artifacts

1. En la página del build exitoso
2. Scroll hacia abajo hasta la sección **"Artifacts"**
3. Verás lista de archivos generados

### 8.2 APKs Disponibles

Verás estos archivos:

```
📱 app-release.apk (~25MB)
   → APK universal (funciona en todos los Android)
   
📱 app-armeabi-v7a-release.apk (~15MB)
   → Para Android viejos (32-bit ARM)
   
📱 app-arm64-v8a-release.apk (~15MB) ⭐ RECOMENDADO
   → Para Android modernos (64-bit ARM)
   → La mayoría de teléfonos usan este
   
📱 app-x86_64-release.apk (~15MB)
   → Para emuladores y tablets Intel
   
📦 app-release.aab
   → App Bundle para Google Play Store
```

### 8.3 Descargar

1. Click en el APK que quieras descargar
2. Recomiendo: **app-arm64-v8a-release.apk** (el más común)
3. Se descargará a tu carpeta de Descargas

✅ **¡APK descargado!**

---

## 📱 PASO 9: Instalar en Android (3 minutos)

### Método A: Desde tu Mac (con cable USB)

```bash
# 1. Conecta tu Android con cable USB
# 2. Activa "Depuración USB" en el teléfono:
#    Ajustes > Opciones de desarrollador > Depuración USB

# 3. En Terminal de tu Mac:
cd ~/Downloads
adb install app-arm64-v8a-release.apk

# Si adb no está instalado:
# brew install android-platform-tools
```

### Método B: Compartir APK (más fácil)

1. **Enviar el APK**:
   - Por WhatsApp a tu propio número
   - Por email a tu Android
   - Por AirDrop (si tienes Mac)
   - Por Google Drive / Dropbox

2. **En tu Android**:
   - Abre el mensaje/email
   - Toca el archivo APK
   - Si pregunta "Instalar apps de fuentes desconocidas":
     - Toca "Configuración"
     - Activa "Permitir desde esta fuente"
     - Vuelve atrás
   - Toca "Instalar"
   - Espera unos segundos
   - Toca "Abrir"

✅ **¡App instalada!**

---

## 🎉 PASO 10: Probar la App

1. Abre SU TODERO en tu Android
2. Prueba las funcionalidades
3. Verifica que todo funcione

---

## 🔄 Uso Futuro (Automático)

Ahora que está configurado, cada vez que hagas:

```bash
git push origin main
```

Codemagic compilará automáticamente y:
- ✅ Generará nuevos APKs
- ✅ Te enviará email cuando termine
- ✅ Podrás descargar las nuevas versiones

**¡Sin hacer nada más!**

---

## 🐛 Si Algo Sale Mal

### Error: "Keystore not found"

**Solución:**
1. Ve a Settings > Code signing identities
2. Verifica que el keystore esté ahí
3. Si no, súbelo de nuevo

### Error: "Wrong password"

**Solución:**
- Verifica que el password sea exactamente: `Perro2011`
- Sin espacios antes o después
- Con mayúscula en la P

### Error: "Build failed"

**Solución:**
1. Click en el build fallido
2. Ve a los logs
3. Busca líneas con "ERROR" o "FAILED"
4. Copia el error y pregúntame

### APK no se instala en Android

**Solución:**
1. Ajustes > Seguridad
2. Activa "Fuentes desconocidas"
3. O "Instalar apps desconocidas" > Tu navegador/app > Permitir

---

## 📞 ¿Necesitas Ayuda?

Si te atascas en algún paso:
1. Toma captura de pantalla
2. Dime en qué paso estás
3. Te ayudo a resolverlo

---

## ✅ Checklist Completo

```
□ Descargar keystore a Mac (git pull)
□ Crear cuenta en Codemagic
□ Conectar repositorio mauricioc21/sutodero
□ Subir keystore a Codemagic
□ Configurar passwords (Perro2011)
□ Verificar workflow Android activo
□ Iniciar primer build manual
□ Esperar 15 minutos
□ Recibir email de confirmación
□ Descargar APK
□ Instalar en Android
□ Probar la app
□ ¡Todo funcionando! 🎉
```

---

**🚀 ¡Comienza desde el PASO 1 y síguelos en orden!**

**Cada paso es importante. Tómate tu tiempo y si necesitas ayuda, estoy aquí.**
