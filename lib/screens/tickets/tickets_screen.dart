import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ticket_model.dart';
import '../../models/user_model.dart';
import '../../models/maestro_profile_model.dart';
import '../../services/ticket_service.dart';
import '../../services/maestro_profile_service.dart';
import 'add_edit_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import '../../config/app_theme.dart';

class TicketsScreen extends StatefulWidget {
  final String? initialFilter; // Filtro inicial: 'todos', 'nuevo', 'completado', etc.
  
  const TicketsScreen({super.key, this.initialFilter});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _searchController = TextEditingController();
  List<TicketModel> _tickets = [];
  List<UserModel> _maestros = [];
  bool _isLoading = true;
  String _filterStatus = 'todos';
  String? _filterMaestro; // null = todos, id del maestro para filtrar
  String _searchQuery = '';
  String _sortBy = 'fecha_desc'; // fecha_desc, fecha_asc, prioridad, estado

  @override
  void initState() {
    super.initState();
    // Aplicar filtro inicial si se proporciona
    if (widget.initialFilter != null) {
      _filterStatus = widget.initialFilter!;
    }
    _loadTickets();
    _loadMaestros();
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

  Future<void> _loadMaestros() async {
    try {
      List<UserModel> maestros = [];
      
      // 1. Cargar perfiles de maestros predefinidos (Rodrigo y Alexander)
      try {
        final maestroProfileService = MaestroProfileService();
        final profiles = await maestroProfileService.getActiveMaestroProfiles()
            .timeout(const Duration(seconds: 3))
            .first;
        
        // Convertir perfiles a UserModel
        for (var profile in profiles) {
          maestros.add(UserModel(
            uid: profile.id,
            nombre: profile.nombre,
            email: profile.email ?? '${profile.id}@sutodero.com',
            rol: 'maestro',
            telefono: profile.telefono,
            fechaCreacion: profile.fechaCreacion,
            activo: profile.activo,
          ));
        }
      } catch (e) {
        // Fallback: perfiles en memoria
        maestros.addAll([
          UserModel(
            uid: 'rodrigo',
            nombre: 'Rodrigo',
            email: 'rodrigo@sutodero.com',
            rol: 'maestro',
            telefono: '3001234567',
            fechaCreacion: DateTime.now(),
            activo: true,
          ),
          UserModel(
            uid: 'alexander',
            nombre: 'Alexander',
            email: 'alexander@sutodero.com',
            rol: 'maestro',
            telefono: '3007654321',
            fechaCreacion: DateTime.now(),
            activo: true,
          ),
        ]);
      }
      
      // 2. Cargar usuarios adicionales con rol de maestro
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('rol', isEqualTo: 'maestro')
            .get()
            .timeout(const Duration(seconds: 3));
        
        final userMaestros = querySnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList();
        
        // Agregar solo si no están duplicados
        for (var userMaestro in userMaestros) {
          if (!maestros.any((m) => m.uid == userMaestro.uid)) {
            maestros.add(userMaestro);
          }
        }
      } catch (e) {
        // Continuar con perfiles predefinidos
      }
      
      // Filtrar solo maestros que tienen tareas asignadas
      final maestrosConTareas = <UserModel>[];
      for (final maestro in maestros) {
        final tieneTickets = _tickets.any((ticket) => ticket.toderoId == maestro.uid);
        if (tieneTickets) {
          maestrosConTareas.add(maestro);
        }
      }
      
      if (mounted) {
        setState(() {
          _maestros = maestrosConTareas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar maestros: $e')),
        );
      }
    }
  }

  List<TicketModel> get _filteredTickets {
    var filtered = _tickets;

    // Filtro por estado
    if (_filterStatus != 'todos') {
      filtered = filtered.where((t) => t.estado.value == _filterStatus).toList();
    }

    // Filtro por maestro
    if (_filterMaestro != null) {
      filtered = filtered.where((t) => t.toderoId == _filterMaestro).toList();
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
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFAB334)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFFFAB334)),
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

