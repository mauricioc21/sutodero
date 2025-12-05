import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para fotos 360° guardadas temporalmente
/// Estas fotos están esperando ser agregadas a un tour virtual
class SavedPhoto360 {
  final String id;
  final String userId;
  final String propertyId;
  final String photoUrl;
  final DateTime savedAt;
  final String? description;

  SavedPhoto360({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.photoUrl,
    required this.savedAt,
    this.description,
  });

  /// Crear desde Firestore
  factory SavedPhoto360.fromFirestore(Map<String, dynamic> data, String id) {
    return SavedPhoto360(
      id: id,
      userId: data['user_id'] as String? ?? '',
      propertyId: data['property_id'] as String? ?? '',
      photoUrl: data['photo_url'] as String? ?? '',
      savedAt: (data['saved_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'property_id': propertyId,
      'photo_url': photoUrl,
      'saved_at': Timestamp.fromDate(savedAt),
      if (description != null) 'description': description,
    };
  }

  /// Crear copia con modificaciones
  SavedPhoto360 copyWith({
    String? id,
    String? userId,
    String? propertyId,
    String? photoUrl,
    DateTime? savedAt,
    String? description,
  }) {
    return SavedPhoto360(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      photoUrl: photoUrl ?? this.photoUrl,
      savedAt: savedAt ?? this.savedAt,
      description: description ?? this.description,
    );
  }
}
