import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  created,          // Ticket creado
  statusChanged,    // Cambio de estado
  assigned,         // Todero asignado
  photoAdded,       // Foto agregada
  budgetUpdated,    // Presupuesto actualizado
  commented,        // Comentario agregado
  completed,        // Ticket completado
  rated,            // Ticket calificado
  cancelled,        // Ticket cancelado
}

class TicketEvent {
  final String id;
  final String ticketId;
  final EventType type;
  final String description;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final Map<String, dynamic>? metadata;

  TicketEvent({
    required this.id,
    required this.ticketId,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.metadata,
  });

  // Crear desde Map (Firestore)
  factory TicketEvent.fromMap(Map<String, dynamic> map, String id) {
    return TicketEvent(
      id: id,
      ticketId: map['ticketId'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.toString() == 'EventType.${map['type']}',
        orElse: () => EventType.commented,
      ),
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Sistema',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'type': type.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'userName': userName,
      'metadata': metadata,
    };
  }

  // Obtener icono según el tipo de evento
  String get icon {
    switch (type) {
      case EventType.created:
        return '🆕';
      case EventType.statusChanged:
        return '🔄';
      case EventType.assigned:
        return '👤';
      case EventType.photoAdded:
        return '📸';
      case EventType.budgetUpdated:
        return '💰';
      case EventType.commented:
        return '💬';
      case EventType.completed:
        return '✅';
      case EventType.rated:
        return '⭐';
      case EventType.cancelled:
        return '❌';
    }
  }
}

// Extensión para obtener nombres legibles
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.created:
        return 'Creado';
      case EventType.statusChanged:
        return 'Estado actualizado';
      case EventType.assigned:
        return 'Asignado';
      case EventType.photoAdded:
        return 'Foto agregada';
      case EventType.budgetUpdated:
        return 'Presupuesto actualizado';
      case EventType.commented:
        return 'Comentario';
      case EventType.completed:
        return 'Completado';
      case EventType.rated:
        return 'Calificado';
      case EventType.cancelled:
        return 'Cancelado';
    }
  }
}
