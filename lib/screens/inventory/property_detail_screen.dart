import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/inventory_property.dart';
import '../../models/property_room.dart';
import '../../models/ticket_model.dart';
import '../../services/inventory_service.dart';
import '../../services/floor_plan_service.dart';
import '../../services/inventory_pdf_service.dart';
import '../../services/qr_service.dart';
import '../../services/ticket_service.dart';
import 'add_edit_property_screen.dart';
import 'add_edit_room_screen.dart';
import 'room_detail_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final InventoryProperty property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  final FloorPlanService _floorPlanService = FloorPlanService();
  final InventoryPdfService _pdfService = InventoryPdfService();
  final QRService _qrService = QRService();
  final TicketService _ticketService = TicketService();
  List<PropertyRoom> _rooms = [];
  List<TicketModel> _relatedTickets = [];
  bool _isLoading = true;
  bool _isGeneratingPropertyPlan = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _inventoryService.getRoomsByProperty(widget.property.id);
      // Cargar tickets relacionados
      final tickets = await _loadRelatedTickets();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _relatedTickets = tickets;
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

  Future<List<TicketModel>> _loadRelatedTickets() async {
    try {
      final allTickets = await _ticketService.getAllTickets();
      return allTickets.where((ticket) {
        return ticket.propiedadId == widget.property.id;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading related tickets: $e');
      }
      return [];
    }
  }

  Future<void> _exportToPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
      
      final pdfBytes = await _pdfService.generatePropertyPdf(widget.property, _rooms);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      await _pdfService.sharePdf(
        pdfBytes,
        'propiedad_${widget.property.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showQRCode() async {
    final qrData = _qrService.generatePropertyQR(
      widget.property.id,
      direccion: widget.property.direccion,
    );
    
    await _qrService.showQRDialog(
      context,
      data: qrData,
      title: 'QR de Propiedad',
      subtitle: widget.property.direccion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Propiedad'),
        actions: [
          // Botón PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Exportar PDF',
          ),
          // Botón QR
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showQRCode,
            tooltip: 'Código QR',
          ),
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
            if (_relatedTickets.isNotEmpty) _buildRelatedTicketsSection(),
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
          
          // Botón generar plano completo
          if (_rooms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPropertyPlan ? null : _generatePropertyFloorPlan,
                icon: _isGeneratingPropertyPlan
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.maps_home_work),
                label: Text(_isGeneratingPropertyPlan
                    ? 'Generando Plano Completo...'
                    : 'Generar Plano Completo de la Propiedad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF2C2C2C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          
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
        builder: (context) => RoomDetailScreen(room: room),
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

  Future<void> _generatePropertyFloorPlan() async {
    // Verificar que haya espacios
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Necesitas agregar al menos un espacio a la propiedad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar que al menos un espacio tenga fotos
    final roomsWithPhotos = _rooms.where((room) => room.fotos.isNotEmpty).toList();
    if (roomsWithPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Necesitas tomar fotos de al menos un espacio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPropertyPlan = true);
    try {
      final floorPlan = await _floorPlanService.generatePropertyFloorPlan(widget.property.id);
      
      if (mounted) {
        setState(() => _isGeneratingPropertyPlan = false);
        
        if (floorPlan != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Plano completo generado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Calcular estadísticas
          double totalArea = 0;
          int totalPhotos = 0;
          int rooms360 = 0;
          
          for (final room in _rooms) {
            if (room.area != null) totalArea += room.area!;
            totalPhotos += room.fotos.length;
            if (room.tiene360) rooms360++;
          }

          // Mostrar mensaje de función en desarrollo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.maps_home_work, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Plano Completo'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análisis de la propiedad:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('🏠 Total espacios: ${_rooms.length}'),
                  Text('📐 Área total: ${totalArea.toStringAsFixed(2)} m²'),
                  Text('📷 Total fotos: $totalPhotos'),
                  Text('🔄 Fotos 360°: $rooms360'),
                  const SizedBox(height: 8),
                  const Text(
                    'Espacios incluidos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._rooms.map((room) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '${room.tipo.icon} ${room.nombre} (${room.fotos.length} fotos)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
                  const SizedBox(height: 16),
                  const Text(
                    'La generación automática del plano completo con IA estará disponible en una próxima actualización.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPropertyPlan = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildRelatedTicketsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Color(0xFFFF6B00), size: 24),
              const SizedBox(width: 8),
              Text(
                'Tickets Relacionados (${_relatedTickets.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._relatedTickets.take(5).map((ticket) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6C8).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getTicketStatusColor(ticket.estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ticket.espacioNombre != null)
                          Text(
                            '📍 ${ticket.espacioNombre}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTicketStatusColor(ticket.estado).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.estado.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTicketStatusColor(ticket.estado),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_relatedTickets.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${_relatedTickets.length - 5} tickets más',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTicketStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.nuevo:
        return const Color(0xFFFFD700);
      case TicketStatus.pendiente:
        return const Color(0xFFFF9800);
      case TicketStatus.enProgreso:
        return const Color(0xFF2196F3);
      case TicketStatus.completado:
        return const Color(0xFF4CAF50);
      case TicketStatus.cancelado:
        return const Color(0xFF757575);
    }
  }
}
