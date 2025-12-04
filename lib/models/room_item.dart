/// Tipos de elementos comunes en espacios
enum ItemType {
  pisos,
  paredes,
  puertas,
  ventanas,
  techo,
  cielo_raso,
  iluminacion,
  tomacorrientes,
  interruptores,
  muebles,
  sanitarios,
  lavamanos,
  ducha,
  griferias,
  desagues,
  electrodomesticos,
  gabinetes,
  mesones,
  closets,
  cortinas,
  persianas,
  aire_acondicionado,
  calefaccion,
  otro,
}

extension ItemTypeExtension on ItemType {
  String get displayName {
    switch (this) {
      case ItemType.pisos:
        return 'Pisos';
      case ItemType.paredes:
        return 'Paredes';
      case ItemType.puertas:
        return 'Puertas';
      case ItemType.ventanas:
        return 'Ventanas';
      case ItemType.techo:
        return 'Techo';
      case ItemType.cielo_raso:
        return 'Cielo Raso';
      case ItemType.iluminacion:
        return 'Iluminación';
      case ItemType.tomacorrientes:
        return 'Tomacorrientes';
      case ItemType.interruptores:
        return 'Interruptores';
      case ItemType.muebles:
        return 'Muebles';
      case ItemType.sanitarios:
        return 'Sanitarios';
      case ItemType.lavamanos:
        return 'Lavamanos';
      case ItemType.ducha:
        return 'Ducha';
      case ItemType.griferias:
        return 'Griferías';
      case ItemType.desagues:
        return 'Desagües';
      case ItemType.electrodomesticos:
        return 'Electrodomésticos';
      case ItemType.gabinetes:
        return 'Gabinetes';
      case ItemType.mesones:
        return 'Mesones';
      case ItemType.closets:
        return 'Closets';
      case ItemType.cortinas:
        return 'Cortinas';
      case ItemType.persianas:
        return 'Persianas';
      case ItemType.aire_acondicionado:
        return 'Aire Acondicionado';
      case ItemType.calefaccion:
        return 'Calefacción';
      case ItemType.otro:
        return 'Otro';
    }
  }
}

/// Materiales comunes
enum MaterialType {
  concreto,
  ladrillo,
  madera,
  metal,
  vidrio,
  ceramica,
  porcelanato,
  baldosa,
  vinilo,
  alfombra,
  marmol,
  granito,
  cuarzo,
  plastico,
  acero_inoxidable,
  aluminio,
  pvc,
  drywall,
  yeso,
  pintura,
  papel_tapiz,
  piedra,
  cemento,
  otro,
}

extension MaterialTypeExtension on MaterialType {
  String get displayName {
    switch (this) {
      case MaterialType.concreto:
        return 'Concreto';
      case MaterialType.ladrillo:
        return 'Ladrillo';
      case MaterialType.madera:
        return 'Madera';
      case MaterialType.metal:
        return 'Metal';
      case MaterialType.vidrio:
        return 'Vidrio';
      case MaterialType.ceramica:
        return 'Cerámica';
      case MaterialType.porcelanato:
        return 'Porcelanato';
      case MaterialType.baldosa:
        return 'Baldosa';
      case MaterialType.vinilo:
        return 'Vinilo';
      case MaterialType.alfombra:
        return 'Alfombra';
      case MaterialType.marmol:
        return 'Mármol';
      case MaterialType.granito:
        return 'Granito';
      case MaterialType.cuarzo:
        return 'Cuarzo';
      case MaterialType.plastico:
        return 'Plástico';
      case MaterialType.acero_inoxidable:
        return 'Acero Inoxidable';
      case MaterialType.aluminio:
        return 'Aluminio';
      case MaterialType.pvc:
        return 'PVC';
      case MaterialType.drywall:
        return 'Drywall';
      case MaterialType.yeso:
        return 'Yeso';
      case MaterialType.pintura:
        return 'Pintura';
      case MaterialType.papel_tapiz:
        return 'Papel Tapiz';
      case MaterialType.piedra:
        return 'Piedra';
      case MaterialType.cemento:
        return 'Cemento';
      case MaterialType.otro:
        return 'Otro';
    }
  }
}

