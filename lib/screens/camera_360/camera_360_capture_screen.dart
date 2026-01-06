import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../services/camera_360_service.dart';
import '../../services/virtual_tour_service.dart';
import '../../models/inventory_property.dart';
import '../../models/virtual_tour_model.dart';
import '../../config/app_theme.dart';
import '../../widgets/camera_360_live_preview.dart';
import '../gallery/gallery_360_screen.dart';
import '../virtual_tour/tour_editor_pro_screen.dart';
import '../virtual_tour/tours_list_screen.dart';

/// Pantalla universal de captura de fotos 360°
/// Implementa persistencia local de fotos y creación de tours virtuales.
class Camera360CaptureScreen extends StatefulWidget {
  final InventoryProperty property;

  Camera360CaptureScreen({
    super.key,
    InventoryProperty? property,
  }) : property = property ?? InventoryProperty(
          id: 'quick_capture_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'unassigned',
          direccion: 'Captura Rápida',
          tipo: PropertyType.otro,
          descripcion: 'Captura realizada sin asignar propiedad previa',
        );

  @override
  State<Camera360CaptureScreen> createState() => _Camera360CaptureScreenState();
}

class _Camera360CaptureScreenState extends State<Camera360CaptureScreen> {
  final Camera360Service _camera360Service = Camera360Service();
  final VirtualTourService _virtualTourService = VirtualTourService();
  
  List<Camera360Device> _detectedCameras = [];
  bool _isScanning = false;
  
  // ✅ REQUERIMIENTO 1: Arreglo de fotos capturadas (Estado con persistencia)
  // Estructura definida en CapturedPhoto: {id, uri, filename, timestamp}
  List<CapturedPhoto> _capturedPhotos = [];
  
  bool _isUploading = false;
  Camera360Device? _connectedCamera;
  bool _isQuickCapture = false;

  @override
  void initState() {
    super.initState();
    _checkIfQuickCapture();
    _loadPersistedPhotos(); // Cargar fotos al iniciar
  }

  void _checkIfQuickCapture() {
    _isQuickCapture = widget.property.userId == 'unassigned' || 
                      widget.property.direccion == 'Captura Rápida' ||
                      widget.property.id.startsWith('quick_capture_');
  }

