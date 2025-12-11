import 'dart:io';
import 'dart:convert';
import 'dart:math' show cos, sin;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../models/room_features.dart';
import '../../models/room_item.dart';
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
    _loadRoom(); // Cargar el room completo con sus items
  }

  Future<void> _loadRoom() async {
    setState(() => _isLoading = true);
    try {
      final room = await _inventoryService.getRoom(widget.room.propertyId, widget.room.id);
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

  /// Helper para construir widget de imagen según plataforma
  Widget _buildImageWidget(String imagePath, BoxFit fit, {double? height}) {
    // Data URL (base64) - usado en web
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
          },
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
      }
    }
    
    // URL (http/https) - network image
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: fit,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: AppTheme.dorado,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
        },
      );
    }
    
    // Path local - file image (solo para casos específicos)
    try {
      return Image.file(
        File(imagePath),
        fit: fit,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
        },
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
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
          child: CircularProgressIndicator(color: Color(0xFFFAB334)),
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

  Future<void> _addRoomPhotos() async {
    // Mostrar diálogo para elegir entre cámara o galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Fotos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || _room == null) return;

    try {
      if (source == ImageSource.camera) {
        // ✅ FIX: Envolver toma de foto en try-catch más específico
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,  // Limitar tamaño para evitar OOM
          maxHeight: 1080,
        ).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error al acceder a la cámara: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        });
        
        if (photo != null) {
          // En web, convertir a Data URL para que funcione la visualización
          String photoPath;
          if (kIsWeb) {
            final bytes = await photo.readAsBytes();
            final base64String = base64Encode(bytes);
            photoPath = 'data:image/png;base64,$base64String';
          } else {
            photoPath = photo.path;
          }
          
          await _inventoryService.addRoomPhoto(_room!.propertyId, _room!.id, photoPath);
          await _loadRoom();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Foto agregada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Seleccionar múltiples de galería
        final List<XFile> photos = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        
        if (photos.isNotEmpty) {
          for (final photo in photos) {
            // En web, convertir a Data URL para que funcione la visualización
            String photoPath;
            if (kIsWeb) {
              final bytes = await photo.readAsBytes();
              final base64String = base64Encode(bytes);
              photoPath = 'data:image/png;base64,$base64String';
            } else {
              photoPath = photo.path;
            }
            
            await _inventoryService.addRoomPhoto(_room!.propertyId, _room!.id, photoPath);
          }
          await _loadRoom();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${photos.length} fotos agregadas'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Métodos deprecados - mantener por compatibilidad pero redirigir al nuevo
  @Deprecated('Usar _addRoomPhotos() que incluye ambas opciones')
  Future<void> _takePhoto() async {
    await _addRoomPhotos();
  }

  @Deprecated('Usar _addRoomPhotos() que incluye ambas opciones')
  Future<void> _pickFromGallery() async {
    await _addRoomPhotos();
  }

  Future<void> _take360Photo() async {
    // Mostrar diálogo para elegir entre cámara o galería para foto 360°
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Foto 360°'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || _room == null) return;

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      
      if (photo != null) {
        // ✅ FIX: Convertir a Data URL en web para compatibilidad
        String photoPath;
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          final base64String = base64Encode(bytes);
          photoPath = 'data:image/png;base64,$base64String';
        } else {
          photoPath = photo.path;
        }
        
        await _inventoryService.setRoom360Photo(_room!.propertyId, _room!.id, photoPath);
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
          SnackBar(content: Text('Error con foto 360°: $e')),
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
        await _inventoryService.deleteRoom(_room!.propertyId, _room!.id);
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

  /// Muestra la vista isométrica 3D en un diálogo flotante interactivo
  void _show3DVisualization() {
    if (_room == null || _room!.ancho == null || _room!.largo == null || _room!.altura == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Interactive3DViewer(
        ancho: _room!.ancho!,
        largo: _room!.largo!,
        altura: _room!.altura!,
        roomName: _room!.nombre,
      ),
    );
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

  /// Mostrar galería de fotos del espacio
  void _showPhotoGallery() {
    if (_room == null || _room!.fotos.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _PhotoGalleryDialog(
        photos: _room!.fotos,
        roomName: _room!.nombre,
      ),
    );
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
              
              // Botón para abrir Vista Isométrica 3D (si hay todas las dimensiones)
              if (_room!.ancho != null && _room!.largo != null && _room!.altura != null) ...[
                ElevatedButton.icon(
                  onPressed: () => _show3DVisualization(),
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('Vista Isométrica 3D'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.grisOscuro,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      if (_room!.areaPiso != null)
                        _buildInfoRow('🔲 Área de piso (materiales)', '${_room!.areaPiso!.toStringAsFixed(2)} m²',
                            highlight: true, color: Colors.orange),
                      if (_room!.areaParedes != null)
                        _buildInfoRow('🎨 Área paredes + techo (pintura)', '${_room!.areaParedes!.toStringAsFixed(2)} m²',
                            highlight: true, color: Colors.green),
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
            
            // Botón unificado de captura de fotos
            ElevatedButton.icon(
              onPressed: _addRoomPhotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar Fotos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.negro,
              ),
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
            SizedBox(height: AppTheme.spacingSM),
            
            // Botón Ver Fotos (SIEMPRE VISIBLE)
            ElevatedButton.icon(
              onPressed: _room!.fotos.isEmpty ? null : _showPhotoGallery,
              icon: const Icon(Icons.photo_library),
              label: Text(_room!.fotos.isEmpty 
                ? 'Ver Fotos (0)' 
                : 'Ver Fotos (${_room!.fotos.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _room!.fotos.isEmpty 
                  ? AppTheme.grisClaro.withValues(alpha: 0.3)
                  : AppTheme.grisOscuro,
                foregroundColor: _room!.fotos.isEmpty 
                  ? AppTheme.grisClaro
                  : AppTheme.dorado,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

            // Elementos del Inventario
            const Text(
              'Elementos del Inventario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.spacingSM),
            
            if (_room!.items.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingMD),
                  child: const Center(
                    child: Text(
                      'No hay elementos registrados.\nAgrega pisos, paredes, puertas, etc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.grisClaro),
                    ),
                  ),
                ),
              )
            else
              ...(_room!.items.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      _showItemDetailDialog(item);
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.dorado,
                      foregroundColor: AppTheme.negro,
                      child: Text(
                        item.cantidad.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      item.nombreElemento,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Material: ${item.nombreMaterial}'),
                        Text('${item.estado.emoji} ${item.estado.displayName}'),
                        if (item.comentarios != null && item.comentarios!.isNotEmpty)
                          Text(
                            item.comentarios!,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        if (item.fotos.isNotEmpty)
                          Text(
                            '📷 ${item.fotos.length} foto(s)',
                            style: const TextStyle(color: AppTheme.dorado),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.fotos.isNotEmpty)
                          const Icon(Icons.photo_library, color: AppTheme.dorado),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: AppTheme.grisClaro),
                      ],
                    ),
                  ),
                );
              }).toList()),
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
                    child: _buildImageWidget(photoPath, BoxFit.cover),
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
              GestureDetector(
                onTap: () {
                  // Mostrar foto 360° en pantalla completa
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          title: const Text('Foto 360°'),
                          leading: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: _buildImageWidget(_room!.foto360Url!, BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      child: _buildImageWidget(_room!.foto360Url!, BoxFit.cover, height: 200),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.panorama_photosphere, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Toca para ver en pantalla completa',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacingMD),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[600],
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo con detalles completos de un elemento del inventario
  void _showItemDetailDialog(RoomItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item.tipo.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.dorado,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cantidad
              _buildDetailRow('Cantidad', '${item.cantidad}'),
              const Divider(),
              
              // Material
              _buildDetailRow('Material', item.material.displayName),
              const Divider(),
              
              // Estado
              _buildDetailRow('Estado', '${item.estado.emoji} ${item.estado.displayName}'),
              const Divider(),
              
              // Comentarios
              if (item.comentarios != null && item.comentarios!.isNotEmpty) ...[
                _buildDetailRow('Comentarios', item.comentarios!),
                const Divider(),
              ],
              
              // Fotografías del elemento
              if (item.fotos.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Fotografías del elemento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: item.fotos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showFullScreenImage(item.fotos[index]);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(
                          item.fotos[index],
                          BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Helper para construir filas de detalles
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Mostrar imagen en pantalla completa
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: _buildImageWidget(imageUrl, BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
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
      ..color = const Color(0xFFFAB334)
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

/// Widget interactivo para visualizar el espacio en 3D con controles de rotación
class Interactive3DViewer extends StatefulWidget {
  final double ancho;
  final double largo;
  final double altura;
  final String roomName;

  const Interactive3DViewer({
    super.key,
    required this.ancho,
    required this.largo,
    required this.altura,
    required this.roomName,
  });

  @override
  State<Interactive3DViewer> createState() => _Interactive3DViewerState();
}

class _Interactive3DViewerState extends State<Interactive3DViewer> {
  double _rotationAngle = 0.0; // Ángulo de rotación en grados (0-360)
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.grisOscuro,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppTheme.dorado, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dorado.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con título y botón de cerrar
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMD),
              decoration: BoxDecoration(
                color: AppTheme.negro,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLG),
                  topRight: Radius.circular(AppTheme.radiusLG),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.dorado, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.view_in_ar, color: AppTheme.dorado, size: 28),
                  SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vista Isométrica 3D',
                          style: TextStyle(
                            color: AppTheme.dorado,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.roomName,
                          style: TextStyle(
                            color: AppTheme.blanco.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón cerrar (X)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppTheme.blanco,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            
            // Área de visualización 3D
            Expanded(
              child: Container(
                padding: EdgeInsets.all(AppTheme.paddingLG),
                child: CustomPaint(
                  painter: Rotatable3DPainter(
                    ancho: widget.ancho,
                    largo: widget.largo,
                    altura: widget.altura,
                    rotationAngle: _rotationAngle,
                  ),
                  child: Container(),
                ),
              ),
            ),
            
            // Panel de información de dimensiones (scrollable)
            Container(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.paddingMD,
              ),
              decoration: BoxDecoration(
                color: AppTheme.negro.withValues(alpha: 0.5),
              ),
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingSM),
                children: [
                  _buildDimensionChip('↔ Ancho', widget.ancho),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('↕ Largo', widget.largo),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('⬆ Altura', widget.altura),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('📐 Área', widget.ancho * widget.largo, suffix: 'm²'),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('🧊 Volumen', widget.ancho * widget.largo * widget.altura, suffix: 'm³'),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('🔲 Piso', widget.ancho * widget.largo, suffix: 'm²', color: Colors.orange),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildDimensionChip('🎨 Paredes', 
                    2 * (widget.ancho * widget.altura) + 2 * (widget.largo * widget.altura) + (widget.ancho * widget.largo), 
                    suffix: 'm²', 
                    color: Colors.green),
                ],
              ),
            ),
            
            // Controles de rotación
            Container(
              padding: EdgeInsets.all(AppTheme.paddingLG),
              decoration: BoxDecoration(
                color: AppTheme.negro,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusLG),
                  bottomRight: Radius.circular(AppTheme.radiusLG),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.dorado.withValues(alpha: 0.3), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.rotate_right, color: AppTheme.dorado, size: 20),
                      SizedBox(width: AppTheme.spacingSM),
                      Text(
                        'Rotación: ${_rotationAngle.toInt()}°',
                        style: TextStyle(
                          color: AppTheme.blanco,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Row(
                    children: [
                      // Botón rotar izquierda
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _rotationAngle = (_rotationAngle - 15) % 360;
                          });
                        },
                        icon: const Icon(Icons.rotate_left),
                        color: AppTheme.dorado,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.grisOscuro,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Rotar -15°',
                      ),
                      
                      // Slider de rotación
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppTheme.dorado,
                            inactiveTrackColor: AppTheme.grisClaro,
                            thumbColor: AppTheme.dorado,
                            overlayColor: AppTheme.dorado.withValues(alpha: 0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _rotationAngle,
                            min: 0,
                            max: 360,
                            divisions: 24, // 15 grados por división
                            onChanged: (value) {
                              setState(() {
                                _rotationAngle = value;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // Botón rotar derecha
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _rotationAngle = (_rotationAngle + 15) % 360;
                          });
                        },
                        icon: const Icon(Icons.rotate_right),
                        color: AppTheme.dorado,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.grisOscuro,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Rotar +15°',
                      ),
                      
                      // Botón reset
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _rotationAngle = 0;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        color: AppTheme.blanco,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.dorado,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Resetear vista',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDimensionChip(String label, double value, {String suffix = 'm', Color? color}) {
    final chipColor = color ?? AppTheme.dorado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.grisClaro,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)} $suffix',
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para vista 3D con capacidad de rotación
class Rotatable3DPainter extends CustomPainter {
  final double ancho;
  final double largo;
  final double altura;
  final double rotationAngle; // En grados

  Rotatable3DPainter({
    required this.ancho,
    required this.largo,
    required this.altura,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Escala para que el espacio quepa en el canvas
    final maxDimension = [ancho, largo, altura].reduce((a, b) => a > b ? a : b);
    final scale = (size.width * 0.5) / maxDimension;
    
    // Centro del canvas
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Dimensiones escaladas
    final w = ancho * scale;
    final l = largo * scale;
    final h = altura * scale;
    
    // Convertir ángulo a radianes
    final rotationRad = rotationAngle * 3.14159 / 180;
    
    // Transformación isométrica con rotación
    Offset iso(double x, double y, double z) {
      // Aplicar rotación alrededor del eje Y
      final xRot = x * cos(rotationRad) - y * sin(rotationRad);
      final yRot = x * sin(rotationRad) + y * cos(rotationRad);
      
      // Proyección isométrica
      final cosAngle = 0.866; // cos(30°)
      final sinAngle = 0.5;   // sin(30°)
      
      return Offset(
        centerX + (xRot - yRot) * cosAngle,
        centerY + (xRot + yRot) * sinAngle - z,
      );
    }
    
    // Definir vértices del cubo
    final v1 = iso(0, 0, 0);        // Base frontal izquierda
    final v2 = iso(w, 0, 0);        // Base frontal derecha
    final v3 = iso(w, l, 0);        // Base trasera derecha
    final v4 = iso(0, l, 0);        // Base trasera izquierda
    final v5 = iso(0, 0, h);        // Techo frontal izquierda
    final v6 = iso(w, 0, h);        // Techo frontal derecha
    final v7 = iso(w, l, h);        // Techo trasera derecha
    final v8 = iso(0, l, h);        // Techo trasera izquierda
    
    // Pinturas con variación de color según rotación
    final baseColor = 220 - (rotationAngle / 360 * 40).toInt();
    
    final paintFloor = Paint()
      ..color = Color.fromRGBO(baseColor + 30, baseColor + 30, baseColor + 30, 1)
      ..style = PaintingStyle.fill;
      
    final paintWallLeft = Paint()
      ..color = Color.fromRGBO(baseColor + 10, baseColor + 10, baseColor + 10, 1)
      ..style = PaintingStyle.fill;
      
    final paintWallRight = Paint()
      ..color = Color.fromRGBO(baseColor - 10, baseColor - 10, baseColor - 10, 1)
      ..style = PaintingStyle.fill;
      
    final paintEdges = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
      
    final paintDimensions = Paint()
      ..color = const Color(0xFFFAB334)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Dibujar caras (orden depende de la rotación para correcto z-ordering)
    _drawFaces(canvas, v1, v2, v3, v4, v5, v6, v7, v8, 
               paintFloor, paintWallLeft, paintWallRight, paintEdges);
    
    // Dibujar líneas de dimensiones
    _drawDimensions(canvas, v1, v2, v4, v5, v8, paintDimensions);
  }
  
  void _drawFaces(Canvas canvas, Offset v1, Offset v2, Offset v3, Offset v4,
                  Offset v5, Offset v6, Offset v7, Offset v8,
                  Paint paintFloor, Paint paintWallLeft, Paint paintWallRight, Paint paintEdges) {
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
    
    // Dibujar cara derecha/frontal
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
  }
  
  void _drawDimensions(Canvas canvas, Offset v1, Offset v2, Offset v4, Offset v5, Offset v8, Paint paint) {
    // Ancho (frontal)
    canvas.drawLine(
      Offset(v1.dx, v1.dy + 20),
      Offset(v2.dx, v2.dy + 20),
      paint,
    );
    _drawText(canvas, '${ancho.toStringAsFixed(1)}m', 
      Offset((v1.dx + v2.dx) / 2, v1.dy + 35), 13, bold: true);
    
    // Largo (lateral)
    canvas.drawLine(
      Offset(v4.dx - 20, v4.dy),
      Offset(v8.dx - 20, v8.dy),
      paint,
    );
    _drawText(canvas, '${largo.toStringAsFixed(1)}m',
      Offset(v4.dx - 40, (v4.dy + v8.dy) / 2), 13, bold: true);
    
    // Altura (vertical)
    canvas.drawLine(
      Offset(v1.dx - 20, v1.dy),
      Offset(v5.dx - 20, v5.dy),
      paint,
    );
    _drawText(canvas, '${altura.toStringAsFixed(1)}m',
      Offset(v1.dx - 45, (v1.dy + v5.dy) / 2), 13, bold: true);
  }
  
  void _drawText(Canvas canvas, String text, Offset position, double fontSize, {bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFAB334),
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant Rotatable3DPainter oldDelegate) {
    return oldDelegate.ancho != ancho ||
           oldDelegate.largo != largo ||
           oldDelegate.altura != altura ||
           oldDelegate.rotationAngle != rotationAngle;
  }
}

/// Helper global para construir widget de imagen según tipo de ruta
Widget _buildImageWidgetGlobal(String imagePath, BoxFit fit, {double? height}) {
  // Data URL (base64) - usado en web
  if (imagePath.startsWith('data:image')) {
    try {
      final base64String = imagePath.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: fit,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
        },
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
    }
  }
  
  // URL (http/https) - network image
  if (imagePath.startsWith('http')) {
    return Image.network(
      imagePath,
      fit: fit,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: AppTheme.dorado,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
      },
    );
  }
  
  // Path local - file image (solo para casos específicos)
  try {
    return Image.file(
      File(imagePath),
      fit: fit,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
      },
    );
  } catch (e) {
    return const Icon(Icons.broken_image, size: 64, color: Colors.grey);
  }
}

/// Widget de galería de fotos flotante
class _PhotoGalleryDialog extends StatefulWidget {
  final List<String> photos;
  final String roomName;

  const _PhotoGalleryDialog({
    required this.photos,
    required this.roomName,
  });

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: AppTheme.negro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dorado, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.dorado, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, color: AppTheme.dorado),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotos de ${widget.roomName}',
                          style: const TextStyle(
                            color: AppTheme.blanco,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} de ${widget.photos.length}',
                          style: const TextStyle(
                            color: AppTheme.grisClaro,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.blanco),
                  ),
                ],
              ),
            ),

            // Galería con PageView
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: _buildImageWidgetGlobal(widget.photos[index], BoxFit.contain),
                        ),
                      );
                    },
                  ),

                  // Botón anterior
                  if (_currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.grisOscuro.withValues(alpha: 0.8),
                            foregroundColor: AppTheme.dorado,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),

                  // Botón siguiente
                  if (_currentIndex < widget.photos.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.grisOscuro.withValues(alpha: 0.8),
                            foregroundColor: AppTheme.dorado,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Indicadores de página (thumbnails)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.photos.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppTheme.dorado : AppTheme.grisClaro,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildImageWidgetGlobal(
                            widget.photos[index],
                            BoxFit.cover,
                            height: 60,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
