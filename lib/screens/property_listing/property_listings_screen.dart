import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/property_listing.dart';
import '../../services/property_listing_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import 'add_edit_property_listing_screen.dart';
import 'property_listing_detail_screen.dart';

/// Pantalla principal de lista de captaciones de inmuebles
class PropertyListingsScreen extends StatefulWidget {
  const PropertyListingsScreen({super.key});

  @override
  State<PropertyListingsScreen> createState() => _PropertyListingsScreenState();
}

class _PropertyListingsScreenState extends State<PropertyListingsScreen> {
  final PropertyListingService _listingService = PropertyListingService();
  List<PropertyListing> _listings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TransactionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) return;

      List<PropertyListing> listings;
      
      if (_filterType != null) {
        listings = await _listingService.filterByTransactionType(
          transactionType: _filterType!,
          userId: user.uid,
          isAdmin: user.hasAdminAccess,
        );
      } else {
        listings = await _listingService.getAllListings(
          userId: user.uid,
          isAdmin: user.hasAdminAccess,
        );
      }

      if (mounted) {
        setState(() {
          _listings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading listings: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchListings(String query) async {
    setState(() => _searchQuery = query);
    if (query.isEmpty) {
      await _loadListings();
      return;
    }
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) return;

      final results = await _listingService.searchListings(
        query: query,
        userId: user.uid,
        isAdmin: user.hasAdminAccess,
      );
      
      if (mounted) {
        setState(() => _listings = results);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching listings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Captación de Inmuebles'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadListings,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            child: TextField(
              style: const TextStyle(color: AppTheme.blanco),
              decoration: InputDecoration(
                hintText: 'Buscar por dirección o ciudad...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppTheme.dorado),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: const BorderSide(color: AppTheme.grisClaro),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: const BorderSide(color: AppTheme.dorado, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.grisOscuro,
              ),
              onChanged: _searchListings,
            ),
          ),

          // Filtros de tipo de transacción
          _buildTransactionTypeFilters(),
          
          // Lista de captaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.dorado))
                : _listings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadListings,
                        child: ListView.builder(
                          padding: EdgeInsets.all(AppTheme.paddingMD),
                          itemCount: _listings.length,
                          itemBuilder: (context, index) {
                            return _buildListingCard(_listings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddListing,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Captación'),
        backgroundColor: AppTheme.dorado,
        foregroundColor: AppTheme.negro,
      ),
    );
  }

  Widget _buildTransactionTypeFilters() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Todos', null),
          const SizedBox(width: 8),
          _buildFilterChip('Venta 💰', TransactionType.venta),
          const SizedBox(width: 8),
          _buildFilterChip('Arriendo 🔑', TransactionType.arriendo),
          const SizedBox(width: 8),
          _buildFilterChip('Venta/Arriendo', TransactionType.ventaArriendo),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _filterType == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? type : null;
        });
        _loadListings();
      },
      selectedColor: AppTheme.dorado,
      backgroundColor: AppTheme.grisOscuro,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.negro : AppTheme.blanco,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.dorado : AppTheme.grisClaro,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 100,
            color: Colors.grey[600],
          ),
          SizedBox(height: AppTheme.spacingXL),
          Text(
            _searchQuery.isEmpty
                ? '¡No hay captaciones aún!'
                : 'No se encontraron resultados',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: AppTheme.spacingMD),
          Text(
            _searchQuery.isEmpty
                ? 'Agrega tu primera captación para comenzar'
                : 'Intenta con otra búsqueda',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(PropertyListing listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(listing),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tipo de transacción
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.dorado,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      '${listing.transaccionTipo.icon} ${listing.transaccionTipo.displayName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.negro,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(listing.estado).withValues(alpha: 0.2),
                      border: Border.all(color: _getEstadoColor(listing.estado)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      listing.estado.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getEstadoColor(listing.estado),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMD),
              
              // Título y dirección
              Text(
                listing.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blanco,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.dorado),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      listing.direccion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.grisClaro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Precio
              Text(
                listing.getPrecioDisplay(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dorado,
                ),
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Detalles
              Row(
                children: [
                  if (listing.numeroHabitaciones != null) ...[
                    const Icon(Icons.bed, size: 16, color: AppTheme.grisClaro),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.numeroHabitaciones}',
                      style: const TextStyle(color: AppTheme.blanco),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                  ],
                  if (listing.numeroBanos != null) ...[
                    const Icon(Icons.bathroom, size: 16, color: AppTheme.grisClaro),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.numeroBanos}',
                      style: const TextStyle(color: AppTheme.blanco),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                  ],
                  if (listing.area != null) ...[
                    const Icon(Icons.square_foot, size: 16, color: AppTheme.grisClaro),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.area!.toStringAsFixed(0)} m²',
                      style: const TextStyle(color: AppTheme.blanco),
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Barra de progreso de medios
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Completitud de Medios',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisClaro,
                        ),
                      ),
                      Text(
                        '${listing.porcentajeCompletitud}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dorado,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: listing.porcentajeCompletitud / 100,
                      backgroundColor: AppTheme.grisClaro.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(ListingStatus estado) {
    switch (estado) {
      case ListingStatus.activo:
        return Colors.green;
      case ListingStatus.enNegociacion:
        return Colors.orange;
      case ListingStatus.vendido:
        return Colors.blue;
      case ListingStatus.arrendado:
        return Colors.purple;
      case ListingStatus.cancelado:
        return Colors.red;
    }
  }

  Future<void> _navigateToAddListing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPropertyListingScreen(),
      ),
    );
    
    if (result == true) {
      await _loadListings();
    }
  }

  Future<void> _navigateToDetail(PropertyListing listing) async {
    // Placeholder - se implementará PropertyListingDetailScreen después
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalle de: ${listing.titulo}'),
        backgroundColor: AppTheme.dorado,
      ),
    );
  }
}
