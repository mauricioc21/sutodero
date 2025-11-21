import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'activity_log_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityLogService _activityLog = ActivityLogService();
  
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

  // Login con email y contraseña (ULTRA-OPTIMIZADO - RETORNO INMEDIATO)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        // Login con Firebase Auth con timeout REDUCIDO a 5 segundos
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Sin respuesta del servidor. Verifica tu internet.');
          },
        );
        
        // ⚡ OPTIMIZACIÓN: Establecer usuario básico PRIMERO para UI rápida
        _currentUser = UserModel(
          uid: credential.user!.uid,
          nombre: credential.user!.displayName ?? 'Usuario',
          email: credential.user!.email ?? email,
          rol: 'user',
          telefono: '',
        );
        
        if (kDebugMode) {
          debugPrint('⚡ Usuario básico establecido: ${_currentUser!.nombre}');
        }
        
        // ✅ ESPERAR a cargar datos completos antes de continuar
        // Esto es CRÍTICO para que el nombre real y userId estén disponibles
        try {
          await _loadUserData(credential.user!.uid);
          if (kDebugMode) {
            debugPrint('✅ Datos completos cargados: ${_currentUser!.nombre}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error cargando datos completos: $e (continuando con datos básicos)');
          }
        }
        
        // ⚡ Retornar éxito después de cargar datos completos
        _isLoading = false;
        notifyListeners();
        
        // 📝 Registrar actividad de login
        _activityLog.logLogin(credential.user!.uid, email);
        
        return true;
      } else {
        // Modo demo sin Firebase (más rápido)
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
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _firebaseAvailable = false; // Marcar Firebase como no disponible
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
        if (kDebugMode) {
          debugPrint('📝 Iniciando registro de usuario: $email');
        }
        
        // Registro con Firebase Auth
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout al registrar usuario. Verifica tu internet.');
          },
        );
        
        if (kDebugMode) {
          debugPrint('✅ Usuario creado en Firebase Auth: ${credential.user!.uid}');
        }
        
        // Actualizar nombre de usuario en Firebase Auth
        await credential.user!.updateDisplayName(nombre);
        
        if (kDebugMode) {
          debugPrint('✅ Display name actualizado: $nombre');
        }
        
        // Crear documento de usuario en Firestore
        final user = UserModel(
          uid: credential.user!.uid,
          nombre: nombre,
          email: email,
          rol: 'cliente',
          telefono: telefono,
          fechaCreacion: DateTime.now(),
        );
        
        if (kDebugMode) {
          debugPrint('💾 Guardando usuario en Firestore: ${user.uid}');
          debugPrint('📄 Datos: ${user.toMap()}');
        }
        
        await _firestore.collection('users').doc(user.uid).set(user.toMap())
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout al guardar datos en Firestore. Verifica tu internet.');
          },
        );
        
        if (kDebugMode) {
          debugPrint('✅ Usuario guardado exitosamente en Firestore');
        }
        
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

  // Login con userId (para reconocimiento facial)
  Future<bool> loginWithUserId(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebaseAvailable) {
        // Cargar datos del usuario desde Firestore
        await _loadUserData(userId);
        
        if (_currentUser != null) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Usuario no encontrado';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Modo demo sin Firebase
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserModel(
          uid: userId,
          nombre: 'Usuario Biométrico',
          email: 'biometric@sutodero.com',
          rol: 'cliente',
          telefono: '3138160439',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error al autenticar con userId: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      final userId = _currentUser?.uid;
      
      if (_firebaseAvailable) {
        await _auth.signOut();
      }
      
      // 📝 Registrar logout antes de limpiar usuario
      if (userId != null) {
        _activityLog.logLogout(userId);
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
      final doc = await _firestore.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        if (kDebugMode) {
          debugPrint('⚠️ Timeout cargando datos de usuario desde Firestore');
        }
        throw Exception('Sin conexión a internet');
      });
      
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
        if (kDebugMode) {
          debugPrint('✅ Datos completos del usuario cargados: ${_currentUser!.nombre}');
        }
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
          if (kDebugMode) {
            debugPrint('✅ Documento de usuario creado en Firestore');
          }
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
    if (kDebugMode) {
      debugPrint('🔴 Firebase Auth Error Code: $code');
    }
    
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      case 'invalid-login-credentials':
        return 'Correo o contraseña incorrectos';
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
    String? direccion,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (telefono != null) updates['telefono'] = telefono;
      if (direccion != null) updates['direccion'] = direccion;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (_firebaseAvailable && updates.isNotEmpty) {
        await _firestore.collection('users').doc(_currentUser!.uid).update(updates);
        
        // Actualizar también en Firebase Auth si cambió el nombre
        if (nombre != null) {
          await _auth.currentUser!.updateDisplayName(nombre);
        }
        
        // Actualizar también la foto de perfil en Firebase Auth
        if (photoUrl != null) {
          await _auth.currentUser!.updatePhotoURL(photoUrl);
        }
        
        // 📝 Registrar actividad de actualización de perfil
        _activityLog.logActivity(
          userId: _currentUser!.uid,
          type: ActivityType.other,
          action: 'Perfil actualizado',
          metadata: {'fields': updates.keys.toList()},
        );
      }

      // Actualizar localmente
      _currentUser = _currentUser!.copyWith(
        nombre: nombre,
        telefono: telefono,
        direccion: direccion,
        photoUrl: photoUrl,
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

  /// Cambiar contraseña del usuario
  /// Requiere la contraseña actual para re-autenticación
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_firebaseAvailable) {
        _errorMessage = 'Cambio de contraseña no disponible en modo offline';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        _errorMessage = 'Usuario no autenticado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Re-autenticar al usuario con la contraseña actual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);

      // Cambiar la contraseña
      await user.updatePassword(newPassword);

      // 📝 Registrar cambio de contraseña
      _activityLog.logActivity(
        userId: _currentUser!.uid,
        type: ActivityType.other,
        action: 'Contraseña cambiada',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al cambiar contraseña: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
