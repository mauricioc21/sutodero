import 'inventory_property.dart';
import 'room_features.dart';

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
class PropertyRoom {
  String id;
  String propertyId;
  String nombre;
  RoomType tipo;
  SpaceCondition estado;
  String? descripcion;
  List<String> fotos;
  String? foto360Url;
  DateTime fechaCreacion;
  DateTime? fechaActualizacion;
  double? ancho; // en metros
  double? largo; // en metros
  double? altura; // en metros
  String? observaciones;
  List<String> problemas; // Lista de problemas detectados
  
  // Campos adicionales de características (estilo MLS/Metrocuadrado/Fincaraiz)
  FloorType? tipoPiso;
  KitchenType? tipoCocina; // Solo para cocinas
  CountertopMaterial? materialMeson; // Solo para cocinas
  BathroomType? tipoBano; // Solo para baños
  BathroomFinish? acabadoBano; // Solo para baños
  ClosetType? tipoCloset; // Principalmente para dormitorios
  ViewType? vista;
  NaturalLighting? iluminacionNatural;

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
    this.tipoPiso,
    this.tipoCocina,
    this.materialMeson,
    this.tipoBano,
    this.acabadoBano,
    this.tipoCloset,
    this.vista,
    this.iluminacionNatural,
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
      'tipoPiso': tipoPiso?.name,
      'tipoCocina': tipoCocina?.name,
      'materialMeson': materialMeson?.name,
      'tipoBano': tipoBano?.name,
      'acabadoBano': acabadoBano?.name,
      'tipoCloset': tipoCloset?.name,
      'vista': vista?.name,
      'iluminacionNatural': iluminacionNatural?.name,
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
      tipoPiso: map['tipoPiso'] != null
          ? FloorType.values.firstWhere(
              (e) => e.name == map['tipoPiso'],
              orElse: () => FloorType.otro,
            )
          : null,
      tipoCocina: map['tipoCocina'] != null
          ? KitchenType.values.firstWhere(
              (e) => e.name == map['tipoCocina'],
              orElse: () => KitchenType.basica,
            )
          : null,
      materialMeson: map['materialMeson'] != null
          ? CountertopMaterial.values.firstWhere(
              (e) => e.name == map['materialMeson'],
              orElse: () => CountertopMaterial.otro,
            )
          : null,
      tipoBano: map['tipoBano'] != null
          ? BathroomType.values.firstWhere(
              (e) => e.name == map['tipoBano'],
              orElse: () => BathroomType.completo,
            )
          : null,
      acabadoBano: map['acabadoBano'] != null
          ? BathroomFinish.values.firstWhere(
              (e) => e.name == map['acabadoBano'],
              orElse: () => BathroomFinish.otro,
            )
          : null,
      tipoCloset: map['tipoCloset'] != null
          ? ClosetType.values.firstWhere(
              (e) => e.name == map['tipoCloset'],
              orElse: () => ClosetType.sinCloset,
            )
          : null,
      vista: map['vista'] != null
          ? ViewType.values.firstWhere(
              (e) => e.name == map['vista'],
              orElse: () => ViewType.interior,
            )
          : null,
      iluminacionNatural: map['iluminacionNatural'] != null
          ? NaturalLighting.values.firstWhere(
              (e) => e.name == map['iluminacionNatural'],
              orElse: () => NaturalLighting.regular,
            )
          : null,
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
    FloorType? tipoPiso,
    KitchenType? tipoCocina,
    CountertopMaterial? materialMeson,
    BathroomType? tipoBano,
    BathroomFinish? acabadoBano,
    ClosetType? tipoCloset,
    ViewType? vista,
    NaturalLighting? iluminacionNatural,
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
      tipoPiso: tipoPiso ?? this.tipoPiso,
      tipoCocina: tipoCocina ?? this.tipoCocina,
      materialMeson: materialMeson ?? this.materialMeson,
      tipoBano: tipoBano ?? this.tipoBano,
      acabadoBano: acabadoBano ?? this.acabadoBano,
      tipoCloset: tipoCloset ?? this.tipoCloset,
      vista: vista ?? this.vista,
      iluminacionNatural: iluminacionNatural ?? this.iluminacionNatural,
    );
  }
}
