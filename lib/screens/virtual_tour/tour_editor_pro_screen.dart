import 'package:flutter/material.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';

/// Editor profesional de tours para agregar hotspots entre escenas
class TourEditorProScreen extends StatefulWidget {
  final VirtualTourModel tour;

  const TourEditorProScreen({
    super.key,
    required this.tour,
  });

  @override
  State<TourEditorProScreen> createState() => _TourEditorProScreenState();
}

class _TourEditorProScreenState extends State<TourEditorProScreen> {
  final VirtualTourService _tourService = VirtualTourService();
  late VirtualTourModel _tour;
  int _currentSceneIndex = 0;
  bool _isSaving = false;
  bool _isAddingHotspot = false;

  @override
  void initState() {
    super.initState();
    _tour = widget.tour;
  }

  TourScene get _currentScene => _tour.scenes[_currentSceneIndex];

  Future<void> _saveTour() async {
    setState(() => _isSaving = true);

    try {
      await _tourService.updateTour(_tour);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addHotspot() {
    showDialog(
      context: context,
      builder: (context) => _AddHotspotDialog(
        tour: _tour,
        currentScene: _currentScene,
        onHotspotAdded: (hotspot) {
          setState(() {
            final updatedHotspots = [..._currentScene.hotspots, hotspot];
            final updatedScene = _currentScene.copyWith(hotspots: updatedHotspots);
            
            // Actualizar tour con la escena modificada
            final updatedScenes = _tour.scenes.map((s) {
              return s.id == _currentScene.id ? updatedScene : s;
            }).toList();
            
            _tour = _tour.copyWith(scenes: updatedScenes);
          });

          // Guardar automáticamente
          _saveTour();
        },
      ),
    );
  }

  void _deleteHotspot(TourHotspot hotspot) {
    setState(() {
      final updatedHotspots = _currentScene.hotspots
          .where((h) => h.id != hotspot.id)
          .toList();
      final updatedScene = _currentScene.copyWith(hotspots: updatedHotspots);
      
      // Actualizar tour
      final updatedScenes = _tour.scenes.map((s) {
        return s.id == _currentScene.id ? updatedScene : s;
      }).toList();
      
      _tour = _tour.copyWith(scenes: updatedScenes);
    });

    // Guardar automáticamente
    _saveTour();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text('Editor de Tour'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.dorado,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar',
              onPressed: _saveTour,
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de escena actual
          _buildSceneIndicator(),
          
          // Vista previa de la imagen 360
          Expanded(
            child: _buildScenePreview(),
          ),
          
          // Lista de hotspots
          _buildHotspotsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHotspot,
        backgroundColor: AppTheme.dorado,
        foregroundColor: AppTheme.negro,
        icon: const Icon(Icons.add_location),
        label: Text('Agregar Hotspot'),
      ),
    );
  }

  Widget _buildSceneIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.grisOscuro,
      child: Row(
        children: [
          IconButton(
            onPressed: _currentSceneIndex > 0
                ? () => setState(() => _currentSceneIndex--)
                : null,
            icon: const Icon(Icons.arrow_back_ios),
            color: AppTheme.dorado,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _currentScene.title,
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escena ${_currentSceneIndex + 1} de ${_tour.scenes.length}',
                  style: TextStyle(
                    color: AppTheme.grisClaro,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _currentSceneIndex < _tour.scenes.length - 1
                ? () => setState(() => _currentSceneIndex++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
            color: AppTheme.dorado,
          ),
        ],
      ),
    );
  }

  Widget _buildScenePreview() {
    return Stack(
      children: [
        // Imagen 360
        Image.network(
          _currentScene.photoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.negro,
              child: const Center(
                child: Icon(
                  Icons.panorama_photosphere,
                  size: 100,
                  color: AppTheme.dorado,
                ),
              ),
            );
          },
        ),
        
        // Overlay con info
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentScene.hotspots.length} punto(s) de navegación',
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentScene.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentScene.description!,
                    style: const TextStyle(
                      color: AppTheme.grisClaro,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHotspotsList() {
    if (_currentScene.hotspots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: AppTheme.grisOscuro,
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: AppTheme.grisClaro.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay puntos de navegación',
              style: TextStyle(
                color: AppTheme.grisClaro.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Agrega hotspots para conectar con otras escenas',
              style: TextStyle(
                color: AppTheme.grisClaro.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      color: AppTheme.grisOscuro,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentScene.hotspots.length,
        itemBuilder: (context, index) {
          final hotspot = _currentScene.hotspots[index];
          return _buildHotspotCard(hotspot);
        },
      ),
    );
  }

  Widget _buildHotspotCard(TourHotspot hotspot) {
    // Buscar escena destino
    final targetScene = _tour.getSceneById(hotspot.targetSceneId);
    
    return Card(
      color: AppTheme.negro,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.near_me, color: AppTheme.dorado),
        title: Text(
          targetScene?.title ?? 'Escena desconocida',
          style: const TextStyle(color: AppTheme.dorado),
        ),
        subtitle: Text(
          hotspot.text ?? 'Sin descripción',
          style: const TextStyle(color: AppTheme.grisClaro),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteHotspot(hotspot),
        ),
      ),
    );
  }
}

// Dialog para agregar hotspot
class _AddHotspotDialog extends StatefulWidget {
  final VirtualTourModel tour;
  final TourScene currentScene;
  final Function(TourHotspot) onHotspotAdded;

  const _AddHotspotDialog({
    required this.tour,
    required this.currentScene,
    required this.onHotspotAdded,
  });

  @override
  State<_AddHotspotDialog> createState() => _AddHotspotDialogState();
}

class _AddHotspotDialogState extends State<_AddHotspotDialog> {
  String? _selectedSceneId;
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Obtener escenas disponibles (excluyendo la actual)
    final availableScenes = widget.tour.scenes
        .where((s) => s.id != widget.currentScene.id)
        .toList();

    return AlertDialog(
      backgroundColor: AppTheme.grisOscuro,
      title: Text(
        'Agregar Punto de Navegación',
        style: TextStyle(color: AppTheme.dorado),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escena destino:',
            style: TextStyle(color: AppTheme.grisClaro, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSceneId,
            dropdownColor: AppTheme.negro,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.negro,
            ),
            style: const TextStyle(color: AppTheme.dorado),
            items: availableScenes.map((scene) {
              return DropdownMenuItem(
                value: scene.id,
                child: Text(scene.title),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedSceneId = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            style: const TextStyle(color: AppTheme.dorado),
            decoration: const InputDecoration(
              labelText: 'Texto (opcional)',
              labelStyle: TextStyle(color: AppTheme.grisClaro),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: AppTheme.negro,
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: AppTheme.grisClaro)),
        ),
        ElevatedButton(
          onPressed: _selectedSceneId != null ? _addHotspot : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dorado,
            foregroundColor: AppTheme.negro,
          ),
          child: Text('Agregar'),
        ),
      ],
    );
  }

  void _addHotspot() {
    if (_selectedSceneId == null) return;

    final hotspot = TourHotspot(
      id: 'hotspot_${DateTime.now().millisecondsSinceEpoch}',
      targetSceneId: _selectedSceneId!,
      yaw: 0, // Posición predeterminada
      pitch: 0,
      text: _textController.text.isNotEmpty ? _textController.text : null,
      icon: 'arrow',
    );

    widget.onHotspotAdded(hotspot);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
