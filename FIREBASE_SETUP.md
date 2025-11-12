# 🔥 Guía de Configuración de Firebase para SUTODERO

## ✅ Estado Actual de la Integración

### Ya Implementado:
- ✅ Dependencias de Firebase instaladas (firebase_core, firebase_auth, cloud_firestore)
- ✅ Archivo `firebase_options.dart` creado
- ✅ `AuthService` actualizado con Firebase Authentication completo
- ✅ Inicialización de Firebase en `main.dart`
- ✅ Manejo de errores en español
- ✅ Modo fallback local (funciona sin Firebase si no está configurado)

### Características Implementadas:
- 🔐 **Login con Firebase Auth**
- 👤 **Registro de usuarios con Firestore**
- 📧 **Recuperación de contraseña**
- 💾 **Almacenamiento de perfil en Firestore**
- 🔄 **Actualización de perfil**
- 🚪 **Logout**
- ⚠️ **Mensajes de error localizados**

---

## 📋 Pasos para Completar la Configuración

### **Paso 1: Crear Proyecto en Firebase Console**

1. Ve a: https://console.firebase.google.com/
2. Haz clic en **"Agregar proyecto"**
3. Nombre del proyecto: **sutodero-app** (o el que prefieras)
4. Deshabilita Google Analytics si no lo necesitas
5. Haz clic en **"Crear proyecto"**

---

### **Paso 2: Configurar Aplicación Web**

1. En la consola de Firebase, haz clic en el ícono **Web** (</>)
2. Registra la app con el nombre: **SUTODERO Web**
3. Copia la configuración que aparece (será algo como esto):

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "sutodero-app.firebaseapp.com",
  projectId: "sutodero-app",
  storageBucket: "sutodero-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef..."
};
```

4. **Actualiza `lib/firebase_options.dart`**:
   - Reemplaza los valores de la sección `web` con tu configuración
   - Reemplaza:
     - `YOUR_WEB_API_KEY` → tu `apiKey`
     - `YOUR_APP_ID` → tu `appId`
     - `YOUR_SENDER_ID` → tu `messagingSenderId`
     - `sutodero-app` → tu `projectId` (si es diferente)

---

### **Paso 3: Configurar Aplicación Android** (Opcional - para APK)

1. En la consola de Firebase, haz clic en **Android** (ícono de Android)
2. **Package name**: `com.sutodero.app` (o el que uses en tu app)
3. Descarga el archivo `google-services.json`
4. Coloca el archivo en: `/home/user/flutter_app/android/app/google-services.json`
5. Actualiza `lib/firebase_options.dart` sección `android` con tus datos

---

### **Paso 4: Habilitar Firebase Authentication**

1. En la consola de Firebase, ve a **Authentication** > **Sign-in method**
2. Habilita **Email/Password**:
   - Haz clic en "Email/Password"
   - Activa "Enable"
   - Guarda los cambios

---

### **Paso 5: Configurar Cloud Firestore**

1. En la consola de Firebase, ve a **Firestore Database**
2. Haz clic en **"Crear base de datos"**
3. Selecciona:
   - **Modo de producción** (más seguro)
   - **Ubicación**: elige la más cercana (us-central, southamerica-east1, etc.)
4. Haz clic en **"Habilitar"**

#### **Reglas de Seguridad Recomendadas:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Regla para colección de usuarios
    match /users/{userId} {
      // Usuarios pueden leer su propio perfil
      allow read: if request.auth != null && request.auth.uid == userId;
      // Usuarios pueden actualizar su propio perfil
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Regla para colección de propiedades (inventarios)
    match /properties/{propertyId} {
      // Solo usuarios autenticados pueden leer/escribir
      allow read, write: if request.auth != null;
    }
    
    // Regla para colección de espacios (rooms)
    match /rooms/{roomId} {
      // Solo usuarios autenticados pueden leer/escribir
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### **Paso 6: Configurar Firebase Storage** (Opcional - para fotos)

1. En la consola de Firebase, ve a **Storage**
2. Haz clic en **"Comenzar"**
3. Selecciona reglas de prueba o producción
4. Haz clic en **"Listo"**

#### **Reglas de Seguridad para Storage:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /properties/{propertyId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /rooms/{roomId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 🧪 Probar la Integración

### **Opción 1: Con Firebase Configurado**

1. Actualiza `lib/firebase_options.dart` con tus credenciales
2. Recompila la app:
   ```bash
   cd /home/user/flutter_app
   flutter build web --release
   ```
3. Intenta registrarte con un email real
4. Verifica en Firebase Console > Authentication que el usuario se creó
5. Verifica en Firestore que el documento del usuario existe

### **Opción 2: Sin Firebase (Modo Local)**

La app funcionará automáticamente en modo demo si Firebase no está configurado:
- ✅ Login funciona con cualquier email/contraseña
- ✅ Crea usuario demo local
- ✅ Todos los datos se guardan en Hive (local)
- ⚠️ Los datos NO se sincronizan entre dispositivos

---

## 🔍 Verificar el Estado de Firebase

Puedes verificar si Firebase está funcionando en los logs de la app:

```
✅ Firebase inicializado correctamente  → Firebase está activo
⚠️ Firebase no disponible, usando modo local  → Modo demo
```

---

## 📱 Próximos Pasos Recomendados

Una vez que Firebase esté configurado:

### 1. **Migrar InventoryService a Firestore**
   - Actualmente usa Hive (local)
   - Migrar a Firestore para sincronización en la nube
   
### 2. **Implementar Firebase Storage**
   - Subir fotos de inventarios a la nube
   - Sincronizar fotos entre dispositivos
   
### 3. **Agregar Cloud Functions** (opcional)
   - Generación automática de planos con IA
   - Procesamiento de imágenes 360°
   - Notificaciones push

---

## ❓ Preguntas Frecuentes

**Q: ¿La app funciona sin Firebase?**  
A: Sí, funciona en modo local con Hive. Los datos se guardan solo en el dispositivo.

**Q: ¿Necesito tarjeta de crédito para Firebase?**  
A: No para el plan gratuito (Spark). Incluye:
- Authentication: Ilimitado
- Firestore: 50,000 lecturas/día
- Storage: 1GB almacenamiento

**Q: ¿Puedo cambiar las credenciales después?**  
A: Sí, solo actualiza `firebase_options.dart` y recompila.

**Q: ¿Cómo actualizo solo el código de autenticación?**  
A: Los cambios en `auth_service.dart` no requieren reconfiguración de Firebase.

---

## 🆘 Soporte

Si encuentras problemas:
1. Verifica los logs de la app
2. Revisa las reglas de seguridad en Firebase Console
3. Asegúrate de que Authentication esté habilitado
4. Verifica que Firestore esté creado

---

## 📝 Notas Adicionales

- **Versiones fijas**: Las versiones de Firebase están fijas para estabilidad
- **No actualizar**: No uses `flutter pub upgrade` para Firebase
- **Compatibilidad**: Configuración probada con Flutter 3.35.4

---

**¡Firebase está listo para usar! Solo necesitas configurar tus credenciales.** 🚀
