/// Roles disponibles en el sistema
enum UserRole {
  administrador('Administrador'),
  coordinador('Coordinador'),
  maestro('Maestro'),
  inventarios('Inventarios'),
  duppla('Duppla');

  final String displayName;
  const UserRole(this.displayName);

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'administrador':
      case 'admin':
        return UserRole.administrador;
      case 'coordinador':
        return UserRole.coordinador;
      case 'maestro':
      case 'tecnico':
        return UserRole.maestro;
      case 'inventarios':
        return UserRole.inventarios;
      case 'duppla':
        return UserRole.duppla;
      default:
        return UserRole.maestro; // Por defecto
    }
  }

  String get value {
    return name;
  }
}

class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'administrador', 'coordinador', 'maestro', 'inventarios', 'duppla'
  final String telefono;
  final String? direccion;
  final String? genero; // 'masculino', 'femenino', 'otro'
  final String? photoURL; // URL de la foto de perfil
  final DateTime? fechaCreacion;
  final bool activo;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.telefono,
    this.direccion,
    this.genero,
    this.photoURL,
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
      'genero': genero,
      'photoURL': photoURL,
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
      genero: map['genero'],
      photoURL: map['photoURL'],
      fechaCreacion: map['fechaCreacion']?.toDate(),
      activo: map['activo'] ?? true,
    );
  }

  /// Detecta el género basado en el nombre (heurística simple)
  String detectarGenero() {
    // Si el usuario ya tiene género definido, usarlo
    if (genero != null && genero!.isNotEmpty) {
      return genero!;
    }
    
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
  
  /// Obtener el rol como enum
  UserRole get roleEnum => UserRole.fromString(rol);
  
  /// Alias para roleEnum (para compatibilidad)
  UserRole get userRole => roleEnum;
  
  /// Verifica si el usuario es administrador
  bool get isAdministrador => roleEnum == UserRole.administrador;
  
  /// Verifica si el usuario es coordinador
  bool get isCoordinador => roleEnum == UserRole.coordinador;
  
  /// Verifica si el usuario es maestro
  bool get isMaestro => roleEnum == UserRole.maestro;
  
  /// Verifica si el usuario es de inventarios
  bool get isInventarios => roleEnum == UserRole.inventarios;
  
  /// Verifica si el usuario es de Duppla
  bool get isDuppla => roleEnum == UserRole.duppla;
  
  /// Verifica si el usuario tiene acceso administrativo
  bool get hasAdminAccess => isAdministrador || isCoordinador;
  
  /// Verifica si el usuario puede gestionar tickets
  bool get canManageTickets => isAdministrador || isCoordinador || isMaestro;
  
  /// Verifica si el usuario puede gestionar inventarios
  bool get canManageInventories => isAdministrador || isInventarios;
  
  /// Verifica si el usuario puede gestionar captaciones
  bool get canManageCaptaciones => isAdministrador || isCoordinador || isDuppla;
  
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
    String? genero,
    String? photoURL,
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
      genero: genero ?? this.genero,
      photoURL: photoURL ?? this.photoURL,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
    );
  }
}
