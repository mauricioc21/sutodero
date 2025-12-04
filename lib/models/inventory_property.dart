/// Estados posibles de un espacio
enum SpaceCondition {
  excelente,
  bueno,
  regular,
  malo,
  critico,
}

extension SpaceConditionExtension on SpaceCondition {
  String get displayName {
    switch (this) {
      case SpaceCondition.excelente:
        return 'Excelente';
      case SpaceCondition.bueno:
        return 'Bueno';
      case SpaceCondition.regular:
        return 'Regular';
      case SpaceCondition.malo:
        return 'Malo';
      case SpaceCondition.critico:
        return 'Crítico';
    }
  }

  String get emoji {
    switch (this) {
      case SpaceCondition.excelente:
        return '⭐';
      case SpaceCondition.bueno:
        return '👍';
      case SpaceCondition.regular:
        return '👌';
      case SpaceCondition.malo:
        return '⚠️';
      case SpaceCondition.critico:
        return '🚨';
    }
  }
}

/// Tipos de propiedad
enum PropertyType {
  casa,
  apartamento,
  oficina,
  local,
  bodega,
  terreno,
  otro,
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.casa:
        return 'Casa';
      case PropertyType.apartamento:
        return 'Apartamento';
      case PropertyType.oficina:
        return 'Oficina';
      case PropertyType.local:
        return 'Local Comercial';
      case PropertyType.bodega:
        return 'Bodega';
      case PropertyType.terreno:
        return 'Terreno';
      case PropertyType.otro:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case PropertyType.casa:
        return '🏠';
      case PropertyType.apartamento:
        return '🏢';
      case PropertyType.oficina:
        return '🏛️';
      case PropertyType.local:
        return '🏪';
      case PropertyType.bodega:
        return '🏭';
      case PropertyType.terreno:
        return '🌳';
      case PropertyType.otro:
        return '📦';
    }
  }
}

/// Modelo de propiedad en inventario
class InventoryProperty {
  String id;
  String userId; // ID del usuario propietario
  String direccion;
  String? clienteNombre;
  String? clienteTelefono;
  String? clienteEmail;
  PropertyType tipo;
  String? descripcion;
  List<String> fotos;
  DateTime fechaCreacion;
  DateTime? fechaActualizacion;
  String? observaciones;
  double? area; // en m²
  int? numeroHabitaciones;
  int? numeroBanos;
  bool activa;
  
  // Nuevos campos - alineados con PropertyListing
  String? pais; // País
  String? ciudad; // Ciudad
  String? municipio; // Municipio/Departamento/Estado
  String? barrio; // Barrio/Colonia
  int? numeroNiveles; // Niveles del inmueble
  String? numeroInterior; // Número de casa, apto, etc (opcional)
  double? areaLote; // Área del lote en m² (opcional)
  String? codigoInterno; // Código interno de la agencia (opcional)
  
  // Información de captación
  double? precioAlquilerDeseado; // Precio de alquiler deseado
  String? nombreAgente; // Nombre del agente inmobiliario
  
  // Documento de identidad del propietario
  String? tipoDocumento; // Tipo de documento: C.C., C.E., NIT
  String? numeroDocumento; // Número de documento de identidad

