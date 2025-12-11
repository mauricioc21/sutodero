import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

// ==========================================
// 1. MODELOS DE DATOS (Tour, Scene, Hotspot)
// ==========================================

class TourModel {
  final String tourId;
  final List<SceneModel> scenes;

  TourModel({required this.tourId, required this.scenes});

  factory TourModel.fromJson(Map<String, dynamic> json) {
    return TourModel(
      tourId: json['tourId'] ?? 'unknown',
      scenes: (json['scenes'] as List?)
              ?.map((s) => SceneModel.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SceneModel {
  final String id;
  final String title;
  final String imageUri;
  final List<HotspotModel> hotspots;

  SceneModel({
    required this.id,
    required this.title,
    required this.imageUri,
    this.hotspots = const [],
  });

  factory SceneModel.fromJson(Map<String, dynamic> json) {
    return SceneModel(
      id: json['id'],
      title: json['title'] ?? 'Sin título',
      imageUri: json['imageUri'],
      hotspots: (json['hotspots'] as List?)
              ?.map((h) => HotspotModel.fromJson(h))
              .toList() ??
          [],
    );
  }
}

class HotspotModel {
  final String id;
  final String targetSceneId;
  final double pitch;
  final double yaw;
  final String? text;

  HotspotModel({
    required this.id,
    required this.targetSceneId,
    required this.pitch,
    required this.yaw,
    this.text,
  });

  factory HotspotModel.fromJson(Map<String, dynamic> json) {
    return HotspotModel(
      id: json['id'] ?? 'hs-${DateTime.now().millisecondsSinceEpoch}',
      targetSceneId: json['targetSceneId'] ?? '',
      pitch: (json['pitch'] ?? 0.0).toDouble(),
      yaw: (json['yaw'] ?? 0.0).toDouble(),
      text: json['text'],
    );
  }
}

// ==========================================
// 2. WIDGET DE HOTSPOT ANIMADO (Pulsing)
// ==========================================

class PulsingHotspotWidget extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const PulsingHotspotWidget({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PulsingHotspotWidget> createState() => _PulsingHotspotWidgetState();
}

class _PulsingHotspotWidgetState extends State<PulsingHotspotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Anillo pulsante
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Núcleo sólido con sombra (Efecto Matterport)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAB334), // Dorado corporativo
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA PRINCIPAL (Matterport Viewer)
// ==========================================

class MatterportViewerScreen extends StatefulWidget {
  final TourModel tour;
  final String? initialSceneId;

  const MatterportViewerScreen({
    Key? key,
    required this.tour,
    this.initialSceneId,
  }) : super(key: key);

  @override
  State<MatterportViewerScreen> createState() => _MatterportViewerScreenState();
}

class _MatterportViewerScreenState extends State<MatterportViewerScreen> {
  // Estado
  late SceneModel _currentScene;
  bool _isTransitioning = false; // Para el fade out/in
  bool _isAutoRotating = false;
  bool _isLoadingImage = true;
  double _overlayOpacity = 0.0; // 0.0 = invisible, 1.0 = negro total

  // Controladores
  // Usamos ValueKey en PanoramaViewer para forzar rebuild al cambiar escena

  @override
  void initState() {
    super.initState();
    // Cargar escena inicial
    if (widget.tour.scenes.isNotEmpty) {
      if (widget.initialSceneId != null) {
        _currentScene = widget.tour.scenes.firstWhere(
          (s) => s.id == widget.initialSceneId,
          orElse: () => widget.tour.scenes.first,
        );
      } else {
        _currentScene = widget.tour.scenes.first;
      }
    }
  }

  // --- LÓGICA DE NAVEGACIÓN ---

  Future<void> _loadScene(String sceneId) async {
    // 1. Evitar navegación si ya estamos transicionando
    if (_isTransitioning) return;
    
    final targetScene = widget.tour.scenes.firstWhere(
      (s) => s.id == sceneId,
      orElse: () => _currentScene,
    );

    if (targetScene.id == _currentScene.id) return;

    setState(() {
      _isTransitioning = true;
      _overlayOpacity = 1.0; // Fade a negro
    });

    // 2. Esperar duración del fade out (simular CSS transition ease-in-out)
    await Future.delayed(const Duration(milliseconds: 600));

    // 3. Cambiar datos de la escena
    setState(() {
      _currentScene = targetScene;
      _isLoadingImage = true; // Reiniciar loading
    });

    // Pequeña pausa para asegurar que el widget se reconstruya
    await Future.delayed(const Duration(milliseconds: 100));

    // 4. Fade in (revelar nueva escena)
    setState(() {
      _overlayOpacity = 0.0;
      _isTransitioning = false;
      _isLoadingImage = false; // Asumimos carga rápida o gestionada por image provider
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      _isAutoRotating = !_isAutoRotating;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tour.scenes.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No hay escenas en este tour', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CAPA VISOR 360 (Fondo)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: _isLoadingImage ? 0.0 : 1.0, // Fade suave al cargar imagen
            child: PanoramaViewer(
              key: ValueKey(_currentScene.id), // CRUCIAL para refrescar
              animSpeed: _isAutoRotating ? 0.8 : 0.0,
              sensorControl: SensorControl.orientation, // Giroscopio activo
              hotspots: _renderHotspots(),
              child: _buildImageProvider(_currentScene.imageUri),
            ),
          ),

          // 2. CAPA DE TRANSICIÓN (Negro Fade)
          IgnorePointer(
            ignoring: _overlayOpacity == 0.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              color: Colors.black.withOpacity(_overlayOpacity),
              child: _overlayOpacity > 0.5 
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFAB334),
                        strokeWidth: 2,
                      ),
                    ) 
                  : null,
            ),
          ),

          // 3. CAPA UI (Overlay estilo Matterport)
          SafeArea(
            child: Column(
              children: [
                // --- Top Bar: Título y Controles ---
                _buildTopBar(),

                const Spacer(),

                // --- Bottom Bar: Carrusel de Escenas ---
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS DE UI ---

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentScene.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAB334), // Green for active/live
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VISTA 360°',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botones Superiores
          Row(
            children: [
              _buildGlassIconButton(
                icon: _isAutoRotating ? Icons.pause_circle_outline : Icons.play_circle_outline,
                tooltip: _isAutoRotating ? 'Pausar Giro' : 'Auto Giro',
                onTap: _toggleAutoRotate,
              ),
              const SizedBox(width: 10),
              _buildGlassIconButton(
                icon: Icons.fullscreen,
                tooltip: 'Pantalla Completa',
                onTap: () {
                   // Implementar lógica fullscreen si se desea
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Modo inmersivo activado')),
                   );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Lista horizontal de escenas
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: widget.tour.scenes.length,
              itemBuilder: (context, index) {
                final scene = widget.tour.scenes[index];
                final isSelected = scene.id == _currentScene.id;

                return GestureDetector(
                  onTap: () => _loadScene(scene.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    width: isSelected ? 120 : 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFAB334) : Colors.white.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected 
                          ? [BoxShadow(color: const Color(0xFFFAB334).withOpacity(0.4), blurRadius: 8)] 
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Miniatura (Image)
                          _buildThumbnail(scene.imageUri),
                          
                          // Gradiente texto
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black87, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Text(
                                scene.title,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFFAB334) : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          // Indicador Activo
                          if (isSelected)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.threesixty, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            tooltip: tooltip,
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  // --- IMAGENES ---

  Image _buildImageProvider(String uri) {
    try {
      if (uri.startsWith('data:')) {
        return Image.memory(
          base64Decode(uri.split(',')[1]),
          fit: BoxFit.cover,
          gaplessPlayback: true, // Evita parpadeo blanco
        );
      } else if (uri.startsWith('http')) {
        return Image.network(
          uri,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else {
        // Local File
        if (kIsWeb) {
          return Image.network(uri, fit: BoxFit.cover, gaplessPlayback: true);
        } else {
          return Image.file(File(uri), fit: BoxFit.cover, gaplessPlayback: true);
        }
      }
    } catch (e) {
      return Image.network('https://via.placeholder.com/800x400?text=Error+Loading', fit: BoxFit.cover);
    }
  }

  Widget _buildThumbnail(String uri) {
    // Versión simplificada para miniaturas
    try {
      if (uri.startsWith('data:')) {
        return Image.memory(base64Decode(uri.split(',')[1]), fit: BoxFit.cover);
      } else if (uri.startsWith('http')) {
        return Image.network(uri, fit: BoxFit.cover);
      } else {
        if (kIsWeb) {
          return Image.network(uri, fit: BoxFit.cover);
        } else {
          return Image.file(File(uri), fit: BoxFit.cover);
        }
      }
    } catch (e) {
      return const ColoredBox(color: Colors.grey);
    }
  }

  // --- RENDER HOTSPOTS ---

  List<Hotspot> _renderHotspots() {
    return _currentScene.hotspots.map((h) {
      // Buscar el nombre de la escena destino para mostrar en el hotspot
      final targetScene = widget.tour.scenes.firstWhere(
        (s) => s.id == h.targetSceneId,
        orElse: () => SceneModel(id: '', title: 'Siguiente', imageUri: ''),
      );

      return Hotspot(
        latitude: h.pitch,
        longitude: h.yaw,
        width: 120, // Área táctil amplia
        height: 120,
        widget: PulsingHotspotWidget(
          text: targetScene.title,
          onTap: () => _loadScene(h.targetSceneId),
        ),
      );
    }).toList();
  }
}

// ==========================================
// 4. EJEMPLO DE USO (Factory)
// ==========================================

class MatterportExampleFactory {
  static TourModel getExampleTour() {
    return TourModel(
      tourId: 'tour-demo-01',
      scenes: [
        SceneModel(
          id: 'scene-1',
          title: 'Sala de Estar',
          imageUri: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Fisheye_photo-1.jpg/2560px-Fisheye_photo-1.jpg', // Placeholder Panorama
          hotspots: [
            HotspotModel(
              id: 'hs-1',
              targetSceneId: 'scene-2',
              pitch: 10.0,
              yaw: 45.0,
            ),
          ],
        ),
        SceneModel(
          id: 'scene-2',
          title: 'Cocina Moderna',
          imageUri: 'https://live.staticflickr.com/65535/51268310930_4b2c1d3738_o.jpg', // Placeholder Panorama
          hotspots: [
            HotspotModel(
              id: 'hs-2',
              targetSceneId: 'scene-3',
              pitch: -5.0,
              yaw: 90.0,
            ),
            HotspotModel(
              id: 'hs-back-1',
              targetSceneId: 'scene-1',
              pitch: 0.0,
              yaw: 180.0,
            ),
          ],
        ),
        SceneModel(
          id: 'scene-3',
          title: 'Terraza',
          imageUri: 'https://live.staticflickr.com/3283/2766336586_3c2f017409_o.jpg', // Placeholder Panorama
          hotspots: [
            HotspotModel(
              id: 'hs-back-2',
              targetSceneId: 'scene-2',
              pitch: 10.0,
              yaw: -45.0,
            ),
          ],
        ),
      ],
    );
  }
}
