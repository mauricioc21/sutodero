import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../config/app_theme.dart';

class TourEditorScreen extends StatefulWidget {
  final String tourId;
  final Map<String, dynamic> tourData;

  const TourEditorScreen({
    Key? key,
    required this.tourId,
    required this.tourData,
  }) : super(key: key);

  @override
  State<TourEditorScreen> createState() => _TourEditorScreenState();
}

class _TourEditorScreenState extends State<TourEditorScreen> {
  int _currentSceneIndex = 0;
  List<dynamic> _scenes = [];

  @override
  void initState() {
    super.initState();
    _scenes = widget.tourData['scenes'] as List? ?? [];
  }

  void _changeScene(int index) {
    if (index != _currentSceneIndex) {
      setState(() {
        _currentSceneIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scenes.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.negro,
        appBar: AppBar(
          title: const Text('Editor de Tour'),
          backgroundColor: AppTheme.grisOscuro,
          foregroundColor: AppTheme.dorado,
        ),
        body: const Center(
          child: Text('⚠️ No hay escenas en este tour', style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }

    final currentScene = _scenes[_currentSceneIndex];

    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Editor de Tour Virtual'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'Añadir Hotspot',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Toca en el visor para añadir un punto de interés')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar Tour',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Tour guardado exitosamente')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ 1. VISOR 360° (Ocupa la mayor parte de la pantalla)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  _buildPanoramaViewer(currentScene),
                  
                  // Título de la escena (Overlay)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.dorado.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.panorama_photosphere, color: AppTheme.dorado, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            currentScene['title'] ?? 'Escena ${_currentSceneIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ✅ LISTA DE ESCENAS (Navegación)
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.grisOscuro,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.black26,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ESCENAS DEL TOUR (${_scenes.length})',
                          style: const TextStyle(
                            color: AppTheme.dorado, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Icon(Icons.layers, color: AppTheme.dorado.withOpacity(0.7), size: 18),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _scenes.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final scene = _scenes[index];
                        final isSelected = index == _currentSceneIndex;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _changeScene(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.dorado.withOpacity(0.15) : Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.dorado : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _buildThumbnail(scene['imageUri']),
                                  ),
                                ),
                                title: Text(
                                  scene['title'] ?? 'Escena ${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.dorado : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${scene['id']}',
                                  style: TextStyle(
                                    color: Colors.grey[400], 
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isSelected 
                                    ? const Icon(Icons.visibility, color: AppTheme.dorado)
                                    : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 2. IMPLEMENTACIÓN CORRECTA DEL VISOR 360° (Sin texto Base64)
  Widget _buildPanoramaViewer(Map<String, dynamic> scene) {
    // Detectar tipo de imagen
    final String imageUri = scene['imageUri'] ?? '';
    ImageProvider imageProvider;

    try {
      if (imageUri.startsWith('data:')) {
        // Opción A: Base64
        final base64String = imageUri.split(',')[1];
        imageProvider = MemoryImage(base64Decode(base64String));
      } else if (imageUri.startsWith('http')) {
        // Opción B: URL Remota
        imageProvider = NetworkImage(imageUri);
      } else {
        // Opción C: Archivo Local
        if (kIsWeb) {
          // En web, 'path' local a veces requiere manejo especial o NetworkImage si es blob
          imageProvider = NetworkImage(imageUri); 
        } else {
          imageProvider = FileImage(File(imageUri));
        }
      }
    } catch (e) {
      debugPrint('❌ Error al procesar imagen para visor: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text('Error al cargar imagen 360°', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // ✅ Uso de PanoramaViewer
    // Usamos ValueKey para forzar la actualización correcta cuando cambia la escena
    return PanoramaViewer(
      key: ValueKey(scene['id']), 
      animSpeed: 0.5, // Rotación automática suave
      // sensorControl: SensorControl.orientation, // Control con giroscopio
      hotspots: _buildHotspots(scene['hotspots']),
      child: Image(
        image: imageProvider,
        fit: BoxFit.cover, // Asegurar que cubra
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text('Error cargando imagen: $error', style: const TextStyle(color: Colors.red)),
          );
        },
      ),
    );
  }

  // ✅ Integración de Hotspots (Puntos de interés)
  List<Hotspot> _buildHotspots(List? hotspotsData) {
    if (hotspotsData == null) return [];
    
    return hotspotsData.map((h) {
      return Hotspot(
        latitude: (h['latitude'] ?? 0.0).toDouble(),
        longitude: (h['longitude'] ?? 0.0).toDouble(),
        width: 60,
        height: 60,
        widget: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white, size: 30),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hotspot: ${h['text'] ?? 'Info'}')),
            );
          },
        ),
      );
    }).toList();
  }
  
  // Generador de miniaturas para la lista
  Widget _buildThumbnail(String uri) {
    try {
      if (uri.startsWith('data:')) {
        return Image.memory(
          base64Decode(uri.split(',')[1]), 
          fit: BoxFit.cover,
          errorBuilder: (_,__,___) => const Icon(Icons.error, color: Colors.red),
        );
      } else if (uri.startsWith('http')) {
        return Image.network(
          uri, 
          fit: BoxFit.cover,
          errorBuilder: (_,__,___) => const Icon(Icons.error, color: Colors.red),
        );
      } else {
        return kIsWeb 
            ? Image.network(uri, fit: BoxFit.cover) 
            : Image.file(File(uri), fit: BoxFit.cover);
      }
    } catch (e) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }
  }
}
