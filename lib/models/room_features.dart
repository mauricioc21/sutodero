/// Tipos de pisos/suelos
enum FloorType {
  ceramica,
  porcelanato,
  madera,
  laminado,
  marmol,
  granito,
  vinilo,
  alfombra,
  cemento,
  otro,
}

extension FloorTypeExtension on FloorType {
  String get displayName {
    switch (this) {
      case FloorType.ceramica:
        return 'Cerámica';
      case FloorType.porcelanato:
        return 'Porcelanato';
      case FloorType.madera:
        return 'Madera';
      case FloorType.laminado:
        return 'Laminado';
      case FloorType.marmol:
        return 'Mármol';
      case FloorType.granito:
        return 'Granito';
      case FloorType.vinilo:
        return 'Vinilo';
      case FloorType.alfombra:
        return 'Alfombra';
      case FloorType.cemento:
        return 'Cemento Pulido';
      case FloorType.otro:
        return 'Otro';
    }
  }
}

/// Tipos de cocina
enum KitchenType {
  integral,
  modular,
  personalizada,
  basica,
  americana,
  isla,
  peninsula,
  lineal,
  enL,
  enU,
}

extension KitchenTypeExtension on KitchenType {
  String get displayName {
    switch (this) {
      case KitchenType.integral:
        return 'Integral';
      case KitchenType.modular:
        return 'Modular';
      case KitchenType.personalizada:
        return 'Personalizada';
      case KitchenType.basica:
        return 'Básica';
      case KitchenType.americana:
        return 'Americana/Abierta';
      case KitchenType.isla:
        return 'Con Isla';
      case KitchenType.peninsula:
        return 'Con Península';
      case KitchenType.lineal:
        return 'Lineal';
      case KitchenType.enL:
        return 'En L';
      case KitchenType.enU:
        return 'En U';
    }
  }
}

/// Material de mesón/encimera
enum CountertopMaterial {
  granito,
  cuarzo,
  marmol,
  formica,
  aceroInoxidable,
  madera,
  concreto,
  porcelanato,
  otro,
}

extension CountertopMaterialExtension on CountertopMaterial {
  String get displayName {
    switch (this) {
      case CountertopMaterial.granito:
        return 'Granito';
      case CountertopMaterial.cuarzo:
        return 'Cuarzo';
      case CountertopMaterial.marmol:
        return 'Mármol';
      case CountertopMaterial.formica:
        return 'Fórmica';
      case CountertopMaterial.aceroInoxidable:
        return 'Acero Inoxidable';
      case CountertopMaterial.madera:
        return 'Madera';
      case CountertopMaterial.concreto:
        return 'Concreto';
      case CountertopMaterial.porcelanato:
        return 'Porcelanato';
      case CountertopMaterial.otro:
        return 'Otro';
    }
  }
}

/// Tipos de baño
enum BathroomType {
  completo,
  social,
  privado,
  auxiliar,
  jacuzzi,
  turco,
  enSuite,
  medioBano,
}

extension BathroomTypeExtension on BathroomType {
  String get displayName {
    switch (this) {
      case BathroomType.completo:
        return 'Baño Completo';
      case BathroomType.social:
        return 'Baño Social';
      case BathroomType.privado:
        return 'Baño Privado';
      case BathroomType.auxiliar:
        return 'Baño Auxiliar';
      case BathroomType.jacuzzi:
        return 'Con Jacuzzi';
      case BathroomType.turco:
        return 'Turco/Sauna';
      case BathroomType.enSuite:
        return 'En Suite';
      case BathroomType.medioBano:
        return 'Medio Baño';
    }
  }
}

/// Acabados de baño
enum BathroomFinish {
  ceramica,
  porcelanato,
  marmol,
  granito,
  enchape,
  pintura,
  otro,
}

extension BathroomFinishExtension on BathroomFinish {
  String get displayName {
    switch (this) {
      case BathroomFinish.ceramica:
        return 'Cerámica';
      case BathroomFinish.porcelanato:
        return 'Porcelanato';
      case BathroomFinish.marmol:
        return 'Mármol';
      case BathroomFinish.granito:
        return 'Granito';
      case BathroomFinish.enchape:
        return 'Enchape';
      case BathroomFinish.pintura:
        return 'Pintura';
      case BathroomFinish.otro:
        return 'Otro';
    }
  }
}

/// Tipo de closet
enum ClosetType {
  empotrado,
  vestier,
  abierto,
  modular,
  personalizado,
  sinCloset,
}

extension ClosetTypeExtension on ClosetType {
  String get displayName {
    switch (this) {
      case ClosetType.empotrado:
        return 'Empotrado';
      case ClosetType.vestier:
        return 'Vestier/Walk-in';
      case ClosetType.abierto:
        return 'Abierto';
      case ClosetType.modular:
        return 'Modular';
      case ClosetType.personalizado:
        return 'Personalizado';
      case ClosetType.sinCloset:
        return 'Sin Closet';
    }
  }
}

/// Vista/Orientación
enum ViewType {
  ciudad,
  montanas,
  mar,
  parque,
  calle,
  interior,
  piscina,
  jardin,
}

extension ViewTypeExtension on ViewType {
  String get displayName {
    switch (this) {
      case ViewType.ciudad:
        return 'Vista a la Ciudad';
      case ViewType.montanas:
        return 'Vista a Montañas';
      case ViewType.mar:
        return 'Vista al Mar';
      case ViewType.parque:
        return 'Vista a Parque';
      case ViewType.calle:
        return 'Vista a la Calle';
      case ViewType.interior:
        return 'Vista Interior';
      case ViewType.piscina:
        return 'Vista a Piscina';
      case ViewType.jardin:
        return 'Vista a Jardín';
    }
  }
}

/// Iluminación natural
enum NaturalLighting {
  excelente,
  buena,
  regular,
  poca,
  ninguna,
}

extension NaturalLightingExtension on NaturalLighting {
  String get displayName {
    switch (this) {
      case NaturalLighting.excelente:
        return 'Excelente';
      case NaturalLighting.buena:
        return 'Buena';
      case NaturalLighting.regular:
        return 'Regular';
      case NaturalLighting.poca:
        return 'Poca';
      case NaturalLighting.ninguna:
        return 'Ninguna';
    }
  }
}
