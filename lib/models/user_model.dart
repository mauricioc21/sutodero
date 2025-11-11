class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'admin', 'tecnico', 'cliente'
  final String telefono;
  final DateTime? fechaCreacion;
  final bool activo;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.telefono,
    this.fechaCreacion,
    this.activo = true,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'telefono': telefono,
      'fechaCreacion': fechaCreacion ?? DateTime.now(),
      'activo': activo,
    };
  }

  // Crear desde Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'cliente',
      telefono: map['telefono'] ?? '',
      fechaCreacion: map['fechaCreacion']?.toDate(),
      activo: map['activo'] ?? true,
    );
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? nombre,
    String? email,
    String? rol,
    String? telefono,
    DateTime? fechaCreacion,
    bool? activo,
  }) {
    return UserModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
    );
  }
}
