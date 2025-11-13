import 'package:flutter/material.dart';
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
                  color: Color(0xFFFFD700),
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
            animSpeed: 1.0,
            sensorControl: SensorControl.orientation,
            child: Image.network(
              widget.tour.photo360Urls[_currentPhotoIndex],
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _isLoading) {
                      setState(() => _isLoading = false);
                    }
                  });
                  return child;
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error al cargar la imagen 360°',
                        style: TextStyle(color: AppTheme.blanco),
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
                          color: Color(0xFFFFD700),
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
                        ? () => setState(() {
                              _currentPhotoIndex--;
                              _isLoading = true;
                            })
                        : null,
                  ),
                  const SizedBox(width: 24),
                  // Botón siguiente
                  _buildNavButton(
                    icon: Icons.arrow_forward,
                    onPressed: _currentPhotoIndex < widget.tour.photo360Urls.length - 1
                        ? () => setState(() {
                              _currentPhotoIndex++;
                              _isLoading = true;
                            })
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
                    Icon(Icons.touch_app, color: Color(0xFFFFD700), size: 20),
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
