import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

class CreateReportScreen extends StatefulWidget {
  final String? ticketId; // Opcional, si viene desde un ticket específico
  final String? ticketCodigo;
  final MaestroReport? draftToEdit; // Si editamos un borrador

  const CreateReportScreen({
    Key? key,
    this.ticketId,
    this.ticketCodigo,
    this.draftToEdit,
  }) : super(key: key);

  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  
  ReportType _selectedType = ReportType.general;
  ReportCategory _selectedCategory = ReportCategory.avance_obra;
  List<String> _attachedImages = []; // Rutas locales
  bool _isSaving = false;

  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    // Inicializar valores si es edición o nuevo
    if (widget.draftToEdit != null) {
      _titleCtrl = TextEditingController(text: widget.draftToEdit!.titulo);
      _descCtrl = TextEditingController(text: widget.draftToEdit!.descripcion);
      _selectedType = widget.draftToEdit!.type;
      _selectedCategory = widget.draftToEdit!.category;
      _attachedImages = widget.draftToEdit!.adjuntos.map((a) => a.localPath).toList();
    } else {
      _titleCtrl = TextEditingController();
      _descCtrl = TextEditingController();
      // Si viene con ticket ID, preseleccionar tipo
      if (widget.ticketId != null) {
        _selectedType = ReportType.ticket_specific;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _attachedImages.add(picked.path);
      });
    }
  }

  Future<void> _saveReport({bool sendNow = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_attachedImages.isEmpty && sendNow) {
      // Opcional: Validar que tenga al menos una foto si envía
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Adjunta al menos una evidencia')));
      // return; 
    }

    setState(() => _isSaving = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    
    try {
      // 1. Crear/Actualizar Borrador
      // Si era edición de borrador, primero borramos el viejo para recrearlo (o update)
      if (widget.draftToEdit != null) {
        await _reportService.deleteDraft(widget.draftToEdit!.id);
      }

      final draft = await _reportService.createDraft(
        maestroId: user!.uid,
        maestroNombre: user.nombre,
        titulo: _titleCtrl.text,
        descripcion: _descCtrl.text,
        type: _selectedType,
        category: _selectedCategory,
        ticketId: widget.ticketId ?? widget.draftToEdit?.ticketId,
        ticketCodigo: widget.ticketCodigo ?? widget.draftToEdit?.ticketCodigo,
        localImages: _attachedImages,
      );

      if (sendNow) {
        final success = await _reportService.sendReport(draft);
        if (success) {
           if (mounted) Navigator.pop(context, true); // Retorna true para refrescar
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado al supervisor')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error enviando. Se guardó como borrador.')));
           if (mounted) Navigator.pop(context, false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrador guardado')));
        if (mounted) Navigator.pop(context, false);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.draftToEdit != null ? 'Editar Borrador' : 'Nuevo Reporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Guardar Borrador',
            onPressed: _isSaving ? null : () => _saveReport(sendNow: false),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de Reporte
              DropdownButtonFormField<ReportType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo de Reporte', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: ReportType.general, child: Text('General')),
                  DropdownMenuItem(value: ReportType.ticket_specific, child: Text('Específico de Ticket')),
                ],
                onChanged: widget.ticketId != null 
                    ? null // Si viene de ticket, bloquear cambio
                    : (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<ReportCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: ReportCategory.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.displayName));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Asunto / Título', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción Detallada', 
                  hintText: '¿Qué pasó? ¿Qué encontraste? ¿Qué falta?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Evidencia Multimedia
              const Text('Evidencia (Fotos)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Botón Cámara
                    _buildAddButton(Icons.camera_alt, () => _pickImage(ImageSource.camera)),
                    const SizedBox(width: 8),
                    // Botón Galería
                    _buildAddButton(Icons.photo_library, () => _pickImage(ImageSource.gallery)),
                    const SizedBox(width: 8),
                    // Lista de fotos
                    ..._attachedImages.map((path) => _buildImageThumbnail(path)).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveReport(sendNow: true),
            icon: const Icon(Icons.send),
            label: Text(_isSaving ? 'PROCESANDO...' : 'ENVIAR REPORTE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Icon(icon, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildImageThumbnail(String path) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: () {
                setState(() {
                  _attachedImages.remove(path);
                });
              },
              child: Container(
                color: Colors.black54,
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          )
        ],
      ),
    );
  }
}
