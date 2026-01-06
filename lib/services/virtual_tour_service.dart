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
    required String userId,
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
        userId: userId,
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

  /// Obtener tours de un usuario
  Future<List<VirtualTourModel>> getUserTours(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VirtualTourModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener tours del usuario: $e');
      }
      return [];
    }
  }

  /// Actualizar tour completo
  Future<void> updateTour(VirtualTourModel tour) async {
    try {
      await _firestore.collection(_collection).doc(tour.id).update(tour.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al actualizar tour: $e');
      }
      rethrow;
    }
  }

  /// Crear tour con escenas (nuevo modelo)
  Future<VirtualTourModel> createTourWithScenes({
    required String propertyId,
    required String propertyName,
    required String propertyAddress,
    required String userId,
    required List<TourScene> scenes,
    String description = '',
    int tourOption = 1,
    String? firstSceneId,
  }) async {
    try {
      final tour = VirtualTourModel(
        id: '',
        propertyId: propertyId,
        propertyName: propertyName,
        propertyAddress: propertyAddress,
        userId: userId,
        description: description,
        createdAt: DateTime.now(),
        tourOption: tourOption,
        firstSceneId: firstSceneId ?? (scenes.isNotEmpty ? scenes.first.id : null),
        scenes: scenes,
        photo360Urls: scenes.map((s) => s.photoUrl).toList(), // Legacy
      );

      final docRef = await _firestore.collection(_collection).add(tour.toMap());
      
      return tour.copyWith(id: docRef.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al crear tour con escenas: $e');
      }
      rethrow;
    }
  }

  /// Actualizar una escena específica del tour
  Future<void> updateScene(String tourId, TourScene scene) async {
    try {
      await _firestore.collection(_collection).doc(tourId).update({
        'scenes.${scene.id}': scene.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al actualizar escena: $e');
      }
      rethrow;
    }
  }

  /// Agregar hotspot a una escena
  Future<void> addHotspotToScene(
    String tourId,
    String sceneId,
    TourHotspot hotspot,
  ) async {
    try {
      final tour = await getTourById(tourId);
      if (tour == null) throw Exception('Tour no encontrado');

      final scene = tour.getSceneById(sceneId);
      if (scene == null) throw Exception('Escena no encontrada');

      final updatedHotspots = [...scene.hotspots, hotspot];
      final updatedScene = scene.copyWith(hotspots: updatedHotspots);

      await updateScene(tourId, updatedScene);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al agregar hotspot: $e');
      }
      rethrow;
    }
  }

  /// Eliminar hotspot de una escena
  Future<void> removeHotspotFromScene(
    String tourId,
    String sceneId,
    String hotspotId,
  ) async {
    try {
      final tour = await getTourById(tourId);
      if (tour == null) throw Exception('Tour no encontrado');

      final scene = tour.getSceneById(sceneId);
      if (scene == null) throw Exception('Escena no encontrada');

      final updatedHotspots = scene.hotspots
          .where((h) => h.id != hotspotId)
          .toList();
      final updatedScene = scene.copyWith(hotspots: updatedHotspots);

      await updateScene(tourId, updatedScene);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al eliminar hotspot: $e');
      }
      rethrow;
    }
  }
}
