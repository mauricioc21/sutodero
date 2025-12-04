import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Servicio para generar PDFs de tickets
class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// Generar PDF completo del ticket
  Future<Uint8List> generateTicketPdf(TicketModel ticket) async {
    final pdf = pw.Document();
    
    // Cargar logo corporativo SU TODERO (principal con personaje)
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle('assets/images/sutodero_logo_principal.png');
      if (kDebugMode) {
        debugPrint('✅ Logo corporativo SU TODERO cargado exitosamente (principal)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar el logo principal: $e');
      }
      // Intentar con logo alternativo como fallback
      try {
        logoImage = await imageFromAssetBundle('assets/images/sutodero_login_logo.png');
        if (kDebugMode) {
          debugPrint('✅ Logo alternativo cargado');
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar ningún logo: $e2');
        }
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

    // Descargar fotos del problema
    final fotosProblema = <pw.MemoryImage>[];
    if (ticket.fotosProblema.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📥 Descargando ${ticket.fotosProblema.length} fotos del problema...');
      }
      for (final photoUrl in ticket.fotosProblema) {
        try {
          final image = await _downloadImage(photoUrl);
          if (image != null) fotosProblema.add(image);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error descargando foto del problema: $e');
          }
          continue;
        }
      }
      if (kDebugMode) {
        debugPrint('✅ ${fotosProblema.length}/${ticket.fotosProblema.length} fotos del problema descargadas');
      }
    }

    // Descargar fotos del resultado
    final fotosResultado = <pw.MemoryImage>[];
    if (ticket.fotosResultado.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📥 Descargando ${ticket.fotosResultado.length} fotos del resultado...');
      }
      for (final photoUrl in ticket.fotosResultado) {
        try {
          final image = await _downloadImage(photoUrl);
          if (image != null) fotosResultado.add(image);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error descargando foto del resultado: $e');
          }
          continue;
        }
      }
      if (kDebugMode) {
        debugPrint('✅ ${fotosResultado.length}/${ticket.fotosResultado.length} fotos del resultado descargadas');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Encabezado con logo
          _buildHeader(logoImage),
          pw.SizedBox(height: 12),
          
          // Título del documento
          pw.Text(
            'ORDEN DE TRABAJO',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FAB334'), // Dorado corporativo
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          
          // ID del ticket y estado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ticket #${ticket.id.substring(0, 8)}'),
              _buildStatusBadge(ticket.estado),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#FAB334')),
          pw.SizedBox(height: 10),
          
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
          pw.SizedBox(height: 8),
          
          // Información de Cotización Aprobada
          if (ticket.cotizacionAprobada)
            _buildSection('Cotización Aprobada', [
              pw.Row(
                children: [
                  pw.Icon(
                    pw.IconData(0xe86c), // check_circle icon
                    color: PdfColors.green,
                    size: 18,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Cotización aprobada',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
              if (ticket.fechaCotizacionAprobada != null)
                _buildInfoRow('Fecha de Aprobación:', _formatDate(ticket.fechaCotizacionAprobada!)),
            ]),
          if (ticket.cotizacionAprobada)
            pw.SizedBox(height: 8),
          
          // Información del cliente
          _buildSection('Datos del Cliente', [
            _buildInfoRow('Nombre:', ticket.clienteNombre),
            if (ticket.clienteTelefono != null)
              _buildInfoRow('Teléfono:', ticket.clienteTelefono!),
            if (ticket.clienteEmail != null)
              _buildInfoRow('Email:', ticket.clienteEmail!),
          ]),
          pw.SizedBox(height: 8),
          
          // Información del todero (si está asignado)
          if (ticket.toderoNombre != null)
            _buildSection('Datos del Todero', [
              _buildInfoRow('Nombre:', ticket.toderoNombre!),
            ]),
          if (ticket.toderoNombre != null)
            pw.SizedBox(height: 8),
          
          // Información de la propiedad (si existe)
          if (ticket.propiedadDireccion != null)
            _buildSection('Ubicación', [
              _buildInfoRow('Dirección:', ticket.propiedadDireccion!),
              if (ticket.espacioNombre != null)
                _buildInfoRow('Espacio:', ticket.espacioNombre!),
            ]),
          if (ticket.propiedadDireccion != null)
            pw.SizedBox(height: 8),
          
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
          pw.SizedBox(height: 8),
          
          // Notas
          if (ticket.notasCliente != null || ticket.notasTodero != null)
            _buildSection('Notas y Observaciones', [
              if (ticket.notasCliente != null)
                _buildInfoRow('Notas del Cliente:', ticket.notasCliente!),
              if (ticket.notasTodero != null)
                _buildInfoRow('Notas del Todero:', ticket.notasTodero!),
            ]),
          if (ticket.notasCliente != null || ticket.notasTodero != null)
            pw.SizedBox(height: 8),
          
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
            pw.SizedBox(height: 8),
          
          // Fotos del problema
          if (fotosProblema.isNotEmpty) ...[
            pw.Text(
              'Fotos del Problema (${fotosProblema.length})',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange900,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildPhotoGrid(fotosProblema),
            pw.SizedBox(height: 8),
          ],
          
          // Fotos del resultado
          if (fotosResultado.isNotEmpty) ...[
            pw.Text(
              'Fotos del Resultado (${fotosResultado.length})',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildPhotoGrid(fotosResultado),
            pw.SizedBox(height: 8),
          ],
          
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
          
          // Pie de página limpio y centrado (sin fondo)
          pw.Column(
            children: [
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#FAB334')),
              pw.SizedBox(height: 8),
              pw.Text(
                'SU TODERO',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FAB334'),
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Gestión Profesional de Servicios de Reparación y Mantenimiento',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Cra 14b #112-85 Segundo Piso, Bogotá, Colombia | Tel: (601) 703-9495 | www.sutodero.com',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Documento generado el ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Construir encabezado con logo y colores corporativos
  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#000000'), // Negro corporativo
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo SU TODERO (tamaño optimizado)
          if (logo != null)
            pw.Container(
              width: 70,
              height: 70,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            )
          else
            pw.Container(
              width: 70,
              height: 70,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FAB334'), // Dorado
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(
                child: pw.Icon(
                  pw.IconData(0xe1a3), // handyman icon
                  size: 35,
                  color: PdfColor.fromHex('#000000'),
                ),
              ),
            ),
          pw.SizedBox(width: 12),
          // Solo eslogan (sin texto "SU TODERO")
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'Servicios Profesionales de Reparación y Mantenimiento',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#F5E6C8'), // Beige claro
                ),
              ),
            ),
          ),
        ],
      ),
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

  /// Construir sección con título y colores corporativos
  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#2C2C2C'), // Gris oscuro corporativo
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FAB334'), // Dorado corporativo
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F5E6C8'), // Beige claro
            border: pw.Border.all(color: PdfColor.fromHex('#FAB334'), width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  /// Construir grid de fotos (2 columnas)
  pw.Widget _buildPhotoGrid(List<pw.MemoryImage> photos) {
    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: photos.map((photo) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Image(photo, fit: pw.BoxFit.cover),
          ),
        );
      }).toList(),
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

  /// Descargar imagen desde URL con timeout y reintentos
  Future<pw.MemoryImage?> _downloadImage(String url, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint('📥 Descargando imagen (intento ${attempt + 1}/${maxRetries + 1}): $url');
        }
        
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout al descargar imagen después de 10 segundos');
          },
        );
        
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ Imagen descargada exitosamente (${response.bodyBytes.length} bytes)');
          }
          return pw.MemoryImage(response.bodyBytes);
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Error HTTP ${response.statusCode} al descargar imagen');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error descargando imagen (intento ${attempt + 1}): $e');
        }
        
        // Si es el último intento, retornar null
        if (attempt == maxRetries) {
          if (kDebugMode) {
            debugPrint('🚫 Todos los intentos fallaron para: $url');
          }
          return null;
        }
        
        // Esperar antes de reintentar
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
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
