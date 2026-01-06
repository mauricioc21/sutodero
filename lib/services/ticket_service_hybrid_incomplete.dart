import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import 'api_service.dart';

/// Servicio para gestionar tickets de trabajo
/// 
/// ✅ MODO HÍBRIDO (Temporal):
/// - Intenta usar Backend API primero
/// - Si falla, usa Firestore directo como fallback
/// 
/// 🎯 OBJETIVO: Migración gradual a 100% backend API
class TicketService {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  // Variable para diagnóstico de errores en UI
  String? lastError;
  
  // Flag para indicar si estamos usando fallback
  bool _usingFirestoreFallback = false;

  /// Verificar si el backend está disponible
  Future<bool> checkBackendHealth() async {
    try {
      final isHealthy = await _apiService.checkHealth();
      _usingFirestoreFallback = !isHealthy;
      
      if (kDebugMode) {
        debugPrint(_usingFirestoreFallback 
          ? '⚠️ Backend no disponible - usando Firestore directo'
          : '✅ Backend disponible - usando API');
      }
      
      return isHealthy;
    } catch (e) {
      _usingFirestoreFallback = true;
      lastError = 'Backend no disponible: $e';
      
      if (kDebugMode) {
        debugPrint('⚠️ $lastError - usando Firestore directo');
      }
      
      return false;
    }
  }

