import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';
import '../../models/ticket_model.dart';
import '../../services/auth_service.dart';
import 'ticket_detail_screen.dart';
import '../maestro/maestro_work_order_screen.dart'; // Nueva pantalla

class MyAssignedTicketsScreen extends StatelessWidget {
  const MyAssignedTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Órdenes de Trabajo'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppTheme.dorado,
            labelColor: AppTheme.dorado,
            unselectedLabelColor: AppTheme.grisClaro,
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Finalizados'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tickets')
              .where(
                Filter.or(
                  Filter('tecnicoId', isEqualTo: user.uid),
                  Filter('toderoId', isEqualTo: user.uid),
                ),
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.dorado),
              );
            }

            final allTickets =
                snapshot.data!.docs
                    .map(
                      (doc) => TicketModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        b.fechaActualizacion.compareTo(a.fechaActualizacion),
                  );

            // Filtrar tickets Activos (Incluye nuevos estados de Maestro)
            final activeTickets = allTickets
                .where(
                  (t) =>
                      t.estado == TicketStatus.asignado ||
                      t.estado == TicketStatus.en_camino ||
                      t.estado == TicketStatus.en_lugar ||
                      t.estado == TicketStatus.en_ejecucion ||
                      t.estado == TicketStatus.pendiente_repuestos,
                )
                .toList();

            // Filtrar tickets Finalizados
            final finishedTickets = allTickets
                .where(
                  (t) =>
                      t.estado == TicketStatus.finalizado ||
                      t.estado == TicketStatus.cancelado,
                )
                .toList();

            return TabBarView(
              children: [
                _buildTicketList(
                  context,
                  activeTickets,
                  'No tienes órdenes activas',
                ),
                _buildTicketList(
                  context,
                  finishedTickets,
                  'No tienes órdenes finalizadas',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketList(
    BuildContext context,
    List<TicketModel> tickets,
    String emptyMessage,
  ) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppTheme.grisClaro.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, color: AppTheme.blanco),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
      child: ListView.builder(
        padding: AppTheme.paddingAll,
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          return _buildTicketCard(context, tickets[index]);
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    Color statusColor;
    switch (ticket.estado) {
      case TicketStatus.asignado:
      case TicketStatus.nuevo:
        statusColor = Colors.blue;
        break;
      case TicketStatus.en_camino:
        statusColor = Colors.orange;
        break;
      case TicketStatus.en_lugar:
        statusColor = Colors.purple;
        break;
      case TicketStatus.en_ejecucion:
        statusColor = Colors.green;
        break;
      case TicketStatus.pendiente_repuestos:
      case TicketStatus.pendiente:
        statusColor = Colors.amber;
        break;
      case TicketStatus.finalizado:
        statusColor = Colors.grey;
        break;
      case TicketStatus.cancelado:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E), // Dark card background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navegar a la pantalla especializada de Maestro
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaestroWorkOrderScreen(ticketId: ticket.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      ticket.estado.displayName.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(ticket.fechaProgramada ?? ticket.fechaCreacion),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.grey),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.dorado,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.ubicacionDireccion.isNotEmpty
                          ? ticket.ubicacionDireccion
                          : 'Sin dirección',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
