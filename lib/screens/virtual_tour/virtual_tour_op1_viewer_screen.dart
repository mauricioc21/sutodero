import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/virtual_tour_model.dart';
import '../../config/app_theme.dart';

/// Pantalla para visualizar tours virtuales 360° - Opción 1 (Pannellum)
/// Utiliza Pannellum para una experiencia inmersiva con colores corporativos
class VirtualTourOp1ViewerScreen extends StatefulWidget {
  final VirtualTourModel tour;

  const VirtualTourOp1ViewerScreen({
    Key? key,
    required this.tour,
  }) : super(key: key);

  @override
  State<VirtualTourOp1ViewerScreen> createState() => _VirtualTourOp1ViewerScreenState();
}

class _VirtualTourOp1ViewerScreenState extends State<VirtualTourOp1ViewerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Inicializar WebView y cargar HTML
  Future<void> _initializeWebView() async {
    try {
      // Cargar HTML desde assets
      final String htmlContent = await rootBundle.loadString('assets/tour_360_viewer_op1.html');
      
      // Crear controlador WebView
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            },
            onPageFinished: (String url) {
              // Enviar datos del tour al HTML
              _sendTourDataToWebView();
              
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _error = 'Error al cargar el visor: ${error.description}';
                _isLoading = false;
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            // Manejar mensajes desde JavaScript (ej: cerrar)
            if (message.message == 'close') {
              Navigator.pop(context);
            }
          },
        )
        ..loadHtmlString(htmlContent);

    } catch (e) {
      setState(() {
        _error = 'Error al inicializar el visor: $e';
        _isLoading = false;
      });
    }
  }

  /// Enviar datos del tour al WebView
  Future<void> _sendTourDataToWebView() async {
    try {
      // Preparar datos del tour en formato JSON
      final tourData = {
        'title': widget.tour.description.isNotEmpty
            ? widget.tour.description
            : 'Tour Virtual de ${widget.tour.propertyName}',
        'scenes': widget.tour.photo360Urls
            .asMap()
            .entries
            .map((entry) => {
                  'id': 'scene_${entry.key}',
                  'title': 'Escena ${entry.key + 1}',
                  'image': entry.value,
                  'hotspots': [], // Hotspots vacíos por ahora
                })
            .toList(),
      };

      final tourDataJson = jsonEncode(tourData);
      
      // Enviar datos al JavaScript
      await _webViewController.runJavaScript('''
        window.postMessage({
          type: 'loadTour',
          data: $tourDataJson
        }, '*');
      ''');

    } catch (e) {
      debugPrint('❌ Error al enviar datos al WebView: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      body: SafeArea(
        child: Stack(
          children: [
            // WebView
            if (!_isLoading && _error == null)
              WebViewWidget(controller: _webViewController),

            // Loading indicator
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
                    Text(
                      'Cargando Tour Virtual...',
                      style: TextStyle(
                        color: AppTheme.dorado,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Error state
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: AppTheme.dorado,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dorado,
                          foregroundColor: AppTheme.negro,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
