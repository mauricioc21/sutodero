import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un ticket (Flujo Maestro)
enum TicketStatus {
  asignado, // Antes: pendiente/nuevo
  en_camino,
  en_lugar,
  en_ejecucion, // Antes: enProgreso
  pendiente_repuestos,
  finalizado, // Antes: completado
  cancelado,
  nuevo, // Legacy/Admin
  pendiente, // Legacy/Admin
}

/// Extensión para obtener el nombre en español del estado
extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.asignado:
        return 'Asignado';
      case TicketStatus.en_camino:
        return 'En Camino';
      case TicketStatus.en_lugar:
        return 'En el Lugar';
      case TicketStatus.en_ejecucion:
        return 'En Ejecución';
      case TicketStatus.pendiente_repuestos:
        return 'Pendiente Repuestos';
      case TicketStatus.finalizado:
        return 'Finalizado';
      case TicketStatus.cancelado:
        return 'Cancelado';
      case TicketStatus.nuevo:
        return 'Nuevo';
      case TicketStatus.pendiente:
        return 'Pendiente';
    }
  }

  String get value {
    // Retorna el valor exacto para la BD
    return toString().split('.').last;
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

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.plomeria: return 'Plomería';
      case ServiceType.electricidad: return 'Electricidad';
      case ServiceType.pintura: return 'Pintura';
      case ServiceType.carpinteria: return 'Carpintería';
      case ServiceType.albanileria: return 'Albañilería';
      case ServiceType.climatizacion: return 'Climatización';
      case ServiceType.limpieza: return 'Limpieza';
      case ServiceType.jardineria: return 'Jardinería';
      case ServiceType.cerrajeria: return 'Cerrajería';
      case ServiceType.electrodomesticos: return 'Electrodomésticos';
      case ServiceType.otro: return 'Otro';
    }
  }

  String get value => toString().split('.').last;
}

/// Niveles de prioridad
enum TicketPriority {
  baja,
  media,
  alta,
  urgente,
}

extension TicketPriorityExtension on TicketPriority {
  String get displayName {
    switch (this) {
      case TicketPriority.baja: return 'Baja';
      case TicketPriority.media: return 'Media';
      case TicketPriority.alta: return 'Alta';
      case TicketPriority.urgente: return 'Urgente';
    }
  }

  String get value => toString().split('.').last;
}

/// Modelo para Material Usado
class TicketMaterial {
  final String id;
  final String nombre;
  final double cantidad;
  final String unidad;
  final String? notas;
  final double? costoUnitario;

  TicketMaterial({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    this.notas,
    this.costoUnitario,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'cantidad': cantidad,
      'unidad': unidad,
      'notas': notas,
      'costoUnitario': costoUnitario,
    };
  }

  factory TicketMaterial.fromMap(Map<String, dynamic> map) {
    return TicketMaterial(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      cantidad: (map['cantidad'] ?? 0).toDouble(),
      unidad: map['unidad'] ?? '',
      notas: map['notas'],
      costoUnitario: map['costoUnitario']?.toDouble(),
    );
  }
}

/// Modelo para Item del Historial
class TicketHistoryItem {
  final DateTime fecha;
  final String accion;
  final String usuario;
  final String? detalles;
  final String? coordenadas;

  TicketHistoryItem({
    required this.fecha,
    required this.accion,
    required this.usuario,
    this.detalles,
    this.coordenadas,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'accion': accion,
      'usuario': usuario,
      'detalles': detalles,
      'coordenadas': coordenadas,
    };
  }

  factory TicketHistoryItem.fromMap(Map<String, dynamic> map) {
    return TicketHistoryItem(
      fecha: (map['fecha'] as Timestamp).toDate(),
      accion: map['accion'] ?? '',
      usuario: map['usuario'] ?? '',
      detalles: map['detalles'],
      coordenadas: map['coordenadas'],
    );
  }
}