  // ✅ REQUERIMIENTO 1: Función para cargar fotos persistentes
  void _loadPersistedPhotos() async {
    final savedPhotos = await _camera360Service.getSessionPhotos(_isQuickCapture, widget.property.id);
    if (savedPhotos.isNotEmpty) {
      if (mounted) {
        setState(() {
          _capturedPhotos = savedPhotos;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Captura 360°'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Ver Galería',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Gallery360Screen(
                    propertyId: widget.property.id,
                    isQuickCapture: _isQuickCapture,
                    onPhotosSelectedForTour: (photos) {
                      Navigator.pop(context); // Cerrar galería
                      _generateAndSaveTour(photos);
                    },
                  ),
                ),
              ).then((_) => _loadPersistedPhotos()); // Recargar al volver
            },
          ),
          if (_capturedPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.dorado.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.dorado),
                  ),
                  child: Text(
                    '${_capturedPhotos.length} fotos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dorado,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPropertyInfo(),
              SizedBox(height: AppTheme.spacingXL),
              _buildCaptureMethodsSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildBluetoothCamerasSection(),
              SizedBox(height: AppTheme.spacingXL),
              if (_connectedCamera != null) _buildLivePreviewSection(),
              if (_connectedCamera != null) SizedBox(height: AppTheme.spacingXL),
              
              // ✅ REQUERIMIENTO 1: Sección VISIBLE de fotos capturadas
              if (_capturedPhotos.isNotEmpty) _buildCapturedPhotosSection(),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // ✅ REQUERIMIENTO 2: Botón CREAR TOUR funcional
              if (_capturedPhotos.isNotEmpty) ...[
                _buildCreateTourButton(),
                SizedBox(height: AppTheme.spacingMD),
              ],
              
              // Botón para ver tours creados
              _buildViewToursButton(),
              
              SizedBox(height: 80), // Espacio extra al final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dorado, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.home, color: Color(0xFFFAB334), size: 32),
          SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.direccion,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blanco),
                ),
                Text(
                  widget.property.tipo == PropertyType.otro ? 'Propiedad' : widget.property.tipo.toString().split('.').last,
                  style: const TextStyle(fontSize: 14, color: Color(0xFFF5E6C8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 MÉTODOS DE CAPTURA',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dorado, letterSpacing: 1),
        ),
        SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(
              child: _buildCaptureMethodCard(
                icon: Icons.photo_library,
                title: 'Galería',
                onPressed: _pickFromGallery,
              ),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: _buildCaptureMethodCard(
                icon: Icons.camera_alt,
                title: 'Cámara',
                onPressed: _captureWithPhone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaptureMethodCard({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.negro,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.grisOscuro, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.blanco, size: 36),
            SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.blanco)),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothCamerasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📡 CÁMARAS 360°',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dorado, letterSpacing: 1),
            ),
            if (!_isScanning)
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16, color: AppTheme.dorado),
                label: const Text('Escanear', style: TextStyle(color: AppTheme.dorado)),
                onPressed: _scanForCameras,
              ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSM),
        if (_isScanning)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.dorado)))
        else if (_detectedCameras.isEmpty)
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.grisOscuro.withOpacity(0.5), borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
            child: const Text('No se detectaron cámaras Bluetooth', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          )
        else
          ..._detectedCameras.map((camera) => _buildCameraCard(camera)).toList(),
      ],
    );
  }

  Widget _buildCameraCard(Camera360Device camera) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dorado.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera, color: AppTheme.dorado, size: 32),
          SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(camera.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.blanco)),
                Text(camera.type, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _connectToCamera(camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado, 
              foregroundColor: AppTheme.negro,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  // ✅ REQUERIMIENTO 1: Sección VISIBLE de fotos capturadas
  Widget _buildCapturedPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✅ FOTOS CAPTURADAS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dorado, letterSpacing: 1),
            ),
            if (_capturedPhotos.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _confirmClearAllPhotos,
                tooltip: 'Borrar todas',
              ),
          ],
        ),
        SizedBox(height: AppTheme.spacingMD),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Mantiene visibilidad al hacer scroll
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _capturedPhotos.length,
          itemBuilder: (context, index) {
            final photo = _capturedPhotos[index];
            return _buildPhotoItem(photo);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoItem(CapturedPhoto photo) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.grisOscuro, width: 1),
            image: DecorationImage(
              image: _getImageProvider(photo.uri),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removePhoto(photo), // ✅ Eliminación individual
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider(String source) {
    if (source.startsWith('http')) {
      return NetworkImage(source);
    } else if (source.startsWith('data:')) {
      // Manejo básico de base64 si fuera necesario
      return NetworkImage(source); // Placeholder
    } else {
      if (kIsWeb) {
        return NetworkImage(source); // En web local blob url
      }
      return FileImage(File(source));
    }
  }

  // ✅ REQUERIMIENTO 1: Eliminar foto individual (Estado + Persistencia)
  void _removePhoto(CapturedPhoto photo) {
    setState(() {
      _capturedPhotos.removeWhere((p) => p.id == photo.id);
    });
    // Eliminar de persistencia
    _camera360Service.removePhotoFromSession(photo.id, _isQuickCapture, widget.property.id);
  }

  Future<void> _confirmClearAllPhotos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.negro,
        title: const Text('¿Borrar todas las fotos?', style: TextStyle(color: AppTheme.blanco)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar Todo', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _capturedPhotos.clear());
      _camera360Service.clearSession(_isQuickCapture, widget.property.id);
    }
  }

  // ✅ REQUERIMIENTO 2: Botón CREAR TOUR funcional
  Widget _buildCreateTourButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _initiateTourCreation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dorado,
          foregroundColor: AppTheme.negro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
          elevation: 4,
        ),
        icon: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.negro))
            : const Icon(Icons.panorama_photosphere, size: 28),
        label: Text(
          _isUploading ? 'PROCESANDO...' : 'CREAR TOUR VIRTUAL',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildViewToursButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ToursListScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.dorado,
          side: const BorderSide(color: AppTheme.dorado, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
        ),
        icon: const Icon(Icons.list_alt, size: 28),
        label: const Text(
          'VER MIS TOURS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  // Lógica de métodos de captura
  Future<void> _pickFromGallery() async {
    final photo = await _camera360Service.pickFrom360Gallery();
    if (photo != null) {
      final path = await _processFileForPreview(photo);
      if (path != null && mounted) _showImagePreviewDialog(path);
    }
  }

  Future<void> _captureWithPhone() async {
    final photo = await _camera360Service.captureWithPhoneCamera();
    if (photo != null) {
      final path = await _processFileForPreview(photo);
      if (path != null && mounted) _showImagePreviewDialog(path);
    }
  }

  Future<void> _uploadAndAddPhoto(String localPath) async {
    if (mounted) _showImagePreviewDialog(localPath);
  }

  Future<String?> _processFileForPreview(XFile photo) async {
    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
    return photo.path;
  }

  // ✅ DIÁLOGO DE PREVISUALIZACIÓN Y GUARDADO
  void _showImagePreviewDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.negro,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dorado),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 300,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  child: _getImageWidget(imagePath),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Descartar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _savePhotoLocally(imagePath),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dorado, foregroundColor: AppTheme.negro),
                        child: const Text('GUARDAR'),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(String source) {
    if (source.startsWith('data:')) {
      return Image.memory(base64Decode(source.split(',')[1]), fit: BoxFit.cover);
    } else if (source.startsWith('http')) {
      return Image.network(source, fit: BoxFit.cover);
    } else {
      return kIsWeb ? Image.network(source, fit: BoxFit.cover) : Image.file(File(source), fit: BoxFit.cover);
    }
  }

  // ✅ REQUERIMIENTO 1: Guardar foto localmente (Estado + Persistencia)
  void _savePhotoLocally(String imagePath) {
    // Estructura requerida: {id, uri, filename, timestamp}
    final newPhoto = CapturedPhoto(
      id: const Uuid().v4(),
      uri: imagePath,
      filename: 'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _capturedPhotos.add(newPhoto);
    });

    // Guardar en almacenamiento persistente
    _camera360Service.addPhotoToSession(newPhoto, _isQuickCapture, widget.property.id);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Foto guardada'), backgroundColor: Colors.green, duration: Duration(milliseconds: 1000)),
    );
  }

  Future<void> _scanForCameras() async {
    setState(() => _isScanning = true);
    final cameras = await _camera360Service.scanFor360Cameras();
    if (mounted) setState(() { _detectedCameras = cameras; _isScanning = false; });
  }

  Future<void> _connectToCamera(Camera360Device camera) async {
    setState(() => _connectedCamera = camera);
  }

  Widget _buildLivePreviewSection() {
    return Camera360LivePreview(
      camera: _connectedCamera!,
      onPhotoCapture: _uploadAndAddPhoto,
    );
  }

  // ✅ REQUERIMIENTO 2: Validación y Ventana Flotante de Selección
  void _initiateTourCreation() {
    // Validación 1: Mínimo 1 foto
    if (_capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes cargar mínimo 1 foto 360°'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Abrir ventana flotante para seleccionar fotos
    _showPhotoSelectionDialog();
  }

  void _showPhotoSelectionDialog() {
    // Por defecto todas seleccionadas
    List<CapturedPhoto> selectedPhotos = List.from(_capturedPhotos);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.negro,
            title: const Text('Seleccionar Fotos para Tour', style: TextStyle(color: AppTheme.dorado)),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Toca las fotos para incluir/excluir', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: _capturedPhotos.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final photo = _capturedPhotos[index];
                        final isSelected = selectedPhotos.any((p) => p.id == photo.id);
                        
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              if (isSelected) {
                                selectedPhotos.removeWhere((p) => p.id == photo.id);
                              } else {
                                selectedPhotos.add(photo);
                              }
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Opacity(
                                  opacity: isSelected ? 1.0 : 0.4,
                                  child: _getImageWidget(photo.uri),
                                ),
                              ),
                              if (isSelected) 
                                const Positioned(
                                  right: 4, 
                                  top: 4, 
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.dorado,
                                    child: Icon(Icons.check, size: 16, color: AppTheme.negro),
                                  )
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${selectedPhotos.length} fotos seleccionadas', style: const TextStyle(color: AppTheme.blanco, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                onPressed: selectedPhotos.isEmpty ? null : () {
                  Navigator.pop(context);
                  _generateAndSaveTour(selectedPhotos);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dorado, foregroundColor: AppTheme.negro),
                child: const Text('CREAR TOUR'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ REQUERIMIENTO 2: Generar Objeto Tour y Redireccionar
  Future<void> _generateAndSaveTour(List<CapturedPhoto> photos) async {
    setState(() => _isUploading = true);

    try {
      // 1. Validar (aunque ya se validó antes)
      if (photos.isEmpty) return;

      // 2. Obtener usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // 3. Crear escenas a partir de las fotos
      final scenes = photos.asMap().entries.map((entry) {
        int index = entry.key;
        CapturedPhoto photo = entry.value;
        
        return TourScene(
          id: 'scene_${index + 1}',
          photoUrl: photo.uri,
          title: 'Escena ${index + 1}',
          description: 'Foto capturada el ${_formatTimestamp(photo.timestamp)}',
          hotspots: [], // Array vacío - se agregarán en el editor
          order: index,
        );
      }).toList();

      // 4. Crear tour en Firestore con el nuevo modelo
      final tour = await _virtualTourService.createTourWithScenes(
        propertyId: widget.property.id,
        propertyName: widget.property.direccion,
        propertyAddress: widget.property.direccion,
        userId: user.uid,
        scenes: scenes,
        description: 'Tour virtual de ${widget.property.direccion}',
        tourOption: 1, // Pannellum
      );
      
      debugPrint('✅ Tour guardado en Firestore: ${tour.id}');

      if (mounted) {
        // 5. Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // 6. Redireccionar al editor para agregar hotspots
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TourEditorProScreen(tour: tour),
          ),
        ).then((_) {
          // Opcional: recargar fotos al volver
          _loadPersistedPhotos();
        });
      }

    } catch (e) {
      debugPrint('❌ Error creando tour: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatTimestamp(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp.toString();
    }
  }
}
