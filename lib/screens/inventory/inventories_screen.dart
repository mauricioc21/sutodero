import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_property.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import 'property_detail_screen.dart';
import 'add_edit_property_screen.dart';
import '../../config/app_theme.dart';

/// Pantalla principal de lista de inventarios
class InventoriesScreen extends StatefulWidget {
  const InventoriesScreen({super.key});

  @override
  State<InventoriesScreen> createState() => _InventoriesScreenState();
}

class _InventoriesScreenState extends State<InventoriesScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryProperty> _properties = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No user logged in');
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      
      final properties = await _inventoryService.getAllProperties(userId);
      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading properties: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchProperties(String query) async {
    setState(() => _searchQuery = query);
    if (query.isEmpty) {
      await _loadProperties();
      return;
    }
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) return;

      final results = await _inventoryService.searchProperties(userId, query);
      if (mounted) {
        setState(() => _properties = results);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching properties: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Inventarios'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProperties,
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
                hintText: 'Buscar por dirección o cliente...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppTheme.dorado),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide(color: AppTheme.dorado),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide(color: AppTheme.grisClaro),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide(color: AppTheme.dorado, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.grisOscuro,
              ),
              onChanged: _searchProperties,
            ),
          ),
          
          // Lista de propiedades
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _properties.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: ListView.builder(
                          padding: EdgeInsets.all(AppTheme.paddingMD),
                          itemCount: _properties.length,
                          itemBuilder: (context, index) {
                            return _buildPropertyCard(_properties[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProperty(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Propiedad'),
        backgroundColor: AppTheme.dorado,
        foregroundColor: AppTheme.grisOscuro,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: AppTheme.spacingXL),
          Text(
            _searchQuery.isEmpty
                ? '¡No hay propiedades aún!'
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
                ? 'Agrega tu primera propiedad para comenzar'
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

  Widget _buildPropertyCard(InventoryProperty property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
      ),
      child: InkWell(
        onTap: () => _navigateToPropertyDetail(property),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dorado.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Text(
                      property.tipo.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.direccion,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blanco,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.tipo.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grisClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (property.clienteNombre != null) ...[
                SizedBox(height: AppTheme.spacingMD),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: AppTheme.spacingSM),
                    Text(
                      property.clienteNombre!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: AppTheme.spacingMD),
              Row(
                children: [
                  if (property.numeroHabitaciones != null) ...[
                    Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${property.numeroHabitaciones}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                  ],
                  if (property.numeroBanos != null) ...[
                    Icon(Icons.bathroom, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${property.numeroBanos}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: AppTheme.spacingMD),
                  ],
                  if (property.area != null) ...[
                    Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${property.area!.toStringAsFixed(0)} m²',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToPropertyDetail(InventoryProperty property) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );
    
    if (result == true) {
      await _loadProperties();
    }
  }

  Future<void> _navigateToAddProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPropertyScreen(),
      ),
    );
    
    if (result == true) {
      await _loadProperties();
    }
  }
}
