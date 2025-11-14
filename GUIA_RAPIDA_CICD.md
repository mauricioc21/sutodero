# ⚡ Guía Rápida: Compilar iOS y Android Automáticamente

## 🎯 Lo Que Necesitas Saber

**TÚ NO TIENES QUE HACER NADA EN TU MAC.**

Todo se compila automáticamente en la nube cada vez que hagas un cambio en GitHub.

---

## 🚀 Configuración Rápida (30 minutos)

### PASO 1: Crear Cuenta Codemagic (2 minutos)

```
1. Ve a: https://codemagic.io/signup
2. Click "Sign up with GitHub"
3. Autoriza Codemagic
```

### PASO 2: Conectar Tu Repositorio (1 minuto)

```
1. En Codemagic: "Add application"
2. Busca: mauricioc21/sutodero
3. Click "Add"
```

### PASO 3: Configurar iOS (15 minutos)

#### 3.1 Obtener Team ID
```
1. Ve a: https://developer.apple.com/account
2. Copia tu "Team ID" (10 caracteres)
```

#### 3.2 Crear App Store Connect API Key
```
1. Ve a: https://appstoreconnect.apple.com/access/api
2. Click "+" para nueva key
3. Nombre: "Codemagic"
4. Descarga archivo .p8
5. Anota "Key ID" e "Issuer ID"
```

#### 3.3 Agregar a Codemagic
```
1. En Codemagic: Settings > Environment variables
2. Add group: "app_store_credentials"
3. Agregar 3 variables:
   - APP_STORE_CONNECT_KEY_IDENTIFIER: [tu Key ID]
   - APP_STORE_CONNECT_ISSUER_ID: [tu Issuer ID]
   - APP_STORE_CONNECT_PRIVATE_KEY: [contenido del .p8]
   (todas marcadas como "Secure")
```

### PASO 4: Configurar Android (5 minutos)

```
¿Tienes un keystore?

NO → Yo te lo creo. Solo dime tu email y nombre de empresa.

SÍ → Súbelo en Codemagic:
     Settings > Code signing > Android
     Upload tu archivo .jks
     Ingresa passwords
```

### PASO 5: ¡Primer Build! (5 minutos)

```
1. En Codemagic: "Start new build"
2. Selecciona "iOS Build & Deploy"
3. Espera 15-20 minutos
4. Recibirás email cuando termine
5. Descarga el IPA
```

---

## 📱 Cómo Usar Tu App

### Para iOS (iPhone/iPad)

**Opción 1: TestFlight** ⭐ RECOMENDADO
```
1. La app se sube automáticamente a TestFlight
2. Ve a App Store Connect
3. Agrega emails de testers
4. Los testers instalan "TestFlight" app
5. Reciben link para descargar SU TODERO
```

**Opción 2: Download directo**
```
1. Descarga IPA de Codemagic
2. Envía a tu iPhone por email/AirDrop
3. Ábrelo en iPhone
4. Se instala automáticamente
```

### Para Android

**Opción 1: APK directo** ⭐ MÁS FÁCIL
```
1. Descarga APK de Codemagic
2. Envía a tu Android (WhatsApp, email, etc.)
3. Abre el APK
4. Permite "Fuentes desconocidas"
5. Instala
```

**Opción 2: Google Play (Internal Testing)**
```
1. Sube AAB a Google Play Console
2. Configura internal testing
3. Envía link a testers
```

---

## 🔄 Flujo de Trabajo Diario

### Cada vez que quieras actualizar la app:

```bash
# 1. Haz cambios en tu código

# 2. Guarda en GitHub
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main

# 3. Espera 15-30 minutos

# 4. Recibes email: "Build exitoso"

# 5. Tu app está lista en:
#    - TestFlight (iOS)
#    - Artifacts download (Android)

# 6. Los testers reciben actualización automática
```

**¡Eso es todo! No tocas tu Mac para nada.**

---

## 📊 Monitorear Builds

```
Ve a: https://codemagic.io/apps

Verás lista de builds:
🟢 Success → Todo bien, app lista
🔴 Failed → Hubo error (revisa logs)
🟡 In progress → Compilando...
⚪ Queued → Esperando turno
```

---

## 💡 Tips Importantes

### ✅ DO (Haz esto)

- Actualiza version en `pubspec.yaml` antes de cada release
- Prueba en simulador/emulador antes de hacer push
- Revisa logs si el build falla
- Usa TestFlight para beta testing (iOS)

### ❌ DON'T (No hagas esto)

- No compiles manualmente en tu Mac (deja que Codemagic lo haga)
- No subas credenciales al repositorio (usa Codemagic secrets)
- No distribuyas IPAs sin firma (usa TestFlight)

---

## 🆘 Problemas Comunes

### "Build failed: No code signing"
```
→ Configura certificados en Codemagic
→ Settings > Code signing > iOS
→ Usa "Automatic code signing"
```

### "Build takes too long"
```
→ iOS: 15-20 minutos es normal
→ Android: 10-15 minutos es normal
→ Si es más: Check en "Re-run with clean build"
```

### "App no se instala en iPhone"
```
→ Usa TestFlight (es la forma oficial)
→ O necesitas provisioning profile de desarrollo
```

### "App no se instala en Android"
```
→ Activa "Instalar apps de fuentes desconocidas"
→ Ajustes > Seguridad > Fuentes desconocidas
```

---

## 💰 ¿Cuánto Cuesta?

### Gratis para empezar
```
Codemagic Free:
- 500 minutos/mes
- ~10-15 builds/mes
- Perfecto para desarrollo
```

### Para producción
```
Codemagic Pro: $30/mes
- 4,000 minutos/mes
- ~100 builds/mes
- 3 builds simultáneos
```

### Apple/Google
```
- Apple Developer: $99/año (necesario para TestFlight)
- Google Play: $25 único (opcional)
```

---

## 🎯 Resultado Final

Con esta configuración:

✅ Haces push a GitHub  
✅ Codemagic compila automáticamente  
✅ 15-30 min después tienes apps listas  
✅ iOS en TestFlight  
✅ Android APK listo  
✅ **Sin tocar tu Mac NUNCA**  

---

## 📞 ¿Necesitas Ayuda?

**Yo hago por ti:**
- Crear keystore Android
- Configurar certificados iOS
- Resolver errores de build
- Optimizar configuración

**Solo pregúntame y lo resuelvo.**

---

## 🔗 Links Rápidos

- **Codemagic**: https://codemagic.io
- **Apple Developer**: https://developer.apple.com/account
- **App Store Connect**: https://appstoreconnect.apple.com
- **Tu Repo**: https://github.com/mauricioc21/sutodero

---

## ✅ Checklist Mínimo para Empezar

Completa estos 5 pasos:

- [ ] Cuenta Codemagic creada
- [ ] Repo conectado a Codemagic
- [ ] Apple Team ID agregado
- [ ] App Store Connect API key configurada
- [ ] Primer build manual ejecutado

**¡Con esto ya funciona todo automáticamente!**

---

**🎉 ¿Listo para configurar? Dime cuando empieces y te guío paso a paso.**
