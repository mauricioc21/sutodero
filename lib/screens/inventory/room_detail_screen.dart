import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../models/room_features.dart';
import '../../services/inventory_service.dart';
import '../../services/floor_plan_service.dart';
import 'add_edit_room_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _inventoryService = InventoryService();
  final _floorPlanService = FloorPlanService();
  final _imagePicker = ImagePicker();
  PropertyRoom? _room;
  bool _isLoading = true;
  bool _isGeneratingFloorPlan = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    setState(() => _isLoading = true);
    try {
      final room = await _inventoryService.getRoom(widget.roomId);
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
      final floorPlan = await _floorPlanService.generateRoomFloorPlan(_room!.id);
      
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
                  const SizedBox(height: 8),
                  Text('📐 Dimensiones: ${_room!.ancho ?? "N/A"} x ${_room!.largo ?? "N/A"} m'),
                  Text('📷 Fotos: ${_room!.fotos.length}'),
                  Text('🔄 Foto 360°: ${_room!.tiene360 ? "Sí" : "No"}'),
                  if (_room!.area != null)
                    Text('📏 Área: ${_room!.area!.toStringAsFixed(2)} m²'),
                  const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(16),
          children: [
            // Encabezado con tipo y estado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _room!.tipo.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 16),
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
                                  const SizedBox(width: 8),
                                  Text('•'),
                                  const SizedBox(width: 8),
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
                      const SizedBox(height: 12),
                      Text(_room!.descripcion!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dimensiones
            if (_room!.ancho != null || _room!.largo != null || _room!.altura != null) ...[
              const Text(
                'Dimensiones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_room!.ancho != null)
                        _buildInfoRow('Ancho', '${_room!.ancho} m'),
                      if (_room!.largo != null)
                        _buildInfoRow('Largo', '${_room!.largo} m'),
                      if (_room!.altura != null)
                        _buildInfoRow('Altura', '${_room!.altura} m'),
                      if (_room!.area != null)
                        _buildInfoRow('Área', '${_room!.area!.toStringAsFixed(2)} m²',
                            highlight: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
            ],

            // Sección de fotos
            const Text(
              'Fotos del Espacio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
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
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Botón foto 360°
            ElevatedButton.icon(
              onPressed: _take360Photo,
              icon: const Icon(Icons.panorama_photosphere),
              label: Text(_room!.tiene360 ? 'Reemplazar Foto 360°' : 'Tomar Foto 360°'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón generar plano
            ElevatedButton.icon(
              onPressed: _isGeneratingFloorPlan ? null : _generateFloorPlan,
              icon: _isGeneratingFloorPlan
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.architecture),
              label: Text(_isGeneratingFloorPlan ? 'Generando Plano...' : 'Generar Plano del Espacio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF2C2C2C),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

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
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Foto 360°
            if (_room!.tiene360) ...[
              const Text(
                'Foto 360°',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_room!.foto360Url!),
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
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