          // Ordenamiento con menú desplegable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Color(0xFFFAB334), size: 20),
                SizedBox(width: AppTheme.spacingSM),
                const Text(
                  'Ordenar:',
                  style: TextStyle(color: Color(0xFFFAB334), fontWeight: FontWeight.bold),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: PopupMenuButton<String>(
                    initialValue: _sortBy,
                    onSelected: (value) {
                      setState(() => _sortBy = value);
                    },
                    color: AppTheme.grisOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      side: BorderSide(color: AppTheme.dorado, width: 1),
                    ),
                    offset: const Offset(0, 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.grisOscuro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.dorado, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSortIcon(_sortBy),
                            size: 16,
                            color: AppTheme.dorado,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getSortLabel(_sortBy),
                              style: const TextStyle(
                                color: AppTheme.dorado,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.dorado,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildPopupMenuItem(
                        'Más reciente',
                        'fecha_desc',
                        Icons.arrow_downward,
                      ),
                      _buildPopupMenuItem(
                        'Más antiguo',
                        'fecha_asc',
                        Icons.arrow_upward,
                      ),
                      _buildPopupMenuItem(
                        'Prioridad',
                        'prioridad',
                        Icons.priority_high,
                      ),
                      _buildPopupMenuItem(
                        'Estado',
                        'estado',
                        Icons.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

          // Filtros por estado con menú desplegable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Color(0xFFFAB334), size: 20),
                SizedBox(width: AppTheme.spacingSM),
                const Text(
                  'Ver:',
                  style: TextStyle(color: Color(0xFFFAB334), fontWeight: FontWeight.bold),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: PopupMenuButton<String>(
                    initialValue: _filterStatus,
                    onSelected: (value) {
                      setState(() => _filterStatus = value);
                    },
                    color: AppTheme.grisOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      side: BorderSide(color: AppTheme.dorado, width: 1),
                    ),
                    offset: const Offset(0, 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.grisOscuro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.dorado, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              _getFilterLabel(_filterStatus),
                              style: const TextStyle(
                                color: AppTheme.dorado,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.dorado,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildFilterMenuItem(
                        'Todos',
                        'todos',
                        _tickets.length,
                      ),
                      _buildFilterMenuItem(
                        'Nuevo',
                        'nuevo',
                        _tickets.where((t) => t.estado == TicketStatus.nuevo).length,
                      ),
                      _buildFilterMenuItem(
                        'Pendiente',
                        'pendiente',
                        _tickets.where((t) => t.estado == TicketStatus.pendiente).length,
                      ),
                      _buildFilterMenuItem(
                        'En Progreso',
                        'en_progreso',
                        _tickets.where((t) => t.estado == TicketStatus.enProgreso).length,
                      ),
                      _buildFilterMenuItem(
                        'Completado',
                        'completado',
                        _tickets.where((t) => t.estado == TicketStatus.completado).length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

          // Filtro por Maestro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFFFAB334), size: 20),
                SizedBox(width: AppTheme.spacingSM),
                const Text(
                  'Maestro:',
                  style: TextStyle(color: Color(0xFFFAB334), fontWeight: FontWeight.bold),
                ),
                SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: PopupMenuButton<String?>(
                    initialValue: _filterMaestro,
                    onSelected: (value) {
                      setState(() => _filterMaestro = value);
                    },
                    color: AppTheme.grisOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      side: BorderSide(color: AppTheme.dorado, width: 1),
                    ),
                    offset: const Offset(0, 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.grisOscuro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(color: AppTheme.dorado, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              _getMaestroFilterLabel(),
                              style: const TextStyle(
                                color: AppTheme.dorado,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.dorado,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildMaestroMenuItem(
                        'Todos los Maestros',
                        null,
                        _tickets.length,
                      ),
                      ..._maestros.map((maestro) {
                        final count = _tickets
                            .where((t) => t.toderoId == maestro.uid)
                            .length;
                        return _buildMaestroMenuItem(
                          maestro.nombre,
                          maestro.uid,
                          count,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

          // Lista de tickets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFAB334)))
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

  String _getFilterLabel(String filterStatus) {
    final count = _getFilterCount(filterStatus);
    switch (filterStatus) {
      case 'todos':
        return 'Todos ($count)';
      case 'nuevo':
        return 'Nuevo ($count)';
      case 'pendiente':
        return 'Pendiente ($count)';
      case 'en_progreso':
        return 'En Progreso ($count)';
      case 'completado':
        return 'Completado ($count)';
      default:
        return 'Todos ($count)';
    }
  }

  int _getFilterCount(String filterStatus) {
    switch (filterStatus) {
      case 'todos':
        return _tickets.length;
      case 'nuevo':
        return _tickets.where((t) => t.estado == TicketStatus.nuevo).length;
      case 'pendiente':
        return _tickets.where((t) => t.estado == TicketStatus.pendiente).length;
      case 'en_progreso':
        return _tickets.where((t) => t.estado == TicketStatus.enProgreso).length;
      case 'completado':
        return _tickets.where((t) => t.estado == TicketStatus.completado).length;
      default:
        return _tickets.length;
    }
  }

  PopupMenuItem<String> _buildFilterMenuItem(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? AppTheme.dorado : AppTheme.blanco,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(
              Icons.check,
              color: AppTheme.dorado,
              size: 18,
            ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'fecha_desc':
        return 'Más reciente';
      case 'fecha_asc':
        return 'Más antiguo';
      case 'prioridad':
        return 'Prioridad';
      case 'estado':
        return 'Estado';
      default:
        return 'Más reciente';
    }
  }

  IconData _getSortIcon(String sortBy) {
    switch (sortBy) {
      case 'fecha_desc':
        return Icons.arrow_downward;
      case 'fecha_asc':
        return Icons.arrow_upward;
      case 'prioridad':
        return Icons.priority_high;
      case 'estado':
        return Icons.label;
      default:
        return Icons.arrow_downward;
    }
  }

  PopupMenuItem<String> _buildPopupMenuItem(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppTheme.dorado : AppTheme.blanco,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.dorado : AppTheme.blanco,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(
              Icons.check,
              color: AppTheme.dorado,
              size: 18,
            ),
        ],
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
              
              // Maestro asignado (si existe)
              if (ticket.toderoNombre != null && ticket.toderoNombre!.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingSM),
                Row(
                  children: [
                    Icon(Icons.engineering, size: 16, color: AppTheme.dorado),
                    const SizedBox(width: 4),
                    Text(
                      'Maestro: ',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ticket.toderoNombre!,
                        style: TextStyle(
                          color: AppTheme.dorado,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
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

  String _getMaestroFilterLabel() {
    if (_filterMaestro == null) {
      return 'Todos los Maestros';
    }
    final maestro = _maestros.firstWhere(
      (m) => m.uid == _filterMaestro,
      orElse: () => UserModel(
        uid: '',
        nombre: 'Desconocido',
        email: '',
        rol: 'maestro',
        telefono: '',
        fechaCreacion: DateTime.now(),
      ),
    );
    final count = _tickets.where((t) => t.toderoId == _filterMaestro).length;
    return '${maestro.nombre} ($count)';
  }

  PopupMenuItem<String?> _buildMaestroMenuItem(String label, String? value, int count) {
    final isSelected = _filterMaestro == value;
    return PopupMenuItem<String?>(
      value: value,
      child: Row(
        children: [
          Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? AppTheme.dorado : AppTheme.blanco,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(
              Icons.check,
              color: AppTheme.dorado,
              size: 18,
            ),
        ],
      ),
    );
  }
}
