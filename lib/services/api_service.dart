import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para conectar Flutter con Firebase Functions Backend
/// URL Base:
/// https://us-central1-sutoderoapp-ee318.cloudfunctions.net/api
class ApiService {
  static const String baseUrl =
      'https://us-central1-sutoderoapp-ee318.cloudfunctions.net/api';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== AUTH ====================

  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== TICKETS ====================

  /// Crear ticket
  /// Solo admin / coordinador (validado en backend)
  Future<Map<String, dynamic>> createTicket({
    required String titulo,
    required String descripcion,
    required String tipoServicio,
    required String prioridad,

    // Cliente
    required String clienteId,
    required String clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,

    // Ubicación
    String? propiedadId,
    String? propiedadDireccion,
    double? lat,
    double? lng,

    // Extras
    DateTime? fechaProgramada,
    String? notasCliente,
    List<String>? fotosAntes,
    double? presupuestoEstimado,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = {
        'titulo': titulo,
        'descripcion': descripcion,
        'tipoServicio': tipoServicio,
        'prioridad': prioridad,

        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'clienteTelefono': clienteTelefono,
        'clienteEmail': clienteEmail,

        'propiedadId': propiedadId,
        'propiedadDireccion': propiedadDireccion,

        if (lat != null && lng != null)
          'ubicacion': {'lat': lat, 'lng': lng},

        'fechaProgramada': fechaProgramada?.toIso8601String(),
        'notasCliente': notasCliente,
        'fotosAntes': fotosAntes ?? [],
        'presupuestoEstimado': presupuestoEstimado,

        // Debug / trazabilidad
        'origen': 'app_movil',
      }..removeWhere((key, value) => value == null);

      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando ticket',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener tickets (filtrados por rol en backend)
  Future<List<dynamic>> getTickets({
    String? estado,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        if (estado != null) 'estado': estado,
        'limit': limit.toString(),
      };

      final uri =
          Uri.parse('$baseUrl/tickets').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['tickets'] as List;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message']);
      }
    } catch (e) {
      print('❌ Error getTickets: $e');
      rethrow;
    }
  }

  /// Obtener ticket por ID
  Future<Map<String, dynamic>> getTicket(String ticketId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$ticketId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['ticket'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message']);
      }
    } catch (e) {
      print('❌ Error getTicket: $e');
      rethrow;
    }
  }

  /// Actualizar ticket
  /// (estado, fechas, notas, asignación de maestro, costos, fotos)
  Future<Map<String, dynamic>> updateTicket(
    String ticketId, {
    String? estado,
    String? descripcion,
    DateTime? fechaInicio,
    DateTime? fechaFin,

    String? maestroId,
    String? maestroNombre,

    List<String>? fotosDurante,
    List<String>? fotosDespues,
    String? notasMaestro,
    double? costoReal,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = {
        'estado': estado,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio?.toIso8601String(),
        'fechaFin': fechaFin?.toIso8601String(),
        'maestroId': maestroId,
        'maestroNombre': maestroNombre,
        'fotosDurante': fotosDurante,
        'fotosDespues': fotosDespues,
        'notasMaestro': notasMaestro,
        'costoReal': costoReal,
      }..removeWhere((key, value) => value == null);

      final response = await http.put(
        Uri.parse('$baseUrl/tickets/$ticketId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message']);
      }
    } catch (e) {
      print('❌ Error updateTicket: $e');
      rethrow;
    }
  }

  /// Agregar comentario
  Future<void> addComment(String ticketId, String texto) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/comment'),
      headers: headers,
      body: jsonEncode({'texto': texto}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message']);
    }
  }

  /// Agregar fotos
  /// tipo: antes | durante | despues
  Future<void> addPhotos(
    String ticketId,
    List<String> fotos,
    String tipo,
  ) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/photos'),
      headers: headers,
      body: jsonEncode({
        'fotos': fotos,
        'tipo': tipo,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message']);
    }
  }

  /// Eliminar ticket (admin / coordinador)
  Future<void> deleteTicket(String ticketId) async {
    final headers = await _getHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/tickets/$ticketId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message']);
    }
  }

  // ==================== MAESTROS ====================

  Future<List<dynamic>> getMaestros() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/maestros'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['maestros'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message']);
    }
  }

  // ==================== UTILS ====================

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  User? getCurrentUser() => _auth.currentUser;
  bool isAuthenticated() => _auth.currentUser != null;
}
