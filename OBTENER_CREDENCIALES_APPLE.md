# 🍎 Cómo Obtener Credenciales de Apple Developer

## 📋 Necesitamos 3 Cosas

1. ✅ **Team ID** (10 caracteres)
2. ✅ **App Store Connect API Key** (.p8 file)
3. ✅ **Key ID** e **Issuer ID**

---

## 🔑 PASO 1: Obtener Team ID

### Opción A: Desde Apple Developer Portal

1. Estás en: https://developer.apple.com/account
2. Click en "Account" (arriba derecha)
3. En la página principal verás:
   ```
   Team Name: [Tu nombre/empresa]
   Team ID: XXXXXXXXXX  ← Este es tu Team ID (10 caracteres)
   ```
4. Copia ese Team ID

### Opción B: Desde Membership

1. Ve a: https://developer.apple.com/account/#!/membership
2. Busca "Team ID" en la página
3. Copia los 10 caracteres

---

## 🔑 PASO 2: Crear App Store Connect API Key

### A. Ir a App Store Connect

1. Ve a: https://appstoreconnect.apple.com
2. Login con tu Apple ID (el mismo que usaste antes)

### B. Acceder a API Keys

1. En App Store Connect, click en tu nombre (arriba derecha)
2. Click en "Users and Access"
3. En el menú lateral, click en "Keys" (bajo "Integrations")
4. O ve directo a: https://appstoreconnect.apple.com/access/api

### C. Generar Nueva Key

1. Click en el botón "+" (Generate API Key)
2. Completa el formulario:
   - **Name**: "Codemagic CI/CD"
   - **Access**: "Developer" (o "Admin" si quieres más permisos)
3. Click en "Generate"

### D. Descargar y Guardar

1. **⚠️ IMPORTANTE**: Solo puedes descargar el archivo .p8 UNA VEZ
2. Click en "Download API Key" (icono de descarga)
3. Se descarga: `AuthKey_XXXXXXXXXX.p8`
4. **Guarda este archivo en lugar seguro**

### E. Anotar Información

Después de crear la key, verás:

```
Key ID: XXXXXXXXXX        ← Anota esto
Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  ← Anota esto
```

---

## 📝 Resumen de lo que Necesitas

Al final debes tener:

```
✅ Team ID: XXXXXXXXXX (10 caracteres)
✅ Key ID: XXXXXXXXXX (10 caracteres)
✅ Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (UUID)
✅ Archivo: AuthKey_XXXXXXXXXX.p8 (descargado)
```

---

## 🚀 Próximo Paso

Con esta información, iremos a Codemagic y configuraremos todo.

**¿Ya tienes todo? Dime y continuamos con Codemagic.**
