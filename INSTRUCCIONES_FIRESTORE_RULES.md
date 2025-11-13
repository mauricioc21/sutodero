# 🔒 Guía para Desplegar Firestore Security Rules

## 📋 Resumen de las Reglas

Las reglas de seguridad implementadas en `firestore.rules` protegen tu aplicación mediante:

### 🔐 **Control de Acceso por Roles**:
- **Admin**: Puede ver, crear, actualizar y eliminar TODOS los datos
- **Técnico**: Puede ver y actualizar tickets asignados a él
- **Cliente**: Solo puede ver y gestionar sus propios datos

### 📦 **Colecciones Protegidas**:
1. ✅ `users` - Perfiles de usuarios
2. ✅ `properties` - Inventarios de propiedades
3. ✅ `rooms` - Espacios de propiedades
4. ✅ `tickets` - Tickets de mantenimiento
5. ✅ `property_listings` - Captaciones de inmuebles
6. ✅ `inventory_acts` - Actas de inventario
7. ✅ `virtual_tours` - Tours virtuales
8. ✅ `ticket_messages` - Mensajes de chat

---

## 🚀 Pasos para Desplegar las Reglas

### **Método 1: Desde Firebase Console (Recomendado)**

#### Paso 1: Abrir el archivo de reglas
1. Abre el archivo `firestore.rules` en tu editor
2. Copia **TODO el contenido** del archivo (líneas 1-142)

#### Paso 2: Ir a Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto
3. En el menú lateral, click en **"Firestore Database"**
4. En la barra superior, click en la pestaña **"Rules"**

#### Paso 3: Reemplazar las reglas
1. Verás el editor de reglas actual
2. **Selecciona todo el contenido** (Ctrl+A / Cmd+A)
3. **Elimínalo** (Delete/Backspace)
4. **Pega** el contenido copiado de `firestore.rules`
5. Click en el botón **"Publish"** (arriba a la derecha)

#### Paso 4: Verificar el despliegue
1. Deberías ver un mensaje de éxito
2. Las reglas estarán activas **inmediatamente**
3. Verifica la fecha de última actualización en la parte superior

---

### **Método 2: Usando Firebase CLI** (Opcional)

Si tienes Firebase CLI instalado:

```bash
# 1. Navegar al directorio del proyecto
cd /home/user/flutter_app

# 2. Inicializar Firebase (si no está inicializado)
firebase init firestore
# Selecciona: Use existing project
# Rules file: firestore.rules (ya existe)
# Indexes file: firestore.indexes.json

# 3. Desplegar las reglas
firebase deploy --only firestore:rules
```

---

## 🧪 Cómo Probar las Reglas

Después de desplegar, prueba el control de acceso:

### **Prueba 1: Usuario Admin puede ver todos los datos**
```
1. Inicia sesión con: admin@sutodero.com
2. Navega a cualquier sección (Inventarios, Tickets, etc.)
3. ✅ Deberías ver TODOS los registros de todos los usuarios
```

### **Prueba 2: Usuario Cliente solo ve sus datos**
```
1. Inicia sesión con: cliente@sutodero.com
2. Navega a Inventarios o Tickets
3. ✅ Solo deberías ver tus propios registros
4. ❌ No deberías ver registros de otros usuarios
```

### **Prueba 3: Usuario Técnico ve tickets asignados**
```
1. Inicia sesión con: tecnico@sutodero.com
2. Navega a Tickets
3. ✅ Deberías ver tickets asignados a ti
4. ✅ Puedes actualizar el estado de tus tickets
```

### **Prueba 4: Usuarios no pueden crear datos de otros**
```
1. Inicia sesión como cualquier usuario
2. Intenta crear un registro con userId diferente al tuyo
3. ❌ Debería fallar con error de permisos
```

---

## 🔍 Verificar en Firebase Console

### **Opción A: Probar desde el Simulador de Reglas**

1. En Firebase Console → Firestore Database → Rules
2. Click en **"Rules Playground"** (arriba a la derecha)
3. Configura una prueba:
   ```
   Location: /users/abc123
   Authenticated: Yes
   Auth UID: abc123
   Operation: Get
   ```
