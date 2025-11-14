#!/bin/bash

# 📱 Script para Compilar iOS Manualmente
# SU TODERO - Compilación Local

echo "🍎 ====================================="
echo "   COMPILAR iOS - SU TODERO"
echo "====================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
echo -e "${YELLOW}🍏 Paso 3: Instalar CocoaPods...${NC}"
cd ios
pod install
cd ..

echo ""
echo -e "${YELLOW}🔍 Paso 4: Verificar dispositivos disponibles...${NC}"
flutter devices

echo ""
echo -e "${GREEN}✅ Preparación completa!${NC}"
echo ""
echo "🎯 OPCIONES DE COMPILACIÓN:"
echo ""
echo "1️⃣  Para SIMULADOR (sin necesidad de certificados):"
echo "   ${GREEN}flutter run${NC}"
echo ""
echo "2️⃣  Para DISPOSITIVO FÍSICO (tu iPhone):"
echo "   ${GREEN}open ios/Runner.xcworkspace${NC}"
echo "   Luego en Xcode:"
echo "   - Selecciona tu iPhone en la lista"
echo "   - Click en el botón ▶️ Play (Cmd+R)"
echo ""
echo "3️⃣  Para BUILD DE RELEASE (IPA):"
echo "   ${GREEN}flutter build ios --release${NC}"
echo "   (Requiere certificados configurados en Xcode)"
echo ""
echo "📝 NOTAS:"
echo "   • Primera vez: Configura tu Apple ID en Xcode"
echo "   • Xcode > Preferences > Accounts > + (tu Apple ID)"
echo "   • En el proyecto: Signing & Capabilities > Team (tu Apple ID)"
echo "   • La app en tu iPhone dura 7 días, luego reinstalar"
echo ""
