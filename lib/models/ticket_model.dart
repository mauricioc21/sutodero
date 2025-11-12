import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un ticket
enum TicketStatus {
  nuevo,
  pendiente,
  enProgreso,
  completado,
  cancelado,
}

/// Extensión para obtener el nombre en español del estado
extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.nuevo:
        return 'Nuevo';
      case TicketStatus.pendiente:
        return 'Pendiente';
      case TicketStatus.enProgreso:
        return 'En Progreso';
      case TicketStatus.completado:
        return 'Completado';
      case TicketStatus.cancelado:
        return 'Cancelado';
    }
  }

  String get value {
    switch (this) {
      case TicketStatus.nuevo:
        return 'nuevo';
      case TicketStatus.pendiente:
        return 'pendiente';
      case TicketStatus.enProgreso:
        return 'en_progreso';
      case TicketStatus.completado:
        return 'completado';
      case TicketStatus.cancelado:
        return 'cancelado';
    }
  }
}

/// Tipos de servicio
enum ServiceType {
  plomeria,
  electricidad,
  pintura,
  carpinteria,
  albanileria,
  climatizacion,
  limpieza,
  jardineria,
  cerrajeria,
  electrodomesticos,
  otro,
}

/// Extensión para obtener el nombre del tipo de servicio
extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.plomeria:
        return 'Plomería';
      case ServiceType.electricidad:
        return 'Electricidad';
      case ServiceType.pintura:
        return 'Pintura';
      case ServiceType.carpinteria:
        return 'Carpintería';
      case ServiceType.albanileria:
        return 'Albañilería';
      case ServiceType.climatizacion:
        return 'Climatización';
      case ServiceType.limpieza:
        return 'Limpieza';
      case ServiceType.jardineria:
        return 'Jardinería';
      case ServiceType.cerrajeria:
        return 'Cerrajería';
      case ServiceType.electrodomesticos:
        return 'Electrodomésticos';
      case ServiceType.otro:
        return 'Otro';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

/// Niveles de prioridad
enum TicketPriority {
  baja,
  media,
  alta,
  urgente,
}