/// Modelo para Check-in
class CheckIn {
  final DateTime hora;
  final double lat;
  final double lng;
  final String? foto; // Base64 or URL
  final String? comentario;
  final double? distanciaDesdeUbicacion; // Distancia calculada

  CheckIn({
    required this.hora,
    required this.lat,
    required this.lng,
    this.foto,
    this.comentario,
    this.distanciaDesdeUbicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'hora': Timestamp.fromDate(hora),
      'lat': lat,
      'lng': lng,
      'foto': foto,
      'comentario': comentario,
      'distanciaDesdeUbicacion': distanciaDesdeUbicacion,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      hora: (map['hora'] as Timestamp).toDate(),
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      foto: map['foto'],
      comentario: map['comentario'],
      distanciaDesdeUbicacion: map['distanciaDesdeUbicacion']?.toDouble(),
    );
  }
}

/// Modelo para Check-out
class CheckOut {
  final DateTime hora;
  final double lat;
  final double lng;
  final String? foto; // Base64 or URL
  final String? comentario;

  CheckOut({
    required this.hora,
    required this.lat,
    required this.lng,
    this.foto,
    this.comentario,
  });

  Map<String, dynamic> toMap() {
    return {
      'hora': Timestamp.fromDate(hora),
      'lat': lat,
      'lng': lng,
      'foto': foto,
      'comentario': comentario,
    };
  }

  factory CheckOut.fromMap(Map<String, dynamic> map) {
    return CheckOut(
      hora: (map['hora'] as Timestamp).toDate(),
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      foto: map['foto'],
      comentario: map['comentario'],
    );
  }
}

/// Modelo contenedor de Check-in y Check-out
class TicketCheck {
  final CheckIn? checkIn;
  final CheckOut? checkOut;

  TicketCheck({
    this.checkIn,
    this.checkOut,
  });

  Map<String, dynamic> toMap() {
    return {
      'checkIn': checkIn?.toMap(),
      'checkOut': checkOut?.toMap(),
    };
  }

  factory TicketCheck.fromMap(Map<String, dynamic> map) {
    return TicketCheck(
      checkIn: map['checkIn'] != null ? CheckIn.fromMap(map['checkIn']) : null,
      checkOut: map['checkOut'] != null ? CheckOut.fromMap(map['checkOut']) : null,
    );
  }
}

/// Modelo de Ticket actualizado con estructura específica
class TicketModel {
  final String id; // ticketId
  final String codigo; // Nuevo campo
  final String titulo;
  final String descripcion;
  final TicketStatus estado;
  final TicketPriority prioridad;
  final DateTime fechaCreacion;
  final DateTime? fechaProgramada;
  
  // Ubicación anidada
  final String ubicacionDireccion;
  final double? ubicacionLat;
  final double? ubicacionLng;
  
  // Propiedad y espacio asociados (Compatibilidad)
  final String? propiedadId;
  final String? espacioId;
  final String? espacioNombre;

  // Listas de fotos
  final List<String> fotosAntes;
  final List<String> fotosDurante; // Nuevo campo
  final List<String> fotosDespues;

  // Materiales
  final List<TicketMaterial> materialesUsados; // Nuevo campo

  // Historial embebido
  final List<TicketHistoryItem> historial; // Nuevo campo

  // Check-in / Check-out
  final TicketCheck? check;

  // Cliente
  final String clienteId;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? clienteEmail;

  // Maestro
  final String? maestroId; // Antes toderoId
  final String? maestroNombre;
  final String? notasMaestro; // Antes notasTodero
  final String? notasCliente; // Nuevo campo

  // Campos heredados/compatibilidad
  final String userId; // Owner ID
  final ServiceType tipoServicio;
  final double? presupuestoEstimado;
  final double? costoFinal;
  final DateTime fechaActualizacion;
  final DateTime? fechaInicio;
  final DateTime? fechaCompletado;
  
  // Firma
  final String? firmaCliente;
  final String? firmaMaestro; // Antes firmaTodero
  final DateTime? fechaFirmaCliente;
  final DateTime? fechaFirmaMaestro;
  
