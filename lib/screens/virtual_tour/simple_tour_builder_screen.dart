import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/inventory_property.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';
import '../../models/virtual_tour_model.dart';

/// Constructor Simple de Tour 360° - Sin WebView
/// Permite seleccionar fotos 360° y crear tours de manera nativa
class SimpleTourBuilderScreen extends StatefulWidget {
  final InventoryProperty property;
  final int tourOption; // 1 o 2

  const SimpleTourBuilderScreen({
    Key? key,
    required this.property,
    required this.tourOption,
  }) : super(key: key);

  @override
  State<SimpleTourBuilderScreen> createState() => _SimpleTourBuilderScreenState();
}

class _SimpleTourBuilderScreenState extends State<SimpleTourBuilderScreen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedPhotos = [];
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Seleccionar fotos 360° de la galería
  Future<void> _selectPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          // Por ahora agregamos las rutas locales
          // En producción, deberías subir a Firebase Storage
          _selectedPhotos.addAll(images.map((img) => img.path));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${images.length} foto(s) agregada(s)'),
              backgroundColor: AppTheme.dorado,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al seleccionar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Eliminar una foto seleccionada
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  /// Crear y guardar el tour
  Future<void> _saveTour() async {
    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega al menos una foto 360°'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

      // Generar descripción
      final description = _descriptionController.text.trim().isEmpty
          ? 'Tour virtual con ${_selectedPhotos.length} escena(s)'
          : _descriptionController.text.trim();

      // Crear el tour en Firebase
      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: _selectedPhotos,
        description: description,
        tourOption: widget.tourOption,
      );

      // Cerrar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tour virtual creado exitosamente'),
            backgroundColor: AppTheme.dorado,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Volver y abrir el tour
      if (mounted) {
        Navigator.pop(context, true);
        
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
            Text(
              'Constructor Tour 360° - OP ${widget.tourOption}',
              style: const TextStyle(
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
        actions: [
          if (_selectedPhotos.isNotEmpty && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTour,
              tooltip: 'Guardar Tour',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción del tour
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción del Tour (opcional)',
                labelStyle: const TextStyle(color: AppTheme.dorado),
                hintText: 'Ej: Tour completo de 3 habitaciones',
                hintStyle: const TextStyle(color: AppTheme.grisClaro),
                filled: true,
                fillColor: AppTheme.negro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dorado),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dorado),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.dorado, width: 2),
                ),
              ),
              style: const TextStyle(color: AppTheme.blanco),
              maxLines: 2,
            ),
            
            const SizedBox(height: 20),

            // Contador de fotos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fotos 360° seleccionadas (${_selectedPhotos.length})',
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _selectPhotos,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar Fotos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.negro,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de fotos seleccionadas
            Expanded(
              child: _selectedPhotos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.panorama,
                            size: 80,
                            color: AppTheme.grisClaro,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay fotos seleccionadas',
                            style: TextStyle(
                              color: AppTheme.grisClaro,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Toca "Agregar Fotos" para comenzar',
                            style: TextStyle(
                              color: AppTheme.grisClaro,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: AppTheme.negro,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.dorado),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.dorado,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.panorama,
                                color: AppTheme.negro,
                              ),
                            ),
                            title: Text(
                              'Escena ${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.blanco,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _selectedPhotos[index].split('/').last,
                              style: const TextStyle(color: AppTheme.grisClaro),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePhoto(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Botón de guardar (inferior)
            if (_selectedPhotos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveTour,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.negro),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar Tour Virtual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dorado,
                      foregroundColor: AppTheme.negro,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
