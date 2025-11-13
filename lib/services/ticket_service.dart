import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/ticket_event.dart';
import 'ticket_history_service.dart';

/// Servicio para gestionar tickets de trabajo
class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final TicketHistoryService _historyService = TicketHistoryService();
  
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  bool _firebaseAvailable = true;

  /// Crear un nuevo ticket
  Future<TicketModel> createTicket({
    required String userId,
    required String titulo,
    required String descripcion,
    required ServiceType tipoServicio,
    required String clienteId,
    required String clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    TicketPriority prioridad = TicketPriority.media,
    String? propiedadId,
    String? propiedadDireccion,
    String? espacioId,
    String? espacioNombre,
    double? presupuestoEstimado,
    DateTime? fechaProgramada,
    String? notasCliente,
    List<String> fotosProblema = const [],
  }) async {
    final now = DateTime.now();
    final ticket = TicketModel(
      id: _uuid.v4(),
      userId: userId,
      titulo: titulo,
      descripcion: descripcion,
      tipoServicio: tipoServicio,
      estado: TicketStatus.nuevo,
      prioridad: prioridad,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      propiedadId: propiedadId,
      propiedadDireccion: propiedadDireccion,
      espacioId: espacioId,
      espacioNombre: espacioNombre,
      presupuestoEstimado: presupuestoEstimado,
      fechaCreacion: now,
      fechaActualizacion: now,
      fechaProgramada: fechaProgramada,
      notasCliente: notasCliente,
      fotosProblema: fotosProblema,
    );

    try {
      if (_firebaseAvailable) {
        await _firestore.collection('tickets').doc(ticket.id).set(ticket.toMap());
        
        // Registrar evento de creación del ticket
        await _historyService.logTicketCreated(
          ticketId: ticket.id,
          userId: clienteId,
          userName: clienteNombre,
          titulo: titulo,
        );
      }
      return ticket;
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Error creando ticket en Firebase: $e');
      }
      return ticket;
    }
  }

  /// Obtener todos los tickets
  Future<List<TicketModel>> getAllTickets() async {
    try {
      if (_firebaseAvailable) {
        final querySnapshot = await _firestore
            .collection('tickets')
            .orderBy('fechaCreacion', descending: true)
            .get();
        
        return querySnapshot.docs
            .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
            .toList();
      }
      return [];
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo tickets: $e');
      }
      return [];
    }
  }

  /// Obtener tickets por usuario (cliente o todero)
  Future<List<TicketModel>> getTicketsByUser(String userId, {bool isCliente = true}) async {
    try {
      if (_firebaseAvailable) {
        final field = isCliente ? 'clienteId' : 'toderoId';
        final querySnapshot = await _firestore
            .collection('tickets')
            .where(field, isEqualTo: userId)
            .get();
        
        final tickets = querySnapshot.docs
            .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
            .toList();
        
        // Ordenar en memoria por fecha de creación
        tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        return tickets;
      }
      return [];
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo tickets por usuario: $e');
      }
      return [];
    }
  }

  /// Obtener tickets por estado
  Future<List<TicketModel>> getTicketsByStatus(TicketStatus status) async {
    try {
      if (_firebaseAvailable) {
        final querySnapshot = await _firestore
            .collection('tickets')
            .where('estado', isEqualTo: status.value)
            .get();
        
        final tickets = querySnapshot.docs
            .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
            .toList();
        
        tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        return tickets;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo tickets por estado: $e');
      }
      return [];
    }
  }

  /// Obtener un ticket por ID
  Future<TicketModel?> getTicket(String ticketId) async {
    try {
      if (_firebaseAvailable) {
        final doc = await _firestore.collection('tickets').doc(ticketId).get();
        if (doc.exists) {
          return TicketModel.fromMap(doc.data()!, doc.id);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo ticket: $e');
      }
      return null;
    }
  }

  /// Actualizar ticket
  Future<bool> updateTicket(TicketModel ticket) async {
    try {
      if (_firebaseAvailable) {
        final updatedTicket = ticket.copyWith(
          fechaActualizacion: DateTime.now(),
        );
        
        await _firestore.collection('tickets').doc(ticket.id).update(updatedTicket.toMap());
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error actualizando ticket: $e');
      }
      return false;
    }
  }

  /// Cambiar estado del ticket
  Future<bool> updateTicketStatus(String ticketId, TicketStatus newStatus, {String? userId, String? userName}) async {
    try {
      if (_firebaseAvailable) {
        // Obtener ticket actual para comparar estado
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        final oldStatus = ticket.estado;
        
        final updates = <String, dynamic>{
          'estado': newStatus.value,
          'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
        };
        
        // Agregar fecha de inicio si cambia a en progreso
        if (newStatus == TicketStatus.enProgreso) {
          updates['fechaInicio'] = Timestamp.fromDate(DateTime.now());
        }
        
        // Agregar fecha de completado si cambia a completado
        if (newStatus == TicketStatus.completado) {
          updates['fechaCompletado'] = Timestamp.fromDate(DateTime.now());
        }
        
        await _firestore.collection('tickets').doc(ticketId).update(updates);
        
        // Registrar evento de cambio de estado
        final userName_ = userName ?? ticket.toderoNombre ?? ticket.clienteNombre;
        final userId_ = userId ?? ticket.toderoId ?? ticket.clienteId;
        
        await _historyService.logStatusChanged(
          ticketId: ticketId,
          userId: userId_,
          userName: userName_,
          oldStatus: oldStatus.displayName,
          newStatus: newStatus.displayName,
        );
        
        // Si se completó, registrar evento especial
        if (newStatus == TicketStatus.completado) {
          await _historyService.logTicketCompleted(
            ticketId: ticketId,
            userId: userId_,
            userName: userName_,
          );
        }
        
        // Si se canceló, registrar evento de cancelación
        if (newStatus == TicketStatus.cancelado) {
          await _historyService.addEvent(
            ticketId: ticketId,
            type: EventType.cancelled,
            description: 'Ticket cancelado',
            userId: userId_,
            userName: userName_,
          );
        }
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error actualizando estado del ticket: $e');
      }
      return false;
    }
  }

  /// Asignar todero al ticket
  Future<bool> assignTodero(String ticketId, String toderoId, String toderoNombre, {String? assignedByUserId, String? assignedByUserName}) async {
    try {
      if (_firebaseAvailable) {
        // Obtener ticket para saber quién lo asigna
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        await _firestore.collection('tickets').doc(ticketId).update({
          'toderoId': toderoId,
          'toderoNombre': toderoNombre,
          'estado': TicketStatus.pendiente.value,
          'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
        });
        
        // Registrar evento de asignación
        final assignerName = assignedByUserName ?? ticket.clienteNombre;
        final assignerId = assignedByUserId ?? ticket.clienteId;
        
        await _historyService.logToderoAssigned(
          ticketId: ticketId,
          userId: assignerId,
          userName: assignerName,
          toderoName: toderoNombre,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error asignando todero: $e');
      }
      return false;
    }
  }

  /// Agregar foto al ticket
  Future<bool> addPhoto(String ticketId, String photoPath, {bool isResult = false, String? userId, String? userName}) async {
    try {
      if (_firebaseAvailable) {
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        final field = isResult ? 'fotosResultado' : 'fotosProblema';
        final currentPhotos = isResult ? ticket.fotosResultado : ticket.fotosProblema;
        
        await _firestore.collection('tickets').doc(ticketId).update({
          field: [...currentPhotos, photoPath],
          'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
        });
        
        // Registrar evento de foto agregada
        final userName_ = userName ?? ticket.toderoNombre ?? ticket.clienteNombre;
        final userId_ = userId ?? ticket.toderoId ?? ticket.clienteId;
        
        await _historyService.logPhotoAdded(
          ticketId: ticketId,
          userId: userId_,
          userName: userName_,
          isResult: isResult,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error agregando foto: $e');
      }
      return false;
    }
  }

  /// Calificar ticket (después de completado)
  Future<bool> rateTicket(String ticketId, int calificacion, String? comentario, {String? userId, String? userName}) async {
    try {
      if (_firebaseAvailable) {
        // Obtener ticket para saber quién califica
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        await _firestore.collection('tickets').doc(ticketId).update({
          'calificacion': calificacion,
          'comentarioCalificacion': comentario,
          'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
        });
        
        // Registrar evento de calificación
        final userName_ = userName ?? ticket.clienteNombre;
        final userId_ = userId ?? ticket.clienteId;
        
        await _historyService.logTicketRated(
          ticketId: ticketId,
          userId: userId_,
          userName: userName_,
          rating: calificacion,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error calificando ticket: $e');
      }
      return false;
    }
  }

  /// Actualizar presupuesto del ticket
  Future<bool> updateBudget(String ticketId, double newBudget, {String? userId, String? userName}) async {
    try {
      if (_firebaseAvailable) {
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        final oldBudget = ticket.presupuestoEstimado;
        
        await _firestore.collection('tickets').doc(ticketId).update({
          'presupuestoEstimado': newBudget,
          'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
        });
        
        // Registrar evento de actualización de presupuesto
        final userName_ = userName ?? ticket.toderoNombre ?? ticket.clienteNombre;
        final userId_ = userId ?? ticket.toderoId ?? ticket.clienteId;
        
        await _historyService.addEvent(
          ticketId: ticketId,
          type: EventType.budgetUpdated,
          description: oldBudget != null 
              ? 'Presupuesto actualizado de \$${oldBudget.toStringAsFixed(0)} a \$${newBudget.toStringAsFixed(0)}'
              : 'Presupuesto establecido en \$${newBudget.toStringAsFixed(0)}',
          userId: userId_,
          userName: userName_,
          metadata: {
            'oldBudget': oldBudget,
            'newBudget': newBudget,
          },
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error actualizando presupuesto: $e');
      }
      return false;
    }
  }

  /// Guardar firma digital
  Future<bool> saveSignature({
    required String ticketId,
    required String signatureBase64,
    required bool isCliente,
    String? userId,
    String? userName,
  }) async {
    try {
      if (_firebaseAvailable) {
        final ticket = await getTicket(ticketId);
        if (ticket == null) return false;
        
        final now = DateTime.now();
        final updates = <String, dynamic>{
          isCliente ? 'firmaCliente' : 'firmaTodero': signatureBase64,
          isCliente ? 'fechaFirmaCliente' : 'fechaFirmaTodero': Timestamp.fromDate(now),
          'fechaActualizacion': Timestamp.fromDate(now),
        };
        
        await _firestore.collection('tickets').doc(ticketId).update(updates);
        
        // Registrar evento de firma
        final userName_ = userName ?? (isCliente ? ticket.clienteNombre : ticket.toderoNombre ?? 'Usuario');
        final userId_ = userId ?? (isCliente ? ticket.clienteId : ticket.toderoId ?? 'unknown');
        
        await _historyService.addEvent(
          ticketId: ticketId,
          type: EventType.commented,
          description: isCliente 
              ? 'Firma del cliente agregada'
              : 'Firma del todero agregada',
          userId: userId_,
          userName: userName_,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error guardando firma: $e');
      }
      return false;
    }
  }

  /// Eliminar ticket
  Future<bool> deleteTicket(String ticketId) async {
    try {
      if (_firebaseAvailable) {
        await _firestore.collection('tickets').doc(ticketId).delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error eliminando ticket: $e');
      }
      return false;
    }
  }

  /// Obtener estadísticas de tickets
  Future<Map<String, int>> getTicketStatistics() async {
    try {
      if (_firebaseAvailable) {
        final tickets = await getAllTickets();
        
        final stats = <String, int>{
          'total': tickets.length,
          'nuevo': tickets.where((t) => t.estado == TicketStatus.nuevo).length,
          'pendiente': tickets.where((t) => t.estado == TicketStatus.pendiente).length,
          'enProgreso': tickets.where((t) => t.estado == TicketStatus.enProgreso).length,
          'completado': tickets.where((t) => t.estado == TicketStatus.completado).length,
          'cancelado': tickets.where((t) => t.estado == TicketStatus.cancelado).length,
        };
        
        return stats;
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo estadísticas: $e');
      }
      return {};
    }
  }

  /// Stream de tickets en tiempo real
  Stream<List<TicketModel>> ticketsStream() {
    try {
      if (_firebaseAvailable) {
        return _firestore
            .collection('tickets')
            .orderBy('fechaCreacion', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
                .toList());
      }
      return Stream.value([]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en stream de tickets: $e');
      }
      return Stream.value([]);
    }
  }
}
