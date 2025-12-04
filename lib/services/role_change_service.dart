import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/role_change_request_model.dart';
import '../models/user_model.dart';

class RoleChangeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<RoleChangeRequest> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RoleChangeRequest> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingRequests.length;

  // Crear una nueva solicitud de cambio de rol
  Future<bool> createRoleChangeRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required UserRole currentRole,
    required UserRole requestedRole,
    String? comments,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Verificar si ya existe una solicitud pendiente
      final existingRequest = await _firestore
          .collection('role_change_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _errorMessage = 'Ya tienes una solicitud de cambio de rol pendiente';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Crear la solicitud
      final request = RoleChangeRequest(
        id: '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        currentRole: currentRole,
        requestedRole: requestedRole,
        status: RequestStatus.pending,
        requestDate: DateTime.now(),
        comments: comments,
      );

      await _firestore.collection('role_change_requests').add(request.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear solicitud: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener todas las solicitudes pendientes (para administradores)
  Future<void> loadPendingRequests() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('role_change_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestDate', descending: true)
          .get();

      _pendingRequests = snapshot.docs
          .map((doc) => RoleChangeRequest.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar solicitudes: $e';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('Error loading pending requests: $e');
      }
    }
  }

  // Obtener solicitudes de un usuario específico
  Future<List<RoleChangeRequest>> getUserRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('role_change_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RoleChangeRequest.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user requests: $e');
      }
      return [];
    }
  }

  // Aprobar una solicitud
  Future<bool> approveRequest({
    required String requestId,
    required String adminId,
    required String adminName,
    String? comments,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Obtener la solicitud
      final requestDoc = await _firestore
          .collection('role_change_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        _errorMessage = 'Solicitud no encontrada';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final request = RoleChangeRequest.fromMap(requestDoc.data()!, requestId);

      // Actualizar el rol del usuario en Firestore
      await _firestore.collection('users').doc(request.userId).update({
        'rol': request.requestedRole.name,
      });

      // Actualizar el estado de la solicitud
      await _firestore.collection('role_change_requests').doc(requestId).update({
        'status': 'approved',
        'adminId': adminId,
        'adminName': adminName,
        'responseDate': Timestamp.now(),
        'comments': comments,
      });

      // Recargar solicitudes pendientes
      await loadPendingRequests();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al aprobar solicitud: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Rechazar una solicitud
  Future<bool> rejectRequest({
    required String requestId,
    required String adminId,
    required String adminName,
    String? comments,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Actualizar el estado de la solicitud
      await _firestore.collection('role_change_requests').doc(requestId).update({
        'status': 'rejected',
        'adminId': adminId,
        'adminName': adminName,
        'responseDate': Timestamp.now(),
        'comments': comments,
      });

      // Recargar solicitudes pendientes
      await loadPendingRequests();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al rechazar solicitud: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verificar si un usuario tiene una solicitud pendiente
  Future<bool> hasPendingRequest(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('role_change_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking pending request: $e');
      }
      return false;
    }
  }

  // Obtener el conteo de solicitudes pendientes (para badge en home)
  Future<int> getPendingRequestsCount() async {
    try {
      final snapshot = await _firestore
          .collection('role_change_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending count: $e');
      }
      return 0;
    }
  }
}
