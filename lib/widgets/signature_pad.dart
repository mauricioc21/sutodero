import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Widget para capturar firmas digitales
class SignaturePadDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  
  const SignaturePadDialog({
    super.key,
    required this.title,
    this.subtitle = 'Firme dentro del recuadro',
  });

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _getSignatureBase64() async {
    if (_controller.isEmpty) {
      return null;
    }

    try {
      final Uint8List? signature = await _controller.toPngBytes();
      if (signature == null) return null;
      
      return base64Encode(signature);
    } catch (e) {
      debugPrint('Error al obtener firma: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Área de firma
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Limpiar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.clear();
                    },
                    icon: const Icon(Icons.clear, color: Colors.white),
                    label: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón Cancelar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón Confirmar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_controller.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, dibuje su firma'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      final signatureBase64 = await _getSignatureBase64();
                      if (!context.mounted) return;
                      
                      Navigator.of(context).pop(signatureBase64);
                    },
                    icon: const Icon(Icons.check, color: Colors.black),
                    label: const Text(
                      'Confirmar',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Función helper para mostrar el diálogo de firma
Future<String?> showSignaturePad({
  required BuildContext context,
  required String title,
  String subtitle = 'Firme dentro del recuadro',
}) async {
  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SignaturePadDialog(
      title: title,
      subtitle: subtitle,
    ),
  );
}
