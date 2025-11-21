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
  String? plano2dUrl; // URL del plano 2D en Firebase Storage
  String? plano3dUrl; // URL del plano 3D isométrico en Firebase Storage

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
    this.plano2dUrl,
    this.plano3dUrl,
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
      'plano2dUrl': plano2dUrl,
      'plano3dUrl': plano3dUrl,
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
      plano2dUrl: map['plano2dUrl'],
      plano3dUrl: map['plano3dUrl'],
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
    String? plano2dUrl,
    String? plano3dUrl,
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
      plano2dUrl: plano2dUrl ?? this.plano2dUrl,
      plano3dUrl: plano3dUrl ?? this.plano3dUrl,
    );
  }
}