  // Cotización (Restored)
  final bool cotizacionAprobada;
  final DateTime? fechaCotizacionAprobada;

  TicketModel({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.prioridad,
    required this.fechaCreacion,
    this.fechaProgramada,
    required this.ubicacionDireccion,
    this.ubicacionLat,
    this.ubicacionLng,
    this.propiedadId,
    this.espacioId,
    this.espacioNombre,
    this.fotosAntes = const [],
    this.fotosDurante = const [],
    this.fotosDespues = const [],
    this.materialesUsados = const [],
    this.historial = const [],
    this.check,
    required this.clienteId,
    required this.clienteNombre,
    this.clienteTelefono,
    this.clienteEmail,
    this.maestroId,
    this.maestroNombre,
    this.notasMaestro,
    this.notasCliente,
    required this.userId,
    required this.tipoServicio,
    this.presupuestoEstimado,
    this.costoFinal,
    required this.fechaActualizacion,
    this.fechaInicio,
    this.fechaCompletado,
    this.firmaCliente,
    this.firmaMaestro,
    this.fechaFirmaCliente,
    this.fechaFirmaMaestro,
    this.cotizacionAprobada = false,
    this.fechaCotizacionAprobada,
  });

  /// Convertir a Map respetando estructura solicitada
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado.value,
      'prioridad': prioridad.value,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaProgramada': fechaProgramada != null ? Timestamp.fromDate(fechaProgramada!) : null,
      
      // Estructura anidada ubicacion
      'ubicacion': {
        'direccion': ubicacionDireccion,
        'lat': ubicacionLat,
        'lng': ubicacionLng,
      },
      'propiedadId': propiedadId,
      'espacioId': espacioId,
      'espacioNombre': espacioNombre,

      'fotosAntes': fotosAntes,
      'fotosDurante': fotosDurante,
      'fotosDespues': fotosDespues,

      'materialesUsados': materialesUsados.map((m) => m.toMap()).toList(),
      
      'historial': historial.map((h) => h.toMap()).toList(),

      'check': check?.toMap(),

      'cliente': {
        'id': clienteId,
        'nombre': clienteNombre,
        'telefono': clienteTelefono,
        'email': clienteEmail,
      },

      'maestroAsignado': {
        'id': maestroId,
        'nombre': maestroNombre,
      },
      
      'notasMaestro': notasMaestro,
      'notasCliente': notasCliente,

