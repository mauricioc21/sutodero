import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/camera_360_service.dart';
import '../config/app_theme.dart';

/// Widget de preview en vivo con control remoto de cámara 360°
/// Muestra el stream de video y permite capturar remotamente
class Camera360LivePreview extends StatefulWidget {
  final Camera360Device camera;
  final Function(String photoPath)? onPhotoCapture;

  const Camera360LivePreview({
    super.key,
    required this.camera,
    this.onPhotoCapture,
  });

  @override
  State<Camera360LivePreview> createState() => _Camera360LivePreviewState();
}

class _Camera360LivePreviewState extends State<Camera360LivePreview> {
  final Camera360Service _cameraService = Camera360Service();
  
  String? _previewUrl;
  bool _isLoading = true;
  bool _isCapturing = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  String _lastImageUrl = '';
  int _imageCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Inicializar preview de la cámara
  Future<void> _initializePreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = await _cameraService.getLivePreviewUrl(widget.camera);
      
      if (url != null) {
        setState(() {
          _previewUrl = url;
          _isLoading = false;
        });
        
        // Refrescar el preview cada 2 segundos para simular stream
        _startPreviewRefresh();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo obtener el preview de la cámara';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al conectar con la cámara: $e';
      });
    }
  }

  /// Refrescar preview periódicamente
  void _startPreviewRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _imageCounter++;
          // Agregar timestamp para forzar recarga de imagen
          if (_previewUrl != null) {
            _lastImageUrl = '$_previewUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          }
        });
      }
    });
  }

  /// Capturar foto remotamente
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final result = await _cameraService.captureWith360Camera(widget.camera);
      
      if (result.success) {
        // Si hay comando HTTP, ejecutarlo
        if (result.httpCommand != null) {
          await _executeHttpCommand(result.httpCommand!);
        }

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Esperar un momento para que la cámara procese
        await Future.delayed(const Duration(seconds: 2));

        // Intentar obtener la última foto capturada
        final photoPath = await _getLastCapturedPhoto();
        if (photoPath != null && widget.onPhotoCapture != null) {
          widget.onPhotoCapture!(photoPath);
        }

      } else if (result.requiresManualCapture) {
        // Mostrar diálogo con instrucciones
        if (mounted) {
          _showManualCaptureDialog(result.message);
        }
      } else {
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Ejecutar comando HTTP a la cámara
  Future<void> _executeHttpCommand(Map<String, dynamic> command) async {
    try {
      final url = command['url'] as String;
      final method = command['method'] as String;
      final body = command['body'] as Map<String, dynamic>?;

      if (method == 'POST') {
        await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        await http.get(Uri.parse(url));
      }
      
      debugPrint('✅ Comando HTTP ejecutado: $method $url');
    } catch (e) {
      debugPrint('❌ Error al ejecutar comando HTTP: $e');
    }
  }

  /// Obtener última foto capturada de la cámara
  Future<String?> _getLastCapturedPhoto() async {
    // En una implementación real, esto consultaría a la cámara
    // por su última foto capturada
    // Por ahora, retornamos null para que el usuario seleccione manualmente
    return null;
  }

  /// Mostrar diálogo de captura manual
  void _showManualCaptureDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          '📸 Captura Manual',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: AppTheme.dorado)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.dorado, width: 2),
      ),
      child: Column(
        children: [
          // Header con nombre de cámara
          _buildHeader(),
          
          // Preview de la cámara
          _buildPreview(),
          
          // Controles de captura
          _buildControls(),
        ],
      ),
    );
  }

  /// Header con información de la cámara
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.negro,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLG - 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _errorMessage != null ? AppTheme.error : AppTheme.success,
              boxShadow: [
                BoxShadow(
                  color: _errorMessage != null 
                      ? AppTheme.error.withValues(alpha: 0.5)
                      : AppTheme.success.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.camera.name,
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.camera.type,
                  style: const TextStyle(
                    color: AppTheme.grisClaro,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.videocam,
            color: AppTheme.dorado,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// Preview en vivo de la cámara
  Widget _buildPreview() {
    return Container(
      height: 300,
      color: Colors.black,
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.dorado),
                  SizedBox(height: 16),
                  Text(
                    'Conectando con cámara...',
                    style: TextStyle(color: AppTheme.grisClaro),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.paddingMD),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 48,
                        ),
                        SizedBox(height: AppTheme.spacingMD),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.grisClaro,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingLG),
                        ElevatedButton.icon(
                          onPressed: _initializePreview,
                          icon: const Icon(Icons.refresh),
                          label: const Text('REINTENTAR'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Preview de la cámara
                    _lastImageUrl.isNotEmpty
                        ? Image.network(
                            _lastImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderPreview();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholderPreview();
                            },
                          )
                        : _buildPlaceholderPreview(),
                    
                    // Overlay con información
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.dorado),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.error,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.error.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'EN VIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

  /// Placeholder cuando no hay preview
  Widget _buildPlaceholderPreview() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.panorama_360,
              color: AppTheme.dorado,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Vista previa de cámara 360°',
              style: TextStyle(
                color: AppTheme.grisClaro,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Controles de captura
  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.paddingLG),
      child: Column(
        children: [
          // Botón de captura grande
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isCapturing ? null : _capturePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.negro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: _isCapturing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.negro,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CAPTURANDO...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'CAPTURAR FOTO 360°',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          SizedBox(height: AppTheme.spacingMD),
          
          // Instrucciones
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            decoration: BoxDecoration(
              color: AppTheme.negro.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.dorado,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Presiona el botón para capturar remotamente',
                    style: TextStyle(
                      color: AppTheme.grisClaro,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
