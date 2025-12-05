import 'dart:convert';
import 'dart:io' if (dart.library.js) '../../stubs/io_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../services/virtual_tour_service.dart';
import '../../config/app_theme.dart';
import 'virtual_tour_op1_viewer_screen.dart';

/// Constructor de Tour 360° - Opción 1
/// Versión simplificada y funcional con subida directa a Firebase Storage
class TourBuilderOp1Screen extends StatefulWidget {
  final InventoryProperty property;

  const TourBuilderOp1Screen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<TourBuilderOp1Screen> createState() => _TourBuilderOp1ScreenState();
}

class _TourBuilderOp1ScreenState extends State<TourBuilderOp1Screen> {
  final VirtualTourService _virtualTourService = VirtualTourService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _photo360Urls = [];
  bool _isUploading = false;
  bool _isSaving = false;
  String? _uploadError;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Seleccionar y subir foto 360°
  Future<void> _pickAndUploadPhoto() async {
    try {
      setState(() {
        _uploadError = null;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Subir directamente a Firebase Storage
      final String photoUrl = await _uploadToFirebaseStorage(image);

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
        _uploadError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al subir foto: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Subir archivo directamente a Firebase Storage
  Future<String> _uploadToFirebaseStorage(XFile image) async {
    try {
      final String propertyId = widget.property.id;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'tour_360_$timestamp.jpg';
      final String path = 'properties/$propertyId/tours/$fileName';

      final storageRef = FirebaseStorage.instance.ref().child(path);

      // Leer bytes del archivo
      final bytes = await image.readAsBytes();
      
      // Subir bytes (funciona tanto en web como móvil)
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error en _uploadToFirebaseStorage: $e');
      throw Exception('Error al subir foto: $e');
    }
  }

  /// Eliminar foto
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

  /// Guardar tour
  Future<void> _saveTour() async {
    if (_photo360Urls.isEmpty) {
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
      final String description = _descriptionController.text.trim().isNotEmpty
          ? '[OP1] ${_descriptionController.text.trim()}'
          : '[OP1] Tour Virtual de ${widget.property.direccion}';

      final tour = await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.tipo.displayName,
        propertyAddress: widget.property.direccion,
        photo360Urls: _photo360Urls,
        description: description,
        tourOption: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour virtual creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.dorado),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenido principal
            Expanded(
              child: _photo360Urls.isEmpty
                  ? _buildEmptyState()
                  : _buildPhotosList(),
            ),

            // Error de subida
            if (_uploadError != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: $_uploadError',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Header con información
  Widget _buildHeader() {
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
              Icon(Icons.apartment, color: AppTheme.dorado, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.property.direccion,
                  style: const TextStyle(
                    color: AppTheme.blanco,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: AppTheme.blanco, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Descripción del Tour',
              labelStyle: const TextStyle(color: AppTheme.dorado, fontSize: 12),
              hintText: 'Ej: Tour completo de la propiedad',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Estado vacío
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
              'Sube una imagen 360° para comenzar',
              style: TextStyle(
                color: AppTheme.blanco,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Presiona el botón "AGREGAR FOTO 360°" para subir fotos panorámicas y construir tu tour virtual',
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

  /// Lista de fotos
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
                // Número
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
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 60,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escena ${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Foto 360° panorámica',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Eliminar
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

  /// Footer con controles
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
          // Contador
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
                  onPressed: _isUploading || _isSaving ? null : _pickAndUploadPhoto,
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
                  label: Text(_isUploading ? 'SUBIENDO...' : 'AGREGAR FOTO 360°'),
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

              // Guardar
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
