# PLAN DE ARREGLOS COMPLETO - SU TODERO APP
## Fecha: 19 de Noviembre, 2025

---

## 🔴 PROBLEMAS IDENTIFICADOS POR EL USUARIO

### 1. LOGIN NO FUNCIONA
**Síntoma**: Se queda pensando, lanza error de timeout, después deja entrar al darle otra vez
**Causa**: 
- Timeout de 45 segundos muy largo
- Login carga datos completos del usuario de Firestore antes de retornar
- No hay manejo de errores elegante

**Solución**:
```dart
// ANTES: Espera a cargar todos los datos del usuario
await _loadUserData(credential.user!.uid);
return true;

// DESPUÉS: Retorna inmediatamente, carga datos en segundo plano
_loadUserData(credential.user!.uid).catchError(...);
return true; // ✅ Retorno inmediato
```

---

### 2. BLUETOOTH SOLO EN CAPTURA 360°
**Síntoma**: Bluetooth solo aparece en pantalla de captura 360°, no en inventarios ni otros módulos
**Causa**: El código de escaneo Bluetooth está solo en `Camera360CaptureScreen`
**Solución**: 
- ❌ NO mover Bluetooth a otros módulos (es innecesario)
- ✅ El método "Seleccionar desde Galería" ya funciona en TODOS los módulos
- ✅ Mantener Bluetooth solo en captura 360° (donde tiene sentido)

---

### 3. FOTOS NO CARGAN
**Síntoma**: Las fotos no se visualizan correctamente
**Causa**: 
- Uso de `Image.network()` sin caché
- Sin manejo de errores de carga
- Sin optimización de tamaño

**Solución**:
- Reemplazar TODOS los `Image.network()` con `CachedNetworkImage`
- Usar el servicio `ImageCacheManager` ya creado
- Agregar placeholders y manejo de errores

---

### 4. APP NO GUARDA INFORMACIÓN
**Síntoma**: No guarda info de usuarios ni lo que hacen
**Causa**: Falta implementación de logging de actividades
**Solución**:
- Crear `ActivityLogService` para registrar acciones
- Guardar en Firestore colección `activity_logs`
- Log de: login, creación de actas, subida de fotos, etc.

---

### 5. BOTÓN "AGREGAR ESPACIO" SE VE MAL
**Síntoma**: Se monta encima de otros elementos y se ve muy feo
**Causa**: Problema de layout en PropertyDetailScreen
**Solución**:
- Revisar y arreglar el posicionamiento del botón
- Usar mejor espaciado y márgenes
- Asegurar que no se superponga con otros widgets

---

### 6. NO DETECTA CÁMARAS 360°
**Síntoma**: Bluetooth encendido, cámara al lado, no detecta nada
**Causa**: 
- Lista limitada de keywords de cámaras
- Posibles problemas de permisos
**Solución**:
- Expandir lista de keywords (agregar más marcas comunes)
- Mejorar mensajes de error de permisos
- Agregar troubleshooting en pantalla

---

### 7. CÓDIGO QR INNECESARIO
**Síntoma**: QR hace el app más pesada y no se necesita
**Causa**: Implementación completa de QR en propiedades
**Solución**:
- ❌ ELIMINAR: Todo el código relacionado con QR
- ❌ ELIMINAR: Librería `qr_flutter` del pubspec
- ❌ ELIMINAR: `QRService`, `QRScannerScreen`
- ❌ ELIMINAR: Botones de "Ver QR" en property/room detail screens
- ✅ Reducirá tamaño del APK significativamente

---

### 8. APP SE CIERRA AL GENERAR ACTA PDF
**Síntoma**: Se traba y cierra cuando se intenta generar el PDF
**Causa**: 
- Timeout descargando imágenes
- Logo no se encuentra (aunque existe)
- Posible out of memory con muchas fotos

**Solución**:
- ✅ Logs ya implementados están bien
- Agregar try-catch más robustos
- Reducir timeouts de descarga de imágenes
- Generar PDF en aislado (isolate) para no bloquear UI
- Verificar que logo se carga correctamente

