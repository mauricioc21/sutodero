import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_photo_360.dart';

/// Servicio para gestionar fotos 360° guardadas temporalmente
/// Estas fotos están listas para ser usadas en tours virtuales
class SavedPhotos360Service {
  static const String _collectionName = 'saved_photos_360';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Guardar una foto 360°
  Future<SavedPhoto360> savePhoto({
    required String userId,
    required String propertyId,
    required String photoUrl,
    String? description,
  }) async {
    final id = _uuid.v4();
    final photo = SavedPhoto360(
      id: id,
      userId: userId,
      propertyId: propertyId,
      photoUrl: photoUrl,
      savedAt: DateTime.now(),
      description: description,
    );

    await _firestore
        .collection(_collectionName)
        .doc(id)
        .set(photo.toMap());

    return photo;
  }

  /// Guardar múltiples fotos 360°
  Future<List<SavedPhoto360>> saveMultiplePhotos({
    required String userId,
    required String propertyId,
    required List<String> photoUrls,
  }) async {
    final savedPhotos = <SavedPhoto360>[];

    for (final photoUrl in photoUrls) {
      final photo = await savePhoto(
        userId: userId,
        propertyId: propertyId,
        photoUrl: photoUrl,
      );
      savedPhotos.add(photo);
    }

    return savedPhotos;
  }

  /// Obtener fotos guardadas de una propiedad
  Future<List<SavedPhoto360>> getSavedPhotosByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('property_id', isEqualTo: propertyId)
        .orderBy('saved_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SavedPhoto360.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Eliminar una foto guardada
  Future<void> deletePhoto(String photoId) async {
    await _firestore
        .collection(_collectionName)
        .doc(photoId)
        .delete();
  }

  /// Eliminar múltiples fotos guardadas
  Future<void> deleteMultiplePhotos(List<String> photoIds) async {
    final batch = _firestore.batch();

    for (final photoId in photoIds) {
      batch.delete(
        _firestore.collection(_collectionName).doc(photoId)
      );
    }

    await batch.commit();
  }

  /// Eliminar todas las fotos de una propiedad
  Future<void> deletePhotosByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('property_id', isEqualTo: propertyId)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Verificar si una propiedad tiene fotos guardadas
  Future<bool> hasPhotos(String propertyId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('property_id', isEqualTo: propertyId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Contar fotos guardadas de una propiedad
  Future<int> countPhotosByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('property_id', isEqualTo: propertyId)
        .get();

    return snapshot.docs.length;
  }

  /// Stream de fotos guardadas por propiedad
  Stream<List<SavedPhoto360>> watchSavedPhotosByProperty(String propertyId) {
    return _firestore
        .collection(_collectionName)
        .where('property_id', isEqualTo: propertyId)
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedPhoto360.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