4. Click en **"Run"**
5. ✅ Debería mostrar "Simulated get allowed"

### **Opción B: Monitorear en tiempo real**

1. Ve a **Firestore Database** → **Data**
2. Abre la consola del navegador (F12)
3. Intenta leer/escribir datos desde la app
4. Observa los errores de permisos en la consola

---

## ⚠️ Solución de Problemas

### **Error: "Missing or insufficient permissions"**

**Causa**: Las reglas están bloqueando el acceso.

**Soluciones**:
1. Verifica que el usuario está autenticado
2. Verifica que el campo `userId` en los documentos coincide con `request.auth.uid`
3. Verifica que el campo `rol` en `/users/{uid}` está correctamente configurado

### **Error: "PERMISSION_DENIED"**

**Causa**: Reglas no desplegadas o usuario sin rol asignado.

**Soluciones**:
1. Confirma que las reglas están desplegadas (verifica fecha en Firebase Console)
2. Verifica que el documento del usuario en `/users/{uid}` tiene el campo `rol`
3. Cierra sesión y vuelve a iniciar sesión

### **Los admins no pueden ver todos los datos**

**Verificar**:
1. El documento en `/users/{uid}` del admin tiene `rol: "admin"`
2. El campo es exactamente `"admin"` (minúsculas)
3. El documento existe en Firestore (no solo en Authentication)

---

## 📊 Estructura de Datos Requerida

Para que las reglas funcionen correctamente, asegúrate de que:

### **Colección `users`**:
```javascript
{
  uid: "abc123",           // ← Debe coincidir con Auth UID
  nombre: "Juan Admin",
  email: "admin@sutodero.com",
  rol: "admin",           // ← CRÍTICO: "admin" | "tecnico" | "cliente"
  telefono: "3101234567",
  fechaCreacion: Timestamp
}
```

### **Colección `properties`, `tickets`, etc.**:
```javascript
{
  id: "prop123",
  userId: "abc123",        // ← CRÍTICO: UID del propietario
  // ... otros campos
}
```

---

## ✅ Checklist de Despliegue

- [ ] Archivo `firestore.rules` copiado
- [ ] Reglas pegadas en Firebase Console
- [ ] Reglas publicadas (botón "Publish")
- [ ] Fecha de actualización verificada
- [ ] Usuarios de prueba creados con campo `rol`
- [ ] Prueba de login con admin exitosa
- [ ] Prueba de login con cliente exitosa
- [ ] Admin puede ver todos los datos
- [ ] Cliente solo ve sus datos
- [ ] Sin errores en consola del navegador

---

## 💡 Notas Importantes

- ⚠️ **Las reglas son aplicadas inmediatamente** después de publicar
- ⚠️ **Todos los datos existentes deben tener campo `userId`** para funcionar
- ⚠️ **El campo `rol` es case-sensitive**: usa exactamente "admin", "tecnico", "cliente"
- ✅ **Las reglas protegen todos los métodos**: read, write, update, delete
- ✅ **La función `isAdmin()` verifica el rol** consultando la colección `users`
- ⚠️ **Usuarios sin documento en `/users/{uid}`** no tendrán rol y serán bloqueados

---

## 🔗 Recursos Adicionales

- **Documentación oficial**: https://firebase.google.com/docs/firestore/security/get-started
- **Testing de reglas**: https://firebase.google.com/docs/firestore/security/test-rules-emulator
- **Mejores prácticas**: https://firebase.google.com/docs/firestore/security/rules-structure

---

## 📝 Después del Despliegue

Una vez desplegadas las reglas, deberías:

1. ✅ Migrar datos existentes para incluir `userId`
2. ✅ Probar cada rol de usuario (admin, tecnico, cliente)
3. ✅ Verificar que no hay errores en producción
4. ✅ Documentar cualquier caso especial de acceso
5. ✅ Configurar alertas de seguridad en Firebase Console
