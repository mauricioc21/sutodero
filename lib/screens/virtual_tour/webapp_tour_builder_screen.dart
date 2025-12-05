import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Pantalla WebApp de Tour 360° - Opción 2
/// Integra el webapp completo de construcción de tours 360°
class WebAppTourBuilderScreen extends StatefulWidget {
  final InventoryProperty property;

  const WebAppTourBuilderScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<WebAppTourBuilderScreen> createState() => _WebAppTourBuilderScreenState();
}

class _WebAppTourBuilderScreenState extends State<WebAppTourBuilderScreen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Inicializar WebView con el webapp de tour 360°
  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Enviar información de la propiedad al webapp
            _sendPropertyInfoToWebApp();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Error cargando webapp: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebAppMessage(message.message);
        },
      )
      ..loadHtmlString(_getWebAppHTML());
  }

  /// Enviar información de la propiedad al webapp
  void _sendPropertyInfoToWebApp() {
    final propertyInfo = jsonEncode({
      'type': 'propertyInfo',
      'data': {
        'id': widget.property.id,
        'address': widget.property.direccion,
        'type': widget.property.tipo.displayName,
      },
    });

    _webViewController.runJavaScript('''
      if (window.onFlutterMessage) {
        window.onFlutterMessage($propertyInfo);
      }
    ''');
  }

  /// Manejar mensajes del webapp
  void _handleWebAppMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'tourSaved') {
        // Tour guardado desde el webapp
        _handleTourSaved(data['tourData']);
      } else if (type == 'close') {
        // Cerrar el webapp
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error procesando mensaje del webapp: $e');
    }
  }

  /// Manejar tour guardado
  Future<void> _handleTourSaved(Map<String, dynamic> tourData) async {
    try {
      // Extraer datos del tour
      final List<String> photoUrls = List<String>.from(tourData['scenes']?.map((s) => s['image']) ?? []);
      final String description = tourData['title'] ?? 'Tour Virtual';

      if (photoUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No hay fotos en el tour'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Guardar en Firestore
      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: photoUrls,
        description: '[OP2] $description',
        tourOption: 2,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Abrir el tour
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VirtualTourOp1ViewerScreen(tour: tour),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar tour: $e'),
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
          'Constructor de Tour 360° - Opción 2',
          style: TextStyle(
            color: AppTheme.dorado,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.dorado),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.dorado,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cargando Constructor de Tour...',
                    style: TextStyle(
                      color: AppTheme.dorado,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// HTML del WebApp completo de tour 360°
  String _getWebAppHTML() {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Virtual Tour Builder</title>
    
    <!-- Pannellum CSS & JS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css"/>
    <script src="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js"></script>
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1A1A1A;
            color: #FFFFFF;
            overflow-x: hidden;
        }

        /* Colores corporativos SU TODERO */
        :root {
            --dorado: #FAB334;
            --gris-oscuro: #2C2C2C;
            --negro: #1A1A1A;
            --blanco: #FFFFFF;
        }

        /* Header */
        .header {
            background: var(--gris-oscuro);
            padding: 16px;
            border-bottom: 2px solid var(--dorado);
        }

        .property-info {
            display: flex;
            align-items: center;
            gap: 10px;
            color: var(--blanco);
            font-size: 14px;
            margin-bottom: 12px;
        }

        .property-icon {
            color: var(--dorado);
            font-size: 20px;
        }

        #title-input {
            width: 100%;
            padding: 12px;
            background: var(--negro);
            border: 1px solid rgba(250, 179, 52, 0.3);
            border-radius: 8px;
            color: var(--blanco);
            font-size: 14px;
        }

        #title-input:focus {
            outline: none;
            border-color: var(--dorado);
        }

        /* Editor Container */
        .editor-container {
            display: flex;
            flex-direction: column;
            height: calc(100vh - 180px);
        }

        /* Pannellum Viewer */
        #panorama {
            width: 100%;
            height: 350px;
            background: #000;
        }

        .empty-state {
            height: 350px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: var(--negro);
            color: var(--blanco);
        }

        .empty-icon {
            font-size: 80px;
            color: var(--dorado);
            opacity: 0.5;
            margin-bottom: 20px;
        }

        /* Scenes List */
        .scenes-section {
            background: var(--gris-oscuro);
            padding: 12px;
            border-top: 1px solid rgba(250, 179, 52, 0.3);
        }

        .scenes-title {
            color: var(--dorado);
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 8px;
        }

        .scenes-list {
            display: flex;
            gap: 8px;
            overflow-x: auto;
            padding-bottom: 8px;
        }

        .scene-item {
            min-width: 80px;
            height: 80px;
            border: 2px solid transparent;
            border-radius: 8px;
            overflow: hidden;
            cursor: pointer;
            position: relative;
        }

        .scene-item.active {
            border-color: var(--dorado);
        }

        .scene-item img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .scene-number {
            position: absolute;
            top: 4px;
            left: 4px;
            background: var(--dorado);
            color: var(--negro);
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: bold;
        }

        .scene-delete {
            position: absolute;
            top: 4px;
            right: 4px;
            background: red;
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            border: none;
            cursor: pointer;
            font-size: 16px;
            line-height: 1;
        }

        /* Footer Controls */
        .footer {
            background: var(--gris-oscuro);
            padding: 12px;
            border-top: 1px solid rgba(250, 179, 52, 0.3);
        }

        .counter {
            text-align: center;
            color: var(--dorado);
            font-size: 12px;
            font-weight: bold;
            margin-bottom: 12px;
        }

        .buttons {
            display: flex;
            gap: 8px;
        }

        .btn {
            flex: 1;
            padding: 14px;
            border: none;
            border-radius: 8px;
            font-weight: bold;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-upload {
            background: var(--dorado);
            color: var(--negro);
            flex: 2;
        }

        .btn-hotspot {
            background: #3498db;
            color: white;
        }

        .btn-save {
            background: #4CAF50;
            color: white;
        }

        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .btn:active:not(:disabled) {
            transform: scale(0.95);
        }

        /* File Input Hidden */
        #file-input {
            display: none;
        }

        /* Loading */
        .loading {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.8);
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }

        .loading.active {
            display: flex;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid rgba(250, 179, 52, 0.3);
            border-top-color: var(--dorado);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <!-- Loading -->
    <div class="loading" id="loading">
        <div class="spinner"></div>
    </div>

    <!-- Header -->
    <div class="header">
        <div class="property-info">
            <span class="property-icon">🏢</span>
            <span id="property-address">Cargando...</span>
        </div>
        <input type="text" id="title-input" placeholder="Descripción del Tour" />
    </div>

    <!-- Editor Container -->
    <div class="editor-container">
        <!-- Panorama Viewer / Empty State -->
        <div id="editor-section">
            <div class="empty-state">
                <div class="empty-icon">🌐</div>
                <p style="font-size: 16px; font-weight: bold;">Sube una imagen 360° para comenzar</p>
            </div>
        </div>

        <!-- Scenes List -->
        <div class="scenes-section">
            <div class="scenes-title">📸 Escenas</div>
            <div class="scenes-list" id="scenes-list"></div>
        </div>
    </div>

    <!-- Footer Controls -->
    <div class="footer">
        <div class="counter" id="counter">0 escena(s) | 0 hotspot(s)</div>
        <div class="buttons">
            <input type="file" id="file-input" accept="image/*" />
            <button class="btn btn-upload" onclick="uploadImage()">AGREGAR FOTO 360°</button>
            <button class="btn btn-hotspot" id="hotspot-btn" onclick="addHotspot()" disabled>HOTSPOT</button>
            <button class="btn btn-save" id="save-btn" onclick="saveTour()" disabled>GUARDAR</button>
        </div>
    </div>

    <script>
        // Estado global
        const state = {
            scenes: [],
            current: null,
            viewer: null,
            propertyInfo: null
        };

        // Recibir información de Flutter
        window.onFlutterMessage = function(data) {
            if (data.type === 'propertyInfo') {
                state.propertyInfo = data.data;
                document.getElementById('property-address').textContent = data.data.address;
            }
        };

        // Subir imagen
        function uploadImage() {
            document.getElementById('file-input').click();
        }

        document.getElementById('file-input').addEventListener('change', async (e) => {
            const file = e.target.files[0];
            if (!file) return;

            showLoading(true);

            try {
                // Convertir a base64 (simulando subida)
                const reader = new FileReader();
                reader.onload = function(event) {
                    const sceneId = 'scene-' + Date.now();
                    const scene = {
                        id: sceneId,
                        title: 'Escena ' + (state.scenes.length + 1),
                        image: event.target.result,
                        hotspots: []
                    };

                    state.scenes.push(scene);
                    
                    if (!state.current) {
                        state.current = sceneId;
                    }

                    renderScenes();
                    loadScene(state.current);
                    updateCounter();
                    updateButtons();
                    
                    showLoading(false);
                };
                reader.readAsDataURL(file);
            } catch (error) {
                console.error('Error:', error);
                showLoading(false);
            }

            e.target.value = '';
        });

        // Renderizar escenas
        function renderScenes() {
            const list = document.getElementById('scenes-list');
            list.innerHTML = '';

            state.scenes.forEach((scene, index) => {
                const item = document.createElement('div');
                item.className = 'scene-item' + (state.current === scene.id ? ' active' : '');
                item.onclick = () => {
                    state.current = scene.id;
                    renderScenes();
                    loadScene(scene.id);
                };

                const img = document.createElement('img');
                img.src = scene.image;
                item.appendChild(img);

                const number = document.createElement('div');
                number.className = 'scene-number';
                number.textContent = index + 1;
                item.appendChild(number);

                const deleteBtn = document.createElement('button');
                deleteBtn.className = 'scene-delete';
                deleteBtn.textContent = '×';
                deleteBtn.onclick = (e) => {
                    e.stopPropagation();
                    deleteScene(scene.id);
                };
                item.appendChild(deleteBtn);

                list.appendChild(item);
            });
        }

        // Cargar escena
        function loadScene(sceneId) {
            const scene = state.scenes.find(s => s.id === sceneId);
            if (!scene) return;

            const editorSection = document.getElementById('editor-section');
            editorSection.innerHTML = '<div id="panorama"></div>';

            if (state.viewer) {
                try {
                    state.viewer.destroy();
                } catch (e) {}
            }

            const hotspots = scene.hotspots.map(h => ({
                pitch: h.pitch,
                yaw: h.yaw,
                type: 'info',
                text: h.text || 'Hotspot',
                createTooltipFunc: createCustomHotspot
            }));

            state.viewer = pannellum.viewer('panorama', {
                type: 'equirectangular',
                panorama: scene.image,
                autoLoad: true,
                hotSpots: hotspots,
                showControls: false,
                mouseZoom: true,
                draggable: true,
                hfov: 100
            });

            updateCounter();
        }

        // Crear hotspot personalizado
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

        // Agregar hotspot
        function addHotspot() {
            if (!state.viewer || state.scenes.length < 2) return;

            const yaw = state.viewer.getYaw();
            const pitch = state.viewer.getPitch();

            const currentScene = state.scenes.find(s => s.id === state.current);
            if (!currentScene) return;

            const hotspot = {
                yaw: yaw,
                pitch: pitch,
                text: 'Ir a escena'
            };

            currentScene.hotspots.push(hotspot);
            loadScene(state.current);
            updateCounter();
        }

        // Eliminar escena
        function deleteScene(sceneId) {
            if (!confirm('¿Eliminar esta escena?')) return;

            state.scenes = state.scenes.filter(s => s.id !== sceneId);
            
            if (state.current === sceneId) {
                state.current = state.scenes[0]?.id || null;
            }

            renderScenes();
            if (state.current) {
                loadScene(state.current);
            } else {
                document.getElementById('editor-section').innerHTML = \`
                    <div class="empty-state">
                        <div class="empty-icon">🌐</div>
                        <p style="font-size: 16px; font-weight: bold;">Sube una imagen 360° para comenzar</p>
                    </div>
                \`;
            }
            updateCounter();
            updateButtons();
        }

        // Actualizar contador
        function updateCounter() {
            const currentScene = state.scenes.find(s => s.id === state.current);
            const hotspotCount = currentScene ? currentScene.hotspots.length : 0;
            document.getElementById('counter').textContent = 
                state.scenes.length + ' escena(s) | ' + hotspotCount + ' hotspot(s)';
        }

        // Actualizar botones
        function updateButtons() {
            const hasScenes = state.scenes.length > 0;
            const hasTwoScenes = state.scenes.length >= 2;
            
            document.getElementById('hotspot-btn').disabled = !hasTwoScenes;
            document.getElementById('save-btn').disabled = !hasScenes;
        }

        // Guardar tour
        function saveTour() {
            const title = document.getElementById('title-input').value || 'Tour Virtual';
            
            const tourData = {
                type: 'tourSaved',
                tourData: {
                    title: title,
                    scenes: state.scenes,
                    propertyId: state.propertyInfo?.id
                }
            };

            // Enviar a Flutter
            if (window.FlutterChannel) {
                FlutterChannel.postMessage(JSON.stringify(tourData));
            }
        }

        // Loading
        function showLoading(show) {
            document.getElementById('loading').classList.toggle('active', show);
        }

        // Inicializar
        updateButtons();
    </script>
</body>
</html>
    ''';
  }
}
