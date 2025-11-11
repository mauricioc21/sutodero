# 🚀 INSTRUCCIONES PARA SUBIR SU TODERO A GITHUB

## 📦 Repositorio Destino
**URL:** https://github.com/mauricioc21/sutodero.git  
**Owner:** @mauricioc21  
**Branch:** main

---

## ✅ **ESTADO ACTUAL**

- ✅ Repositorio Git local inicializado
- ✅ Commit inicial realizado (136 archivos)
- ✅ Remoto configurado: `origin` → `https://github.com/mauricioc21/sutodero.git`
- ⏳ Pendiente: Autenticación y push a GitHub

---

## 🔐 **MÉTODO 1: DESDE ESTA SESIÓN (Automático con autorización)**

### Paso 1: Autorizar GitHub en la interfaz
1. Ve a la pestaña **"GitHub"** en la barra lateral izquierda
2. Haz clic en **"Authorize GitHub App"**
3. Sigue las instrucciones para autorizar

### Paso 2: Una vez autorizado, ejecuta:
```bash
cd /home/user/flutter_app
./push_to_github.sh
```

---

## 💻 **MÉTODO 2: DESDE TU COMPUTADORA LOCAL (Recomendado)**

### Paso 1: Descargar el backup
```bash
# Descarga el archivo
wget https://page.gensparksite.com/project_backups/sutodero_backup_v1.0.tar.gz

# Extrae el contenido
tar -xzf sutodero_backup_v1.0.tar.gz

# Entra al directorio
cd flutter_app
```

### Paso 2: Configurar el repositorio remoto
```bash
# Añade el repositorio remoto
git remote add origin https://github.com/mauricioc21/sutodero.git

# Verifica la configuración
git remote -v
```

### Paso 3A: Push con HTTPS (requiere Personal Access Token)

**Primero, crea un Personal Access Token:**
1. Ve a: https://github.com/settings/tokens/new
2. **Note:** `SU TODERO App`
3. **Expiration:** `No expiration` o `90 days`
4. **Scopes:** Selecciona `repo` (marca todos los checkboxes debajo)
5. Haz clic en **"Generate token"**
6. **COPIA EL TOKEN** (solo se muestra una vez)

**Luego, haz push:**
```bash
# Reemplaza YOUR_TOKEN con el token que copiaste
git remote set-url origin https://YOUR_TOKEN@github.com/mauricioc21/sutodero.git

# Sube el código
git push -u origin main
```

### Paso 3B: Push con SSH (más seguro, recomendado)

**Primero, configura SSH (si no lo has hecho):**
```bash
# Genera una clave SSH (si no tienes una)
ssh-keygen -t ed25519 -C "tu_email@ejemplo.com"

# Copia la clave pública
cat ~/.ssh/id_ed25519.pub
```

**Agrega la clave a GitHub:**
1. Ve a: https://github.com/settings/keys
2. Haz clic en **"New SSH key"**
3. **Title:** `Mi computadora`
4. **Key:** Pega la clave que copiaste
5. Haz clic en **"Add SSH key"**

**Luego, haz push:**
```bash
# Cambia la URL a SSH
git remote set-url origin git@github.com:mauricioc21/sutodero.git

# Sube el código
git push -u origin main
```

---

## 🖥️ **MÉTODO 3: GITHUB DESKTOP (Más fácil para principiantes)**

### Paso 1: Instalar GitHub Desktop
- Descarga desde: https://desktop.github.com/
- Instala y abre la aplicación
- Inicia sesión con tu cuenta de GitHub

### Paso 2: Agregar el repositorio local
1. Descarga y extrae el backup (ver Método 2, Paso 1)
2. En GitHub Desktop: **File** → **Add Local Repository**
3. Selecciona la carpeta `flutter_app`
4. Haz clic en **"Add repository"**

### Paso 3: Publicar a GitHub
1. Haz clic en **"Publish repository"**
2. Verifica que el nombre sea `sutodero`
3. **Desactiva** "Keep this code private" si quieres que sea público
4. Haz clic en **"Publish repository"**

**¡Listo!** Tu código estará en GitHub.

---

## 🔄 **COMANDOS ÚTILES PARA EL FUTURO**

### Subir cambios después de editar código:
```bash
cd /home/user/flutter_app

# Ver qué cambió
git status

# Agregar todos los cambios
git add .

# Hacer commit con mensaje descriptivo
git commit -m "✨ Agrega sistema de inventarios"

# Subir a GitHub
git push origin main
```

### Descargar cambios desde GitHub (si trabajas en varias máquinas):
```bash
git pull origin main
```

### Ver historial de commits:
```bash
git log --oneline --graph
```

### Crear una rama para nuevas funcionalidades:
```bash
# Crear y cambiar a una nueva rama
git checkout -b feature/inventarios

# Hacer cambios, commits...

# Volver a la rama principal
git checkout main

# Fusionar los cambios
git merge feature/inventarios
```

---

## 📞 **¿NECESITAS AYUDA?**

### Errores comunes:

**Error: "Authentication failed"**
- Solución: Verifica que tu Personal Access Token sea correcto
- O usa SSH en lugar de HTTPS

**Error: "Permission denied"**
- Solución: Verifica que estás autenticado correctamente
- Revisa que tu cuenta tenga permisos para el repositorio

**Error: "Repository not found"**
- Solución: Verifica que el repositorio exista en GitHub
- Verifica que la URL sea correcta

**Error: "failed to push some refs"**
- Solución: Primero haz `git pull origin main --rebase`
- Luego `git push origin main`

---

## 🎯 **RESUMEN RÁPIDO**

1. **Más fácil:** GitHub Desktop
2. **Más rápido:** HTTPS con Personal Access Token
3. **Más seguro:** SSH
4. **Automático:** Autorizar en la pestaña GitHub de esta interfaz

**Tu código YA ESTÁ protegido con el backup descargable.**  
Subir a GitHub es un paso adicional para tener respaldo en la nube.

---

## ✅ **CHECKLIST DE VERIFICACIÓN**

Después de subir a GitHub, verifica:
- [ ] El repositorio está visible en https://github.com/mauricioc21/sutodero
- [ ] Todos los archivos están presentes (136 archivos)
- [ ] El README.md se ve correctamente
- [ ] El commit inicial aparece en el historial
- [ ] Las imágenes en `assets/images/` están subidas

---

**¡Tu código está listo para subir!** 🚀

Última actualización: Noviembre 2024
