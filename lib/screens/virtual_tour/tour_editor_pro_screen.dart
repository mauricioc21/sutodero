import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';

class TourEditorProScreen extends StatefulWidget {
  final Map<String, dynamic> tourData;

  const TourEditorProScreen({
    Key? key,
    required this.tourData,
  }) : super(key: key);

  @override
  State<TourEditorProScreen> createState() => _TourEditorProScreenState();
}

class _TourEditorProScreenState extends State<TourEditorProScreen> {
  // Estado del Tour
  late Map<String, dynamic> _tour;
  List<dynamic> _scenes = [];
  String _activeSceneId = "";
  int _activeSceneIndex = 0;
  
  // Estado de la Interfaz
  bool _isPreviewMode = false;
  bool _isSaving = false;
  
  // Estado de Edición
  String? _movingHotspotId; // Si no es null, el próximo click mueve este hotspot

  @override
  void initState() {
    super.initState();
    _loadTour();
  }

  // ------------------------------------------------------------------------
  // 1. GESTIÓN DE DATOS Y CARGA (Load & Save)
  // ------------------------------------------------------------------------

  void _loadTour() {
    // Clonación profunda para evitar mutaciones directas a referencias externas
    _tour = jsonDecode(jsonEncode(widget.tourData));
    _scenes = _tour['scenes'];

    if (_scenes.isNotEmpty) {
      _activeSceneId = _scenes[0]['id'];
      _activeSceneIndex = 0;
    }
  }

