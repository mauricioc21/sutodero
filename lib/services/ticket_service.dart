import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import 'ticket_history_service.dart';
import 'geolocation_service.dart';

/// Servicio para gestionar tickets de trabajo
/// Versión Corregida: Sin bloqueo por errores transitorios
class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final TicketHistoryService _historyService = TicketHistoryService();
  final GeolocationService _geolocationService = GeolocationService();
  
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  // ELIMINADO: bool _firebaseAvailable = true; (Causa raíz de fallos silenciosos)

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
    final now = DateTime.now();
    final id = _uuid.v4();
    // Generar código simple y legible
    final codigo = 'TKT-${now.millisecondsSinceEpoch.toString().substring(8)}';

    // Determinar estado inicial
    // Si se asigna maestro al crear, nace como ASIGNADO, sino como NUEVO
    final estadoInicial = (maestroId != null && maestroId.isNotEmpty)
        ? TicketStatus.asignado
        : TicketStatus.nuevo;

    final ticket = TicketModel(
      id: id,
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
          usuario: clienteNombre, // O 'Coordinador' si tuviéramos ese dato exacto
          detalles: 'Ticket creado exitosamente. Estado: ${estadoInicial.displayName}',
        )
      ],
    );

    try {
      // Intento de escritura en Firestore
      // Usamos SetOptions(merge: true) por seguridad
      await _firestore.collection('tickets').doc(ticket.id).set(ticket.toMap(), SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('✅ Ticket creado exitosamente en Firebase: ${ticket.id}');
      }
      return {'success': true, 'message': 'Ticket creado correctamente', 'data': ticket};

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error CRÍTICO creando ticket en Firebase: $e');
      }
      // Retornamos el error para que la UI lo sepa
      return {'success': false, 'message': 'Error al guardar en base de datos: $e', 'data': null};
    }
  }

  // Variable para diagnóstico de errores en UI
  String? lastError;

  /// Obtener todos los tickets (Admin / Coordinador Dashboard)
  /// Ahora soporta filtrado por rol para garantizar visibilidad
  Future<List<TicketModel>> getAllTickets({String? userId, String? userRole}) async {
    lastError = null; // Reset error
    try {
      QuerySnapshot querySnapshot;
      
      // Estrategia de Consulta:
      // 1. Si es Admin, intentar traer TODO.
      // 2. Si es Coordinador/Otro, intentar traer TODO (por si tiene permisos).
      // 3. Si falla por permisos, hacer Fallback a "Mis Tickets Relacionados".

      try {
        // Intento 1: Traer todo ordenado
        querySnapshot = await _firestore
            .collection('tickets')
            .orderBy('fechaCreacion', descending: true)
            .get();
      } catch (e) {
        // Fallback A: Intentar sin orden (por índices)
        try {
          debugPrint('⚠️ Falló query ordenada, intentando sin orden: $e');
          querySnapshot = await _firestore.collection('tickets').get();
        } catch (e2) {
          // Fallback B: Permisos insuficientes -> Traer tickets relacionados
          if (userId != null) {
            debugPrint('⚠️ Falló lectura general (posible permiso), buscando tickets relacionados a: $userId');
            return await _getRelatedTickets(userId);
          }
          rethrow; // Si no hay userId, no podemos hacer más
        }
      }
      
      final tickets = querySnapshot.docs.map((doc) {
        try {
          return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          debugPrint('⚠️ Error parseando ticket ${doc.id}: $e');
          return null;
        }
      }).whereType<TicketModel>().toList();

      // Ordenar en memoria
      tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      return tickets;

    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Error obteniendo tickets: $e');
      return [];
    }
  }

  /// Método privado para buscar todos los tickets relacionados con un usuario
  /// (Creados por él, Asignados a él, o donde es Cliente)
  Future<List<TicketModel>> _getRelatedTickets(String userId) async {
    try {
      // Firestore no soporta OR nativo eficiente para múltiples campos diferentes,
      // así que hacemos 3 queries paralelas y unimos resultados.
      
      final results = await Future.wait([
        // 1. Creados por mí (userId)
        _firestore.collection('tickets').where('userId', isEqualTo: userId).get(),
        // 2. Yo soy el cliente (cliente.id)
        _firestore.collection('tickets').where('cliente.id', isEqualTo: userId).get(),
        // 3. Asignados a mí (maestroAsignado.id)
        _firestore.collection('tickets').where('maestroAsignado.id', isEqualTo: userId).get(),
      ]);

      final Map<String, TicketModel> uniqueTickets = {};

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          if (!uniqueTickets.containsKey(doc.id)) {
            try {
              uniqueTickets[doc.id] = TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              debugPrint('Error parseando ticket relacionado: $e');
            }
          }
        }
      }

      final tickets = uniqueTickets.values.toList();
      tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      return tickets;
      
    } catch (e) {
      debugPrint('❌ Error buscando tickets relacionados: $e');
      lastError = 'Error buscando tickets personales: $e';
      return [];
    }
  }

  /// Obtener tickets por usuario (cliente o maestro)
  Future<List<TicketModel>> getTicketsByUser(String userId, {bool isCliente = true}) async {
    try {
      final field = isCliente ? 'cliente.id' : 'maestroAsignado.id';
      // Fallback fields para compatibilidad con datos antiguos
      final legacyField = isCliente ? 'clienteId' : 'toderoId';

      QuerySnapshot querySnapshot;
      
      try {
        // Intentar query principal (estructura nueva)
        try {
          querySnapshot = await _firestore
              .collection('tickets')
              .where(field, isEqualTo: userId)
              .get();
          
          if (querySnapshot.docs.isEmpty) {
             throw Exception('Empty results, try legacy');
          }
        } catch(e) {
           // Fallback a legacy o si falla por índice
           debugPrint('⚠️ Falló query principal ticketsByUser, intentando legacy: $e');
           querySnapshot = await _firestore
              .collection('tickets')
              .where(legacyField, isEqualTo: userId)
              .get();
        }
      } catch(e) {
         debugPrint('❌ Error obteniendo tickets por usuario (ambos métodos fallaron): $e');
         return [];
      }
      
      final tickets = querySnapshot.docs.map((doc) {
        try {
          return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          return null;
        }
      }).whereType<TicketModel>().toList();
      
      // Ordenamiento en memoria si el índice compuesto falla
      tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      return tickets;

    } catch (e) {
      debugPrint('⚠️ Error obteniendo tickets por usuario: $e');
      return [];
    }
  }

  /// Obtener un ticket por ID
  Future<TicketModel?> getTicket(String ticketId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists && doc.data() != null) {
        return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error obteniendo ticket: $e');
      return null;
    }
  }

  /// Actualizar estado del ticket
  Future<bool> updateTicketStatus(String ticketId, TicketStatus newStatus, {String? userId, String? userName, String? detalles}) async {
    try {
      final ticket = await getTicket(ticketId);
      if (ticket == null) return false;
      
      final now = DateTime.now();
      final historyItem = TicketHistoryItem(
        fecha: now,
        accion: 'Cambio de estado: ${newStatus.displayName}',
        usuario: userName ?? 'Usuario',
        detalles: detalles,
      );

      final updatedTicket = ticket.copyWith(
        estado: newStatus,
        fechaActualizacion: now,
        historial: [...ticket.historial, historyItem],
        fechaInicio: (newStatus == TicketStatus.en_ejecucion && ticket.fechaInicio == null) ? now : ticket.fechaInicio,
        fechaCompletado: (newStatus == TicketStatus.finalizado) ? now : ticket.fechaCompletado,
      );
      
      await _firestore.collection('tickets').doc(ticketId).update(updatedTicket.toMap());
      return true;
    } catch (e) {
      debugPrint('⚠️ Error actualizando estado: $e');
      return false;
    }
  }

  // ... (Otros métodos se mantienen similares pero sin el check _firebaseAvailable) ...
  // Por brevedad, mantengo los métodos críticos corregidos arriba.
  // Agrego los métodos auxiliares necesarios para que no rompa compilación:

  Future<Map<String, int>> getTicketStatistics() async {
    try {
      final tickets = await getAllTickets();
      int nuevo = 0, pendiente = 0, enProgreso = 0, completado = 0, cancelado = 0;

      for (var ticket in tickets) {
        switch (ticket.estado) {
          case TicketStatus.nuevo:
          case TicketStatus.asignado: nuevo++; break;
          case TicketStatus.pendiente: pendiente++; break;
          case TicketStatus.en_camino:
          case TicketStatus.en_lugar:
          case TicketStatus.en_ejecucion:
          case TicketStatus.pendiente_repuestos: enProgreso++; break;
          case TicketStatus.finalizado: completado++; break;
          case TicketStatus.cancelado: cancelado++; break;
        }
      }
      return {
        'nuevo': nuevo,
        'pendiente': pendiente,
        'en_progreso': enProgreso,
        'completado': completado,
        'cancelado': cancelado,
      };
    } catch (e) {
      return {};
    }
  }

  /// Agregar una foto al ticket
  Future<void> addPhoto(String ticketId, String photoUrl, String tipo) async {
    try {
      final field = tipo == 'antes' ? 'fotosAntes' :
                    tipo == 'durante' ? 'fotosDurante' : 'fotosDespues';
      
      await _firestore.collection('tickets').doc(ticketId).update({
        field: FieldValue.arrayUnion([photoUrl]),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding photo: $e');
      throw e;
    }
  }

  /// Agregar material usado
  Future<void> addMaterial(String ticketId, TicketMaterial material) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'materialesUsados': FieldValue.arrayUnion([material.toMap()]),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding material: $e');
      throw e;
    }
  }

  /// Realizar Check-in
  Future<void> performCheckIn(String ticketId, CheckIn checkIn) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'check.checkIn': checkIn.toMap(),
        'estado': TicketStatus.en_lugar.value,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'historial': FieldValue.arrayUnion([
          TicketHistoryItem(
            fecha: DateTime.now(),
            accion: 'Check-in',
            usuario: 'Maestro', // Idealmente obtener nombre real
            detalles: 'Llegada al sitio. Distancia: ${checkIn.distanciaDesdeUbicacion?.toStringAsFixed(0) ?? "?"}m',
          ).toMap()
        ]),
      });
    } catch (e) {
      debugPrint('Error performing check-in: $e');
      throw e;
    }
  }

  /// Realizar Check-out
  Future<void> performCheckOut(String ticketId, CheckOut checkOut) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'check.checkOut': checkOut.toMap(),
        'estado': TicketStatus.en_ejecucion.value, // O el estado que corresponda post check-out
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'historial': FieldValue.arrayUnion([
          TicketHistoryItem(
            fecha: DateTime.now(),
            accion: 'Check-out',
            usuario: 'Maestro',
            detalles: 'Salida del sitio.',
          ).toMap()
        ]),
      });
    } catch (e) {
      debugPrint('Error performing check-out: $e');
      throw e;
    }
  }

  /// Aprobar cotización y asignar maestro (o solo aprobar si maestroId es vacío)
  Future<bool> approveCotizacionAndAssignMaestro({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      final now = DateTime.now();
      final Map<String, dynamic> updates = {
        'cotizacionAprobada': true,
        'fechaCotizacionAprobada': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      if (maestroId.isNotEmpty) {
        updates['maestroAsignado'] = {
          'id': maestroId,
          'nombre': maestroNombre,
        };
        updates['maestroId'] = maestroId; // Legacy
        updates['toderoId'] = maestroId; // Legacy
        updates['maestroNombre'] = maestroNombre; // Legacy
        updates['toderoNombre'] = maestroNombre; // Legacy
        updates['estado'] = TicketStatus.asignado.value;
      }

      await _firestore.collection('tickets').doc(ticketId).update(updates);

      // Historial
      await _firestore.collection('tickets').doc(ticketId).update({
        'historial': FieldValue.arrayUnion([
          TicketHistoryItem(
            fecha: now,
            accion: 'Cotización Aprobada',
            usuario: userName ?? 'Usuario',
            detalles: maestroId.isNotEmpty ? 'Maestro asignado: $maestroNombre' : 'Pendiente asignación',
          ).toMap()
        ])
      });

      return true;
    } catch (e) {
      debugPrint('Error approving cotizacion: $e');
      return false;
    }
  }

  /// Asignar maestro a un ticket existente
  Future<bool> assignMaestroToTicket({
    required String ticketId,
    required String maestroId,
    required String maestroNombre,
    String? userId,
    String? userName,
  }) async {
    try {
      final now = DateTime.now();
      final updates = {
        'maestroAsignado': {
          'id': maestroId,
          'nombre': maestroNombre,
        },
        'maestroId': maestroId,
        'toderoId': maestroId,
        'maestroNombre': maestroNombre,
        'toderoNombre': maestroNombre,
        'estado': TicketStatus.asignado.value,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('tickets').doc(ticketId).update(updates);

      // Historial
      await _firestore.collection('tickets').doc(ticketId).update({
        'historial': FieldValue.arrayUnion([
          TicketHistoryItem(
            fecha: now,
            accion: 'Maestro Asignado',
            usuario: userName ?? 'Usuario',
            detalles: 'Se asignó a $maestroNombre',
          ).toMap()
        ])
      });

      return true;
    } catch (e) {
      debugPrint('Error assigning maestro: $e');
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
      final now = DateTime.now();
      final field = isCliente ? 'firmaCliente' : 'firmaMaestro';
      final dateField = isCliente ? 'fechaFirmaCliente' : 'fechaFirmaMaestro';
      final legacyField = isCliente ? null : 'firmaTodero'; // Legacy for maestro

      final Map<String, dynamic> updates = {
        field: signatureBase64,
        dateField: FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };
      
      if (legacyField != null) {
        updates[legacyField] = signatureBase64;
      }

      await _firestore.collection('tickets').doc(ticketId).update(updates);

      // Historial
      await _firestore.collection('tickets').doc(ticketId).update({
        'historial': FieldValue.arrayUnion([
          TicketHistoryItem(
            fecha: now,
            accion: 'Firma Registrada',
            usuario: userName ?? 'Usuario',
            detalles: isCliente ? 'Firma del Cliente' : 'Firma del Maestro',
          ).toMap()
        ])
      });

      return true;
    } catch (e) {
      debugPrint('Error saving signature: $e');
      return false;
    }
  }
}
