import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/inventory_property.dart';
import '../../models/property_room.dart';
import '../../models/ticket_model.dart';
import '../../models/inventory_act.dart';
import '../../services/inventory_service.dart';
import '../../services/floor_plan_service.dart';
import '../../services/floor_plan_3d_service.dart';
import '../../services/inventory_pdf_service.dart';
import '../../services/qr_service.dart';
import '../../services/ticket_service.dart';
import '../../services/inventory_act_service.dart';
import '../../services/inventory_act_pdf_service.dart';
import 'add_edit_property_screen.dart';
import 'add_edit_room_screen.dart';
import 'room_detail_screen.dart';
import 'sign_inventory_act_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final InventoryProperty property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  final FloorPlanService _floorPlanService = FloorPlanService();
  final FloorPlan3DService _floorPlan3DService = FloorPlan3DService();
  final InventoryPdfService _pdfService = InventoryPdfService();
  final QRService _qrService = QRService();
  final TicketService _ticketService = TicketService();
  final InventoryActService _actService = InventoryActService();
  final InventoryActPdfService _actPdfService = InventoryActPdfService();
  List<PropertyRoom> _rooms = [];
  List<TicketModel> _relatedTickets = [];
  List<InventoryAct> _acts = [];
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

  /// Genera plano 2D de la propiedad
  Future<void> _generateFloorPlan() async {
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega espacios primero para generar el plano'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFD700)),
                    SizedBox(height: 16),
                    Text('Generando plano 2D...'),
                    Text(
                      'Calculando layout automático',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Generar plano 2D
      final floorPlanService = FloorPlanService();
      final pdfBytes = await floorPlanService.generateFloorPlanPdf(
        property: widget.property,
        rooms: _rooms,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Guardar PDF
      if (kIsWeb) {
        // En web: descargar automáticamente
        // TODO: Implementar descarga web
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plano 2D generado (función web en desarrollo)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // En móvil: guardar y compartir
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Plano_2D_${widget.property.id.substring(0, 8)}.pdf');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Plano 2D guardado: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  // TODO: Abrir PDF
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar plano: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Genera plano 3D isométrico de la propiedad
  Future<void> _generate3DFloorPlan() async {
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Agrega espacios primero para generar el plano 3D'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFD700)),
                    SizedBox(height: 16),
                    Text('Generando plano 3D isométrico...'),
                    Text(
                      'Renderizando vista tridimensional',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Generar plano 3D
      final pdfBytes = await _floorPlan3DService.generate3DFloorPlan(
        property: widget.property,
        rooms: _rooms,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Guardar PDF
      if (kIsWeb) {
        // En web: descargar automáticamente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plano 3D generado (función web en desarrollo)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // En móvil: guardar y compartir
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Plano_3D_${widget.property.id.substring(0, 8)}.pdf');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Plano 3D isométrico guardado: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  // TODO: Abrir PDF
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar plano 3D: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Propiedad'),
        actions: [
          // Botón Acta de Inventario
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: _createInventoryAct,
            tooltip: 'Crear Acta de Inventario',
          ),
          // Botón PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Exportar PDF',
          ),
          // Botón Plano 2D
          IconButton(
            icon: const Icon(Icons.architecture),
            onPressed: _generateFloorPlan,
            tooltip: 'Generar Plano 2D',
          ),
          // Botón Plano 3D
          IconButton(
            icon: const Icon(Icons.view_in_ar),
            onPressed: _generate3DFloorPlan,
            tooltip: 'Generar Plano 3D Isométrico',
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
    // Redirigir al método correcto
    await _generateFloorPlan();
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

  /// Crea un Acta de Inventario
  Future<void> _createInventoryAct() async {
    // Mostrar diálogo para capturar información del cliente
    final actData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ActClientInfoDialog(property: widget.property),
    );

    if (actData == null) return;

    try {
      // Recopilar todas las fotos de la propiedad y sus espacios
      final allPhotos = <String>[
        ...widget.property.fotos,
        ..._rooms.expand((room) => room.fotos),
      ];

      // Crear acta inicial
      final act = await _actService.createAct(
        propertyId: widget.property.id,
        propertyAddress: widget.property.direccion,
        propertyType: widget.property.tipo.name,
        propertyDescription: widget.property.descripcion,
        clientName: actData['clientName']!,
        clientPhone: actData['clientPhone'],
        clientEmail: actData['clientEmail'],
        clientIdNumber: actData['clientIdNumber'],
        observations: actData['observations'],
        roomIds: _rooms.map((r) => r.id).toList(),
        photoUrls: allPhotos,
        createdBy: 'current_user', // TODO: Obtener del AuthService
        createdByName: actData['inspectorName'],
        createdByRole: actData['inspectorRole'],
      );

      if (!mounted) return;

      // Navegar a pantalla de firma y reconocimiento facial
      final completedAct = await Navigator.push<InventoryAct>(
        context,
        MaterialPageRoute(
          builder: (context) => SignInventoryActScreen(act: act),
        ),
      );

      if (completedAct != null && mounted) {
        // Generar y descargar PDF
        await _generateAndDownloadActPdf(completedAct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear acta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Genera PDF del acta y lo descarga
  Future<void> _generateAndDownloadActPdf(InventoryAct act) async {
    try {
      // Mostrar loading con más información
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFFD700)),
                    const SizedBox(height: 16),
                    const Text(
                      'Generando PDF del acta...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descargando ${act.photoUrls.length} fotos',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Esto puede tomar 10-30 segundos',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Generar PDF con timeout general de 2 minutos
      final pdfBytes = await _actPdfService.generateActPdf(
        act: act,
        rooms: _rooms,
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception(
            'La generación del PDF tardó demasiado. '
            'Intenta con menos fotos o verifica tu conexión.',
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Guardar PDF
      if (kIsWeb) {
        // En web: descargar automáticamente
        _downloadPdfWeb(pdfBytes, 'Acta_${act.validationCode}.pdf');
      } else {
        // En móvil: guardar y compartir
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Acta_${act.validationCode}.pdf');
        await file.writeAsBytes(pdfBytes);

        // Subir PDF a Firebase Storage
        final pdfUrl = await _actService.uploadPdf(act.id, file);
        await _actService.updatePdfUrl(act.id, pdfUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ PDF generado: Acta_${act.validationCode}.pdf'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Compartir',
                onPressed: () {
                  // Share PDF
                  // Share.shareXFiles([XFile(file.path)]);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Descarga PDF en web
  void _downloadPdfWeb(List<int> bytes, String filename) {
    // Esta función solo se ejecuta en web
    // El import condicional de dart:html lo permite
    if (kIsWeb) {
      // TODO: Implementar descarga web cuando se compile para web
      // final blob = html.Blob([bytes]);
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement(href: url)
      //   ..setAttribute('download', filename)
      //   ..click();
      // html.Url.revokeObjectUrl(url);
    }
  }
}

/// Diálogo para capturar información del cliente para el acta
class _ActClientInfoDialog extends StatefulWidget {
  final InventoryProperty property;

  const _ActClientInfoDialog({required this.property});

  @override
  State<_ActClientInfoDialog> createState() => _ActClientInfoDialogState();
}

class _ActClientInfoDialogState extends State<_ActClientInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _inspectorNameController = TextEditingController();
  final _inspectorRoleController = TextEditingController();
  final _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-llenar con datos de la propiedad si existen
    _clientNameController.text = widget.property.clienteNombre ?? '';
    _clientPhoneController.text = widget.property.clienteTelefono ?? '';
    _clientEmailController.text = widget.property.clienteEmail ?? '';
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientIdController.dispose();
    _inspectorNameController.dispose();
    _inspectorRoleController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Información del Acta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DATOS DEL CLIENTE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Número de Identificación',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const Text(
                'DATOS DEL INSPECTOR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inspectorNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Inspector',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inspectorRoleController,
                decoration: const InputDecoration(
                  labelText: 'Cargo/Rol',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'OBSERVACIONES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones generales',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'clientName': _clientNameController.text,
                'clientPhone': _clientPhoneController.text.isEmpty ? null : _clientPhoneController.text,
                'clientEmail': _clientEmailController.text.isEmpty ? null : _clientEmailController.text,
                'clientIdNumber': _clientIdController.text.isEmpty ? null : _clientIdController.text,
                'inspectorName': _inspectorNameController.text.isEmpty ? null : _inspectorNameController.text,
                'inspectorRole': _inspectorRoleController.text.isEmpty ? null : _inspectorRoleController.text,
                'observations': _observationsController.text.isEmpty ? null : _observationsController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