  InventoryProperty({
    required this.id,
    required this.userId,
    required this.direccion,
    this.clienteNombre,
    this.clienteTelefono,
    this.clienteEmail,
    this.tipo = PropertyType.casa,
    this.descripcion,
    List<String>? fotos,
    DateTime? fechaCreacion,
    this.fechaActualizacion,
    this.observaciones,
    this.area,
    this.numeroHabitaciones,
    this.numeroBanos,
    this.activa = true,
    this.pais,
    this.ciudad,
    this.municipio,
    this.barrio,
    this.numeroNiveles,
    this.numeroInterior,
    this.areaLote,
    this.codigoInterno,
    this.precioAlquilerDeseado,
    this.nombreAgente,
    this.tipoDocumento,
    this.numeroDocumento,
  })  : fotos = fotos ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Convierte a Map para JSON/Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'direccion': direccion,
      'clienteNombre': clienteNombre,
      'clienteTelefono': clienteTelefono,
      'clienteEmail': clienteEmail,
      'tipo': tipo.name,
      'descripcion': descripcion,
      'fotos': fotos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'observaciones': observaciones,
      'area': area,
      'numeroHabitaciones': numeroHabitaciones,
      'numeroBanos': numeroBanos,
      'activa': activa,
      'pais': pais,
      'ciudad': ciudad,
      'municipio': municipio,
      'barrio': barrio,
      'numeroNiveles': numeroNiveles,
      'numeroInterior': numeroInterior,
      'areaLote': areaLote,
      'codigoInterno': codigoInterno,
      'precioAlquilerDeseado': precioAlquilerDeseado,
      'nombreAgente': nombreAgente,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
    };
  }

  /// Crea desde Map (JSON/Firebase)
  factory InventoryProperty.fromMap(Map<String, dynamic> map) {
    return InventoryProperty(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      direccion: map['direccion'] ?? '',
      clienteNombre: map['clienteNombre'],
      clienteTelefono: map['clienteTelefono'],
      clienteEmail: map['clienteEmail'],
      tipo: PropertyType.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => PropertyType.casa,
      ),
      descripcion: map['descripcion'],
      fotos: List<String>.from(map['fotos'] ?? []),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
          : null,
      observaciones: map['observaciones'],
      area: map['area']?.toDouble(),
      numeroHabitaciones: map['numeroHabitaciones'],
      numeroBanos: map['numeroBanos'],
      activa: map['activa'] ?? true,
      pais: map['pais'],
      ciudad: map['ciudad'],
      municipio: map['municipio'],
      barrio: map['barrio'],
      numeroNiveles: map['numeroNiveles'],
      numeroInterior: map['numeroInterior'],
      areaLote: map['areaLote']?.toDouble(),
      codigoInterno: map['codigoInterno'],
      precioAlquilerDeseado: map['precioAlquilerDeseado']?.toDouble(),
      nombreAgente: map['nombreAgente'],
      tipoDocumento: map['tipoDocumento'],
      numeroDocumento: map['numeroDocumento'],
    );
  }

  /// Copia con modificaciones
  InventoryProperty copyWith({
    String? id,
    String? userId,
    String? direccion,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    PropertyType? tipo,
    String? descripcion,
    List<String>? fotos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? observaciones,
    double? area,
    int? numeroHabitaciones,
    int? numeroBanos,
    bool? activa,
    String? pais,
    String? ciudad,
    String? municipio,
    String? barrio,
    int? numeroNiveles,
    String? numeroInterior,
    double? areaLote,
    String? codigoInterno,
    double? precioAlquilerDeseado,
    String? nombreAgente,
    String? tipoDocumento,
    String? numeroDocumento,
  }) {
    return InventoryProperty(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      direccion: direccion ?? this.direccion,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      fotos: fotos ?? this.fotos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      observaciones: observaciones ?? this.observaciones,
      area: area ?? this.area,
      numeroHabitaciones: numeroHabitaciones ?? this.numeroHabitaciones,
      numeroBanos: numeroBanos ?? this.numeroBanos,
      activa: activa ?? this.activa,
      pais: pais ?? this.pais,
      ciudad: ciudad ?? this.ciudad,
      municipio: municipio ?? this.municipio,
      barrio: barrio ?? this.barrio,
      numeroNiveles: numeroNiveles ?? this.numeroNiveles,
      numeroInterior: numeroInterior ?? this.numeroInterior,
      areaLote: areaLote ?? this.areaLote,
      codigoInterno: codigoInterno ?? this.codigoInterno,
      precioAlquilerDeseado: precioAlquilerDeseado ?? this.precioAlquilerDeseado,
      nombreAgente: nombreAgente ?? this.nombreAgente,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
    );
  }
}
