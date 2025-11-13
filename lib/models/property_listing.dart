/// Tipos de transacción inmobiliaria
enum TransactionType {
  venta,
  arriendo,
  ventaArriendo,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.venta:
        return 'Venta';
      case TransactionType.arriendo:
        return 'Arriendo';
      case TransactionType.ventaArriendo:
        return 'Venta o Arriendo';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.venta:
        return '💰';
      case TransactionType.arriendo:
        return '🔑';
      case TransactionType.ventaArriendo:
        return '💰🔑';
    }
  }
}

/// Estado de la captación del inmueble
enum ListingStatus {
  activo,
  enNegociacion,
  vendido,
  arrendado,
  cancelado,
}

extension ListingStatusExtension on ListingStatus {
  String get displayName {
    switch (this) {
      case ListingStatus.activo:
        return 'Activo';
      case ListingStatus.enNegociacion:
        return 'En Negociación';
      case ListingStatus.vendido:
        return 'Vendido';
      case ListingStatus.arrendado:
        return 'Arrendado';
      case ListingStatus.cancelado:
        return 'Cancelado';
    }
  }
}

/// Modelo para captación de inmuebles (venta/arriendo)
class PropertyListing {
  String id;
  String userId; // ID del usuario propietario
  
  // Información básica
  String titulo;
  String direccion;
  String? ciudad;
  String? barrio;
  String tipo; // casa, apartamento, local, etc.
  TransactionType transaccionTipo;
  ListingStatus estado;
  
  // Detalles del inmueble
  String? descripcion;
  double? area; // en m²
  int? numeroHabitaciones;
  int? numeroBanos;
  int? numeroParqueaderos;
  int? estrato;
  int? antiguedad; // años
  
  // Precios
  double? precioVenta;
  double? precioArriendo;
  double? administracion;
  
  // Características
  List<String> caracteristicas; // ['Balcón', 'Cocina integral', etc.]
  
  // Medios (URLs de Firebase Storage)
  List<String> fotos;
  List<String> fotos360;
  String? plano2DUrl;
  String? plano3DUrl;
  String? tourVirtualId; // ID del tour virtual en collection 'virtual_tours'
  
  // Información del propietario
  String? propietarioNombre;
  String? propietarioTelefono;
  String? propietarioEmail;
  
  // Metadata
  DateTime fechaCreacion;
  DateTime? fechaActualizacion;
  String? observaciones;
  bool activo;

