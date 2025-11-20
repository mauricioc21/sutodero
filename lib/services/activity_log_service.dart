import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tipos de actividad que se pueden registrar
enum ActivityType {
    login,
    logout,
    createProperty,
    updateProperty,
    deleteProperty,
    createRoom,
    updateRoom,
    deleteRoom,
    createAct,
    updateAct,
    deleteAct,
    uploadPhoto,
    deletePhoto,
    generatePDF,
    createTicket,
    updateTicket,
    deleteTicket,
    scan360Camera,
    createVirtualTour,
    other,
}

/// Servicio para registrar actividades de usuarios en la app
/// Permite auditoría completa de todas las acciones realizadas
class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _enabled = true;

  /// Registrar actividad del usuario
  Future<void> logActivity({
    required String userId,
    required ActivityType type,
    required String action,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_enabled) return;

    try {
      final logData = {
        'userId': userId,
        'type': type.name,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'timestampLocal': DateTime.now().toIso8601String(),
        if (entityId != null) 'entityId': entityId,
        if (entityType != null) 'entityType': entityType,
        if (metadata != null) 'metadata': metadata,
      };

      await _firestore.collection('activity_logs').add(logData);

      if (kDebugMode) {
        debugPrint('📝 Activity logged: ${type.name} - $action');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error logging activity: $e');
      }
      // No lanzar excepción para no interrumpir la app
    }
  }

  /// Registrar login
  Future<void> logLogin(String userId, String email) async {
    await logActivity(
      userId: userId,
      type: ActivityType.login,
      action: 'Usuario inició sesión',
      metadata: {'email': email},
    );
  }

  /// Registrar logout
  Future<void> logLogout(String userId) async {
    await logActivity(
      userId: userId,
      type: ActivityType.logout,
      action: 'Usuario cerró sesión',
    );
  }

  /// Registrar creación de propiedad
  Future<void> logCreateProperty(String userId, String propertyId, String address) async {
    await logActivity(
      userId: userId,
      type: ActivityType.createProperty,
      action: 'Creó propiedad: $address',
      entityId: propertyId,
      entityType: 'property',
      metadata: {'address': address},
    );
  }

  /// Registrar actualización de propiedad
  Future<void> logUpdateProperty(String userId, String propertyId, String address) async {
    await logActivity(
      userId: userId,
      type: ActivityType.updateProperty,
      action: 'Actualizó propiedad: $address',
      entityId: propertyId,
      entityType: 'property',
      metadata: {'address': address},
    );
  }

  /// Registrar eliminación de propiedad
  Future<void> logDeleteProperty(String userId, String propertyId) async {
    await logActivity(
      userId: userId,
      type: ActivityType.deleteProperty,
      action: 'Eliminó propiedad',
      entityId: propertyId,
      entityType: 'property',
    );
  }

  /// Registrar creación de espacio/habitación
  Future<void> logCreateRoom(String userId, String propertyId, String roomId, String roomName) async {
    await logActivity(
      userId: userId,
      type: ActivityType.createRoom,
      action: 'Creó espacio: $roomName',
      entityId: roomId,
      entityType: 'room',
      metadata: {'propertyId': propertyId, 'roomName': roomName},
    );
  }

  /// Registrar actualización de espacio/habitación
  Future<void> logUpdateRoom(String userId, String propertyId, String roomId, String roomName) async {
    await logActivity(
      userId: userId,
      type: ActivityType.updateRoom,
      action: 'Actualizó espacio: $roomName',
      entityId: roomId,
      entityType: 'room',
      metadata: {'propertyId': propertyId, 'roomName': roomName},
    );
  }

  /// Registrar eliminación de espacio/habitación
  Future<void> logDeleteRoom(String userId, String propertyId, String roomId) async {
    await logActivity(
      userId: userId,
      type: ActivityType.deleteRoom,
      action: 'Eliminó espacio',
      entityId: roomId,
      entityType: 'room',
      metadata: {'propertyId': propertyId},
    );
  }

  /// Registrar creación de acta
  Future<void> logCreateAct(String userId, String actId, String propertyAddress) async {
    await logActivity(
      userId: userId,
      type: ActivityType.createAct,
      action: 'Creó acta de inventario para: $propertyAddress',
      entityId: actId,
      entityType: 'act',
      metadata: {'propertyAddress': propertyAddress},
    );
  }

  /// Registrar subida de foto (versión con contexto)
  Future<void> logUploadPhotoWithContext(String userId, String photoUrl, String context) async {
    await logActivity(
      userId: userId,
      type: ActivityType.uploadPhoto,
      action: 'Subió foto: $context',
      metadata: {'photoUrl': photoUrl, 'context': context},
    );
  }

  /// Registrar subida de foto (versión con entidad)
  Future<void> logUploadPhoto(
    String userId, {
    String? entityId,
    String? entityType,
    String? photoUrl,
  }) async {
    await logActivity(
      userId: userId,
      type: ActivityType.uploadPhoto,
      action: 'Subió foto ${entityType != null ? "a $entityType" : ""}',
      entityId: entityId,
      entityType: entityType,
      metadata: {'photoUrl': photoUrl},
    );
  }

  /// Registrar generación de PDF
  Future<void> logGeneratePDF(String userId, String actId, String filename) async {
    await logActivity(
      userId: userId,
      type: ActivityType.generatePDF,
      action: 'Generó PDF de acta',
      entityId: actId,
      entityType: 'act',
      metadata: {'filename': filename},
    );
  }

  /// Registrar creación de ticket
  Future<void> logCreateTicket(String userId, String ticketId, String title) async {
    await logActivity(
      userId: userId,
      type: ActivityType.createTicket,
      action: 'Creó ticket: $title',
      entityId: ticketId,
      entityType: 'ticket',
      metadata: {'title': title},
    );
  }

  /// Registrar escaneo de cámara 360°
  Future<void> logScan360Camera(String userId, int camerasFound) async {
    await logActivity(
      userId: userId,
      type: ActivityType.scan360Camera,
      action: 'Escaneó cámaras 360° Bluetooth',
      metadata: {'camerasFound': camerasFound},
    );
  }

  /// Registrar creación de tour virtual
  Future<void> logCreateVirtualTour(String userId, String propertyId, int photosCount) async {
    await logActivity(
      userId: userId,
      type: ActivityType.createVirtualTour,
      action: 'Creó tour virtual 360°',
      entityId: propertyId,
      entityType: 'property',
      metadata: {'photosCount': photosCount},
    );
  }

  /// Obtener actividades recientes de un usuario
  Future<List<Map<String, dynamic>>> getUserActivities(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user activities: $e');
      }
      return [];
    }
  }

  /// Obtener estadísticas de actividad
  Future<Map<String, int>> getActivityStats(String userId) async {
    try {
      final activities = await getUserActivities(userId, limit: 1000);
      
      final stats = <String, int>{};
      for (final activity in activities) {
        final type = activity['type'] as String? ?? 'other';
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error calculating activity stats: $e');
      }
      return {};
    }
  }

  /// Habilitar/deshabilitar logging
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (kDebugMode) {
      debugPrint('📝 Activity logging ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// Limpiar logs antiguos (más de 90 días)
  Future<void> cleanOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('timestampLocal', isLessThan: cutoffDate.toIso8601String())
          .get();

      // Eliminar en batch
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      if (kDebugMode) {
        debugPrint('🗑️ Cleaned ${snapshot.docs.length} old activity logs');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cleaning old logs: $e');
      }
    }
  }
}
