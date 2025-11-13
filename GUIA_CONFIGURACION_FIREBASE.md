# 🔥 Guía Completa de Configuración de Firebase para SU TODERO

## 📋 Índice

1. [Crear Usuarios de Prueba](#1-crear-usuarios-de-prueba)
2. [Desplegar Reglas de Seguridad](#2-desplegar-reglas-de-seguridad)
3. [Verificar y Migrar Datos](#3-verificar-y-migrar-datos)
4. [Verificación Final](#4-verificación-final)

---

## 1. Crear Usuarios de Prueba

### 📝 Usuarios a Crear

| Rol | Email | Password | Nombre | Teléfono |
|-----|-------|----------|--------|----------|
| **Admin** | admin@sutodero.com | admin123 | Juan Administrador | 3101234567 |
| **Técnico** | tecnico@sutodero.com | tecnico123 | Carlos Técnico | 3109876543 |
| **Cliente** | cliente@sutodero.com | cliente123 | María Cliente | 3108765432 |
| **Cliente 2** | cliente2@sutodero.com | cliente123 | Pedro González | 3107654321 |

### 🚀 Opción A: Creación Manual (Recomendada)

#### Paso 1: Crear en Authentication
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto
3. **Authentication** → **Users** → **"Add user"**
4. Para cada usuario:
   - Ingresa Email y Password
   - Click "Add user"
   - **Copia el UID generado** (importante para el siguiente paso)

#### Paso 2: Crear documentos en Firestore
1. **Firestore Database** → Colección **`users`**
2. **"Add document"**
3. **Document ID**: Pega el UID copiado
4. **Campos a agregar**:
   ```
   uid (string): [UID del usuario]
   nombre (string): [Nombre completo]
   email (string): [Email]
   rol (string): [admin | tecnico | cliente]
   telefono (string): [Teléfono]
   fechaCreacion (timestamp): [Fecha actual]
   ```

### 🤖 Opción B: Script Automático (Requiere Firebase Admin SDK)

Si tienes el archivo `firebase-admin-sdk.json`:

```bash
python3 /home/user/create_test_users.py
```

### ✅ Verificación
- [ ] 4 usuarios en Authentication
- [ ] 4 documentos en colección `users`
- [ ] Todos los UIDs coinciden entre Auth y Firestore
- [ ] Campo `rol` correctamente asignado

📖 **Guía detallada**: `INSTRUCCIONES_CREAR_USUARIOS.md`

---

## 2. Desplegar Reglas de Seguridad

### 📋 ¿Qué hacen las reglas?

Las reglas de seguridad protegen tu aplicación:
- ✅ **Admins** pueden ver y gestionar TODOS los datos
- ✅ **Técnicos** pueden ver y actualizar tickets asignados
- ✅ **Clientes** solo ven sus propios datos
- ❌ Usuarios sin rol = Sin acceso

### 🚀 Pasos para Desplegar

#### 1. Copiar el contenido de las reglas
```bash
cat /home/user/flutter_app/firestore.rules
```

#### 2. Ir a Firebase Console
1. https://console.firebase.google.com/
2. Tu proyecto → **Firestore Database** → pestaña **"Rules"**

#### 3. Reemplazar las reglas
1. Selecciona todo (Ctrl+A)
2. Borra el contenido
3. Pega las reglas de `firestore.rules`
4. Click **"Publish"**

#### 4. Verificar despliegue
- ✅ Mensaje de éxito
- ✅ Fecha de actualización visible
- ✅ Reglas activas inmediatamente

### 🧪 Probar las Reglas

**Test 1: Admin ve todo**
```
Login: admin@sutodero.com
✅ Debe ver TODOS los inventarios/tickets
```

**Test 2: Cliente ve solo sus datos**
```
Login: cliente@sutodero.com
✅ Solo ve sus propios registros
❌ No ve registros de otros usuarios
```

📖 **Guía detallada**: `INSTRUCCIONES_FIRESTORE_RULES.md`

---

## 3. Verificar y Migrar Datos

### 🔍 Paso 1: Verificar Estado Actual

#### Opción A: Script de Verificación
```bash
python3 /home/user/flutter_app/scripts/verify_userid_fields.py
```

El script verifica qué colecciones necesitan el campo `userId`:
- ✅ properties
- ✅ rooms
- ✅ tickets
- ✅ property_listings
- ✅ inventory_acts
- ✅ virtual_tours

#### Opción B: Verificación Manual
1. Firebase Console → Firestore Database
2. Abre cada colección
3. Verifica si los documentos tienen campo `userId`

### 🔄 Paso 2: Migrar Datos (si es necesario)

#### Opción A: Script Automático
```bash
python3 /home/user/flutter_app/scripts/migrate_userid_fields.py
```

**¿Qué hace el script?**
- Busca el primer usuario admin
- Asigna todos los datos huérfanos a ese admin
- Agrega campo `userId` a documentos que no lo tienen

**⚠️ IMPORTANTE:**
- Los datos migrados se asignarán al admin
- Puedes reasignar manualmente después
- O eliminar datos de prueba y crear nuevos

#### Opción B: Migración Manual
Para cada documento sin `userId`:
1. Firebase Console → Firestore
2. Click en el documento
3. "Add field"
4. Field name: `userId`
5. Field type: `string`
6. Value: [UID del propietario]
7. "Save"

### ✅ Verificación Post-Migración
```bash
# Ejecutar verificación nuevamente
python3 /home/user/flutter_app/scripts/verify_userid_fields.py
```

Resultado esperado:
```
✅ properties: X/X documentos OK
✅ rooms: X/X documentos OK
✅ tickets: X/X documentos OK
...
```

---

## 4. Verificación Final

### 📋 Checklist Completo

#### Authentication
- [ ] 4 usuarios creados (admin, técnico, 2 clientes)
- [ ] Contraseñas configuradas
- [ ] Todos tienen UID únicos

#### Firestore - Colección `users`
- [ ] 4 documentos creados
- [ ] Document IDs coinciden con UIDs de Auth
- [ ] Campo `rol` correctamente asignado
- [ ] Todos los campos requeridos presentes

#### Firestore - Otras Colecciones
- [ ] Todas las colecciones tienen campo `userId`
- [ ] Script de verificación muestra "✅ TODOS OK"
- [ ] No hay datos huérfanos

#### Reglas de Seguridad
- [ ] Reglas desplegadas en Firebase Console
- [ ] Fecha de actualización reciente
- [ ] Sin errores de sintaxis

#### Pruebas de Acceso
- [ ] Admin puede ver todos los datos
- [ ] Técnico ve tickets asignados
- [ ] Cliente solo ve sus datos
- [ ] Sin errores de permisos en consola

---

## 🚨 Solución de Problemas

### Error: "Missing or insufficient permissions"

**Causa**: Reglas bloqueando acceso o datos sin `userId`.

**Solución**:
1. Verifica que reglas están desplegadas
2. Ejecuta script de verificación
3. Ejecuta migración si es necesario
4. Cierra sesión y vuelve a entrar

### Error: "Cannot read properties of undefined (reading 'rol')"

**Causa**: Documento de usuario no existe en Firestore.

**Solución**:
1. Verifica que el usuario tiene documento en `/users/{uid}`
2. Confirma que el UID coincide con Authentication
3. Agrega campo `rol` si falta

### Admin no puede ver todos los datos

**Verificar**:
1. Documento en `/users/{uid}` tiene `rol: "admin"` (minúsculas)
2. Reglas están desplegadas correctamente
3. Usuario cerró sesión y volvió a entrar

---

## 📊 Resumen de Comandos

```bash
# 1. Crear usuarios (si tienes Firebase Admin SDK)
python3 /home/user/create_test_users.py

# 2. Verificar estado de datos
python3 /home/user/flutter_app/scripts/verify_userid_fields.py

# 3. Migrar datos (si es necesario)
python3 /home/user/flutter_app/scripts/migrate_userid_fields.py

# 4. Ver contenido de reglas de seguridad
cat /home/user/flutter_app/firestore.rules
```

---

## 🔗 Recursos Adicionales

- **Firebase Console**: https://console.firebase.google.com/
- **Documentación Firestore**: https://firebase.google.com/docs/firestore
- **Security Rules**: https://firebase.google.com/docs/firestore/security/get-started

---

## ✅ Próximos Pasos

Una vez completada la configuración:

1. ✅ Probar login con cada tipo de usuario
2. ✅ Crear datos de prueba con cada usuario
3. ✅ Verificar que cada usuario solo ve sus datos
4. ✅ Confirmar que admin puede gestionar todo
5. ✅ Documentar cualquier caso especial

---

## 💡 Notas Finales

- ⚠️ **Contraseñas de prueba**: Cambiar en producción
- ⚠️ **Datos migrados**: Reasignar a propietarios reales
- ✅ **Reglas activas**: Protección inmediata
- ✅ **Scripts disponibles**: Automatización completa
- ✅ **Documentación detallada**: Guías paso a paso

**¿Listo? ¡Comienza por el Paso 1!** 🚀
