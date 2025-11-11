import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/inventory_property.dart';
import '../../models/property_room.dart';
import '../../services/inventory_service.dart';
import 'add_edit_property_screen.dart';
import 'add_edit_room_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final InventoryProperty property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<PropertyRoom> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _inventoryService.getRoomsByProperty(widget.property.id);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading rooms: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Propiedad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProperty,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyHeader(),
            _buildPropertyInfo(),
            _buildRoomsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoom,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Espacio'),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }

  Widget _buildPropertyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.property.tipo.icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.direccion,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      widget.property.tipo.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C2C2C),
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

  Widget _buildPropertyInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la Propiedad',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.property.clienteNombre != null)
            _buildInfoRow(Icons.person, 'Cliente', widget.property.clienteNombre!),
          if (widget.property.clienteTelefono != null)
            _buildInfoRow(Icons.phone, 'Teléfono', widget.property.clienteTelefono!),
          if (widget.property.clienteEmail != null)
            _buildInfoRow(Icons.email, 'Email', widget.property.clienteEmail!),
          if (widget.property.area != null)
            _buildInfoRow(Icons.square_foot, 'Área', '${widget.property.area!.toStringAsFixed(0)} m²'),
          if (widget.property.numeroHabitaciones != null)
            _buildInfoRow(Icons.bed, 'Habitaciones', '${widget.property.numeroHabitaciones}'),
          if (widget.property.numeroBanos != null)
            _buildInfoRow(Icons.bathroom, 'Baños', '${widget.property.numeroBanos}'),
          if (widget.property.descripcion != null) ...[
            const SizedBox(height: 8),
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.property.descripcion!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Espacios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_rooms.length} espacios',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rooms.isEmpty
                  ? _buildEmptyRooms()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomCard(_rooms[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyRooms() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay espacios agregados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(PropertyRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getConditionColor(room.estado).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(room.tipo.icon, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          room.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.tipo.displayName),
            Row(
              children: [
                Text(room.estado.emoji),
                const SizedBox(width: 4),
                Text(
                  room.estado.displayName,
                  style: TextStyle(
                    color: _getConditionColor(room.estado),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () => _viewRoomDetail(room),
      ),
    );
  }

  Color _getConditionColor(SpaceCondition condition) {
    switch (condition) {
      case SpaceCondition.excelente:
        return Colors.green;
      case SpaceCondition.bueno:
        return Colors.blue;
      case SpaceCondition.regular:
        return Colors.orange;
      case SpaceCondition.malo:
        return Colors.red;
      case SpaceCondition.critico:
        return Colors.purple;
    }
  }

  Future<void> _editProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPropertyScreen(property: widget.property),
      ),
    );
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _addRoom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRoomScreen(propertyId: widget.property.id),
      ),
    );
    if (result == true) {
      await _loadRooms();
    }
  }

  Future<void> _viewRoomDetail(PropertyRoom room) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRoomScreen(
          propertyId: widget.property.id,
          room: room,
        ),
      ),
    );
    if (result == true) {
      await _loadRooms();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Propiedad'),
        content: const Text(
          '¿Estás seguro de eliminar esta propiedad y todos sus espacios?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _inventoryService.deleteProperty(widget.property.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
