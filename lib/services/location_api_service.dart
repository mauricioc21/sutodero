import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import 'ticket_service.dart';
import 'geolocation_service.dart';

/// Servicio que simula las rutas de API requeridas para el módulo de ubicación
class LocationApiService {
  final TicketService _ticketService = TicketService();
  final GeolocationService _geolocationService = GeolocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final LocationApiService _instance = LocationApiService._internal();
  factory LocationApiService() => _instance;
  LocationApiService._internal();

  /// POST /ubicacion/enviar
  /// Envía la ubicación actual del usuario (Maestro) asociada a un ticket o independiente
  Future<Map<String, dynamic>> sendLocation({
    required String userId,
    required double lat,
    required double lng,
    String? ticketId,
  }) async {
    try {
      final timestamp = DateTime.now();
      
      // 1. Guardar en colección de historial de ubicaciones del usuario (Audit Log)
      await _firestore.collection('user_locations').add({
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'timestamp': Timestamp.fromDate(timestamp),
        'ticketId': ticketId,
        'deviceInfo': 'Mobile App', // Simulado
      });

      // 2. Si hay ticketId, actualizar última ubicación conocida en el contexto del ticket (opcional)
      if (ticketId != null) {
        // Podríamos guardar un rastro en el ticket si fuera necesario
        // await _firestore.collection('tickets').doc(ticketId).update({...});
      }

      return {
        'status': 'success',
        'message': 'Ubicación registrada correctamente',
        'data': {
          'lat': lat,
          'lng': lng,
          'timestamp': timestamp.toIso8601String(),
        }
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error al enviar ubicación: $e',
        'code': 500
      };
    }
  }

  /// GET /ubicacion/historial/:id
  /// Obtiene el historial de ubicaciones de un usuario o ticket
  Future<Map<String, dynamic>> getLocationHistory(String id, {bool isTicketId = false}) async {
    try {
      final field = isTicketId ? 'ticketId' : 'userId';
      final querySnapshot = await _firestore
          .collection('user_locations')
          .where(field, isEqualTo: id)
          .orderBy('timestamp', descending: true)
          .limit(100) // Límite por seguridad
          .get();

      final history = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'lat': data['lat'],
          'lng': data['lng'],
          'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
          'ticketId': data['ticketId'],
        };
      }).toList();

      return {
        'status': 'success',
        'data': history,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error obteniendo historial: $e',
        'code': 500
      };
    }
  }

  /// GET /ubicacion/propiedad/:id
  /// Obtiene la ubicación de la propiedad asociada a un ticket
  Future<Map<String, dynamic>> getPropertyLocation(String ticketId) async {
    try {
      final ticket = await _ticketService.getTicket(ticketId);
      if (ticket == null) {
        return {'status': 'error', 'message': 'Ticket no encontrado', 'code': 404};
      }

      if (ticket.ubicacionLat == null || ticket.ubicacionLng == null) {
        return {
          'status': 'success',
          'data': null,
          'message': 'La propiedad no tiene coordenadas registradas'
        };
      }

      return {
        'status': 'success',
        'data': {
          'lat': ticket.ubicacionLat,
          'lng': ticket.ubicacionLng,
          'address': ticket.ubicacionDireccion,
        }
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error obteniendo ubicación de propiedad: $e',
        'code': 500
      };
    }
  }

  /// Validar ubicación (Logic helper)
  /// Verifica si una coordenada está dentro del rango de la propiedad
  Future<bool> validateLocationInRange(String ticketId, double currentLat, double currentLng, double rangeMeters) async {
    final propLoc = await getPropertyLocation(ticketId);
    if (propLoc['status'] != 'success' || propLoc['data'] == null) return false;

    final targetLat = propLoc['data']['lat'];
    final targetLng = propLoc['data']['lng'];

    return _geolocationService.isWithinRange(
      currentLat, currentLng, 
      targetLat, targetLng, 
      rangeMeters: rangeMeters
    );
  }
}
