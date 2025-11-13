import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Tipos de entidad para QR
enum QREntityType {
  property,
  room,
  ticket,
}

/// Datos del QR Code
class QRData {
  final QREntityType type;
  final String id;
  final Map<String, dynamic>? metadata;

  QRData({
    required this.type,
    required this.id,
    this.metadata,
  });

  /// Convertir a JSON string para el QR
  String toQRString() {
    return jsonEncode({
      'type': type.name,
      'id': id,
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Crear desde JSON string del QR
  factory QRData.fromQRString(String qrString) {
    final Map<String, dynamic> data = jsonDecode(qrString);
    return QRData(
      type: QREntityType.values.firstWhere((e) => e.name == data['type']),
      id: data['id'],
      metadata: data['metadata'],
    );
  }
}

/// Servicio para gestionar códigos QR
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  /// Generar código QR para una propiedad
  String generatePropertyQR(String propertyId, {String? direccion}) {
    return QRData(
      type: QREntityType.property,
      id: propertyId,
      metadata: direccion != null ? {'direccion': direccion} : null,
    ).toQRString();
  }

  /// Generar código QR para un espacio/habitación
  String generateRoomQR(String roomId, String propertyId, {String? nombre}) {
    return QRData(
      type: QREntityType.room,
      id: roomId,
      metadata: {
        'propertyId': propertyId,
        if (nombre != null) 'nombre': nombre,
      },
    ).toQRString();
  }

  /// Generar código QR para un ticket
  String generateTicketQR(String ticketId, {String? titulo}) {
    return QRData(
      type: QREntityType.ticket,
      id: ticketId,
      metadata: titulo != null ? {'titulo': titulo} : null,
    ).toQRString();
  }

  /// Parsear datos del QR escaneado
  QRData? parseQRCode(String qrString) {
    try {
      return QRData.fromQRString(qrString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error parseando QR: $e');
      }
      return null;
    }
  }

  /// Generar imagen del QR code
  Future<Uint8List?> generateQRImage(
    String data, {
    double size = 300,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: foregroundColor,
        emptyColor: backgroundColor,
        gapless: true,
      );

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..color = backgroundColor;

      canvas.drawRect(Rect.fromLTWH(0, 0, size, size), paint);
      qrPainter.paint(canvas, Size(size, size));

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error generando imagen QR: $e');
      }
      return null;
    }
  }

  /// Mostrar diálogo con QR code
  Future<void> showQRDialog(
    BuildContext context, {
    required String data,
    required String title,
    String? subtitle,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFAB334),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Compartir
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final imageBytes = await generateQRImage(data);
                        if (imageBytes != null && context.mounted) {
                          // TODO: Implementar compartir imagen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR generado (compartir próximamente)'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share, color: Colors.black),
                      label: const Text(
                        'Compartir',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAB334),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Botón Cerrar
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Cerrar',
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validar formato de QR
  bool isValidQRFormat(String qrString) {
    try {
      final data = jsonDecode(qrString);
      return data.containsKey('type') && data.containsKey('id');
    } catch (e) {
      return false;
    }
  }

  /// Obtener descripción legible del tipo de QR
  String getQRTypeDescription(QREntityType type) {
    switch (type) {
      case QREntityType.property:
        return 'Propiedad';
      case QREntityType.room:
        return 'Espacio/Habitación';
      case QREntityType.ticket:
        return 'Ticket de Trabajo';
    }
  }
}
