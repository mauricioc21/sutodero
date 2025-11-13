import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/inventory_property.dart';
import '../models/property_room.dart';

/// Servicio para generar planos 3D isométricos
/// Utiliza vector_math para transformaciones 3D
class FloorPlan3DService {
  static const double _scale = 20.0; // 1 metro = 20 unidades
  static const double _wallHeight = 50.0; // Altura de paredes en unidades

  /// Generar plano 3D en vista isométrica
  Future<Uint8List> generate3DFloorPlan({
    required InventoryProperty property,
    required List<PropertyRoom> rooms,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(property),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: pw.Center(
                  child: _build3DFloorPlanWidget(rooms),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildLegend(rooms),
              _buildFooter(),
            ],
          ),
        ),
      );

      return pdf.save();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al generar plano 3D: $e');
      }
      rethrow;
    }
  }

  /// Construir encabezado del PDF
  pw.Widget _buildPdfHeader(InventoryProperty property) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#000000'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PLANO 3D ISOMÉTRICO',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FAB334'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                property.direccion,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromHex('#FFFFFF'),
                ),
              ),
              pw.Text(
                'Tipo: ${property.tipo}',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#F5E6C8'),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FAB334'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'SU TODERO',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#000000'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir widget de plano 3D
  pw.Widget _build3DFloorPlanWidget(List<PropertyRoom> rooms) {
    // Calcular dimensiones totales
    final layout = _calculateRoomLayout(rooms);
    final maxWidth = layout.values.map((pos) => pos.$1 + 1).reduce((a, b) => a > b ? a : b);
    final maxHeight = layout.values.map((pos) => pos.$2 + 1).reduce((a, b) => a > b ? a : b);

    final totalWidth = maxWidth * 150.0;
    final totalHeight = maxHeight * 150.0;

    return pw.Container(
      width: totalWidth,
      height: totalHeight,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          _draw3DFloorPlan(canvas, size, rooms, layout);
        },
      ),
    );
  }

  /// Dibujar plano 3D isométrico
  void _draw3DFloorPlan(
    PdfGraphics canvas,
    PdfPoint size,
    List<PropertyRoom> rooms,
    Map<String, (int, int)> layout,
  ) {
    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i];
      final position = layout[room.id];
      if (position == null) continue;

      final (col, row) = position;
      final roomWidth = (room.ancho ?? 3.0) * _scale;
      final roomDepth = (room.largo ?? 3.0) * _scale;

      // Calcular posición isométrica
      final x = col * 150.0 + 75.0;
      final y = row * 150.0 + 75.0;

      // Dibujar habitación en vista isométrica
      _drawIsometricRoom(
        canvas,
        x,
        y,
        roomWidth,
        roomDepth,
        _wallHeight,
        _getRoomColor(room.tipo.displayName),
        room.nombre,
      );
    }
  }

  /// Dibujar habitación en perspectiva isométrica
  void _drawIsometricRoom(
    PdfGraphics canvas,
    double x,
    double y,
    double width,
    double depth,
    double height,
    PdfColor color,
    String name,
  ) {

    // Calcular vértices de la caja isométrica
    // Base frontal inferior
    final p1 = _isometricPoint(x, y, 0, 0, 0);
    final p2 = _isometricPoint(x, y, width, 0, 0);
    final p3 = _isometricPoint(x, y, width, depth, 0);
    final p4 = _isometricPoint(x, y, 0, depth, 0);

    // Base frontal superior
    final p5 = _isometricPoint(x, y, 0, 0, height);
    final p6 = _isometricPoint(x, y, width, 0, height);
    final p7 = _isometricPoint(x, y, width, depth, height);
    final p8 = _isometricPoint(x, y, 0, depth, height);

    // Dibujar suelo (más oscuro)
    canvas
      ..setFillColor(color.shade(0.3))
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..lineTo(p4.x, p4.y)
      ..fillPath();

    // Dibujar pared frontal
    canvas
      ..setFillColor(color)
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p6.x, p6.y)
      ..lineTo(p5.x, p5.y)
      ..fillPath();

    // Dibujar pared lateral derecha
    canvas
      ..setFillColor(color.shade(0.2))
      ..moveTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..lineTo(p7.x, p7.y)
      ..lineTo(p6.x, p6.y)
      ..fillPath();

    // Dibujar techo
    canvas
      ..setFillColor(color.shade(0.5))
      ..moveTo(p5.x, p5.y)
      ..lineTo(p6.x, p6.y)
      ..lineTo(p7.x, p7.y)
      ..lineTo(p8.x, p8.y)
      ..fillPath();

    // Dibujar bordes
    canvas
      ..setStrokeColor(PdfColor.fromHex('#2C2C2C'))
      ..setLineWidth(1.5)
      // Base inferior
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..lineTo(p4.x, p4.y)
      ..lineTo(p1.x, p1.y)
      // Base superior
      ..moveTo(p5.x, p5.y)
      ..lineTo(p6.x, p6.y)
      ..lineTo(p7.x, p7.y)
      ..lineTo(p8.x, p8.y)
      ..lineTo(p5.x, p5.y)
      // Aristas verticales
      ..moveTo(p1.x, p1.y)
      ..lineTo(p5.x, p5.y)
      ..moveTo(p2.x, p2.y)
      ..lineTo(p6.x, p6.y)
      ..moveTo(p3.x, p3.y)
      ..lineTo(p7.x, p7.y)
      ..moveTo(p4.x, p4.y)
      ..lineTo(p8.x, p8.y)
      ..strokePath();

    // Nota: El texto no se puede dibujar directamente en CustomPaint de PDF
    // Se debe agregar con pw.Text en el widget principal
  }

  /// Convertir coordenadas 3D a proyección isométrica
  PdfPoint _isometricPoint(double baseX, double baseY, double x, double y, double z) {
    // Proyección isométrica: 30° en ambos ejes
    final isoX = baseX + (x - y) * 0.866; // cos(30°) ≈ 0.866
    final isoY = baseY + (x + y) * 0.5 - z; // sin(30°) = 0.5
    return PdfPoint(isoX, isoY);
  }

  /// Calcular distribución de habitaciones (grid 3 columnas)
  Map<String, (int, int)> _calculateRoomLayout(List<PropertyRoom> rooms) {
    final Map<String, (int, int)> layout = {};
    const maxColumns = 3;

    for (int i = 0; i < rooms.length; i++) {
      final col = i % maxColumns;
      final row = i ~/ maxColumns;
      layout[rooms[i].id] = (col, row);
    }

    return layout;
  }

  /// Obtener color por tipo de habitación
  PdfColor _getRoomColor(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('sala') || tipoLower.contains('living')) {
      return PdfColor.fromHex('#F5E6C8'); // Beige
    } else if (tipoLower.contains('cocina')) {
      return PdfColor.fromHex('#FFB347'); // Naranja claro
    } else if (tipoLower.contains('baño') || tipoLower.contains('bathroom')) {
      return PdfColor.fromHex('#87CEEB'); // Azul cielo
    } else if (tipoLower.contains('habitación') || tipoLower.contains('dormitorio') || tipoLower.contains('cuarto')) {
      return PdfColor.fromHex('#90EE90'); // Verde claro
    } else if (tipoLower.contains('garaje') || tipoLower.contains('garage')) {
      return PdfColor.fromHex('#D3D3D3'); // Gris claro
    } else {
      return PdfColor.fromHex('#FFE4B5'); // Beige moccasin
    }
  }

  /// Construir leyenda
  pw.Widget _buildLegend(List<PropertyRoom> rooms) {
    final uniqueTypes = rooms.map((r) => r.tipo.displayName).toSet().toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5E6C8'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#FAB334'), width: 2),
      ),
      child: pw.Wrap(
        spacing: 16,
        runSpacing: 8,
        children: uniqueTypes.map((tipoName) {
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: _getRoomColor(tipoName),
                  border: pw.Border.all(color: PdfColor.fromHex('#2C2C2C'), width: 1),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                tipoName,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#2C2C2C'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Construir pie de página
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#000000'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por SU TODERO',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#FAB334'),
            ),
          ),
          pw.Text(
            'Plano 3D Isométrico',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#F5E6C8'),
            ),
          ),
        ],
      ),
    );
  }
}
