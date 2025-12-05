import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/acta_model.dart';

/// Servicio para gestionar Actas en Firebase
class ActaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'actas';

  /// Crear o actualizar un acta
  Future<ActaModel> guardarActa(ActaModel acta) async {
    try {
      final actaData = acta.copyWith(
        updatedAt: DateTime.now(),
      );

      if (acta.id.isEmpty) {
        // Crear nueva acta
        final docRef = await _firestore.collection(_collectionName).add(
          actaData.toFirestore(),
        );
        
        return actaData.copyWith(id: docRef.id);
      } else {
        // Actualizar acta existente
        await _firestore
            .collection(_collectionName)
            .doc(acta.id)
            .set(actaData.toFirestore(), SetOptions(merge: true));
        
        return actaData;
      }
    } catch (e) {
      throw Exception('Error al guardar acta: $e');
    }
  }

  /// Obtener acta por ID
  Future<ActaModel?> obtenerActa(String actaId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(actaId).get();
      
      if (doc.exists && doc.data() != null) {
        return ActaModel.fromFirestore(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      throw Exception('Error al obtener acta: $e');
    }
  }

  /// Obtener actas de una propiedad
  Future<List<ActaModel>> obtenerActasPorPropiedad(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ActaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener actas: $e');
    }
  }

  /// Obtener última acta de una propiedad por tipo
  Future<ActaModel?> obtenerUltimaActa(String propertyId, String tipoActa) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('propertyId', isEqualTo: propertyId)
          .where('tipoActa', isEqualTo: tipoActa)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ActaModel.fromFirestore(doc.data(), doc.id);
      }
      
      return null;
    } catch (e) {
      // Si falla por falta de índice, intentar sin orderBy
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('propertyId', isEqualTo: propertyId)
            .where('tipoActa', isEqualTo: tipoActa)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Ordenar en memoria
          final docs = querySnapshot.docs.toList();
          docs.sort((a, b) {
            final aDate = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bDate = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
          
          final doc = docs.first;
          return ActaModel.fromFirestore(doc.data(), doc.id);
        }
        
        return null;
      } catch (e2) {
        return null;
      }
    }
  }

  /// Eliminar acta
  Future<void> eliminarActa(String actaId) async {
    try {
      await _firestore.collection(_collectionName).doc(actaId).delete();
    } catch (e) {
      throw Exception('Error al eliminar acta: $e');
    }
  }

  /// Actualizar URL del PDF generado
  Future<void> actualizarPdfUrl(String actaId, String pdfUrl) async {
    try {
      await _firestore.collection(_collectionName).doc(actaId).update({
        'pdfUrl': pdfUrl,
        'pdfGenerado': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar PDF URL: $e');
    }
  }

  /// Actualizar firma
  Future<void> actualizarFirma(String actaId, String tipoFirma, String firmaBase64) async {
    try {
      final field = tipoFirma == 'recibido' ? 'firmaRecibido' : 'firmaEntrega';
      
      await _firestore.collection(_collectionName).doc(actaId).update({
        field: firmaBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar firma: $e');
    }
  }

  /// Subir PDF a Firebase Storage y actualizar URL en Firestore
  Future<String> subirPdf(String actaId, Uint8List pdfBytes, String fileName) async {
    try {
      // Crear referencia en Storage
      final ref = _storage.ref().child('actas/$actaId/$fileName');
      
      // Subir archivo PDF
      final uploadTask = ref.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      
      // Obtener URL pública
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Actualizar Firestore con la URL
      await actualizarPdfUrl(actaId, downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir PDF: $e');
    }
  }

  /// Eliminar PDF de Storage
  Future<void> eliminarPdf(String actaId, String fileName) async {
    try {
      final ref = _storage.ref().child('actas/$actaId/$fileName');
      await ref.delete();
    } catch (e) {
      // Ignorar error si el archivo no existe
      if (kDebugMode) {
        print('Error al eliminar PDF: $e');
      }
    }
  }
}
