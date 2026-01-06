import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/simple_ticket_model.dart';

/// Script de debugging para probar consultas de Firestore
class FirestoreQueryDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Probar todas las consultas de tickets
  static Future<void> testAllQueries(String userId) async {
    if (kDebugMode) {
      debugPrint('🧪 ===== TEST DE CONSULTAS FIRESTORE =====');
      debugPrint('Usuario actual: $userId');
      debugPrint('');

      // Test 1: Obtener todos los tickets
      debugPrint('📋 Test 1: Obtener TODOS los tickets');
      try {
        final allTickets = await _firestore.collection('simple_tickets').get();
        debugPrint('   ✅ Total de documentos: ${allTickets.docs.length}');
        
        if (allTickets.docs.isNotEmpty) {
          debugPrint('   Tickets encontrados:');
          for (var doc in allTickets.docs) {
            final data = doc.data();
            debugPrint('      - ID: ${doc.id}');
            debugPrint('        Cliente: ${data['clienteNombre']}');
            debugPrint('        Servicio: ${data['servicio']}');
            debugPrint('        Estado: ${data['estado']}');
            debugPrint('        Creado por: ${data['creadoPor']}');
            debugPrint('');
          }
        }
      } catch (e) {
        debugPrint('   ❌ Error: $e');
      }

      // Test 2: Obtener tickets del usuario específico
      debugPrint('📋 Test 2: Obtener tickets del usuario específico');
      debugPrint('   Buscando tickets con creadoPor == "$userId"');
      try {
        final userTickets = await _firestore
            .collection('simple_tickets')
            .where('creadoPor', isEqualTo: userId)
            .get();
        
        debugPrint('   ✅ Tickets del usuario: ${userTickets.docs.length}');
        
        if (userTickets.docs.isEmpty) {
          debugPrint('   ⚠️  NO SE ENCONTRARON TICKETS PARA ESTE USUARIO');
          debugPrint('   Verificar:');
          debugPrint('      1. El campo "creadoPor" debe ser exactamente: "$userId"');
          debugPrint('      2. No debe haber espacios en blanco');
          debugPrint('      3. El tipo debe ser String');
        } else {
          for (var doc in userTickets.docs) {
            final data = doc.data();
            debugPrint('      - ${data['clienteNombre']} | ${data['servicio']}');
          }
        }
      } catch (e) {
        debugPrint('   ❌ Error: $e');
      }

      // Test 3: Verificar tickets pendientes
      debugPrint('📋 Test 3: Obtener tickets PENDIENTES');
      try {
        final pendingTickets = await _firestore
            .collection('simple_tickets')
            .where('estado', isEqualTo: 'pendiente')
            .get();
        
        debugPrint('   ✅ Tickets pendientes: ${pendingTickets.docs.length}');
        
        for (var doc in pendingTickets.docs) {
          final data = doc.data();
          debugPrint('      - ${data['clienteNombre']} (${data['creadoPor']})');
        }
      } catch (e) {
        debugPrint('   ❌ Error: $e');
      }

      // Test 4: Verificar estructura del ticket
      debugPrint('📋 Test 4: Verificar estructura de datos');
      try {
        final sample = await _firestore.collection('simple_tickets').limit(1).get();
        
        if (sample.docs.isNotEmpty) {
          final data = sample.docs.first.data();
          debugPrint('   Campos disponibles:');
          data.forEach((key, value) {
            debugPrint('      - $key: ${value.runtimeType}');
          });
        }
      } catch (e) {
        debugPrint('   ❌ Error: $e');
      }

      debugPrint('🧪 ===== FIN DEL TEST =====');
    }
  }

  /// Verificar si un usuario tiene tickets
  static Future<bool> userHasTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('simple_tickets')
          .where('creadoPor', isEqualTo: userId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verificando tickets del usuario: $e');
      }
      return false;
    }
  }

  /// Contar tickets por usuario
  static Future<int> countUserTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('simple_tickets')
          .where('creadoPor', isEqualTo: userId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error contando tickets del usuario: $e');
      }
      return 0;
    }
  }
}
