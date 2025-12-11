import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../models/ticket_model.dart';
import '../models/inventory_property.dart';
import '../models/property_room.dart';
import 'ticket_service.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TicketService _ticketService = TicketService();
  final Uuid _uuid = const Uuid();

  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  /// GET /inventario/maestro/:id
  /// Obtiene el inventario actual asignado al maestro
  Future<List<MaestroInventoryItem>> getMaestroInventory(String maestroId) async {
    try {
      final snapshot = await _firestore
          .collection('maestro_inventory')
          .doc(maestroId)
          .collection('items')
          .orderBy('nombre')
          .get();

      return snapshot.docs
          .map((doc) => MaestroInventoryItem.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error obteniendo inventario: $e');
      return [];
    }
  }

  /// POST /inventario/solicitud
  /// Crea una solicitud de material
  Future<bool> createMaterialRequest(MaterialRequest request) async {
    try {
      await _firestore.collection('material_requests').doc(request.id).set(request.toMap());
      
      // Simular notificación al equipo de inventario
      _notifyInventoryTeam(request);
      
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error creando solicitud: $e');
      return false;
    }
  }

  /// POST /inventario/reporte-uso
  /// Reporta uso, daño o pérdida de material
  /// Si es uso en ticket, actualiza también el ticket.
  Future<Map<String, dynamic>> reportMaterialUsage({
    required String maestroId,
    required String itemId,
    required double cantidadUsada,
    required InventoryTransactionType tipo,
    String? ticketId,
    String? evidenciaFoto,
    String? comentario,
  }) async {
    try {
      // 1. Obtener item actual para validación
      final itemRef = _firestore
          .collection('maestro_inventory')
          .doc(maestroId)
          .collection('items')
          .doc(itemId);

      final itemDoc = await itemRef.get();
      if (!itemDoc.exists) {
        return {'success': false, 'message': 'Item no encontrado en inventario'};
      }

      final item = MaestroInventoryItem.fromMap(itemDoc.data()!);

      // 2. Validación de Stock
      if (item.cantidadActual < cantidadUsada) {
        return {
          'success': false, 
          'message': 'Stock insuficiente. Tienes ${item.cantidadActual} ${item.unidad}.'
        };
      }

      // 3. Crear Transacción (Historial)
      final transaction = InventoryTransaction(
        id: _uuid.v4(),
        maestroId: maestroId,
        itemId: itemId,
        nombreItem: item.nombre,
        cantidad: -cantidadUsada, // Negativo porque sale
        tipo: tipo,
        ticketId: ticketId,
        evidenciaFoto: evidenciaFoto,
        comentario: comentario,
        fecha: DateTime.now(),
      );

      // 4. Batch Write (Transacción atómica)
      final batch = _firestore.batch();

      // 4a. Registrar en historial global
      final transRef = _firestore.collection('inventory_transactions').doc(transaction.id);
      batch.set(transRef, transaction.toMap());

      // 4b. Actualizar stock del maestro
      batch.update(itemRef, {
        'cantidadActual': FieldValue.increment(-cantidadUsada),
        'ultimaActualizacion': Timestamp.now(),
      });

      // 4c. Si es ticket, actualizar ticket
      if (ticketId != null && tipo == InventoryTransactionType.uso_ticket) {
        // Usamos el TicketService existente o actualizamos directamente
        // Aquí simulamos la llamada interna para agregar material al ticket
        // Nota: Esto es asíncrono fuera del batch de Firestore, o debería ser parte de la lógica
        // Para consistencia estricta, idealmente se hace update aquí, pero usaremos el servicio helper después.
      }

      await batch.commit();

      // Paso extra: Actualizar Ticket (fuera del batch de inventario por separación de servicios)
      if (ticketId != null && tipo == InventoryTransactionType.uso_ticket) {
        final ticketMaterial = TicketMaterial(
          id: transaction.id,
          nombre: item.nombre,
          cantidad: cantidadUsada,
          unidad: item.unidad,
          notas: comentario ?? 'Reportado desde inventario',
        );
        await _ticketService.addMaterial(ticketId, ticketMaterial);
      }
      
      // Notificar si es daño o pérdida
      if (tipo == InventoryTransactionType.danado || tipo == InventoryTransactionType.perdido) {
        _notifyInventoryTeamLoss(transaction);
      }

      return {'success': true, 'message': 'Reporte registrado correctamente'};

    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error reportando uso: $e');
      return {'success': false, 'message': 'Error interno: $e'};
    }
  }

  /// GET /inventario/historial/:id
  Future<List<InventoryTransaction>> getHistory(String maestroId) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_transactions')
          .where('maestroId', isEqualTo: maestroId)
          .orderBy('fecha', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => InventoryTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- Helpers de Notificación (Simulados) ---
  
  void _notifyInventoryTeam(MaterialRequest request) {
    if (kDebugMode) {
      print('🔔 NOTIFICACIÓN A BODEGA: Nueva solicitud de ${request.cantidadSolicitada} ${request.nombreMaterial} por maestro ${request.maestroId}');
    }
    // Aquí iría la lógica de FCM o Email
  }

  void _notifyInventoryTeamLoss(InventoryTransaction trans) {
    if (kDebugMode) {
      print('🔔 ALERTA A BODEGA: Material ${trans.nombreItem} reportado como ${trans.tipo} por maestro ${trans.maestroId}');
    }
  }

  // --- Property Management Methods ---

  Future<List<InventoryProperty>> getAllProperties() async {
    try {
      final snapshot = await _firestore.collection('properties').orderBy('name').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return InventoryProperty.fromMap(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting properties: $e');
      return [];
    }
  }

  Future<List<InventoryProperty>> searchProperties(String query) async {
    try {
      // Basic client-side filtering for search query simulation
      final allProps = await getAllProperties();
      final lowerQuery = query.toLowerCase();
      return allProps.where((p) => 
        (p.clienteNombre ?? '').toLowerCase().contains(lowerQuery) || 
        p.direccion.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  Future<InventoryProperty?> getProperty(String id) async {
    try {
      final doc = await _firestore.collection('properties').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return InventoryProperty.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createProperty(InventoryProperty property) async {
    await _firestore.collection('properties').doc(property.id).set(property.toMap());
  }

  Future<void> updateProperty(InventoryProperty property) async {
    await _firestore.collection('properties').doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String id) async {
    await _firestore.collection('properties').doc(id).delete();
  }

  // --- Room Management Methods ---

  Future<List<PropertyRoom>> getRoomsByProperty(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .orderBy('name')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PropertyRoom.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PropertyRoom?> getRoom(String propertyId, String roomId) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return PropertyRoom.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createRoom(String propertyId, PropertyRoom room) async {
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(room.id)
        .set(room.toMap());
  }

  Future<void> updateRoom(String propertyId, PropertyRoom room) async {
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(room.id)
        .update(room.toMap());
  }

  Future<void> deleteRoom(String propertyId, String roomId) async {
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId)
        .delete();
  }

  Future<void> addRoomPhoto(String propertyId, String roomId, String photoUrl) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId)
          .update({
        'photos': FieldValue.arrayUnion([photoUrl]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding photo: $e');
    }
  }

  Future<void> setRoom360Photo(String propertyId, String roomId, String photo360Url) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId)
          .update({
        'photo360Url': photo360Url,
        'has360View': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting 360 photo: $e');
    }
  }
}
