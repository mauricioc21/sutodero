import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Empleado (sin cuenta de usuario)
/// Representa empleados que trabajan para Su Todero pero no necesitan acceso a la app
class EmpleadoModel {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String cargo; // rol del empleado (maestro, coordinador, etc.)
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final bool activo;
  final String? notas;

  EmpleadoModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.cargo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.activo = true,
    this.notas,
  });

  /// Convertir desde Map (Firestore)
  factory EmpleadoModel.fromMap(Map<String, dynamic> map, String id) {
    return EmpleadoModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      cargo: map['cargo'] as String? ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activo: map['activo'] as bool? ?? true,
      notas: map['notas'] as String?,
    );
  }

  /// Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'cargo': cargo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
      'activo': activo,
      'notas': notas,
    };
  }

  /// Crear una copia con cambios
  EmpleadoModel copyWith({
    String? id,
    String? nombre,
    String? correo,
    String? telefono,
    String? cargo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
    String? notas,
  }) {
    return EmpleadoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      cargo: cargo ?? this.cargo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
      notas: notas ?? this.notas,
    );
  }

  @override
  String toString() {
    return 'EmpleadoModel(id: $id, nombre: $nombre, cargo: $cargo, correo: $correo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmpleadoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
