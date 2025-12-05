import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Pantalla Constructor de Tour 360° - Opción 2
/// WebView con el webapp completo integrado
class TourBuilderOp2Screen extends StatefulWidget {
  final InventoryProperty property;

  const TourBuilderOp2Screen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<TourBuilderOp2Screen> createState() => _TourBuilderOp2ScreenState();
}

class _TourBuilderOp2ScreenState extends State<TourBuilderOp2Screen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Inicializar WebView con el HTML embebido
  Future<void> _initializeWebView() async {
    try {
      // Cargar el HTML desde assets
      debugPrint('🔄 Cargando tour_360_builder_op2.html desde assets...');
      final htmlContent = await rootBundle.loadString('assets/tour_360_builder_op2.html');
      debugPrint('✅ HTML cargado correctamente (${htmlContent.length} caracteres)');

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF1A1A1A))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('🔄 Página iniciando: $url');
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              debugPrint('✅ Página cargada: $url');
              setState(() {
                _isLoading = false;
              });
              
              // Enviar información de la propiedad al webapp
              _sendPropertyInfoToWebApp();
              
              // Verificar que el WebApp se inicializó correctamente
              _webViewController.runJavaScript('''
                console.log('✅ WebView OP2 initialized successfully');
                console.log('FlutterChannel available:', typeof FlutterChannel !== 'undefined');
              ''');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ Error cargando recurso web:');
              debugPrint('   - Type: ${error.errorType}');
              debugPrint('   - Code: ${error.errorCode}');
              debugPrint('   - Description: ${error.description}');
              debugPrint('   - URL: ${error.url}');
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('📨 Mensaje recibido del WebApp OP2: ${message.message}');
            _handleWebAppMessage(message.message);
          },
        )
        ..loadHtmlString(
          htmlContent,
          baseUrl: 'https://cdn.jsdelivr.net',
        );
      
      debugPrint('✅ WebViewController OP2 configurado correctamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando WebView OP2: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar el constructor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Enviar información de la propiedad al webapp
  void _sendPropertyInfoToWebApp() {
    try {
      final propertyInfo = jsonEncode({
        'type': 'propertyInfo',
        'propertyId': widget.property.id,
        'propertyAddress': widget.property.direccion,
        'propertyType': widget.property.tipo.displayName,
      });

      debugPrint('📤 Enviando información de propiedad al WebApp OP2:');
      debugPrint('   - ID: ${widget.property.id}');
      debugPrint('   - Dirección: ${widget.property.direccion}');

      _webViewController.runJavaScript('''
        try {
          const propertyData = $propertyInfo;
          window.postMessage(propertyData, '*');
          console.log('✅ Property info sent to webapp OP2:', propertyData);
          
          if (typeof state !== 'undefined') {
            state.propertyId = propertyData.propertyId;
            state.propertyAddress = propertyData.propertyAddress;
            state.tourId = 'tour_' + propertyData.propertyId + '_' + Date.now();
            console.log('✅ State OP2 updated:', state);
          }
        } catch (error) {
          console.error('❌ Error in property info handler OP2:', error);
        }
      ''');
      
      debugPrint('✅ Información de propiedad OP2 enviada correctamente');
    } catch (e) {
      debugPrint('❌ Error al enviar información de propiedad OP2: $e');
    }
  }

  /// Manejar mensajes del webapp
  void _handleWebAppMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'tourSaved') {
        // Tour guardado desde el webapp
        _handleTourSaved(data);
      } else if (type == 'close') {
        // Cerrar el webapp
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error procesando mensaje del webapp: $e');
    }
  }

  /// Guardar el tour en Firebase
  Future<void> _handleTourSaved(Map<String, dynamic> tourData) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
            ),
          ),
        );
      }

      // Extraer URLs de las imágenes (ya están en base64)
      final scenes = tourData['scenes'] as List;
      final photo360Urls = scenes
          .map((scene) => scene['image'] as String)
          .toList();

      // Generar descripción del tour
      final sceneCount = scenes.length;
      final hotspotCount = tourData['hotspotCount'] ?? 0;
      final description = 'Tour virtual con $sceneCount escenas y $hotspotCount puntos de navegación';

      // Crear el tour en Firebase
      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: photo360Urls,
        description: description,
        tourOption: 2, // Opción 2
      );

      // Cerrar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tour virtual creado exitosamente ($sceneCount escenas)'),
            backgroundColor: AppTheme.dorado,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Volver y abrir el tour
      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        
        // Abrir el visor del tour
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VirtualTourOp1ViewerScreen(tour: tour),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al guardar tour: $e');
      
      // Cerrar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear tour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grisOscuro,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Constructor Tour 360° - OP 2',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.negro,
              ),
            ),
            Text(
              widget.property.direccion,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grisOscuro,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.dorado,
        iconTheme: const IconThemeData(color: AppTheme.grisOscuro),
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _webViewController),

          // Loading indicator
          if (_isLoading)
            Container(
              color: AppTheme.grisOscuro,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '⏳ Cargando Constructor de Tour 360°...',
                      style: TextStyle(
                        color: AppTheme.blanco,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
