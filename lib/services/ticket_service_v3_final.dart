import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import 'package:flutter/foundation.dart';

/// ✅ TICKET SERVICE V3 - FIRESTORE DIRECTO CON ARQUITECTURA API-READY
/// 
/// Este servicio usa Firestore directamente PERO con la misma estructura
/// que el backend API, para facilitar la migración futura.
/// 
/// VENTAJAS:
/// - ✅ Funciona AHORA sin depender del backend
/// - ✅ Interfaz compatible con API REST
/// - ✅ Fácil migración cuando el backend funcione
/// - ✅ Logs detallados para debugging

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

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
      debugPrint('🔄 [TicketService] Creando ticket...');
      debugPrint('   Usuario: $userId');
      debugPrint('   Título: $titulo');
      debugPrint('   Cliente: $clienteNombre');

      final now = DateTime.now();
      final ticketId = _uuid.v4();
      final codigo = 'TKT-${now.millisecondsSinceEpoch.toString().substring(8)}';

      // Determinar estado inicial
      final estadoInicial = (maestroId != null && maestroId.isNotEmpty)
          ? TicketStatus.asignado
          : TicketStatus.nuevo;

      // Crear modelo de ticket
      final ticket = TicketModel(
        id: ticketId,
        codigo: codigo,
        userId: userId,
        titulo: titulo,
        descripcion: descripcion,
        tipoServicio: tipoServicio,
        estado: estadoInicial,
        prioridad: prioridad,
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono ?? '',
        clienteEmail: clienteEmail ?? '',
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
            detalles: 'Ticket creado - Estado: ${estadoInicial.displayName}',
          ),
        ],
      );

      // Guardar en Firestore
      final ticketData = ticket.toMap();
      
      debugPrint('📝 [Firestore] Guardando documento en colección "tickets"');
      debugPrint('   ID: $ticketId');
      debugPrint('   Código: $codigo');

      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .set(ticketData, SetOptions(merge: true));

      debugPrint('✅ [SUCCESS] Ticket creado exitosamente');
      debugPrint('   ID: $ticketId');
      debugPrint('   Código: $codigo');
      debugPrint('   Estado: ${estadoInicial.displayName}');
      debugPrint('   Colección: tickets');
      debugPrint('   Proyecto: sutoderoapp-ee318');

      lastError = null;

      return {
        'success': true,
        'message': 'Ticket creado exitosamente - $codigo',
        'data': ticket,
      };
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

  /// ==================== OBTENER TICKETS (STREAM EN TIEMPO REAL) ====================
  Stream<List<TicketModel>> watchTickets({
    required String userId,
    required String userRole,
  }) async* {
    try {
      debugPrint('👁️ [TicketService] Iniciando stream de tickets');
      debugPrint('   Usuario ID: $userId');
      debugPrint('   Rol: $userRole');

      final ticketsCollection = _firestore.collection('tickets');
      Query<Map<String, dynamic>> query;

      // Determinar query según el rol
      if (_isAdminRole(userRole)) {
        debugPrint('   🔍 Modo: COORDINADOR/ADMIN - Consultando TODOS los tickets');
        query = ticketsCollection.orderBy('fechaCreacion', descending: true);
      } else if (_isMaestroRole(userRole)) {
        debugPrint('   🔍 Modo: MAESTRO - Consultando tickets asignados');
        query = ticketsCollection.where('toderoId', isEqualTo: userId);
      } else {
        debugPrint('   🔍 Modo: USUARIO - Consultando tickets propios');
        query = ticketsCollection.where('userId', isEqualTo: userId);
      }

      // Stream de Firestore
      yield* query.snapshots().map((snapshot) {
        debugPrint('📊 [Snapshot] Recibido de Firestore');
        debugPrint('   Total documentos: ${snapshot.docs.length}');
        debugPrint('   From cache: ${snapshot.metadata.isFromCache}');
        debugPrint('   Pending writes: ${snapshot.metadata.hasPendingWrites}');

        if (snapshot.docs.isEmpty) {
          debugPrint('   ⚠️ NO HAY TICKETS en la colección');
          lastError = 'No hay tickets disponibles';
          return <TicketModel>[];
        }

        // Parsear tickets
        final tickets = <TicketModel>[];
        for (var doc in snapshot.docs) {
          try {
            final ticket = TicketModel.fromMap(
              doc.data(),
              doc.id,
            );
            tickets.add(ticket);
            
            if (tickets.length <= 3) {
              debugPrint('   ✓ Ticket ${tickets.length}: ${ticket.titulo} (${ticket.codigo})');
            }
          } catch (e) {
            debugPrint('   ⚠️ Error parseando documento ${doc.id}: $e');
          }
        }

        debugPrint('✅ [Success] ${tickets.length} tickets parseados correctamente');
        lastError = null;
        
        return tickets;
      }).handleError((error, stackTrace) {
        final errorMsg = '❌ [ERROR] watchTickets: $error';
        debugPrint(errorMsg);
        debugPrint('Stack trace: $stackTrace');
        lastError = errorMsg;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [ERROR] Error iniciando watchTickets: $e');
      debugPrint('Stack trace: $stackTrace');
      lastError = e.toString();
      yield <TicketModel>[];
    }
  }

  /// ==================== OBTENER TODOS LOS TICKETS (ONE-TIME) ====================
  Future<List<TicketModel>> getAllTickets() async {
    try {
      debugPrint('📥 [TicketService] Obteniendo todos los tickets');

      final snapshot = await _firestore
          .collection('tickets')
          .orderBy('fechaCreacion', descending: true)
          .get();

      debugPrint('   Total documentos: ${snapshot.docs.length}');

      final tickets = snapshot.docs
          .map((doc) {
            try {
              return TicketModel.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint('   ⚠️ Error parseando ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketModel>()
          .toList();

      debugPrint('✅ ${tickets.length} tickets obtenidos');
      return tickets;
    } catch (e) {
      debugPrint('❌ Error getAllTickets: $e');
      return [];
    }
  }

  /// ==================== OBTENER TICKET POR ID ====================
  Future<TicketModel?> getTicket(String ticketId) async {
    try {
      debugPrint('📥 [TicketService] Obteniendo ticket: $ticketId');

      final doc = await _firestore.collection('tickets').doc(ticketId).get();

      if (!doc.exists) {
        debugPrint('   ⚠️ Ticket no encontrado');
        return null;
      }

      final ticket = TicketModel.fromMap(doc.data()!, doc.id);
      debugPrint('✅ Ticket obtenido: ${ticket.titulo}');
      
      return ticket;
    } catch (e) {
      debugPrint('❌ Error getTicket: $e');
      return null;
    }
  }

  /// ==================== ESTADÍSTICAS ====================
  Future<Map<String, int>> getTicketStatistics() async {
    try {
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
    } catch (e) {
      debugPrint('❌ Error getTicketStatistics: $e');
      return {};
    }
  }

  /// ==================== HELPERS ====================
  bool _isAdminRole(String role) {
    return ['admin', 'administrador', 'coordinador', 'super_admin']
        .contains(role.toLowerCase());
  }

  bool _isMaestroRole(String role) {
    return ['maestro', 'tecnico'].contains(role.toLowerCase());
  }
}
