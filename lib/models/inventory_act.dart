import 'inventory_property.dart';

/// Modelo de Acta de Inventario
/// Documento oficial que registra el estado completo de un inmueble
/// con autenticación mediante firma digital y reconocimiento facial
class InventoryAct {
  String id;
  String propertyId;
  
  // Información del inmueble (referencia)
  String propertyAddress;
  PropertyType propertyType;
  String? propertyDescription;
  
  // Información del cliente
  String clientName;
  String? clientPhone;
  String? clientEmail;
  String? clientIdNumber; // Número de identificación
  
  // Detalles del inventario
  String? observations;
  List<String> roomIds; // IDs de espacios incluidos
  List<String> photoUrls; // URLs de fotos del inventario completo
  
  // Autenticación y firma
  String? digitalSignatureUrl; // URL de la firma digital capturada
  String? facialRecognitionUrl; // URL de foto de reconocimiento facial
  DateTime? signatureTimestamp; // Momento exacto de la firma
  String? signatureLocation; // Coordenadas GPS opcionales
  
  // Persona que realiza el acta
  String createdBy; // ID del usuario que crea el acta
  String? createdByName; // Nombre de quien realiza el inventario
  String? createdByRole; // Rol (ej: "Inspector", "Administrador")
  
  // Metadatos
  DateTime createdAt;
  DateTime? updatedAt;
  bool isCompleted; // Si el acta está firmada y completada
  bool isPdfGenerated; // Si ya se generó el PDF
  String? pdfUrl; // URL del PDF generado
  
  // Validación
  String? validationCode; // Código único de validación del acta
  String? authenticationHash; // Hash de autenticación (firma + facial)

  InventoryAct({
    required this.id,
    required this.propertyId,
    required this.propertyAddress,
    required this.propertyType,
    this.propertyDescription,
    required this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientIdNumber,
    this.observations,
    List<String>? roomIds,
    List<String>? photoUrls,
    this.digitalSignatureUrl,
    this.facialRecognitionUrl,
    this.signatureTimestamp,
    this.signatureLocation,
    required this.createdBy,
    this.createdByName,
    this.createdByRole,
    DateTime? createdAt,
    this.updatedAt,
    this.isCompleted = false,
    this.isPdfGenerated = false,
    this.pdfUrl,
    this.validationCode,
    this.authenticationHash,
  })  : roomIds = roomIds ?? [],
        photoUrls = photoUrls ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Genera un código de validación único
  static String generateValidationCode() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 100000).toString().padLeft(5, '0');
    return 'ACT-${now.year}${now.month.toString().padLeft(2, '0')}$random';
  }

  /// Genera hash de autenticación basado en firma y facial
  String generateAuthenticationHash() {
    final components = [
      id,
      propertyId,
      clientName,
      clientIdNumber ?? '',
      signatureTimestamp?.toIso8601String() ?? '',
      digitalSignatureUrl ?? '',
      facialRecognitionUrl ?? '',
    ];
    return components.join('|').hashCode.toString();
  }

  /// Verifica si el acta está lista para completarse
  bool get canComplete {
    return digitalSignatureUrl != null && 
           facialRecognitionUrl != null &&
           clientName.isNotEmpty;
  }

  /// Marca el acta como completada
  InventoryAct complete() {
    if (!canComplete) {
      throw Exception('Acta no puede completarse: faltan firma o reconocimiento facial');
    }
    
    return copyWith(
      isCompleted: true,
      signatureTimestamp: DateTime.now(),
      validationCode: validationCode ?? generateValidationCode(),
      authenticationHash: generateAuthenticationHash(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convierte a Map para JSON/Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyAddress': propertyAddress,
      'propertyType': propertyType.name,
      'propertyDescription': propertyDescription,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'clientIdNumber': clientIdNumber,
      'observations': observations,
      'roomIds': roomIds,
      'photoUrls': photoUrls,
      'digitalSignatureUrl': digitalSignatureUrl,
      'facialRecognitionUrl': facialRecognitionUrl,
      'signatureTimestamp': signatureTimestamp?.toIso8601String(),
      'signatureLocation': signatureLocation,
      'createdBy': createdBy,
      'userId': createdBy, // Compatibilidad con reglas antiguas de Firestore
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'isPdfGenerated': isPdfGenerated,
      'pdfUrl': pdfUrl,
      'validationCode': validationCode,
      'authenticationHash': authenticationHash,
    };
  }

  /// Crea desde Map (JSON/Firebase)
  factory InventoryAct.fromMap(Map<String, dynamic> map) {
    return InventoryAct(
      id: map['id'] ?? '',
      propertyId: map['propertyId'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == map['propertyType'],
        orElse: () => PropertyType.casa,
      ),
      propertyDescription: map['propertyDescription'],
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'],
      clientEmail: map['clientEmail'],
      clientIdNumber: map['clientIdNumber'],
      observations: map['observations'],
      roomIds: List<String>.from(map['roomIds'] ?? []),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      digitalSignatureUrl: map['digitalSignatureUrl'],
      facialRecognitionUrl: map['facialRecognitionUrl'],
      signatureTimestamp: map['signatureTimestamp'] != null
          ? DateTime.parse(map['signatureTimestamp'])
          : null,
      signatureLocation: map['signatureLocation'],
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'],
      createdByRole: map['createdByRole'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
      isPdfGenerated: map['isPdfGenerated'] ?? false,
      pdfUrl: map['pdfUrl'],
      validationCode: map['validationCode'],
      authenticationHash: map['authenticationHash'],
    );
  }

  /// Copia con modificaciones
  InventoryAct copyWith({
    String? id,
    String? propertyId,
    String? propertyAddress,
    PropertyType? propertyType,
    String? propertyDescription,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientIdNumber,
    String? observations,
    List<String>? roomIds,
    List<String>? photoUrls,
    String? digitalSignatureUrl,
    String? facialRecognitionUrl,
    DateTime? signatureTimestamp,
    String? signatureLocation,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
    bool? isPdfGenerated,
    String? pdfUrl,
    String? validationCode,
    String? authenticationHash,
  }) {
    return InventoryAct(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyType: propertyType ?? this.propertyType,
      propertyDescription: propertyDescription ?? this.propertyDescription,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientIdNumber: clientIdNumber ?? this.clientIdNumber,
      observations: observations ?? this.observations,
      roomIds: roomIds ?? this.roomIds,
      photoUrls: photoUrls ?? this.photoUrls,
      digitalSignatureUrl: digitalSignatureUrl ?? this.digitalSignatureUrl,
      facialRecognitionUrl: facialRecognitionUrl ?? this.facialRecognitionUrl,
      signatureTimestamp: signatureTimestamp ?? this.signatureTimestamp,
      signatureLocation: signatureLocation ?? this.signatureLocation,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isPdfGenerated: isPdfGenerated ?? this.isPdfGenerated,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      validationCode: validationCode ?? this.validationCode,
      authenticationHash: authenticationHash ?? this.authenticationHash,
    );
  }
}
