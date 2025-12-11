import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import 'widgets/check_in_out_card.dart';

import '../../services/location_api_service.dart';
import '../../services/geolocation_service.dart';

class MaestroWorkOrderScreen extends StatefulWidget {
  final String ticketId;

  const MaestroWorkOrderScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  _MaestroWorkOrderScreenState createState() => _MaestroWorkOrderScreenState();
}

class _MaestroWorkOrderScreenState extends State<MaestroWorkOrderScreen> with SingleTickerProviderStateMixin {
  late TicketService _ticketService;
  final LocationApiService _locationApi = LocationApiService();
  final GeolocationService _geolocationService = GeolocationService();
  TicketModel? _ticket;
  bool _isLoading = true;
  late TabController _tabController;
  
  // Rango configurable (podría venir de Remote Config o Settings)
  final double _allowedRange = 50.0; 

  @override
  void initState() {
    super.initState();
    _ticketService = TicketService();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _updateStatus(TicketStatus newStatus, {String? detalles}) async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    setState(() => _isLoading = true);
    
    final success = await _ticketService.updateTicketStatus(
      widget.ticketId, 
      newStatus,
      userId: user?.uid,
      userName: user?.nombre ?? 'Maestro',
      detalles: detalles,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a ${newStatus.displayName}'), backgroundColor: AppTheme.success),
      );
      _loadTicket();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar estado'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _launchMaps() async {
    if (_ticket?.ubicacionDireccion == null) return;
    
    // Si tenemos lat/lng, usar eso
    if (_ticket!.ubicacionLat != null && _ticket!.ubicacionLng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${_ticket!.ubicacionLat},${_ticket!.ubicacionLng}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        // Opcional: Actualizar estado a "En Camino" automáticamente si está en "Asignado"
        if (_ticket!.estado == TicketStatus.asignado || _ticket!.estado == TicketStatus.nuevo) {
          _updateStatus(TicketStatus.en_camino, detalles: 'Inició ruta GPS');
        }
      }
    } else {
      // Usar dirección
      final query = Uri.encodeComponent(_ticket!.ubicacionDireccion);
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  Future<void> _addPhoto(String stage) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    
    if (pickedFile != null) {
      // Simular subida - en prod usar StorageService
      setState(() => _isLoading = true);
      // Mock URL (base64 o local path para demo)
      final mockUrl = pickedFile.path; 
      
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      await _ticketService.addPhoto(widget.ticketId, mockUrl, stage);
      _loadTicket();
    }
  }

