import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/inventory_property.dart';
import '../../config/app_theme.dart';

/// Pantalla de prueba para diagnosticar problemas con WebView
class TourBuilderTestScreen extends StatefulWidget {
  final InventoryProperty property;

  const TourBuilderTestScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<TourBuilderTestScreen> createState() => _TourBuilderTestScreenState();
}

class _TourBuilderTestScreenState extends State<TourBuilderTestScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String _lastMessage = 'Esperando mensajes...';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Inicializar WebView de prueba
  Future<void> _initializeWebView() async {
    try {
      debugPrint('🧪 === TEST WEBVIEW - INICIO ===');
      
      // Cargar el HTML de prueba desde assets
      debugPrint('🔄 Cargando tour_360_builder_test.html desde assets...');
      final htmlContent = await rootBundle.loadString('assets/tour_360_builder_test.html');
      debugPrint('✅ HTML cargado correctamente (${htmlContent.length} caracteres)');
      debugPrint('📄 Primeras 200 caracteres: ${htmlContent.substring(0, 200)}...');

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
            debugPrint('📨 Mensaje recibido del WebApp: ${message.message}');
            setState(() {
              _lastMessage = message.message;
            });
            
            // Mostrar mensaje en SnackBar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📨 WebApp: ${message.message}'),
                  backgroundColor: AppTheme.dorado,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        )
        ..loadHtmlString(htmlContent);
      
      debugPrint('✅ WebViewController TEST configurado correctamente');
      debugPrint('🧪 === TEST WEBVIEW - FIN ===');
    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando WebView TEST: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar el test: $e'),
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

      debugPrint('📤 Enviando información de propiedad al WebApp TEST:');
      debugPrint('   - ID: ${widget.property.id}');
      debugPrint('   - Dirección: ${widget.property.direccion}');
      debugPrint('   - Tipo: ${widget.property.tipo.displayName}');

      _webViewController.runJavaScript('''
        try {
          const propertyData = $propertyInfo;
          window.postMessage(propertyData, '*');
          console.log('✅ Property info sent to webapp TEST:', propertyData);
        } catch (error) {
          console.error('❌ Error in property info handler TEST:', error);
        }
      ''');
      
      debugPrint('✅ Información de propiedad TEST enviada correctamente');
    } catch (e) {
      debugPrint('❌ Error al enviar información de propiedad TEST: $e');
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
              '🧪 TEST Constructor Tour 360°',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grisOscuro,
              ),
            ),
            Text(
              'Diagnóstico de WebView',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grisOscuro,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.dorado,
        iconTheme: const IconThemeData(color: AppTheme.negro),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeWebView();
            },
            tooltip: 'Recargar',
          ),
        ],
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
                      '⏳ Cargando Test de WebView...',
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.negro,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📨 Último mensaje recibido:',
              style: TextStyle(
                color: AppTheme.dorado,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dorado, width: 1),
              ),
              child: Text(
                _lastMessage,
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
