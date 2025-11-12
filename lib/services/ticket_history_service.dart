import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ticket_event.dart';

class TicketHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _firebaseAvailable = true;

  TicketHistoryService() {
    _checkFirebaseAvailability();
  }

  Future<void> _checkFirebaseAvailability() async {
    try {
      await _firestore.collection('_test').limit(1).get();
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Firebase no disponible para historial: $e');
      }
    }
  }

  /// Agregar evento al historial
  Future<void> addEvent({
    required String ticketId,
    required EventType type,
    required String description,
    required String userId,
    required String userName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_firebaseAvailable) return;

      final event = TicketEvent(
        id: '',
        ticketId: ticketId,
        type: type,
        description: description,
        timestamp: DateTime.now(),
        userId: userId,
        userName: userName,
        metadata: metadata,
      );

      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('history')
          .add(event.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error agregando evento al historial: $e');
      }
    }
  }

  /// Stream de eventos de un ticket
  Stream<List<TicketEvent>> getEventsStream(String ticketId) {
    if (!_firebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TicketEvent.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Obtener eventos de un ticket (una vez)
  Future<List<TicketEvent>> getEvents(String ticketId) async {
    try {
      if (!_firebaseAvailable) return [];

      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TicketEvent.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo eventos: $e');
      }
      return [];
    }
  }

  /// Eventos de creación de ticket
  Future<void> logTicketCreated({
    required String ticketId,
    required String userId,
    required String userName,
    required String titulo,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.created,
      description: 'Ticket "$titulo" creado',
      userId: userId,
      userName: userName,
    );
  }

  /// Evento de cambio de estado
  Future<void> logStatusChanged({
    required String ticketId,
    required String userId,
    required String userName,
    required String oldStatus,
    required String newStatus,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.statusChanged,
      description: 'Estado cambiado de "$oldStatus" a "$newStatus"',
      userId: userId,
      userName: userName,
      metadata: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    );
  }

  /// Evento de asignación de todero
  Future<void> logToderoAssigned({
    required String ticketId,
    required String userId,
    required String userName,
    required String toderoName,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.assigned,
      description: 'Todero asignado: $toderoName',
      userId: userId,
      userName: userName,
      metadata: {
        'toderoName': toderoName,
      },
    );
  }

  /// Evento de foto agregada
  Future<void> logPhotoAdded({
    required String ticketId,
    required String userId,
    required String userName,
    required bool isResult,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.photoAdded,
      description: isResult 
          ? 'Foto de resultado agregada'
          : 'Foto del problema agregada',
      userId: userId,
      userName: userName,
      metadata: {
        'isResult': isResult,
      },
    );
  }

  /// Evento de ticket completado
  Future<void> logTicketCompleted({
    required String ticketId,
    required String userId,
    required String userName,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.completed,
      description: 'Ticket marcado como completado',
      userId: userId,
      userName: userName,
    );
  }

  /// Evento de ticket calificado
  Future<void> logTicketRated({
    required String ticketId,
    required String userId,
    required String userName,
    required int rating,
  }) async {
    await addEvent(
      ticketId: ticketId,
      type: EventType.rated,
      description: 'Ticket calificado con $rating estrellas',
      userId: userId,
      userName: userName,
      metadata: {
        'rating': rating,
      },
    );
  }
}
