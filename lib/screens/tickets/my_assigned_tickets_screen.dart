import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_theme.dart';
import '../../models/ticket_model.dart';
import '../../services/auth_service.dart';
import 'ticket_detail_screen.dart';

class MyAssignedTicketsScreen extends StatelessWidget {
  const MyAssignedTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tickets Asignados'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text('Usuario no autenticado'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tickets')
                  .where('toderoId', isEqualTo: user.uid)
                  .orderBy('fechaActualizacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar tickets',
                          style: TextStyle(color: AppTheme.blanco),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: AppTheme.grisClaro,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                    ),
                  );
                }

                final tickets = snapshot.data!.docs
                    .map((doc) => TicketModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ))
                    .toList();

                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: AppTheme.grisClaro.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes tickets asignados',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.blanco,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los tickets que te asignen aparecerán aquí',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grisClaro,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientBackground,
                  ),
                  child: ListView.builder(
                    padding: AppTheme.paddingAll,
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(context, ticket);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    Color statusColor;
    IconData statusIcon;

    switch (ticket.estado) {
      case TicketStatus.nuevo:
        statusColor = Colors.blue;
        statusIcon = Icons.new_releases;
        break;
      case TicketStatus.pendiente:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case TicketStatus.enProgreso:
        statusColor = Colors.amber;
        statusIcon = Icons.construction;
        break;
      case TicketStatus.completado:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TicketStatus.cancelado:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    Color priorityColor;
    switch (ticket.prioridad) {
      case TicketPriority.baja:
        priorityColor = Colors.green;
        break;
      case TicketPriority.media:
        priorityColor = Colors.blue;
        break;
      case TicketPriority.alta:
        priorityColor = Colors.orange;
        break;
      case TicketPriority.urgente:
        priorityColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: AppTheme.containerDecoration(
        withBorder: false,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticket.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Estado y Prioridad
                Row(
                  children: [
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            ticket.estado.displayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Prioridad
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 14, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            ticket.prioridad.displayName,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Tipo de servicio
                    Icon(
                      Icons.build_circle,
                      size: 20,
                      color: AppTheme.dorado,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Título
                Text(
                  ticket.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blanco,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Descripción
                Text(
                  ticket.descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grisClaro,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Info adicional
                Row(
                  children: [
                    // Cliente
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.grisClaro,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket.clienteNombre,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grisClaro,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tipo de servicio
                    Text(
                      ticket.tipoServicio.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.dorado,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                if (ticket.fechaProgramada != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppTheme.grisClaro,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Programado: ${_formatDate(ticket.fechaProgramada!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grisClaro,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ticketDate = DateTime(date.year, date.month, date.day);
    
    if (ticketDate == today) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (ticketDate == today.add(const Duration(days: 1))) {
      return 'Mañana ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
