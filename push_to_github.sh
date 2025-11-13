#!/bin/bash
# Script para hacer push a GitHub
# Uso: ./push_to_github.sh <GITHUB_TOKEN>

if [ -z "$1" ]; then
  echo "❌ Error: Debes proporcionar un GitHub Personal Access Token"
  echo "Uso: ./push_to_github.sh <TOKEN>"
  echo ""
  echo "Para obtener un token:"
  echo "1. Ir a https://github.com/settings/tokens"
  echo "2. Generar nuevo token (classic)"
  echo "3. Seleccionar scopes: repo (todos)"
  echo "4. Copiar el token y ejecutar: ./push_to_github.sh <TOKEN>"
  exit 1
fi

TOKEN=$1
cd /home/user/flutter_app

echo "🔄 Configurando remote con autenticación..."
git remote set-url origin https://${TOKEN}@github.com/mauricioc21/sutodero.git

echo "🚀 Haciendo push a GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
  echo "✅ Push exitoso a https://github.com/mauricioc21/sutodero"
  # Limpiar token de la URL por seguridad
  git remote set-url origin https://github.com/mauricioc21/sutodero.git
else
  echo "❌ Error durante el push"
  exit 1
fi
