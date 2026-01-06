import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_event.dart';
import '../services/ticket_history_service.dart';

class TicketTimeline extends StatelessWidget {
  final String ticketId;

  const TicketTimeline({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TicketEvent>>(
      stream: TicketHistoryService().getEventsStream(ticketId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay historial disponible',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final events = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            return _buildTimelineItem(event, isLast);
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(TicketEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea de tiempo
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getEventColor(event.type),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    event.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[800],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenido del evento
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        event.userName,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatTimestamp(event.timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.created:
        return const Color(0xFFFFD700);
      case EventType.statusChanged:
        return const Color(0xFF2196F3);
      case EventType.assigned:
        return const Color(0xFF9C27B0);
      case EventType.photoAdded:
        return const Color(0xFFFF6B00);
      case EventType.budgetUpdated:
        return const Color(0xFF4CAF50);
      case EventType.commented:
        return Colors.grey[600]!;
      case EventType.completed:
        return const Color(0xFF4CAF50);
      case EventType.rated:
        return const Color(0xFFFFD700);
      case EventType.cancelled:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Justo ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }
}
