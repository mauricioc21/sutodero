import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../models/room_features.dart';
import '../../services/inventory_service.dart';
import '../../services/floor_plan_service.dart';
import '../../services/qr_service.dart';
import '../../services/inventory_pdf_service.dart';
import 'add_edit_room_screen.dart';
import '../../config/app_theme.dart';

class RoomDetailScreen extends StatefulWidget {
  final PropertyRoom room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _inventoryService = InventoryService();
  final _floorPlanService = FloorPlanService();
  final _imagePicker = ImagePicker();
  final _qrService = QRService();
  final _pdfService = InventoryPdfService();
  PropertyRoom? _room;
  bool _isLoading = true;
  bool _isGeneratingFloorPlan = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _isLoading = false;
  }

  Future<void> _loadRoom() async {
    setState(() => _isLoading = true);
    try {
      final room = await _inventoryService.getRoom(widget.room.id);
      if (mounted) {
        setState(() {
          _room = room;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar espacio: $e')),
        );
      }
    }
  }

  Future<void> _showQRCode() async {
    if (_room == null) return;
    
    final qrData = _qrService.generateRoomQR(
      _room!.id,
      _room!.propertyId,
      nombre: _room!.nombre,
    );
    
    await _qrService.showQRDialog(
      context,
      data: qrData,
      title: 'QR de Espacio',
      subtitle: '${_room!.tipo.icon} ${_room!.nombre}',
    );
  }

  Future<void> _exportToPdf() async {
    if (_room == null) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
      
      // Necesitamos cargar la propiedad
      final property = await _inventoryService.getProperty(_room!.propertyId);
      if (property == null) throw Exception('Propiedad no encontrada');
      
      final pdfBytes = await _pdfService.generateRoomPdf(property, _room!);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      await _pdfService.sharePdf(
        pdfBytes,
        'espacio_${_room!.nombre.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null && _room != null) {
        // Agregar foto a la lista
        await _inventoryService.addRoomPhoto(_room!.id, photo.path);
        await _loadRoom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Foto agregada correctamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );
      
      if (photos.isNotEmpty && _room != null) {
        for (final photo in photos) {
          await _inventoryService.addRoomPhoto(_room!.id, photo.path);
        }
        await _loadRoom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${photos.length} fotos agregadas')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar fotos: $e')),
        );
      }
    }
  }

  Future<void> _take360Photo() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null && _room != null) {
        await _inventoryService.setRoom360Photo(_room!.id, photo.path);
        await _loadRoom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Foto 360° guardada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto 360°: $e')),
        );
      }
    }
  }

  Future<void> _generateFloorPlan() async {
    if (_room == null) return;
    
    // Verificar que haya fotos
    if (_room!.fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Necesitas tomar al menos una foto del espacio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingFloorPlan = true);
    try {
      // Plano individual de habitación - En desarrollo
      final floorPlan = null; // await _floorPlanService.generateRoomFloorPlan(_room!.id);
      
      if (mounted) {
        setState(() => _isGeneratingFloorPlan = false);
        
        if (floorPlan != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Plano generado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Mostrar mensaje de función en desarrollo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Generación de Planos'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análisis completado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text('📐 Dimensiones: ${_room!.ancho ?? "N/A"} x ${_room!.largo ?? "N/A"} m'),
                  Text('📷 Fotos: ${_room!.fotos.length}'),
                  Text('🔄 Foto 360°: ${_room!.tiene360 ? "Sí" : "No"}'),
                  if (_room!.area != null)
                    Text('📏 Área: ${_room!.area!.toStringAsFixed(2)} m²'),
                  SizedBox(height: AppTheme.spacingMD),
                  const Text(
                    'La generación automática de planos con IA estará disponible en una próxima actualización.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingFloorPlan = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar espacio?'),
        content: const Text('Esta acción no se puede deshacer'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && _room != null) {
      try {
        await _inventoryService.deleteRoom(_room!.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _editRoom() async {
    if (_room == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRoomScreen(
          propertyId: _room!.propertyId,
          room: _room,
        ),
      ),
    );
    if (result == true) {
      _loadRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Espacio no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_room!.nombre),
        actions: [
          // Botón PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Exportar PDF',
          ),
          // Botón QR
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showQRCode,
            tooltip: 'Código QR',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editRoom,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRoom,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoom,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          children: [
            // Encabezado con tipo y estado
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _room!.tipo.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                        SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _room!.nombre,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(_room!.tipo.displayName),
                                  SizedBox(width: AppTheme.spacingSM),
                                  Text('•'),
                                  SizedBox(width: AppTheme.spacingSM),
                                  Text(_room!.estado.emoji),
                                  const SizedBox(width: 4),
                                  Text(_room!.estado.displayName),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_room!.descripcion != null) ...[
                      SizedBox(height: AppTheme.spacingMD),
                      Text(_room!.descripcion!),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Dimensiones y Visualización 3D
            if (_room!.ancho != null || _room!.largo != null || _room!.altura != null) ...[
              const Text(
                'Dimensiones y Visualización 3D',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppTheme.spacingSM),
              
              // Visualización 3D (si hay todas las dimensiones)
              if (_room!.ancho != null && _room!.largo != null && _room!.altura != null) ...[
                Card(
                  elevation: 4,
                  child: Container(
                    height: 200,
                    padding: EdgeInsets.all(AppTheme.paddingMD),
                    child: CustomPaint(
                      painter: Room3DPainter(
                        ancho: _room!.ancho!,
                        largo: _room!.largo!,
                        altura: _room!.altura!,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingSM),
              ],
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingMD),
                  child: Column(
                    children: [
                      if (_room!.ancho != null)
                        _buildInfoRow('↔ Ancho', '${_room!.ancho} m'),
                      if (_room!.largo != null)
                        _buildInfoRow('↕ Largo', '${_room!.largo} m'),
                      if (_room!.altura != null)
                        _buildInfoRow('⬆ Altura', '${_room!.altura} m'),
                      if (_room!.area != null)
                        _buildInfoRow('📐 Área', '${_room!.area!.toStringAsFixed(2)} m²',
                            highlight: true),
                      if (_room!.volumen != null)
                        _buildInfoRow('🧊 Volumen', '${_room!.volumen!.toStringAsFixed(2)} m³',
                            highlight: true),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
            ],

            // Características detalladas
            if (_room!.tipoPiso != null ||
                _room!.tipoCocina != null ||
                _room!.tipoBano != null ||
                _room!.tipoCloset != null ||
                _room!.vista != null ||
                _room!.iluminacionNatural != null) ...[
              const Text(
                'Características',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppTheme.spacingSM),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingMD),
                  child: Column(
                    children: [
                      if (_room!.tipoPiso != null)
                        _buildInfoRow('Tipo de piso', _room!.tipoPiso!.displayName),
                      if (_room!.tipoCocina != null)
                        _buildInfoRow('Tipo de cocina', _room!.tipoCocina!.displayName),
                      if (_room!.materialMeson != null)
                        _buildInfoRow('Material mesón', _room!.materialMeson!.displayName),
                      if (_room!.tipoBano != null)
                        _buildInfoRow('Tipo de baño', _room!.tipoBano!.displayName),
                      if (_room!.acabadoBano != null)
                        _buildInfoRow('Acabado baño', _room!.acabadoBano!.displayName),
                      if (_room!.tipoCloset != null)
                        _buildInfoRow('Tipo de closet', _room!.tipoCloset!.displayName),
                      if (_room!.vista != null)
                        _buildInfoRow('Vista', _room!.vista!.displayName),
                      if (_room!.iluminacionNatural != null)
                        _buildInfoRow('Iluminación natural',
                            _room!.iluminacionNatural!.displayName),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
            ],

            // Sección de fotos
            const Text(
              'Fotos del Espacio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.spacingSM),
            
            // Botones de captura
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: AppTheme.blanco,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: AppTheme.blanco,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSM),
            
            // Botón foto 360°
            ElevatedButton.icon(
              onPressed: _take360Photo,
              icon: const Icon(Icons.panorama_photosphere),
              label: Text(_room!.tiene360 ? 'Reemplazar Foto 360°' : 'Tomar Foto 360°'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: AppTheme.blanco,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Botón generar plano
            ElevatedButton.icon(
              onPressed: _isGeneratingFloorPlan ? null : _generateFloorPlan,
              icon: _isGeneratingFloorPlan
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.blanco),
                      ),
                    )
                  : const Icon(Icons.architecture),
              label: Text(_isGeneratingFloorPlan ? 'Generando Plano...' : 'Generar Plano del Espacio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.grisOscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Galería de fotos
            if (_room!.fotos.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _room!.fotos.length,
                itemBuilder: (context, index) {
                  final photoPath = _room!.fotos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              SizedBox(height: AppTheme.spacingMD),
            ],

            // Foto 360°
            if (_room!.tiene360) ...[
              const Text(
                'Foto 360°',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppTheme.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                child: Image.file(
                  File(_room!.foto360Url!),
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para renderizar vista 3D isométrica del espacio
class Room3DPainter extends CustomPainter {
  final double ancho;
  final double largo;
  final double altura;
  
  Room3DPainter({
    required this.ancho,
    required this.largo,
    required this.altura,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Escala para que el espacio quepa en el canvas
    final maxDimension = [ancho, largo, altura].reduce((a, b) => a > b ? a : b);
    final scale = (size.width * 0.6) / maxDimension;
    
    // Centro del canvas
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Dimensiones escaladas
    final w = ancho * scale;
    final l = largo * scale;
    final h = altura * scale;
    
    // Ángulo isométrico (30 grados)
    final angle = 3.14159 / 6; // 30 grados en radianes
    final cosAngle = 0.866; // cos(30°)
    final sinAngle = 0.5;   // sin(30°)
    
    // Transformación isométrica
    Offset iso(double x, double y, double z) {
      return Offset(
        centerX + (x - y) * cosAngle,
        centerY + (x + y) * sinAngle - z,
      );
    }
    
    // Definir vértices del cubo (espacio 3D)
    final v1 = iso(0, 0, 0);        // Base frontal izquierda
    final v2 = iso(w, 0, 0);        // Base frontal derecha
    final v3 = iso(w, l, 0);        // Base trasera derecha
    final v4 = iso(0, l, 0);        // Base trasera izquierda
    final v5 = iso(0, 0, h);        // Techo frontal izquierda
    final v6 = iso(w, 0, h);        // Techo frontal derecha
    final v7 = iso(w, l, h);        // Techo trasera derecha
    final v8 = iso(0, l, h);        // Techo trasera izquierda
    
    // Pinturas
    final paintFloor = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;
      
    final paintWallLeft = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..style = PaintingStyle.fill;
      
    final paintWallRight = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.fill;
      
    final paintEdges = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final paintDimensions = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Dibujar cara inferior (piso)
    final pathFloor = Path()
      ..moveTo(v1.dx, v1.dy)
      ..lineTo(v2.dx, v2.dy)
      ..lineTo(v3.dx, v3.dy)
      ..lineTo(v4.dx, v4.dy)
      ..close();
    canvas.drawPath(pathFloor, paintFloor);
    canvas.drawPath(pathFloor, paintEdges);
    
    // Dibujar cara izquierda
    final pathLeft = Path()
      ..moveTo(v1.dx, v1.dy)
      ..lineTo(v4.dx, v4.dy)
      ..lineTo(v8.dx, v8.dy)
      ..lineTo(v5.dx, v5.dy)
      ..close();
    canvas.drawPath(pathLeft, paintWallLeft);
    canvas.drawPath(pathLeft, paintEdges);
    
    // Dibujar cara derecha
    final pathRight = Path()
      ..moveTo(v2.dx, v2.dy)
      ..lineTo(v1.dx, v1.dy)
      ..lineTo(v5.dx, v5.dy)
      ..lineTo(v6.dx, v6.dy)
      ..close();
    canvas.drawPath(pathRight, paintWallRight);
    canvas.drawPath(pathRight, paintEdges);
    
    // Dibujar aristas restantes
    canvas.drawLine(v3, v7, paintEdges);
    canvas.drawLine(v4, v8, paintEdges);
    canvas.drawLine(v5, v6, paintEdges);
    canvas.drawLine(v6, v7, paintEdges);
    canvas.drawLine(v7, v8, paintEdges);
    
    // Dibujar líneas de dimensiones
    // Ancho (frontal)
    canvas.drawLine(
      Offset(v1.dx, v1.dy + 20),
      Offset(v2.dx, v2.dy + 20),
      paintDimensions,
    );
    _drawText(canvas, '${ancho.toStringAsFixed(1)}m', 
      Offset((v1.dx + v2.dx) / 2, v1.dy + 30), 12);
    
    // Largo (lateral)
    canvas.drawLine(
      Offset(v4.dx - 20, v4.dy),
      Offset(v8.dx - 20, v8.dy),
      paintDimensions,
    );
    _drawText(canvas, '${largo.toStringAsFixed(1)}m',
      Offset(v4.dx - 30, (v4.dy + v8.dy) / 2), 12);
    
    // Altura (vertical)
    canvas.drawLine(
      Offset(v1.dx - 20, v1.dy),
      Offset(v5.dx - 20, v5.dy),
      paintDimensions,
    );
    _drawText(canvas, '${altura.toStringAsFixed(1)}m',
      Offset(v1.dx - 35, (v1.dy + v5.dy) / 2), 12);
    
    // Etiqueta del espacio
    _drawText(canvas, 'Vista Isométrica 3D', 
      Offset(centerX, 20), 14, bold: true);
  }
  
  void _drawText(Canvas canvas, String text, Offset position, double fontSize, {bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF000000),
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
  }
  
  @override
  bool shouldRepaint(covariant Room3DPainter oldDelegate) {
    return oldDelegate.ancho != ancho ||
           oldDelegate.largo != largo ||
           oldDelegate.altura != altura;
  }
}
