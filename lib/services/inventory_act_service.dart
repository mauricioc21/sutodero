import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/inventory_act.dart';
import '../models/inventory_property.dart';

/// Servicio para gestionar Actas de Inventario
class InventoryActService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _boxName = 'inventory_acts';
  static const String _collectionName = 'inventory_acts';

  /// Obtiene el box de Hive para actas
  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  /// Crea una nueva acta de inventario
  Future<InventoryAct> createAct({
    required String propertyId,
    required String propertyAddress,
    required String propertyType,
    String? propertyDescription,
    required String clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientIdNumber,
    String? observations,
    List<String>? roomIds,
    List<String>? photoUrls,
    required String createdBy,
    String? createdByName,
    String? createdByRole,
  }) async {
    final actId = _firestore.collection(_collectionName).doc().id;
    
    final act = InventoryAct(
      id: actId,
      propertyId: propertyId,
      propertyAddress: propertyAddress,
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == propertyType,
        orElse: () => PropertyType.casa,
      ),
      propertyDescription: propertyDescription,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientIdNumber: clientIdNumber,
      observations: observations,
      roomIds: roomIds,
      photoUrls: photoUrls,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByRole: createdByRole,
      validationCode: InventoryAct.generateValidationCode(),
    );

    // Guardar en Firestore
    await _firestore.collection(_collectionName).doc(actId).set(act.toMap());

    // Guardar en Hive (cache local)
    final box = await _getBox();
    await box.put(actId, act.toMap());

    return act;
  }

  /// Sube firma digital a Firebase Storage (compatible con Web)
  Future<String> uploadSignature(String actId, Uint8List signatureBytes) async {
    final ref = _storage.ref().child('inventory_acts/$actId/signature.png');
    final uploadTask = await ref.putData(signatureBytes, SettableMetadata(contentType: 'image/png'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Sube foto de reconocimiento facial a Firebase Storage (compatible con Web)
  Future<String> uploadFacialRecognition(String actId, Uint8List facialBytes) async {
    final ref = _storage.ref().child('inventory_acts/$actId/facial_recognition.jpg');
    final uploadTask = await ref.putData(facialBytes, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Sube PDF generado a Firebase Storage (compatible con Web)
  Future<String> uploadPdf(String actId, Uint8List pdfBytes) async {
    final ref = _storage.ref().child('inventory_acts/$actId/acta_${actId}.pdf');
    final uploadTask = await ref.putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// Actualiza URLs de autenticación (firma + facial)
  Future<void> updateAuthentication({
    required String actId,
    String? signatureUrl,
    String? facialUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (signatureUrl != null) {
      updates['digitalSignatureUrl'] = signatureUrl;
    }

    if (facialUrl != null) {
      updates['facialRecognitionUrl'] = facialUrl;
    }

    // Actualizar en Firestore
    await _firestore.collection(_collectionName).doc(actId).update(updates);

    // Actualizar en Hive
    final box = await _getBox();
    final actData = box.get(actId);
    if (actData != null) {
      final updatedData = Map<String, dynamic>.from(actData);
      updatedData.addAll(updates);
      await box.put(actId, updatedData);
    }
  }

  /// Completa el acta (marca como firmada y autenticada)
  Future<InventoryAct> completeAct(String actId) async {
    final act = await getAct(actId);
    if (act == null) {
      throw Exception('Acta no encontrada');
    }

    final completedAct = act.complete();

    // Actualizar en Firestore
    await _firestore.collection(_collectionName).doc(actId).update({
      'isCompleted': true,
      'signatureTimestamp': Timestamp.fromDate(completedAct.signatureTimestamp!),
      'authenticationHash': completedAct.authenticationHash,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Actualizar en Hive
    final box = await _getBox();
    await box.put(actId, completedAct.toMap());

    return completedAct;
  }

  /// Actualiza URL del PDF generado
  Future<void> updatePdfUrl(String actId, String pdfUrl) async {
    await _firestore.collection(_collectionName).doc(actId).update({
      'pdfUrl': pdfUrl,
      'isPdfGenerated': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final box = await _getBox();
    final actData = box.get(actId);
    if (actData != null) {
      final updatedData = Map<String, dynamic>.from(actData);
      updatedData['pdfUrl'] = pdfUrl;
      updatedData['isPdfGenerated'] = true;
      updatedData['updatedAt'] = DateTime.now().toIso8601String();
      await box.put(actId, updatedData);
    }
  }

  /// Obtiene una acta por ID
  Future<InventoryAct?> getAct(String actId) async {
    // Intentar desde Hive primero
    final box = await _getBox();
    final localData = box.get(actId);
    
    if (localData != null) {
      return InventoryAct.fromMap(Map<String, dynamic>.from(localData));
    }

    // Si no está en cache, buscar en Firestore
    final doc = await _firestore.collection(_collectionName).doc(actId).get();
    
    if (!doc.exists) return null;

    final act = InventoryAct.fromMap(doc.data()!);
    
    // Guardar en cache
    await box.put(actId, act.toMap());
    
    return act;
  }

  /// Obtiene todas las actas de una propiedad
  Future<List<InventoryAct>> getActsByProperty(String propertyId) async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => InventoryAct.fromMap(doc.data()))
        .toList();
  }

  /// Obtiene todas las actas
  Future<List<InventoryAct>> getAllActs() async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => InventoryAct.fromMap(doc.data()))
        .toList();
  }

  /// Obtiene actas completadas
  Future<List<InventoryAct>> getCompletedActs() async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('isCompleted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => InventoryAct.fromMap(doc.data()))
        .toList();
  }

  /// Obtiene actas pendientes (sin completar)
  Future<List<InventoryAct>> getPendingActs() async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => InventoryAct.fromMap(doc.data()))
        .toList();
  }

  /// Elimina una acta
  Future<void> deleteAct(String actId) async {
    // Eliminar archivos de Storage
    try {
      await _storage.ref().child('inventory_acts/$actId').listAll().then((result) async {
        for (var item in result.items) {
          await item.delete();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error eliminando archivos de Storage: $e');
      }
    }

    // Eliminar de Firestore
    await _firestore.collection(_collectionName).doc(actId).delete();

    // Eliminar de Hive
    final box = await _getBox();
    await box.delete(actId);
  }

  /// Busca actas por código de validación
  Future<InventoryAct?> getActByValidationCode(String validationCode) async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('validationCode', isEqualTo: validationCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return InventoryAct.fromMap(querySnapshot.docs.first.data());
  }

  /// Verifica autenticidad de un acta mediante su hash
  Future<bool> verifyActAuthenticity(String actId, String providedHash) async {
    final act = await getAct(actId);
    if (act == null) return false;
    
    return act.authenticationHash == providedHash;
  }
}
