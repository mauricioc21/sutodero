# 📱 Cómo Obtener el APK de SU TODERO

## ⚠️ Situación Actual

El sandbox de desarrollo no puede compilar APKs porque **no tiene Android SDK instalado**. Esto es normal en entornos cloud por limitaciones de recursos.

## ✅ 3 Opciones Disponibles

### 🏆 Opción 1: Compilar en Tu Computadora (5 min) ⭐ RECOMENDADO

**Si tienes Flutter instalado:**

```bash
# 1. Clona el repositorio
git clone https://github.com/mauricioc21/sutodero.git
cd sutodero

# 2. Instala dependencias
flutter pub get

# 3. Construye el APK
flutter build apk --release

# 4. Encuentra el APK en:
# build/app/outputs/flutter-apk/app-release.apk
```

**Instalar en tu Android:**
- Por USB: `adb install build/app/outputs/flutter-apk/app-release.apk`
- Por WhatsApp: Envíate el archivo APK
- Por Email: Adjunta y descarga en tu Android

---

### 🤖 Opción 2: Usar Codemagic (15 min)

**No necesitas Flutter instalado. Tu proyecto ya tiene `codemagic.yaml` configurado.**

1. Ve a https://codemagic.io/signup
2. Inicia sesión con GitHub
3. Conecta el repo `sutodero`
4. Click en "Start new build"
5. Selecciona "Android Release"
6. Espera 10-15 minutos
7. Descarga el APK de "Artifacts"
8. Envíalo a tu Android por WhatsApp/Email

---

### 🌐 Opción 3: Otros Servicios Cloud

Alternativas si prefieres:
- **AppCenter** (Microsoft): https://appcenter.ms
- **Bitrise**: https://bitrise.io  
- **CircleCI**: https://circleci.com

---

## 🎯 ¿Cuál Elegir?

| Situación | Opción Recomendada |
|-----------|-------------------|
| Tienes Flutter instalado | **Opción 1** (más rápido) |
| NO tienes Flutter | **Opción 2** (Codemagic) |
| Quieres builds automáticos | **Opción 2** (Codemagic) |

---

## 📋 Detalles Opción 1 (En tu computadora)

### Pre-requisitos:
```bash
# Verifica que tienes Flutter
flutter --version

# Si no, instala desde: https://flutter.dev
```

### Pasos completos:
```bash
cd ~/Documents  # o donde prefieras

git clone https://github.com/mauricioc21/sutodero.git
cd sutodero

flutter pub get

flutter build apk --release

# El APK estará en:
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

### Instalar:
**Por USB:**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Por WhatsApp:**
1. Abre `build/app/outputs/flutter-apk/`
2. Envíate `app-release.apk` por WhatsApp
3. Descarga en Android e instala

---

## 🔧 Detalles Opción 2 (Codemagic)

### Primera vez (5 min):
1. https://codemagic.io/signup
2. "Sign in with GitHub"
3. "Add application" → GitHub → "sutodero"
4. Codemagic detecta `codemagic.yaml` automáticamente

### Cada build (10-15 min):
1. https://codemagic.io/apps
2. Click en "sutodero"
3. "Start new build"
4. Workflow: "Android Release"
5. Espera a que termine
6. Download "app-release.apk" de Artifacts
7. Envía a tu Android

---

## 📊 Comparación

| Característica | Opción 1 | Opción 2 |
|----------------|----------|----------|
| Tiempo | 5 min | 15 min |
| Requiere Flutter | ✅ Sí | ❌ No |
| Setup | Ninguno | 5 min (1 vez) |
| Automático | ❌ No | ✅ Sí |
| Gratis | ✅ Sí | ✅ Sí (500 min/mes) |

---

## 🆘 Troubleshooting

### "Flutter no encontrado"
```bash
# Instala Flutter:
# Mac: brew install flutter
# Windows/Linux: https://flutter.dev/docs/get-started/install
```

### "No puedo instalar APK"
```bash
# Android: Configuración → Seguridad
# Activa "Fuentes desconocidas"
```

### "Build falla en Codemagic"
```bash
# Verifica logs en Codemagic
# Generalmente son problemas de Firebase
# google-services.json debe estar en el repo
```

---

## 🎊 Resumen

**No puedo compilar el APK aquí** (no hay Android SDK en el sandbox).

**Tienes 3 opciones:**
1. **Compilar localmente** (5 min) - si tienes Flutter
2. **Usar Codemagic** (15 min) - build en la nube
3. **Otros servicios** - alternativas

**El código está listo** en GitHub para cualquiera de estas opciones.

---

**Repositorio**: https://github.com/mauricioc21/sutodero  
**Más ayuda**: `BUILD_APK_INSTRUCTIONS.md` (detalles completos)  
**Configuración**: `codemagic.yaml` (ya está listo)
