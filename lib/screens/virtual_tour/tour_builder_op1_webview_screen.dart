import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Pantalla Constructor de Tour 360° - Opción 1 (WebView Completo)
/// WebView con el webapp completo con todas las funcionalidades
class TourBuilderOp1WebViewScreen extends StatefulWidget {
  final InventoryProperty property;

  const TourBuilderOp1WebViewScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<TourBuilderOp1WebViewScreen> createState() => _TourBuilderOp1WebViewScreenState();
}

class _TourBuilderOp1WebViewScreenState extends State<TourBuilderOp1WebViewScreen> {
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
      debugPrint('🔄 Cargando tour_360_builder_op1.html desde assets...');
      final htmlContent = await rootBundle.loadString('assets/tour_360_builder_op1.html');
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
                console.log('✅ WebView initialized successfully');
                console.log('FlutterChannel available:', typeof FlutterChannel !== 'undefined');
              ''');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ Error cargando recurso web:');
              debugPrint('   - Type: ${error.errorType}');
              debugPrint('   - Code: ${error.errorCode}');
              debugPrint('   - Description: ${error.description}');
              debugPrint('   - URL: ${error.url}');
              
              // Mostrar error al usuario solo si es crítico
              if (error.errorType.toString().contains('FILE_NOT_FOUND') ||
                  error.errorType.toString().contains('FAILED')) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Error cargando recurso: ${error.description}'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('📨 Mensaje recibido del WebApp: ${message.message}');
            _handleWebAppMessage(message.message);
          },
        )
        ..loadHtmlString(
          htmlContent,
          baseUrl: 'https://cdn.jsdelivr.net', // Base URL para recursos CDN
        );
      
      debugPrint('✅ WebViewController configurado correctamente');
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando WebView: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar el constructor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _initializeWebView();
              },
            ),
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

      debugPrint('📤 Enviando información de propiedad al WebApp:');
      debugPrint('   - ID: ${widget.property.id}');
      debugPrint('   - Dirección: ${widget.property.direccion}');
      debugPrint('   - Tipo: ${widget.property.tipo.displayName}');

      _webViewController.runJavaScript('''
        try {
          const propertyData = $propertyInfo;
          window.postMessage(propertyData, '*');
          console.log('✅ Property info sent to webapp:', propertyData);
          
          // Verificar que el estado se inicializó correctamente
          if (typeof state !== 'undefined') {
            state.propertyId = propertyData.propertyId;
            state.propertyAddress = propertyData.propertyAddress;
            state.tourId = 'tour_' + propertyData.propertyId + '_' + Date.now();
            console.log('✅ State updated:', state);
          } else {
            console.error('❌ State object not found');
          }
        } catch (error) {
          console.error('❌ Error in property info handler:', error);
        }
      ''');
      
      debugPrint('✅ Información de propiedad enviada correctamente');
    } catch (e) {
      debugPrint('❌ Error al enviar información de propiedad: $e');
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
        tourOption: 1, // Opción 1
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
              'Constructor Tour 360° - OP 1',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grisOscuro,
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
        iconTheme: const IconThemeData(color: AppTheme.negro),
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
