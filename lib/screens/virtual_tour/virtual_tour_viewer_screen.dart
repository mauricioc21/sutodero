import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../models/virtual_tour_model.dart';
import '../../config/app_theme.dart';

/// Pantalla para visualizar tour virtual 360°
/// Permite navegar entre múltiples fotos panorámicas
class VirtualTourViewerScreen extends StatefulWidget {
  final VirtualTourModel tour;

  const VirtualTourViewerScreen({
    super.key,
    required this.tour,
  });

  @override
  State<VirtualTourViewerScreen> createState() => _VirtualTourViewerScreenState();
}

class _VirtualTourViewerScreenState extends State<VirtualTourViewerScreen> {
  int _currentPhotoIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Pre-cache de la primera imagen para mejor rendimiento
    if (widget.tour.photo360Urls.isNotEmpty) {
      precacheImage(
        NetworkImage(widget.tour.photo360Urls[_currentPhotoIndex]),
        context,
      ).catchError((e) {
        debugPrint('⚠️ Error pre-caching imagen: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tour.photo360Urls.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tour Virtual'),
          backgroundColor: AppTheme.grisOscuro,
          foregroundColor: AppTheme.dorado,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.panorama, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay fotos 360° en este tour',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final currentPhotoUrl = widget.tour.photo360Urls[_currentPhotoIndex];

    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text(widget.tour.propertyName),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          // Contador de fotos
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentPhotoIndex + 1}/${widget.tour.photo360Urls.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFAB334),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Visor panorámico 360°
          PanoramaViewer(
            key: ValueKey(currentPhotoUrl), // Forzar rebuild al cambiar foto
            animSpeed: 1.0,
            sensorControl: SensorControl.orientation,
            child: Image.network(
              currentPhotoUrl,
              fit: BoxFit.cover,
              cacheWidth: 2048, // Optimizar tamaño de cache
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // Imagen cargada exitosamente
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _isLoading) {
                      setState(() => _isLoading = false);
                    }
                  });
                  return child;
                }
                
                // Mostrar progreso de carga
                final progress = loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFFFAB334),
                        value: progress,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        progress != null
                            ? 'Cargando... ${(progress * 100).toInt()}%'
                            : 'Cargando imagen 360°...',
                        style: const TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error cargando imagen 360°: $error');
                debugPrint('URL: $currentPhotoUrl');
                
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar la imagen 360°',
                        style: TextStyle(color: AppTheme.blanco, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verifica tu conexión a internet',
                        style: TextStyle(color: AppTheme.grisClaro, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Forzar rebuild para reintentar carga
                          setState(() {
                            _isLoading = true;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dorado,
                          foregroundColor: AppTheme.negro,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Overlay con información
          if (widget.tour.description.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.negro.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFAB334),
                          size: 20,
                        ),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Text(
                            widget.tour.description,
                            style: const TextStyle(
                              color: AppTheme.blanco,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Controles de navegación (solo si hay múltiples fotos)
          if (widget.tour.photo360Urls.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón anterior
                  _buildNavButton(
                    icon: Icons.arrow_back,
                    onPressed: _currentPhotoIndex > 0
                        ? () {
                            setState(() {
                              _currentPhotoIndex--;
                              _isLoading = true;
                            });
                            // Pre-cache de la imagen
                            _precacheCurrentImage();
                          }
                        : null,
                  ),
                  const SizedBox(width: 24),
                  // Botón siguiente
                  _buildNavButton(
                    icon: Icons.arrow_forward,
                    onPressed: _currentPhotoIndex < widget.tour.photo360Urls.length - 1
                        ? () {
                            setState(() {
                              _currentPhotoIndex++;
                              _isLoading = true;
                            });
                            // Pre-cache de la imagen
                            _precacheCurrentImage();
                          }
                        : null,
                  ),
                ],
              ),
            ),

          // Instrucciones de uso
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.negro.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Color(0xFFFAB334), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Arrastra para explorar',
                      style: TextStyle(color: AppTheme.blanco, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pre-cargar imagen actual en cache
  void _precacheCurrentImage() {
    if (_currentPhotoIndex < widget.tour.photo360Urls.length) {
      precacheImage(
        NetworkImage(widget.tour.photo360Urls[_currentPhotoIndex]),
        context,
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error pre-caching imagen: $e');
        }
      });
    }
  }

  /// Construir botón de navegación
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onPressed != null
            ? AppTheme.dorado
            : Colors.grey.withValues(alpha: 0.5),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.dorado.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: AppTheme.grisOscuro,
        iconSize: 32,
        onPressed: onPressed,
      ),
    );
  }
}
