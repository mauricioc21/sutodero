import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Constructor Avanzado de Tours 360° - Opción 1
/// Incluye editor de escenas, hotspots y vista previa en tiempo real
class AdvancedTourBuilderScreen extends StatefulWidget {
  final InventoryProperty property;

  const AdvancedTourBuilderScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<AdvancedTourBuilderScreen> createState() => _AdvancedTourBuilderScreenState();
}

class _AdvancedTourBuilderScreenState extends State<AdvancedTourBuilderScreen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  // Estado del constructor
  final List<TourScene> _scenes = [];
  int _currentSceneIndex = 0;
  bool _isUploading = false;
  bool _isSaving = false;
  
  // WebView para el editor
  late WebViewController _webViewController;
  bool _editorLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewEditor();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Inicializar editor WebView con Pannellum
  Future<void> _initializeWebViewEditor() async {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _editorLoaded = true;
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _handleEditorMessage(message.message);
          },
        )
        ..loadHtmlString(_getEditorHTML());
    } catch (e) {
      debugPrint('❌ Error al inicializar editor: $e');
    }
  }

  /// Manejar mensajes del editor
  void _handleEditorMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'hotspotAdded') {
        // Hotspot agregado desde el editor
        final hotspot = TourHotspot(
          yaw: data['yaw'].toDouble(),
          pitch: data['pitch'].toDouble(),
          targetSceneId: data['targetSceneId'],
          text: data['text'],
        );
        
        setState(() {
          _scenes[_currentSceneIndex].hotspots.add(hotspot);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hotspot agregado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al procesar mensaje del editor: $e');
    }
  }

  /// Agregar foto 360°
  Future<void> _addPhoto360() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Subir a Firebase Storage
      final String photoUrl = await _uploadPhotoToStorage(image);

      // Crear nueva escena
      final scene = TourScene(
        id: 'scene_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Escena ${_scenes.length + 1}',
        imageUrl: photoUrl,
        hotspots: [],
      );

      setState(() {
        _scenes.add(scene);
        _currentSceneIndex = _scenes.length - 1;
        _isUploading = false;
      });

      // Actualizar editor
      _loadSceneInEditor(_currentSceneIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto 360° agregada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Subir foto a Firebase Storage
  Future<String> _uploadPhotoToStorage(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64';
      
      final photoUrl = await _storageService.uploadInventoryActPhoto(
        actId: widget.property.id,
        filePath: dataUrl,
      );
      
      if (photoUrl == null) {
        throw Exception('Error al subir foto');
      }
      
      return photoUrl;
    } else {
      final photoUrl = await _storageService.uploadInventoryActPhoto(
        actId: widget.property.id,
        filePath: image.path,
      );
      
      if (photoUrl == null) {
        throw Exception('Error al subir foto');
      }
      
      return photoUrl;
    }
  }

  /// Cargar escena en el editor
  void _loadSceneInEditor(int index) {
    if (!_editorLoaded || index < 0 || index >= _scenes.length) return;

    final scene = _scenes[index];
    final sceneData = jsonEncode({
      'type': 'loadScene',
      'scene': {
        'id': scene.id,
        'title': scene.title,
        'image': scene.imageUrl,
        'hotspots': scene.hotspots.map((h) => {
          'yaw': h.yaw,
          'pitch': h.pitch,
          'targetSceneId': h.targetSceneId,
          'text': h.text,
        }).toList(),
      },
      'availableScenes': _scenes.map((s) => {
        'id': s.id,
        'title': s.title,
      }).toList(),
    });

    _webViewController.runJavaScript('''
      window.postMessage($sceneData, '*');
    ''');
  }

  /// Eliminar escena
  void _deleteScene(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          '¿Eliminar escena?',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${_scenes[index].title}"?',
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.blanco)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _scenes.removeAt(index);
                if (_currentSceneIndex >= _scenes.length) {
                  _currentSceneIndex = _scenes.length - 1;
                }
                if (_currentSceneIndex >= 0) {
                  _loadSceneInEditor(_currentSceneIndex);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Agregar hotspot a escena actual
  void _addHotspotToCurrentScene() {
    if (_scenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega al menos una escena primero'),
        ),
      );
      return;
    }

    if (_scenes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Necesitas al menos 2 escenas para crear hotspots'),
        ),
      );
      return;
    }

    // Solicitar al editor que agregue un hotspot en la posición actual
    _webViewController.runJavaScript('''
      window.postMessage({type: 'requestAddHotspot'}, '*');
    ''');
  }

  /// Guardar tour completo
  Future<void> _saveTour() async {
    if (_scenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega al menos una escena'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String description = _descriptionController.text.trim().isNotEmpty
          ? '[OP1] ${_descriptionController.text.trim()}'
          : '[OP1] Tour Virtual de ${widget.property.direccion}';

      final List<String> photo360Urls = _scenes.map((s) => s.imageUrl).toList();

      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: photo360Urls,
        description: description,
        tourOption: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VirtualTourOp1ViewerScreen(tour: tour),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Constructor de Tour 360° - Opción 1',
          style: TextStyle(
            color: AppTheme.dorado,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.dorado),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Información de propiedad
            _buildPropertyHeader(),

            // Editor principal (WebView con Pannellum)
            Expanded(
              flex: 3,
              child: _buildEditor(),
            ),

            // Lista de escenas
            _buildScenesList(),

            // Controles inferiores
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  /// Header con información de la propiedad
  Widget _buildPropertyHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border(
          bottom: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: AppTheme.dorado, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.property.direccion,
                  style: const TextStyle(
                    color: AppTheme.blanco,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: AppTheme.blanco, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Descripción del Tour',
              labelStyle: const TextStyle(color: AppTheme.dorado, fontSize: 12),
              hintText: 'Ej: Tour completo',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              filled: true,
              fillColor: AppTheme.negro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dorado, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Editor principal (WebView con Pannellum)
  Widget _buildEditor() {
    if (_scenes.isEmpty) {
      return Container(
        color: AppTheme.negro,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.panorama_photosphere_outlined,
                size: 80,
                color: AppTheme.dorado.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sube una imagen 360° para comenzar',
                style: TextStyle(
                  color: AppTheme.blanco,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: _editorLoaded
          ? WebViewWidget(controller: _webViewController)
          : const Center(
              child: CircularProgressIndicator(color: AppTheme.dorado),
            ),
    );
  }

  /// Lista horizontal de escenas
  Widget _buildScenesList() {
    if (_scenes.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border(
          top: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _scenes.length,
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final isActive = index == _currentSceneIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentSceneIndex = index;
              });
              _loadSceneInEditor(index);
            },
            onLongPress: () => _deleteScene(index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? AppTheme.dorado : Colors.grey,
                  width: isActive ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      scene.imageUrl,
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black54,
                      child: Text(
                        scene.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.dorado,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.negro,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Controles inferiores
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border(
          top: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información de escenas y hotspots
          if (_scenes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '📸 ${_scenes.length} escena(s)',
                    style: const TextStyle(
                      color: AppTheme.dorado,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_scenes.isNotEmpty)
                    Text(
                      '🎯 ${_scenes[_currentSceneIndex].hotspots.length} hotspot(s)',
                      style: const TextStyle(
                        color: AppTheme.dorado,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          // Botones principales
          Row(
            children: [
              // Agregar foto
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || _isSaving ? null : _addPhoto360,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.negro,
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate, size: 18),
                  label: Text(
                    _isUploading ? 'CARGANDO...' : 'AGREGAR FOTO 360°',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.negro,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Agregar hotspot
              if (_scenes.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading || _isSaving ? null : _addHotspotToCurrentScene,
                    icon: const Icon(Icons.add_location, size: 18),
                    label: const Text(
                      'HOTSPOT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              // Guardar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scenes.isEmpty || _isUploading || _isSaving ? null : _saveTour,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(
                    _isSaving ? 'GUARDANDO...' : 'GUARDAR',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// HTML del editor con Pannellum
  String _getEditorHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css"/>
  <script src="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; overflow: hidden; }
    #panorama { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <div id="panorama"></div>
  <script>
    let viewer = null;
    let currentScene = null;

    window.addEventListener('message', function(event) {
      const data = event.data;
      if (data.type === 'loadScene') {
        loadScene(data.scene, data.availableScenes);
      } else if (data.type === 'requestAddHotspot') {
        addHotspot();
      }
    });

    function loadScene(scene, availableScenes) {
      currentScene = scene;
      
      if (viewer) {
        viewer.destroy();
      }

      const hotspots = scene.hotspots.map(h => ({
        pitch: h.pitch,
        yaw: h.yaw,
        type: 'scene',
        text: h.text || 'Ir',
        createTooltipFunc: createCustomHotspot,
      }));

      viewer = pannellum.viewer('panorama', {
        type: 'equirectangular',
        panorama: scene.image,
        autoLoad: true,
        hotSpots: hotspots,
        showControls: false,
        mouseZoom: true,
        draggable: true,
      });
    }

    function createCustomHotspot(hotSpotDiv, args) {
      hotSpotDiv.style.width = '40px';
      hotSpotDiv.style.height = '40px';
      hotSpotDiv.style.background = '#FAB334';
      hotSpotDiv.style.borderRadius = '50%';
      hotSpotDiv.style.display = 'flex';
      hotSpotDiv.style.alignItems = 'center';
      hotSpotDiv.style.justifyContent = 'center';
      hotSpotDiv.style.color = '#1A1A1A';
      hotSpotDiv.style.fontWeight = 'bold';
      hotSpotDiv.innerHTML = '➤';
    }

    function addHotspot() {
      if (!viewer) return;

      const yaw = viewer.getYaw();
      const pitch = viewer.getPitch();

      // Enviar a Flutter
      FlutterChannel.postMessage(JSON.stringify({
        type: 'hotspotAdded',
        yaw: yaw,
        pitch: pitch,
        targetSceneId: 'next',
        text: 'Ir a escena',
      }));
    }
  </script>
</body>
</html>
    ''';
  }
}

/// Modelo de escena del tour
class TourScene {
  final String id;
  String title;
  final String imageUrl;
  final List<TourHotspot> hotspots;

  TourScene({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.hotspots,
  });
}

/// Modelo de hotspot (punto de navegación)
class TourHotspot {
  final double yaw;
  final double pitch;
  final String targetSceneId;
  final String text;

  TourHotspot({
    required this.yaw,
    required this.pitch,
    required this.targetSceneId,
    required this.text,
  });
}