  Future<void> _addMaterialDialog() async {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();
    final unidadController = TextEditingController(text: 'unid');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre Material')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: cantidadController, decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: unidadController, decoration: const InputDecoration(labelText: 'Unidad'))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty || cantidadController.text.isEmpty) return;
              Navigator.pop(context);
              
              final material = TicketMaterial(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nombre: nombreController.text,
                cantidad: double.tryParse(cantidadController.text) ?? 1,
                unidad: unidadController.text,
              );
              
              final user = Provider.of<AuthService>(context, listen: false).currentUser;
              await _ticketService.addMaterial(widget.ticketId, material);
              _loadTicket();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCurrentLocation() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final position = await _geolocationService.getCurrentLocation();
    
    if (position != null) {
      await _locationApi.sendLocation(
        userId: user?.uid ?? 'unknown',
        lat: position.latitude,
        lng: position.longitude,
        ticketId: widget.ticketId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación compartida exitosamente'), backgroundColor: AppTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener ubicación. Verifique GPS.'), backgroundColor: AppTheme.error),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _ticket == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ticket == null) {
      return const Scaffold(body: Center(child: Text('Ticket no encontrado')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orden #${_ticket!.codigo}', style: const TextStyle(fontSize: 16)),
            Text(_ticket!.titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Fotos'),
            Tab(text: 'Materiales'),
            Tab(text: 'Historial'),
          ],
          indicatorColor: AppTheme.dorado,
          labelColor: AppTheme.dorado,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_location),
            tooltip: 'Compartir Ubicación Actual',
            onPressed: _shareCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTicket,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          _buildStatusBar(),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildPhotosTab(),
                _buildMaterialsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
          
          // Action Button Area
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    switch (_ticket!.estado) {
      case TicketStatus.nuevo:
      case TicketStatus.asignado: statusColor = Colors.blue; break;
      case TicketStatus.en_camino: statusColor = Colors.orange; break;
      case TicketStatus.en_lugar: statusColor = Colors.purple; break;
      case TicketStatus.en_ejecucion: statusColor = Colors.green; break;
      case TicketStatus.finalizado: statusColor = Colors.grey; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppTheme.grisOscuro,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              _ticket!.estado.displayName.toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const Spacer(),
          const Icon(Icons.access_time, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            DateFormat('dd/MM HH:mm').format(_ticket!.fechaActualizacion),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check-In / Check-Out Module
          CheckInCheckOutCard(
            ticket: _ticket!, 
            onUpdate: _loadTicket,
            allowedRange: _allowedRange,
          ),
          
          const SizedBox(height: 16),

          // Visual Map Indicator (Static Map Preview)
          if (_ticket!.ubicacionLat != null && _ticket!.ubicacionLng != null)
            GestureDetector(
              onTap: _launchMaps,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  image: const DecorationImage(
                    // Using a generic map placeholder or a static map API if available
                    // Using a placeholder image for visual indication in this demo
                    image: NetworkImage('https://via.placeholder.com/600x300.png?text=Mapa+Ubicación'), 
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 30),
                        Text('Ver en Mapa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_ticket!.ubicacionLat != null) const SizedBox(height: 16),

          _buildInfoCard('Cliente', Icons.person, [
            Text(_ticket!.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_ticket!.clienteTelefono != null) 
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${_ticket!.clienteTelefono}')),
                child: Text(_ticket!.clienteTelefono!, style: const TextStyle(color: Colors.blue)),
              ),
            Text(_ticket!.ubicacionDireccion),
          ]),
          
          const SizedBox(height: 16),
          
          _buildInfoCard('Detalle del Trabajo', Icons.work, [
            Text(_ticket!.descripcion),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(_ticket!.tipoServicio.displayName), backgroundColor: Colors.grey[200]),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_ticket!.prioridad.displayName), 
                  backgroundColor: _ticket!.prioridad == TicketPriority.urgente ? Colors.red[100] : Colors.grey[200],
                  labelStyle: TextStyle(color: _ticket!.prioridad == TicketPriority.urgente ? Colors.red : Colors.black),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          if (_ticket!.notasMaestro != null && _ticket!.notasMaestro!.isNotEmpty)
            _buildInfoCard('Mis Notas', Icons.note, [
              Text(_ticket!.notasMaestro!),
            ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.dorado, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPhotoSection('Antes', _ticket!.fotosAntes, () => _addPhoto('antes')),
        const SizedBox(height: 20),
        _buildPhotoSection('Durante', _ticket!.fotosDurante, () => _addPhoto('durante')),
        const SizedBox(height: 20),
        _buildPhotoSection('Después', _ticket!.fotosDespues, () => _addPhoto('despues')),
      ],
    );
  }

  Widget _buildPhotoSection(String title, List<String> photos, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_ticket!.estado == TicketStatus.en_ejecucion)
              IconButton(icon: const Icon(Icons.add_a_photo, color: AppTheme.dorado), onPressed: onAdd),
          ],
        ),
        if (photos.isEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('Sin fotos', style: TextStyle(color: Colors.grey))),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: NetworkImage(photos[index]), fit: BoxFit.cover), // Handle local paths too
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    return Column(
      children: [
        Expanded(
          child: _ticket!.materialesUsados.isEmpty
              ? const Center(child: Text('No se han registrado materiales'))
              : ListView.builder(
                  itemCount: _ticket!.materialesUsados.length,
                  itemBuilder: (context, index) {
                    final item = _ticket!.materialesUsados[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.build, size: 16)),
                      title: Text(item.nombre),
                      subtitle: Text(item.notas ?? ''),
                      trailing: Text('${item.cantidad} ${item.unidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        if (_ticket!.estado == TicketStatus.en_ejecucion)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addMaterialDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final history = _ticket!.historial.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: AppTheme.dorado, shape: BoxShape.circle),
                  ),
                  if (index < history.length - 1)
                    Container(width: 2, height: 40, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.accion, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(item.fecha)} - ${item.usuario}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (item.detalles != null)
                      Text(item.detalles!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionFooter() {
    // Definir acción principal según estado
    Widget actionButton;
    
    switch (_ticket!.estado) {
      case TicketStatus.asignado:
      case TicketStatus.nuevo:
        actionButton = _buildMainButton(
          'INICIAR RUTA', 
          Icons.map, 
          Colors.blue, 
          () {
            _launchMaps();
            _updateStatus(TicketStatus.en_camino, detalles: 'Inició desplazamiento al sitio');
          }
        );
        break;
      
      case TicketStatus.en_camino:
        // Se usa CheckInCheckOutCard
        actionButton = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text('📍 Por favor, realice Check-In al llegar al sitio.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        );
        break;
        
      case TicketStatus.en_lugar:
        actionButton = _buildMainButton(
          'INICIAR TRABAJO', 
          Icons.play_arrow, 
          Colors.green, 
          () => _updateStatus(TicketStatus.en_ejecucion, detalles: 'Inicio de labores'),
        );
        break;
        
      case TicketStatus.en_ejecucion:
        actionButton = Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus(TicketStatus.pendiente_repuestos, detalles: 'Pausa por materiales'),
                child: const Text('PAUSAR'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMainButton(
                'FINALIZAR', 
                Icons.check_circle, 
                AppTheme.dorado, 
                () => _updateStatus(TicketStatus.finalizado, detalles: 'Trabajo terminado'),
              ),
            ),
          ],
        );
        break;
        
      case TicketStatus.pendiente_repuestos:
        actionButton = _buildMainButton(
          'REANUDAR TRABAJO', 
          Icons.play_arrow, 
          Colors.green, 
          () => _updateStatus(TicketStatus.en_ejecucion, detalles: 'Reanudación de labores'),
        );
        break;
        
      case TicketStatus.finalizado:
        actionButton = Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Trabajo Finalizado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        );
        break;

      default:
        actionButton = const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(child: actionButton),
    );
  }

  Widget _buildMainButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
