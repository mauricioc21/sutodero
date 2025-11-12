import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/property_room.dart';
import '../models/inventory_property.dart';

/// Servicio para generar planos 2D automáticos desde datos de inventario
class FloorPlanService {
  static final FloorPlanService _instance = FloorPlanService._internal();
  factory FloorPlanService() => _instance;
  FloorPlanService._internal();

  /// Genera un plano 2D en formato PDF
  Future<Uint8List> generateFloorPlanPdf({
    required InventoryProperty property,
    required List<PropertyRoom> rooms,
  }) async {
    final pdf = pw.Document();

    // Calcular layout automático
    final layout = _calculateRoomLayout(rooms);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            _buildPdfHeader(property),
            pw.SizedBox(height: 20),

            // Plano 2D
            pw.Expanded(
              child: _buildFloorPlanWidget(layout, rooms),
            ),

            pw.SizedBox(height: 16),

            // Leyenda
            _buildLegend(rooms),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Header del PDF
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
                'PLANO 2D - ${property.tipo}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FFD700'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                property.direccion,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#F5E6C8'),
                ),
              ),
            ],
          ),
          pw.Text(
            'SU TODERO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FFD700'),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula layout automático de habitaciones
  Map<String, RoomLayoutInfo> _calculateRoomLayout(List<PropertyRoom> rooms) {
    final layout = <String, RoomLayoutInfo>{};
    
    // Ordenar habitaciones por área (más grandes primero)
    final sortedRooms = List<PropertyRoom>.from(rooms)
      ..sort((a, b) {
        final areaA = (a.ancho ?? 3.0) * (a.largo ?? 3.0);
        final areaB = (b.ancho ?? 3.0) * (b.largo ?? 3.0);
        return areaB.compareTo(areaA);
      });

    // Grid simple: 3 columnas máximo
    const maxColumns = 3;
    double currentX = 0;
    double currentY = 0;
    double rowHeight = 0;
    int columnCount = 0;

    for (final room in sortedRooms) {
      final width = (room.ancho ?? 3.0) * 20; // Escala: 1m = 20 unidades
      final height = (room.largo ?? 3.0) * 20;

      // Nueva fila si alcanzamos el máximo de columnas
      if (columnCount >= maxColumns) {
        currentX = 0;
        currentY += rowHeight + 10; // 10 unidades de separación
        rowHeight = 0;
        columnCount = 0;
      }

      layout[room.id] = RoomLayoutInfo(
        x: currentX,
        y: currentY,
        width: width,
        height: height,
        room: room,
      );

      currentX += width + 10; // 10 unidades de separación
      rowHeight = height > rowHeight ? height : rowHeight;
      columnCount++;
    }

    return layout;
  }

  /// Construye el widget del plano
  pw.Widget _buildFloorPlanWidget(
    Map<String, RoomLayoutInfo> layout,
    List<PropertyRoom> rooms,
  ) {
    // Calcular dimensiones totales
    double maxX = 0;
    double maxY = 0;
    for (final info in layout.values) {
      if (info.x + info.width > maxX) maxX = info.x + info.width;
      if (info.y + info.height > maxY) maxY = info.y + info.height;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5E6C8'),
        border: pw.Border.all(color: PdfColor.fromHex('#2C2C2C'), width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Stack(
        children: layout.values.map((info) {
          return pw.Positioned(
            left: info.x + 20,
            top: info.y + 20,
            child: _buildRoomBox(info),
          );
        }).toList(),
      ),
    );
  }

  /// Construye una caja de habitación
  pw.Widget _buildRoomBox(RoomLayoutInfo info) {
    final room = info.room;
    final color = _getRoomColor(room.nombre);

    return pw.Container(
      width: info.width,
      height: info.height,
      decoration: pw.BoxDecoration(
        color: color,
        border: pw.Border.all(color: PdfColor.fromHex('#000000'), width: 2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              room.nombre,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${room.ancho?.toStringAsFixed(1) ?? "?"} × ${room.largo?.toStringAsFixed(1) ?? "?"} m',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene color según tipo de habitación
  PdfColor _getRoomColor(String nombreHabitacion) {
    final nombre = nombreHabitacion.toLowerCase();
    
    if (nombre.contains('sala') || nombre.contains('living')) {
      return PdfColor.fromHex('#FFE5B4'); // Beige claro
    } else if (nombre.contains('cocina')) {
      return PdfColor.fromHex('#FFD9B3'); // Naranja claro
    } else if (nombre.contains('baño') || nombre.contains('sanitario')) {
      return PdfColor.fromHex('#B3E5FF'); // Azul claro
    } else if (nombre.contains('habitación') || nombre.contains('dormitorio') || nombre.contains('cuarto')) {
      return PdfColor.fromHex('#E5FFB3'); // Verde claro
    } else if (nombre.contains('garaje') || nombre.contains('estacionamiento')) {
      return PdfColor.fromHex('#D9D9D9'); // Gris claro
    } else {
      return PdfColor.fromHex('#FFFFFF'); // Blanco
    }
  }

  /// Construye la leyenda
  pw.Widget _buildLegend(List<PropertyRoom> rooms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2C2C2C'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LEYENDA',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FFD700'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Sala/Living', PdfColor.fromHex('#FFE5B4')),
              _buildLegendItem('Cocina', PdfColor.fromHex('#FFD9B3')),
              _buildLegendItem('Baño', PdfColor.fromHex('#B3E5FF')),
              _buildLegendItem('Habitación', PdfColor.fromHex('#E5FFB3')),
              _buildLegendItem('Garaje', PdfColor.fromHex('#D9D9D9')),
              _buildLegendItem('Otros', PdfColors.white),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Total de espacios: ${rooms.length}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#F5E6C8'),
            ),
          ),
        ],
      ),
    );
  }

  /// Item de leyenda
  pw.Widget _buildLegendItem(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 16,
          height: 16,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(color: PdfColors.black),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#F5E6C8'),
          ),
        ),
      ],
    );
  }
}

/// Información de layout de una habitación
class RoomLayoutInfo {
  final double x;
  final double y;
  final double width;
  final double height;
  final PropertyRoom room;

  RoomLayoutInfo({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.room,
  });
}
