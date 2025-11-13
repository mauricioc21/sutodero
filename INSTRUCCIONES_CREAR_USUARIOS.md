# 📋 Instrucciones para Crear Usuarios de Prueba en Firebase

## 🎯 Usuarios a Crear

### 1. **ADMINISTRADOR**
- **Email**: `admin@sutodero.com`
- **Contraseña**: `admin123`
- **Nombre**: Juan Administrador
- **Rol**: admin
- **Teléfono**: 3101234567

### 2. **TÉCNICO**
- **Email**: `tecnico@sutodero.com`
- **Contraseña**: `tecnico123`
- **Nombre**: Carlos Técnico
- **Rol**: tecnico
- **Teléfono**: 3109876543

### 3. **CLIENTE 1**
- **Email**: `cliente@sutodero.com`
- **Contraseña**: `cliente123`
- **Nombre**: María Cliente
- **Rol**: cliente
- **Teléfono**: 3108765432

### 4. **CLIENTE 2**
- **Email**: `cliente2@sutodero.com`
- **Contraseña**: `cliente123`
- **Nombre**: Pedro González
- **Rol**: cliente
- **Teléfono**: 3107654321

---

## 🔧 Pasos para Crear en Firebase Console

### **Paso 1: Crear usuarios en Authentication**

1. Ir a **Firebase Console**: https://console.firebase.google.com/
2. Seleccionar tu proyecto
3. Ir a **Authentication** → **Users**
4. Click en **"Add user"**
5. Para cada usuario:
   - Ingresar **Email**
   - Ingresar **Password**
   - Click en **"Add user"**
   - **Copiar el UID** generado (lo necesitarás para el siguiente paso)

### **Paso 2: Crear documentos en Firestore**

1. Ir a **Firestore Database** en el menú lateral
2. Seleccionar la colección **`users`** (créala si no existe)
3. Click en **"Add document"**
4. Para cada usuario:
   - **Document ID**: Usar el **UID** copiado del paso anterior
   - **Agregar campos**:
     ```
     uid (string): [UID del usuario]
     nombre (string): [Nombre completo]
     email (string): [Email del usuario]
     rol (string): [admin | tecnico | cliente]
     telefono (string): [Número de teléfono]
     fechaCreacion (timestamp): [Usar "Add field" → "timestamp" → fecha actual]
     ```
   - Click en **"Save"**

### **Ejemplo de documento en Firestore**:
```
Collection: users
Document ID: abc123xyz (UID del usuario)

Fields:
{
  "uid": "abc123xyz",
  "nombre": "Juan Administrador",
  "email": "admin@sutodero.com",
  "rol": "admin",
  "telefono": "3101234567",
  "fechaCreacion": Timestamp (auto-generado)
}
```

---

## ✅ Verificación

Después de crear los usuarios:

1. **Verificar en Authentication**:
   - Debes ver 4 usuarios en la lista
   - Cada uno con su email correspondiente

2. **Verificar en Firestore**:
   - La colección `users` debe tener 4 documentos
   - Cada documento debe tener el mismo UID que en Authentication
   - El campo `rol` debe estar correctamente asignado

3. **Probar login en la app**:
   - Intentar iniciar sesión con cada usuario
   - Verificar que cada uno solo vea sus propios datos
   - Verificar que el admin puede ver todos los datos

---

## 🔐 Credenciales de Prueba

### 🔴 ADMINISTRADOR
```
Email: admin@sutodero.com
Password: admin123
```

### 🔧 TÉCNICO
```
Email: tecnico@sutodero.com
Password: tecnico123
```

### 👤 CLIENTES
```
Email: cliente@sutodero.com
Password: cliente123

Email: cliente2@sutodero.com
Password: cliente123
```

---

## 💡 Notas Importantes

- ⚠️ **Los UID deben coincidir** entre Authentication y Firestore
- ⚠️ **El campo `rol` es crítico** para el control de acceso
- ⚠️ Las contraseñas son **solo para pruebas**, cámbialas en producción
- ✅ Después de crear usuarios, prueba el login con cada uno
- ✅ Verifica que las reglas de seguridad se apliquen correctamente
