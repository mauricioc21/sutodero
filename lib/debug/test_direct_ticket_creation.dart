import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// TEST DIRECTO PARA CREAR TICKET EN FIRESTORE
/// Este código crea un ticket directamente sin pasar por servicios
Future<void> testDirectTicketCreation() async {
  print('🧪 === TEST DIRECTO DE CREACIÓN DE TICKET ===');
  
  // 1. Verificar usuario autenticado
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('❌ ERROR: No hay usuario autenticado');
    return;
  }
  
  print('✅ Usuario autenticado:');
  print('   UID: ${currentUser.uid}');
  print('   Email: ${currentUser.email}');
  
  // 2. Crear documento de prueba con TODOS los campos requeridos
  final ticketId = 'test_${DateTime.now().millisecondsSinceEpoch}';
  final now = DateTime.now();
  
  final ticketData = {
    // ===== CAMPOS CRÍTICOS PARA REGLAS =====
    'cliente_id': currentUser.uid,  // ✅ Snake case (para reglas)
    'clienteId': currentUser.uid,   // ✅ Camel case (para código)
    'maestro_id': null,              // ✅ Snake case (para reglas)
    'maestroId': null,               // ✅ Camel case (para código)
    
    // ===== CAMPOS BÁSICOS =====
    'id': ticketId,
    'codigo': 'TEST-${now.millisecondsSinceEpoch}',
    'titulo': 'Test directo desde código',
    'descripcion': 'Ticket de prueba para diagnóstico',
    'estado': 'nuevo',
    'prioridad': 'media',
    'tipoServicio': 'otro',
    
    // ===== TIMESTAMPS =====
    'fechaCreacion': Timestamp.fromDate(now),
    'fechaActualizacion': Timestamp.fromDate(now),
    
    // ===== UBICACIÓN =====
    'ubicacion': {
      'direccion': 'Test dirección',
      'lat': null,
      'lng': null,
    },
    
    // ===== CLIENTE =====
    'cliente': {
      'id': currentUser.uid,
      'nombre': currentUser.displayName ?? 'Usuario Test',
      'email': currentUser.email,
      'telefono': null,
    },
    'clienteNombre': currentUser.displayName ?? 'Usuario Test',
    'clienteTelefono': null,
    'clienteEmail': currentUser.email,
    
    // ===== MAESTRO =====
    'maestroAsignado': {
      'id': null,
      'nombre': null,
    },
    'maestroNombre': null,
    'tecnicoId': null,
    'tecnicoNombre': null,
    'toderoId': null,
    'toderoNombre': null,
    
    // ===== OTROS =====
    'userId': currentUser.uid,
    'propiedadId': null,
    'espacioId': null,
    'espacioNombre': null,
    'presupuestoEstimado': null,
    'costoFinal': null,
    'fotosAntes': [],
    'fotosDurante': [],
    'fotosDespues': [],
    'materialesUsados': [],
    'historial': [
      {
        'fecha': Timestamp.fromDate(now),
        'accion': 'Test Creación',
        'usuario': 'Test Usuario',
        'detalles': 'Ticket de prueba para diagnóstico de permisos',
      }
    ],
    'notasMaestro': null,
    'notasCliente': 'Test de diagnóstico',
    'fechaProgramada': null,
    'fechaInicio': null,
    'fechaCompletado': null,
    'firmaCliente': null,
    'firmaMaestro': null,
    'fechaFirmaCliente': null,
    'fechaFirmaMaestro': null,
    'cotizacionAprobada': false,
    'fechaCotizacionAprobada': null,
  };
  
  print('\n📦 Datos del ticket:');
  print('   cliente_id: ${ticketData['cliente_id']}');
  print('   maestro_id: ${ticketData['maestro_id']}');
  print('   UID usuario: ${currentUser.uid}');
  print('   ¿Coinciden?: ${ticketData['cliente_id'] == currentUser.uid}');
  
  // 3. Intentar crear en Firestore
  try {
    print('\n🔄 Intentando crear ticket en Firestore...');
    print('   Colección: tickets');
    print('   Documento ID: $ticketId');
    print('   Proyecto: sutoderoapp-ee318');
    
    await FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .set(ticketData);
    
    print('\n✅ ¡ÉXITO! Ticket creado correctamente');
    print('   ID del documento: $ticketId');
    print('   Colección: tickets');
    
    // Verificar que se creó
    final doc = await FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .get();
    
    if (doc.exists) {
      print('✅ Verificado: El documento existe en Firestore');
      print('   Data: ${doc.data()}');
    } else {
      print('⚠️ El documento NO existe (pero no dio error)');
    }
    
  } on FirebaseException catch (e) {
    print('\n❌ ERROR de Firebase:');
    print('   Código: ${e.code}');
    print('   Mensaje: ${e.message}');
    print('   Plugin: ${e.plugin}');
    if (e.stackTrace != null) {
      print('   Stack: ${e.stackTrace}');
    }
    
    // Diagnóstico específico
    if (e.code == 'permission-denied') {
      print('\n🔍 DIAGNÓSTICO:');
      print('   El error es de PERMISOS en Firestore');
      print('   Las reglas están rechazando la creación');
      print('   ');
      print('   POSIBLES CAUSAS:');
      print('   1. El campo cliente_id no coincide con el UID');
      print('   2. Las reglas no están publicadas correctamente');
      print('   3. Hay caché de reglas antiguas');
      print('   ');
      print('   VERIFICAR:');
      print('   - cliente_id enviado: ${ticketData['cliente_id']}');
      print('   - UID del usuario: ${currentUser.uid}');
      print('   - ¿Son iguales?: ${ticketData['cliente_id'] == currentUser.uid}');
    }
    
  } catch (e) {
    print('\n❌ ERROR GENERAL:');
    print('   Tipo: ${e.runtimeType}');
    print('   Mensaje: $e');
  }
}
