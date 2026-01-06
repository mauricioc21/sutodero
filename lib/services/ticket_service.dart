import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import 'api_service.dart';

/// Servicio para gestionar tickets de trabajo
/// 🔥 VERSIÓN BACKEND-ONLY: Usa Cloud Functions para TODA operación de escritura
/// ✅ Lectura: Firestore directo (filtrado por reglas)
/// ✅ Escritura: Backend API (Admin SDK, sin restricciones)
class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  // Singleton
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  // Variable para diagnóstico de errores en UI
  String? lastError;

  // ==================== HELPERS DE ROL ====================

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

  // ==================== CREAR TICKET (BACKEND ONLY) ====================

  /// Crear un nuevo ticket a través del BACKEND
  /// ⚠️ NO escribe directamente a Firestore
  /// ✅ Usa Cloud Functions con Admin SDK
  /// 
  /// Retorna un Map con {success: bool, message: String, data: Map?}
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
      debugPrint('🚀 Creando ticket vía BACKEND...');
      debugPrint('   Título: $titulo');
      debugPrint('   Cliente: $clienteNombre');
      debugPrint('   Cliente ID: $clienteId');

      // Llamar al backend
      final result = await _apiService.createTicket(
        titulo: titulo,
        descripcion: descripcion,
        tipoServicio: tipoServicio.value,
        prioridad: prioridad.value,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        clienteEmail: clienteEmail,
        propiedadId: propiedadId,
        propiedadDireccion: propiedadDireccion,
        lat: lat,
        lng: lng,
        fechaProgramada: fechaProgramada,
        notasCliente: notasCliente,
        fotosAntes: fotosAntes,
        presupuestoEstimado: presupuestoEstimado,
      );

      if (result['success'] == true) {
        debugPrint('✅ Ticket creado exitosamente en backend');
        debugPrint('   Datos: ${result['data']}');
        
        lastError = null;
        return {
          'success': true,
          'message': 'Ticket creado correctamente',
          'data': result['data'],
        };
      } else {
        final errorMsg = result['message'] ?? 'Error desconocido';
        debugPrint('❌ Backend rechazó la creación: $errorMsg');
        
        lastError = errorMsg;
        return {
          'success': false,
          'message': errorMsg,
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('❌ Error creando ticket: $e');
      lastError = 'Error de conexión: $e';
      
      return {
        'success': false,
        'message': 'Error de conexión con el servidor: $e',
        'data': null,
      };
    }
  }

  // ==================== OBTENER TICKETS (FIRESTORE DIRECTO) ====================

  /// Obtener todos los tickets disponibles según permisos del usuario
  /// ✅ Lectura directa de Firestore (las reglas manejan el filtrado)
  /// 
  /// Para admin/coordinador: Todos los tickets
  /// Para maestro: Tickets asignados a él
  /// Para cliente: Tickets creados por él
  Future<List<TicketModel>> getTickets({
    String? userId,
    String? userRole,
  }) async {
    try {
      debugPrint('📖 Obteniendo tickets desde Firestore...');
      debugPrint('   User ID: $userId');
      debugPrint('   Role: $userRole');

      Query<Map<String, dynamic>> query = _firestore.collection('tickets');

      // Filtrar según rol
      if (userId != null && userRole != null) {
        if (_isAdminRole(userRole)) {
          // Admin/coordinador: Sin filtro (ve todos)
          debugPrint('   👑 Admin/Coordinador: Sin filtro');
        } else if (_isMaestroRole(userRole)) {
          // Maestro: Solo tickets asignados a él
          debugPrint('   🔧 Maestro: Filtrando por maestroId');
          query = query.where('maestroId', isEqualTo: userId);
        } else {
          // Cliente: Solo tickets creados por él
          debugPrint('   👤 Cliente: Filtrando por clienteId');
          query = query.where('clienteId', isEqualTo: userId);
        }
      }

      // Ordenar por fecha
      query = query.orderBy('fechaCreacion', descending: true);

      final snapshot = await query.get();
      debugPrint('   📊 Total documentos: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('   📭 No hay tickets');
        return [];
      }

      final tickets = snapshot.docs
          .map((doc) {
            try {
              return TicketModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint('   ⚠️ Error parseando ticket ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();

      debugPrint('   ✅ Tickets parseados: ${tickets.length}');
      lastError = null;
      return tickets;
      
    } catch (e) {
      debugPrint('❌ Error obteniendo tickets: $e');
      lastError = 'Error obteniendo tickets: $e';
      
      // En lugar de fallar, retornar lista vacía
      // Esto evita loaders infinitos
      return [];
    }
  }

  /// Stream de tickets en tiempo real (ALIAS para compatibilidad)
  /// ✅ Lectura directa de Firestore con stream
  Stream<List<TicketModel>> watchTickets({
    String? userId,
    String? userRole,
  }) {
    return getTicketsStream(userId: userId, userRole: userRole);
  }

  /// Stream de tickets en tiempo real
  /// ✅ Lectura directa de Firestore con stream
  Stream<List<TicketModel>> getTicketsStream({
    String? userId,
    String? userRole,
  }) {
    try {
      debugPrint('📡 Iniciando stream de tickets...');
      debugPrint('   User ID: $userId');
      debugPrint('   Role: $userRole');

      Query<Map<String, dynamic>> query = _firestore.collection('tickets');

      // Filtrar según rol
      if (userId != null && userRole != null) {
        if (_isAdminRole(userRole)) {
          // Admin: Sin filtro
          debugPrint('   👑 Admin: Sin filtro');
        } else if (_isMaestroRole(userRole)) {
          // Maestro: Solo sus tickets
          debugPrint('   🔧 Maestro: maestroId = $userId');
          query = query.where('maestroId', isEqualTo: userId);
        } else {
          // Cliente: Solo sus tickets
          debugPrint('   👤 Cliente: clienteId = $userId');
          query = query.where('clienteId', isEqualTo: userId);
        }
      }

      // Ordenar por fecha
      query = query.orderBy('fechaCreacion', descending: true);

      return query.snapshots().map((snapshot) {
        debugPrint('   📊 Stream update: ${snapshot.docs.length} documentos');
        
        if (snapshot.docs.isEmpty) {
          debugPrint('   📭 Stream vacío');
          return <TicketModel>[];
        }

        final tickets = snapshot.docs
            .map((doc) {
              try {
                return TicketModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                debugPrint('   ⚠️ Error parseando ticket ${doc.id}: $e');
                return null;
              }
            })
            .whereType<TicketModel>()
            .toList();

        debugPrint('   ✅ Tickets en stream: ${tickets.length}');
        return tickets;
      });
      
    } catch (e) {
      debugPrint('❌ Error en stream: $e');
      lastError = 'Error en stream: $e';
      
      // Retornar stream vacío en lugar de fallar
      return Stream.value([]);
    }
  }

  /// Obtener un ticket específico por ID
  /// ✅ Lectura directa de Firestore
  Future<TicketModel?> getTicketById(String ticketId) async {
    try {
      debugPrint('📖 Obteniendo ticket: $ticketId');
      
      final doc = await _firestore.collection('tickets').doc(ticketId).get();

      if (!doc.exists) {
        debugPrint('   ❌ Ticket no existe');
        return null;
      }

      final ticket = TicketModel.fromMap(doc.data()!, doc.id);
      debugPrint('   ✅ Ticket encontrado: ${ticket.titulo}');
      
      lastError = null;
      return ticket;
      
    } catch (e) {
      debugPrint('❌ Error obteniendo ticket: $e');
      lastError = 'Error obteniendo ticket: $e';
      return null;
    }
  }

  /// Alias para compatibilidad
  Future<TicketModel?> getTicket(String ticketId) async {
    return getTicketById(ticketId);
  }

  /// Obtener todos los tickets (admin/coordinador)
  /// ✅ Lectura directa de Firestore
  Future<List<TicketModel>> getAllTickets() async {
    return getTickets(userId: null, userRole: 'administrador');
  }

  /// Obtener tickets por usuario
  Future<List<TicketModel>> getTicketsByUser(String userId, String userRole) async {
    return getTickets(userId: userId, userRole: userRole);
  }

  // ==================== ACTUALIZAR TICKET (BACKEND ONLY) ====================

  /// Actualizar ticket a través del BACKEND
  /// ⚠️ NO escribe directamente a Firestore
  /// ✅ Usa Cloud Functions con Admin SDK
  Future<Map<String, dynamic>> updateTicket(
    String ticketId, {
    String? estado,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? maestroId,
    String? maestroNombre,
    List<String>? fotosDurante,
    List<String>? fotosDespues,
    String? notasMaestro,
    double? costoReal,
  }) async {
    try {
      debugPrint('🔄 Actualizando ticket vía BACKEND: $ticketId');

      final result = await _apiService.updateTicket(
        ticketId,
        estado: estado,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
        fotosDurante: fotosDurante,
        fotosDespues: fotosDespues,
        notasMaestro: notasMaestro,
        costoReal: costoReal,
      );

      debugPrint('✅ Ticket actualizado');
      lastError = null;
      return result;
      
    } catch (e) {
      debugPrint('❌ Error actualizando ticket: $e');
      lastError = 'Error actualizando ticket: $e';
      rethrow;
    }
  }

  // ==================== ELIMINAR TICKET (BACKEND ONLY) ====================

  /// Eliminar ticket a través del BACKEND
  /// ⚠️ NO escribe directamente a Firestore
  /// ✅ Usa Cloud Functions con Admin SDK
  Future<void> deleteTicket(String ticketId) async {
    try {
      debugPrint('🗑️ Eliminando ticket vía BACKEND: $ticketId');

      await _apiService.deleteTicket(ticketId);

      debugPrint('✅ Ticket eliminado');
      lastError = null;
      
    } catch (e) {
      debugPrint('❌ Error eliminando ticket: $e');
      lastError = 'Error eliminando ticket: $e';
      rethrow;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener estadísticas de tickets
  /// ✅ Lectura directa de Firestore
  Future<Map<String, int>> getTicketStats({
    String? userId,
    String? userRole,
  }) async {
    try {
      final tickets = await getTickets(userId: userId, userRole: userRole);

      return {
        'total': tickets.length,
        'nuevos': tickets.where((t) => t.estado == TicketStatus.nuevo).length,
        'asignados': tickets.where((t) => t.estado == TicketStatus.asignado).length,
        'en_progreso': tickets.where((t) => t.estado == TicketStatus.en_ejecucion).length,
        'completados': tickets.where((t) => t.estado == TicketStatus.finalizado).length,
        'cancelados': tickets.where((t) => t.estado == TicketStatus.cancelado).length,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'nuevos': 0,
        'asignados': 0,
        'en_progreso': 0,
        'completados': 0,
        'cancelados': 0,
      };
    }
  }

  /// Alias para compatibilidad
  Future<Map<String, int>> getTicketStatistics() async {
    return getTicketStats();
  }

  // ==================== MÉTODOS ADICIONALES PARA COMPATIBILIDAD ====================

  /// Actualizar solo el estado de un ticket
  Future<bool> updateTicketStatus(
    String ticketId,
    TicketStatus newStatus, {
    String? userId,
    String? userName,
    String? detalles,
  }) async {
    try {
      await updateTicket(ticketId, estado: newStatus.value);
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando estado: $e');
      return false;
    }
  }

  /// Asignar maestro a ticket
  Future<bool> assignMaestroToTicket({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      await updateTicket(
        ticketId,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
        estado: 'ASIGNADO',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error asignando maestro: $e');
      return false;
    }
  }

  /// Aprobar cotización y asignar maestro
  Future<bool> approveCotizacionAndAssignMaestro({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      await updateTicket(
        ticketId,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
        estado: 'ASIGNADO',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error aprobando cotización: $e');
      return false;
    }
  }

  /// Guardar firma
  Future<bool> saveSignature({
    required String ticketId,
    String? signatureUrl,
    String? signatureBase64,
    String? signedBy,
    bool? isCliente,
    String? userName,
    String? userId,
  }) async {
    try {
      // Por ahora, solo actualizar el estado a completado
      await updateTicket(ticketId, estado: 'COMPLETADO');
      return true;
    } catch (e) {
      debugPrint('❌ Error guardando firma: $e');
      return false;
    }
  }

  /// Agregar foto
  Future<void> addPhoto(
    String ticketId,
    String photoUrl,
    String stage,
  ) async {
    try {
      final ticket = await getTicketById(ticketId);
      if (ticket == null) return;

      List<String> photos = [];
      if (stage == 'antes') {
        photos = [...ticket.fotosAntes, photoUrl];
        await updateTicket(ticketId, fotosDurante: photos);
      } else if (stage == 'durante') {
        photos = [...ticket.fotosDurante, photoUrl];
        await updateTicket(ticketId, fotosDurante: photos);
      } else if (stage == 'despues') {
        photos = [...ticket.fotosDespues, photoUrl];
        await updateTicket(ticketId, fotosDespues: photos);
      }
    } catch (e) {
      debugPrint('❌ Error agregando foto: $e');
      rethrow;
    }
  }

  /// Agregar material
  Future<void> addMaterial(String ticketId, dynamic material) async {
    try {
      // Por ahora, solo log
      debugPrint('📦 Material agregado: $material');
    } catch (e) {
      debugPrint('❌ Error agregando material: $e');
      rethrow;
    }
  }

  /// Check-in
  Future<void> performCheckIn(String ticketId, dynamic checkIn) async {
    try {
      await updateTicket(
        ticketId,
        estado: 'EN_PROGRESO',
        fechaInicio: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error en check-in: $e');
      rethrow;
    }
  }

  /// Check-out
  Future<void> performCheckOut(String ticketId, dynamic checkOut) async {
    try {
      await updateTicket(
        ticketId,
        fechaFin: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error en check-out: $e');
      rethrow;
    }
  }
}
