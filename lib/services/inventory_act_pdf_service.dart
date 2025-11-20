import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/inventory_act.dart';
import '../models/property_room.dart';
import '../models/inventory_property.dart';
import '../models/room_features.dart';
import '../config/brand_colors.dart';

/// Servicio para generar PDFs de Actas de Inventario
/// con firma digital, reconocimiento facial y fotos
class InventoryActPdfService {
  /// Genera PDF completo del acta de inventario
  Future<Uint8List> generateActPdf({
    required InventoryAct act,
    List<PropertyRoom>? rooms,
  }) async {
    final pdf = pw.Document();

    // Cargar logo corporativo Su Todero usando BrandColors
    pw.ImageProvider? logoImage;
    try {
      logoImage = await imageFromAssetBundle(BrandColors.logoMain);
      if (kDebugMode) {
        debugPrint('✅ Logo corporativo SU TODERO cargado exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo cargar el logo principal: $e');
      }
      // Intentar con logo amarillo como fallback
      try {
        logoImage = await imageFromAssetBundle(BrandColors.logoYellow);
        if (kDebugMode) {
          debugPrint('✅ Logo alternativo (amarillo) cargado');
        }
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('⚠️ No se pudo cargar ningún logo corporativo: $e2');
        }
      }
    }

    // Descargar imágenes necesarias
    final signatureImage = act.digitalSignatureUrl != null
        ? await _downloadImage(act.digitalSignatureUrl!)
        : null;
    final facialImage = act.facialRecognitionUrl != null
        ? await _downloadImage(act.facialRecognitionUrl!)
        : null;

    // Descargar fotos del inventario
    final photos = <pw.MemoryImage>[];
    for (final photoUrl in act.photoUrls) {
      try {
        final image = await _downloadImage(photoUrl);
        if (image != null) photos.add(image);
      } catch (e) {
        // Continuar si alguna foto falla
        continue;
      }
    }

