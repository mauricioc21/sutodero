class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'admin', 'tecnico', 'cliente'
  final String telefono;
  final String? direccion;
  final String? photoUrl;
  final DateTime? fechaCreacion;
  final bool activo;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.telefono,
    this.direccion,
    this.photoUrl,
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
      'direccion': direccion,
      'photoUrl': photoUrl,
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
      direccion: map['direccion'],
      photoUrl: map['photoUrl'],
      fechaCreacion: map['fechaCreacion']?.toDate(),
      activo: map['activo'] ?? true,
    );
  }

  /// Detecta el género basado en el nombre (heurística simple)
  String detectarGenero() {
    final nombreLower = nombre.toLowerCase();
    
    // Lista de nombres comunes masculinos
    final nombresMasculinos = [
      'juan', 'carlos', 'josé', 'jose', 'luis', 'miguel', 'pedro', 'antonio',
      'francisco', 'javier', 'fernando', 'jorge', 'ricardo', 'roberto',
      'daniel', 'david', 'sergio', 'alberto', 'rafael', 'mauricio', 'andrés',
      'andres', 'pablo', 'manuel', 'alejandro', 'diego', 'mario', 'raúl',
      'raul', 'eduardo', 'oscar', 'héctor', 'hector', 'guillermo',
    ];
    
    // Lista de nombres comunes femeninos
    final nombresFemeninos = [
      'maría', 'maria', 'carmen', 'ana', 'isabel', 'laura', 'patricia',
      'rosa', 'teresa', 'marta', 'sandra', 'cristina', 'elena', 'silvia',
      'pilar', 'beatriz', 'luisa', 'mónica', 'monica', 'paula', 'diana',
      'andrea', 'carolina', 'natalia', 'verónica', 'veronica', 'mariana',
      'gabriela', 'catalina', 'valentina', 'juliana', 'camila', 'daniela',
      'marcela', 'lorena',
    ];
    
    // Obtener primer nombre
    final primerNombre = nombreLower.split(' ').first;
    
    // Verificar si está en alguna lista
    if (nombresMasculinos.contains(primerNombre)) {
      return 'masculino';
    } else if (nombresFemeninos.contains(primerNombre)) {
      return 'femenino';
    }
    
    // Heurística adicional: terminaciones comunes
    if (primerNombre.endsWith('a') && !primerNombre.endsWith('ia')) {
      return 'femenino';
    } else if (primerNombre.endsWith('o') || 
               primerNombre.endsWith('os') ||
               primerNombre.endsWith('ez')) {
      return 'masculino';
    }
    
    // Por defecto, usar neutro
    return 'neutro';
  }
  
  /// Verifica si el usuario es administrador
  bool get isAdmin => rol.toLowerCase() == 'admin';
  
  /// Verifica si el usuario es técnico
  bool get isTecnico => rol.toLowerCase() == 'tecnico';
  
  /// Verifica si el usuario es cliente
  bool get isCliente => rol.toLowerCase() == 'cliente';
  
  /// Genera un saludo personalizado según el género y hora del día
  String obtenerSaludoPersonalizado() {
    final genero = detectarGenero();
    final hora = DateTime.now().hour;
    
    String saludo;
    if (hora >= 5 && hora < 12) {
      saludo = 'Buenos días';
    } else if (hora >= 12 && hora < 19) {
      saludo = 'Buenas tardes';
    } else {
      saludo = 'Buenas noches';
    }
    
    String tratamiento;
    switch (genero) {
      case 'masculino':
        tratamiento = 'Bienvenido';
        break;
      case 'femenino':
        tratamiento = 'Bienvenida';
        break;
      default:
        tratamiento = 'Bienvenido/a';
    }
    
    // Obtener solo el primer nombre para el saludo
    final primerNombre = nombre.split(' ').first;
    
    return '$saludo, $tratamiento $primerNombre';
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? nombre,
    String? email,
    String? rol,
    String? telefono,
    String? direccion,
    String? photoUrl,
    DateTime? fechaCreacion,
    bool? activo,
  }) {
    return UserModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      photoUrl: photoUrl ?? this.photoUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
    );
  }
}
