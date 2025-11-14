#!/bin/bash

# 🔑 Script para Crear Keystore Android
# SU TODERO - Firma de APKs

echo "🔑 ====================================="
echo "   CREAR KEYSTORE ANDROID"
echo "====================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Este script creará un keystore para firmar tus APKs de Android.${NC}"
echo -e "${YELLOW}El keystore es necesario para distribuir la app.${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANTE: Guarda el password en un lugar seguro!${NC}"
echo -e "${RED}Si lo pierdes, NO podrás actualizar la app en Google Play.${NC}"
echo ""

# Solicitar información
read -p "Nombre completo: " NOMBRE
read -p "Email: " EMAIL
read -p "Organización (empresa): " ORGANIZACION
read -p "Ciudad: " CIUDAD
read -p "Estado/Departamento: " ESTADO
read -p "País (código de 2 letras, ej: CO): " PAIS

echo ""
read -s -p "Password del keystore (mínimo 6 caracteres): " PASSWORD
echo ""
read -s -p "Confirma el password: " PASSWORD2
echo ""

if [ "$PASSWORD" != "$PASSWORD2" ]; then
    echo -e "${RED}❌ Los passwords no coinciden. Intenta de nuevo.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Generando keystore...${NC}"
echo ""

# Generar keystore
keytool -genkey -v -keystore sutodero-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sutodero \
  -dname "CN=$NOMBRE, OU=$ORGANIZACION, O=$ORGANIZACION, L=$CIUDAD, ST=$ESTADO, C=$PAIS" \
  -storepass "$PASSWORD" \
  -keypass "$PASSWORD"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ¡Keystore creado exitosamente!${NC}"
    echo ""
    echo "📋 INFORMACIÓN DEL KEYSTORE:"
    echo "════════════════════════════════════════"
    echo "Archivo: sutodero-release.jks"
    echo "Ubicación: $(pwd)/sutodero-release.jks"
    echo "Alias: sutodero"
    echo "Password: ********** (el que ingresaste)"
    echo ""
    echo -e "${YELLOW}📝 GUARDA ESTA INFORMACIÓN EN UN LUGAR SEGURO:${NC}"
    echo ""
    echo "Keystore password: $PASSWORD"
    echo "Key alias: sutodero"
    echo "Key password: $PASSWORD"
    echo ""
    echo -e "${BLUE}📤 PRÓXIMO PASO:${NC}"
    echo "Sube el archivo 'sutodero-release.jks' a Codemagic:"
    echo "1. Ve a: https://codemagic.io"
    echo "2. Tu app > Settings > Code signing identities"
    echo "3. Android > Upload keystore"
    echo "4. Sube el archivo y agrega los passwords"
    echo ""
    echo -e "${GREEN}🎉 ¡Listo para usar!${NC}"
else
    echo -e "${RED}❌ Error al crear el keystore${NC}"
    exit 1
fi
