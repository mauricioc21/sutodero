import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesitas agregar intl a pubspec.yaml si no está
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../services/camera_360_service.dart'; // Para el modelo CapturedPhoto

class Gallery360Screen extends StatefulWidget {
  final String propertyId;
  final bool isQuickCapture;
  final Function(List<CapturedPhoto>)? onPhotosSelectedForTour;

  const Gallery360Screen({
    Key? key,
    required this.propertyId,
    this.isQuickCapture = false,
    this.onPhotosSelectedForTour,
  }) : super(key: key);

  @override
  State<Gallery360Screen> createState() => _Gallery360ScreenState();
}

class _Gallery360ScreenState extends State<Gallery360Screen> {
  final Camera360Service _camera360Service = Camera360Service();
  
  // Estado de Datos
  List<CapturedPhoto> _allPhotos = [];
  List<CapturedPhoto> _filteredPhotos = [];
  Set<String> _selectedPhotoIds = {};
  
  // Estado de Filtros
  String _searchQuery = "";
  SortOption _currentSort = SortOption.dateDesc;
  bool _isSelectionMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // ------------------------------------------------------------------------
  // 1. GESTIÓN DE DATOS (Load & Save)
  // ------------------------------------------------------------------------

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = await _camera360Service.getSessionPhotos(widget.isQuickCapture, widget.propertyId);
    
    if (mounted) {
      setState(() {
        _allPhotos = photos;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(CapturedPhoto photo) async {
    await _camera360Service.removePhotoFromSession(photo.id, widget.isQuickCapture, widget.propertyId);
    setState(() {
      _allPhotos.removeWhere((p) => p.id == photo.id);
      _selectedPhotoIds.remove(photo.id);
      _applyFilters();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto eliminada'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    if (_selectedPhotoIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.negro,
        title: const Text('Eliminar Fotos', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de eliminar ${_selectedPhotoIds.length} fotos?', 
          style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedPhotoIds) {
        await _camera360Service.removePhotoFromSession(id, widget.isQuickCapture, widget.propertyId);
        _allPhotos.removeWhere((p) => p.id == id);
      }
      setState(() {
        _selectedPhotoIds.clear();
        _isSelectionMode = false;
        _applyFilters();
      });
    }
  }

  // ------------------------------------------------------------------------
  // 2. LÓGICA DE FILTROS Y SELECCIÓN
  // ------------------------------------------------------------------------

  void _applyFilters() {
    List<CapturedPhoto> temp = List.from(_allPhotos);

    // 1. Búsqueda
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((p) => p.filename.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 2. Ordenamiento
    switch (_currentSort) {
      case SortOption.dateDesc:
        temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOption.dateAsc:
        temp.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOption.nameAsc:
        temp.sort((a, b) => a.filename.compareTo(b.filename));
        break;
    }

    _filteredPhotos = temp;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPhotoIds.contains(id)) {
        _selectedPhotoIds.remove(id);
        if (_selectedPhotoIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPhotoIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPhotoIds.length == _filteredPhotos.length) {
        _selectedPhotoIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedPhotoIds = _filteredPhotos.map((p) => p.id).toSet();
        _isSelectionMode = true;
      }
    });
  }

  // ------------------------------------------------------------------------
  // 3. UI PRINCIPAL
  // ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.dorado))
              : _filteredPhotos.isEmpty
                ? _buildEmptyState()
                : _buildPhotoGrid(),
          ),
        ],
      ),
      floatingActionButton: (_isSelectionMode && widget.onPhotosSelectedForTour != null)
        ? FloatingActionButton.extended(
            backgroundColor: AppTheme.dorado,
            label: Text('Crear Tour (${_selectedPhotoIds.length})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.panorama_photosphere, color: Colors.black),
            onPressed: () {
              final selected = _allPhotos.where((p) => _selectedPhotoIds.contains(p.id)).toList();
              widget.onPhotosSelectedForTour!(selected);
            },
          )
        : null,
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text('Galería 360°'),
      backgroundColor: AppTheme.grisOscuro,
      foregroundColor: AppTheme.dorado,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPhotos,
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: AppTheme.dorado,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => setState(() {
          _selectedPhotoIds.clear();
          _isSelectionMode = false;
        }),
      ),
      title: Text('${_selectedPhotoIds.length} seleccionadas', 
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all, color: Colors.black),
          onPressed: _toggleSelectAll,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.black),
          onPressed: _deleteSelectedPhotos,
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar fotos...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFilters();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort, color: AppTheme.dorado),
            color: AppTheme.grisOscuro,
            onSelected: (SortOption result) {
              setState(() {
                _currentSort = result;
                _applyFilters();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.dateDesc,
                child: Text('Más recientes', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.dateAsc,
                child: Text('Más antiguas', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.nameAsc,
                child: Text('Nombre (A-Z)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No hay fotos 360° guardadas' : 'No se encontraron resultados',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredPhotos.length,
      itemBuilder: (context, index) {
        final photo = _filteredPhotos[index];
        final isSelected = _selectedPhotoIds.contains(photo.id);

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(photo.id);
            } else {
              _openViewerModal(photo);
            }
          },
          onLongPress: () => _toggleSelection(photo.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: _buildThumbnailImage(photo.uri),
                ),
              ),
              // Overlay de selección
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.dorado.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dorado, width: 3),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ),
                ),
              // Etiqueta de fecha
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Text(
                    _formatDate(photo.timestamp),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------------
  // 4. VISOR MODAL 360°
  // ------------------------------------------------------------------------

  void _openViewerModal(CapturedPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Confirmar y eliminar
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.negro,
                      title: const Text('Eliminar Foto', style: TextStyle(color: Colors.white)),
                      content: const Text('¿Estás seguro?', style: TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Cerrar diálogo
                            Navigator.pop(context); // Cerrar visor
                            _deletePhoto(photo);
                          }, 
                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: PanoramaViewer(
                    child: _buildFullImageWidget(photo.uri),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.filename, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_formatFullDate(photo.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 16),
                      if (widget.onPhotosSelectedForTour != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dorado,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('USAR EN TOUR'),
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onPhotosSelectedForTour!([photo]);
                            },
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
    );
  }

  // ------------------------------------------------------------------------
  // 5. UTILIDADES
  // ------------------------------------------------------------------------

  Widget _buildThumbnailImage(String uri) {
    if (uri.startsWith('data:')) {
      return Image.memory(base64Decode(uri.split(',')[1]), fit: BoxFit.cover);
    } else if (uri.startsWith('http')) {
      return Image.network(uri, fit: BoxFit.cover);
    } else {
      return kIsWeb ? Image.network(uri, fit: BoxFit.cover) : Image.file(File(uri), fit: BoxFit.cover);
    }
  }

  Image _buildFullImageWidget(String uri) {
    if (uri.startsWith('data:')) {
      return Image.memory(base64Decode(uri.split(',')[1]));
    } else if (uri.startsWith('http')) {
      return Image.network(uri);
    } else {
      return kIsWeb ? Image.network(uri) : Image.file(File(uri));
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}";
  }

  String _formatFullDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}

enum SortOption {
  dateDesc,
  dateAsc,
  nameAsc,
}
