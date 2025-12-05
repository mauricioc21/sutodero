import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para tours virtuales 360°
class VirtualTourModel {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final List<String> photo360Urls;
  final String description;
  final DateTime createdAt;
  final int tourOption; // 1 = Tour Avanzado (Pannellum), 2 = Tour Simple (PanoramaViewer)

  VirtualTourModel({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.photo360Urls,
    this.description = '',
    required this.createdAt,
    this.tourOption = 1, // Por defecto Opción 1 (Pannellum)
  });

  /// Crear desde Firestore
  factory VirtualTourModel.fromFirestore(Map<String, dynamic> data, String id) {
    return VirtualTourModel(
      id: id,
      propertyId: data['property_id'] as String? ?? '',
      propertyName: data['property_name'] as String? ?? '',
      propertyAddress: data['property_address'] as String? ?? '',
      photo360Urls: List<String>.from(data['photo_360_urls'] as List? ?? []),
      description: data['description'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tourOption: data['tour_option'] as int? ?? 1, // Por defecto Opción 1
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'property_id': propertyId,
      'property_name': propertyName,
      'property_address': propertyAddress,
      'photo_360_urls': photo360Urls,
      'description': description,
      'created_at': Timestamp.fromDate(createdAt),
      'tour_option': tourOption, // 1 = Pannellum, 2 = PanoramaViewer
    };
  }

  /// Crear copia con modificaciones
  VirtualTourModel copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    List<String>? photo360Urls,
    String? description,
    DateTime? createdAt,
    int? tourOption,
  }) {
    return VirtualTourModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      photo360Urls: photo360Urls ?? this.photo360Urls,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      tourOption: tourOption ?? this.tourOption,
    );
  }

  /// Número de fotos en el tour
  int get photoCount => photo360Urls.length;

  /// Verificar si el tour tiene fotos
  bool get hasPhotos => photo360Urls.isNotEmpty;
}
