import 'package:cloud_firestore/cloud_firestore.dart';

/// Rol del evaluador
enum EvaluatorRole {
  cliente,
  supervisor,
  admin,
}

/// Criterios específicos de evaluación
class RatingCriteria {
  final int puntualidad; // 1-5
  final int calidadTrabajo; // 1-5
  final int limpieza; // 1-5
  final int profesionalismo; // 1-5
  
  RatingCriteria({
    required this.puntualidad,
    required this.calidadTrabajo,
    required this.limpieza,
    required this.profesionalismo,
  });

  Map<String, dynamic> toMap() => {
    'puntualidad': puntualidad,
    'calidadTrabajo': calidadTrabajo,
    'limpieza': limpieza,
    'profesionalismo': profesionalismo,
  };

  factory RatingCriteria.fromMap(Map<String, dynamic> map) {
    return RatingCriteria(
      puntualidad: map['puntualidad'] ?? 0,
      calidadTrabajo: map['calidadTrabajo'] ?? 0,
      limpieza: map['limpieza'] ?? 0,
      profesionalismo: map['profesionalismo'] ?? 0,
    );
  }

  double get average => (puntualidad + calidadTrabajo + limpieza + profesionalismo) / 4.0;
}

/// Modelo de Evaluación
class MaestroEvaluation {
  final String id;
  final String ticketId;
  final String ticketCodigo;
  final String maestroId;
  final String maestroNombre;
  final String evaluadorId;
  final String evaluadorNombre;
  final EvaluatorRole evaluadorRol;
  
  final RatingCriteria criterios;
  final double promedioFinal; // Calculado
  final bool recontrataria;
  final String? comentario;
  final List<String> fotosEvidencia; // URLs
  
  final DateTime fechaEvaluacion;

  MaestroEvaluation({
    required this.id,
    required this.ticketId,
    required this.ticketCodigo,
    required this.maestroId,
    required this.maestroNombre,
    required this.evaluadorId,
    required this.evaluadorNombre,
    required this.evaluadorRol,
    required this.criterios,
    required this.promedioFinal,
    required this.recontrataria,
    this.comentario,
    this.fotosEvidencia = const [],
    required this.fechaEvaluacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'ticketCodigo': ticketCodigo,
      'maestroId': maestroId,
      'maestroNombre': maestroNombre,
      'evaluadorId': evaluadorId,
      'evaluadorNombre': evaluadorNombre,
      'evaluadorRol': evaluadorRol.toString().split('.').last,
      'criterios': criterios.toMap(),
      'promedioFinal': promedioFinal,
      'recontrataria': recontrataria,
      'comentario': comentario,
      'fotosEvidencia': fotosEvidencia,
      'fechaEvaluacion': Timestamp.fromDate(fechaEvaluacion),
    };
  }

  factory MaestroEvaluation.fromMap(Map<String, dynamic> map) {
    return MaestroEvaluation(
      id: map['id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      ticketCodigo: map['ticketCodigo'] ?? '',
      maestroId: map['maestroId'] ?? '',
      maestroNombre: map['maestroNombre'] ?? '',
      evaluadorId: map['evaluadorId'] ?? '',
      evaluadorNombre: map['evaluadorNombre'] ?? '',
      evaluadorRol: EvaluatorRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['evaluadorRol'],
        orElse: () => EvaluatorRole.cliente,
      ),
      criterios: RatingCriteria.fromMap(map['criterios'] ?? {}),
      promedioFinal: (map['promedioFinal'] ?? 0).toDouble(),
      recontrataria: map['recontrataria'] ?? true,
      comentario: map['comentario'],
      fotosEvidencia: List<String>.from(map['fotosEvidencia'] ?? []),
      fechaEvaluacion: (map['fechaEvaluacion'] as Timestamp).toDate(),
    );
  }
}

/// Modelo de Estadísticas Agregadas del Maestro
class MaestroStats {
  final String maestroId;
  final int totalEvaluaciones;
  final double promedioGeneral;
  final double promedioPuntualidad;
  final double promedioCalidad;
  final double promedioLimpieza;
  final double promedioProfesionalismo;
  final int totalRecontratariaSi;

  MaestroStats({
    required this.maestroId,
    required this.totalEvaluaciones,
    required this.promedioGeneral,
    required this.promedioPuntualidad,
    required this.promedioCalidad,
    required this.promedioLimpieza,
    required this.promedioProfesionalismo,
    required this.totalRecontratariaSi,
  });

  factory MaestroStats.empty(String maestroId) {
    return MaestroStats(
      maestroId: maestroId,
      totalEvaluaciones: 0,
      promedioGeneral: 0,
      promedioPuntualidad: 0,
      promedioCalidad: 0,
      promedioLimpieza: 0,
      promedioProfesionalismo: 0,
      totalRecontratariaSi: 0,
    );
  }
}
