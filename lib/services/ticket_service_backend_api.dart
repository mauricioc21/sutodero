import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import 'api_service.dart';

/// ✅ TICKET SERVICE - VERSION BACKEND API
/// 
/// Este servicio usa el backend API de Cloud Functions
/// para todas las operaciones de tickets.

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  final ApiService _apiService = ApiService();
  String? lastError;

  /// ==================== CREAR TICKET ====================
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
    try {
      debugPrint('🔄 [TicketService-API] Creando ticket...');
      debugPrint('   Backend: ${ApiService.baseUrl}');
      debugPrint('   Usuario: $userId');
      debugPrint('   Título: $titulo');

      final result = await _apiService.createTicket(
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

      if (result['success'] == true) {
        debugPrint('✅ [SUCCESS] Ticket creado en backend');
        debugPrint('   ID: ${result['data']['id']}');
        debugPrint('   Código: ${result['data']['codigo']}');
        
        lastError = null;
        return {
          'success': true,
          'message': result['message'] ?? 'Ticket creado exitosamente',
          'data': result['data'],
        };
      } else {
        debugPrint('❌ [ERROR] ${result['message']}');
        lastError = result['message'];
        return result;
      }
    } catch (e, stackTrace) {
      final errorMsg = '❌ [ERROR] Error creando ticket: $e';
      debugPrint(errorMsg);
      debugPrint('Stack trace: $stackTrace');
      
      lastError = errorMsg;
      return {
        'success': false,
        'message': 'Error al crear ticket: $e',
        'data': null,
      };
    }
  }

  /// ==================== OBTENER TICKETS ====================
  Future<List<TicketModel>> getTickets() async {
    try {
      debugPrint('📥 [TicketService-API] Obteniendo tickets...');
      debugPrint('   Backend: ${ApiService.baseUrl}/tickets');

      final result = await _apiService.getTickets();

      if (result['success'] == true) {
        final ticketsData = result['data'] as List;
        final tickets = ticketsData
            .map((json) {
              try {
                return TicketModel.fromMap(
                  Map<String, dynamic>.from(json),
                  json['id'] ?? '',
                );
              } catch (e) {
                debugPrint('⚠️ Error parseando ticket: $e');
                return null;
              }
            })
            .whereType<TicketModel>()
            .toList();

        debugPrint('✅ ${tickets.length} tickets obtenidos del backend');
        lastError = null;
        return tickets;
      } else {
        debugPrint('❌ Error: ${result['message']}');
        lastError = result['message'];
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getTickets: $e');
      lastError = e.toString();
      return [];
    }
  }

  /// ==================== STREAM DE TICKETS (POLLING) ====================
  Stream<List<TicketModel>> watchTickets({
    required String userId,
    required String userRole,
  }) async* {
    debugPrint('👁️ [TicketService-API] Iniciando polling de tickets');
    debugPrint('   Usuario: $userId');
    debugPrint('   Rol: $userRole');

    while (true) {
      try {
        final tickets = await getTickets();
        yield tickets;
        
        // Polling cada 5 segundos
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('❌ Error en watchTickets: $e');
        lastError = e.toString();
        yield [];
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  /// ==================== OBTENER TICKET POR ID ====================
  Future<TicketModel?> getTicket(String ticketId) async {
    try {
      debugPrint('📥 [TicketService-API] Obteniendo ticket: $ticketId');

      final result = await _apiService.getTicket(ticketId);

      if (result['success'] == true) {
        final ticketData = result['data'];
        final ticket = TicketModel.fromMap(
          Map<String, dynamic>.from(ticketData),
          ticketData['id'] ?? ticketId,
        );
        
        debugPrint('✅ Ticket obtenido');
        return ticket;
      } else {
        debugPrint('❌ Error: ${result['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getTicket: $e');
      return null;
    }
  }

  /// ==================== MÉTODOS AUXILIARES ====================
  
  Future<List<TicketModel>> getAllTickets() async {
    return await getTickets();
  }

  Future<List<TicketModel>> getTicketsByUser(
    String userId, {
    bool isCliente = true,
  }) async {
    final allTickets = await getTickets();
    
    if (isCliente) {
      return allTickets.where((t) => t.userId == userId || t.clienteId == userId).toList();
    } else {
      return allTickets.where((t) => t.maestroId == userId || t.toderoId == userId).toList();
    }
  }

  Future<Map<String, int>> getTicketStatistics() async {
    final tickets = await getAllTickets();

    final stats = <String, int>{
      'nuevo': 0,
      'pendiente': 0,
      'en_progreso': 0,
      'completado': 0,
      'cancelado': 0,
    };

    for (var ticket in tickets) {
      switch (ticket.estado) {
        case TicketStatus.nuevo:
          stats['nuevo'] = (stats['nuevo'] ?? 0) + 1;
          break;
        case TicketStatus.pendiente:
          stats['pendiente'] = (stats['pendiente'] ?? 0) + 1;
          break;
        case TicketStatus.en_ejecucion:
        case TicketStatus.en_camino:
        case TicketStatus.en_lugar:
        case TicketStatus.asignado:
        case TicketStatus.pendiente_repuestos:
          stats['en_progreso'] = (stats['en_progreso'] ?? 0) + 1;
          break;
        case TicketStatus.finalizado:
          stats['completado'] = (stats['completado'] ?? 0) + 1;
          break;
        case TicketStatus.cancelado:
          stats['cancelado'] = (stats['cancelado'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  /// ==================== MÉTODOS STUB (Para compatibilidad) ====================
  /// Estos métodos necesitan ser implementados en el backend
  
  Future<bool> updateTicketStatus(
    String ticketId,
    TicketStatus newStatus, {
    String? userId,
    String? userName,
    String? detalles,
  }) async {
    try {
      debugPrint('⚠️ updateTicketStatus: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
      return false;
    } catch (e) {
      debugPrint('❌ Error updateTicketStatus: $e');
      return false;
    }
  }

  Future<bool> assignMaestroToTicket({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      debugPrint('⚠️ assignMaestroToTicket: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
      return false;
    } catch (e) {
      debugPrint('❌ Error assignMaestroToTicket: $e');
      return false;
    }
  }

  Future<bool> approveCotizacionAndAssignMaestro({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      debugPrint('⚠️ approveCotizacionAndAssignMaestro: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
      return false;
    } catch (e) {
      debugPrint('❌ Error approveCotizacionAndAssignMaestro: $e');
      return false;
    }
  }

  Future<bool> saveSignature({
    required String ticketId,
    required String signatureBase64,
    required bool isCliente,
    String? userId,
    String? userName,
  }) async {
    try {
      debugPrint('⚠️ saveSignature: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
      return false;
    } catch (e) {
      debugPrint('❌ Error saveSignature: $e');
      return false;
    }
  }

  Future<void> addPhoto(String ticketId, String photoUrl, String tipo) async {
    try {
      debugPrint('⚠️ addPhoto: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
    } catch (e) {
      debugPrint('❌ Error addPhoto: $e');
      rethrow;
    }
  }

  Future<void> addMaterial(String ticketId, TicketMaterial material) async {
    try {
      debugPrint('⚠️ addMaterial: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
    } catch (e) {
      debugPrint('❌ Error addMaterial: $e');
      rethrow;
    }
  }

  Future<void> performCheckIn(String ticketId, CheckIn checkIn) async {
    try {
      debugPrint('⚠️ performCheckIn: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
    } catch (e) {
      debugPrint('❌ Error performCheckIn: $e');
      rethrow;
    }
  }

  Future<void> performCheckOut(String ticketId, CheckOut checkOut) async {
    try {
      debugPrint('⚠️ performCheckOut: Método pendiente de implementar en backend');
      // TODO: Implementar en backend
    } catch (e) {
      debugPrint('❌ Error performCheckOut: $e');
      rethrow;
    }
  }
}
