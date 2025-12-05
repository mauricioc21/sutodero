import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget de diálogo para capturar firma digital táctil
class SignaturePadDialog extends StatefulWidget {
  final String title;
  
  const SignaturePadDialog({
    super.key,
    this.title = 'Firma Digital',
  });

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<Offset?> _points = [];
  bool _isEmpty = true;
  final GlobalKey _signatureKey = GlobalKey();

  void _clear() {
    setState(() {
      _points.clear();
      _isEmpty = true;
    });
  }

  Future<String?> _getSignatureAsBase64() async {
    if (_isEmpty || _points.isEmpty) {
      return null;
    }

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          const Offset(0.0, 0.0),
          const Offset(400.0, 200.0),
        ),
      );

      // Fondo blanco
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 400, 200),
        paint,
      );

      // Dibujar la firma
      final signaturePaint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, signaturePaint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 200);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      return base64Encode(buffer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar firma: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Instrucciones
            const Text(
              'Traza tu firma con el dedo o lápiz táctil',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Canvas de firma con GlobalKey
            Container(
              key: _signatureKey,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: GestureDetector(
                  onPanStart: (details) {
                    final RenderBox? renderBox = _signatureKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                      setState(() {
                        _points.add(localPosition);
                        _isEmpty = false;
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    final RenderBox? renderBox = _signatureKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                      setState(() {
                        _points.add(localPosition);
                        _isEmpty = false;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _points.add(null);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.white,
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: const Size(double.infinity, 200),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Limpiar
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),

                // Botón Cancelar
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('Cancelar'),
                ),

                // Botón Aceptar
                ElevatedButton.icon(
                  onPressed: _isEmpty
                      ? null
                      : () async {
                          final base64 = await _getSignatureAsBase64();
                          if (mounted && base64 != null) {
                            Navigator.of(context).pop(base64);
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
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

/// Custom Painter para dibujar la firma
class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