      // Otros campos necesarios para la app pero quizás no en el JSON estricto del prompt
      // Se mantienen en el nivel raíz para compatibilidad con Firestore
      'userId': userId,
      'tipoServicio': tipoServicio.value,
      'presupuestoEstimado': presupuestoEstimado,
      'costoFinal': costoFinal,
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaCompletado': fechaCompletado != null ? Timestamp.fromDate(fechaCompletado!) : null,
      'firmaCliente': firmaCliente,
      'firmaMaestro': firmaMaestro,
      'fechaFirmaCliente': fechaFirmaCliente != null ? Timestamp.fromDate(fechaFirmaCliente!) : null,
      'fechaFirmaMaestro': fechaFirmaMaestro != null ? Timestamp.fromDate(fechaFirmaMaestro!) : null,
      'cotizacionAprobada': cotizacionAprobada,
      'fechaCotizacionAprobada': fechaCotizacionAprobada != null ? Timestamp.fromDate(fechaCotizacionAprobada!) : null,
    };
  }

  // Helper estático para manejar fechas de cualquier tipo (Timestamp, String, null)
  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    return fallback ?? DateTime.now();
  }

  // Helper para manejar doubles (int, double, String, null)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    // Manejo seguro de mapas anidados
    final ubicacion = map['ubicacion'] is Map ? map['ubicacion'] as Map<String, dynamic> : <String, dynamic>{};
    final cliente = map['cliente'] is Map ? map['cliente'] as Map<String, dynamic> : <String, dynamic>{};
    final maestro = map['maestroAsignado'] is Map ? map['maestroAsignado'] as Map<String, dynamic> : <String, dynamic>{};
    final checkMap = map['check'] is Map ? map['check'] as Map<String, dynamic> : null;

    return TicketModel(
      id: id,
      codigo: map['codigo']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? 'Sin Título',
      descripcion: map['descripcion']?.toString() ?? '',
      
      // Enum parsing seguro
      estado: TicketStatus.values.firstWhere(
        (e) => e.value == map['estado']?.toString(),
        orElse: () => TicketStatus.nuevo,
      ),
      prioridad: TicketPriority.values.firstWhere(
        (e) => e.value == map['prioridad']?.toString(),
        orElse: () => TicketPriority.media,
      ),
      
      // Fechas BLINDADAS
      fechaCreacion: _parseDate(map['fechaCreacion']),
      fechaProgramada: map['fechaProgramada'] != null ? _parseDate(map['fechaProgramada']) : null,
      
      // Ubicación segura
      ubicacionDireccion: ubicacion['direccion']?.toString() ?? map['propiedadDireccion']?.toString() ?? '',
      ubicacionLat: _parseDouble(ubicacion['lat']),
      ubicacionLng: _parseDouble(ubicacion['lng']),
      
      propiedadId: map['propiedadId']?.toString(),
      espacioId: map['espacioId']?.toString(),
      espacioNombre: map['espacioNombre']?.toString(),

      // Listas seguras
      fotosAntes: (map['fotosAntes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      fotosDurante: (map['fotosDurante'] as List?)?.map((e) => e.toString()).toList() ?? [],
      fotosDespues: (map['fotosDespues'] as List?)?.map((e) => e.toString()).toList() ?? [],

      // Sub-modelos seguros
      materialesUsados: (map['materialesUsados'] as List?)
          ?.map((e) => TicketMaterial.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],

      historial: (map['historial'] as List?)
          ?.map((e) => TicketHistoryItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],

      check: checkMap != null ? TicketCheck.fromMap(checkMap) : null,

      clienteId: cliente['id']?.toString() ?? map['clienteId']?.toString() ?? '',
      clienteNombre: cliente['nombre']?.toString() ?? map['clienteNombre']?.toString() ?? 'Cliente',
      clienteTelefono: cliente['telefono']?.toString() ?? map['clienteTelefono']?.toString(),
      clienteEmail: cliente['email']?.toString() ?? map['clienteEmail']?.toString(),

      maestroId: maestro['id']?.toString() ?? map['toderoId']?.toString() ?? map['maestroId']?.toString(),
      maestroNombre: maestro['nombre']?.toString() ?? map['toderoNombre']?.toString() ?? map['maestroNombre']?.toString(),
      notasMaestro: map['notasMaestro']?.toString() ?? map['notasTodero']?.toString(),
      notasCliente: map['notasCliente']?.toString(),

      userId: map['userId']?.toString() ?? '',
      
      tipoServicio: ServiceType.values.firstWhere(
        (e) => e.value == map['tipoServicio']?.toString(),
        orElse: () => ServiceType.otro,
      ),
      
      presupuestoEstimado: _parseDouble(map['presupuestoEstimado']),
      costoFinal: _parseDouble(map['costoFinal']),
      
      fechaActualizacion: _parseDate(map['fechaActualizacion']),
      fechaInicio: map['fechaInicio'] != null ? _parseDate(map['fechaInicio']) : null,
      fechaCompletado: map['fechaCompletado'] != null ? _parseDate(map['fechaCompletado']) : null,
      
      firmaCliente: map['firmaCliente']?.toString(),
      firmaMaestro: map['firmaMaestro']?.toString(),
      
      fechaFirmaCliente: map['fechaFirmaCliente'] != null ? _parseDate(map['fechaFirmaCliente']) : null,
      fechaFirmaMaestro: map['fechaFirmaMaestro'] != null ? _parseDate(map['fechaFirmaMaestro']) : null,
      
      cotizacionAprobada: map['cotizacionAprobada'] == true,
      fechaCotizacionAprobada: map['fechaCotizacionAprobada'] != null ? _parseDate(map['fechaCotizacionAprobada']) : null,
    );
  }

  TicketModel copyWith({
    String? codigo,
    String? titulo,
    String? descripcion,
    TicketStatus? estado,
    TicketPriority? prioridad,
    String? ubicacionDireccion,
    double? ubicacionLat,
    double? ubicacionLng,
    String? propiedadId,
    String? espacioId,
    String? espacioNombre,
    List<String>? fotosAntes,
    List<String>? fotosDurante,
    List<String>? fotosDespues,
    List<TicketMaterial>? materialesUsados,
    List<TicketHistoryItem>? historial,
    TicketCheck? check,
    String? maestroId,
    String? maestroNombre,
    String? notasMaestro,
    String? notasCliente,
    DateTime? fechaActualizacion,
    DateTime? fechaInicio,
    DateTime? fechaCompletado,
    String? firmaCliente,
    String? firmaMaestro,
    DateTime? fechaFirmaCliente,
    DateTime? fechaFirmaMaestro,
    bool? cotizacionAprobada,
    DateTime? fechaCotizacionAprobada,
  }) {
    return TicketModel(
      id: id,
      codigo: codigo ?? this.codigo,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      fechaCreacion: fechaCreacion,
      fechaProgramada: fechaProgramada,
      ubicacionDireccion: ubicacionDireccion ?? this.ubicacionDireccion,
      ubicacionLat: ubicacionLat ?? this.ubicacionLat,
      ubicacionLng: ubicacionLng ?? this.ubicacionLng,
      propiedadId: propiedadId ?? this.propiedadId,
      espacioId: espacioId ?? this.espacioId,
      espacioNombre: espacioNombre ?? this.espacioNombre,
      fotosAntes: fotosAntes ?? this.fotosAntes,
      fotosDurante: fotosDurante ?? this.fotosDurante,
      fotosDespues: fotosDespues ?? this.fotosDespues,
      materialesUsados: materialesUsados ?? this.materialesUsados,
      historial: historial ?? this.historial,
      check: check ?? this.check,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      maestroId: maestroId ?? this.maestroId,
      maestroNombre: maestroNombre ?? this.maestroNombre,
      notasMaestro: notasMaestro ?? this.notasMaestro,
      notasCliente: notasCliente ?? this.notasCliente,
      userId: userId,
      tipoServicio: tipoServicio,
      presupuestoEstimado: presupuestoEstimado,
      costoFinal: costoFinal,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      firmaCliente: firmaCliente ?? this.firmaCliente,
      firmaMaestro: firmaMaestro ?? this.firmaMaestro,
      fechaFirmaCliente: fechaFirmaCliente ?? this.fechaFirmaCliente,
      fechaFirmaMaestro: fechaFirmaMaestro ?? this.fechaFirmaMaestro,
      cotizacionAprobada: cotizacionAprobada ?? this.cotizacionAprobada,
      fechaCotizacionAprobada: fechaCotizacionAprobada ?? this.fechaCotizacionAprobada,
    );
  }

  // Getters de compatibilidad
  String? get toderoId => maestroId;
  String? get toderoNombre => maestroNombre;
  String? get firmaTodero => firmaMaestro;
  String? get notasTodero => notasMaestro;
  DateTime? get fechaFirmaTodero => fechaFirmaMaestro;
  // String? get notasCliente => notasCliente; // Ya es un campo
  double? get calificacion => null; // Campo faltante
  String? get comentarioCalificacion => null; // Campo faltante
  String? get propiedadDireccion => ubicacionDireccion;
  List<String> get fotosProblema => fotosAntes;
  List<String> get fotosResultado => fotosDespues;
}