  Future<void> _saveTour() async {
    setState(() => _isSaving = true);

    try {
      // 1. Actualizar Timestamp
      _tour['updatedAt'] = DateTime.now().toIso8601String();

      // 2. Simulación de Guardado Local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_tour_${_tour['tourId']}', jsonEncode(_tour));

      // 3. Simulación de llamada a API POST /api/tours/update
      // await http.post(Uri.parse('/api/tours/update'), body: jsonEncode(_tour));
      
      await Future.delayed(const Duration(milliseconds: 800)); // Simular red

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ------------------------------------------------------------------------
  // 2. GESTIÓN DE ESCENAS (CRUD Scene)
  // ------------------------------------------------------------------------

  void _setActiveScene(String sceneId) {
    final index = _scenes.indexWhere((s) => s['id'] == sceneId);
    if (index != -1) {
      setState(() {
        _activeSceneId = sceneId;
        _activeSceneIndex = index;
        _movingHotspotId = null; // Cancelar movimiento si cambiamos escena
      });
    }
  }

  void _updateSceneTitle(int index, String newTitle) {
    setState(() {
      _scenes[index]['title'] = newTitle;
    });
  }

  Future<void> _replaceSceneImage(int index) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _scenes[index]['imageUri'] = image.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen 360° actualizada')),
      );
    }
  }

  void _deleteScene(int index) {
    if (_scenes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ El tour debe tener al menos una escena')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.negro,
        title: const Text('Eliminar Escena', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro? Esto eliminará también los hotspots que apunten aquí.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                String deletedId = _scenes[index]['id'];
                _scenes.removeAt(index);
                
                // Limpiar hotspots huérfanos en otras escenas
                for (var scene in _scenes) {
                  List hotspots = scene['hotspots'] ?? [];
                  hotspots.removeWhere((h) => h['targetSceneId'] == deletedId);
                }

                // Ajustar escena activa
                if (_activeSceneId == deletedId) {
                  _activeSceneIndex = 0;
                  _activeSceneId = _scenes[0]['id'];
                } else {
                  // Recalcular índice
                  _activeSceneIndex = _scenes.indexWhere((s) => s['id'] == _activeSceneId);
                }
              });
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reorderScenes(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _scenes.removeAt(oldIndex);
      _scenes.insert(newIndex, item);
      // Actualizar índice activo
      _activeSceneIndex = _scenes.indexWhere((s) => s['id'] == _activeSceneId);
    });
  }

  // ------------------------------------------------------------------------
  // 3. GESTIÓN DE HOTSPOTS (CRUD Hotspot)
  // ------------------------------------------------------------------------

  void _onPanoramaTap(double longitude, double latitude, double tilt) {
    if (_isPreviewMode) return;

    if (_movingHotspotId != null) {
      // Estamos moviendo un hotspot existente
      _finishMovingHotspot(longitude, latitude);
    } else {
      // Estamos creando uno nuevo
      _openAddHotspotDialog(longitude, latitude);
    }
  }

  void _openAddHotspotDialog(double longitude, double latitude) {
    String? targetSceneId;
    String hotspotTitle = "";
    
    // Filtrar escenas disponibles (no podemos ir a la misma escena)
    final availableScenes = _scenes.where((s) => s['id'] != _activeSceneId).toList();

    if (availableScenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Necesitas al menos 2 escenas para crear conexiones')),
      );
      return;
    }

    targetSceneId = availableScenes.first['id'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.negro,
              title: const Text('Nuevo Hotspot', style: TextStyle(color: AppTheme.dorado)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Selecciona la escena destino:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: targetSceneId,
                    dropdownColor: AppTheme.grisOscuro,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: availableScenes.map<DropdownMenuItem<String>>((s) {
                      return DropdownMenuItem<String>(
                        value: s['id'],
                        child: Text(s['title']),
                      );
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => targetSceneId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Título (Opcional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.dorado)),
                    ),
                    onChanged: (val) => hotspotTitle = val,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dorado),
                  onPressed: () {
                    _addHotspot(targetSceneId!, hotspotTitle, longitude, latitude);
                    Navigator.pop(context);
                  },
                  child: const Text('Crear', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addHotspot(String targetId, String title, double lon, double lat) {
    setState(() {
      final currentScene = _scenes[_activeSceneIndex];
      if (currentScene['hotspots'] == null) {
        currentScene['hotspots'] = [];
      }
      (currentScene['hotspots'] as List).add({
        "id": "hotspot-${DateTime.now().millisecondsSinceEpoch}",
        "targetSceneId": targetId,
        "text": title.isEmpty ? null : title,
        "longitude": lon, // Mapping Yaw
        "latitude": lat,  // Mapping Pitch
      });
    });
  }

  void _updateHotspot(String hotspotId, String? newTargetId, String? newTitle) {
    setState(() {
      final currentScene = _scenes[_activeSceneIndex];
      final hotspots = currentScene['hotspots'] as List;
      final index = hotspots.indexWhere((h) => h['id'] == hotspotId);
      
      if (index != -1) {
        if (newTargetId != null) hotspots[index]['targetSceneId'] = newTargetId;
        hotspots[index]['text'] = newTitle; // Puede ser null
      }
    });
  }

  void _deleteHotspot(String hotspotId) {
    setState(() {
      final currentScene = _scenes[_activeSceneIndex];
      (currentScene['hotspots'] as List).removeWhere((h) => h['id'] == hotspotId);
    });
  }

  void _startMovingHotspot(String hotspotId) {
    setState(() {
      _movingHotspotId = hotspotId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Toca en el visor la nueva posición para el hotspot'),
        duration: Duration(seconds: 4),
        backgroundColor: AppTheme.dorado,
      ),
    );
  }

  void _finishMovingHotspot(double lon, double lat) {
    setState(() {
      final currentScene = _scenes[_activeSceneIndex];
      final hotspots = currentScene['hotspots'] as List;
      final index = hotspots.indexWhere((h) => h['id'] == _movingHotspotId);
      
      if (index != -1) {
        hotspots[index]['longitude'] = lon;
        hotspots[index]['latitude'] = lat;
      }
      _movingHotspotId = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Posición actualizada')),
    );
  }

  // ------------------------------------------------------------------------
  // 4. UI BUILDERS
  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_scenes.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentScene = _scenes[_activeSceneIndex];

    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: _isPreviewMode ? null : _buildAppBar(),
      body: Stack(
        children: [
          // CAPA 1: VISOR 360
          _buildPanoramaViewer(currentScene),

          // CAPA 2: OVERLAY MODO MOVIMIENTO
          if (_movingHotspotId != null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: const Text('MODO REUBICACIÓN: Toca la nueva posición', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          // CAPA 3: BOTÓN SALIR VISTA PREVIA
          if (_isPreviewMode)
            Positioned(
              top: 40,
              left: 20,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                child: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => setState(() => _isPreviewMode = false),
              ),
            ),

          // CAPA 4: PANEL DE ESCENAS (Solo en modo edición)
          if (!_isPreviewMode)
            _buildBottomScenePanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Editor Profesional 360°'),
      backgroundColor: AppTheme.grisOscuro,
      foregroundColor: AppTheme.dorado,
      actions: [
        IconButton(
          icon: Icon(_isPreviewMode ? Icons.visibility_off : Icons.visibility),
          tooltip: 'Vista Previa',
          onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
        ),
        IconButton(
          icon: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.dorado))
            : const Icon(Icons.save),
          tooltip: 'Guardar Tour',
          onPressed: _isSaving ? null : _saveTour,
        ),
      ],
    );
  }

  Widget _buildPanoramaViewer(Map<String, dynamic> scene) {
    ImageProvider imageProvider = _getImageProvider(scene['imageUri']);

    return PanoramaViewer(
      key: ValueKey(scene['id']), // Forzar recarga al cambiar escena
      animSpeed: 0.5,
      sensorControl: SensorControl.orientation,
      onTap: _onPanoramaTap, // Captura coordenadas (pitch/yaw)
      hotspots: _buildHotspotWidgets(scene['hotspots']),
      child: Image(image: imageProvider),
    );
  }

  List<Hotspot> _buildHotspotWidgets(List? hotspotsData) {
    if (hotspotsData == null) return [];

    return hotspotsData.map((h) {
      bool isMovingTarget = h['id'] == _movingHotspotId;

      return Hotspot(
        latitude: (h['latitude'] ?? 0.0).toDouble(),
        longitude: (h['longitude'] ?? 0.0).toDouble(),
        width: 70,
        height: 70,
        widget: GestureDetector(
          onTap: () {
            if (_isPreviewMode) {
              // Navegación
              _setActiveScene(h['targetSceneId']);
            } else {
              // Edición
              _showEditHotspotDialog(h);
            }
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMovingTarget ? Colors.orange : AppTheme.dorado.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 4)],
                ),
                child: Icon(
                  Icons.input, 
                  color: isMovingTarget ? Colors.white : Colors.black, 
                  size: 24
                ),
              ),
              if (h['text'] != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: Text(h['text'], style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showEditHotspotDialog(Map<String, dynamic> hotspot) {
    if (_movingHotspotId != null) return; // No editar mientras se mueve

    String? currentTarget = hotspot['targetSceneId'];
    String title = hotspot['text'] ?? "";
    final availableScenes = _scenes.where((s) => s['id'] != _activeSceneId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.grisOscuro,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar Hotspot', style: TextStyle(color: AppTheme.dorado, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Destino:', style: TextStyle(color: Colors.grey)),
            DropdownButton<String>(
              value: availableScenes.any((s) => s['id'] == currentTarget) ? currentTarget : null,
              dropdownColor: Colors.black,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: availableScenes.map<DropdownMenuItem<String>>((s) {
                return DropdownMenuItem<String>(
                  value: s['id'],
                  child: Text(s['title']),
                );
              }).toList(),
              onChanged: (val) {
                _updateHotspot(hotspot['id'], val, title);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.open_with, 'Mover', () {
                  Navigator.pop(context);
                  _startMovingHotspot(hotspot['id']);
                }),
                _buildActionButton(Icons.delete, 'Eliminar', () {
                  Navigator.pop(context);
                  _deleteHotspot(hotspot['id']);
                }, color: Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildBottomScenePanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.15,
      maxChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.grisOscuro.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _scenes.length,
                  onReorder: _reorderScenes,
                  itemBuilder: (context, index) {
                    final scene = _scenes[index];
                    final isActive = scene['id'] == _activeSceneId;

                    return Container(
                      key: ValueKey(scene['id']),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.dorado.withOpacity(0.15) : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? AppTheme.dorado : Colors.transparent),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: GestureDetector(
                          onTap: () => _replaceSceneImage(index),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 50, 
                                height: 50, 
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: _buildThumbnail(scene['imageUri'])
                                )
                              ),
                              const Icon(Icons.edit, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                        title: isActive 
                          ? TextFormField(
                              initialValue: scene['title'],
                              style: const TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                              onChanged: (val) => _updateSceneTitle(index, val),
                            )
                          : Text(scene['title'], style: const TextStyle(color: Colors.white)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _deleteScene(index),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _setActiveScene(scene['id']),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Utilidad de Imagen
  ImageProvider _getImageProvider(String uri) {
    if (uri.startsWith('data:')) {
      return MemoryImage(base64Decode(uri.split(',')[1]));
    } else if (uri.startsWith('http')) {
      return NetworkImage(uri);
    } else {
      // Manejo de archivos locales (File) vs Web
      if (kIsWeb) return NetworkImage(uri);
      return FileImage(File(uri));
    }
  }

  Widget _buildThumbnail(String uri) {
    if (uri.startsWith('data:')) {
      return Image.memory(base64Decode(uri.split(',')[1]), fit: BoxFit.cover);
    } else if (uri.startsWith('http')) {
      return Image.network(uri, fit: BoxFit.cover);
    } else {
      return kIsWeb ? Image.network(uri, fit: BoxFit.cover) : Image.file(File(uri), fit: BoxFit.cover);
    }
  }
}
