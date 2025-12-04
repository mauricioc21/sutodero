import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/empleado_model.dart';

/// Servicio para gestionar empleados (sin cuenta de usuario)
class EmpleadoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final EmpleadoService _instance = EmpleadoService._internal();
  factory EmpleadoService() => _instance;
  EmpleadoService._internal();

  /// Crear un nuevo empleado
  Future<EmpleadoModel> createEmpleado({
    required String nombre,
    required String correo,
    required String telefono,
    required String cargo,
    String? notas,
  }) async {
    try {
      final now = DateTime.now();
      final empleado = EmpleadoModel(
        id: _uuid.v4(),
        nombre: nombre,
        correo: correo,
        telefono: telefono,
        cargo: cargo,
        fechaCreacion: now,
        fechaActualizacion: now,
        activo: true,
        notas: notas,
      );

      await _firestore.collection('empleados').doc(empleado.id).set(empleado.toMap());

      if (kDebugMode) {
        debugPrint('✅ Empleado creado: ${empleado.nombre} (${empleado.cargo})');
      }

      return empleado;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creando empleado: $e');
      }
      rethrow;
    }
  }

  /// Obtener todos los empleados
  Future<List<EmpleadoModel>> getAllEmpleados() async {
    try {
      final querySnapshot = await _firestore
          .collection('empleados')
          .orderBy('fechaCreacion', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EmpleadoModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo empleados: $e');
      }
      return [];
    }
  }

  /// Obtener empleados por cargo
  Future<List<EmpleadoModel>> getEmpleadosByCargo(String cargo) async {
    try {
      final querySnapshot = await _firestore
          .collection('empleados')
          .where('cargo', isEqualTo: cargo)
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();

      return querySnapshot.docs
          .map((doc) => EmpleadoModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo empleados por cargo: $e');
      }
      return [];
    }
  }

  /// Obtener un empleado por ID
  Future<EmpleadoModel?> getEmpleadoById(String id) async {
    try {
      final doc = await _firestore.collection('empleados').doc(id).get();

      if (doc.exists) {
        return EmpleadoModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo empleado: $e');
      }
      return null;
    }
  }

  /// Actualizar un empleado
  Future<bool> updateEmpleado(EmpleadoModel empleado) async {
    try {
      final updatedEmpleado = empleado.copyWith(
        fechaActualizacion: DateTime.now(),
      );

      await _firestore
          .collection('empleados')
          .doc(empleado.id)
          .update(updatedEmpleado.toMap());

      if (kDebugMode) {
        debugPrint('✅ Empleado actualizado: ${empleado.nombre}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error actualizando empleado: $e');
      }
      return false;
    }
  }

  /// Eliminar un empleado (soft delete - marcar como inactivo)
  Future<bool> deleteEmpleado(String id) async {
    try {
      await _firestore.collection('empleados').doc(id).update({
        'activo': false,
        'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ Empleado marcado como inactivo: $id');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando empleado: $e');
      }
      return false;
    }
  }

  /// Eliminar permanentemente un empleado
  Future<bool> deleteEmpleadoPermanently(String id) async {
    try {
      await _firestore.collection('empleados').doc(id).delete();

      if (kDebugMode) {
        debugPrint('✅ Empleado eliminado permanentemente: $id');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando empleado permanentemente: $e');
      }
      return false;
    }
  }

  /// Buscar empleados por nombre
  Future<List<EmpleadoModel>> searchEmpleadosByNombre(String query) async {
    try {
      final allEmpleados = await getAllEmpleados();
      final queryLower = query.toLowerCase();

      return allEmpleados
          .where((empleado) =>
              empleado.nombre.toLowerCase().contains(queryLower) ||
              empleado.correo.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error buscando empleados: $e');
      }
      return [];
    }
  }

  /// Obtener estadísticas de empleados por cargo
  Future<Map<String, int>> getEmpleadosStatsByCargo() async {
    try {
      final empleados = await getAllEmpleados();
      final stats = <String, int>{};

      for (final empleado in empleados) {
        if (empleado.activo) {
          stats[empleado.cargo] = (stats[empleado.cargo] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo estadísticas: $e');
      }
      return {};
    }
  }
}
