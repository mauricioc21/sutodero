import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import 'add_edit_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import '../../config/app_theme.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _searchController = TextEditingController();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String _filterStatus = 'todos';
  String _searchQuery = '';
  String _sortBy = 'fecha_desc'; // fecha_desc, fecha_asc, prioridad, estado

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    var filtered = _tickets;

    // Filtro por estado
    if (_filterStatus != 'todos') {
      filtered = filtered.where((t) => t.estado.value == _filterStatus).toList();
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.titulo.toLowerCase().contains(_searchQuery) ||
            t.descripcion.toLowerCase().contains(_searchQuery) ||
            t.clienteNombre.toLowerCase().contains(_searchQuery) ||
            (t.propiedadDireccion?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Ordenamiento
    switch (_sortBy) {
      case 'fecha_asc':
        filtered.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        break;
      case 'fecha_desc':
        filtered.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        break;
      case 'prioridad':
        filtered.sort((a, b) {
          final priorityOrder = {
            TicketPriority.urgente: 0,
            TicketPriority.alta: 1,
            TicketPriority.media: 2,
            TicketPriority.baja: 3,
          };
          return priorityOrder[a.prioridad]!.compareTo(priorityOrder[b.prioridad]!);
        });
        break;
      case 'estado':
        filtered.sort((a, b) => a.estado.value.compareTo(b.estado.value));
        break;
    }

    return filtered;
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.nuevo:
        return AppTheme.dorado;
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
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Tickets de Trabajo'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.blanco),
              decoration: InputDecoration(
                hintText: 'Buscar tickets...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFFFFD700)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.grisOscuro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Ordenamiento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Color(0xFFFFD700), size: 20),
                SizedBox(width: AppTheme.spacingSM),
                const Text(
                  'Ordenar:',
                  style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Más reciente', 'fecha_desc', Icons.arrow_downward),
                        SizedBox(width: AppTheme.spacingSM),
                        _buildSortChip('Más antiguo', 'fecha_asc', Icons.arrow_upward),
                        SizedBox(width: AppTheme.spacingSM),
                        _buildSortChip('Prioridad', 'prioridad', Icons.priority_high),
                        SizedBox(width: AppTheme.spacingSM),
                        _buildSortChip('Estado', 'estado', Icons.label),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

          // Filtros por estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos', _tickets.length),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildFilterChip('Nuevo', 'nuevo', 
                    _tickets.where((t) => t.estado == TicketStatus.nuevo).length),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildFilterChip('Pendiente', 'pendiente',
                    _tickets.where((t) => t.estado == TicketStatus.pendiente).length),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildFilterChip('En Progreso', 'en_progreso',
                    _tickets.where((t) => t.estado == TicketStatus.enProgreso).length),
                  SizedBox(width: AppTheme.spacingSM),
                  _buildFilterChip('Completado', 'completado',
                    _tickets.where((t) => t.estado == TicketStatus.completado).length),
                ],
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

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
                            SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'No hay tickets',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: AppTheme.spacingSM),
                            Text(
                              'Crea tu primer ticket de trabajo',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        color: AppTheme.dorado,
                        child: ListView.builder(
                          padding: EdgeInsets.all(AppTheme.paddingMD),
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
        backgroundColor: AppTheme.dorado,
        foregroundColor: AppTheme.grisOscuro,
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
      backgroundColor: AppTheme.grisOscuro,
      selectedColor: AppTheme.dorado,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.grisOscuro : AppTheme.dorado,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? AppTheme.grisOscuro : AppTheme.dorado),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _sortBy = value);
      },
      backgroundColor: AppTheme.grisOscuro,
      selectedColor: AppTheme.dorado,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.grisOscuro : AppTheme.dorado,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return Card(
      color: AppTheme.grisOscuro,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingMD),
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
                  SizedBox(width: AppTheme.spacingSM),
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
                    color: AppTheme.dorado,
                    size: 24,
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMD),

              // Título
              Text(
                ticket.titulo,
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppTheme.spacingSM),

              // Descripción
              Text(
                ticket.descripcion,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppTheme.spacingMD),

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
                    SizedBox(width: AppTheme.spacingMD),
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
              SizedBox(height: AppTheme.spacingSM),

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
