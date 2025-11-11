import 'package:hive/hive.dart';

part 'inventory_property.g.dart';

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
@HiveType(typeId: 0)
class InventoryProperty extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String direccion;

  @HiveField(2)
  String? clienteNombre;

  @HiveField(3)
  String? clienteTelefono;

  @HiveField(4)
  String? clienteEmail;

  @HiveField(5)
  PropertyType tipo;

  @HiveField(6)
  String? descripcion;

  @HiveField(7)
  List<String> fotos;

  @HiveField(8)
  DateTime fechaCreacion;

  @HiveField(9)
  DateTime? fechaActualizacion;

  @HiveField(10)
  String? observaciones;

  @HiveField(11)
  double? area; // en m²

  @HiveField(12)
  int? numeroHabitaciones;

  @HiveField(13)
  int? numeroBanos;

  @HiveField(14)
  bool activa;

  InventoryProperty({
    required this.id,
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
  })  : fotos = fotos ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Convierte a Map para JSON/Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }

  /// Crea desde Map (JSON/Firebase)
  factory InventoryProperty.fromMap(Map<String, dynamic> map) {
    return InventoryProperty(
      id: map['id'] ?? '',
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
    );
  }

  /// Copia con modificaciones
  InventoryProperty copyWith({
    String? id,
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
  }) {
    return InventoryProperty(
      id: id ?? this.id,
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
    );
  }
}
