import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ticket_model.dart';
import '../../models/user_model.dart';
import '../../models/maestro_profile_model.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/pdf_service.dart';
import '../../services/maestro_profile_service.dart';
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
  
  // Para cotización aprobada
  List<UserModel> _maestros = [];
  UserModel? _maestroSeleccionado;
  bool _isLoadingMaestros = false;
  bool _isApprovingCotizacion = false;
  bool _cotizacionToggleActivada = false; // Toggle para activar cotización

  @override
  void initState() {
    super.initState();
    _loadTicket();
    _loadMaestros();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    final ticket = await _ticketService.getTicket(widget.ticketId);
    setState(() {
      _ticket = ticket;
      _isLoading = false;
      
      // Si ya tiene maestro asignado, seleccionarlo
      if (ticket != null && ticket.toderoId != null) {
        _maestroSeleccionado = _maestros.firstWhere(
          (m) => m.uid == ticket.toderoId,
          orElse: () => _maestros.isNotEmpty ? _maestros.first : _maestros.first,
        );
      }
    });
  }
  
  Future<void> _loadMaestros() async {
    setState(() => _isLoadingMaestros = true);
    
    try {
      List<UserModel> maestros = [];
      
      // 1. Cargar perfiles de maestros predefinidos (Rodrigo y Alexander) - PRIORIDAD
      try {
        final maestroProfileService = MaestroProfileService();
        final profiles = await maestroProfileService.getActiveMaestroProfiles()
            .timeout(const Duration(seconds: 3))
            .first;
        
        // Convertir perfiles a UserModel para compatibilidad
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
        // Si no se pueden cargar los perfiles, crear los predeterminados en memoria
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
            .where('activo', isEqualTo: true)
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
        // Si falla la carga de users, continuar con los perfiles predefinidos
      }
      
      // Ordenar alfabéticamente
      maestros.sort((a, b) => a.nombre.compareTo(b.nombre));
      
      setState(() {
        _maestros = maestros;
        _isLoadingMaestros = false;
      });
    } catch (e) {
      setState(() => _isLoadingMaestros = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error cargando maestros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child: CircularProgressIndicator(color: Color(0xFFFAB334)),
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

  /// Aprobar cotización solamente (sin asignar maestro)
  Future<void> _approveCotizacionOnly() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      // Aprobar cotización sin maestro
      final success = await _ticketService.approveCotizacionAndAssignMaestro(
        ticketId: widget.ticketId,
        maestroId: '',
        maestroNombre: 'Sin asignar',
        userId: currentUser?.uid,
        userName: currentUser?.nombre,
      );
      
      if (success) {
        await _loadTicket();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cotización aprobada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al aprobar cotización'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Asignar maestro a una cotización ya aprobada
  Future<void> _assignMaestroOnly() async {
    if (_maestroSeleccionado == null) return;
    
    setState(() => _isApprovingCotizacion = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      // Asignar maestro únicamente
      final success = await _ticketService.assignMaestroToTicket(
        ticketId: widget.ticketId,
        maestroId: _maestroSeleccionado!.uid,
        maestroNombre: _maestroSeleccionado!.nombre,
        userId: currentUser?.uid,
        userName: currentUser?.nombre,
      );
      
      setState(() => _isApprovingCotizacion = false);
      
      if (success) {
        await _loadTicket();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Maestro asignado: ${_maestroSeleccionado!.nombre}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al asignar maestro'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isApprovingCotizacion = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          child: CircularProgressIndicator(color: Color(0xFFFAB334)),
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
                    onPressed: () async {
                      // Abrir WhatsApp directamente al número 3133164510
                      final whatsappNumber = '573133164510'; // Código de país Colombia (57)
                      final message = Uri.encodeComponent(
                        'Hola, tengo una consulta sobre el ticket #${_ticket!.id.substring(0, 8)} - ${_ticket!.titulo}'
                      );
                      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$message';
                      
                      try {
                        final uri = Uri.parse(whatsappUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo abrir WhatsApp. Verifica que esté instalado.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al abrir WhatsApp: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
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
                      color: Color(0xFFFAB334),
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
              color: Color(0xFFFAB334),
              fontSize: 16,
            ),
          ),
          SizedBox(height: AppTheme.spacingMD),

          // Cotización aprobada - Toggle verde + Dropdown condicional
          if (!_ticket!.cotizacionAprobada)
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMD),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(
                  color: _cotizacionToggleActivada 
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Switch con texto
                  Row(
                    children: [
                      Icon(
                        _cotizacionToggleActivada 
                            ? Icons.check_circle 
                            : Icons.check_circle_outline,
                        color: _cotizacionToggleActivada ? Colors.green : Colors.grey,
                        size: 22,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          'Cotización Aprobada',
                          style: TextStyle(
                            color: _cotizacionToggleActivada 
                                ? Colors.green 
                                : AppTheme.blanco,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Toggle Switch Verde
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: _cotizacionToggleActivada,
                          onChanged: (value) async {
                            if (value) {
                              // Activar toggle y aprobar automáticamente
                              setState(() {
                                _cotizacionToggleActivada = value;
                                _isApprovingCotizacion = true;
                              });
                              
                              // Aprobar cotización automáticamente
                              await _approveCotizacionOnly();
                              
                              setState(() {
                                _isApprovingCotizacion = false;
                              });
                            } else {
                              // No permitir desactivar si ya está aprobada
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No se puede desactivar una cotización ya aprobada'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          activeColor: Colors.green,
                          activeTrackColor: Colors.green.withValues(alpha: 0.5),
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  // Dropdown de maestros - Solo visible cuando toggle está activado
                  if (_cotizacionToggleActivada) ...[
                    SizedBox(height: AppTheme.spacingMD),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.negro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonFormField<UserModel>(
                        value: _maestroSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Maestro',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.engineering, color: Colors.green),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingMD,
                            vertical: 12,
                          ),
                        ),
                        dropdownColor: AppTheme.grisOscuro,
                        style: const TextStyle(color: AppTheme.blanco, fontSize: 16),
                        items: _maestros.isNotEmpty ? _maestros.map((maestro) {
                          return DropdownMenuItem<UserModel>(
                            value: maestro,
                            child: Text(
                              maestro.nombre,
                              style: const TextStyle(color: AppTheme.blanco),
                            ),
                          );
                        }).toList() : null,
                        onChanged: _maestros.isNotEmpty ? (value) {
                          setState(() {
                            _maestroSeleccionado = value;
                          });
                        } : null,
                        hint: Text(
                          _isLoadingMaestros 
                              ? 'Cargando maestros...' 
                              : _maestros.isEmpty
                                  ? 'No hay maestros disponibles'
                                  : 'Seleccione un maestro',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingMD),
                    
                    // Botón de asignar maestro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isApprovingCotizacion || _maestroSeleccionado == null)
                            ? null
                            : _assignMaestroOnly,
                        icon: _isApprovingCotizacion
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.blanco,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add, color: AppTheme.blanco),
                        label: Text(
                          _isApprovingCotizacion 
                              ? 'Asignando...' 
                              : 'Asignar Maestro',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blanco,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: AppTheme.blanco,
                          padding: EdgeInsets.symmetric(vertical: AppTheme.paddingMD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          disabledBackgroundColor: Colors.grey[700],
                          disabledForegroundColor: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMD),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cotización Aprobada',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_ticket!.fechaCotizacionAprobada != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Aprobada: ${_formatDate(_ticket!.fechaCotizacionAprobada!)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Dropdown de maestros - Visible cuando cotización está aprobada
                  SizedBox(height: AppTheme.spacingMD),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.negro,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonFormField<UserModel>(
                      value: _maestroSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Maestro',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.engineering, color: Colors.green),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingMD,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: AppTheme.grisOscuro,
                      style: const TextStyle(color: AppTheme.blanco, fontSize: 16),
                      items: _maestros.isNotEmpty ? _maestros.map((maestro) {
                        return DropdownMenuItem<UserModel>(
                          value: maestro,
                          child: Text(
                            maestro.nombre,
                            style: const TextStyle(color: AppTheme.blanco),
                          ),
                        );
                      }).toList() : null,
                      onChanged: _maestros.isNotEmpty ? (value) {
                        setState(() {
                          _maestroSeleccionado = value;
                        });
                      } : null,
                      hint: Text(
                        _isLoadingMaestros 
                            ? 'Cargando maestros...' 
                            : _maestros.isEmpty
                                ? 'No hay maestros disponibles'
                                : _ticket!.toderoNombre != null && _ticket!.toderoNombre!.isNotEmpty
                                    ? 'Maestro actual: ${_ticket!.toderoNombre}'
                                    : 'Seleccione un maestro',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingMD),
                  
                  // Botón de asignar maestro
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isApprovingCotizacion || _maestroSeleccionado == null)
                          ? null
                          : _assignMaestroOnly,
                      icon: _isApprovingCotizacion
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.blanco,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.person_add, color: AppTheme.blanco),
                      label: Text(
                        _isApprovingCotizacion 
                            ? 'Asignando...' 
                            : 'Asignar Maestro',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blanco,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: AppTheme.blanco,
                        padding: EdgeInsets.symmetric(vertical: AppTheme.paddingMD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        disabledBackgroundColor: Colors.grey[700],
                        disabledForegroundColor: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
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
                    const Icon(Icons.history, color: Color(0xFFFAB334), size: 20),
                    SizedBox(width: AppTheme.spacingSM),
                    const Text(
                      'Historial de Cambios',
                      style: TextStyle(
                        color: Color(0xFFFAB334),
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
                  color: Color(0xFFFAB334),
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
