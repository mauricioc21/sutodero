import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Pantalla para construir tours virtuales 360° - Opción 1
/// Permite subir fotos, organizarlas y crear el tour
class TourBuilderScreen extends StatefulWidget {
  final InventoryProperty property;

  const TourBuilderScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<TourBuilderScreen> createState() => _TourBuilderScreenState();
}

class _TourBuilderScreenState extends State<TourBuilderScreen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _photo360Urls = [];
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Seleccionar foto 360° desde galería
  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Subir a Firebase Storage
      final String photoUrl = await _uploadPhotoToStorage(image);

      setState(() {
        _photo360Urls.add(photoUrl);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto 360° agregada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Subir foto a Firebase Storage
  Future<String> _uploadPhotoToStorage(XFile image) async {
    if (kIsWeb) {
      // Web: Convertir a Data URL
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64';
      
      // Subir usando el método existente
      final photoUrl = await _storageService.uploadInventoryActPhoto(
        actId: widget.property.id,
        filePath: dataUrl,
      );
      
      if (photoUrl == null) {
        throw Exception('Error al subir foto a Firebase Storage');
      }
      
      return photoUrl;
    } else {
      // Móvil: Usar path directamente
      final photoUrl = await _storageService.uploadInventoryActPhoto(
        actId: widget.property.id,
        filePath: image.path,
      );
      
      if (photoUrl == null) {
        throw Exception('Error al subir foto a Firebase Storage');
      }
      
      return photoUrl;
    }
  }

  /// Eliminar foto de la lista
  void _removePhoto(int index) {
    setState(() {
      _photo360Urls.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Foto eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Mover foto hacia arriba
  void _movePhotoUp(int index) {
    if (index > 0) {
      setState(() {
        final photo = _photo360Urls.removeAt(index);
        _photo360Urls.insert(index - 1, photo);
      });
    }
  }

  /// Mover foto hacia abajo
  void _movePhotoDown(int index) {
    if (index < _photo360Urls.length - 1) {
      setState(() {
        final photo = _photo360Urls.removeAt(index);
        _photo360Urls.insert(index + 1, photo);
      });
    }
  }

  /// Guardar tour virtual
  Future<void> _saveTour() async {
    if (_photo360Urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega al menos una foto 360° para crear el tour'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String description = _descriptionController.text.trim().isNotEmpty
          ? '[OP1] ${_descriptionController.text.trim()}'
          : '[OP1] Tour Virtual de ${widget.property.direccion}';

      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: _photo360Urls,
        description: description,
        tourOption: 1, // Opción 1 (Pannellum)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour virtual creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Abrir el tour recién creado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VirtualTourOp1ViewerScreen(tour: tour),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear tour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Vista previa del tour
  Future<void> _previewTour() async {
    if (_photo360Urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega fotos para previsualizar el tour'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Crear tour temporal para previsualizar
    final tempTour = VirtualTourModel(
      id: 'preview',
      propertyId: widget.property.id,
      propertyName: widget.property.tipo.displayName,
      propertyAddress: widget.property.direccion,
      photo360Urls: _photo360Urls,
      description: 'Vista Previa',
      createdAt: DateTime.now(),
      tourOption: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualTourOp1ViewerScreen(tour: tempTour),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Constructor de Tour 360° - Opción 1',
          style: TextStyle(
            color: AppTheme.dorado,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.dorado),
        actions: [
          if (_photo360Urls.isNotEmpty && !_isUploading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.visibility, color: AppTheme.dorado),
              onPressed: _previewTour,
              tooltip: 'Vista Previa',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header con información de la propiedad
            _buildPropertyHeader(),

            // Lista de fotos
            Expanded(
              child: _photo360Urls.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotosList(),
            ),

            // Footer con controles
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Header con información de la propiedad
  Widget _buildPropertyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border(
          bottom: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apartment,
                color: AppTheme.dorado,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.property.direccion,
                  style: const TextStyle(
                    color: AppTheme.blanco,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: AppTheme.blanco),
            decoration: InputDecoration(
              labelText: 'Descripción del Tour',
              labelStyle: const TextStyle(color: AppTheme.dorado),
              hintText: 'Ej: Tour completo de la propiedad',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: AppTheme.negro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.dorado, width: 2),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Estado vacío cuando no hay fotos
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.panorama_photosphere_outlined,
              size: 100,
              color: AppTheme.dorado.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay fotos 360° agregadas',
              style: TextStyle(
                color: AppTheme.blanco,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Presiona el botón "AGREGAR FOTO 360°" para comenzar a construir tu tour virtual',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de fotos con controles de orden
  Widget _buildPhotosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _photo360Urls.length,
      itemBuilder: (context, index) {
        return Card(
          color: AppTheme.grisOscuro,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Número de escena
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.dorado,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.negro,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _photo360Urls[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Text(
                    'Escena ${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.blanco,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Controles
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        color: index > 0 ? AppTheme.dorado : Colors.grey,
                      ),
                      onPressed: index > 0 ? () => _movePhotoUp(index) : null,
                      tooltip: 'Mover arriba',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_downward,
                        color: index < _photo360Urls.length - 1
                            ? AppTheme.dorado
                            : Colors.grey,
                      ),
                      onPressed: index < _photo360Urls.length - 1
                          ? () => _movePhotoDown(index)
                          : null,
                      tooltip: 'Mover abajo',
                      iconSize: 20,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePhoto(index),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Footer con botones de acción
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border(
          top: BorderSide(color: AppTheme.dorado.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contador de fotos
          if (_photo360Urls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '📸 ${_photo360Urls.length} foto(s) 360° agregada(s)',
                style: TextStyle(
                  color: AppTheme.dorado,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Botones
          Row(
            children: [
              // Agregar foto
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || _isSaving ? null : _pickPhoto,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.negro,
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate),
                  label: Text(_isUploading ? 'CARGANDO...' : 'AGREGAR FOTO 360°'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.negro,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Guardar tour
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _photo360Urls.isEmpty || _isUploading || _isSaving
                      ? null
                      : _saveTour,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
