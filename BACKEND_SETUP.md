# 🔥 Sutodero - Configuración del Backend

## ⚠️ IMPORTANTE: Backend Requerido

Esta aplicación utiliza una **arquitectura Backend-Only** donde:
- ✅ **Lectura**: Firestore directo (reglas de seguridad filtran por rol)
- ✅ **Escritura**: Cloud Functions API (Admin SDK sin restricciones)

**El backend DEBE estar desplegado** para que la app funcione correctamente.

---

## 📍 URL del Backend

```
https://us-central1-sutoderoapp-ee318.cloudfunctions.net/api
```

---

## 🚀 Estado Actual

❌ **Backend NO desplegado**: La app muestra error de conexión al crear tickets.

✅ **Solución**: Desplegar el backend de Cloud Functions.

---

## 🔧 Endpoints Necesarios

El backend debe implementar estos endpoints:

### 1. Crear Ticket
```
POST /tickets
Authorization: Bearer <firebase_token>
Content-Type: application/json

Body:
{
  "titulo": "Reparación de plomería",
  "descripcion": "Fuga en tubería del baño",
  "tipoServicio": "PLOMERIA",
  "prioridad": "ALTA",
  "clienteId": "user_id",
  "clienteNombre": "Juan Pérez",
  "clienteTelefono": "3001234567",
  "clienteEmail": "juan@example.com",
  "propiedadDireccion": "Calle 123 #45-67",
  "fechaProgramada": "2025-02-01T09:00:00Z",
  "notasCliente": "Urgente",
  "fotosAntes": ["https://..."],
  "presupuestoEstimado": 150000
}

Response:
{
  "success": true,
  "message": "Ticket creado correctamente",
  "data": {
    "id": "ticket_id",
    "codigo": "TKT-12345678",
    ...
  }
}
```

### 2. Obtener Tickets
```
GET /tickets?estado=NUEVO&limit=50
Authorization: Bearer <firebase_token>

Response:
{
  "success": true,
  "data": {
    "tickets": [...]
  }
}
```

### 3. Obtener Ticket por ID
```
GET /tickets/:ticketId
Authorization: Bearer <firebase_token>

Response:
{
  "success": true,
  "data": {
    "ticket": {...}
  }
}
```

### 4. Actualizar Ticket
```
PUT /tickets/:ticketId
Authorization: Bearer <firebase_token>
Content-Type: application/json

Body:
{
  "estado": "EN_PROGRESO",
  "maestroId": "maestro_id",
  "maestroNombre": "Rodrigo",
  "notasMaestro": "Iniciando trabajo"
}

Response:
{
  "success": true,
  "message": "Ticket actualizado"
}
```

### 5. Eliminar Ticket
```
DELETE /tickets/:ticketId
Authorization: Bearer <firebase_token>

Response:
{
  "success": true,
  "message": "Ticket eliminado"
}
```

---

## 🔐 Autenticación

Todos los endpoints deben:
1. Validar el token de Firebase Auth
2. Extraer el UID del usuario
3. Verificar permisos según el rol
4. Usar Firebase Admin SDK para operaciones en Firestore

---

## 📦 Estructura del Backend (Node.js + Express)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Middleware de autenticación
const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ message: 'No autorizado' });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token inválido' });
  }
};

// POST /tickets - Crear ticket
app.post('/tickets', authenticate, async (req, res) => {
  try {
    const ticketData = {
      ...req.body,
      cliente_id: req.user.uid,
      userId: req.user.uid,
      maestro_id: req.body.maestroId || null,
      fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
      estado: req.body.maestroId ? 'ASIGNADO' : 'NUEVO',
    };
    
    const docRef = await db.collection('tickets').add(ticketData);
    const newTicket = await docRef.get();
    
    res.status(201).json({
      success: true,
      message: 'Ticket creado correctamente',
      data: { id: docRef.id, ...newTicket.data() }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al crear ticket: ' + error.message
    });
  }
});

