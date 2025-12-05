import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para Actas (Entrega y Recibido)
class ActaModel {
  final String id;
  final String propertyId;
  final String propertyAddress;
  final String propertyType;
  final String tipoActa; // 'entrega' o 'recibido'
  
  // Datos del arrendatario
  final String arrendatarioNombre;
  final String arrendatarioCedula;
  final String fecha;
  
  // Novedades
  final List<String> novedades;
  
  // Firmas (base64)
  final String? firmaRecibido;
  final String? firmaEntrega;
  
  // Estado del PDF
  final String? pdfUrl;
  final bool pdfGenerado;
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  ActaModel({
    required this.id,
    required this.propertyId,
    required this.propertyAddress,
    required this.propertyType,
    required this.tipoActa,
    required this.arrendatarioNombre,
    required this.arrendatarioCedula,
    required this.fecha,
    required this.novedades,
    this.firmaRecibido,
    this.firmaEntrega,
    this.pdfUrl,
    this.pdfGenerado = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde Firestore
  factory ActaModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ActaModel(
      id: id,
      propertyId: data['propertyId'] ?? '',
      propertyAddress: data['propertyAddress'] ?? '',
      propertyType: data['propertyType'] ?? '',
      tipoActa: data['tipoActa'] ?? 'entrega',
      arrendatarioNombre: data['arrendatarioNombre'] ?? '',
      arrendatarioCedula: data['arrendatarioCedula'] ?? '',
      fecha: data['fecha'] ?? '',
      novedades: List<String>.from(data['novedades'] ?? []),
      firmaRecibido: data['firmaRecibido'],
      firmaEntrega: data['firmaEntrega'],
      pdfUrl: data['pdfUrl'],
      pdfGenerado: data['pdfGenerado'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'propertyAddress': propertyAddress,
      'propertyType': propertyType,
      'tipoActa': tipoActa,
      'arrendatarioNombre': arrendatarioNombre,
      'arrendatarioCedula': arrendatarioCedula,
      'fecha': fecha,
      'novedades': novedades,
      'firmaRecibido': firmaRecibido,
      'firmaEntrega': firmaEntrega,
      'pdfUrl': pdfUrl,
      'pdfGenerado': pdfGenerado,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Crear copia con modificaciones
  ActaModel copyWith({
    String? id,
    String? propertyId,
    String? propertyAddress,
    String? propertyType,
    String? tipoActa,
    String? arrendatarioNombre,
    String? arrendatarioCedula,
    String? fecha,
    List<String>? novedades,
    String? firmaRecibido,
    String? firmaEntrega,
    String? pdfUrl,
    bool? pdfGenerado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActaModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyType: propertyType ?? this.propertyType,
      tipoActa: tipoActa ?? this.tipoActa,
      arrendatarioNombre: arrendatarioNombre ?? this.arrendatarioNombre,
      arrendatarioCedula: arrendatarioCedula ?? this.arrendatarioCedula,
      fecha: fecha ?? this.fecha,
      novedades: novedades ?? this.novedades,
      firmaRecibido: firmaRecibido ?? this.firmaRecibido,
      firmaEntrega: firmaEntrega ?? this.firmaEntrega,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfGenerado: pdfGenerado ?? this.pdfGenerado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
