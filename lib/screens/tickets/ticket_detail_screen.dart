import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  TicketModel? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    final ticket = await _ticketService.getTicket(widget.ticketId);
    setState(() {
      _ticket = ticket;
      _isLoading = false;
    });
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

  Future<void> _changeStatus(TicketStatus newStatus) async {
    final success = await _ticketService.updateTicketStatus(widget.ticketId, newStatus);
    if (success) {
      _loadTicket();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Estado actualizado a ${newStatus.displayName}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: const Color(0xFFFFD700),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: const Color(0xFFFFD700),
        ),
        body: const Center(
          child: Text(
            'Ticket no encontrado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Detalle del Ticket'),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          // Botón de chat con badge de mensajes no leídos
          Builder(
            builder: (context) {
              final authService = Provider.of<AuthService>(context, listen: false);
              final currentUser = authService.currentUser;
              
              return FutureBuilder<int>(
                future: currentUser != null
                    ? ChatService().getUnreadCount(
                        ticketId: _ticket!.id,
                        currentUserId: currentUser.uid,
                      )
                    : Future.value(0),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(ticket: _ticket!),
                        ),
                      ).then((_) => setState(() {})); // Refresh después del chat
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
                },
              );
            },
          ),
          PopupMenuButton<TicketStatus>(
            icon: const Icon(Icons.more_vert),
            onSelected: _changeStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TicketStatus.nuevo,
                child: Text('Marcar como Nuevo'),
              ),
              const PopupMenuItem(
                value: TicketStatus.pendiente,
                child: Text('Marcar como Pendiente'),
              ),
              const PopupMenuItem(
                value: TicketStatus.enProgreso,
                child: Text('Marcar En Progreso'),
              ),
              const PopupMenuItem(
                value: TicketStatus.completado,
                child: Text('Marcar como Completado'),
              ),
              const PopupMenuItem(
                value: TicketStatus.cancelado,
                child: Text('Cancelar Ticket'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(_ticket!.estado),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _ticket!.estado.displayName,
                  style: TextStyle(
                    color: _getStatusColor(_ticket!.estado),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _ticket!.prioridad.displayName,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            _ticket!.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Tipo de servicio
          Text(
            _ticket!.tipoServicio.displayName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Descripción
          _buildSection(
            'Descripción',
            Icons.description,
            _ticket!.descripcion,
          ),
          const SizedBox(height: 16),

          // Cliente
          _buildSection(
            'Cliente',
            Icons.person,
            _ticket!.clienteNombre,
            subtitle: _ticket!.clienteTelefono,
          ),
          const SizedBox(height: 16),

          // Propiedad (si existe)
          if (_ticket!.propiedadDireccion != null)
            _buildSection(
              'Propiedad',
              Icons.location_on,
              _ticket!.propiedadDireccion!,
              subtitle: _ticket!.espacioNombre,
            ),
          if (_ticket!.propiedadDireccion != null) const SizedBox(height: 16),

          // Presupuesto (si existe)
          if (_ticket!.presupuestoEstimado != null)
            _buildSection(
              'Presupuesto Estimado',
              Icons.attach_money,
              '\$${_ticket!.presupuestoEstimado!.toStringAsFixed(2)}',
            ),
          if (_ticket!.presupuestoEstimado != null) const SizedBox(height: 16),

          // Fechas
          _buildSection(
            'Fechas',
            Icons.calendar_today,
            'Creado: ${_formatDate(_ticket!.fechaCreacion)}',
            subtitle: _ticket!.fechaCompletado != null
                ? 'Completado: ${_formatDate(_ticket!.fechaCompletado!)}'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
