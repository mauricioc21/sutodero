#!/bin/bash
# Script para subir SU TODERO a GitHub

echo "🚀 Subiendo SU TODERO a GitHub..."
echo ""
echo "📦 Repositorio: https://github.com/mauricioc21/sutodero.git"
echo "🌿 Branch: main"
echo ""

# Verificar que hay cambios para subir
if git status --porcelain | grep -q .; then
    echo "📝 Nuevos cambios detectados, haciendo commit..."
    git add .
    git commit -m "📦 Update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Intentar push
echo "⬆️ Subiendo a GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ¡Código subido exitosamente a GitHub!"
    echo "🔗 Ver en: https://github.com/mauricioc21/sutodero"
else
    echo ""
    echo "❌ Error al subir. Necesitas autenticación."
    echo ""
    echo "🔑 Para autenticar, usa uno de estos métodos:"
    echo ""
    echo "1️⃣ GitHub CLI (si está instalado):"
    echo "   gh auth login"
    echo ""
    echo "2️⃣ Personal Access Token:"
    echo "   - Ve a: https://github.com/settings/tokens"
    echo "   - Crea un nuevo token (classic)"
    echo "   - Permisos: repo (todos los checkboxes)"
    echo "   - Copia el token"
    echo "   - Usa: git remote set-url origin https://TOKEN@github.com/mauricioc21/sutodero.git"
    echo ""
    echo "3️⃣ SSH (recomendado para uso frecuente):"
    echo "   - Genera una clave SSH"
    echo "   - Agrégala a GitHub"
    echo "   - Usa: git remote set-url origin git@github.com:mauricioc21/sutodero.git"
fi
