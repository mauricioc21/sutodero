import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/inventory_model.dart';
import '../../models/ticket_model.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../services/ticket_service.dart'; // Para obtener tickets activos

class MaestroInventoryScreen extends StatefulWidget {
  const MaestroInventoryScreen({Key? key}) : super(key: key);

  @override
  _MaestroInventoryScreenState createState() => _MaestroInventoryScreenState();
}

class _MaestroInventoryScreenState extends State<MaestroInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryService _inventoryService = InventoryService();
  final TicketService _ticketService = TicketService();
  
  bool _isLoading = false;
  List<MaestroInventoryItem> _items = [];
  List<InventoryTransaction> _history = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    // Cargar Inventario y Historial en paralelo
    final items = await _inventoryService.getMaestroInventory(user.uid);
    final history = await _inventoryService.getHistory(user.uid);

    setState(() {
      _items = items;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Inventario'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.dorado,
          labelColor: AppTheme.dorado,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Bodega Móvil'),
            Tab(text: 'Solicitudes'),
            Tab(text: 'Movimientos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(),
          _buildRequestsTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestMaterialDialog,
        backgroundColor: AppTheme.dorado,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
        label: const Text('Solicitar Material', style: TextStyle(color: Colors.black)),
      ),
    );
  }

  // --- TAB 1: Inventario Actual ---
  Widget _buildInventoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No tienes materiales asignados.', style: TextStyle(color: Colors.grey)),
            TextButton(onPressed: _loadData, child: const Text('Recargar'))
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final isLowStock = item.cantidadActual <= item.cantidadMinima;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Unidad: ${item.unidad}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.cantidadActual}', 
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.red : Colors.green
                            )
                          ),
                          if (isLowStock)
                            const Text('Stock Bajo', style: TextStyle(color: Colors.red, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.build, size: 18),
                        label: const Text('Usar en Ticket'),
                        onPressed: () => _showReportUsageDialog(item, InventoryTransactionType.uso_ticket),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                        label: const Text('Reportar Daño'),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        onPressed: () => _showReportUsageDialog(item, InventoryTransactionType.danado),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: Solicitudes (Placeholder simple) ---
  Widget _buildRequestsTab() {
    // Aquí se listarian las solicitudes (requiere otro endpoint en servicio, simulamos vacío por ahora)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_edu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Historial de solicitudes (Próximamente)', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- TAB 3: Historial de Movimientos ---
  Widget _buildHistoryTab() {
    if (_history.isEmpty) return const Center(child: Text('Sin movimientos recientes'));

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final trans = _history[index];
        IconData icon;
        Color color;

        switch (trans.tipo) {
          case InventoryTransactionType.uso_ticket:
            icon = Icons.construction;
            color = Colors.blue;
            break;
          case InventoryTransactionType.solicitud:
            icon = Icons.add_circle;
            color = Colors.green;
            break;
          case InventoryTransactionType.danado:
            icon = Icons.broken_image;
            color = Colors.orange;
            break;
          case InventoryTransactionType.perdido:
            icon = Icons.remove_circle;
            color = Colors.red;
            break;
          default:
            icon = Icons.info;
            color = Colors.grey;
        }

        return ListTile(
          leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          title: Text(trans.nombreItem),
          subtitle: Text('${DateFormat('dd/MM HH:mm').format(trans.fecha)} - ${trans.tipo.toString().split('.').last}'),
          trailing: Text(
            '${trans.cantidad > 0 ? "+" : ""}${trans.cantidad}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: trans.cantidad > 0 ? Colors.green : Colors.red,
            ),
          ),
          onTap: () {
            if (trans.ticketId != null) {
              // Navegar al ticket si fuera necesario
            }
          },
        );
      },
    );
  }

  // --- DIÁLOGO: Solicitar Material ---
  Future<void> _showRequestMaterialDialog() async {
    final nombreCtrl = TextEditingController();
    final cantCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar Material'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Material'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: cantCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: motivoCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo (Ej. Stock bajo)'),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final user = Provider.of<AuthService>(context, listen: false).currentUser;
              final request = MaterialRequest(
                id: const Uuid().v4(),
                maestroId: user!.uid,
                nombreMaterial: nombreCtrl.text,
                cantidadSolicitada: double.parse(cantCtrl.text),
                unidad: 'unid', // Simplificado
                motivo: motivoCtrl.text,
                estado: RequestStatus.pendiente,
                fechaSolicitud: DateTime.now(),
              );

              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await _inventoryService.createMaterialRequest(request);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Solicitud enviada' : 'Error al enviar'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
              setState(() => _isLoading = false);
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO: Reportar Uso/Daño ---
  Future<void> _showReportUsageDialog(MaestroInventoryItem item, InventoryTransactionType type) async {
    final cantCtrl = TextEditingController();
    final comentCtrl = TextEditingController();
    String? selectedTicketId;
    String? photoPath;
    
    // Si es uso normal, necesitamos cargar tickets activos
    List<TicketModel> activeTickets = [];
    if (type == InventoryTransactionType.uso_ticket) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      // Esto debería ser un método optimizado tipo getActiveTickets
      final tickets = await _ticketService.getTicketsByUser(user!.uid, isCliente: false); 
      activeTickets = tickets.where((t) => 
        t.estado == TicketStatus.en_ejecucion || 
        t.estado == TicketStatus.en_lugar
      ).toList();
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(type == InventoryTransactionType.uso_ticket ? 'Reportar Uso' : 'Reportar Incidencia'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Item: ${item.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Disponible: ${item.cantidadActual} ${item.unidad}'),
                  const SizedBox(height: 16),
                  
                  if (type == InventoryTransactionType.uso_ticket)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Seleccionar Ticket'),
                      items: activeTickets.map<DropdownMenuItem<String>>((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.codigo.isNotEmpty ? t.codigo : t.titulo, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => selectedTicketId = val,
                    ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: cantCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad a descontar'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: comentCtrl,
                    decoration: const InputDecoration(labelText: 'Comentarios'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  
                  // Botón Foto
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.camera);
                      if (picked != null) {
                        setStateDialog(() => photoPath = picked.path);
                      }
                    },
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: photoPath != null
                          ? Image.file(File(photoPath!), fit: BoxFit.cover)
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt), Text('Evidencia (Opcional)')]),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final qty = double.tryParse(cantCtrl.text);
                  if (qty == null || qty <= 0) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
                     return;
                  }
                  if (type == InventoryTransactionType.uso_ticket && selectedTicketId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un ticket')));
                    return;
                  }

                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);

                  final user = Provider.of<AuthService>(context, listen: false).currentUser;
                  final result = await _inventoryService.reportMaterialUsage(
                    maestroId: user!.uid,
                    itemId: item.id,
                    cantidadUsada: qty,
                    tipo: type,
                    ticketId: selectedTicketId,
                    evidenciaFoto: photoPath,
                    comentario: comentCtrl.text,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                    ),
                  );
                  _loadData();
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
