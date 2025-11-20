# Reglas de Seguridad de Firestore para SU TODERO

## 🔴 PROBLEMA CRÍTICO
Los datos NO se están guardando porque las reglas de Firestore están bloqueando las escrituras.

## ✅ SOLUCIÓN: Configurar Reglas en Firebase Console

### Paso 1: Ir a Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Selecciona el proyecto: **su-todero**
3. En el menú lateral, ve a: **Firestore Database**
4. Haz clic en la pestaña: **Reglas** (Rules)

### Paso 2: Copiar y Pegar estas Reglas

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // ✅ Regla para colección de usuarios
    // Los usuarios pueden leer y escribir solo sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // ✅ Propiedades del usuario (inventarios)
      match /properties/{propertyId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // ✅ Habitaciones/espacios de una propiedad
        match /rooms/{roomId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
    
    // ✅ Regla para tickets (opcional - si se usa)
    match /tickets/{ticketId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // ✅ Regla para logs de actividad (opcional)
    match /activity_logs/{logId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    
    // ✅ Regla para listados de propiedades (captación)
    match /property_listings/{listingId} {
      allow read: if true; // Público (todos pueden ver)
      allow write: if request.auth != null; // Solo usuarios autenticados pueden crear
    }
    
    // ❌ Bloquear todo lo demás por defecto
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Paso 3: Publicar las Reglas
1. Haz clic en el botón **"Publicar"** (Publish)
2. Espera la confirmación de que las reglas se aplicaron

## 🧪 Para Desarrollo/Testing (SOLO TEMPORAL)

Si quieres probar la app sin restricciones (⚠️ NO usar en producción):

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ IMPORTANTE**: Esta regla permite que cualquier usuario autenticado lea/escriba TODO.
Solo usar para testing. Luego cambiar a las reglas de producción de arriba.

## 🔥 Reglas de Firebase Storage (para fotos)

También debes configurar Firebase Storage para permitir subir fotos:

1. Ve a: **Storage** en Firebase Console
2. Haz clic en: **Reglas** (Rules)
3. Usa estas reglas:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // ✅ Fotos de perfil de usuarios
    match /users/{userId}/profile/{allPaths=**} {
      allow read: if true; // Cualquiera puede ver fotos de perfil
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ✅ Fotos de propiedades/inventarios
    match /users/{userId}/properties/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ✅ Fotos de tickets
    match /tickets/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // ❌ Bloquear todo lo demás
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## 🔍 Verificar que Funcionó

Después de aplicar las reglas:

1. **Registra un usuario nuevo** en la app
2. **Crea una propiedad** en Inventarios
3. Ve a Firestore en Firebase Console
4. Deberías ver:
   ```
   📁 users/
      └── 📁 {uid del usuario}/
           ├── 📄 (datos del usuario)
           └── 📁 properties/
                └── 📄 {id de la propiedad}
   ```

## ❓ Si Sigue Sin Funcionar

1. **Verifica que Firebase Authentication esté habilitado**:
   - Firebase Console → Authentication
   - Debe tener el método "Email/Password" habilitado

2. **Verifica los logs de la app**:
   - Conecta el teléfono por USB
   - Ejecuta: `adb logcat | grep -i firestore`
   - Busca errores como "PERMISSION_DENIED"

3. **Verifica la API Key**:
   - La API key en `firebase_options.dart` debe ser: `AIzaSyBVYy6qGJvV1Kizim3KnTEZfHRC9EYOjmg`
   - La del `google-services.json` debe ser la misma

## 📞 Contacto

Si después de aplicar estas reglas sigue sin funcionar, necesitamos:
1. Los logs de la app (con `adb logcat`)
2. Screenshot de las reglas aplicadas en Firebase Console
3. Screenshot del error que muestra la app
