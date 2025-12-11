import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'report_model.g.dart'; // For Hive generator

/// Tipo de Reporte
@HiveType(typeId: 1)
enum ReportType {
  @HiveField(0)
  general,
  @HiveField(1)
  ticket_specific,
}

/// Estado del Reporte
@HiveType(typeId: 2)
enum ReportStatus {
  @HiveField(0)
  borrador,      // Guardado localmente, no enviado
  @HiveField(1)
  pendiente,     // Enviado, esperando revisión
  @HiveField(2)
  en_revision,   // Supervisor lo está viendo
  @HiveField(3)
  aprobado,      // Aceptado
  @HiveField(4)
  rechazado,     // Rechazado completamente
  @HiveField(5)
  requiere_ajustes, // Devuelto para correcciones
}

/// Categoría del Reporte
@HiveType(typeId: 3)
enum ReportCategory {
  @HiveField(0)
  avance_obra,
  @HiveField(1)
  dano_estructural,
  @HiveField(2)
  electricidad,
  @HiveField(3)
  plomeria,
  @HiveField(4)
  imprevisto,
  @HiveField(5)
  retraso,
  @HiveField(6)
  solicitud_cliente,
  @HiveField(7)
  trabajo_no_realizado, // Motivo de no ejecución
  @HiveField(8)
  otro,
}

extension ReportCategoryExtension on ReportCategory {
  String get displayName {
    switch (this) {
      case ReportCategory.avance_obra: return 'Avance de Obra';
      case ReportCategory.dano_estructural: return 'Daño Estructural';
      case ReportCategory.electricidad: return 'Electricidad';
      case ReportCategory.plomeria: return 'Plomería';
      case ReportCategory.imprevisto: return 'Imprevisto';
      case ReportCategory.retraso: return 'Retraso / Bloqueo';
      case ReportCategory.solicitud_cliente: return 'Solicitud Adicional Cliente';
      case ReportCategory.trabajo_no_realizado: return 'Trabajo No Realizado';
      case ReportCategory.otro: return 'Otro';
    }
  }
}

/// Modelo de Archivo Adjunto (Foto, Video, Audio)
@HiveType(typeId: 4)
class ReportAttachment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String localPath; // Ruta en el dispositivo
  @HiveField(2)
  final String? cloudUrl; // URL en Firebase Storage (si ya se subió)
  @HiveField(3)
  final String type; // 'image', 'video', 'audio'
  @HiveField(4)
  final DateTime createdAt;

  ReportAttachment({
    required this.id,
    required this.localPath,
    this.cloudUrl,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localPath': localPath, // Nota: Local paths no sirven en nube, solo cloudUrl
      'cloudUrl': cloudUrl,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportAttachment.fromMap(Map<String, dynamic> map) {
    return ReportAttachment(
      id: map['id'] ?? '',
      localPath: map['localPath'] ?? '', 
      cloudUrl: map['cloudUrl'],
      type: map['type'] ?? 'image',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

/// Modelo Principal de Reporte
@HiveType(typeId: 5)
class MaestroReport {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String maestroId;
  @HiveField(2)
  final String maestroNombre;
  @HiveField(3)
  final ReportType type;
  @HiveField(4)
  final String? ticketId; // Opcional, solo para reportes específicos
  @HiveField(5)
  final String? ticketCodigo; // Para visualización rápida
  @HiveField(6)
  final ReportCategory category;
  @HiveField(7)
  final String titulo; // Resumen corto
  @HiveField(8)
  final String descripcion; // Detalle completo (qué pasó, solución, faltantes)
  @HiveField(9)
  final List<ReportAttachment> adjuntos;
  @HiveField(10)
  final ReportStatus status;
  @HiveField(11)
  final DateTime fechaCreacion;
  @HiveField(12)
  final DateTime? fechaEnvio;
  @HiveField(13)
  final DateTime? fechaRevision;
  @HiveField(14)
  final String? notasSupervisor; // Feedback del supervisor

  MaestroReport({
    required this.id,
    required this.maestroId,
    required this.maestroNombre,
    required this.type,
    this.ticketId,
    this.ticketCodigo,
    required this.category,
    required this.titulo,
    required this.descripcion,
    required this.adjuntos,
    required this.status,
    required this.fechaCreacion,
    this.fechaEnvio,
    this.fechaRevision,
    this.notasSupervisor,
  });

  /// Copia para inmutabilidad y actualizaciones
  MaestroReport copyWith({
    String? titulo,
    String? descripcion,
    ReportCategory? category,
    List<ReportAttachment>? adjuntos,
    ReportStatus? status,
    DateTime? fechaEnvio,
  }) {
    return MaestroReport(
      id: id,
      maestroId: maestroId,
      maestroNombre: maestroNombre,
      type: type,
      ticketId: ticketId,
      ticketCodigo: ticketCodigo,
      category: category ?? this.category,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      adjuntos: adjuntos ?? this.adjuntos,
      status: status ?? this.status,
      fechaCreacion: fechaCreacion,
      fechaEnvio: fechaEnvio ?? this.fechaEnvio,
      fechaRevision: fechaRevision,
      notasSupervisor: notasSupervisor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maestroId': maestroId,
      'maestroNombre': maestroNombre,
      'type': type.toString().split('.').last,
      'ticketId': ticketId,
      'ticketCodigo': ticketCodigo,
      'category': category.toString().split('.').last,
      'titulo': titulo,
      'descripcion': descripcion,
      'adjuntos': adjuntos.map((x) => x.toMap()).toList(),
      'status': status.toString().split('.').last,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaEnvio': fechaEnvio != null ? Timestamp.fromDate(fechaEnvio!) : null,
      'fechaRevision': fechaRevision != null ? Timestamp.fromDate(fechaRevision!) : null,
      'notasSupervisor': notasSupervisor,
    };
  }

  factory MaestroReport.fromMap(Map<String, dynamic> map) {
    return MaestroReport(
      id: map['id'] ?? '',
      maestroId: map['maestroId'] ?? '',
      maestroNombre: map['maestroNombre'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ReportType.general,
      ),
      ticketId: map['ticketId'],
      ticketCodigo: map['ticketCodigo'],
      category: ReportCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => ReportCategory.otro,
      ),
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      adjuntos: (map['adjuntos'] as List<dynamic>?)
          ?.map((x) => ReportAttachment.fromMap(x))
          .toList() ?? [],
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ReportStatus.borrador,
      ),
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaEnvio: map['fechaEnvio'] != null ? (map['fechaEnvio'] as Timestamp).toDate() : null,
      fechaRevision: map['fechaRevision'] != null ? (map['fechaRevision'] as Timestamp).toDate() : null,
      notasSupervisor: map['notasSupervisor'],
    );
  }
}