// GET /tickets - Obtener tickets
app.get('/tickets', authenticate, async (req, res) => {
  try {
    const { estado, limit = 50 } = req.query;
    
    let query = db.collection('tickets');
    
    // Filtrar por rol del usuario
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    const userRole = userDoc.data()?.rol;
    
    if (userRole === 'cliente') {
      query = query.where('clienteId', '==', req.user.uid);
    } else if (userRole === 'maestro') {
      query = query.where('maestroId', '==', req.user.uid);
    }
    // admin/coordinador ven todos
    
    if (estado) {
      query = query.where('estado', '==', estado);
    }
    
    query = query.orderBy('fechaCreacion', 'desc').limit(parseInt(limit));
    
    const snapshot = await query.get();
    const tickets = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({
      success: true,
      data: { tickets }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener tickets: ' + error.message
    });
  }
});

// PUT /tickets/:id - Actualizar ticket
app.put('/tickets/:id', authenticate, async (req, res) => {
  try {
    const ticketRef = db.collection('tickets').doc(req.params.id);
    const updateData = {
      ...req.body,
      fechaActualizacion: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await ticketRef.update(updateData);
    
    res.json({
      success: true,
      message: 'Ticket actualizado'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al actualizar: ' + error.message
    });
  }
});

// DELETE /tickets/:id - Eliminar ticket
app.delete('/tickets/:id', authenticate, async (req, res) => {
  try {
    await db.collection('tickets').doc(req.params.id).delete();
    res.json({
      success: true,
      message: 'Ticket eliminado'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al eliminar: ' + error.message
    });
  }
});

exports.api = functions.https.onRequest(app);
```

---

## 🚀 Desplegar el Backend

### Requisitos:
- Node.js 18+
- Firebase CLI instalado
- Proyecto Firebase configurado

### Pasos:

```bash
# 1. Instalar Firebase CLI (si no está instalado)
npm install -g firebase-tools

# 2. Login a Firebase
firebase login

# 3. Inicializar proyecto (si es primera vez)
firebase init functions

# 4. Instalar dependencias
cd functions
npm install firebase-functions firebase-admin express cors

# 5. Copiar el código del backend a functions/index.js

# 6. Desplegar
firebase deploy --only functions
```

---

## ✅ Verificar Despliegue

Una vez desplegado, probar:

```bash
# Health check
curl https://us-central1-sutoderoapp-ee318.cloudfunctions.net/api

# Debería responder con información del API
```

---

## 🔐 Reglas de Firestore

Las reglas deben permitir **lectura** pero **rechazar escritura**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    match /tickets/{ticketId} {
      // ✅ Lectura permitida (filtrada por backend)
      allow read: if isAuthenticated();
      
      // ❌ Escritura rechazada (solo backend con Admin SDK)
      allow create, update, delete: if false;
    }
    
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

---

## 🧪 Probar la App

Una vez desplegado el backend:

1. Abrir la app: https://5060-iaecaw9lxbp64u1sgzlot-cbeee0f9.sandbox.novita.ai
2. Iniciar sesión
3. Ir a "Mis Tickets"
4. Presionar "Nuevo Ticket"
5. Llenar formulario y guardar

**Resultado esperado:**
- ✅ Mensaje: "Ticket creado correctamente"
- ✅ Ticket aparece en la lista
- ✅ Sin errores de conexión

---

## 📖 Documentación Adicional

- **Arquitectura completa**: Ver `ARQUITECTURA_BACKEND_ONLY.md`
- **API Service**: Ver `lib/services/api_service.dart`
- **Ticket Service**: Ver `lib/services/ticket_service.dart`

---

## 🆘 Soporte

Si necesitas ayuda para desplegar el backend, contacta al equipo de desarrollo.

---

**Fecha de actualización**: Enero 2025
**Versión**: 1.0.0
