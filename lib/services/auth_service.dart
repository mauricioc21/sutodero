import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Constructor
  AuthService() {
    _checkAuthState();
  }

  // Verificar estado de autenticación
  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implementar con Firebase Auth
      // final user = _auth.currentUser;
      // if (user != null) {
      //   await _loadUserData(user.uid);
      // }
    } catch (e) {
      _errorMessage = 'Error al verificar autenticación: $e';
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
      // TODO: Implementar con Firebase Auth
      // final credential = await _auth.signInWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );
      // await _loadUserData(credential.user!.uid);
      
      // Simulación temporal
      await Future.delayed(const Duration(seconds: 1));
      _currentUser = UserModel(
        uid: 'demo_user',
        nombre: 'Usuario Demo',
        email: email,
        rol: 'admin',
        telefono: '3138160439',
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
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
      // TODO: Implementar con Firebase Auth
      // final credential = await _auth.createUserWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );
      //
      // final user = UserModel(
      //   uid: credential.user!.uid,
      //   nombre: nombre,
      //   email: email,
      //   rol: 'cliente',
      //   telefono: telefono,
      // );
      //
      // await _firestore.collection('users').doc(user.uid).set(user.toMap());
      // _currentUser = user;
      
      _isLoading = false;
      notifyListeners();
      return true;
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
      // await _auth.signOut();
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
      // final doc = await _firestore.collection('users').doc(uid).get();
      // if (doc.exists) {
      //   _currentUser = UserModel.fromMap(doc.data()!, uid);
      // }
    } catch (e) {
      _errorMessage = 'Error al cargar datos del usuario: $e';
    }
  }
}
