import 'package:flutter/material.dart';
import '../../services/camera_360_service.dart';
import '../../services/storage_service.dart';
import '../../services/virtual_tour_service.dart';
import '../../models/inventory_property.dart';

/// Pantalla universal de captura de fotos 360°
/// Soporta múltiples métodos: Galería, Cámara del teléfono, Bluetooth
class Camera360CaptureScreen extends StatefulWidget {
  final InventoryProperty property;

  const Camera360CaptureScreen({
    super.key,
    required this.property,
  });

  @override
  State<Camera360CaptureScreen> createState() => _Camera360CaptureScreenState();
}

class _Camera360CaptureScreenState extends State<Camera360CaptureScreen> {
  final Camera360Service _camera360Service = Camera360Service();
  final StorageService _storageService = StorageService();
  final VirtualTourService _virtualTourService = VirtualTourService();

  List<Camera360Device> _detectedCameras = [];
  bool _isScanning = false;
  List<String> _capturedPhotos = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Captura 360°'),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          if (_capturedPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_capturedPhotos.length} fotos',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información de la propiedad
              _buildPropertyInfo(),
              
              const SizedBox(height: 32),
              
              // Métodos de captura principales
              _buildCaptureMethodsSection(),
              
              const SizedBox(height: 32),
              
              // Sección de cámaras Bluetooth
              _buildBluetoothCamerasSection(),
              
              const SizedBox(height: 32),
              
              // Fotos capturadas
              if (_capturedPhotos.isNotEmpty) _buildCapturedPhotosSection(),
              
              const SizedBox(height: 32),
              
              // Botón para crear tour virtual
              if (_capturedPhotos.isNotEmpty) _buildCreateTourButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Información de la propiedad
  Widget _buildPropertyInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.direccion,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tipo: ${widget.property.tipo}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF5E6C8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Métodos de captura principales
  Widget _buildCaptureMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 MÉTODOS DE CAPTURA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        
        // Botón: Seleccionar desde Galería (RECOMENDADO)
        _buildCaptureMethodButton(
          icon: Icons.photo_library,
          title: 'Seleccionar desde Galería',
          subtitle: 'Fotos 360° ya capturadas',
          recommended: true,
          onPressed: _pickFromGallery,
        ),
        
        const SizedBox(height: 12),
        
        // Botón: Capturar con Cámara del Teléfono
        _buildCaptureMethodButton(
          icon: Icons.camera_alt,
          title: 'Capturar con Cámara del Teléfono',
          subtitle: 'Foto panorámica manual',
          onPressed: _captureWithPhone,
        ),
      ],
    );
  }

  /// Botón de método de captura
  Widget _buildCaptureMethodButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool recommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommended ? const Color(0xFFFFD700) : const Color(0xFF2C2C2C),
          width: 2,
        ),
      ),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFFFD700), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'RECOMENDADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sección de cámaras Bluetooth
  Widget _buildBluetoothCamerasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📡 CÁMARAS 360° (BLUETOOTH)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 1,
              ),
            ),
            if (!_isScanning)
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
                onPressed: _scanForCameras,
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isScanning)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFFFD700)),
                SizedBox(height: 16),
                Text(
                  'Escaneando cámaras 360°...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        else if (_detectedCameras.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'No se detectaron cámaras 360°',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _scanForCameras,
                  icon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                  label: const Text(
                    'Escanear',
                    style: TextStyle(color: Color(0xFFFFD700)),
                  ),
                ),
              ],
            ),
          )
        else
          ..._detectedCameras.map((camera) => _buildCameraCard(camera)).toList(),
      ],
    );
  }

  /// Tarjeta de cámara detectada
  Widget _buildCameraCard(Camera360Device camera) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera, color: Color(0xFFFFD700), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camera.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  camera.type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF5E6C8),
                  ),
                ),
                if (camera.rssi != null)
                  Text(
                    'Señal: ${camera.rssi} dBm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _connectToCamera(camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  /// Fotos capturadas
  Widget _buildCapturedPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✅ FOTOS CAPTURADAS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _capturedPhotos.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _capturedPhotos[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          _capturedPhotos.removeAt(index);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Botón para crear tour virtual
  Widget _buildCreateTourButton() {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _createVirtualTour,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : const Icon(Icons.panorama_photosphere, size: 28),
      label: Text(
        _isUploading ? 'Creando Tour...' : 'CREAR TOUR VIRTUAL (${_capturedPhotos.length} fotos)',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// Seleccionar desde galería
  Future<void> _pickFromGallery() async {
    final photoPath = await _camera360Service.pickFrom360Gallery();
    if (photoPath != null) {
      await _uploadAndAddPhoto(photoPath);
    }
  }

  /// Capturar con cámara del teléfono
  Future<void> _captureWithPhone() async {
    final photoPath = await _camera360Service.captureWithPhoneCamera();
    if (photoPath != null) {
      await _uploadAndAddPhoto(photoPath);
    }
  }

  /// Subir foto y agregarla a la lista
  Future<void> _uploadAndAddPhoto(String localPath) async {
    try {
      setState(() => _isUploading = true);

      // Subir a Firebase Storage
      final photoUrl = await _storageService.uploadInventoryActPhoto(
        actId: widget.property.id,
        filePath: localPath,
      );

      if (photoUrl != null && mounted) {
        setState(() {
          _capturedPhotos.add(photoUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al subir foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Escanear cámaras Bluetooth
  Future<void> _scanForCameras() async {
    setState(() => _isScanning = true);

    final cameras = await _camera360Service.scanFor360Cameras();

    if (mounted) {
      setState(() {
        _detectedCameras = cameras;
        _isScanning = false;
      });

      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No se detectaron cámaras 360° cerca'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Conectar a cámara
  Future<void> _connectToCamera(Camera360Device camera) async {
    final result = await _camera360Service.captureWith360Camera(camera);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${camera.name}'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      );
    }
  }

  /// Crear tour virtual
  Future<void> _createVirtualTour() async {
    if (_capturedPhotos.isEmpty) return;

    try {
      setState(() => _isUploading = true);

      // Crear tour virtual
      await _virtualTourService.createTour(
        propertyId: widget.property.id,
        propertyName: widget.property.direccion,
        propertyAddress: widget.property.direccion,
        photo360Urls: _capturedPhotos,
        description: 'Tour virtual de ${widget.property.direccion}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tour virtual creado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Volver a la pantalla anterior
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true); // true indica que se creó un tour
        }
      }
    } catch (e) {
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
        setState(() => _isUploading = false);
      }
    }
  }
}
