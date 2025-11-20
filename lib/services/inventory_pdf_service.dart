import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import '../models/inventory_property.dart';
import '../models/property_room.dart';
import '../config/brand_colors.dart';
import 'package:intl/intl.dart';

/// Servicio para generar PDFs de inventarios
class InventoryPdfService {
  static final InventoryPdfService _instance = InventoryPdfService._internal();
  factory InventoryPdfService() => _instance;
  InventoryPdfService._internal();

  /// Generar PDF completo de una propiedad con todos sus espacios
  Future<Uint8List> generatePropertyPdf(
    InventoryProperty property,
    List<PropertyRoom> rooms,
  ) async {
    final pdf = pw.Document();
    
    // Cargar logo corporativo Su Todero (NUEVO LOGO)
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle(BrandColors.logoMain);
      if (kDebugMode) {
        debugPrint('✅ Logo corporativo SU TODERO cargado exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar logo corporativo: $e');
      }
      // Intentar con logo amarillo como fallback
      try {
        logoImage = await imageFromAssetBundle(BrandColors.logoYellow);
        if (kDebugMode) {
          debugPrint('✅ Logo fallback (amarillo) cargado');
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar ningún logo: $e2');
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          _buildHeader(logoImage),
          pw.SizedBox(height: 20),
          
          // Título
          pw.Text(
            'REPORTE DE INVENTARIO',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FAB334'),
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          
          // Información de la propiedad
          _buildPropertySection(property),
          pw.SizedBox(height: 20),
          
          // Resumen de espacios
          _buildRoomsSummary(rooms),
          pw.SizedBox(height: 20),
          
          // Detalle de cada espacio
          ..._buildRoomsDetail(rooms),
          
          pw.Spacer(),
          
          // Pie de página
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generar PDF de un espacio individual
  Future<Uint8List> generateRoomPdf(
    InventoryProperty property,
    PropertyRoom room,
  ) async {
    final pdf = pw.Document();
    
    // Cargar logo corporativo Su Todero (NUEVO LOGO)
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle(BrandColors.logoMain);
      if (kDebugMode) {
        debugPrint('✅ Logo corporativo SU TODERO cargado exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar logo corporativo: $e');
      }
      // Intentar con logo amarillo como fallback
      try {
        logoImage = await imageFromAssetBundle(BrandColors.logoYellow);
        if (kDebugMode) {
          debugPrint('✅ Logo fallback (amarillo) cargado');
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar ningún logo: $e2');
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(logoImage),
          pw.SizedBox(height: 20),
          
          pw.Text(
            'REPORTE DE ESPACIO',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: BrandColors.primaryPdf, // Dorado corporativo
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          
          // Info de la propiedad (resumida)
          pw.Text(
            property.direccion,
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          
          // Detalle del espacio
          _buildRoomDetailSection(room),
          
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Construir encabezado
  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#000000'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Image(logo, height: 35, fit: pw.BoxFit.contain)
          else
            pw.Text(
              'SU TODERO',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#FAB334'),
              ),
            ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Gestión de Inventarios',
                style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#FFFFFF')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de información de propiedad
  pw.Widget _buildPropertySection(InventoryProperty property) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Información de la Propiedad',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#000000'),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Tipo:', property.tipo.displayName),
              _buildInfoRow('Dirección:', property.direccion),
              if (property.clienteNombre != null)
                _buildInfoRow('Cliente:', property.clienteNombre!),
              if (property.clienteTelefono != null)
                _buildInfoRow('Teléfono:', property.clienteTelefono!),
              if (property.area != null)
                _buildInfoRow('Área:', '${property.area!.toStringAsFixed(1)} m²'),
              if (property.numeroHabitaciones != null)
                _buildInfoRow('Habitaciones:', '${property.numeroHabitaciones}'),
              if (property.numeroBanos != null)
                _buildInfoRow('Baños:', '${property.numeroBanos}'),
              if (property.descripcion != null)
                _buildInfoRow('Descripción:', property.descripcion!),
              _buildInfoRow('Fecha de registro:', _formatDate(property.fechaCreacion)),
            ],
          ),
        ),
      ],
    );
  }

  /// Resumen de espacios
  pw.Widget _buildRoomsSummary(List<PropertyRoom> rooms) {
    final porEstado = <SpaceCondition, int>{};
    for (var room in rooms) {
      porEstado[room.estado] = (porEstado[room.estado] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen de Espacios (${rooms.length} total)',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#000000'),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey100,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: SpaceCondition.values.map((condition) {
              final count = porEstado[condition] ?? 0;
              if (count == 0) return pw.SizedBox();
              
              return pw.Column(
                children: [
                  pw.Text(
                    '${condition.emoji} ${condition.displayName}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '$count',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _getConditionColor(condition),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Detalle de espacios
  List<pw.Widget> _buildRoomsDetail(List<PropertyRoom> rooms) {
    if (rooms.isEmpty) {
      return [
        pw.Text(
          'No hay espacios registrados',
          style: const pw.TextStyle(color: PdfColors.grey),
        ),
      ];
    }

    return rooms.map((room) {
      return pw.Column(
        children: [
          _buildRoomDetailSection(room),
          pw.SizedBox(height: 16),
        ],
      );
    }).toList();
  }

  /// Sección de detalle de un espacio
  pw.Widget _buildRoomDetailSection(PropertyRoom room) {
    final area = (room.ancho != null && room.largo != null)
        ? (room.ancho! * room.largo!).toStringAsFixed(2)
        : 'N/A';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${room.tipo.icon} ${room.nombre}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            _buildConditionBadge(room.estado),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Tipo:', room.tipo.displayName),
              _buildInfoRow('Dimensiones:', 
                  '${room.ancho?.toStringAsFixed(2) ?? 'N/A'} × ${room.largo?.toStringAsFixed(2) ?? 'N/A'} m'),
              _buildInfoRow('Área:', '$area m²'),
              if (room.altura != null)
                _buildInfoRow('Altura:', '${room.altura!.toStringAsFixed(2)} m'),
              if (room.descripcion != null)
                _buildInfoRow('Descripción:', room.descripcion!),
              if (room.problemas.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Problemas detectados:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      ...room.problemas.map((problema) => pw.Text('• $problema')),
                    ],
                  ),
                ),
              if (room.observaciones != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: _buildInfoRow('Observaciones:', room.observaciones!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge de condición
  pw.Widget _buildConditionBadge(SpaceCondition condition) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _getConditionColor(condition),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        '${condition.emoji} ${condition.displayName}',
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
      ),
    );
  }

  /// Color según condición
  PdfColor _getConditionColor(SpaceCondition condition) {
    switch (condition) {
      case SpaceCondition.excelente:
        return PdfColors.green;
      case SpaceCondition.bueno:
        return PdfColors.blue;
      case SpaceCondition.regular:
        return PdfColors.orange;
      case SpaceCondition.malo:
        return PdfColors.deepOrange;
      case SpaceCondition.critico:
        return PdfColors.red;
    }
  }

  /// Fila de información
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  /// Pie de página
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('#FAB334'), width: 2),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'SU TODERO - Gestión Profesional de Inventarios',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#000000'),
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Cra 14b #112-85 Segundo Piso, Bogotá, Colombia | Tel: (601) 703-9495 | www.sutodero.com',
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#2C2C2C')),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#2C2C2C')),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es').format(date);
  }

  /// Compartir PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error compartiendo PDF: $e');
      }
      rethrow;
    }
  }
}
