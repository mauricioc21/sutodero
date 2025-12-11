import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/evaluation_model.dart';
import '../models/ticket_model.dart'; // Para actualizar flag en ticket

class EvaluationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final EvaluationService _instance = EvaluationService._internal();
  factory EvaluationService() => _instance;
  EvaluationService._internal();

  /// POST /evaluacion/crear
  /// Crea una evaluación y actualiza estadísticas del maestro
  Future<Map<String, dynamic>> submitEvaluation(MaestroEvaluation eval) async {
    try {
      // 1. Guardar la evaluación
      await _firestore.collection('evaluations').doc(eval.id).set(eval.toMap());

      // 2. Marcar ticket como evaluado (para no duplicar)
      await _firestore.collection('tickets').doc(eval.ticketId).update({
        'isEvaluated': true, // Campo nuevo sugerido en TicketModel
        'evaluationId': eval.id,
      });

      // 3. Actualizar estadísticas del maestro (Incremental o Recalculado)
      await _updateMaestroStats(eval.maestroId);

      return {'success': true, 'message': 'Evaluación registrada con éxito'};
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error submitEvaluation: $e');
      return {'success': false, 'message': 'Error al guardar evaluación'};
    }
  }

  /// GET /evaluacion/ticket/:id
  Future<MaestroEvaluation?> getEvaluationByTicket(String ticketId) async {
    try {
      final snapshot = await _firestore
          .collection('evaluations')
          .where('ticketId', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MaestroEvaluation.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /evaluacion/maestro/:id (Lista histórica)
  Future<List<MaestroEvaluation>> getMaestroEvaluations(String maestroId) async {
    try {
      final snapshot = await _firestore
          .collection('evaluations')
          .where('maestroId', isEqualTo: maestroId)
          .orderBy('fechaEvaluacion', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => MaestroEvaluation.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// GET Stats (Helper interno o endpoint dashboard)
  Future<MaestroStats> getMaestroStats(String maestroId) async {
    // En una app real de alto tráfico, esto se leería de un documento 'maestro_stats'
    // pre-calculado por Cloud Functions. Aquí lo calculamos on-demand para la demo.
    
    // Si ya existe la colección agregada:
    final doc = await _firestore.collection('maestro_stats').doc(maestroId).get();
    if (doc.exists) {
      // Retornar objeto mapeado (simplificado aquí calculamos manual para asegurar datos frescos en demo)
    }
    
    // Recálculo manual (demo)
    final evals = await getMaestroEvaluations(maestroId);
    if (evals.isEmpty) return MaestroStats.empty(maestroId);

    double sumGeneral = 0;
    int sumPunt = 0;
    int sumCalidad = 0;
    int sumLimp = 0;
    int sumProf = 0;
    int siCount = 0;

    for (var e in evals) {
      sumGeneral += e.promedioFinal;
      sumPunt += e.criterios.puntualidad;
      sumCalidad += e.criterios.calidadTrabajo;
      sumLimp += e.criterios.limpieza;
      sumProf += e.criterios.profesionalismo;
      if (e.recontrataria) siCount++;
    }

    final total = evals.length;
    return MaestroStats(
      maestroId: maestroId,
      totalEvaluaciones: total,
      promedioGeneral: sumGeneral / total,
      promedioPuntualidad: sumPunt / total,
      promedioCalidad: sumCalidad / total,
      promedioLimpieza: sumLimp / total,
      promedioProfesionalismo: sumProf / total,
      totalRecontratariaSi: siCount,
    );
  }

  /// Helper privado para actualizar estadísticas
  Future<void> _updateMaestroStats(String maestroId) async {
    // En producción: Cloud Function triggers onWrite.
    // Aquí: Cliente recalcula (no ideal pero funcional para demo).
    final stats = await getMaestroStats(maestroId);
    
    await _firestore.collection('maestro_stats').doc(maestroId).set({
      'totalEvaluaciones': stats.totalEvaluaciones,
      'promedioGeneral': stats.promedioGeneral,
      'lastUpdate': FieldValue.serverTimestamp(),
      // ... otros campos
    });
  }
}
