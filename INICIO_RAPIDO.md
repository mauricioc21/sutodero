# ⚡ INICIO RÁPIDO - CI/CD Automático

## 🎯 Lo Que Tienes Ahora

Tu app **SU TODERO** está configurada para **compilarse automáticamente** en la nube.

**Ya NO necesitas:**
- ❌ Abrir Xcode en tu Mac
- ❌ Configurar certificados manualmente
- ❌ Esperar compilaciones lentas
- ❌ Instalar Android Studio
- ❌ Problemas de dependencias locales

**Ahora solo:**
1. ✅ Haces cambios en tu código
2. ✅ `git push origin main`
3. ✅ Esperas 20 minutos
4. ✅ Recibes email con apps listas

---

## 🚀 Configurar en 3 Pasos (30 minutos)

### PASO 1: Codemagic (5 min)
```
1. Ve a: https://codemagic.io/signup
2. "Sign up with GitHub"
3. Autoriza acceso
4. "Add application"
5. Selecciona: mauricioc21/sutodero
```

### PASO 2: Credenciales iOS (15 min)
```
A. Obtén tu Team ID:
   https://developer.apple.com/account
   (Copia los 10 caracteres)

B. Crea API Key:
   https://appstoreconnect.apple.com/access/api
   - Nueva key: "Codemagic"
   - Descarga archivo .p8
   - Anota Key ID e Issuer ID

C. En Codemagic → Settings → Environment variables:
   - Add group: "app_store_credentials"
   - Agregar 3 variables (marca como "Secure"):
     * APP_STORE_CONNECT_KEY_IDENTIFIER
     * APP_STORE_CONNECT_ISSUER_ID  
     * APP_STORE_CONNECT_PRIVATE_KEY
```

### PASO 3: Android Keystore (5 min)
```
¿Tienes keystore?

NO → Dime y yo lo creo (necesito email y nombre empresa)

SÍ → Codemagic → Settings → Code signing → Android
      Upload tu .jks y passwords
```

### PASO 4: Primer Build (5 min)
```
1. Codemagic → "Start new build"
2. Workflow: "iOS Build & Deploy"
3. Click "Start"
4. Espera 20 min
5. Recibes email
```

---

## 📱 Cómo Instalar Apps

### iPhone/iPad
```
1. Ve a: https://appstoreconnect.apple.com
2. My Apps → SU TODERO → TestFlight
3. Agregar testers (emails)
4. Ellos instalan "TestFlight" desde App Store
5. Reciben link de tu app
6. Instalan SU TODERO
```

### Android
```
1. Descarga APK de Codemagic
2. Envía por WhatsApp/Email
3. Abre en Android
4. "Permitir fuentes desconocidas"
5. Instala
```

---

## 🔄 Uso Diario

```bash
# Cambias código localmente
code ~/Desktop/sutodero

# Guardas en GitHub
git add .
git commit -m "feat: nueva función"
git push origin main

# ☕ Esperas 20 min

# ✉️ Recibes email: "Build exitoso"

# 📱 Apps actualizadas en TestFlight/Artifacts
```

---

## 💡 Tips

### ✅ Antes de Push
- Prueba localmente: `flutter run`
- Verifica que compile: `flutter build apk --release`
- Revisa cambios: `git diff`

### 📝 Versiones
```yaml
# pubspec.yaml
version: 1.0.0+1
         ↑     ↑
     Versión  Build

# Actualiza para cada release:
version: 1.0.1+2  # Bug fix
version: 1.1.0+3  # Nueva feature
version: 2.0.0+4  # Major update
```

### 🐛 Si Build Falla
```
1. Ve a Codemagic
2. Click en build fallido
3. "Build logs"
4. Busca líneas con "ERROR"
5. Pregúntame si no entiendes
```

---

## 📚 Documentación

### Guías Disponibles

**GUIA_RAPIDA_CICD.md** ⭐ EMPIEZA AQUÍ
- Setup en 30 minutos
- Solo lo esencial
- Links rápidos

**CONFIGURACION_CICD_AUTOMATICO.md**
- Guía completa detallada
- Troubleshooting extenso
- Todas las opciones

**RESUMEN_CONFIGURACION_CICD.md**
- Qué se configuró
- Cómo funciona
- Beneficios

**BUILD_IOS_INSTRUCTIONS.md**
- Compilación manual iOS (backup)
- Para casos especiales

---

## 🔗 Links Importantes

- **Codemagic**: https://codemagic.io
- **GitHub**: https://github.com/mauricioc21/sutodero
- **Apple Developer**: https://developer.apple.com/account
- **App Store Connect**: https://appstoreconnect.apple.com

---

## ✅ Checklist

Marca cuando completes:

- [ ] Cuenta Codemagic creada
- [ ] Repo conectado
- [ ] Team ID obtenido
- [ ] API Key creada
- [ ] Credenciales en Codemagic
- [ ] Keystore Android (si aplica)
- [ ] Primer build exitoso
- [ ] App en TestFlight
- [ ] Testers agregados
- [ ] ¡Todo funcionando! 🎉

---

## 🆘 Ayuda Rápida

### "No sé mi Team ID"
```
→ https://developer.apple.com/account
→ Está en la página principal (10 caracteres)
```

### "No puedo crear API Key"
```
→ Necesitas ser "Account Holder" o "Admin"
→ O pídele a quien tenga ese rol
```

### "Build tarda mucho"
```
→ iOS: 15-20 min es normal
→ Android: 10-15 min es normal
→ Primera vez puede ser más lento
```

### "App no se instala"
```
iOS: Usa TestFlight (es la forma oficial)
Android: Activa "Fuentes desconocidas"
```

---

## 💬 ¿Preguntas?

**Estoy aquí para ayudarte.**

Solo pregúntame y resolveré cualquier problema o duda que tengas.

---

**🚀 ¡Empieza configurando Codemagic y en 30 minutos tendrás todo funcionando!**
