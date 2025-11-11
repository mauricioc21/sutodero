import 'package:hive/hive.dart';
import 'inventory_property.dart';

part 'property_room.g.dart';

/// Tipos de espacios/habitaciones
enum RoomType {
  sala,
  comedor,
  cocina,
  dormitorio,
  bano,
  estudio,
  balcon,
  terraza,
  garaje,
  jardin,
  lavanderia,
  bodega,
  pasillo,
  recibidor,
  otro,
}

extension RoomTypeExtension on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.sala:
        return 'Sala';
      case RoomType.comedor:
        return 'Comedor';
      case RoomType.cocina:
        return 'Cocina';
      case RoomType.dormitorio:
        return 'Dormitorio';
      case RoomType.bano:
        return 'Baño';
      case RoomType.estudio:
        return 'Estudio';
      case RoomType.balcon:
        return 'Balcón';
      case RoomType.terraza:
        return 'Terraza';
      case RoomType.garaje:
        return 'Garaje';
      case RoomType.jardin:
        return 'Jardín';
      case RoomType.lavanderia:
        return 'Lavandería';
      case RoomType.bodega:
        return 'Bodega';
      case RoomType.pasillo:
        return 'Pasillo';
      case RoomType.recibidor:
        return 'Recibidor';
      case RoomType.otro:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case RoomType.sala:
        return '🛋️';
      case RoomType.comedor:
        return '🍽️';
      case RoomType.cocina:
        return '🍳';
      case RoomType.dormitorio:
        return '🛏️';
      case RoomType.bano:
        return '🚿';
      case RoomType.estudio:
        return '📚';
      case RoomType.balcon:
        return '🌇';
      case RoomType.terraza:
        return '🏖️';
      case RoomType.garaje:
        return '🚗';
      case RoomType.jardin:
        return '🌿';
      case RoomType.lavanderia:
        return '🧺';
      case RoomType.bodega:
        return '📦';
      case RoomType.pasillo:
        return '🚪';
      case RoomType.recibidor:
        return '🚪';
      case RoomType.otro:
        return '📍';
    }
  }
}

/// Modelo de espacio/habitación
@HiveType(typeId: 1)
class PropertyRoom extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String propertyId;

  @HiveField(2)
  String nombre;

  @HiveField(3)
  RoomType tipo;

  @HiveField(4)
  SpaceCondition estado;

  @HiveField(5)
  String? descripcion;

  @HiveField(6)
  List<String> fotos;

  @HiveField(7)
  String? foto360Url;

  @HiveField(8)
  DateTime fechaCreacion;

  @HiveField(9)
  DateTime? fechaActualizacion;

  @HiveField(10)
  double? ancho; // en metros

  @HiveField(11)
  double? largo; // en metros

  @HiveField(12)
  double? altura; // en metros

  @HiveField(13)
  String? observaciones;

  @HiveField(14)
  List<String> problemas; // Lista de problemas detectados

  PropertyRoom({
    required this.id,
    required this.propertyId,
    required this.nombre,
    this.tipo = RoomType.otro,
    this.estado = SpaceCondition.bueno,
    this.descripcion,
    List<String>? fotos,
    this.foto360Url,
    DateTime? fechaCreacion,
    this.fechaActualizacion,
    this.ancho,
    this.largo,
    this.altura,
    this.observaciones,
    List<String>? problemas,
  })  : fotos = fotos ?? [],
        problemas = problemas ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Área calculada (ancho × largo)
  double? get area {
    if (ancho != null && largo != null) {
      return ancho! * largo!;
    }
    return null;
  }

  /// Volumen calculado (ancho × largo × altura)
  double? get volumen {
    if (ancho != null && largo != null && altura != null) {
      return ancho! * largo! * altura!;
    }
    return null;
  }

  /// ¿Tiene foto 360°?
  bool get tiene360 => foto360Url != null && foto360Url!.isNotEmpty;

  /// Convierte a Map para JSON/Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'nombre': nombre,
      'tipo': tipo.name,
      'estado': estado.name,
      'descripcion': descripcion,
      'fotos': fotos,
      'foto360Url': foto360Url,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'ancho': ancho,
      'largo': largo,
      'altura': altura,
      'observaciones': observaciones,
      'problemas': problemas,
    };
  }

  /// Crea desde Map (JSON/Firebase)
  factory PropertyRoom.fromMap(Map<String, dynamic> map) {
    return PropertyRoom(
      id: map['id'] ?? '',
      propertyId: map['propertyId'] ?? '',
      nombre: map['nombre'] ?? '',
      tipo: RoomType.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => RoomType.otro,
      ),
      estado: SpaceCondition.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => SpaceCondition.bueno,
      ),
      descripcion: map['descripcion'],
      fotos: List<String>.from(map['fotos'] ?? []),
      foto360Url: map['foto360Url'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
          : null,
      ancho: map['ancho']?.toDouble(),
      largo: map['largo']?.toDouble(),
      altura: map['altura']?.toDouble(),
      observaciones: map['observaciones'],
      problemas: List<String>.from(map['problemas'] ?? []),
    );
  }

  /// Copia con modificaciones
  PropertyRoom copyWith({
    String? id,
    String? propertyId,
    String? nombre,
    RoomType? tipo,
    SpaceCondition? estado,
    String? descripcion,
    List<String>? fotos,
    String? foto360Url,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    double? ancho,
    double? largo,
    double? altura,
    String? observaciones,
    List<String>? problemas,
  }) {
    return PropertyRoom(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      fotos: fotos ?? this.fotos,
      foto360Url: foto360Url ?? this.foto360Url,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      ancho: ancho ?? this.ancho,
      largo: largo ?? this.largo,
      altura: altura ?? this.altura,
      observaciones: observaciones ?? this.observaciones,
      problemas: problemas ?? this.problemas,
    );
  }
}
