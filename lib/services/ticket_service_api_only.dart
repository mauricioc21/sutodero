import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import 'api_service.dart';

/// Servicio para gestionar tickets de trabajo usando Backend API
/// 
/// ✅ ARQUITECTURA CORRECTA:
/// Flutter → ApiService → Backend API (Cloud Functions) → Firestore
/// 
/// ❌ NO más acceso directo a Firestore desde Flutter para tickets
class TicketService {
  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  // Variable para diagnóstico de errores en UI
  String? lastError;

  /// Verificar si el backend está disponible
  Future<bool> checkBackendHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      lastError = 'Backend no disponible: $e';
      debugPrint('❌ $lastError');
      return false;
    }
  }

  /// Crear un nuevo ticket
  /// Retorna un Map con {success: bool, message: String, data: TicketModel?}
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

    try {
      if (kDebugMode) {
        debugPrint('🎫 Creando ticket: $titulo');
      }

      // Llamar al backend API
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
      );

      if (kDebugMode) {
        debugPrint('✅ Ticket creado exitosamente: ${response['data']['ticketId']}');
      }

      // Parsear respuesta del backend
      final ticketData = response['data']['ticket'];
      final ticket = TicketModel.fromMap(ticketData, ticketData['id']);

      return {
        'success': true,
        'message': response['message'] ?? 'Ticket creado correctamente',
        'data': ticket,
      };
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) {
        debugPrint('❌ Error creando ticket: $e');
      }

      return {
        'success': false,
        'message': 'Error al crear ticket: $e',
        'data': null,
      };
    }
  }

  /// Obtener todos los tickets disponibles según permisos del usuario
  /// El backend filtra automáticamente por rol:
  /// - admin: Ve todos los tickets
  /// - coordinador: Ve tickets que creó
  /// - maestro: Ve tickets asignados a él
  Future<List<TicketModel>> getAllTickets({
    String? userId,
    String? userRole,
    String? estado,
  }) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('📋 Obteniendo tickets (rol: $userRole, estado: $estado)');
      }

      // El backend filtra automáticamente según el rol del usuario autenticado
      final tickets = await _apiService.getTickets(
        estado: estado,
        limit: 100,
      );

      if (kDebugMode) {
        debugPrint('✅ Tickets obtenidos: ${tickets.length}');
      }

      // Convertir a TicketModel
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
      lastError = e.toString();
      debugPrint('❌ Error obteniendo tickets: $e');
      return [];
    }
  }

  /// Obtener un ticket específico por ID
  Future<TicketModel?> getTicketById(String ticketId) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('🔍 Obteniendo ticket: $ticketId');
      }

      final ticketData = await _apiService.getTicket(ticketId);

      if (kDebugMode) {
        debugPrint('✅ Ticket obtenido: $ticketId');
      }

      return TicketModel.fromMap(
        ticketData as Map<String, dynamic>,
        ticketId,
      );
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error obteniendo ticket $ticketId: $e');
      return null;
    }
  }

  /// Actualizar un ticket
  Future<Map<String, dynamic>> updateTicket(
    String ticketId, {
    String? estado,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<String>? fotosDurante,
    List<String>? fotosDespues,
    String? notasMaestro,
    double? costoReal,
  }) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('📝 Actualizando ticket: $ticketId');
      }

      final response = await _apiService.updateTicket(
        ticketId,
        estado: estado,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        fotosDurante: fotosDurante,
        fotosDespues: fotosDespues,
        notasMaestro: notasMaestro,
        costoReal: costoReal,
      );

      if (kDebugMode) {
        debugPrint('✅ Ticket actualizado: $ticketId');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Ticket actualizado correctamente',
        'data': response['data'],
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error actualizando ticket $ticketId: $e');

      return {
        'success': false,
        'message': 'Error al actualizar ticket: $e',
        'data': null,
      };
    }
  }

  /// Asignar un ticket a un maestro
  /// Solo coordinadores y admins pueden asignar tickets
  Future<Map<String, dynamic>> assignTicket(
    String ticketId,
    String maestroId,
  ) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('👤 Asignando ticket $ticketId a maestro $maestroId');
      }

      final response = await _apiService.assignTicket(ticketId, maestroId);

      if (kDebugMode) {
        debugPrint('✅ Ticket asignado correctamente');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Ticket asignado correctamente',
        'data': response['data'],
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error asignando ticket: $e');

      return {
        'success': false,
        'message': 'Error al asignar ticket: $e',
        'data': null,
      };
    }
  }

  /// Agregar un comentario a un ticket
  Future<Map<String, dynamic>> addComment(
    String ticketId,
    String texto,
  ) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('💬 Agregando comentario al ticket $ticketId');
      }

      final response = await _apiService.addComment(ticketId, texto);

      if (kDebugMode) {
        debugPrint('✅ Comentario agregado correctamente');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Comentario agregado correctamente',
        'data': response['data'],
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error agregando comentario: $e');

      return {
        'success': false,
        'message': 'Error al agregar comentario: $e',
        'data': null,
      };
    }
  }

  /// Agregar fotos a un ticket
  /// tipo: 'antes', 'durante', 'despues'
  Future<Map<String, dynamic>> addPhotos(
    String ticketId,
    List<String> fotos,
    String tipo,
  ) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('📸 Agregando ${fotos.length} fotos ($tipo) al ticket $ticketId');
      }

      final response = await _apiService.addPhotos(ticketId, fotos, tipo);

      if (kDebugMode) {
        debugPrint('✅ Fotos agregadas correctamente');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Fotos agregadas correctamente',
        'data': response['data'],
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error agregando fotos: $e');

      return {
        'success': false,
        'message': 'Error al agregar fotos: $e',
        'data': null,
      };
    }
  }

  /// Eliminar un ticket (solo admin/coordinador)
  Future<Map<String, dynamic>> deleteTicket(String ticketId) async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('🗑️ Eliminando ticket: $ticketId');
      }

      final response = await _apiService.deleteTicket(ticketId);

      if (kDebugMode) {
        debugPrint('✅ Ticket eliminado correctamente');
      }

      return {
        'success': true,
        'message': response['message'] ?? 'Ticket eliminado correctamente',
        'data': null,
      };
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error eliminando ticket: $e');

      return {
        'success': false,
        'message': 'Error al eliminar ticket: $e',
        'data': null,
      };
    }
  }

  /// Obtener lista de maestros disponibles
  Future<List<Map<String, dynamic>>> getMaestros() async {
    lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('👷 Obteniendo lista de maestros');
      }

      final maestros = await _apiService.getMaestros();

      if (kDebugMode) {
        debugPrint('✅ Maestros obtenidos: ${maestros.length}');
      }

      return maestros.cast<Map<String, dynamic>>();
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error obteniendo maestros: $e');
      return [];
    }
  }

  // ==================== MÉTODOS DE COMPATIBILIDAD ====================
  // Mantener compatibilidad con código existente que espera streams

  /// Stream de tickets (simulado con polling)
  /// NOTA: Esto es temporal - idealmente el backend debería tener WebSockets
  Stream<List<TicketModel>> watchTickets({
    required String userId,
    required String userRole,
    String? estado,
  }) async* {
    while (true) {
      final tickets = await getAllTickets(
        userId: userId,
        userRole: userRole,
        estado: estado,
      );
      yield tickets;

      // Poll cada 10 segundos
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  /// Obtener ticket por código (código alfanumérico del ticket)
  Future<TicketModel?> getTicketByCode(String codigo) async {
    try {
      // Buscar en todos los tickets (filtrado en backend)
      final tickets = await getAllTickets();
      return tickets.firstWhere(
        (t) => t.codigo == codigo,
        orElse: () => throw Exception('Ticket no encontrado'),
      );
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error buscando ticket por código: $e');
      return null;
    }
  }

  // ==================== HELPERS ====================

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
