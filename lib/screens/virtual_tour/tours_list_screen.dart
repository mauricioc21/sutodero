import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'tour_editor_pro_screen.dart';
import 'virtual_tour_viewer_screen.dart';

/// Pantalla para listar y gestionar tours virtuales creados
class ToursListScreen extends StatefulWidget {
  const ToursListScreen({super.key});

  @override
  State<ToursListScreen> createState() => _ToursListScreenState();
}

class _ToursListScreenState extends State<ToursListScreen> {
  final VirtualTourService _tourService = VirtualTourService();
  List<VirtualTourModel> _tours = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      final tours = await _tourService.getUserTours(user.uid);
      
      setState(() {
        _tours = tours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar tours: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTour(VirtualTourModel tour) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Tour'),
        content: Text('¿Estás seguro de eliminar el tour "${tour.propertyName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _tourService.deleteTour(tour.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour eliminado exitosamente')),
        );
        _loadTours(); // Recargar lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  void _editTour(VirtualTourModel tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourEditorProScreen(tour: tour),
      ),
    ).then((_) => _loadTours()); // Recargar al volver
  }

  void _viewTour(VirtualTourModel tour) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VirtualTourViewerScreen(tour: tour),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text('Mis Tours Virtuales'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _loadTours,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.dorado),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.dorado),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTours,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.negro,
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_tours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.panorama_photosphere_outlined,
              size: 64,
              color: AppTheme.dorado.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tours creados',
              style: TextStyle(
                color: AppTheme.dorado.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer tour desde\nla pantalla de captura 360°',
              style: TextStyle(
                color: AppTheme.grisClaro.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTours,
      color: AppTheme.dorado,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tours.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final tour = _tours[index];
          return _buildTourCard(tour);
        },
      ),
    );
  }

  Widget _buildTourCard(VirtualTourModel tour) {
    final firstScene = tour.firstScene;
    final thumbnailUrl = firstScene?.photoUrl ?? 
                        (tour.scenes.isNotEmpty ? tour.scenes.first.photoUrl : null);

    return Card(
      color: AppTheme.grisOscuro,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _viewTour(tour),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  thumbnailUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      color: AppTheme.negro,
                      child: const Icon(
                        Icons.panorama_photosphere,
                        size: 64,
                        color: AppTheme.dorado,
                      ),
                    );
                  },
                ),
              ),

            // Información del tour
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tour.propertyName,
                          style: const TextStyle(
                            color: AppTheme.dorado,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildSceneCountBadge(tour),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dirección
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.grisClaro,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tour.propertyAddress,
                          style: const TextStyle(
                            color: AppTheme.grisClaro,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Fecha de creación
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.grisClaro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(tour.createdAt),
                        style: const TextStyle(
                          color: AppTheme.grisClaro,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Descripción (si existe)
                  if (tour.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      tour.description,
                      style: TextStyle(
                        color: AppTheme.grisClaro.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewTour(tour),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: Text('Ver'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dorado,
                            side: const BorderSide(color: AppTheme.dorado),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editTour(tour),
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dorado,
                            foregroundColor: AppTheme.negro,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteTour(tour),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade300,
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneCountBadge(VirtualTourModel tour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.dorado.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dorado),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.panorama_photosphere,
            size: 16,
            color: AppTheme.dorado,
          ),
          const SizedBox(width: 4),
          Text(
            '${tour.sceneCount}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.dorado,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
