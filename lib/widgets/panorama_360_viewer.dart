import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../config/app_theme.dart';

/// Widget para visualizar fotos panorámicas 360°
class Panorama360Viewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  
  const Panorama360Viewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<Panorama360Viewer> createState() => _Panorama360ViewerState();
}

class _Panorama360ViewerState extends State<Panorama360Viewer> {
  late int _currentIndex;
  late PageController _pageController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: _showControls
          ? AppBar(
              title: Text(
                'Vista 360° (${_currentIndex + 1}/${widget.imageUrls.length})',
                style: const TextStyle(color: AppTheme.dorado),
              ),
              backgroundColor: AppTheme.grisOscuro,
              foregroundColor: AppTheme.dorado,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    _showHelpDialog();
                  },
                  tooltip: 'Ayuda',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Panorama viewer
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return PanoramaViewer(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.dorado,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cargando panorama 360°...',
                              style: TextStyle(
                                color: AppTheme.grisClaro,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error cargando panorama 360°',
                              style: TextStyle(
                                color: AppTheme.grisClaro,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(
                                color: AppTheme.grisClaro,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Navigation controls
            if (_showControls && widget.imageUrls.length > 1) ...[
              // Previous button
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavigationButton(
                      icon: Icons.chevron_left,
                      onPressed: _previousImage,
                    ),
                  ),
                ),

              // Next button
              if (_currentIndex < widget.imageUrls.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavigationButton(
                      icon: Icons.chevron_right,
                      onPressed: _nextImage,
                    ),
                  ),
                ),
            ],

            // Bottom info panel
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.negro.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicators
                      if (widget.imageUrls.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.imageUrls.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentIndex
                                    ? AppTheme.dorado
                                    : AppTheme.grisClaro.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Instructions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: AppTheme.grisClaro,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Arrastra para explorar la vista 360°',
                            style: TextStyle(
                              color: AppTheme.grisClaro,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.dorado, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, size: 32),
        color: AppTheme.dorado,
        onPressed: onPressed,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Cómo usar el visor 360°',
          style: TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.touch_app,
              title: 'Explorar',
              description: 'Arrastra en cualquier dirección para rotar la vista',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.pinch,
              title: 'Zoom',
              description: 'Usa dos dedos para hacer zoom in/out',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.swipe,
              title: 'Cambiar foto',
              description: 'Desliza horizontal para ver otras vistas 360°',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.visibility_off,
              title: 'Ocultar controles',
              description: 'Toca la pantalla para mostrar/ocultar controles',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.dorado, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.grisClaro,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
