import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/virtual_tour_model.dart';

/// Servicio para gestionar tours virtuales 360°
/// Permite crear, listar y gestionar tours con fotos panorámicas
class VirtualTourService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'virtual_tours';

  /// Crear un nuevo tour virtual
  Future<VirtualTourModel> createTour({
    required String propertyId,
    required String propertyName,
    required String propertyAddress,
    required List<String> photo360Urls,
    String description = '',
    int tourOption = 1, // 1 = Pannellum, 2 = PanoramaViewer
  }) async {
    try {
      final tour = VirtualTourModel(
        id: '',
        propertyId: propertyId,
        propertyName: propertyName,
        propertyAddress: propertyAddress,
        photo360Urls: photo360Urls,
        description: description,
        createdAt: DateTime.now(),
        tourOption: tourOption,
      );

      final docRef = await _firestore.collection(_collection).add(tour.toMap());
      
      return tour.copyWith(id: docRef.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al crear tour virtual: $e');
      }
      rethrow;
    }
  }

  /// Obtener tour virtual por ID
  Future<VirtualTourModel?> getTourById(String tourId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tourId).get();
      
      if (!doc.exists) return null;
      
      return VirtualTourModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener tour: $e');
      }
      return null;
    }
  }

  /// Obtener tours de una propiedad
  Future<List<VirtualTourModel>> getToursByProperty(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('property_id', isEqualTo: propertyId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VirtualTourModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener tours de la propiedad: $e');
      }
      return [];
    }
  }

  /// Obtener todos los tours
  Future<List<VirtualTourModel>> getAllTours() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VirtualTourModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener tours: $e');
      }
      return [];
    }
  }

  /// Agregar foto 360° a un tour existente
  Future<void> addPhoto360ToTour(String tourId, String photoUrl) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'photo_360_urls': FieldValue.arrayUnion([photoUrl]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al agregar foto al tour: $e');
      }
      rethrow;
    }
  }

  /// Eliminar foto 360° de un tour
  Future<void> removePhoto360FromTour(String tourId, String photoUrl) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'photo_360_urls': FieldValue.arrayRemove([photoUrl]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al eliminar foto del tour: $e');
      }
      rethrow;
    }
  }

  /// Actualizar descripción del tour
  Future<void> updateTourDescription(String tourId, String description) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'description': description,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al actualizar descripción: $e');
      }
      rethrow;
    }
  }

  /// Eliminar tour
  Future<void> deleteTour(String tourId) async {
    try {
      await _firestore.collection(_collection).doc(tourId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al eliminar tour: $e');
      }
      rethrow;
    }
  }

  /// Stream de tours de una propiedad (actualizaciones en tiempo real)
  Stream<List<VirtualTourModel>> watchToursByProperty(String propertyId) {
    return _firestore
        .collection(_collection)
        .where('property_id', isEqualTo: propertyId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VirtualTourModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
