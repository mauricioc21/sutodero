import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para perfiles predefinidos de maestros
class MaestroProfileModel {
  final String id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? especialidad;
  final String? foto; // URL de la foto de perfil
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  MaestroProfileModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.especialidad,
    this.foto,
    this.activo = true,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'especialidad': especialidad,
      'foto': foto,
      'activo': activo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
    };
  }

  /// Crear desde Map de Firestore
  factory MaestroProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return MaestroProfileModel(
      id: id,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'],
      especialidad: map['especialidad'],
      foto: map['foto'],
      activo: map['activo'] ?? true,
      fechaCreacion: (map['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copiar con modificaciones
  MaestroProfileModel copyWith({
    String? nombre,
    String? telefono,
    String? email,
    String? especialidad,
    String? foto,
    bool? activo,
    DateTime? fechaActualizacion,
  }) {
    return MaestroProfileModel(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      especialidad: especialidad ?? this.especialidad,
      foto: foto ?? this.foto,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
