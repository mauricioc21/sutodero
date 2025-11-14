#!/bin/bash

# 🤖 Script para Compilar Android Manualmente
# SU TODERO - Compilación Local

echo "🤖 ====================================="
echo "   COMPILAR ANDROID - SU TODERO"
echo "====================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: No se encuentra pubspec.yaml${NC}"
    echo "Ejecuta este script desde la raíz del proyecto"
    exit 1
fi

echo -e "${YELLOW}📦 Paso 1: Limpiar builds anteriores...${NC}"
flutter clean

echo ""
echo -e "${YELLOW}📦 Paso 2: Obtener dependencias...${NC}"
flutter pub get

echo ""
echo -e "${YELLOW}🔍 Paso 3: Verificar dispositivos disponibles...${NC}"
flutter devices

echo ""
echo -e "${GREEN}✅ Preparación completa!${NC}"
echo ""
echo "🎯 OPCIONES DE COMPILACIÓN:"
echo ""
echo "═══════════════════════════════════════════════"
echo ""
echo "1️⃣  ${BLUE}DESARROLLO - Ejecutar en dispositivo conectado:${NC}"
echo "   ${GREEN}flutter run${NC}"
echo ""
echo "2️⃣  ${BLUE}APK DEBUG - Para pruebas rápidas:${NC}"
echo "   ${GREEN}flutter build apk --debug${NC}"
echo "   📁 Ubicación: build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "3️⃣  ${BLUE}APK RELEASE - Para distribución:${NC}"
echo "   ${GREEN}flutter build apk --release${NC}"
echo "   📁 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "4️⃣  ${BLUE}APK SPLIT (Optimizado por arquitectura):${NC}"
echo "   ${GREEN}flutter build apk --release --split-per-abi${NC}"
echo "   📁 Genera 3 APKs optimizados:"
echo "      • app-armeabi-v7a-release.apk (32-bit ARM)"
echo "      • app-arm64-v8a-release.apk (64-bit ARM) ⭐ Más común"
echo "      • app-x86_64-release.apk (Emuladores/Tablets)"
echo ""
echo "5️⃣  ${BLUE}APP BUNDLE (AAB) - Para Google Play Store:${NC}"
echo "   ${GREEN}flutter build appbundle --release${NC}"
echo "   📁 Ubicación: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "═══════════════════════════════════════════════"
echo ""
echo "📱 CÓMO INSTALAR EL APK:"
echo ""
echo "   Opción A - USB (ADB):"
echo "   ${GREEN}flutter install${NC}"
echo "   ${GREEN}# o directamente:${NC}"
echo "   ${GREEN}adb install build/app/outputs/flutter-apk/app-release.apk${NC}"
echo ""
echo "   Opción B - Compartir APK:"
echo "   1. Envía el APK por WhatsApp/Email/AirDrop"
echo "   2. Abre en el Android"
echo "   3. Permite 'Instalar apps de fuentes desconocidas'"
echo "   4. Instala"
echo ""
echo "   Opción C - Desde tu Mac:"
echo "   ${GREEN}open build/app/outputs/flutter-apk/${NC}"
echo "   (Abre la carpeta con los APKs)"
echo ""
echo "📝 NOTAS:"
echo "   • APK Debug: ~50MB, para pruebas rápidas"
echo "   • APK Release: ~20MB, optimizado y firmado"
echo "   • APK Split: ~15MB c/u, el más pequeño"
echo "   • AAB: Solo para subir a Google Play Store"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • Los APKs están firmados con certificado debug"
echo "   • Para producción, necesitas un keystore de release"
echo "   • Pregúntame si necesitas crear uno"
echo ""
