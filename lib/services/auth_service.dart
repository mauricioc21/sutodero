import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _firebaseAvailable = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get firebaseAvailable => _firebaseAvailable;

  // Constructor
  AuthService() {
    _checkAuthState();
  }

  // Verificar estado de autenticación
  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      }
    } catch (e) {
      _errorMessage = 'Error al verificar autenticación: $e';
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Firebase no disponible, usando modo local');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login con email y contraseña
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        // Login con Firebase Auth
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _loadUserData(credential.user!.uid);
      } else {
        // Modo demo sin Firebase
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserModel(
          uid: 'demo_user',
          nombre: 'Usuario Demo',
          email: email,
          rol: 'admin',
          telefono: '3138160439',
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registro de nuevo usuario
  Future<bool> register(String nombre, String email, String password, String telefono) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        // Registro con Firebase Auth
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Actualizar nombre de usuario en Firebase Auth
        await credential.user!.updateDisplayName(nombre);
        
        // Crear documento de usuario en Firestore
        final user = UserModel(
          uid: credential.user!.uid,
          nombre: nombre,
          email: email,
          rol: 'cliente',
          telefono: telefono,
          fechaCreacion: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        _currentUser = user;
      } else {
        // Modo demo sin Firebase
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserModel(
          uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
          nombre: nombre,
          email: email,
          rol: 'cliente',
          telefono: telefono,
          fechaCreacion: DateTime.now(),
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al registrar usuario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      if (_firebaseAvailable) {
        await _auth.signOut();
      }
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
      notifyListeners();
    }
  }

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      } else {
        // Si no existe el documento, crear uno con datos básicos
        final user = _auth.currentUser;
        if (user != null) {
          _currentUser = UserModel(
            uid: uid,
            nombre: user.displayName ?? 'Usuario',
            email: user.email ?? '',
            rol: 'cliente',
            telefono: '',
            fechaCreacion: DateTime.now(),
          );
          await _firestore.collection('users').doc(uid).set(_currentUser!.toMap());
        }
      }
    } catch (e) {
      _errorMessage = 'Error al cargar datos del usuario: $e';
      if (kDebugMode) {
        debugPrint('⚠️ Error cargando usuario: $e');
      }
    }
  }

  // Recuperar contraseña
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        await _auth.sendPasswordResetEmail(email: email);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al enviar correo de recuperación: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener mensajes de error en español
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: $code';
    }
  }

  // Actualizar perfil de usuario
  Future<bool> updateProfile({
    String? nombre,
    String? telefono,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (telefono != null) updates['telefono'] = telefono;

      if (_firebaseAvailable && updates.isNotEmpty) {
        await _firestore.collection('users').doc(_currentUser!.uid).update(updates);
        
        // Actualizar también en Firebase Auth si cambió el nombre
        if (nombre != null) {
          await _auth.currentUser!.updateDisplayName(nombre);
        }
      }

      // Actualizar localmente
      _currentUser = _currentUser!.copyWith(
        nombre: nombre ?? _currentUser!.nombre,
        telefono: telefono ?? _currentUser!.telefono,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar perfil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
