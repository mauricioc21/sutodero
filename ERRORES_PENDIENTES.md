# Errores Pendientes - SU TODERO App

## 📋 LISTA DE ERRORES REPORTADOS

### ✅ 1. Foto de perfil no se carga
**Estado**: ✅ SOLUCIONADO (commit 9394ea6)
- La foto ahora se guarda en Storage, Firestore y Auth
- Agregado logging detallado

### ⏳ 2. Botones al final quedan montados con botones del sistema
**Estado**: 🔄 EN PROGRESO
**Solución**:
- Agregada constante `AppTheme.safeBottomPadding = 80px`
- Falta aplicar en todas las pantallas

**Archivos a modificar**:
- `lib/screens/inventory/add_edit_property_screen.dart`
- `lib/screens/inventory/add_edit_room_screen.dart`
- `lib/screens/profile/user_profile_screen.dart`
- `lib/screens/tickets/add_edit_ticket_screen.dart`
- Todos los formularios que tengan botones al final

**Código a aplicar**:
```dart
// Envolver el botón en Padding:
Padding(
  padding: const EdgeInsets.only(bottom: AppTheme.safeBottomPadding),
  child: ElevatedButton(...),
)
```

### ❌ 3. Acta de inventario no funciona
**Estado**: ❌ CRÍTICO - NO FUNCIONA
**Problema**:
- La ventana flotante no hace nada al oprimir continuar/cancelar
- Cambia lo que hay detrás pero no cierra

**Archivo**: `lib/screens/inventory/sign_inventory_act_screen.dart`

**Solución requerida**:
- Revisar el Navigator.pop() en botones
- Agregar botón X en la esquina para cerrar
- Verificar que el proceso de firma funcione

### ❌ 4. Falta foto + firma en acta (doble factor)
**Estado**: ❌ FUNCIONALIDAD FALTANTE
**Requerimiento**:
- Al firmar acta, debe capturar:
  1. Firma digital (canvas)
  2. Foto de la persona firmando

**Implementación sugerida**:
```dart
1. Pantalla de firma actual
2. Botón "Tomar foto de confirmación"
3. Captura foto con cámara
4. Guardar ambos: firma + foto
5. Incluir ambos en el PDF del inventario
```

### ❌ 5. Captura de cámara no permite elegir galería
**Estado**: ❌ UX MEJORABLE
**Problema**:
- "Capturar con Cámara del Teléfono" solo permite cámara
- Debería permitir elegir: Cámara O Galería

**Archivos afectados**:
- Todas las pantallas con captura de fotos
- `room_detail_screen.dart` (fotos de espacios)
- Captura de fotos 360°

**Solución**:
```dart
// Mostrar diálogo con opciones
final source = await showDialog<ImageSource>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Seleccionar imagen'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.camera_alt),
          title: Text('Tomar Foto'),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: Icon(Icons.photo_library),
          title: Text('Seleccionar de Galería'),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    ),
  ),
);
```

### ❌ 6. Plano 2D dice que se generó pero no existe
**Estado**: ❌ CRÍTICO - FUNCIONALIDAD ROTA
**Problema**:
- Aparece toast "Plano 2D guardado"
- Pero el archivo NO se guarda en ningún lado
- NO aparece en el PDF

**Causa probable**:
- El código genera el archivo temporalmente
- Pero no lo sube a Firebase Storage
- O no guarda la referencia en Firestore

**Solución requerida**:
1. Generar plano 2D en memoria
2. Subir a Firebase Storage (`/users/{userId}/properties/{propertyId}/planos/`)
3. Guardar URL en Firestore
4. Mostrar en la UI
5. Incluir en PDF del inventario

### ❌ 7. Plano 3D dice que se generó pero no existe
**Estado**: ❌ CRÍTICO - FUNCIONALIDAD ROTA
**Mismo problema que Plano 2D**

### ❌ 8. Fotos 360° no se suben ni muestran
**Estado**: ❌ CRÍTICO - FUNCIONALIDAD ROTA
**Problema**:
- Al seleccionar foto 360° de galería, no pasa nada
- La foto no se sube a Firebase Storage
- No se muestra en ningún lado
- No aparece en el PDF

**Solución requerida**:
1. Capturar/seleccionar foto 360°
2. Subir a Firebase Storage (`/users/{userId}/properties/{propertyId}/rooms/{roomId}/360/`)
3. Guardar URL en Firestore (campo `foto360Url` del room)
4. Mostrar en room_detail_screen con visor 360°
5. Incluir en PDF

### ❌ 9. PDF del inventario no incluye fotos, planos ni firma
**Estado**: ❌ CRÍTICO - REPORTE INCOMPLETO
**Problema**:
- El PDF solo muestra datos de texto
- NO incluye:
  - Fotos de los espacios
  - Plano 2D
  - Plano 3D
  - Fotos 360°
  - Firma del acta
  - Foto de confirmación de la firma

**Archivo**: `lib/services/inventory_pdf_service.dart`

**Solución requerida**:
```dart
// En el PDF debe aparecer:
1. Datos de la propiedad
2. Datos del cliente
3. Lista de espacios con:
   - Descripción del espacio
   - Fotos del espacio (grid 2x2)
   - Foto 360° (miniatura con indicador)
4. Plano 2D (imagen completa)
5. Plano 3D (imagen completa)
6. Sección de firma con:
   - Firma digital
   - Foto de la persona firmando
   - Fecha y hora
   - Nombre del firmante
```