/// Extensión para obtener el nombre de la prioridad
extension TicketPriorityExtension on TicketPriority {
  String get displayName {
    switch (this) {
      case TicketPriority.baja:
        return 'Baja';
      case TicketPriority.media:
        return 'Media';
      case TicketPriority.alta:
        return 'Alta';
      case TicketPriority.urgente:
        return 'Urgente';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

/// Modelo de Ticket para gestión de órdenes de trabajo
class TicketModel {
  final String id;
  final String titulo;
  final String descripcion;
  final ServiceType tipoServicio;
  final TicketStatus estado;
  final TicketPriority prioridad;
  
  // Información del cliente
  final String clienteId;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? clienteEmail;
  
  // Información del todero (opcional - cuando se asigna)
  final String? toderoId;
  final String? toderoNombre;
  
  // Propiedad y espacio asociados (opcional)
  final String? propiedadId;
  final String? propiedadDireccion;
  final String? espacioId;
  final String? espacioNombre;
  
  // Presupuesto
  final double? presupuestoEstimado;
  final double? costoFinal;
  
  // Fechas
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final DateTime? fechaInicio;
  final DateTime? fechaCompletado;
  final DateTime? fechaProgramada;
  
  // Fotos
  final List<String> fotosProblema;
  final List<String> fotosResultado;
  
  // Notas y observaciones
  final String? notasCliente;
  final String? notasTodero;
  
  // Calificación (después de completar)
  final int? calificacion; // 1-5 estrellas
  final String? comentarioCalificacion;
  
  // Firma digital (al completar trabajo)
  final String? firmaCliente; // Base64 de la firma del cliente
  final String? firmaTodero; // Base64 de la firma del todero
  final DateTime? fechaFirmaCliente;
  final DateTime? fechaFirmaTodero;

  TicketModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipoServicio,
    this.estado = TicketStatus.nuevo,
    this.prioridad = TicketPriority.media,
    required this.clienteId,
    required this.clienteNombre,
    this.clienteTelefono,
    this.clienteEmail,
    this.toderoId,
    this.toderoNombre,
    this.propiedadId,
    this.propiedadDireccion,
    this.espacioId,
    this.espacioNombre,
    this.presupuestoEstimado,
    this.costoFinal,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.fechaInicio,
    this.fechaCompletado,
    this.fechaProgramada,
    this.fotosProblema = const [],
    this.fotosResultado = const [],
    this.notasCliente,
    this.notasTodero,
    this.calificacion,
    this.comentarioCalificacion,
    this.firmaCliente,
    this.firmaTodero,
    this.fechaFirmaCliente,
    this.fechaFirmaTodero,
  });

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'tipoServicio': tipoServicio.value,
      'estado': estado.value,
      'prioridad': prioridad.value,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteTelefono': clienteTelefono,
      'clienteEmail': clienteEmail,
      'toderoId': toderoId,
      'toderoNombre': toderoNombre,
      'propiedadId': propiedadId,
      'propiedadDireccion': propiedadDireccion,
      'espacioId': espacioId,
      'espacioNombre': espacioNombre,
      'presupuestoEstimado': presupuestoEstimado,
      'costoFinal': costoFinal,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaCompletado': fechaCompletado != null ? Timestamp.fromDate(fechaCompletado!) : null,
      'fechaProgramada': fechaProgramada != null ? Timestamp.fromDate(fechaProgramada!) : null,
      'fotosProblema': fotosProblema,
      'fotosResultado': fotosResultado,
      'notasCliente': notasCliente,
      'notasTodero': notasTodero,
      'calificacion': calificacion,
      'comentarioCalificacion': comentarioCalificacion,
      'firmaCliente': firmaCliente,
      'firmaTodero': firmaTodero,
      'fechaFirmaCliente': fechaFirmaCliente != null ? Timestamp.fromDate(fechaFirmaCliente!) : null,
      'fechaFirmaTodero': fechaFirmaTodero != null ? Timestamp.fromDate(fechaFirmaTodero!) : null,
    };
  }

  /// Crear desde Map de Firestore
  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    return TicketModel(
      id: id,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      tipoServicio: ServiceType.values.firstWhere(
        (e) => e.value == map['tipoServicio'],
        orElse: () => ServiceType.otro,
      ),
      estado: TicketStatus.values.firstWhere(
        (e) => e.value == map['estado'],
        orElse: () => TicketStatus.nuevo,
      ),
      prioridad: TicketPriority.values.firstWhere(
        (e) => e.value == map['prioridad'],
        orElse: () => TicketPriority.media,
      ),
      clienteId: map['clienteId'] ?? '',
      clienteNombre: map['clienteNombre'] ?? '',
      clienteTelefono: map['clienteTelefono'],
      clienteEmail: map['clienteEmail'],
      toderoId: map['toderoId'],
      toderoNombre: map['toderoNombre'],
      propiedadId: map['propiedadId'],
      propiedadDireccion: map['propiedadDireccion'],
      espacioId: map['espacioId'],
      espacioNombre: map['espacioNombre'],
      presupuestoEstimado: map['presupuestoEstimado']?.toDouble(),
      costoFinal: map['costoFinal']?.toDouble(),
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
      fechaInicio: map['fechaInicio'] != null ? (map['fechaInicio'] as Timestamp).toDate() : null,
      fechaCompletado: map['fechaCompletado'] != null ? (map['fechaCompletado'] as Timestamp).toDate() : null,
      fechaProgramada: map['fechaProgramada'] != null ? (map['fechaProgramada'] as Timestamp).toDate() : null,
      fotosProblema: List<String>.from(map['fotosProblema'] ?? []),
      fotosResultado: List<String>.from(map['fotosResultado'] ?? []),
      notasCliente: map['notasCliente'],
      notasTodero: map['notasTodero'],
      calificacion: map['calificacion'],
      comentarioCalificacion: map['comentarioCalificacion'],
      firmaCliente: map['firmaCliente'],
      firmaTodero: map['firmaTodero'],
      fechaFirmaCliente: map['fechaFirmaCliente'] != null ? (map['fechaFirmaCliente'] as Timestamp).toDate() : null,
      fechaFirmaTodero: map['fechaFirmaTodero'] != null ? (map['fechaFirmaTodero'] as Timestamp).toDate() : null,
    );
  }

  /// Copiar con modificaciones
  TicketModel copyWith({
    String? titulo,
    String? descripcion,
    ServiceType? tipoServicio,
    TicketStatus? estado,
    TicketPriority? prioridad,
    String? clienteId,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    String? toderoId,
    String? toderoNombre,
    String? propiedadId,
    String? propiedadDireccion,
    String? espacioId,
    String? espacioNombre,
    double? presupuestoEstimado,
    double? costoFinal,
    DateTime? fechaActualizacion,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
    DateTime? fechaProgramada,
    List<String>? fotosProblema,
    List<String>? fotosResultado,
    String? notasCliente,
    String? notasTodero,
    int? calificacion,
    String? comentarioCalificacion,
    String? firmaCliente,
    String? firmaTodero,
    DateTime? fechaFirmaCliente,
    DateTime? fechaFirmaTodero,
  }) {
    return TicketModel(
      id: id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      toderoId: toderoId ?? this.toderoId,
      toderoNombre: toderoNombre ?? this.toderoNombre,
      propiedadId: propiedadId ?? this.propiedadId,
      propiedadDireccion: propiedadDireccion ?? this.propiedadDireccion,
      espacioId: espacioId ?? this.espacioId,
      espacioNombre: espacioNombre ?? this.espacioNombre,
      presupuestoEstimado: presupuestoEstimado ?? this.presupuestoEstimado,
      costoFinal: costoFinal ?? this.costoFinal,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fotosProblema: fotosProblema ?? this.fotosProblema,
      fotosResultado: fotosResultado ?? this.fotosResultado,
      notasCliente: notasCliente ?? this.notasCliente,
      notasTodero: notasTodero ?? this.notasTodero,
      calificacion: calificacion ?? this.calificacion,
      comentarioCalificacion: comentarioCalificacion ?? this.comentarioCalificacion,
      firmaCliente: firmaCliente ?? this.firmaCliente,
      firmaTodero: firmaTodero ?? this.firmaTodero,
      fechaFirmaCliente: fechaFirmaCliente ?? this.fechaFirmaCliente,
      fechaFirmaTodero: fechaFirmaTodero ?? this.fechaFirmaTodero,
    );
  }
}
