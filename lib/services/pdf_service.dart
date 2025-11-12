import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';

/// Servicio para generar PDFs de tickets
class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// Generar PDF completo del ticket
  Future<Uint8List> generateTicketPdf(TicketModel ticket) async {
    final pdf = pw.Document();
    
    // Cargar logo si existe
    pw.ImageProvider? logoImage;
    try {
      // Intentar cargar el logo de la app
      logoImage = await imageFromAssetBundle('assets/icons/app_icon.png');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar el logo: $e');
      }
    }

    // Convertir firmas de Base64 a ImageProvider si existen
    pw.ImageProvider? firmaClienteImage;
    pw.ImageProvider? firmaToderoImage;
    
    if (ticket.firmaCliente != null) {
      try {
        final bytes = base64Decode(ticket.firmaCliente!);
        firmaClienteImage = pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error decodificando firma cliente: $e');
        }
      }
    }
    
    if (ticket.firmaTodero != null) {
      try {
        final bytes = base64Decode(ticket.firmaTodero!);
        firmaToderoImage = pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error decodificando firma todero: $e');
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado con logo
          _buildHeader(logoImage),
          pw.SizedBox(height: 20),
          
          // Título del documento
          pw.Text(
            'ORDEN DE TRABAJO',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          
          // ID del ticket y estado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ticket #${ticket.id.substring(0, 8)}'),
              _buildStatusBadge(ticket.estado),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.orange),
          pw.SizedBox(height: 20),
          
          // Información del ticket
          _buildSection('Información del Servicio', [
            _buildInfoRow('Título:', ticket.titulo),
            _buildInfoRow('Descripción:', ticket.descripcion),
            _buildInfoRow('Tipo de Servicio:', ticket.tipoServicio.displayName),
            _buildInfoRow('Prioridad:', ticket.prioridad.displayName),
            if (ticket.presupuestoEstimado != null)
              _buildInfoRow('Presupuesto Estimado:', '\$${ticket.presupuestoEstimado!.toStringAsFixed(0)}'),
            if (ticket.costoFinal != null)
              _buildInfoRow('Costo Final:', '\$${ticket.costoFinal!.toStringAsFixed(0)}'),
          ]),
          pw.SizedBox(height: 15),
          
          // Información del cliente
          _buildSection('Datos del Cliente', [
            _buildInfoRow('Nombre:', ticket.clienteNombre),
            if (ticket.clienteTelefono != null)
              _buildInfoRow('Teléfono:', ticket.clienteTelefono!),
            if (ticket.clienteEmail != null)
              _buildInfoRow('Email:', ticket.clienteEmail!),
          ]),
          pw.SizedBox(height: 15),
          
          // Información del todero (si está asignado)
          if (ticket.toderoNombre != null)
            _buildSection('Datos del Todero', [
              _buildInfoRow('Nombre:', ticket.toderoNombre!),
            ]),
          if (ticket.toderoNombre != null)
            pw.SizedBox(height: 15),
          
          // Información de la propiedad (si existe)
          if (ticket.propiedadDireccion != null)
            _buildSection('Ubicación', [
              _buildInfoRow('Dirección:', ticket.propiedadDireccion!),
              if (ticket.espacioNombre != null)
                _buildInfoRow('Espacio:', ticket.espacioNombre!),
            ]),
          if (ticket.propiedadDireccion != null)
            pw.SizedBox(height: 15),
          
          // Fechas
          _buildSection('Fechas', [
            _buildInfoRow('Creación:', _formatDate(ticket.fechaCreacion)),
            if (ticket.fechaProgramada != null)
              _buildInfoRow('Programada:', _formatDate(ticket.fechaProgramada!)),
            if (ticket.fechaInicio != null)
              _buildInfoRow('Inicio:', _formatDate(ticket.fechaInicio!)),
            if (ticket.fechaCompletado != null)
              _buildInfoRow('Completado:', _formatDate(ticket.fechaCompletado!)),
          ]),
          pw.SizedBox(height: 15),
          
          // Notas
          if (ticket.notasCliente != null || ticket.notasTodero != null)
            _buildSection('Notas y Observaciones', [
              if (ticket.notasCliente != null)
                _buildInfoRow('Notas del Cliente:', ticket.notasCliente!),
              if (ticket.notasTodero != null)
                _buildInfoRow('Notas del Todero:', ticket.notasTodero!),
            ]),
          if (ticket.notasCliente != null || ticket.notasTodero != null)
            pw.SizedBox(height: 15),
          
          // Calificación (si existe)
          if (ticket.calificacion != null)
            _buildSection('Calificación del Servicio', [
              pw.Row(
                children: [
                  pw.Text('Calificación: '),
                  ...List.generate(5, (index) {
                    return pw.Text(
                      index < ticket.calificacion! ? '★' : '☆',
                      style: const pw.TextStyle(color: PdfColors.orange, fontSize: 18),
                    );
                  }),
                ],
              ),
              if (ticket.comentarioCalificacion != null)
                _buildInfoRow('Comentario:', ticket.comentarioCalificacion!),
            ]),
          if (ticket.calificacion != null)
            pw.SizedBox(height: 15),
          
          // Firmas digitales
          if (firmaClienteImage != null || firmaToderoImage != null)
            _buildSignaturesSection(
              firmaClienteImage,
              firmaToderoImage,
              ticket.fechaFirmaCliente,
              ticket.fechaFirmaTodero,
              ticket.clienteNombre,
              ticket.toderoNombre,
            ),
          
          pw.Spacer(),
          
          // Pie de página
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'SU TODERO - Gestión Profesional de Servicios',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Generado el ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Construir encabezado con logo
  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logo != null)
          pw.Image(logo, width: 60, height: 60)
        else
          pw.Container(width: 60, height: 60),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'SU TODERO',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange,
              ),
            ),
            pw.Text(
              'Servicios Profesionales',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  /// Construir badge de estado
  pw.Widget _buildStatusBadge(TicketStatus status) {
    PdfColor color;
    switch (status) {
      case TicketStatus.nuevo:
        color = PdfColors.blue;
        break;
      case TicketStatus.pendiente:
        color = PdfColors.orange;
        break;
      case TicketStatus.enProgreso:
        color = PdfColors.purple;
        break;
      case TicketStatus.completado:
        color = PdfColors.green;
        break;
      case TicketStatus.cancelado:
        color = PdfColors.red;
        break;
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        status.displayName,
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
      ),
    );
  }

  /// Construir sección con título
  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// Construir fila de información
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
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

  /// Construir sección de firmas
  pw.Widget _buildSignaturesSection(
    pw.ImageProvider? firmaCliente,
    pw.ImageProvider? firmaTodero,
    DateTime? fechaFirmaCliente,
    DateTime? fechaFirmaTodero,
    String clienteNombre,
    String? toderoNombre,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Firmas Digitales',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            // Firma del cliente
            if (firmaCliente != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Image(firmaCliente, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      clienteNombre,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Cliente', style: const pw.TextStyle(fontSize: 10)),
                    if (fechaFirmaCliente != null)
                      pw.Text(
                        _formatDate(fechaFirmaCliente),
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                      ),
                  ],
                ),
              ),
            // Firma del todero
            if (firmaTodero != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 100,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Image(firmaTodero, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      toderoNombre ?? 'Todero',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Todero', style: const pw.TextStyle(fontSize: 10)),
                    if (fechaFirmaTodero != null)
                      pw.Text(
                        _formatDate(fechaFirmaTodero),
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es').format(date);
  }

  /// Compartir/Imprimir PDF
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

  /// Vista previa del PDF
  Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en vista previa de PDF: $e');
      }
      rethrow;
    }
  }
}