  PropertyListing({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.direccion,
    this.ciudad,
    this.barrio,
    required this.tipo,
    this.transaccionTipo = TransactionType.venta,
    this.estado = ListingStatus.activo,
    this.descripcion,
    this.area,
    this.numeroHabitaciones,
    this.numeroBanos,
    this.numeroParqueaderos,
    this.estrato,
    this.antiguedad,
    this.precioVenta,
    this.precioArriendo,
    this.administracion,
    List<String>? caracteristicas,
    List<String>? fotos,
    List<String>? fotos360,
    this.plano2DUrl,
    this.plano3DUrl,
    this.tourVirtualId,
    this.propietarioNombre,
    this.propietarioTelefono,
    this.propietarioEmail,
    DateTime? fechaCreacion,
    this.fechaActualizacion,
    this.observaciones,
    this.activo = true,
  })  : caracteristicas = caracteristicas ?? [],
        fotos = fotos ?? [],
        fotos360 = fotos360 ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Convierte a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'titulo': titulo,
      'direccion': direccion,
      'ciudad': ciudad,
      'barrio': barrio,
      'tipo': tipo,
      'transaccionTipo': transaccionTipo.name,
      'estado': estado.name,
      'descripcion': descripcion,
      'area': area,
      'numeroHabitaciones': numeroHabitaciones,
      'numeroBanos': numeroBanos,
      'numeroParqueaderos': numeroParqueaderos,
      'estrato': estrato,
      'antiguedad': antiguedad,
      'precioVenta': precioVenta,
      'precioArriendo': precioArriendo,
      'administracion': administracion,
      'caracteristicas': caracteristicas,
      'fotos': fotos,
      'fotos360': fotos360,
      'plano2DUrl': plano2DUrl,
      'plano3DUrl': plano3DUrl,
      'tourVirtualId': tourVirtualId,
      'propietarioNombre': propietarioNombre,
      'propietarioTelefono': propietarioTelefono,
      'propietarioEmail': propietarioEmail,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'observaciones': observaciones,
      'activo': activo,
    };
  }

  /// Crea desde Map de Firebase
  factory PropertyListing.fromMap(Map<String, dynamic> map) {
    return PropertyListing(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      titulo: map['titulo'] ?? '',
      direccion: map['direccion'] ?? '',
      ciudad: map['ciudad'],
      barrio: map['barrio'],
      tipo: map['tipo'] ?? 'casa',
      transaccionTipo: TransactionType.values.firstWhere(
        (e) => e.name == map['transaccionTipo'],
        orElse: () => TransactionType.venta,
      ),
      estado: ListingStatus.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => ListingStatus.activo,
      ),
      descripcion: map['descripcion'],
      area: map['area']?.toDouble(),
      numeroHabitaciones: map['numeroHabitaciones'],
      numeroBanos: map['numeroBanos'],
      numeroParqueaderos: map['numeroParqueaderos'],
      estrato: map['estrato'],
      antiguedad: map['antiguedad'],
      precioVenta: map['precioVenta']?.toDouble(),
      precioArriendo: map['precioArriendo']?.toDouble(),
      administracion: map['administracion']?.toDouble(),
      caracteristicas: List<String>.from(map['caracteristicas'] ?? []),
      fotos: List<String>.from(map['fotos'] ?? []),
      fotos360: List<String>.from(map['fotos360'] ?? []),
      plano2DUrl: map['plano2DUrl'],
      plano3DUrl: map['plano3DUrl'],
      tourVirtualId: map['tourVirtualId'],
      propietarioNombre: map['propietarioNombre'],
      propietarioTelefono: map['propietarioTelefono'],
      propietarioEmail: map['propietarioEmail'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
          : null,
      observaciones: map['observaciones'],
      activo: map['activo'] ?? true,
    );
  }

  /// Obtiene el precio para mostrar según el tipo de transacción
  String getPrecioDisplay() {
    if (transaccionTipo == TransactionType.venta && precioVenta != null) {
      return '\$${precioVenta!.toStringAsFixed(0)}';
    } else if (transaccionTipo == TransactionType.arriendo && precioArriendo != null) {
      return '\$${precioArriendo!.toStringAsFixed(0)}/mes';
    } else if (transaccionTipo == TransactionType.ventaArriendo) {
      final venta = precioVenta != null ? '\$${precioVenta!.toStringAsFixed(0)}' : '-';
      final arriendo = precioArriendo != null ? '\$${precioArriendo!.toStringAsFixed(0)}/mes' : '-';
      return 'V: $venta | A: $arriendo';
    }
    return 'Precio no especificado';
  }

  /// Verifica si tiene todos los medios completos
  bool get tieneMediaCompleta {
    return fotos.isNotEmpty &&
        fotos360.isNotEmpty &&
        plano2DUrl != null &&
        plano3DUrl != null &&
        tourVirtualId != null;
  }

  /// Obtiene el porcentaje de completitud de medios (0-100)
  int get porcentajeCompletitud {
    int total = 0;
    int completado = 0;

    // Fotos (20%)
    total += 20;
    if (fotos.isNotEmpty) completado += 20;

    // Fotos 360 (20%)
    total += 20;
    if (fotos360.isNotEmpty) completado += 20;

    // Plano 2D (20%)
    total += 20;
    if (plano2DUrl != null) completado += 20;

    // Plano 3D (20%)
    total += 20;
    if (plano3DUrl != null) completado += 20;

    // Tour Virtual (20%)
    total += 20;
    if (tourVirtualId != null) completado += 20;

    return ((completado / total) * 100).round();
  }

  /// Copia con modificaciones
  PropertyListing copyWith({
    String? id,
    String? userId,
    String? titulo,
    String? direccion,
    String? ciudad,
    String? barrio,
    String? tipo,
    TransactionType? transaccionTipo,
    ListingStatus? estado,
    String? descripcion,
    double? area,
    int? numeroHabitaciones,
    int? numeroBanos,
    int? numeroParqueaderos,
    int? estrato,
    int? antiguedad,
    double? precioVenta,
    double? precioArriendo,
    double? administracion,
    List<String>? caracteristicas,
    List<String>? fotos,
    List<String>? fotos360,
    String? plano2DUrl,
    String? plano3DUrl,
    String? tourVirtualId,
    String? propietarioNombre,
    String? propietarioTelefono,
    String? propietarioEmail,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? observaciones,
    bool? activo,
  }) {
    return PropertyListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      barrio: barrio ?? this.barrio,
      tipo: tipo ?? this.tipo,
      transaccionTipo: transaccionTipo ?? this.transaccionTipo,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      area: area ?? this.area,
      numeroHabitaciones: numeroHabitaciones ?? this.numeroHabitaciones,
      numeroBanos: numeroBanos ?? this.numeroBanos,
      numeroParqueaderos: numeroParqueaderos ?? this.numeroParqueaderos,
      estrato: estrato ?? this.estrato,
      antiguedad: antiguedad ?? this.antiguedad,
      precioVenta: precioVenta ?? this.precioVenta,
      precioArriendo: precioArriendo ?? this.precioArriendo,
      administracion: administracion ?? this.administracion,
      caracteristicas: caracteristicas ?? this.caracteristicas,
      fotos: fotos ?? this.fotos,
      fotos360: fotos360 ?? this.fotos360,
      plano2DUrl: plano2DUrl ?? this.plano2DUrl,
      plano3DUrl: plano3DUrl ?? this.plano3DUrl,
      tourVirtualId: tourVirtualId ?? this.tourVirtualId,
      propietarioNombre: propietarioNombre ?? this.propietarioNombre,
      propietarioTelefono: propietarioTelefono ?? this.propietarioTelefono,
      propietarioEmail: propietarioEmail ?? this.propietarioEmail,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
    );
  }
}
