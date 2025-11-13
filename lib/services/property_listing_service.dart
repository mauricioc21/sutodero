import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/property_listing.dart';

/// Servicio para gestionar las captaciones de inmuebles
class PropertyListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'property_listings';

  /// Obtiene todas las captaciones de inmuebles
  /// Si userId está especificado y no es admin, filtra por usuario
  Future<List<PropertyListing>> getAllListings({
    String? userId,
    bool isAdmin = false,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Si no es admin y se especifica userId, filtrar por usuario
      if (!isAdmin && userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query
          .where('activo', isEqualTo: true)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PropertyListing.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting property listings: $e');
      }
      return [];
    }
  }

  /// Obtiene una captación específica por ID
  Future<PropertyListing?> getListing(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) return null;

      return PropertyListing.fromMap(doc.data()!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting listing: $e');
      }
      return null;
    }
  }

  /// Crea una nueva captación de inmueble
  Future<PropertyListing> createListing(PropertyListing listing) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newListing = listing.copyWith(
        id: docRef.id,
        fechaCreacion: DateTime.now(),
      );

      await docRef.set(newListing.toMap());

      if (kDebugMode) {
        debugPrint('Property listing created: ${newListing.id}');
      }

      return newListing;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating property listing: $e');
      }
      rethrow;
    }
  }

  /// Actualiza una captación existente
  Future<void> updateListing(PropertyListing listing) async {
    try {
      final updatedListing = listing.copyWith(
        fechaActualizacion: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(listing.id)
          .update(updatedListing.toMap());

      if (kDebugMode) {
        debugPrint('Property listing updated: ${listing.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating property listing: $e');
      }
      rethrow;
    }
  }

  /// Elimina una captación (marca como inactiva)
  Future<void> deleteListing(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'activo': false,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('Property listing deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting property listing: $e');
      }
      rethrow;
    }
  }

  /// Agrega una foto a la captación
  Future<void> addFoto(String listingId, String fotoUrl) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'fotos': FieldValue.arrayUnion([fotoUrl]),
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding foto: $e');
      }
      rethrow;
    }
  }

  /// Agrega una foto 360° a la captación
  Future<void> addFoto360(String listingId, String foto360Url) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'fotos360': FieldValue.arrayUnion([foto360Url]),
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding foto 360: $e');
      }
      rethrow;
    }
  }

  /// Actualiza el plano 2D
  Future<void> updatePlano2D(String listingId, String plano2DUrl) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'plano2DUrl': plano2DUrl,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating plano 2D: $e');
      }
      rethrow;
    }
  }

  /// Actualiza el plano 3D
  Future<void> updatePlano3D(String listingId, String plano3DUrl) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'plano3DUrl': plano3DUrl,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating plano 3D: $e');
      }
      rethrow;
    }
  }

  /// Asocia un tour virtual a la captación
  Future<void> linkTourVirtual(String listingId, String tourVirtualId) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'tourVirtualId': tourVirtualId,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error linking virtual tour: $e');
      }
      rethrow;
    }
  }

  /// Actualiza el estado de la captación
  Future<void> updateEstado(String listingId, ListingStatus nuevoEstado) async {
    try {
      await _firestore.collection(_collection).doc(listingId).update({
        'estado': nuevoEstado.name,
        'fechaActualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating estado: $e');
      }
      rethrow;
    }
  }

  /// Busca captaciones por texto (dirección, ciudad, barrio, descripción)
  Future<List<PropertyListing>> searchListings({
    required String query,
    String? userId,
    bool isAdmin = false,
  }) async {
    try {
      final allListings = await getAllListings(userId: userId, isAdmin: isAdmin);
      
      final queryLower = query.toLowerCase();
      
      return allListings.where((listing) {
        final direccionMatch = listing.direccion.toLowerCase().contains(queryLower);
        final ciudadMatch = listing.ciudad?.toLowerCase().contains(queryLower) ?? false;
        final barrioMatch = listing.barrio?.toLowerCase().contains(queryLower) ?? false;
        final descripcionMatch = listing.descripcion?.toLowerCase().contains(queryLower) ?? false;
        
        return direccionMatch || ciudadMatch || barrioMatch || descripcionMatch;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching listings: $e');
      }
      return [];
    }
  }

  /// Filtra captaciones por tipo de transacción
  Future<List<PropertyListing>> filterByTransactionType({
    required TransactionType transactionType,
    String? userId,
    bool isAdmin = false,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (!isAdmin && userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query
          .where('activo', isEqualTo: true)
          .where('transaccionTipo', isEqualTo: transactionType.name)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PropertyListing.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error filtering by transaction type: $e');
      }
      return [];
    }
  }

  /// Obtiene estadísticas de captaciones del usuario
  Future<Map<String, int>> getListingStats(String userId) async {
    try {
      final listings = await getAllListings(userId: userId, isAdmin: false);

      return {
        'total': listings.length,
        'activos': listings.where((l) => l.estado == ListingStatus.activo).length,
        'enNegociacion': listings.where((l) => l.estado == ListingStatus.enNegociacion).length,
        'vendidos': listings.where((l) => l.estado == ListingStatus.vendido).length,
        'arrendados': listings.where((l) => l.estado == ListingStatus.arrendado).length,
        'conMediaCompleta': listings.where((l) => l.tieneMediaCompleta).length,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting listing stats: $e');
      }
      return {};
    }
  }
}
