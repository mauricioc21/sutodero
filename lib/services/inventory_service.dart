import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_property.dart';
import '../models/property_room.dart';

/// Servicio para gestionar inventarios de propiedades
class InventoryService {
  static const String _propertiesBoxName = 'properties';
  static const String _roomsBoxName = 'rooms';
  
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final Uuid _uuid = const Uuid();
  
  Box<Map>? _propertiesBox;
  Box<Map>? _roomsBox;

  /// Inicializa Hive y abre las cajas
  Future<void> init() async {
    await Hive.initFlutter();
    _propertiesBox = await Hive.openBox<Map>(_propertiesBoxName);
    _roomsBox = await Hive.openBox<Map>(_roomsBoxName);
  }

  /// Obtiene todas las propiedades
  Future<List<InventoryProperty>> getAllProperties() async {
    if (_propertiesBox == null) await init();
    
    return _propertiesBox!.values
        .map((map) => InventoryProperty.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  /// Obtiene una propiedad por ID
  Future<InventoryProperty?> getProperty(String id) async {
    if (_propertiesBox == null) await init();
    
    final map = _propertiesBox!.get(id);
    if (map == null) return null;
    return InventoryProperty.fromMap(Map<String, dynamic>.from(map));
  }

  /// Guarda una propiedad
  Future<void> saveProperty(InventoryProperty property) async {
    if (_propertiesBox == null) await init();
    
    property.fechaActualizacion = DateTime.now();
    await _propertiesBox!.put(property.id, property.toMap());
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
    String? pais,
    String? ciudad,
    String? municipio,
    String? barrio,
    int? numeroNiveles,
    String? numeroInterior,
    double? areaLote,
    String? codigoInterno,
    double? precioAlquilerDeseado,
    String? nombreAgente,
    String? tipoDocumento,
    String? numeroDocumento,
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
      pais: pais,
      ciudad: ciudad,
      municipio: municipio,
      barrio: barrio,
      numeroNiveles: numeroNiveles,
      numeroInterior: numeroInterior,
      areaLote: areaLote,
      codigoInterno: codigoInterno,
      precioAlquilerDeseado: precioAlquilerDeseado,
      nombreAgente: nombreAgente,
      tipoDocumento: tipoDocumento,
      numeroDocumento: numeroDocumento,
    );

    await saveProperty(property);
    return property;
  }

  /// Actualiza una propiedad
  Future<void> updateProperty(InventoryProperty property) async {
    property.fechaActualizacion = DateTime.now();
    await saveProperty(property);
  }

  /// Elimina una propiedad y todos sus espacios
  Future<void> deleteProperty(String propertyId) async {
    if (_propertiesBox == null) await init();
    
    // Eliminar todos los espacios de la propiedad
    final rooms = await getRoomsByProperty(propertyId);
    for (final room in rooms) {
      await deleteRoom(room.id);
    }
    
    // Eliminar la propiedad
    await _propertiesBox!.delete(propertyId);
  }

  /// Obtiene todos los espacios de una propiedad
  Future<List<PropertyRoom>> getRoomsByProperty(String propertyId) async {
    if (_roomsBox == null) await init();
    
    if (kDebugMode) {
      debugPrint('🔍 [InventoryService] Buscando espacios para propiedad: $propertyId');
      debugPrint('   Total de espacios en box: ${_roomsBox!.length}');
    }
    
    final allRooms = _roomsBox!.values
        .map((map) {
          try {
            return PropertyRoom.fromMap(Map<String, dynamic>.from(map));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error deserializando espacio: $e');
              debugPrint('   Datos del map: $map');
            }
            return null;
          }
        })
        .whereType<PropertyRoom>()
        .where((room) => room.propertyId == propertyId)
        .toList()
      ..sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    
    if (kDebugMode) {
      debugPrint('✅ Espacios encontrados: ${allRooms.length}');
      for (var room in allRooms) {
        debugPrint('   - ${room.nombre}: ${room.items.length} elementos');
      }
    }
    
    return allRooms;
  }

  /// Obtiene un espacio por ID
  Future<PropertyRoom?> getRoom(String id) async {
    if (_roomsBox == null) await init();
    
    final map = _roomsBox!.get(id);
    if (map == null) return null;
    return PropertyRoom.fromMap(Map<String, dynamic>.from(map));
  }

  /// Guarda un espacio
  Future<void> saveRoom(PropertyRoom room) async {
    if (_roomsBox == null) await init();
    
    room.fechaActualizacion = DateTime.now();
    final roomMap = room.toMap();
    
    if (kDebugMode) {
      debugPrint('💾 Guardando espacio: ${room.nombre}');
      debugPrint('   ID: ${room.id}');
      debugPrint('   Propiedad ID: ${room.propertyId}');
      debugPrint('   Elementos: ${room.items.length}');
      debugPrint('   Map serializado: ${roomMap.keys}');
    }
    
    await _roomsBox!.put(room.id, roomMap);
    
    if (kDebugMode) {
      debugPrint('✅ Espacio guardado exitosamente');
      // Verificar que se guardó
      final saved = _roomsBox!.get(room.id);
      if (saved != null) {
        debugPrint('✅ Verificación: Espacio encontrado en box');
      } else {
        debugPrint('❌ ERROR: Espacio NO encontrado en box después de guardar');
      }
    }
  }

  /// Crea un nuevo espacio
  Future<PropertyRoom> createRoom({
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

    await saveRoom(room);
    return room;
  }

  /// Actualiza un espacio
  Future<void> updateRoom(PropertyRoom room) async {
    room.fechaActualizacion = DateTime.now();
    await saveRoom(room);
  }

  /// Elimina un espacio
  Future<void> deleteRoom(String roomId) async {
    if (_roomsBox == null) await init();
    await _roomsBox!.delete(roomId);
  }

  /// Agrega una foto a un espacio
  Future<void> addRoomPhoto(String roomId, String photoUrl) async {
    final room = await getRoom(roomId);
    if (room == null) return;

    room.fotos.add(photoUrl);
    await updateRoom(room);
  }

  /// Establece la foto 360° de un espacio
  Future<void> setRoom360Photo(String roomId, String photo360Url) async {
    final room = await getRoom(roomId);
    if (room == null) return;

    room.foto360Url = photo360Url;
    await updateRoom(room);
  }

  /// Agrega un problema a un espacio
  Future<void> addRoomProblem(String roomId, String problema) async {
    final room = await getRoom(roomId);
    if (room == null) return;

    if (!room.problemas.contains(problema)) {
      room.problemas.add(problema);
      await updateRoom(room);
    }
  }

  /// Busca propiedades por dirección o cliente
  Future<List<InventoryProperty>> searchProperties(String query) async {
    final allProperties = await getAllProperties();
    final queryLower = query.toLowerCase();

    return allProperties.where((property) {
      return property.direccion.toLowerCase().contains(queryLower) ||
          (property.clienteNombre?.toLowerCase().contains(queryLower) ?? false) ||
          (property.descripcion?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Obtiene estadísticas de inventario
  Future<Map<String, dynamic>> getStatistics() async {
    final properties = await getAllProperties();
    final allRooms = <PropertyRoom>[];
    
    for (final property in properties) {
      final rooms = await getRoomsByProperty(property.id);
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

  /// Cierra las cajas de Hive
  Future<void> dispose() async {
    await _propertiesBox?.close();
    await _roomsBox?.close();
  }
}