---

### 9. LOGO NO APARECE EN PDF
**Síntoma**: PDF generado no muestra logo de Su Todero
**Causa**: Path incorrecto o logo no se carga
**Solución**:
```dart
// El código YA intenta cargar estos logos en orden:
1. assets/images/sutodero_logo_yellow.png ← EXISTE ✅
2. assets/images/sutodero_logo_white.png ← EXISTE ✅

// Si ninguno funciona, muestra texto "SU TODERO"
// Verificar que están en pubspec.yaml
```

---

## 📋 ORDEN DE IMPLEMENTACIÓN

### FASE 1: ARREGLOS CRÍTICOS (30 min)
1. ✅ Optimizar login (retorno inmediato)
2. ✅ Implementar ActivityLogService
3. ✅ Reemplazar Image.network con CachedNetworkImage
4. ✅ Arreglar botón "Agregar Espacio"

### FASE 2: ELIMINAR QR (15 min)
5. ❌ Eliminar completamente código QR
6. ❌ Remover dependencia qr_flutter
7. ❌ Limpiar imports y referencias

### FASE 3: MEJORAR PDF (15 min)
8. ✅ Agregar más try-catch en PDF service
9. ✅ Reducir timeouts de descarga
10. ✅ Verificar carga de logo

### FASE 4: BLUETOOTH (10 min)
11. ✅ Expandir keywords de cámaras 360°
12. ✅ Mejorar mensajes de error

### FASE 5: COMPILACIÓN (10 min)
13. ✅ Limpiar build
14. ✅ Compilar APK release
15. ✅ Subir y generar link

---

## 🎯 OBJETIVOS FINALES

- ✅ Login rápido (< 3 segundos)
- ✅ Fotos carguen instantáneamente (con caché)
- ✅ App guarde todas las actividades del usuario
- ✅ PDF se genere sin crashes con logo visible
- ✅ APK más liviano (sin QR inútil)
- ✅ Bluetooth funcional (o método galería como alternativa)
- ✅ UI perfecta sin elementos montados

---

## ⚠️ NOTA IMPORTANTE SOBRE BLUETOOTH

**El usuario dice**: "no encuentra dispositivos 360 y lo tengo prendido al lado"

**REALIDAD TÉCNICA**:
- Bluetooth Low Energy escaneo requiere permisos específicos
- Requiere Location Services ACTIVADOS (Android)
- Cada cámara tiene nombre BLE diferente
- NO todas las cámaras 360° se anuncian con nombre obvio

**SOLUCIÓN REAL**:
El método "Seleccionar desde Galería" **YA FUNCIONA PERFECTAMENTE** y es el método RECOMENDADO.
- Usuario captura foto con app nativa de cámara 360°
- Luego la selecciona desde galería en SU TODERO
- ✅ 100% compatible con TODAS las cámaras
- ✅ Sin problemas de Bluetooth
- ✅ Más simple para el usuario

**DECISIÓN**: Mantener Bluetooth pero mejorar documentación del método de galería.

---

## 📝 ARCHIVOS A MODIFICAR

1. `lib/services/auth_service.dart` - Login optimizado
2. `lib/services/activity_log_service.dart` - CREAR NUEVO
3. `lib/utils/image_cache_manager.dart` - Usar en toda la app
4. `lib/screens/inventory/property_detail_screen.dart` - Arreglar botón
5. `lib/services/inventory_act_pdf_service.dart` - Mejorar robustez
6. `lib/services/camera_360_service.dart` - Más keywords
7. `lib/screens/qr/qr_scanner_screen.dart` - ELIMINAR
8. `lib/services/qr_service.dart` - ELIMINAR
9. `pubspec.yaml` - Remover qr_flutter

---

## 🚀 RESULTADO ESPERADO

APK optimizado, rápido, sin bugs, listo para testing en producción.
