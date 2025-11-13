import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/ticket_timeline.dart';
import '../../widgets/signature_pad.dart';
import 'chat_screen.dart';
import '../../config/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  final PdfService _pdfService = PdfService();
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

  Future<void> _exportToPdf() async {
    if (_ticket == null) return;
    
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
      
      // Generar PDF
      final pdfBytes = await _pdfService.generateTicketPdf(_ticket!);
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      
      // Compartir/Imprimir PDF
      await _pdfService.sharePdf(
        pdfBytes,
        'ticket_${_ticket!.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureSignature(bool isCliente) async {
    if (_ticket == null) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final signatureBase64 = await showSignaturePad(
      context: context,
      title: isCliente ? 'Firma del Cliente' : 'Firma del Todero',
      subtitle: 'Confirme la realización del trabajo',
    );
    
    if (signatureBase64 == null || !mounted) return;
    
    // Guardar firma
    final success = await _ticketService.saveSignature(
      ticketId: widget.ticketId,
      signatureBase64: signatureBase64,
      isCliente: isCliente,
      userId: authService.currentUser?.uid,
      userName: authService.currentUser?.nombre,
    );
    
    if (success) {
      _loadTicket();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCliente 
                  ? '✅ Firma del cliente guardada' 
                  : '✅ Firma del todero guardada',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al guardar firma'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.negro,
        appBar: AppBar(
          backgroundColor: AppTheme.grisOscuro,
          foregroundColor: AppTheme.dorado,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        backgroundColor: AppTheme.negro,
        appBar: AppBar(
          backgroundColor: AppTheme.grisOscuro,
          foregroundColor: AppTheme.dorado,
        ),
        body: const Center(
          child: Text(
            'Ticket no encontrado',
            style: TextStyle(color: AppTheme.blanco),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Detalle del Ticket'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          // Botón de Exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _exportToPdf,
          ),
          
          // Botón de Firma Digital (solo si está completado o en progreso)
          if (_ticket!.estado == TicketStatus.completado || 
              _ticket!.estado == TicketStatus.enProgreso)
            PopupMenuButton<String>(
              icon: const Icon(Icons.draw),
              tooltip: 'Firma Digital',
              onSelected: (value) {
                if (value == 'cliente') {
                  _captureSignature(true);
                } else if (value == 'todero') {
                  _captureSignature(false);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cliente',
                  child: Row(
                    children: [
                      Icon(
                        _ticket!.firmaCliente != null 
                            ? Icons.check_circle 
                            : Icons.circle_outlined,
                        color: _ticket!.firmaCliente != null 
                            ? Colors.green 
                            : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      const Text('Firma Cliente'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'todero',
                  child: Row(
                    children: [
                      Icon(
                        _ticket!.firmaTodero != null 
                            ? Icons.check_circle 
                            : Icons.circle_outlined,
                        color: _ticket!.firmaTodero != null 
                            ? Colors.green 
                            : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      const Text('Firma Todero'),
                    ],
                  ),
                ),
              ],
            ),
          
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
                            color: AppTheme.blanco,
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
        padding: EdgeInsets.all(AppTheme.paddingMD),
        children: [
          // Estado
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            decoration: BoxDecoration(
              color: AppTheme.grisOscuro,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
                SizedBox(width: AppTheme.spacingMD),
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
                    color: AppTheme.dorado.withValues(alpha: 0.2),
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
          SizedBox(height: AppTheme.spacingMD),

          // Título
          Text(
            _ticket!.titulo,
            style: const TextStyle(
              color: AppTheme.blanco,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacingSM),

          // Tipo de servicio
          Text(
            _ticket!.tipoServicio.displayName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
            ),
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Descripción
          _buildSection(
            'Descripción',
            Icons.description,
            _ticket!.descripcion,
          ),
          SizedBox(height: AppTheme.spacingMD),

          // Cliente
          _buildSection(
            'Cliente',
            Icons.person,
            _ticket!.clienteNombre,
            subtitle: _ticket!.clienteTelefono,
          ),
          SizedBox(height: AppTheme.spacingMD),

          // Propiedad (si existe)
          if (_ticket!.propiedadDireccion != null)
            _buildSection(
              'Propiedad',
              Icons.location_on,
              _ticket!.propiedadDireccion!,
              subtitle: _ticket!.espacioNombre,
            ),
          if (_ticket!.propiedadDireccion != null) SizedBox(height: AppTheme.spacingMD),

          // Presupuesto (si existe)
          if (_ticket!.presupuestoEstimado != null)
            _buildSection(
              'Presupuesto Estimado',
              Icons.attach_money,
              '\$${_ticket!.presupuestoEstimado!.toStringAsFixed(2)}',
            ),
          if (_ticket!.presupuestoEstimado != null) SizedBox(height: AppTheme.spacingMD),

          // Fechas
          _buildSection(
            'Fechas',
            Icons.calendar_today,
            'Creado: ${_formatDate(_ticket!.fechaCreacion)}',
            subtitle: _ticket!.fechaCompletado != null
                ? 'Completado: ${_formatDate(_ticket!.fechaCompletado!)}'
                : null,
          ),
          SizedBox(height: AppTheme.spacingXL),

          // Historial de cambios
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMD),
            decoration: BoxDecoration(
              color: AppTheme.grisOscuro,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFFFFD700), size: 20),
                    SizedBox(width: AppTheme.spacingSM),
                    const Text(
                      'Historial de Cambios',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),
                TicketTimeline(ticketId: _ticket!.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content, {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.dorado, size: 20),
              SizedBox(width: AppTheme.spacingSM),
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
          SizedBox(height: AppTheme.spacingMD),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.blanco,
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppTheme.spacingSM),
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