    // Página 1: Portada y datos principales
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage),
            pw.SizedBox(height: 20),
            _buildActInfo(act),
            pw.SizedBox(height: 20),
            _buildPropertyInfo(act),
            pw.SizedBox(height: 20),
            _buildClientInfo(act),
            pw.SizedBox(height: 20),
            if (act.observations != null) ...[
              _buildObservations(act.observations!),
              pw.SizedBox(height: 20),
            ],
            pw.Spacer(),
            _buildAuthenticationSection(act, signatureImage, facialImage),
          ],
        ),
      ),
    );

    // Páginas adicionales: Espacios del inventario (si hay)
    if (rooms != null && rooms.isNotEmpty) {
      for (final room in rooms) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPageHeader(act),
                pw.SizedBox(height: 20),
                _buildRoomDetails(room),
              ],
            ),
          ),
        );
      }
    }

    // Páginas de fotos: Galería de imágenes
    if (photos.isNotEmpty) {
      // Dividir fotos en páginas (4 fotos por página)
      final photosPerPage = 4;
      for (var i = 0; i < photos.length; i += photosPerPage) {
        final pagePhotos = photos.skip(i).take(photosPerPage).toList();
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPageHeader(act),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Galería Fotográfica (${i + 1}-${i + pagePhotos.length} de ${photos.length})',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                _buildPhotoGrid(pagePhotos),
              ],
            ),
          ),
        );
      }
    }

    // Página final: Validación y códigos
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader(act),
            pw.SizedBox(height: 20),
            _buildValidationSection(act),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Descarga imagen desde URL con timeout y reintentos
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

  /// Header principal del documento
  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: BrandColors.darkPdf,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ACTA DE INVENTARIO',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: BrandColors.primaryPdf,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  BrandColors.companySlogan,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: BrandColors.beigeClairPdf,
                  ),
                ),
              ],
            ),
          ),
          if (logo != null)
            pw.Image(logo, height: 40, fit: pw.BoxFit.contain)
          else
            pw.Text(
              BrandColors.companyName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: BrandColors.primaryPdf,
              ),
            ),
        ],
      ),
    );
  }

  /// Header pequeño para páginas secundarias
  pw.Widget _buildPageHeader(InventoryAct act) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: BrandColors.primaryPdf,
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Acta: ${act.validationCode ?? "N/A"}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            act.propertyAddress,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Información del acta
  pw.Widget _buildActInfo(InventoryAct act) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: BrandColors.beigeClairPdf,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Código de Validación:', act.validationCode ?? 'N/A', bold: true),
          _buildInfoRow(
            'Fecha de Creación:',
            DateFormat('dd/MM/yyyy HH:mm').format(act.createdAt),
          ),
          if (act.signatureTimestamp != null)
            _buildInfoRow(
              'Fecha de Firma:',
              DateFormat('dd/MM/yyyy HH:mm').format(act.signatureTimestamp!),
            ),
          if (act.createdByName != null)
            _buildInfoRow('Elaborado por:', act.createdByName!),
          if (act.createdByRole != null)
            _buildInfoRow('Cargo:', act.createdByRole!),
        ],
      ),
    );
  }

  /// Información de la propiedad
  pw.Widget _buildPropertyInfo(InventoryAct act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN DEL INMUEBLE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#FF6B00'),
          ),
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
              _buildInfoRow('Dirección:', act.propertyAddress, bold: true),
              _buildInfoRow('Tipo:', act.propertyType.displayName),
              if (act.propertyDescription != null)
                _buildInfoRow('Descripción:', act.propertyDescription!),
              if (act.roomIds.isNotEmpty)
                _buildInfoRow('Espacios inventariados:', '${act.roomIds.length}'),
              if (act.photoUrls.isNotEmpty)
                _buildInfoRow('Fotografías:', '${act.photoUrls.length}'),
            ],
          ),
        ),
      ],
    );
  }

  /// Información del cliente
  pw.Widget _buildClientInfo(InventoryAct act) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMACIÓN DEL CLIENTE',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#9C27B0'),
          ),
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
              _buildInfoRow('Nombre:', act.clientName, bold: true),
              if (act.clientIdNumber != null)
                _buildInfoRow('Identificación:', act.clientIdNumber!),
              if (act.clientPhone != null)
                _buildInfoRow('Teléfono:', act.clientPhone!),
              if (act.clientEmail != null)
                _buildInfoRow('Email:', act.clientEmail!),
            ],
          ),
        ),
      ],
    );
  }

  /// Observaciones
  pw.Widget _buildObservations(String observations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OBSERVACIONES',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            observations,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Sección de autenticación (firma + facial)
  pw.Widget _buildAuthenticationSection(
    InventoryAct act,
    pw.MemoryImage? signatureImage,
    pw.MemoryImage? facialImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: BrandColors.beigeClairPdf,
        border: pw.Border.all(color: BrandColors.primaryPdf, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          // Firma digital
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  'FIRMA DIGITAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (signatureImage != null)
                  pw.Container(
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                    ),
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    height: 80,
                    child: pw.Center(
                      child: pw.Text('No disponible', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  act.clientName,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // Reconocimiento facial
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  'RECONOCIMIENTO FACIAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (facialImage != null)
                  pw.Container(
                    height: 80,
                    width: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(40),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 40,
                      verticalRadius: 40,
                      child: pw.Image(facialImage, fit: pw.BoxFit.cover),
                    ),
                  )
                else
                  pw.Container(
                    height: 80,
                    child: pw.Center(
                      child: pw.Text('No disponible', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Verificado',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Detalles de un espacio
  pw.Widget _buildRoomDetails(PropertyRoom room) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F5E6C8'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                room.nombre,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                room.estado.displayName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _getConditionColor(room.estado),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        if (room.descripcion != null) ...[
          _buildInfoRow('Descripción:', room.descripcion!),
          pw.SizedBox(height: 8),
        ],
        pw.Text(
          'Características:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        _buildRoomFeatures(room),
      ],
    );
  }

  /// Características del espacio
  pw.Widget _buildRoomFeatures(PropertyRoom room) {
    final items = <pw.Widget>[];
    
    // Dimensiones
    if (room.ancho != null || room.largo != null) {
      final dimensiones = <String>[];
      if (room.ancho != null) dimensiones.add('${room.ancho}m ancho');
      if (room.largo != null) dimensiones.add('${room.largo}m largo');
      if (room.altura != null) dimensiones.add('${room.altura}m alto');
      
      items.add(_buildFeatureItem('Dimensiones', dimensiones.join(' × ')));
    }

    // Tipo de piso
    if (room.tipoPiso != null) {
      items.add(_buildFeatureItem('Piso', room.tipoPiso!.displayName));
    }

    // Características específicas según tipo
    if (room.tipoCocina != null) {
      items.add(_buildFeatureItem('Tipo de Cocina', room.tipoCocina!.displayName));
    }
    if (room.materialMeson != null) {
      items.add(_buildFeatureItem('Material Mesón', room.materialMeson!.displayName));
    }
    if (room.tipoBano != null) {
      items.add(_buildFeatureItem('Tipo de Baño', room.tipoBano!.displayName));
    }
    if (room.acabadoBano != null) {
      items.add(_buildFeatureItem('Acabado Baño', room.acabadoBano!.displayName));
    }
    if (room.tipoCloset != null) {
      items.add(_buildFeatureItem('Closet', room.tipoCloset!.displayName));
    }
    if (room.vista != null) {
      items.add(_buildFeatureItem('Vista', room.vista!.displayName));
    }
    if (room.iluminacionNatural != null) {
      items.add(_buildFeatureItem('Iluminación', room.iluminacionNatural!.displayName));
    }

    // Problemas detectados
    if (room.problemas.isNotEmpty) {
      items.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Problemas detectados:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F44336')),
              ),
              ...room.problemas.map((problema) => 
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, top: 2),
                  child: pw.Text('⚠ $problema', style: const pw.TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.isEmpty 
        ? [pw.Text('Sin características adicionales', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey))]
        : items,
    );
  }

  /// Item de característica
  pw.Widget _buildFeatureItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text('• ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Grid de fotos
  pw.Widget _buildPhotoGrid(List<pw.MemoryImage> photos) {
    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
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

  /// Sección de validación
  pw.Widget _buildValidationSection(InventoryAct act) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DE VALIDACIÓN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Código de Validación:', act.validationCode ?? 'N/A', bold: true),
          if (act.authenticationHash != null)
            _buildInfoRow('Hash de Autenticación:', act.authenticationHash!),
          _buildInfoRow('Estado:', act.isCompleted ? 'Completada' : 'Pendiente'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Este documento es una representación digital del acta de inventario autenticada '
            'mediante firma digital y reconocimiento facial. Para verificar su autenticidad, '
            'utilice el código de validación en la plataforma SU TODERO.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  /// Footer del documento
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: BrandColors.primaryPdf, width: 2),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '${BrandColors.companyName} - Gestión Profesional de Inventarios',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: BrandColors.darkPdf,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${BrandColors.companyAddress} | Tel: ${BrandColors.companyPhone} | ${BrandColors.companyWebsite}',
            style: pw.TextStyle(fontSize: 8, color: BrandColors.darkGrayPdf),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Documento generado automáticamente - Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#2C2C2C')),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Fila de información
  pw.Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Color según condición
  PdfColor _getConditionColor(SpaceCondition condition) {
    switch (condition) {
      case SpaceCondition.excelente:
        return PdfColor.fromHex('#4CAF50');
      case SpaceCondition.bueno:
        return PdfColor.fromHex('#8BC34A');
      case SpaceCondition.regular:
        return PdfColor.fromHex('#FFC107');
      case SpaceCondition.malo:
        return PdfColor.fromHex('#FF9800');
      case SpaceCondition.critico:
        return PdfColor.fromHex('#F44336');
    }
  }
}
