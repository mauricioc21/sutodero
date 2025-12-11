import 'package:sutodero/utils/file_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/ticket_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // Nombre de la caja Hive para borradores
  static const String _draftsBoxName = 'report_drafts';

  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  /// Inicializar Hive (Llamar en main.dart)
  Future<void> init() async {
    // Nota: En una app real, aquí se registran los adaptadores generados
    // Hive.registerAdapter(MaestroReportAdapter());
    // ...
    await Hive.openBox<Map>(_draftsBoxName); // Usamos Map para evitar dependencia de generador en demo
  }

  /// 1. Crear Nuevo Reporte (Borrador Local)
  Future<MaestroReport> createDraft({
    required String maestroId,
    required String maestroNombre,
    required String titulo,
    required String descripcion,
    required ReportType type,
    required ReportCategory category,
    String? ticketId,
    String? ticketCodigo,
    List<String>? localImages, // Rutas locales
  }) async {
    final now = DateTime.now();
    final reportId = _uuid.v4();

    // Convertir rutas simples a objetos adjuntos
    List<ReportAttachment> adjuntos = [];
    if (localImages != null) {
      for (var path in localImages) {
        adjuntos.add(ReportAttachment(
          id: _uuid.v4(),
          localPath: path,
          type: 'image',
          createdAt: now,
        ));
      }
    }

    final report = MaestroReport(
      id: reportId,
      maestroId: maestroId,
      maestroNombre: maestroNombre,
      type: type,
      ticketId: ticketId,
      ticketCodigo: ticketCodigo,
      category: category,
      titulo: titulo,
      descripcion: descripcion,
      adjuntos: adjuntos,
      status: ReportStatus.borrador,
      fechaCreacion: now,
    );

    // Guardar en Hive (Local)
    final box = Hive.box<Map>(_draftsBoxName);
    await box.put(reportId, report.toMap()); // Guardamos como Map por simplicidad sin build_runner

    return report;
  }

  /// 2. Obtener Borradores (Local)
  Future<List<MaestroReport>> getDrafts(String maestroId) async {
    final box = Hive.box<Map>(_draftsBoxName);
    final drafts = box.values
        .map((map) => MaestroReport.fromMap(Map<String, dynamic>.from(map)))
        .where((r) => r.maestroId == maestroId)
        .toList();
    
    // Ordenar por fecha reciente
    drafts.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return drafts;
  }

  /// 3. Obtener Reportes Enviados (Cloud)
  Future<List<MaestroReport>> getSentReports(String maestroId) async {
    try {
      final snapshot = await _firestore
          .collection('maestro_reports')
          .where('maestroId', isEqualTo: maestroId)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MaestroReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error obteniendo reportes: $e');
      return [];
    }
  }

  /// 4. Sincronizar/Enviar Reporte
  Future<bool> sendReport(MaestroReport draft) async {
    try {
      // a. Subir adjuntos (Simulado)
      List<ReportAttachment> uploadedAttachments = [];
      for (var att in draft.adjuntos) {
        String? cloudUrl;
        if (att.localPath.isNotEmpty) {
           cloudUrl = await _uploadFile(att.localPath);
        }
        uploadedAttachments.add(ReportAttachment(
          id: att.id,
          localPath: att.localPath,
          cloudUrl: cloudUrl,
          type: att.type,
          createdAt: att.createdAt,
        ));
      }

      // b. Actualizar estado y fecha
      final reportToSend = MaestroReport(
        id: draft.id,
        maestroId: draft.maestroId,
        maestroNombre: draft.maestroNombre,
        type: draft.type,
        ticketId: draft.ticketId,
        ticketCodigo: draft.ticketCodigo,
        category: draft.category,
        titulo: draft.titulo,
        descripcion: draft.descripcion,
        adjuntos: uploadedAttachments,
        status: ReportStatus.pendiente, // Cambia a pendiente de revisión
        fechaCreacion: draft.fechaCreacion,
        fechaEnvio: DateTime.now(),
      );

      // c. Guardar en Firestore
      await _firestore.collection('maestro_reports').doc(draft.id).set(reportToSend.toMap());

      // d. Borrar de borradores locales
      final box = Hive.box<Map>(_draftsBoxName);
      await box.delete(draft.id);

      // e. Notificar Supervisor (Simulado)
      _notifySupervisor(reportToSend);

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error enviando reporte: $e');
      return false;
    }
  }

  /// 5. Eliminar Borrador
  Future<void> deleteDraft(String reportId) async {
    final box = Hive.box<Map>(_draftsBoxName);
    await box.delete(reportId);
  }

  // --- Helpers ---

  /// Simulación de subida a Storage
  Future<String> _uploadFile(String localPath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Retorna una URL simulada o la misma si ya es URL
    if (localPath.startsWith('http')) return localPath;
    return 'https://firebasestorage.googleapis.com/v0/b/app/o/${_uuid.v4()}.jpg';
  }

  /// Simulación de Notificación
  void _notifySupervisor(MaestroReport report) {
    if (kDebugMode) {
      print('🔔 NOTIFICACIÓN: Nuevo reporte de ${report.maestroNombre}: "${report.titulo}"');
    }
  }
}
