import 'inventory_property.dart';
import 'room_features.dart';
import 'room_item.dart';

/// Tipos de espacios/habitaciones
enum RoomType {
  alcoba,
  alcobaAuxiliar,
  antejardin,
  areaDeServicio,
  atico,
  balcon,
  bano,
  biblioteca,
  bodega,
  closetAbierto,
  cochera,
  cocina,
  cocinaAmericana,
  cocineta,
  cocinaZonaOficios,
  comedor,
  contadores,
  corredor,
  cuartoDeServicio,
  cuartoUtil,
  cubierta,
  deposito,
  despacho,
  dormitorio,
  entrada,
  entresuelo,
  escaleras,
  estacionamiento,
  estudio,
  fachada,
  garaje,
  gradas,
  habitacion,
  hallDeAlcobas,
  hallDeEntrada,
  jardin,
  lavanderia,
  linderos,
  living,
  local,
  medidores,
  mezzanine,
  oficina,
  parqueadero,
  pasillo,
  patio,
  recepcion,
  recibidor,
  sala,
  salaAuxiliar,
  salaComedor,
  salaDeTV,
  salaDeEstar,
  salaDeJuntas,
  salon,
  serviciosPublicos,
  sotano,
  terraza,
  vestier,
  walkInCloset,
  zonaBBQ,
  zonaDeOficios,
  zonaDeRopas,
  otro,
}