### ⏳ 10. Ventana flotante de acta necesita botón X
**Estado**: ⏳ UX MEJORABLE
**Solución simple**:
```dart
// Agregar IconButton en esquina superior derecha:
Positioned(
  top: 8,
  right: 8,
  child: IconButton(
    icon: Icon(Icons.close),
    onPressed: () => Navigator.pop(context),
  ),
)
```

---

## 🎯 PRIORIDAD DE IMPLEMENTACIÓN

### Prioridad ALTA (Funcionalidad rota):
1. ❌ Acta de inventario no funciona
2. ❌ Plano 2D no se guarda
3. ❌ Plano 3D no se guarda
4. ❌ Fotos 360° no se suben
5. ❌ PDF incompleto (falta TODO)

### Prioridad MEDIA (UX/Funcionalidad faltante):
6. ❌ Falta foto + firma en acta
7. ⏳ Botones montados con sistema (parcialmente resuelto)
8. ❌ Captura de cámara sin opción de galería

### Prioridad BAJA (UX mejorable):
9. ⏳ Botón X en ventana flotante

---

## 📝 NOTAS TÉCNICAS

### Firebase Storage - Estructura de carpetas:
```
/users/{userId}/
  ├── profile/
  │   └── avatar.jpg
  ├── properties/{propertyId}/
  │   ├── planos/
  │   │   ├── plano_2d.png
  │   │   └── plano_3d.png
  │   ├── rooms/{roomId}/
  │   │   ├── photos/
  │   │   │   ├── photo_1.jpg
  │   │   │   ├── photo_2.jpg
  │   │   │   └── ...
  │   │   └── 360/
  │   │       └── panorama.jpg
  │   └── actas/
  │       ├── firma_{timestamp}.png
  │       └── foto_confirmacion_{timestamp}.jpg
```

### Firestore - Estructura de datos:
```javascript
users/{userId}/properties/{propertyId}
  - direccion: string
  - clienteNombre: string
  - ...
  - plano2dUrl: string (URL de Firebase Storage)
  - plano3dUrl: string (URL de Firebase Storage)
  - actaFirmadaUrl: string (URL del PDF firmado)
  - actaFirmaDigitalUrl: string (URL de la firma)
  - actaFotoConfirmacionUrl: string (URL de la foto)
  - actaFechaFirma: timestamp
  - actaNombreFirmante: string
  
users/{userId}/properties/{propertyId}/rooms/{roomId}
  - nombre: string
  - ...
  - fotos: array[string] (URLs de fotos normales)
  - foto360Url: string (URL de foto 360°)
```

---

## 🔧 ARCHIVOS PRINCIPALES A MODIFICAR

1. **Acta de inventario**:
   - `lib/screens/inventory/sign_inventory_act_screen.dart`

2. **Planos 2D/3D**:
   - `lib/screens/inventory/property_detail_screen.dart`
   - `lib/services/floor_plan_service.dart` (crear si no existe)

3. **Fotos 360°**:
   - `lib/screens/inventory/room_detail_screen.dart`
   - `lib/services/storage_service.dart`

4. **PDF completo**:
   - `lib/services/inventory_pdf_service.dart`

5. **Márgenes inferiores**:
   - Todos los formularios con botones al final

---

## 📊 ESTIMACIÓN DE TIEMPO

| Tarea | Tiempo estimado | Prioridad |
|-------|----------------|-----------|
| Arreglar acta | 2-3 horas | ALTA |
| Guardar planos 2D/3D | 3-4 horas | ALTA |
| Subir fotos 360° | 2-3 horas | ALTA |
| PDF completo con imágenes | 4-5 horas | ALTA |
| Foto + firma en acta | 2 horas | MEDIA |
| Botones con margin-bottom | 1 hora | MEDIA |
| Opción galería en cámara | 1 hora | MEDIA |
| Botón X en ventanas | 30 min | BAJA |
| **TOTAL** | **16-19 horas** | |

---

## ✅ CHECKLIST DE VERIFICACIÓN

Después de implementar cada fix:

- [ ] Acta de inventario funciona
  - [ ] Botón continuar cierra ventana
  - [ ] Botón cancelar cierra ventana
  - [ ] Botón X cierra ventana
  - [ ] Firma se guarda
  - [ ] Foto de confirmación se captura y guarda

- [ ] Planos funcionan
  - [ ] Plano 2D se genera y guarda
  - [ ] Plano 3D se genera y guarda
  - [ ] Planos se pueden ver en la UI
  - [ ] Planos aparecen en Firebase Storage
  - [ ] URLs se guardan en Firestore

- [ ] Fotos 360° funcionan
  - [ ] Se pueden capturar/seleccionar
  - [ ] Se suben a Firebase Storage
  - [ ] Se muestran en room detail
  - [ ] Aparecen en el PDF

- [ ] PDF completo
  - [ ] Incluye fotos de espacios
  - [ ] Incluye plano 2D
  - [ ] Incluye plano 3D
  - [ ] Incluye fotos 360° (miniatura)
  - [ ] Incluye firma digital
  - [ ] Incluye foto de confirmación

- [ ] UX mejorado
  - [ ] Botones no se montan con sistema
  - [ ] Opción de cámara o galería en todos lados
  - [ ] Ventanas tienen botón X para cerrar
