import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import '../models/inventory_property.dart';
import '../models/property_room.dart';
import '../models/room_item.dart';
import 'package:intl/intl.dart';

/// Servicio para generar PDFs de inventarios con formato profesional
class InventoryPdfService {
  static final InventoryPdfService _instance = InventoryPdfService._internal();
  factory InventoryPdfService() => _instance;
  InventoryPdfService._internal();

  /// Colores corporativos SU TODERO
  static final PdfColor primaryYellow = PdfColor.fromHex('#FAB334');
  static final PdfColor darkGray = PdfColor.fromHex('#2C2C2C');
  static final PdfColor lightGray = PdfColors.grey300;
  static final PdfColor white = PdfColors.white;

  /// Generar PDF completo de una propiedad con todos sus espacios
  Future<Uint8List> generatePropertyPdf(
    InventoryProperty property,
    List<PropertyRoom> rooms,
  ) async {
    final pdf = pw.Document();
    
    // Cargar logo corporativo Su Todero (sin fondo) - mismo del login
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle('assets/images/sutodero_logo_login.png');
      if (kDebugMode) {
        debugPrint('✅ Logo corporativo SU TODERO del login cargado exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar el logo del login: $e');
      }
      try {
        logoImage = await imageFromAssetBundle('assets/images/logo_sutodero_nobg.png');
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar ningún logo: $e2');
        }
      }
    }

    // Agrupar espacios por nivel (si no hay nivel, usar "Nivel 1")
    final roomsByLevel = <String, List<PropertyRoom>>{};
    for (final room in rooms) {
      final nivel = room.nivel ?? 'Nivel 1';
      if (!roomsByLevel.containsKey(nivel)) {
        roomsByLevel[nivel] = [];
      }
      roomsByLevel[nivel]!.add(room);
    }

    // Generar páginas
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // Header superior
          _buildHeader(property, logoImage),
          pw.SizedBox(height: 15),

          // Datos de la empresa
          _buildCompanyInfo(),
          pw.SizedBox(height: 15),

          // Datos básicos e Información de captación
          _buildBasicInfo(property),
          pw.SizedBox(height: 20),

          // Espacios por nivel
          ...roomsByLevel.entries.expand((entry) => [
            _buildNivelHeader(entry.key),
            pw.SizedBox(height: 10),
            ...entry.value.expand((room) => [
              _buildRoomSection(room),
              pw.SizedBox(height: 15),
            ]),
          ]),

          // Textos jurídicos
          pw.SizedBox(height: 20),
          _buildLegalText(property),
        ],
        footer: (context) => _buildFooter(context),
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
    
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle('assets/images/logo_sutodero_nobg.png');
    } catch (e) {
      try {
        logoImage = await imageFromAssetBundle('assets/images/logo_sutodero_transparente.png');
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar el logo: $e2');
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(property, logoImage),
          pw.SizedBox(height: 15),
          _buildCompanyInfo(),
          pw.SizedBox(height: 15),
          _buildBasicInfo(property),
          pw.SizedBox(height: 15),
          _buildRoomSection(room),
          pw.SizedBox(height: 20),
          _buildLegalText(property),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  /// Header con fecha, serial y logo
  pw.Widget _buildHeader(InventoryProperty property, pw.ImageProvider? logoImage) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd \'de\' MMMM \'de\' yyyy \'a las\' HH:mm', 'es_ES');
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo a la izquierda
        if (logoImage != null)
          pw.Container(
            width: 120,
            height: 60,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(width: 120),
        
        // Información a la derecha
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generado el ${dateFormat.format(now)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Serial inventario: ${property.id}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generado con SU TODERO App',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Información de la empresa
  pw.Widget _buildCompanyInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SU TODERO',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: darkGray,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'NIT. 900.158.284 - 9',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
        pw.Text(
          'Cra 14b #112-85 Segundo Piso',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
        pw.Text(
          'info@sutodero.com',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
        pw.Text(
          '6017039495',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
        ),
      ],
    );
  }

  /// Datos básicos de la propiedad
  pw.Widget _buildBasicInfo(InventoryProperty property) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna izquierda - Datos básicos
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Datos básicos',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildSimpleInfoRow('País: ${property.pais ?? 'CO'}'),
                _buildSimpleInfoRow('Ciudad: ${property.ciudad ?? 'N/A'}'),
                if (property.municipio != null && property.municipio!.isNotEmpty)
                  _buildSimpleInfoRow('Municipio: ${property.municipio}'),
                _buildSimpleInfoRow('Barrio: ${property.barrio ?? 'N/A'}'),
                _buildSimpleInfoRow('Direccion: ${property.direccion}${property.numeroInterior != null && property.numeroInterior!.isNotEmpty ? ' ${property.numeroInterior}' : ''}'),
                _buildSimpleInfoRow('Area Construida: ${property.area?.toStringAsFixed(0) ?? '0'} m²'),
                _buildSimpleInfoRow('Area Lote: ${property.areaLote?.toStringAsFixed(0) ?? '0'} m²'),
                _buildSimpleInfoRow('Tipo de propiedad: ${property.tipo.displayName}'),
                _buildSimpleInfoRow('Codigo del Inmueble: ${property.codigoInterno ?? property.id.substring(0, 12).toUpperCase()}'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        // Columna derecha - Información de Captación
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Información de Captacion',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildSimpleInfoRow('Precio deseado de alquiler: \$ ${property.precioAlquilerDeseado?.toStringAsFixed(0) ?? (property.area != null ? (property.area! * 20).toStringAsFixed(0) : '0')}'),
                _buildSimpleInfoRow('Nombre del Propietario: ${property.clienteNombre ?? 'N/A'}'),
                if (property.numeroDocumento != null && property.numeroDocumento!.isNotEmpty)
                  _buildSimpleInfoRow('Documento: ${property.tipoDocumento ?? 'C.C.'} ${property.numeroDocumento}'),
                _buildSimpleInfoRow('Teléfono del Propietario: ${property.clienteTelefono ?? 'N/A'}'),
                _buildSimpleInfoRow('Nombre del Agente: ${property.nombreAgente ?? 'N/A'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Fila de información simple
  pw.Widget _buildSimpleInfoRow(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
      ),
    );
  }



  /// Header de nivel
  pw.Widget _buildNivelHeader(String nivel) {
    // Formatear el nivel para asegurar que siempre diga "Nivel X"
    String nivelFormateado = nivel;
    if (!nivel.toLowerCase().contains('nivel')) {
      nivelFormateado = 'Nivel $nivel';
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: darkGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        nivelFormateado,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: primaryYellow,
        ),
      ),
    );
  }

  /// Sección de espacio/habitación
  pw.Widget _buildRoomSection(PropertyRoom room) {
    final items = room.items ?? [];
    
    if (items.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Nombre del espacio
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            '${room.nombre} / ${room.tipo.displayName}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: darkGray,
            ),
          ),
        ),
        pw.SizedBox(height: 8),

        // Tabla de elementos
        pw.Table(
          border: pw.TableBorder.all(color: lightGray, width: 1),
          columnWidths: {
            0: const pw.FixedColumnWidth(58),    // Cantidad: compacto
            1: const pw.FixedColumnWidth(72),    // Elemento: compacto
            2: const pw.FixedColumnWidth(68),    // Material: compacto
            3: const pw.FixedColumnWidth(58),    // Estado: compacto
            4: const pw.FlexColumnWidth(1),      // Comentarios: toma espacio restante
            5: const pw.FixedColumnWidth(120),   // Fotos: AMPLIADO para foto a ancho completo
          },
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primaryYellow),
              children: [
                _buildTableHeaderCell('Cantidad'),
                _buildTableHeaderCell('Elemento'),
                _buildTableHeaderCell('Material'),
                _buildTableHeaderCell('Estado'),
                _buildTableHeaderCell('Comentarios'),
                _buildTableHeaderCell('Fotos'),
              ],
            ),
            // Filas de elementos
            ...items.map((item) {
              // Obtener fotos del elemento específico
              final elementoFotos = item.fotos ?? [];
              
              return pw.TableRow(
                children: [
                  _buildTableCell(item.cantidad.toString(), centered: true),
                  _buildTableCell(item.nombreElemento.toUpperCase(), centered: true),  // CENTRADO
                  _buildTableCell(item.nombreMaterial, centered: true),  // CENTRADO
                  _buildTableCell(item.estado.displayName, centered: true),
                  _buildTableCell(item.comentarios ?? '', fontSize: 8),
                  // Si el elemento tiene fotos, mostrar la primera foto como imagen pequeña
                  elementoFotos.isNotEmpty
                      ? _buildTableCellWithImage(elementoFotos[0])
                      : _buildTableCell('-', centered: true, fontSize: 8),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Textos jurídicos
  pw.Widget _buildLegalText(InventoryProperty property) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Textos Jurídicos:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: darkGray,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Los elementos que hacen parte del ${property.tipo.displayName}, ubicado en ${property.direccion}${property.numeroInterior != null && property.numeroInterior!.isNotEmpty ? ' ${property.numeroInterior}' : ''}, que aquí se relacionan corresponde a un inventario general, mas exime a la inmobiliaria de todo daño, hurto, desgaste, faltante y/o deterioro que se genere en el inmueble mientras el inmueble está desocupado. Esto, de acuerdo a lo establecido en la ley de arrendamientos.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Propietario',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Nombre: ${property.clienteNombre}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      height: 1,
                      width: 150,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Firma Digital',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Celda de header de tabla
  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,  // Centrado vertical y horizontal
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Celda de tabla
  pw.Widget _buildTableCell(String text, {bool centered = false, double fontSize = 9}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,  // Centrado vertical
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, color: darkGray),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Celda de tabla con enlace
  pw.Widget _buildTableCellWithLink(String text, String url, {bool centered = false, double fontSize = 9}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.UrlLink(
        destination: url,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            color: PdfColors.blue,
            decoration: pw.TextDecoration.underline,
          ),
          textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
        ),
      ),
    );
  }

  /// Celda de tabla con múltiples vínculos de fotos
  pw.Widget _buildTableCellWithMultipleLinks(List<String> urls, {double fontSize = 7}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: urls.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final url = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.UrlLink(
              destination: url,
              child: pw.Text(
                '📷 Foto $index',
                style: pw.TextStyle(
                  fontSize: fontSize,
                  color: PdfColors.blue,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Celda de tabla con imagen del elemento (primera foto)
  pw.Widget _buildTableCellWithImage(String imageUrl) {
    try {
      // Si es una data URL (base64)
      if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        final imageProvider = pw.MemoryImage(bytes);
        
        return pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,  // Centrado vertical y horizontal
          child: pw.Container(
            width: 110,   // Ancho completo de columna (120pts - 10pts padding)
            height: 62,   // Altura para mantener proporción 16:9 (110 / 16 * 9 ≈ 62)
            child: pw.Image(
              imageProvider,
              fit: pw.BoxFit.contain,  // Mantiene proporción original sin recortar
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al decodificar imagen: $e');
      }
    }
    
    // Si no se puede decodificar o no es base64, mostrar texto de fallback
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,  // Centrado vertical y horizontal
      child: pw.Text(
        '📷',
        style: const pw.TextStyle(fontSize: 16),
      ),
    );
  }

  /// Fila de información
  pw.TableRow _buildInfoTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: darkGray,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  /// Pie de página
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: primaryYellow, width: 2)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Página ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy', 'es_ES').format(date);
  }

  /// Compartir PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      if (kDebugMode) {
        debugPrint('PDF compartido: $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error compartiendo PDF: $e');
      }
      rethrow;
    }
  }
}
