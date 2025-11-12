import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/inventory_property.dart';
import '../../services/inventory_service.dart';
import 'property_detail_screen.dart';
import 'add_edit_property_screen.dart';

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
      final properties = await _inventoryService.getAllProperties();
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
      final results = await _inventoryService.searchProperties(query);
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
      appBar: AppBar(
        title: const Text('Inventarios'),
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por dirección o cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
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
                          padding: const EdgeInsets.all(16),
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
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF2C2C2C),
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 12),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToPropertyDetail(property),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.tipo.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.direccion,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.tipo.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  if (property.numeroHabitaciones != null) ...[
                    Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${property.numeroHabitaciones}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (property.numeroBanos != null) ...[
                    Icon(Icons.bathroom, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${property.numeroBanos}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
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