extension RoomTypeExtension on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.alcoba:
        return 'Alcoba';
      case RoomType.alcobaAuxiliar:
        return 'Alcoba auxiliar';
      case RoomType.antejardin:
        return 'Antejardín';
      case RoomType.areaDeServicio:
        return 'Área de servicio';
      case RoomType.atico:
        return 'Ático';
      case RoomType.balcon:
        return 'Balcón';
      case RoomType.bano:
        return 'Baño';
      case RoomType.biblioteca:
        return 'Biblioteca';
      case RoomType.bodega:
        return 'Bodega';
      case RoomType.closetAbierto:
        return 'Closet abierto';
      case RoomType.cochera:
        return 'Cochera';
      case RoomType.cocina:
        return 'Cocina';
      case RoomType.cocinaAmericana:
        return 'Cocina americana';
      case RoomType.cocineta:
        return 'Cocineta';
      case RoomType.cocinaZonaOficios:
        return 'Cocina / zona de oficios';
      case RoomType.comedor:
        return 'Comedor';
      case RoomType.contadores:
        return 'Contadores';
      case RoomType.corredor:
        return 'Corredor';
      case RoomType.cuartoDeServicio:
        return 'Cuarto de servicio';
      case RoomType.cuartoUtil:
        return 'Cuarto útil';
      case RoomType.cubierta:
        return 'Cubierta';
      case RoomType.deposito:
        return 'Depósito';
      case RoomType.despacho:
        return 'Despacho';
      case RoomType.dormitorio:
        return 'Dormitorio';
      case RoomType.entrada:
        return 'Entrada';
      case RoomType.entresuelo:
        return 'Entresuelo';
      case RoomType.escaleras:
        return 'Escaleras';
      case RoomType.estacionamiento:
        return 'Estacionamiento';
      case RoomType.estudio:
        return 'Estudio';
      case RoomType.fachada:
        return 'Fachada';
      case RoomType.garaje:
        return 'Garaje';
      case RoomType.gradas:
        return 'Gradas';
      case RoomType.habitacion:
        return 'Habitación';
      case RoomType.hallDeAlcobas:
        return 'Hall de alcobas';
      case RoomType.hallDeEntrada:
        return 'Hall de entrada';
      case RoomType.jardin:
        return 'Jardín';
      case RoomType.lavanderia:
        return 'Lavandería';
      case RoomType.linderos:
        return 'Linderos';
      case RoomType.living:
        return 'Living';
      case RoomType.local:
        return 'Local';
      case RoomType.medidores:
        return 'Medidores';
      case RoomType.mezzanine:
        return 'Mezzanine';
      case RoomType.oficina:
        return 'Oficina';
      case RoomType.parqueadero:
        return 'Parqueadero';
      case RoomType.pasillo:
        return 'Pasillo';
      case RoomType.patio:
        return 'Patio';
      case RoomType.recepcion:
        return 'Recepción';
      case RoomType.recibidor:
        return 'Recibidor';
      case RoomType.sala:
        return 'Sala';
      case RoomType.salaAuxiliar:
        return 'Sala auxiliar';
      case RoomType.salaComedor:
        return 'Sala comedor';
      case RoomType.salaDeTV:
        return 'Sala de TV';
      case RoomType.salaDeEstar:
        return 'Sala de estar';
      case RoomType.salaDeJuntas:
        return 'Sala de juntas';
      case RoomType.salon:
        return 'Salón';
      case RoomType.serviciosPublicos:
        return 'Servicios públicos';
      case RoomType.sotano:
        return 'Sótano';
      case RoomType.terraza:
        return 'Terraza';
      case RoomType.vestier:
        return 'Vestier';
      case RoomType.walkInCloset:
        return 'Walk-in closet';
      case RoomType.zonaBBQ:
        return 'Zona BBQ';
      case RoomType.zonaDeOficios:
        return 'Zona de oficios';
      case RoomType.zonaDeRopas:
        return 'Zona de ropas';
      case RoomType.otro:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case RoomType.alcoba:
        return '🛏️';
      case RoomType.alcobaAuxiliar:
        return '🛏️';
      case RoomType.antejardin:
        return '🌱';
      case RoomType.areaDeServicio:
        return '🧹';
      case RoomType.atico:
        return '🏠';
      case RoomType.balcon:
        return '🌇';
      case RoomType.bano:
        return '🚿';
      case RoomType.biblioteca:
        return '📚';
      case RoomType.bodega:
        return '📦';
      case RoomType.closetAbierto:
        return '👔';
      case RoomType.cochera:
        return '🚗';
      case RoomType.cocina:
        return '🍳';
      case RoomType.cocinaAmericana:
        return '🍳';
      case RoomType.cocineta:
        return '🍳';
      case RoomType.cocinaZonaOficios:
        return '🍳';
      case RoomType.comedor:
        return '🍽️';
      case RoomType.contadores:
        return '🔢';
      case RoomType.corredor:
        return '🚶';
      case RoomType.cuartoDeServicio:
        return '🧹';
      case RoomType.cuartoUtil:
        return '🔧';
      case RoomType.cubierta:
        return '🏠';
      case RoomType.deposito:
        return '📦';
      case RoomType.despacho:
        return '💼';
      case RoomType.dormitorio:
        return '🛏️';
      case RoomType.entrada:
        return '🚪';
      case RoomType.entresuelo:
        return '🏠';
      case RoomType.escaleras:
        return '🪜';
      case RoomType.estacionamiento:
        return '🅿️';
      case RoomType.estudio:
        return '📚';
      case RoomType.fachada:
        return '🏛️';
      case RoomType.garaje:
        return '🚗';
      case RoomType.gradas:
        return '🪜';
      case RoomType.habitacion:
        return '🛏️';
      case RoomType.hallDeAlcobas:
        return '🚪';
      case RoomType.hallDeEntrada:
        return '🚪';
      case RoomType.jardin:
        return '🌿';
      case RoomType.lavanderia:
        return '🧺';
      case RoomType.linderos:
        return '🌳';
      case RoomType.living:
        return '🛋️';
      case RoomType.local:
        return '🏪';
      case RoomType.medidores:
        return '⚡';
      case RoomType.mezzanine:
        return '🏠';
      case RoomType.oficina:
        return '💼';
      case RoomType.parqueadero:
        return '🅿️';
      case RoomType.pasillo:
        return '🚶';
      case RoomType.patio:
        return '🏡';
      case RoomType.recepcion:
        return '🏢';
      case RoomType.recibidor:
        return '🚪';
      case RoomType.sala:
        return '🛋️';
      case RoomType.salaAuxiliar:
        return '🛋️';
      case RoomType.salaComedor:
        return '🍽️';
      case RoomType.salaDeTV:
        return '📺';
      case RoomType.salaDeEstar:
        return '🛋️';
      case RoomType.salaDeJuntas:
        return '🏢';
      case RoomType.salon:
        return '🏢';
      case RoomType.serviciosPublicos:
        return '⚙️';
      case RoomType.sotano:
        return '⬇️';
      case RoomType.terraza:
        return '🏖️';
      case RoomType.vestier:
        return '👔';
      case RoomType.walkInCloset:
        return '👗';
      case RoomType.zonaBBQ:
        return '🍖';
      case RoomType.zonaDeOficios:
        return '🧹';
      case RoomType.zonaDeRopas:
        return '👕';
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
  String? nivel; // Nivel del espacio (ej: "Nivel 1", "Nivel 2", "Sótano", etc.)
  String? observaciones;
  List<String> problemas; // Lista de problemas detectados
  List<RoomItem> items; // Lista de elementos/items del espacio (del inventario)
  
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
    this.nivel,
    this.observaciones,
    List<String>? problemas,
    List<RoomItem>? items,
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
        items = items ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Área calculada (ancho × largo) - Igual a área de piso
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

  /// Área de piso (ancho × largo) - Útil para calcular materiales de piso
  double? get areaPiso {
    if (ancho != null && largo != null) {
      return ancho! * largo!;
    }
    return null;
  }

  /// Área de paredes y techo (2 paredes anchas + 2 paredes largas + techo)
  /// Útil para calcular pintura o revestimientos
  /// Fórmula: 2(ancho × altura) + 2(largo × altura) + (ancho × largo)
  double? get areaParedes {
    if (ancho != null && largo != null && altura != null) {
      // Dos paredes anchas
      final paredAncha = 2 * (ancho! * altura!);
      // Dos paredes largas
      final paredLarga = 2 * (largo! * altura!);
      // Techo
      final techo = ancho! * largo!;
      
      return paredAncha + paredLarga + techo;
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
      'nivel': nivel,
      'observaciones': observaciones,
      'problemas': problemas,
      'items': items.map((item) => item.toMap()).toList(),
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
      nivel: map['nivel'],
      observaciones: map['observaciones'],
      problemas: List<String>.from(map['problemas'] ?? []),
      items: (map['items'] as List?)
          ?.map((itemMap) => RoomItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
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
    String? nivel,
    String? observaciones,
    List<String>? problemas,
    List<RoomItem>? items,
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
      nivel: nivel ?? this.nivel,
      observaciones: observaciones ?? this.observaciones,
      problemas: problemas ?? this.problemas,
      items: items ?? this.items,
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
