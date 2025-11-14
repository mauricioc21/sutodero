#!/bin/bash

# 🌐 Script para Compilar Web Manualmente
# SU TODERO - Compilación Local

echo "🌐 ====================================="
echo "   COMPILAR WEB - SU TODERO"
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
echo -e "${GREEN}✅ Preparación completa!${NC}"
echo ""
echo "🎯 OPCIONES DE COMPILACIÓN WEB:"
echo ""
echo "═══════════════════════════════════════════════"
echo ""
echo "1️⃣  ${BLUE}DESARROLLO - Servidor local con hot reload:${NC}"
echo "   ${GREEN}flutter run -d chrome${NC}"
echo "   Abre en: http://localhost:XXXX"
echo ""
echo "2️⃣  ${BLUE}BUILD RELEASE - Versión optimizada:${NC}"
echo "   ${GREEN}flutter build web --release${NC}"
echo "   📁 Ubicación: build/web/"
echo ""
echo "3️⃣  ${BLUE}BUILD CON CANVASKIT (Mejor rendimiento):${NC}"
echo "   ${GREEN}flutter build web --release --web-renderer canvaskit${NC}"
echo "   📁 Ubicación: build/web/"
echo ""
echo "4️⃣  ${BLUE}BUILD CON HTML (Mejor compatibilidad):${NC}"
echo "   ${GREEN}flutter build web --release --web-renderer html${NC}"
echo "   📁 Ubicación: build/web/"
echo ""
echo "═══════════════════════════════════════════════"
echo ""
echo "🌐 CÓMO PROBAR LOCALMENTE:"
echo ""
echo "   Opción A - Servidor Python simple:"
echo "   ${GREEN}cd build/web${NC}"
echo "   ${GREEN}python3 -m http.server 8000${NC}"
echo "   Abre: ${BLUE}http://localhost:8000${NC}"
echo ""
echo "   Opción B - Servidor con CORS habilitado:"
echo "   ${GREEN}cd build/web${NC}"
echo "   ${GREEN}python3 ../../cors_server.py${NC}"
echo "   Abre: ${BLUE}http://localhost:8000${NC}"
echo ""
echo "   Opción C - Abrir directamente (limitado):"
echo "   ${GREEN}open build/web/index.html${NC}"
echo "   (Algunas funciones pueden no funcionar)"
echo ""
echo "═══════════════════════════════════════════════"
echo ""
echo "☁️  OPCIONES DE HOSTING (Deploy):"
echo ""
echo "   1. ${BLUE}Firebase Hosting${NC} (Gratis, recomendado)"
echo "      ${GREEN}firebase login${NC}"
echo "      ${GREEN}firebase init hosting${NC}"
echo "      ${GREEN}firebase deploy${NC}"
echo ""
echo "   2. ${BLUE}Netlify${NC} (Gratis, muy fácil)"
echo "      • Arrastra carpeta build/web a netlify.com/drop"
echo "      • O conecta con GitHub para deploy automático"
echo ""
echo "   3. ${BLUE}Vercel${NC} (Gratis, rápido)"
echo "      ${GREEN}npm install -g vercel${NC}"
echo "      ${GREEN}cd build/web && vercel${NC}"
echo ""
echo "   4. ${BLUE}GitHub Pages${NC} (Gratis)"
echo "      • Push build/web a rama gh-pages"
echo "      • Activa GitHub Pages en Settings"
echo ""
echo "   5. ${BLUE}Servidor propio${NC}"
echo "      • Sube carpeta build/web/ a tu servidor"
echo "      • Configura como directorio raíz en Apache/Nginx"
echo ""
echo "📝 NOTAS:"
echo "   • CanvasKit: Mejor para apps complejas (más pesado)"
echo "   • HTML: Mejor compatibilidad con navegadores viejos"
echo "   • Auto: Flutter elige el mejor según el navegador"
echo ""
echo "⚠️  CORS y Firebase:"
echo "   • Si usas Firebase, necesitas CORS configurado"
echo "   • Ya tienes cors_server.py para desarrollo local"
echo ""
