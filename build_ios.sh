#!/bin/bash

# ============================================================================
# Script de Build para SU TODERO iOS
# ============================================================================
# Este script automatiza la compilación de la app para iPhone y iPad
#
# REQUISITOS:
# - macOS 12.0+ (Monterey o superior)
# - Xcode 14.0+
# - Flutter 3.35.4 instalado
# - CocoaPods instalado (sudo gem install cocoapods)
# - Apple Developer Account (para firma)
#
# USO:
#   ./build_ios.sh [simulator|device|ipa]
#
# EJEMPLOS:
#   ./build_ios.sh simulator  # Compila para simulador (no requiere firma)
#   ./build_ios.sh device     # Compila para dispositivo conectado
#   ./build_ios.sh ipa        # Genera IPA para distribución
# ============================================================================

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    log_error "Este script debe ejecutarse desde el directorio raíz del proyecto Flutter"
    exit 1
fi

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    log_error "Flutter no está instalado o no está en el PATH"
    log_info "Instala Flutter desde: https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi

# Verificar que CocoaPods está instalado
if ! command -v pod &> /dev/null; then
    log_error "CocoaPods no está instalado"
    log_info "Instala CocoaPods: sudo gem install cocoapods"
    exit 1
fi

# Determinar el tipo de build
BUILD_TYPE=${1:-"simulator"}

log_info "==================================================="
log_info "  SU TODERO - Build iOS"
log_info "  Tipo: $BUILD_TYPE"
log_info "==================================================="

# Limpiar builds anteriores
log_info "Limpiando builds anteriores..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
log_success "Limpieza completada"

# Obtener dependencias Flutter
log_info "Obteniendo dependencias Flutter..."
flutter pub get
log_success "Dependencias Flutter instaladas"

# Instalar CocoaPods
log_info "Instalando CocoaPods para iOS..."
cd ios
pod install --repo-update
cd ..
log_success "CocoaPods instalados"

# Verificar GoogleService-Info.plist
if ! grep -q "YOUR_IOS_CLIENT_ID" ios/Runner/GoogleService-Info.plist 2>/dev/null; then
    log_success "GoogleService-Info.plist configurado correctamente"
else
    log_warning "GoogleService-Info.plist usa valores placeholder"
    log_warning "Firebase NO funcionará hasta que lo reemplaces con el archivo real"
    log_info "Descarga el archivo real desde Firebase Console:"
    log_info "https://console.firebase.google.com/ > Project Settings > iOS app"
fi

# Ejecutar build según el tipo
case "$BUILD_TYPE" in
    simulator)
        log_info "Compilando para iOS Simulator..."
        flutter build ios --simulator --release
        log_success "Build para simulador completado"
        log_info "Para ejecutar en simulador:"
        log_info "  1. Abre Xcode: open ios/Runner.xcworkspace"
        log_info "  2. Selecciona un simulador iOS"
        log_info "  3. Presiona Cmd+R para ejecutar"
        ;;
        
    device)
        log_info "Compilando para dispositivo iOS..."
        
        # Verificar que hay un dispositivo conectado
        if ! flutter devices | grep -q "ios"; then
            log_error "No se detectó ningún dispositivo iOS conectado"
            log_info "Conecta tu iPhone/iPad con cable USB"
            log_info "Asegúrate de confiar en la computadora en el dispositivo"
            exit 1
        fi
        
        flutter build ios --release --no-codesign
        log_success "Build para dispositivo completado"
        log_warning "Nota: Se requiere firma en Xcode para instalar en dispositivo"
        log_info "Pasos siguientes:"
        log_info "  1. Abre Xcode: open ios/Runner.xcworkspace"
        log_info "  2. Selecciona tu dispositivo conectado"
        log_info "  3. Ve a Signing & Capabilities"
        log_info "  4. Selecciona tu Team (Apple Developer Account)"
        log_info "  5. Presiona Cmd+R para instalar en dispositivo"
        ;;
        
    ipa)
        log_info "Generando IPA para distribución..."
        
        # Verificar que hay una configuración de firma
        log_warning "Este paso requiere configuración de firma en Xcode"
        log_info "Antes de continuar, asegúrate de haber configurado:"
        log_info "  - Bundle Identifier correcto"
        log_info "  - Certificado de distribución"
        log_info "  - Provisioning Profile"
        
        read -p "¿Continuar con la generación de IPA? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Build cancelado"
            exit 0
        fi
        
        flutter build ipa --release
        log_success "IPA generado exitosamente"
        log_info "Archivo IPA ubicado en:"
        log_info "  build/ios/ipa/sutodero.ipa"
        log_info ""
        log_info "Próximos pasos para distribución:"
        log_info "  1. TestFlight: Sube el IPA a App Store Connect"
        log_info "  2. App Store: Envía para revisión desde App Store Connect"
        log_info "  3. Ad-Hoc: Distribuye el IPA directamente a dispositivos registrados"
        ;;
        
    *)
        log_error "Tipo de build desconocido: $BUILD_TYPE"
        log_info "Uso: ./build_ios.sh [simulator|device|ipa]"
        exit 1
        ;;
esac

log_success "==================================================="
log_success "  Build completado exitosamente"
log_success "==================================================="
