import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de movimiento de inventario
enum InventoryTransactionType {
  uso_ticket,    // Usado en un trabajo
  solicitud,     // Ingreso por solicitud aprobada
  danado,        // Reportado como dañado
  perdido,       // Reportado como perdido
  ajuste,        // Ajuste manual de inventario
}

/// Estado de una solicitud de material
enum RequestStatus {
  pendiente,
  aprobado,
  rechazado,
  entregado,
}

/// Modelo de Item de Inventario (Lo que el maestro tiene en su "bodega móvil")
class MaestroInventoryItem {
  final String id;
  final String nombre;
  final String unidad; // unidad, metros, litros, etc.
  final double cantidadActual;
  final double cantidadMinima; // Para alertas de stock bajo
  final DateTime ultimaActualizacion;

  MaestroInventoryItem({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.cantidadActual,
    this.cantidadMinima = 0,
    required this.ultimaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'unidad': unidad,
      'cantidadActual': cantidadActual,
      'cantidadMinima': cantidadMinima,
      'ultimaActualizacion': Timestamp.fromDate(ultimaActualizacion),
    };
  }

  factory MaestroInventoryItem.fromMap(Map<String, dynamic> map) {
    return MaestroInventoryItem(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      unidad: map['unidad'] ?? 'unid',
      cantidadActual: (map['cantidadActual'] ?? 0).toDouble(),
      cantidadMinima: (map['cantidadMinima'] ?? 0).toDouble(),
      ultimaActualizacion: (map['ultimaActualizacion'] as Timestamp).toDate(),
    );
  }
}

/// Modelo de Solicitud de Material
class MaterialRequest {
  final String id;
  final String maestroId;
  final String nombreMaterial;
  final double cantidadSolicitada;
  final String unidad;
  final String motivo; // "Stock bajo", "Ticket específico", etc.
  final RequestStatus estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaRespuesta;

  MaterialRequest({
    required this.id,
    required this.maestroId,
    required this.nombreMaterial,
    required this.cantidadSolicitada,
    required this.unidad,
    required this.motivo,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaRespuesta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maestroId': maestroId,
      'nombreMaterial': nombreMaterial,
      'cantidadSolicitada': cantidadSolicitada,
      'unidad': unidad,
      'motivo': motivo,
      'estado': estado.toString().split('.').last,
      'fechaSolicitud': Timestamp.fromDate(fechaSolicitud),
      'fechaRespuesta': fechaRespuesta != null ? Timestamp.fromDate(fechaRespuesta!) : null,
    };
  }

  factory MaterialRequest.fromMap(Map<String, dynamic> map) {
    return MaterialRequest(
      id: map['id'] ?? '',
      maestroId: map['maestroId'] ?? '',
      nombreMaterial: map['nombreMaterial'] ?? '',
      cantidadSolicitada: (map['cantidadSolicitada'] ?? 0).toDouble(),
      unidad: map['unidad'] ?? '',
      motivo: map['motivo'] ?? '',
      estado: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['estado'],
        orElse: () => RequestStatus.pendiente,
      ),
      fechaSolicitud: (map['fechaSolicitud'] as Timestamp).toDate(),
      fechaRespuesta: map['fechaRespuesta'] != null ? (map['fechaRespuesta'] as Timestamp).toDate() : null,
    );
  }
}

/// Modelo de Transacción/Historial
class InventoryTransaction {
  final String id;
  final String maestroId;
  final String itemId;
  final String nombreItem;
  final double cantidad; // Puede ser negativa (uso) o positiva (ingreso)
  final InventoryTransactionType tipo;
  final String? ticketId; // Opcional, si fue usado en un ticket
  final String? evidenciaFoto; // URL de la foto
  final String? comentario;
  final DateTime fecha;

  InventoryTransaction({
    required this.id,
    required this.maestroId,
    required this.itemId,
    required this.nombreItem,
    required this.cantidad,
    required this.tipo,
    this.ticketId,
    this.evidenciaFoto,
    this.comentario,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maestroId': maestroId,
      'itemId': itemId,
      'nombreItem': nombreItem,
      'cantidad': cantidad,
      'tipo': tipo.toString().split('.').last,
      'ticketId': ticketId,
      'evidenciaFoto': evidenciaFoto,
      'comentario': comentario,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'] ?? '',
      maestroId: map['maestroId'] ?? '',
      itemId: map['itemId'] ?? '',
      nombreItem: map['nombreItem'] ?? '',
      cantidad: (map['cantidad'] ?? 0).toDouble(),
      tipo: InventoryTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => InventoryTransactionType.uso_ticket,
      ),
      ticketId: map['ticketId'],
      evidenciaFoto: map['evidenciaFoto'],
      comentario: map['comentario'],
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }
}
