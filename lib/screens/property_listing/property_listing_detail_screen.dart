import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/property_listing.dart';
import '../../services/property_listing_service.dart';
import '../../widgets/panorama_360_viewer.dart';
import '../../config/app_theme.dart';
import 'add_edit_property_listing_screen.dart';

/// Pantalla de detalle completa de una captación inmobiliaria
class PropertyListingDetailScreen extends StatefulWidget {
  final PropertyListing listing;

  const PropertyListingDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<PropertyListingDetailScreen> createState() => _PropertyListingDetailScreenState();
}

class _PropertyListingDetailScreenState extends State<PropertyListingDetailScreen> {
  final PropertyListingService _service = PropertyListingService();
  late PropertyListing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen de fondo
          _buildSliverAppBar(),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información principal
                _buildMainInfo(),
                
                // Precio y estado
                _buildPriceSection(),
                
                // Características principales
                _buildMainFeatures(),
                
                // Descripción
                if (_listing.descripcion != null) _buildDescription(),
                
                // Características adicionales
                if (_listing.caracteristicas.isNotEmpty) _buildCharacteristics(),
                
                // Galería de fotos
                if (_listing.fotos.isNotEmpty) _buildPhotoGallery(),
                
                // Fotos 360°
                if (_listing.fotos360.isNotEmpty) _build360Gallery(),
                
                // Planos
                if (_listing.plano2DUrl != null || _listing.plano3DUrl != null)
                  _buildFloorPlans(),
                
                // Tour virtual
                if (_listing.tourVirtualId != null) _buildVirtualTour(),
                
                // Información del propietario
                _buildOwnerInfo(),
                
                // Observaciones
                if (_listing.observaciones != null) _buildObservations(),
                
