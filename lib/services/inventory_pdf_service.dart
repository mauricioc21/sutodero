import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

    // Descargar planos 2D y 3D si existen
    pw.MemoryImage? plano2dImage;
    pw.MemoryImage? plano3dImage;
    
    if (property.plano2dUrl != null && property.plano2dUrl!.isNotEmpty) {
      try {
        plano2dImage = await _downloadImage(property.plano2dUrl!);
        if (kDebugMode) {
          debugPrint('✅ Plano 2D descargado para PDF de inventario');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error descargando plano 2D: $e');
        }
      }
    }
    
    if (property.plano3dUrl != null && property.plano3dUrl!.isNotEmpty) {
      try {
        plano3dImage = await _downloadImage(property.plano3dUrl!);
        if (kDebugMode) {
          debugPrint('✅ Plano 3D descargado para PDF de inventario');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error descargando plano 3D: $e');
        }
      }
    }

    // Descargar fotos de todos los espacios
    final List<pw.MemoryImage> allRoomPhotos = [];
    final Map<String, List<pw.MemoryImage>> photosByRoom = {};
    
    for (final room in rooms) {
      final roomPhotos = <pw.MemoryImage>[];
      
      // Fotos regulares del espacio
      for (final photoUrl in room.fotos) {
        try {
          final image = await _downloadImage(photoUrl);
          if (image != null) {
            roomPhotos.add(image);
            allRoomPhotos.add(image);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error descargando foto de espacio: $e');
          }
        }
      }
      
      // Foto 360° si existe
      if (room.foto360Url != null && room.foto360Url!.isNotEmpty) {
        try {
          final image360 = await _downloadImage(room.foto360Url!);
          if (image360 != null) {
            roomPhotos.add(image360);
            allRoomPhotos.add(image360);
          }
          if (kDebugMode) {
            debugPrint('✅ Foto 360° descargada para ${room.nombre}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error descargando foto 360°: $e');
          }
        }
      }
      
      if (roomPhotos.isNotEmpty) {
        photosByRoom[room.nombre] = roomPhotos;
      }
    }

    // Página principal con información
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

    // Página de Plano 2D
    if (plano2dImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage),
              pw.SizedBox(height: 20),
              pw.Text(
                'PLANO 2D - VISTA SUPERIOR',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FAB334'),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(plano2dImage!, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      );
    }

    // Página de Plano 3D
    if (plano3dImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage),
              pw.SizedBox(height: 20),
              pw.Text(
                'PLANO 3D - VISTA ISOMÉTRICA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FAB334'),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(plano3dImage!, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      );
    }

    // Páginas de fotos (4 fotos por página, agrupadas por espacio)
    if (photosByRoom.isNotEmpty) {
      photosByRoom.forEach((roomName, photos) {
        // Dividir fotos en páginas (4 por página)
        const photosPerPage = 4;
        for (var i = 0; i < photos.length; i += photosPerPage) {
          final pagePhotos = photos.skip(i).take(photosPerPage).toList();
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.letter,
              margin: const pw.EdgeInsets.all(40),
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(logoImage),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'GALERÍA FOTOGRÁFICA - $roomName',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#FAB334'),
                    ),
                  ),
                  pw.Text(
                    '(${i + 1}-${i + pagePhotos.length} de ${photos.length})',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Expanded(
                    child: _buildPhotoGrid(pagePhotos),
                  ),
                  pw.SizedBox(height: 12),
                  _buildFooter(),
                ],
              ),
            ),
          );
        }
      });
    }

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

  /// Descargar imagen desde URL
  Future<pw.MemoryImage?> _downloadImage(String url) async {
    try {
      if (kDebugMode) {
        debugPrint('📥 Descargando imagen: ${url.substring(0, 50)}...');
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
          debugPrint('❌ Error HTTP ${response.statusCode} al descargar imagen');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error descargando imagen: $e');
      }
      return null;
    }
  }

  /// Grid de fotos para PDF (2x2)
  pw.Widget _buildPhotoGrid(List<pw.MemoryImage> photos) {
    return pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: photos.map((photo) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(photo, fit: pw.BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }
}