/// Estado del elemento
enum ItemCondition {
  excelente,
  bueno,
  regular,
  malo,
  critico,
}

extension ItemConditionExtension on ItemCondition {
  String get displayName {
    switch (this) {
      case ItemCondition.excelente:
        return 'Excelente';
      case ItemCondition.bueno:
        return 'Bueno';
      case ItemCondition.regular:
        return 'Regular';
      case ItemCondition.malo:
        return 'Malo';
      case ItemCondition.critico:
        return 'Crítico';
    }
  }

  String get emoji {
    switch (this) {
      case ItemCondition.excelente:
        return '⭐';
      case ItemCondition.bueno:
        return '👍';
      case ItemCondition.regular:
        return '👌';
      case ItemCondition.malo:
        return '⚠️';
      case ItemCondition.critico:
        return '🚨';
    }
  }
}

/// Modelo de elemento/item dentro de un espacio
class RoomItem {
  String id;
  String roomId; // ID del espacio al que pertenece
  int cantidad; // Número de elementos (ej: 4 paredes)
  ItemType tipo; // Tipo de elemento
  String? nombrePersonalizado; // Para tipo "otro"
  MaterialType material; // Material del elemento
  String? materialPersonalizado; // Para material "otro"
  ItemCondition estado; // Estado/condición del elemento
  String? comentarios; // Observaciones adicionales
  List<String> fotos; // URLs de fotos del elemento
  DateTime fechaCreacion;
  DateTime? fechaActualizacion;

  RoomItem({
    required this.id,
    required this.roomId,
    this.cantidad = 1,
    required this.tipo,
    this.nombrePersonalizado,
    required this.material,
    this.materialPersonalizado,
    this.estado = ItemCondition.bueno,
    this.comentarios,
    List<String>? fotos,
    DateTime? fechaCreacion,
    this.fechaActualizacion,
  })  : fotos = fotos ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Obtiene el nombre del elemento (usa personalizado si es "otro")
  String get nombreElemento {
    if (tipo == ItemType.otro && nombrePersonalizado != null) {
      return nombrePersonalizado!;
    }
    return tipo.displayName;
  }

  /// Obtiene el nombre del material (usa personalizado si es "otro")
  String get nombreMaterial {
    if (material == MaterialType.otro && materialPersonalizado != null) {
      return materialPersonalizado!;
    }
    return material.displayName;
  }

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'cantidad': cantidad,
      'tipo': tipo.name,
      'nombrePersonalizado': nombrePersonalizado,
      'material': material.name,
      'materialPersonalizado': materialPersonalizado,
      'estado': estado.name,
      'comentarios': comentarios,
      'fotos': fotos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory RoomItem.fromMap(Map<String, dynamic> map) {
    return RoomItem(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      cantidad: map['cantidad'] ?? 1,
      tipo: ItemType.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => ItemType.otro,
      ),
      nombrePersonalizado: map['nombrePersonalizado'],
      material: MaterialType.values.firstWhere(
        (e) => e.name == map['material'],
        orElse: () => MaterialType.otro,
      ),
      materialPersonalizado: map['materialPersonalizado'],
      estado: ItemCondition.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => ItemCondition.bueno,
      ),
      comentarios: map['comentarios'],
      fotos: List<String>.from(map['fotos'] ?? []),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'])
          : null,
    );
  }

  /// Copia con modificaciones
  RoomItem copyWith({
    String? id,
    String? roomId,
    int? cantidad,
    ItemType? tipo,
    String? nombrePersonalizado,
    MaterialType? material,
    String? materialPersonalizado,
    ItemCondition? estado,
    String? comentarios,
    List<String>? fotos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return RoomItem(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      cantidad: cantidad ?? this.cantidad,
      tipo: tipo ?? this.tipo,
      nombrePersonalizado: nombrePersonalizado ?? this.nombrePersonalizado,
      material: material ?? this.material,
      materialPersonalizado: materialPersonalizado ?? this.materialPersonalizado,
      estado: estado ?? this.estado,
      comentarios: comentarios ?? this.comentarios,
      fotos: fotos ?? this.fotos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
