import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Asegúrate de tener esta dependencia o usa Iconos manuales
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/evaluation_model.dart';
import '../../models/ticket_model.dart';
import '../../services/evaluation_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

class EvaluationFormScreen extends StatefulWidget {
  final TicketModel ticket;

  const EvaluationFormScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  _EvaluationFormScreenState createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EvaluationService _evalService = EvaluationService();

  // Ratings (1-5)
  double _puntualidad = 0;
  double _calidad = 0;
  double _limpieza = 0;
  double _profesionalismo = 0;

  bool _recontrataria = true;
  final TextEditingController _commentCtrl = TextEditingController();
  List<String> _evidencePhotos = []; // Paths locales
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_puntualidad == 0 || _calidad == 0 || _limpieza == 0 || _profesionalismo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor califica todos los criterios')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    try {
      final criteria = RatingCriteria(
        puntualidad: _puntualidad.toInt(),
        calidadTrabajo: _calidad.toInt(),
        limpieza: _limpieza.toInt(),
        profesionalismo: _profesionalismo.toInt(),
      );

      final evaluation = MaestroEvaluation(
        id: const Uuid().v4(),
        ticketId: widget.ticket.id,
        ticketCodigo: widget.ticket.codigo,
        maestroId: widget.ticket.maestroId ?? '',
        maestroNombre: widget.ticket.maestroNombre ?? 'Maestro',
        evaluadorId: user?.uid ?? 'anon',
        evaluadorNombre: user?.nombre ?? 'Cliente',
        evaluadorRol: EvaluatorRole.cliente, // Lógica para detectar si es supervisor
        criterios: criteria,
        promedioFinal: criteria.average,
        recontrataria: _recontrataria,
        comentario: _commentCtrl.text,
        fotosEvidencia: _evidencePhotos, // En prod subir a Storage primero
        fechaEvaluacion: DateTime.now(),
      );

      final result = await _evalService.submitEvaluation(evaluation);

      if (result['success']) {
        if (mounted) {
          Navigator.pop(context, true); // Retorna éxito
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('¡Gracias por tu evaluación!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _evidencePhotos.add(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluar Servicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.dorado,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text('Maestro: ${widget.ticket.maestroNombre ?? "N/A"}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Ticket: ${widget.ticket.codigo}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating Sections
            _buildRatingRow('Puntualidad', _puntualidad, (v) => setState(() => _puntualidad = v)),
            _buildRatingRow('Calidad del Trabajo', _calidad, (v) => setState(() => _calidad = v)),
            _buildRatingRow('Limpieza y Orden', _limpieza, (v) => setState(() => _limpieza = v)),
            _buildRatingRow('Profesionalismo', _profesionalismo, (v) => setState(() => _profesionalismo = v)),
            
            const Divider(height: 32),

            // Recontratar Switch
            SwitchListTile(
              title: const Text('¿Recontrataría a este Maestro?', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _recontrataria,
              activeColor: Colors.green,
              onChanged: (v) => setState(() => _recontrataria = v),
            ),

            const SizedBox(height: 16),

            // Comentarios
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comentarios adicionales (Opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Evidencia
            const Text('Evidencia del Resultado (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidencePhotos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_evidencePhotos[index]), width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: Colors.black,
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator()
                    : const Text('ENVIAR EVALUACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          RatingBar.builder(
            initialRating: value,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false, // Simplificado a enteros
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: onChanged,
          ),
        ],
      ),
    );
  }
}
