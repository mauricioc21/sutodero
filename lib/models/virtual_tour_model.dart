import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para hotspot/punto de navegación entre escenas
class TourHotspot {
  final String id;
  final String targetSceneId; // ID de la escena destino
  final double yaw; // Posición horizontal (-180 a 180)
  final double pitch; // Posición vertical (-90 a 90)
  final String? text; // Texto descriptivo
  final String? icon; // Icono del hotspot (ej: 'arrow', 'door', 'info')
  final String? cssClass; // Clase CSS personalizada

  TourHotspot({
    required this.id,
    required this.targetSceneId,
    required this.yaw,
    required this.pitch,
    this.text,
    this.icon = 'arrow',
    this.cssClass,
  });

  factory TourHotspot.fromMap(Map<String, dynamic> map) {
    return TourHotspot(
      id: map['id'] as String? ?? '',
      targetSceneId: map['target_scene_id'] as String? ?? '',
      yaw: (map['yaw'] as num?)?.toDouble() ?? 0.0,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 0.0,
      text: map['text'] as String?,
      icon: map['icon'] as String? ?? 'arrow',
      cssClass: map['css_class'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_scene_id': targetSceneId,
      'yaw': yaw,
      'pitch': pitch,
      'text': text,
      'icon': icon,
      'css_class': cssClass,
    };
  }
}

/// Modelo para una escena individual del tour (una foto 360)
class TourScene {
  final String id;
  final String photoUrl;
  final String title; // Título de la escena (ej: "Sala", "Cocina")
  final String? description;
  final List<TourHotspot> hotspots; // Puntos de navegación a otras escenas
  final double? initialYaw; // Vista inicial horizontal
  final double? initialPitch; // Vista inicial vertical
  final int order; // Orden en el tour

  TourScene({
    required this.id,
    required this.photoUrl,
    required this.title,
    this.description,
    this.hotspots = const [],
    this.initialYaw,
    this.initialPitch,
    this.order = 0,
  });

  factory TourScene.fromMap(Map<String, dynamic> map, String id) {
    return TourScene(
      id: id,
      photoUrl: map['photo_url'] as String? ?? '',
      title: map['title'] as String? ?? 'Sin título',
      description: map['description'] as String?,
      hotspots: (map['hotspots'] as List<dynamic>?)
              ?.map((h) => TourHotspot.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      initialYaw: (map['initial_yaw'] as num?)?.toDouble(),
      initialPitch: (map['initial_pitch'] as num?)?.toDouble(),
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photo_url': photoUrl,
      'title': title,
      'description': description,
      'hotspots': hotspots.map((h) => h.toMap()).toList(),
      'initial_yaw': initialYaw,
      'initial_pitch': initialPitch,
      'order': order,
    };
  }

  TourScene copyWith({
    String? id,
    String? photoUrl,
    String? title,
    String? description,
    List<TourHotspot>? hotspots,
    double? initialYaw,
    double? initialPitch,
    int? order,
  }) {
    return TourScene(
      id: id ?? this.id,
      photoUrl: photoUrl ?? this.photoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      hotspots: hotspots ?? this.hotspots,
      initialYaw: initialYaw ?? this.initialYaw,
      initialPitch: initialPitch ?? this.initialPitch,
      order: order ?? this.order,
    );
  }
}

/// Modelo mejorado para tours virtuales 360° con hotspots
class VirtualTourModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final String userId; // Usuario creador
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int tourOption; // 1 = Tour Avanzado (Pannellum), 2 = Tour Simple (PanoramaViewer)
  final String? firstSceneId; // ID de la escena inicial
  final List<TourScene> scenes; // Escenas del tour
  
  // Campos legacy para compatibilidad con tours antiguos
  @Deprecated('Use scenes instead')
  final List<String> photo360Urls;

  VirtualTourModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.userId,
    this.description = '',
    required this.createdAt,
    this.updatedAt,
    this.tourOption = 1,
    this.firstSceneId,
    this.scenes = const [],
    this.photo360Urls = const [], // Legacy
  });

  /// Crear desde Firestore
  factory VirtualTourModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Soporte para scenes nuevas
    final scenesData = data['scenes'] as Map<String, dynamic>?;
    List<TourScene> scenes = [];
    
    if (scenesData != null) {
      scenes = scenesData.entries
          .map((entry) => TourScene.fromMap(entry.value, entry.key))
          .toList();
      // Ordenar por orden
      scenes.sort((a, b) => a.order.compareTo(b.order));
    }

    // Si no hay scenes, crear desde photo360Urls (legacy)
    if (scenes.isEmpty && data['photo_360_urls'] != null) {
      final urls = List<String>.from(data['photo_360_urls'] as List? ?? []);
      scenes = urls.asMap().entries.map((entry) {
        return TourScene(
          id: 'scene_${entry.key}',
          photoUrl: entry.value,
          title: 'Escena ${entry.key + 1}',
          order: entry.key,
        );
      }).toList();
    }

    return VirtualTourModel(
      id: id,
      propertyId: data['property_id'] as String? ?? '',
      propertyName: data['property_name'] as String? ?? '',
      propertyAddress: data['property_address'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      tourOption: data['tour_option'] as int? ?? 1,
      firstSceneId: data['first_scene_id'] as String?,
      scenes: scenes,
      photo360Urls: List<String>.from(data['photo_360_urls'] as List? ?? []),
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    // Convertir scenes a Map
    final scenesMap = <String, dynamic>{};
    for (var scene in scenes) {
      scenesMap[scene.id] = scene.toMap();
    }

    return {
      'property_id': propertyId,
      'property_name': propertyName,
      'property_address': propertyAddress,
      'user_id': userId,
      'description': description,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'tour_option': tourOption,
      'first_scene_id': firstSceneId ?? (scenes.isNotEmpty ? scenes.first.id : null),
      'scenes': scenesMap,
      // Mantener photo360Urls para compatibilidad
      'photo_360_urls': scenes.map((s) => s.photoUrl).toList(),
    };
  }

  /// Crear copia con modificaciones
  VirtualTourModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    String? userId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? tourOption,
    String? firstSceneId,
    List<TourScene>? scenes,
    List<String>? photo360Urls,
  }) {
    return VirtualTourModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tourOption: tourOption ?? this.tourOption,
      firstSceneId: firstSceneId ?? this.firstSceneId,
      scenes: scenes ?? this.scenes,
      photo360Urls: photo360Urls ?? this.photo360Urls,
    );
  }

  /// Número de escenas en el tour
  int get sceneCount => scenes.length;

  /// Número de fotos (legacy - para compatibilidad)
  int get photoCount => scenes.length;

  /// Verificar si el tour tiene escenas
  bool get hasScenes => scenes.isNotEmpty;
  
  /// Verificar si tiene fotos (legacy - para compatibilidad)
  bool get hasPhotos => scenes.isNotEmpty;
  
  /// Obtener escena por ID
  TourScene? getSceneById(String sceneId) {
    try {
      return scenes.firstWhere((s) => s.id == sceneId);
    } catch (_) {
      return null;
    }
  }
  
  /// Obtener primera escena
  TourScene? get firstScene {
    if (firstSceneId != null) {
      return getSceneById(firstSceneId!);
    }
    return scenes.isNotEmpty ? scenes.first : null;
  }
}