                const SizedBox(height: 100), // Espacio para botones flotantes
              ],
            ),
          ),
        ],
      ),
      
      // Botones flotantes
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// App bar con imagen principal
  Widget _buildSliverAppBar() {
    final String? imageUrl = _listing.fotos.isNotEmpty ? _listing.fotos.first : null;
    
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _listing.tipo.toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
        background: imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.home, size: 100, color: Colors.grey),
                      );
                    },
                  ),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.home, size: 100, color: Colors.grey),
              ),
      ),
      actions: [
        // Badge de completitud de medios
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCompletitudeColor(_listing.porcentajeCompletitud),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${_listing.porcentajeCompletitud}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Información principal (título, dirección, estado)
  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono de tipo de transacción
              Text(
                _listing.transaccionTipo.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _listing.titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _listing.direccion,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
          if (_listing.ciudad != null || _listing.barrio != null) ...[
            const SizedBox(height: 4),
            Text(
              [_listing.barrio, _listing.ciudad].where((e) => e != null).join(', '),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          // Estado de la captación
          _buildStatusChip(_listing.estado),
        ],
      ),
    );
  }

  /// Chip de estado
  Widget _buildStatusChip(ListingStatus estado) {
    Color color;
    switch (estado) {
      case ListingStatus.activo:
        color = Colors.green;
        break;
      case ListingStatus.enNegociacion:
        color = Colors.orange;
        break;
      case ListingStatus.vendido:
        color = Colors.blue;
        break;
      case ListingStatus.arrendado:
        color = Colors.purple;
        break;
      case ListingStatus.cancelado:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Sección de precios
  Widget _buildPriceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFFFFD700)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _listing.transaccionTipo.displayName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          if (_listing.transaccionTipo == TransactionType.venta ||
              _listing.transaccionTipo == TransactionType.ventaArriendo) ...[
            Row(
              children: [
                const Text('Venta: ', style: TextStyle(fontSize: 16)),
                Text(
                  _listing.precioVenta != null
                      ? '\$${_listing.precioVenta!.toStringAsFixed(0)}'
                      : 'No especificado',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ],
          if (_listing.transaccionTipo == TransactionType.arriendo ||
              _listing.transaccionTipo == TransactionType.ventaArriendo) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Arriendo: ', style: TextStyle(fontSize: 16)),
                Text(
                  _listing.precioArriendo != null
                      ? '\$${_listing.precioArriendo!.toStringAsFixed(0)}/mes'
                      : 'No especificado',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ],
          if (_listing.administracion != null) ...[
            const SizedBox(height: 8),
            Text(
              'Administración: \$${_listing.administracion!.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// Características principales (área, habitaciones, baños)
  Widget _buildMainFeatures() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_listing.area != null)
            _buildFeatureCard(
              icon: Icons.square_foot,
              value: '${_listing.area!.toStringAsFixed(0)} m²',
              label: 'Área',
            ),
          if (_listing.numeroHabitaciones != null)
            _buildFeatureCard(
              icon: Icons.bed,
              value: '${_listing.numeroHabitaciones}',
              label: 'Habitaciones',
            ),
          if (_listing.numeroBanos != null)
            _buildFeatureCard(
              icon: Icons.bathroom,
              value: '${_listing.numeroBanos}',
              label: 'Baños',
            ),
          if (_listing.numeroParqueaderos != null)
            _buildFeatureCard(
              icon: Icons.directions_car,
              value: '${_listing.numeroParqueaderos}',
              label: 'Parqueaderos',
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xFFFFD700)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// Descripción del inmueble
  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _listing.descripcion!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Lista de características
  Widget _buildCharacteristics() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Características',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _listing.caracteristicas.map((caracteristica) {
              return Chip(
                label: Text(caracteristica),
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Galería de fotos
  Widget _buildPhotoGallery() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Galería de Fotos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _listing.fotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showPhotoGallery(context, index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_listing.fotos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Galería de fotos 360°
  Widget _build360Gallery() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.threesixty, color: AppTheme.dorado),
              const SizedBox(width: 8),
              const Text(
                'Fotos 360°',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blanco,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.dorado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dorado),
                ),
                child: Text(
                  '${_listing.fotos360.length} vistas',
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _listing.fotos360.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Abrir visor 360°
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Panorama360Viewer(
                          imageUrls: _listing.fotos360,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.dorado, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(_listing.fotos360[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // 360° Badge overlay
                      Positioned(
                        top: 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.dorado,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '360°',
                            style: TextStyle(
                              color: AppTheme.negro,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      // Center icon
                      const Center(
                        child: Icon(
                          Icons.threesixty,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.grisClaro),
              const SizedBox(width: 6),
              const Text(
                'Toca una vista para explorar en 360°',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grisClaro,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Planos 2D y 3D
  Widget _buildFloorPlans() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_listing.plano2DUrl != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImage(context, _listing.plano2DUrl!, 'Plano 2D'),
                    child: Column(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(_listing.plano2DUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Plano 2D'),
                      ],
                    ),
                  ),
                ),
              if (_listing.plano2DUrl != null && _listing.plano3DUrl != null)
                const SizedBox(width: 16),
              if (_listing.plano3DUrl != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImage(context, _listing.plano3DUrl!, 'Plano 3D'),
                    child: Column(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(_listing.plano3DUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Plano 3D'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tour virtual
  Widget _buildVirtualTour() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tour Virtual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Abrir tour virtual
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tour virtual en desarrollo')),
              );
            },
            icon: const Icon(Icons.view_in_ar),
            label: const Text('Ver Tour Virtual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Información del propietario
  Widget _buildOwnerInfo() {
    if (_listing.propietarioNombre == null &&
        _listing.propietarioTelefono == null &&
        _listing.propietarioEmail == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Propietario',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_listing.propietarioNombre != null) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_listing.propietarioNombre!),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (_listing.propietarioTelefono != null) ...[
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_listing.propietarioTelefono!),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (_listing.propietarioEmail != null) ...[
            Row(
              children: [
                const Icon(Icons.email, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_listing.propietarioEmail!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Observaciones
  Widget _buildObservations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Observaciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_listing.observaciones!),
        ],
      ),
    );
  }

  /// Botones flotantes (editar, compartir, eliminar)
  Widget _buildFloatingActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Editar
          FloatingActionButton.extended(
            heroTag: 'edit',
            onPressed: _editListing,
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
          
          // Compartir
          FloatingActionButton(
            heroTag: 'share',
            onPressed: _shareListing,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.share),
          ),
          
          // Eliminar
          FloatingActionButton(
            heroTag: 'delete',
            onPressed: _deleteListing,
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  /// Mostrar galería de fotos con zoom
  void _showPhotoGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryViewer(
          images: _listing.fotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// Mostrar imagen individual con zoom
  void _showImage(BuildContext context, String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  /// Editar captación
  void _editListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPropertyListingScreen(listing: _listing),
      ),
    ).then((result) {
      if (result == true) {
        // Recargar datos
        _reloadListing();
      }
    });
  }

  /// Compartir captación
  void _shareListing() {
    // TODO: Implementar compartir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir en desarrollo')),
    );
  }

  /// Eliminar captación
  void _deleteListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Captación'),
        content: const Text('¿Estás seguro de eliminar esta captación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deletePropertyListing(_listing.id);
        if (mounted) {
          Navigator.pop(context, true); // Volver a lista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Captación eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  /// Recargar datos de la captación
  void _reloadListing() async {
    try {
      final updated = await _service.getPropertyListing(_listing.id);
      if (updated != null && mounted) {
        setState(() {
          _listing = updated;
        });
      }
    } catch (e) {
      // Error silencioso
    }
  }

  /// Obtener color según completitud de medios
  Color _getCompletitudeColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// Visor de galería de fotos con zoom
class PhotoGalleryViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const PhotoGalleryViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foto ${initialIndex + 1} de ${images.length}'),
        backgroundColor: Colors.black,
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(images[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}
