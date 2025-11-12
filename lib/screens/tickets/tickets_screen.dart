import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import 'add_edit_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String _filterStatus = 'todos';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _ticketService.getAllTickets();
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  List<TicketModel> get _filteredTickets {
    if (_filterStatus == 'todos') return _tickets;
    return _tickets.where((t) => t.estado.value == _filterStatus).toList();
  }

  Color _getStatusColor(TicketStatus status) {
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

  IconData _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.plomeria:
        return Icons.plumbing;
      case ServiceType.electricidad:
        return Icons.electrical_services;
      case ServiceType.pintura:
        return Icons.format_paint;
      case ServiceType.carpinteria:
        return Icons.carpenter;
      case ServiceType.albanileria:
        return Icons.construction;
      case ServiceType.climatizacion:
        return Icons.ac_unit;
      case ServiceType.limpieza:
        return Icons.cleaning_services;
      case ServiceType.jardineria:
        return Icons.grass;
      case ServiceType.cerrajeria:
        return Icons.lock;
      case ServiceType.electrodomesticos:
        return Icons.kitchen;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tickets de Trabajo'),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos', _tickets.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Nuevo', 'nuevo', 
                    _tickets.where((t) => t.estado == TicketStatus.nuevo).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendiente', 'pendiente',
                    _tickets.where((t) => t.estado == TicketStatus.pendiente).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('En Progreso', 'en_progreso',
                    _tickets.where((t) => t.estado == TicketStatus.enProgreso).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completado', 'completado',
                    _tickets.where((t) => t.estado == TicketStatus.completado).length),
                ],
              ),
            ),
          ),

          // Lista de tickets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                : _filteredTickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment, size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay tickets',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primer ticket de trabajo',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        color: const Color(0xFFFFD700),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _filteredTickets[index];
                            return _buildTicketCard(ticket);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTicketScreen()),
          );
          _loadTickets();
        },
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF2C2C2C),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Ticket'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: const Color(0xFF2C2C2C),
      selectedColor: const Color(0xFFFFD700),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2C2C2C) : const Color(0xFFFFD700),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
          _loadTickets();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado y prioridad
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.estado).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.estado.displayName,
                      style: TextStyle(
                        color: _getStatusColor(ticket.estado),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ticket.prioridad == TicketPriority.alta || 
                      ticket.prioridad == TicketPriority.urgente)
                    Icon(
                      Icons.priority_high,
                      color: ticket.prioridad == TicketPriority.urgente 
                          ? Colors.red 
                          : Colors.orange,
                      size: 20,
                    ),
                  const Spacer(),
                  Icon(
                    _getServiceIcon(ticket.tipoServicio),
                    color: const Color(0xFFFFD700),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                ticket.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Descripción
              Text(
                ticket.descripcion,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Información adicional
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.clienteNombre,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ticket.propiedadDireccion != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.propiedadDireccion!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Fecha
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado: ${_formatDate(ticket.fechaCreacion)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
