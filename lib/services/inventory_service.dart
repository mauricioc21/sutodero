import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_property.dart';
import '../models/property_room.dart';
import 'activity_log_service.dart';

/// Servicio para gestionar inventarios de propiedades en Firestore
/// Datos organizados por usuario: users/{userId}/properties/{propertyId}
class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityLogService _activityLog = ActivityLogService();
  final Uuid _uuid = const Uuid();
  
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  /// Inicializa el servicio (mantiene compatibilidad con versión Hive)
  Future<void> init() async {
    // No requiere inicialización para Firestore
    if (kDebugMode) {
      debugPrint('✅ InventoryService inicializado (Firestore)');
    }
  }

  /// Referencia a la colección de propiedades de un usuario
  CollectionReference _propertiesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('properties');
  }

  /// Referencia a la colección de espacios de una propiedad
  CollectionReference _roomsCollection(String userId, String propertyId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('properties')
        .doc(propertyId)
        .collection('rooms');
  }

  /// Obtiene todas las propiedades de un usuario
  Future<List<InventoryProperty>> getAllProperties(String userId) async {
    try {
      final snapshot = await _propertiesCollection(userId)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InventoryProperty.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo propiedades: $e');
      }
      return [];
    }
  }

  /// Obtiene una propiedad por ID
  Future<InventoryProperty?> getProperty(String userId, String propertyId) async {
    try {
      final doc = await _propertiesCollection(userId).doc(propertyId).get();
      
      if (!doc.exists) return null;

      return InventoryProperty.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo propiedad: $e');
      }
      return null;
    }
  }

  /// Guarda una propiedad (crear o actualizar)
  Future<void> saveProperty(String userId, InventoryProperty property) async {
    try {
      property.fechaActualizacion = DateTime.now();
      
      await _propertiesCollection(userId).doc(property.id).set(
            property.toMap(),
            SetOptions(merge: true),
          );

      if (kDebugMode) {
        debugPrint('✅ Propiedad guardada: ${property.direccion}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error guardando propiedad: $e');
      }
      rethrow;
    }
  }

  /// Crea una nueva propiedad
  Future<InventoryProperty> createProperty({
    required String userId,
    required String direccion,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    PropertyType tipo = PropertyType.casa,
    String? descripcion,
    double? area,
    int? numeroHabitaciones,
    int? numeroBanos,
  }) async {
    final property = InventoryProperty(
      id: _uuid.v4(),
      userId: userId,
      direccion: direccion,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      tipo: tipo,
      descripcion: descripcion,
      area: area,
      numeroHabitaciones: numeroHabitaciones,
      numeroBanos: numeroBanos,
    );

    await saveProperty(userId, property);

    // Registrar actividad
    _activityLog.logCreateProperty(userId, property.id, direccion);

    return property;
  }

  /// Actualiza una propiedad
  Future<void> updateProperty(String userId, InventoryProperty property) async {
    property.fechaActualizacion = DateTime.now();
    await saveProperty(userId, property);

    // Registrar actividad
    _activityLog.logUpdateProperty(userId, property.id, property.direccion);
  }

  /// Elimina una propiedad y todos sus espacios
  Future<void> deleteProperty(String userId, String propertyId) async {
    try {
      // Eliminar todos los espacios de la propiedad
      final roomsSnapshot = await _roomsCollection(userId, propertyId).get();
      final batch = _firestore.batch();

      for (final doc in roomsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar la propiedad
      batch.delete(_propertiesCollection(userId).doc(propertyId));

      await batch.commit();

      // Registrar actividad
      _activityLog.logDeleteProperty(userId, propertyId);

      if (kDebugMode) {
        debugPrint('✅ Propiedad eliminada: $propertyId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando propiedad: $e');
      }
      rethrow;
    }
  }

  /// Obtiene todos los espacios de una propiedad
  Future<List<PropertyRoom>> getRoomsByProperty(String userId, String propertyId) async {
    try {
      final snapshot = await _roomsCollection(userId, propertyId)
          .orderBy('fechaCreacion')
          .get();

      return snapshot.docs
          .map((doc) => PropertyRoom.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo espacios: $e');
      }
      return [];
    }
  }

  /// Obtiene un espacio por ID
  Future<PropertyRoom?> getRoom(String userId, String propertyId, String roomId) async {
    try {
      final doc = await _roomsCollection(userId, propertyId).doc(roomId).get();
      
      if (!doc.exists) return null;

      return PropertyRoom.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo espacio: $e');
      }
      return null;
    }
  }

  /// Guarda un espacio (crear o actualizar)
  Future<void> saveRoom(String userId, String propertyId, PropertyRoom room) async {
    try {
      room.fechaActualizacion = DateTime.now();
      
      await _roomsCollection(userId, propertyId).doc(room.id).set(
            room.toMap(),
            SetOptions(merge: true),
          );

      if (kDebugMode) {
        debugPrint('✅ Espacio guardado: ${room.nombre}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error guardando espacio: $e');
      }
      rethrow;
    }
  }

  /// Crea un nuevo espacio
  Future<PropertyRoom> createRoom({
    required String userId,
    required String propertyId,
    required String nombre,
    RoomType tipo = RoomType.otro,
    SpaceCondition estado = SpaceCondition.bueno,
    String? descripcion,
    double? ancho,
    double? largo,
    double? altura,
  }) async {
    final room = PropertyRoom(
      id: _uuid.v4(),
      propertyId: propertyId,
      nombre: nombre,
      tipo: tipo,
      estado: estado,
      descripcion: descripcion,
      ancho: ancho,
      largo: largo,
      altura: altura,
    );

    await saveRoom(userId, propertyId, room);

    // Registrar actividad
    _activityLog.logCreateRoom(userId, propertyId, room.id, nombre);

    return room;
  }

  /// Actualiza un espacio
  Future<void> updateRoom(String userId, String propertyId, PropertyRoom room) async {
    room.fechaActualizacion = DateTime.now();
    await saveRoom(userId, propertyId, room);

    // Registrar actividad
    _activityLog.logUpdateRoom(userId, propertyId, room.id, room.nombre);
  }

  /// Elimina un espacio
  Future<void> deleteRoom(String userId, String propertyId, String roomId) async {
    try {
      await _roomsCollection(userId, propertyId).doc(roomId).delete();

      // Registrar actividad
      _activityLog.logDeleteRoom(userId, propertyId, roomId);

      if (kDebugMode) {
        debugPrint('✅ Espacio eliminado: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando espacio: $e');
      }
      rethrow;
    }
  }

  /// Agrega una foto a un espacio
  Future<void> addRoomPhoto(String userId, String propertyId, String roomId, String photoUrl) async {
    final room = await getRoom(userId, propertyId, roomId);
    if (room == null) return;

    room.fotos.add(photoUrl);
    await updateRoom(userId, propertyId, room);

    // Registrar actividad
    _activityLog.logUploadPhoto(
      userId,
      entityId: roomId,
      entityType: 'room',
      photoUrl: photoUrl,
    );
  }

  /// Establece la foto 360° de un espacio
  Future<void> setRoom360Photo(String userId, String propertyId, String roomId, String photo360Url) async {
    final room = await getRoom(userId, propertyId, roomId);
    if (room == null) return;

    room.foto360Url = photo360Url;
    await updateRoom(userId, propertyId, room);

    // Registrar actividad
    _activityLog.logUploadPhoto(
      userId,
      entityId: roomId,
      entityType: 'room_360',
      photoUrl: photo360Url,
    );
  }

  /// Agrega un problema a un espacio
  Future<void> addRoomProblem(String userId, String propertyId, String roomId, String problema) async {
    final room = await getRoom(userId, propertyId, roomId);
    if (room == null) return;

    if (!room.problemas.contains(problema)) {
      room.problemas.add(problema);
      await updateRoom(userId, propertyId, room);
    }
  }

  /// Busca propiedades por dirección o cliente
  Future<List<InventoryProperty>> searchProperties(String userId, String query) async {
    try {
      final allProperties = await getAllProperties(userId);
      final queryLower = query.toLowerCase();

      return allProperties.where((property) {
        return property.direccion.toLowerCase().contains(queryLower) ||
            (property.clienteNombre?.toLowerCase().contains(queryLower) ?? false) ||
            (property.descripcion?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error buscando propiedades: $e');
      }
      return [];
    }
  }

  /// Obtiene estadísticas de inventario para un usuario
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      final properties = await getAllProperties(userId);
      final allRooms = <PropertyRoom>[];
      
      for (final property in properties) {
        final rooms = await getRoomsByProperty(userId, property.id);
        allRooms.addAll(rooms);
      }

      return {
        'totalProperties': properties.length,
        'activeProperties': properties.where((p) => p.activa).length,
        'totalRooms': allRooms.length,
        'roomsWith360': allRooms.where((r) => r.tiene360).length,
        'propertiesByType': _countByType(properties),
        'roomsByCondition': _countByCondition(allRooms),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo estadísticas: $e');
      }
      return {
        'totalProperties': 0,
        'activeProperties': 0,
        'totalRooms': 0,
        'roomsWith360': 0,
        'propertiesByType': <String, int>{},
        'roomsByCondition': <String, int>{},
      };
    }
  }

  Map<String, int> _countByType(List<InventoryProperty> properties) {
    final counts = <String, int>{};
    for (final property in properties) {
      final typeName = property.tipo.displayName;
      counts[typeName] = (counts[typeName] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _countByCondition(List<PropertyRoom> rooms) {
    final counts = <String, int>{};
    for (final room in rooms) {
      final conditionName = room.estado.displayName;
      counts[conditionName] = (counts[conditionName] ?? 0) + 1;
    }
    return counts;
  }

  /// Método de compatibilidad - ya no requiere dispose con Firestore
  Future<void> dispose() async {
    // No requiere limpieza con Firestore
    if (kDebugMode) {
      debugPrint('✅ InventoryService disposed (Firestore - no action needed)');
    }
  }
}
