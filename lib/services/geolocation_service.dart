import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal();

  /// Solicitar permisos y obtener ubicación actual
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Verificar si los servicios de ubicación están habilitados
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) debugPrint('⚠️ Servicios de ubicación deshabilitados.');
        return null;
      }

      // Verificar permisos
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) debugPrint('⚠️ Permisos de ubicación denegados.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) debugPrint('⚠️ Permisos de ubicación denegados permanentemente.');
        return null;
      }

      // Obtener posición actual
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Calcular distancia usando la fórmula de Haversine
  /// Retorna la distancia en metros
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * asin... result in meters
  }

  /// Validar si está dentro del rango permitido (150 metros)
  bool isWithinRange(double currentLat, double currentLng, double targetLat, double targetLng, {double rangeMeters = 150}) {
    final distance = calculateDistance(currentLat, currentLng, targetLat, targetLng);
    return distance <= rangeMeters;
  }
}
