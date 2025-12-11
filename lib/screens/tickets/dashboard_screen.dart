import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import 'ticket_detail_screen.dart';
import 'tickets_screen.dart';
import '../../config/app_theme.dart';
import '../empleados/empleados_por_rol_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TicketService _ticketService = TicketService();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  Map<String, int> _estadisticas = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final tickets = await _ticketService.getAllTickets();
    final stats = await _ticketService.getTicketStatistics();
    
    setState(() {
      _tickets = tickets;
      _estadisticas = stats;
      _isLoading = false;
    });
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.nuevo:
        return AppTheme.dorado;
      case TicketStatus.pendiente:
        return const Color(0xFFFF9800);
      case TicketStatus.asignado:
      case TicketStatus.en_camino:
      case TicketStatus.en_lugar:
        return const Color(0xFF2196F3);
      case TicketStatus.en_ejecucion:
      case TicketStatus.pendiente_repuestos:
        return const Color(0xFF2196F3);
      case TicketStatus.finalizado:
        return const Color(0xFF4CAF50);
      case TicketStatus.cancelado:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Dashboard de Tickets'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFAB334)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.dorado,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppTheme.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen general
                    _buildResumenGeneral(),
                    SizedBox(height: AppTheme.spacingXL),

                    // Gráfico circular de estados
                    _buildEstadosChart(),
                    SizedBox(height: AppTheme.spacingXL),

                    // Gráfico de barras de servicios
                    _buildServiciosChart(),
                    SizedBox(height: AppTheme.spacingXL),

                    // Tickets urgentes
                    _buildTicketsUrgentes(),
                    SizedBox(height: AppTheme.spacingXL),

                    // Actividad reciente
                    _buildActividadReciente(),
                    SizedBox(height: AppTheme.spacingXL),

                    // Roles Su Todero (al final)
                    _buildRolesSuTodero(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumenGeneral() {
    final total = _tickets.length;
    final nuevo = _estadisticas['nuevo'] ?? 0;
    final pendiente = _estadisticas['pendiente'] ?? 0;
    final enProgreso = _estadisticas['en_progreso'] ?? 0;
    final completado = _estadisticas['completado'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(
            color: Color(0xFFFAB334),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                value: total.toString(),
                icon: Icons.assignment,
                color: AppTheme.dorado,
                onTap: () {
                  // Navegar a tickets sin filtro (todos)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketsScreen(initialFilter: 'todos'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: _buildStatCard(
                title: 'En Proceso',
                value: enProgreso.toString(),
                icon: Icons.autorenew,
                color: const Color(0xFF2196F3),
                onTap: () {
                  // Navegar a tickets en progreso
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketsScreen(initialFilter: 'en_progreso'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingMD),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Completados',
                value: completado.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  // Navegar a tickets completados
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketsScreen(initialFilter: 'completado'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: _buildStatCard(
                title: 'Nuevos',
                value: nuevo.toString(),
                icon: Icons.fiber_new,
                color: AppTheme.dorado,
                onTap: () {
                  // Navegar a tickets nuevos
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketsScreen(initialFilter: 'nuevo'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          decoration: BoxDecoration(
            color: AppTheme.grisOscuro,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSM),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadosChart() {
    if (_tickets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución por Estado',
            style: TextStyle(
              color: Color(0xFFFAB334),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _getPieChartSections(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacingMD),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    final nuevo = _estadisticas['nuevo'] ?? 0;
    final pendiente = _estadisticas['pendiente'] ?? 0;
    final enProgreso = _estadisticas['en_progreso'] ?? 0;
    final completado = _estadisticas['completado'] ?? 0;
    final cancelado = _estadisticas['cancelado'] ?? 0;

    final total = nuevo + pendiente + enProgreso + completado + cancelado;
    if (total == 0) return [];

    return [
      if (nuevo > 0)
        PieChartSectionData(
          value: nuevo.toDouble(),
          title: '$nuevo',
          color: AppTheme.dorado,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
      if (pendiente > 0)
        PieChartSectionData(
          value: pendiente.toDouble(),
          title: '$pendiente',
          color: const Color(0xFFFF9800),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.blanco,
          ),
        ),
      if (enProgreso > 0)
        PieChartSectionData(
          value: enProgreso.toDouble(),
          title: '$enProgreso',
          color: const Color(0xFF2196F3),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.blanco,
          ),
        ),
      if (completado > 0)
        PieChartSectionData(
          value: completado.toDouble(),
          title: '$completado',
          color: const Color(0xFF4CAF50),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.blanco,
          ),
        ),
      if (cancelado > 0)
        PieChartSectionData(
          value: cancelado.toDouble(),
          title: '$cancelado',
          color: const Color(0xFF757575),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.blanco,
          ),
        ),
    ];
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem('Nuevo', AppTheme.dorado),
        _buildLegendItem('Pendiente', const Color(0xFFFF9800)),
        _buildLegendItem('En Progreso', const Color(0xFF2196F3)),
        _buildLegendItem('Completado', const Color(0xFF4CAF50)),
        _buildLegendItem('Cancelado', const Color(0xFF757575)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildServiciosChart() {
    if (_tickets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Contar tickets por tipo de servicio
    final Map<ServiceType, int> servicioCount = {};
    for (final ticket in _tickets) {
      servicioCount[ticket.tipoServicio] = (servicioCount[ticket.tipoServicio] ?? 0) + 1;
    }

    // Ordenar por cantidad
    final sortedServicios = servicioCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tickets por Tipo de Servicio',
            style: TextStyle(
              color: Color(0xFFFAB334),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (sortedServicios.isNotEmpty ? sortedServicios.first.value.toDouble() : 10) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedServicios.length) {
                          return const Text('');
                        }
                        final servicio = sortedServicios[value.toInt()].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getServiceIcon(servicio),
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: sortedServicios.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: AppTheme.dorado,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.plomeria:
        return '🚰';
      case ServiceType.electricidad:
        return '⚡';
      case ServiceType.pintura:
        return '🎨';
      case ServiceType.carpinteria:
        return '🪚';
      case ServiceType.albanileria:
        return '🧱';
      case ServiceType.climatizacion:
        return '❄️';
      case ServiceType.limpieza:
        return '🧹';
      case ServiceType.jardineria:
        return '🌿';
      case ServiceType.cerrajeria:
        return '🔐';
      case ServiceType.electrodomesticos:
        return '🔌';
      default:
        return '🔧';
    }
  }

  Widget _buildTicketsUrgentes() {
    final urgentes = _tickets.where((t) => t.prioridad == TicketPriority.urgente).toList();

    if (urgentes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: AppTheme.spacingSM),
            const Text(
              'Tickets Urgentes',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: AppTheme.spacingSM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Text(
                '${urgentes.length}',
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingMD),
        ...urgentes.take(3).map((ticket) => _buildTicketCard(ticket)),
      ],
    );
  }

  Widget _buildActividadReciente() {
    final recientes = _tickets.take(5).toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            color: Color(0xFFFAB334),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingMD),
        ...recientes.map((ticket) => _buildTicketCard(ticket)),
      ],
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return Card(
      color: AppTheme.grisOscuro,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.estado),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.titulo,
                      style: const TextStyle(
                        color: AppTheme.blanco,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.tipoServicio.displayName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.estado).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  ticket.estado.displayName,
                  style: TextStyle(
                    color: _getStatusColor(ticket.estado),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de Roles Su Todero
  Widget _buildRolesSuTodero() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isCoordinadorOnly = (user?.isCoordinador ?? false) && !(user?.isAdministrador ?? false);

    var roles = [
      {
        'nombre': 'Administrador',
        'cargo': 'administrador',
        'icon': Icons.admin_panel_settings,
        'color': const Color(0xFF9C27B0),
      },
      {
        'nombre': 'Coordinador',
        'cargo': 'coordinador',
        'icon': Icons.manage_accounts,
        'color': const Color(0xFF2196F3),
      },
      {
        'nombre': 'Maestro',
        'cargo': 'maestro',
        'icon': Icons.engineering,
        'color': AppTheme.dorado,
      },
      {
        'nombre': 'Inventarios',
        'cargo': 'inventarios',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF4CAF50),
      },
    ];

    // Si es coordinador (y no admin), filtrar roles
    if (isCoordinadorOnly) {
      roles = roles.where((r) => r['cargo'] == 'coordinador' || r['cargo'] == 'maestro').toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Roles Su Todero',
          style: TextStyle(
            color: AppTheme.dorado,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingMD),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final rol = roles[index];
            return _buildRolCard(
              nombre: rol['nombre'] as String,
              cargo: rol['cargo'] as String,
              icon: rol['icon'] as IconData,
              color: rol['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRolCard({
    required String nombre,
    required String cargo,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmpleadosPorRolScreen(
                cargo: cargo,
                nombreCargo: nombre,
                colorCargo: color,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.grisOscuro,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(AppTheme.paddingMD),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              SizedBox(height: AppTheme.spacingSM),
              Text(
                nombre,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
