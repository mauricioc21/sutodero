
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ticket_model.dart';
import '../../models/inventory_property.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';

class AddEditTicketScreen extends StatefulWidget {
  final TicketModel? ticket;

  const AddEditTicketScreen({super.key, this.ticket});

  @override
  State<AddEditTicketScreen> createState() => _AddEditTicketScreenState();
}

class _AddEditTicketScreenState extends State<AddEditTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TicketService _ticketService = TicketService();
  final InventoryService _inventoryService = InventoryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _presupuestoController;
  
  ServiceType _tipoServicio = ServiceType.otro;
  TicketPriority _prioridad = TicketPriority.media;
  bool _isLoading = false;
  
  // Selector de propiedad
  List<InventoryProperty> _propiedades = [];
  InventoryProperty? _propiedadSeleccionada;
  
  // Fotos del ticket
  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.ticket?.titulo ?? '');
    _descripcionController = TextEditingController(text: widget.ticket?.descripcion ?? '');
    _presupuestoController = TextEditingController(
      text: widget.ticket?.presupuestoEstimado?.toString() ?? '',
    );
    
    if (widget.ticket != null) {
      _tipoServicio = widget.ticket!.tipoServicio;
      _prioridad = widget.ticket!.prioridad;
      _fotos = List.from(widget.ticket!.fotosProblema);
    }
    
    _loadPropiedades();
  }

  Future<void> _loadPropiedades() async {
    try {
      final propiedades = await _inventoryService.getAllProperties();
      if (mounted) {
        setState(() {
          _propiedades = propiedades;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar propiedades: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _fotos.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _fotos.add(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }



  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _presupuestoController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final presupuesto = double.tryParse(_presupuestoController.text);
      
      await _ticketService.createTicket(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        tipoServicio: _tipoServicio,
        clienteId: user.uid,
        clienteNombre: user.nombre,
        clienteTelefono: user.telefono,
        clienteEmail: user.email,
        prioridad: _prioridad,
        presupuestoEstimado: presupuesto,
        propiedadId: _propiedadSeleccionada?.id,
        propiedadDireccion: _propiedadSeleccionada?.direccion,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _fotos.isEmpty 
                ? '✅ Ticket creado exitosamente'
                : '✅ Ticket creado con ${_fotos.length} foto(s)'
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.ticket == null ? 'Nuevo Ticket' : 'Editar Ticket'),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _tituloController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Título del Trabajo *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Ej: Reparar tubería del baño',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 16),

            // Tipo de servicio
            DropdownButtonFormField<ServiceType>(
              value: _tipoServicio,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tipo de Servicio *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ServiceType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _tipoServicio = value!),
            ),
            const SizedBox(height: 16),

            // Prioridad
            DropdownButtonFormField<TicketPriority>(
              value: _prioridad,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Prioridad *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: TicketPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _prioridad = value!),
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descripción del Problema *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Describe detalladamente el trabajo a realizar...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700)),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ingresa una descripción' : null,
            ),
            const SizedBox(height: 16),

            // Selector de propiedad
            if (_propiedades.isNotEmpty)
              DropdownButtonFormField<InventoryProperty>(
                value: _propiedadSeleccionada,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Propiedad (Opcional)',
                  labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                  hintText: 'Selecciona una propiedad',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.home, color: Color(0xFFFFD700)),
                ),
                items: _propiedades
                    .map((propiedad) => DropdownMenuItem(
                          value: propiedad,
                          child: Text(
                            propiedad.direccion,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _propiedadSeleccionada = value),
              ),
            if (_propiedades.isNotEmpty) const SizedBox(height: 16),

            // Fotos del problema
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Fotos del Problema',
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${_fotos.length}/10',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _fotos.length < 10 ? _pickImage : null,
                          icon: const Icon(Icons.image),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _fotos.length < 10 ? _takePhoto : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fotos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _fotos[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Presupuesto estimado
            TextFormField(
              controller: _presupuestoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Presupuesto Estimado (Opcional)',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Colors.white),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C2C2C)),
                        ),
                      )
                    : const Text(
                        'CREAR TICKET',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