  /// Crear un nuevo ticket (con fallback a Firestore)
  Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String titulo,
    required String descripcion,
    required ServiceType tipoServicio,
    required String clienteId,
    required String clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    TicketPriority prioridad = TicketPriority.media,
    String? propiedadDireccion,
    double? lat,
    double? lng,
    DateTime? fechaProgramada,
    String? notasCliente,
    List<String> fotosAntes = const [],
    String? maestroId,
    String? maestroNombre,
    String? propiedadId,
    double? presupuestoEstimado,
  }) async {
    lastError = null;

    // Intentar con backend primero
    try {
      if (kDebugMode) {
        debugPrint('🎫 Intentando crear ticket via backend API...');
      }

      final response = await _apiService.createTicket(
        titulo: titulo,
        descripcion: descripcion,
        tipoServicio: tipoServicio.value,
        prioridad: prioridad.value,
        propiedadId: propiedadId,
        clienteId: clienteId,
        lat: lat,
        lng: lng,
        fechaProgramada: fechaProgramada,
        fotosAntes: fotosAntes,
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('✅ Ticket creado via backend: ${response['data']['ticketId']}');
      }

      final ticketData = response['data']['ticket'];
      final ticket = TicketModel.fromMap(ticketData, ticketData['id']);

      return {
        'success': true,
        'message': response['message'] ?? 'Ticket creado correctamente',
        'data': ticket,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backend falló: $e - usando Firestore directo');
      }

      // FALLBACK: Crear directamente en Firestore
      return await _createTicketFirestore(
        userId: userId,
        titulo: titulo,
        descripcion: descripcion,
        tipoServicio: tipoServicio,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        clienteEmail: clienteEmail,
        prioridad: prioridad,
        propiedadDireccion: propiedadDireccion,
        lat: lat,
        lng: lng,
        fechaProgramada: fechaProgramada,
        notasCliente: notasCliente,
        fotosAntes: fotosAntes,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
        propiedadId: propiedadId,
        presupuestoEstimado: presupuestoEstimado,
      );
    }
  }

  /// Crear ticket directamente en Firestore (FALLBACK)
  Future<Map<String, dynamic>> _createTicketFirestore({
    required String userId,
    required String titulo,
    required String descripcion,
    required ServiceType tipoServicio,
    required String clienteId,
    required String clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    TicketPriority prioridad = TicketPriority.media,
    String? propiedadDireccion,
    double? lat,
    double? lng,
    DateTime? fechaProgramada,
    String? notasCliente,
    List<String> fotosAntes = const [],
    String? maestroId,
    String? maestroNombre,
    String? propiedadId,
    double? presupuestoEstimado,
  }) async {
    try {
      final now = DateTime.now();
      final ticketRef = _firestore.collection('tickets').doc();
      final codigo = 'TKT-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final estadoInicial = (maestroId != null && maestroId.isNotEmpty)
          ? TicketStatus.asignado
          : TicketStatus.nuevo;

      final ticket = TicketModel(
        id: ticketRef.id,
        codigo: codigo,
        userId: userId,
        titulo: titulo,
        descripcion: descripcion,
        tipoServicio: tipoServicio,
        estado: estadoInicial,
        prioridad: prioridad,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        clienteEmail: clienteEmail,
        ubicacionDireccion: propiedadDireccion ?? '',
        ubicacionLat: lat,
        ubicacionLng: lng,
        propiedadId: propiedadId,
        presupuestoEstimado: presupuestoEstimado,
        fechaCreacion: now,
        fechaActualizacion: now,
        fechaProgramada: fechaProgramada,
        fotosAntes: fotosAntes,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
        notasCliente: notasCliente,
        historial: [
          TicketHistoryItem(
            fecha: now,
            accion: 'Creación',
            usuario: clienteNombre,
            detalles: 'Ticket creado exitosamente. Estado: ${estadoInicial.displayName}',
          ),
        ],
      );

      await ticketRef.set(ticket.toMap(), SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ Ticket creado en Firestore (fallback): ${ticket.id}');
      }

      return {
        'success': true,
        'message': 'Ticket creado correctamente (Firestore)',
        'data': ticket,
      };
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) {
        debugPrint('❌ Error creando ticket en Firestore: $e');
      }

      return {
        'success': false,
        'message': 'Error al crear ticket: $e',
        'data': null,
      };
    }
  }

  /// Obtener todos los tickets (con fallback a Firestore)
  Future<List<TicketModel>> getAllTickets({
    String? userId,
    String? userRole,
    String? estado,
  }) async {
    lastError = null;

    // Intentar con backend primero
    try {
      if (kDebugMode) {
        debugPrint('📋 Obteniendo tickets via backend API...');
      }

      final tickets = await _apiService.getTickets(
        estado: estado,
        limit: 100,
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('✅ Tickets obtenidos via backend: ${tickets.length}');
      }

      return tickets
          .map((ticketData) {
            try {
              return TicketModel.fromMap(
                ticketData as Map<String, dynamic>,
                ticketData['id'] ?? '',
              );
            } catch (e) {
              debugPrint('⚠️ Error parseando ticket: $e');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Backend falló: $e - usando Firestore directo');
      }

      // FALLBACK: Leer directamente de Firestore
      return await _getTicketsFirestore(userId: userId, userRole: userRole, estado: estado);
    }
  }

  /// Obtener tickets directamente de Firestore (FALLBACK)
  Future<List<TicketModel>> _getTicketsFirestore({
    String? userId,
    String? userRole,
    String? estado,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('tickets');

      // Filtrar por estado si se proporciona
      if (estado != null && estado != 'todos') {
        query = query.where('estado', isEqualTo: estado);
      }

      // Filtrar por rol
      if (_isAdminRole(userRole)) {
        // Admin ve todos
      } else if (_isMaestroRole(userRole) && userId != null) {
        query = query.where('maestroId', isEqualTo: userId);
      } else if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('fechaCreacion', descending: true).get();

      final tickets = snapshot.docs
          .map((doc) {
            try {
              return TicketModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint('⚠️ Error parseando ticket ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();

      if (kDebugMode) {
        debugPrint('✅ Tickets obtenidos de Firestore (fallback): ${tickets.length}');
      }

      return tickets;
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error obteniendo tickets de Firestore: $e');
      return [];
    }
  }

  /// Stream de tickets (usa Firestore directo por ahora)
  Stream<List<TicketModel>> watchTickets({
    required String userId,
    required String userRole,
    String? estado,
  }) {
    return _watchTicketsFirestore(userId: userId, userRole: userRole, estado: estado);
  }

  /// Watch tickets desde Firestore (más eficiente que polling)
  Stream<List<TicketModel>> _watchTicketsFirestore({
    required String userId,
    required String userRole,
    String? estado,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('tickets');

    // Filtrar por estado
    if (estado != null && estado != 'todos') {
      query = query.where('estado', isEqualTo: estado);
    }

    // Filtrar por rol
    if (_isAdminRole(userRole)) {
      // Admin ve todos
    } else if (_isMaestroRole(userRole)) {
      query = query.where('maestroId', isEqualTo: userId);
    } else {
      query = query.where('userId', isEqualTo: userId);
    }

    return query
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) {
            try {
              return TicketModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint('⚠️ Error parseando ticket ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();

      if (kDebugMode) {
        debugPrint('📊 Stream actualizado: ${tickets.length} tickets');
      }

      return tickets;
    }).handleError((error) {
      debugPrint('❌ Error en stream de tickets: $error');
      lastError = error.toString();
      return <TicketModel>[];
    });
  }

  // Helpers
  bool _isAdminRole(String? role) {
    final value = role?.toLowerCase().trim();
    return value == 'admin' ||
        value == 'administrador' ||
        value == 'coordinador' ||
        value == 'super_admin';
  }

  bool _isMaestroRole(String? role) {
    final value = role?.toLowerCase().trim();
    return value == 'maestro' || value == 'tecnico';
  }
}
