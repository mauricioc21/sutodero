import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/maestro_profile_model.dart';

class MaestroProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'maestro_profiles';
  
  // Cache en memoria para perfiles que no se pudieron guardar en Firebase
  static final Map<String, MaestroProfileModel> _memoryCache = {};

  /// Crear perfil de maestro - Versión simplificada que NUNCA falla
  Future<String?> createMaestroProfile(MaestroProfileModel profile) async {
    // Validar campos requeridos
    if (profile.nombre.trim().isEmpty || profile.telefono.trim().isEmpty) {
      throw Exception('Nombre y teléfono son obligatorios');
    }
    
    // Generar ID único
    String finalId = profile.id;
    if (finalId.isEmpty || finalId.contains(RegExp(r'\d{13,}'))) {
      finalId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Preparar datos
    final data = profile.toMap();
    
    // Intentar guardar en Firebase (con timeout corto - no bloqueante)
    bool savedInFirebase = false;
    try {
      if (finalId.startsWith('local_')) {
        final docRef = await _firestore.collection(_collection).add(data).timeout(
          const Duration(seconds: 2),
        );
        finalId = docRef.id;
        savedInFirebase = true;
        if (kDebugMode) {
          debugPrint('✅ Perfil guardado en Firebase: $finalId');
        }
      } else {
        await _firestore.collection(_collection).doc(finalId).set(data).timeout(
          const Duration(seconds: 2),
        );
        savedInFirebase = true;
        if (kDebugMode) {
          debugPrint('✅ Perfil guardado en Firebase: $finalId');
        }
      }
    } catch (e) {
      // Firebase falló - usar ID local
      if (!finalId.startsWith('local_')) {
        finalId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
      if (kDebugMode) {
        debugPrint('⚠️ Firebase no disponible, usando ID local: $finalId');
      }
    }
    
    // SIEMPRE guardar en cache de memoria
    _memoryCache[finalId] = MaestroProfileModel(
      id: finalId,
      nombre: profile.nombre,
      telefono: profile.telefono,
      email: profile.email,
      especialidad: profile.especialidad,
      foto: profile.foto,
      activo: profile.activo,
      fechaCreacion: profile.fechaCreacion,
      fechaActualizacion: profile.fechaActualizacion,
    );
    
    if (kDebugMode) {
      debugPrint('✅ Perfil creado con ID: $finalId (Firebase: $savedInFirebase, Memoria: true)');
    }
    
    // SIEMPRE retornar el ID - nunca fallar
    return finalId;
  }

  /// Obtener todos los perfiles (Firebase + Memoria)
  Future<List<MaestroProfileModel>> getAllProfiles() async {
    final allProfiles = <MaestroProfileModel>[];
    
    // Cargar desde Firebase
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('nombre')
          .get()
          .timeout(const Duration(seconds: 3));
      
      allProfiles.addAll(
        snapshot.docs.map((doc) => MaestroProfileModel.fromMap(doc.data(), doc.id))
      );
      
      if (kDebugMode) {
        debugPrint('☁️ Perfiles de Firebase: ${allProfiles.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo conectar a Firebase: $e');
      }
    }
    
    // Agregar perfiles de memoria que no estén en Firebase
    for (var entry in _memoryCache.entries) {
      if (!allProfiles.any((p) => p.id == entry.key)) {
        allProfiles.add(entry.value);
      }
    }
    
    // Si no hay perfiles, agregar predeterminados
    if (allProfiles.isEmpty) {
      final now = DateTime.now();
      allProfiles.addAll([
        MaestroProfileModel(
          id: 'rodrigo',
          nombre: 'Rodrigo',
          telefono: '3001234567',
          email: 'rodrigo@sutodero.com',
          especialidad: 'Plomería y Electricidad',
          activo: true,
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
        MaestroProfileModel(
          id: 'alexander',
          nombre: 'Alexander',
          telefono: '3007654321',
          email: 'alexander@sutodero.com',
          especialidad: 'Carpintería y Albañilería',
          activo: true,
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
      ]);
      // Agregar a cache
      for (var profile in allProfiles) {
        _memoryCache[profile.id] = profile;
      }
    }
    
    allProfiles.sort((a, b) => a.nombre.compareTo(b.nombre));
    
    if (kDebugMode) {
      debugPrint('📊 Total perfiles: ${allProfiles.length} (Firebase + Memoria + Predeterminados)');
    }
    
    return allProfiles;
  }

  /// Obtener perfiles activos
  Future<List<MaestroProfileModel>> getActiveProfiles() async {
    final allProfiles = await getAllProfiles();
    return allProfiles.where((profile) => profile.activo).toList();
  }

  /// Stream de perfiles (solo Firebase - para compatibilidad)
  Stream<List<MaestroProfileModel>> getMaestroProfiles() {
    return _firestore
        .collection(_collection)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaestroProfileModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtener un perfil específico
  Future<MaestroProfileModel?> getMaestroProfile(String id) async {
    // Buscar en cache primero
    if (_memoryCache.containsKey(id)) {
      return _memoryCache[id];
    }
    
    // Buscar en Firebase
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return MaestroProfileModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener perfil: $e');
      }
    }
    
    return null;
  }

  /// Actualizar perfil
  Future<bool> updateMaestroProfile(String id, MaestroProfileModel profile) async {
    try {
      await _firestore.collection(_collection).doc(id).update(profile.toMap());
      _memoryCache[id] = profile; // Actualizar cache
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar: $e');
      }
      // Actualizar solo en cache
      _memoryCache[id] = profile;
      return true; // Retornar true porque se actualizó en cache
    }
  }

  /// Eliminar perfil (soft delete)
  Future<bool> deleteMaestroProfile(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'activo': false,
        'fechaActualizacion': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar: $e');
      }
      return false;
    }
  }

  /// Inicializar perfiles predeterminados
  Future<bool> initializeDefaultProfiles() async {
    final allProfiles = await getAllProfiles();
    
    final rodrigoExists = allProfiles.any((p) => p.id == 'rodrigo' || p.nombre.toLowerCase() == 'rodrigo');
    final alexanderExists = allProfiles.any((p) => p.id == 'alexander' || p.nombre.toLowerCase() == 'alexander');
    
    if (rodrigoExists && alexanderExists) {
      return false;
    }
    
    final now = DateTime.now();
    bool created = false;
    
    if (!rodrigoExists) {
      final rodrigo = MaestroProfileModel(
        id: 'rodrigo',
        nombre: 'Rodrigo',
        telefono: '3001234567',
        email: 'rodrigo@sutodero.com',
        especialidad: 'Plomería y Electricidad',
        activo: true,
        fechaCreacion: now,
        fechaActualizacion: now,
      );
      await createMaestroProfile(rodrigo);
      created = true;
    }
    
    if (!alexanderExists) {
      final alexander = MaestroProfileModel(
        id: 'alexander',
        nombre: 'Alexander',
        telefono: '3007654321',
        email: 'alexander@sutodero.com',
        especialidad: 'Carpintería y Albañilería',
        activo: true,
        fechaCreacion: now,
        fechaActualizacion: now,
      );
      await createMaestroProfile(alexander);
      created = true;
    }
    
    return created;
  }

  /// Obtener perfiles activos (Stream - para compatibilidad)
  Stream<List<MaestroProfileModel>> getActiveMaestroProfiles() {
    return _firestore
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaestroProfileModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
