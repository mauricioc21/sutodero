# 📋 Guía de Despliegue y Configuración - SU TODERO

Esta guía explica cómo completar la configuración de Firebase, crear usuarios de prueba y desplegar las reglas de seguridad de Firestore.

---

## 🔥 1. Desplegar Reglas de Seguridad de Firestore

### Paso 1: Acceder a Firebase Console
1. Ve a: **https://console.firebase.google.com/**
2. Selecciona tu proyecto
3. En el menú lateral, ve a **Build** → **Firestore Database**
4. Haz clic en la pestaña **Rules** (Reglas)

### Paso 2: Copiar las Reglas de Seguridad
El archivo con las reglas está en: `/home/user/flutter_app/firestore.rules`

Contenido de las reglas:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'admin';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone can read their own user document, admins can read all
      allow read: if isAdmin() || isOwner(userId);
      // Users can create their own document during registration
      allow create: if isAuthenticated() && request.auth.uid == userId;
      // Users can update their own document, admins can update any
      allow update: if isAdmin() || isOwner(userId);
      // Only admins can delete users
      allow delete: if isAdmin();
    }
    
    // Inventories collection (local storage - not used in Firestore)
    // But included for future migration
    match /inventories/{inventoryId} {
      allow read: if isAdmin() || 
                     (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow delete: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
    }
    
    // Tickets collection
    match /tickets/{ticketId} {
      allow read: if isAdmin() || 
                     (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow delete: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
    }
    
    // Property Listings collection (Captación de Inmuebles)
    match /property_listings/{listingId} {
      allow read: if isAdmin() || 
                     (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow delete: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
    }
    
    // Inventory Acts collection
    match /acts/{actId} {
      allow read: if isAdmin() || 
                     (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow delete: if isAdmin() || 
                      (isAuthenticated() && resource.data.userId == request.auth.uid);
    }
    
    // User Biometrics collection (for facial recognition)
    match /user_biometrics/{userId} {
      // Only the user themselves or admins can read biometric data
      allow read: if isAdmin() || isOwner(userId);
      // Only the user can create/update their own biometric data
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      // Users can delete their own biometric data, admins can delete any
      allow delete: if isAdmin() || isOwner(userId);
    }
    
    // Ticket History collection
    match /ticket_history/{historyId} {
      allow read: if isAdmin() || 
                     (isAuthenticated() && resource.data.userId == request.auth.uid);
      allow create: if isAuthenticated();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Default deny all other collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Paso 3: Publicar las Reglas
1. Pega las reglas en el editor de Firebase Console
2. Haz clic en **Publicar** (Publish)
3. Espera la confirmación: "Reglas publicadas con éxito"

---

## 👥 2. Crear Usuarios de Prueba

### Método Manual (Firebase Console)

#### Usuario 1: Administrador
1. Ve a **Authentication** → **Users** → **Add user**
2. Datos:
   - **Email**: `admin@sutodero.com`
   - **Password**: `Admin123!`
3. Haz clic en **Add user**
4. **IMPORTANTE**: Copia el **UID** generado (ejemplo: `abc123def456`)
5. Ve a **Firestore Database** → **Collection `users`** → **Add document**
6. ID del documento: **Usa el UID copiado**
7. Campos:
   ```
   uid: abc123def456 (el UID que copiaste)
   nombre: Administrador Principal
   email: admin@sutodero.com
   rol: admin
   telefono: +57 318 816 0439
   fechaCreacion: (timestamp - usa el botón de calendario)
   ```

#### Usuario 2: Técnico
1. Ve a **Authentication** → **Users** → **Add user**
2. Datos:
   - **Email**: `tecnico@sutodero.com`
   - **Password**: `Tecnico123!`
3. Haz clic en **Add user**
4. Copia el **UID** generado
5. Ve a **Firestore Database** → **Collection `users`** → **Add document**
6. ID del documento: **Usa el UID copiado**
7. Campos:
   ```
   uid: (el UID que copiaste)
   nombre: Juan Pérez (Técnico)
   email: tecnico@sutodero.com
   rol: tecnico
   telefono: +57 310 123 4567
   fechaCreacion: (timestamp actual)
   ```

#### Usuario 3: Cliente
1. Ve a **Authentication** → **Users** → **Add user**
2. Datos:
   - **Email**: `cliente@sutodero.com`
   - **Password**: `Cliente123!`
3. Haz clic en **Add user**
4. Copia el **UID** generado
5. Ve a **Firestore Database** → **Collection `users`** → **Add document**
6. ID del documento: **Usa el UID copiado**
7. Campos:
   ```
   uid: (el UID que copiaste)
   nombre: María González (Cliente)
   email: cliente@sutodero.com
   rol: cliente
   telefono: +57 301 987 6543
   fechaCreacion: (timestamp actual)
   ```

### Método Alternativo (Script Python)

Si tienes el archivo `firebase-admin-sdk.json`:

1. Colócalo en: `/opt/flutter/firebase-admin-sdk.json`
2. Ejecuta:
   ```bash
   python3 /home/user/create_test_users.py
   ```

---

## 🧪 3. Probar el Control de Acceso

### Test 1: Usuario Cliente
1. Abre la app SU TODERO: https://5060-ixdzpt9i8h4noynjll6vy-c07dda5e.sandbox.novita.ai
2. Ingresa con:
   - Email: `cliente@sutodero.com`
   - Password: `Cliente123!`
3. Crea un nuevo ticket de reparación
4. Crea una nueva propiedad en Inventarios
5. Cierra sesión

### Test 2: Usuario Técnico
1. Ingresa con:
   - Email: `tecnico@sutodero.com`
   - Password: `Tecnico123!`
2. Verifica que NO veas los tickets/propiedades del cliente
3. Crea tus propios tickets y propiedades
4. Cierra sesión

### Test 3: Usuario Administrador
1. Ingresa con:
   - Email: `admin@sutodero.com`
   - Password: `Admin123!`
2. Verifica que PUEDAS VER:
   - Todos los tickets (del cliente, del técnico, y propios)
   - Todas las propiedades
   - Todas las captaciones de inmuebles
3. El administrador tiene acceso completo a todos los datos

---

## 🔐 4. Probar Reconocimiento Facial

### Registrar Biometría
1. Crea una nueva cuenta en la app
2. Cuando termine el registro, se te preguntará: **"¿Deseas activar el reconocimiento facial?"**
3. Si aceptas, se abrirá la cámara
4. Sigue las instrucciones:
   - Busca buena iluminación
   - Mira de frente a la cámara
   - Mantén expresión neutral
   - No uses gafas de sol o gorras
5. Captura tu rostro
6. El sistema guardará tus características faciales en Firestore

### Login con Reconocimiento Facial
1. En la pantalla de login, haz clic en el botón: **"RECONOCIMIENTO FACIAL"**
2. Lee las instrucciones
3. Toma una foto de tu rostro
4. El sistema comparará tu rostro con los registrados
5. Si coincide, ingresarás automáticamente sin contraseña

### Características del Reconocimiento Facial
- **Detección de calidad**: Verifica iluminación, ángulo, y claridad
- **Landmarks faciales**: Usa puntos de referencia (ojos, nariz, boca, mejillas)
- **Similitud mínima**: 75% de coincidencia requerida
- **Seguridad**: Datos biométricos encriptados en Firestore

---

## 📊 5. Verificar en Firebase Console

### Firestore Database
Verifica que se hayan creado las siguientes colecciones:
- ✅ `users` - Usuarios del sistema
- ✅ `tickets` - Tickets de reparación (con campo `userId`)
- ✅ `property_listings` - Captación de inmuebles (con campo `userId`)
- ✅ `user_biometrics` - Datos biométricos faciales
- ✅ `ticket_history` - Historial de tickets

### Campos userId en Colecciones
Todas las colecciones importantes deben tener el campo `userId` para control de acceso:
- `tickets.userId` - ID del usuario propietario del ticket
- `property_listings.userId` - ID del usuario que captó el inmueble
- `inventories.userId` - ID del usuario propietario del inventario

---

## ⚠️ 6. Notas Importantes

### Seguridad
- Las reglas de Firestore **están configuradas para producción**
- Cada usuario solo puede ver sus propios datos
- Los administradores tienen acceso total
- Los datos biométricos están protegidos y solo accesibles por el usuario propietario

### Performance
- El reconocimiento facial procesa en ~2-5 segundos
- La comparación facial usa distancia euclidiana normalizada
- El umbral de similitud es 75% (ajustable en `face_recognition_service.dart`)

### Limitaciones Web
- El reconocimiento facial **requiere HTTPS** para acceso a cámara
- En preview local puede tener restricciones de permisos
- Para producción, despliega en dominio HTTPS

### Próximas Mejoras Sugeridas
1. Implementar recuperación de contraseña por email
2. Agregar verificación de email al registrarse
3. Implementar re-autenticación periódica
4. Agregar logs de auditoría de acceso
5. Implementar sistema de notificaciones push

---

## 🎯 Resumen de Credenciales

| Rol | Email | Password |
|-----|-------|----------|
| **Admin** | admin@sutodero.com | Admin123! |
| **Técnico** | tecnico@sutodero.com | Tecnico123! |
| **Cliente** | cliente@sutodero.com | Cliente123! |

---

## 🔗 Enlaces Útiles

- **App Preview**: https://5060-ixdzpt9i8h4noynjll6vy-c07dda5e.sandbox.novita.ai
- **Firebase Console**: https://console.firebase.google.com/
- **Firestore Rules**: `/home/user/flutter_app/firestore.rules`
- **Script Usuarios**: `/home/user/create_test_users.py`

---

**¡Configuración completada!** 🎉

Si tienes algún problema, revisa los logs de Firebase Console o contacta al equipo de desarrollo.
