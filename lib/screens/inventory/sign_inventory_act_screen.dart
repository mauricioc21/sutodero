import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/inventory_act.dart';
import '../../services/inventory_act_service.dart';

/// Pantalla para firmar y autenticar acta de inventario
/// con reconocimiento facial
class SignInventoryActScreen extends StatefulWidget {
  final InventoryAct act;

  const SignInventoryActScreen({
    super.key,
    required this.act,
  });

  @override
  State<SignInventoryActScreen> createState() => _SignInventoryActScreenState();
}

class _SignInventoryActScreenState extends State<SignInventoryActScreen> {
  final InventoryActService _actService = InventoryActService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final ImagePicker _imagePicker = ImagePicker();
  
  File? _facialPhoto;
  Uint8List? _signatureBytes;
  bool _isLoading = false;
  bool _signatureCompleted = false;
  bool _facialCompleted = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _captureFacialPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _facialPhoto = File(photo.path);
          _facialCompleted = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Foto de reconocimiento facial capturada'),
              backgroundColor: Color(0xFFFFD700),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor, firme el acta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final signature = await _signatureController.toPngBytes();
    if (signature != null) {
      setState(() {
        _signatureBytes = signature;
        _signatureCompleted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Firma capturada correctamente'),
            backgroundColor: Color(0xFFFFD700),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureBytes = null;
      _signatureCompleted = false;
    });
  }

  Future<void> _completeAct() async {
    if (!_signatureCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debe capturar la firma digital'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_facialCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debe capturar foto de reconocimiento facial'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Subir firma digital
      final signatureFile = await _saveBytesToFile(_signatureBytes!, 'signature.png');
      final signatureUrl = await _actService.uploadSignature(widget.act.id, signatureFile);

      // 2. Subir foto facial
      final facialUrl = await _actService.uploadFacialRecognition(widget.act.id, _facialPhoto!);

      // 3. Actualizar acta con URLs
      await _actService.updateAuthentication(
        actId: widget.act.id,
        signatureUrl: signatureUrl,
        facialUrl: facialUrl,
      );

      // 4. Completar acta
      final completedAct = await _actService.completeAct(widget.act.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Acta completada: ${completedAct.validationCode}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Regresar con el acta completada
        Navigator.pop(context, completedAct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar acta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<File> _saveBytesToFile(Uint8List bytes, String filename) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      appBar: AppBar(
        title: const Text('Firmar Acta de Inventario'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          if (_signatureCompleted && _facialCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _isLoading ? null : _completeAct,
              tooltip: 'Completar Acta',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 24),
                  Text(
                    'Procesando autenticación...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del acta
                  _buildActInfo(),
                  const SizedBox(height: 24),

                  // Sección de Firma Digital
                  _buildSignatureSection(),
                  const SizedBox(height: 24),

                  // Sección de Reconocimiento Facial
                  _buildFacialSection(),
                  const SizedBox(height: 32),

                  // Botón de completar
                  _buildCompleteButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildActInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Color(0xFFFF6B00)),
              const SizedBox(width: 8),
              Text(
                'Acta de Inventario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Código:', widget.act.validationCode ?? 'N/A'),
          _buildInfoRow('Propiedad:', widget.act.propertyAddress),
          _buildInfoRow('Cliente:', widget.act.clientName),
          if (widget.act.clientIdNumber != null)
            _buildInfoRow('ID:', widget.act.clientIdNumber!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _signatureCompleted ? Icons.check_circle : Icons.edit,
                color: _signatureCompleted ? Colors.green : const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 8),
              Text(
                'Firma Digital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (!_signatureCompleted)
                TextButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _signatureCompleted ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.grey.shade50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!_signatureCompleted)
            ElevatedButton.icon(
              onPressed: _saveSignature,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Firma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Firma capturada correctamente',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFacialSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _facialCompleted ? Icons.check_circle : Icons.face,
                color: _facialCompleted ? Colors.green : const Color(0xFFFF6B00),
              ),
              const SizedBox(width: 8),
              const Text(
                'Reconocimiento Facial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_facialPhoto != null)
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  _facialPhoto!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Capture su rostro para\nautenticar el acta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (!_facialCompleted)
            ElevatedButton.icon(
              onPressed: _captureFacialPhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capturar Rostro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rostro capturado',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _facialPhoto = null;
                      _facialCompleted = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  color: Colors.orange,
                  tooltip: 'Tomar nueva foto',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    final canComplete = _signatureCompleted && _facialCompleted;

    return ElevatedButton.icon(
      onPressed: canComplete && !_isLoading ? _completeAct : null,
      icon: const Icon(Icons.check_circle, size: 28),
      label: const Text(
        'COMPLETAR Y AUTENTICAR ACTA',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canComplete ? const Color(0xFFFFD700) : Colors.grey,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
