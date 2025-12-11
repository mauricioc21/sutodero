import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/evaluation_model.dart';
import '../../services/evaluation_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

class MaestroPerformanceScreen extends StatefulWidget {
  final String maestroId; // Puede ser el ID del usuario logueado o de otro maestro (vista admin)

  const MaestroPerformanceScreen({Key? key, required this.maestroId}) : super(key: key);

  @override
  _MaestroPerformanceScreenState createState() => _MaestroPerformanceScreenState();
}

class _MaestroPerformanceScreenState extends State<MaestroPerformanceScreen> {
  final EvaluationService _evalService = EvaluationService();
  bool _isLoading = true;
  MaestroStats? _stats;
  List<MaestroEvaluation> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _evalService.getMaestroStats(widget.maestroId);
    final history = await _evalService.getMaestroEvaluations(widget.maestroId);
    
    setState(() {
      _stats = stats;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Desempeño')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen General
            _buildSummaryCard(),
            const SizedBox(height: 20),
            
            // Desglose por Categoría
            const Text('Desglose por Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildCategoryBreakdown(),
            
            const SizedBox(height: 20),
            
            // Historial Reciente
            const Text('Últimas Evaluaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_stats == null) return const SizedBox();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROMEDIO GENERAL', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Row(
                  children: [
                    Text(
                      _stats!.promedioGeneral.toStringAsFixed(1),
                      style: const TextStyle(color: AppTheme.dorado, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: AppTheme.dorado, size: 30),
                  ],
                ),
                Text('${_stats!.totalEvaluaciones} Evaluaciones', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Recontratación', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(
                    '${(_stats!.totalEvaluaciones > 0 ? (_stats!.totalRecontratariaSi / _stats!.totalEvaluaciones * 100) : 0).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_stats == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgressBar('Puntualidad', _stats!.promedioPuntualidad),
            const SizedBox(height: 12),
            _buildProgressBar('Calidad', _stats!.promedioCalidad),
            const SizedBox(height: 12),
            _buildProgressBar('Limpieza', _stats!.promedioLimpieza),
            const SizedBox(height: 12),
            _buildProgressBar('Profesionalismo', _stats!.promedioProfesionalismo),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 5,
          backgroundColor: Colors.grey[200],
          color: value >= 4.0 ? Colors.green : (value >= 3.0 ? Colors.orange : Colors.red),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) return const Text('No hay evaluaciones recientes');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final eval = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: eval.promedioFinal >= 4 ? Colors.green[100] : Colors.orange[100],
              child: Text(eval.promedioFinal.toStringAsFixed(1), 
                  style: TextStyle(fontWeight: FontWeight.bold, color: eval.promedioFinal >= 4 ? Colors.green : Colors.orange)),
            ),
            title: Text('Ticket: ${eval.ticketCodigo}'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(eval.fechaEvaluacion)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eval.comentario != null && eval.comentario!.isNotEmpty)
                      Text('"${eval.comentario}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildMiniBadge('Punt', eval.criterios.puntualidad),
                        _buildMiniBadge('Cal', eval.criterios.calidadTrabajo),
                        _buildMiniBadge('Limp', eval.criterios.limpieza),
                        _buildMiniBadge('Prof', eval.criterios.profesionalismo),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMiniBadge(String text, int val) {
    return Chip(
      label: Text('$text: $val'),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey[100],
      padding: EdgeInsets.zero,
    );
  }
}
