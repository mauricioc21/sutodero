
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/ticket_model.dart';
import '../../models/inventory_property.dart';
import '../../services/ticket_service.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/storage_service.dart';

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
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _presupuestoController;
  late TextEditingController _direccionController;
  late TextEditingController _codigoInmuebleController;
  late TextEditingController _barrioController;
  late TextEditingController _telefonoController;
  
  ServiceType _tipoServicio = ServiceType.otro;
  TicketPriority _prioridad = TicketPriority.media;
  bool _isLoading = false;
  DateTime? _fechaVisitaPreferida;
  TimeOfDay? _horaVisitaPreferida;
  
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
    _direccionController = TextEditingController(text: widget.ticket?.propiedadDireccion ?? '');
    _codigoInmuebleController = TextEditingController();
    _barrioController = TextEditingController();
    _telefonoController = TextEditingController();
    
    if (widget.ticket != null) {
      _tipoServicio = widget.ticket!.tipoServicio;
      _prioridad = widget.ticket!.prioridad;
      _fotos = List.from(widget.ticket!.fotosProblema);
      _fechaVisitaPreferida = widget.ticket!.fechaProgramada;
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

  Future<void> _selectFechaVisita() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVisitaPreferida ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF2C2C2C),
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _fechaVisitaPreferida = picked;
      });
    }
  }

  Future<void> _selectHoraVisita() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaVisitaPreferida ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF2C2C2C),
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _horaVisitaPreferida = picked;
      });
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '⚠️ EMERGENCIA URGENTE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Instrucciones de seguridad inmediatas:',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Emergencia de agua
                _buildEmergencyItem(
                  icon: Icons.water_drop,
                  title: '💧 Fuga de Agua',
                  instructions: [
                    'Cerrar el registro principal de agua',
                    'Cortar el suministro del área afectada',
                    'Retirar objetos de valor de la zona',
                  ],
                ),
                const SizedBox(height: 16),
                
                // Emergencia de gas
                _buildEmergencyItem(
                  icon: Icons.local_fire_department,
                  title: '🔥 Fuga de Gas',
                  instructions: [
                    'NO encender luces ni aparatos eléctricos',
                    'Cerrar la llave de paso de gas inmediatamente',
                    'Abrir puertas y ventanas para ventilar',
                    'Evacuar el área y llamar a emergencias',
                  ],
                ),
                const SizedBox(height: 16),
                
                // Emergencia eléctrica
                _buildEmergencyItem(
                  icon: Icons.electrical_services,
                  title: '⚡ Corto Circuito',
                  instructions: [
                    'Apagar los tacos/breakers principales',
                    'Desconectar electrodomésticos',
                    'NO tocar cables expuestos',
                    'Llamar a un electricista certificado',
                  ],
                ),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Horario de Atención',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Emergencias en fin de semana o horario nocturno: '
                        'Se enviará personal al día siguiente apenas se confirme la asistencia.\n\n'
                        '• Para emergencias críticas que no pueden esperar, '
                        'contacte a los servicios de emergencia locales.',
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ENTENDIDO',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyItem({
    required IconData icon,
    required String title,
    required List<String> instructions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...instructions.map((instruction) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _presupuestoController.dispose();
    _direccionController.dispose();
    _codigoInmuebleController.dispose();
    _barrioController.dispose();
    _telefonoController.dispose();
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
      
      // Combinar fecha y hora si ambas están seleccionadas
      DateTime? fechaProgramada;
      if (_fechaVisitaPreferida != null && _horaVisitaPreferida != null) {
        fechaProgramada = DateTime(
          _fechaVisitaPreferida!.year,
          _fechaVisitaPreferida!.month,
          _fechaVisitaPreferida!.day,
          _horaVisitaPreferida!.hour,
          _horaVisitaPreferida!.minute,
        );
      } else if (_fechaVisitaPreferida != null) {
        fechaProgramada = _fechaVisitaPreferida;
      }
      
      // Construir título completo con código de inmueble si existe
      String tituloCompleto = _tituloController.text.trim();
      if (_codigoInmuebleController.text.trim().isNotEmpty) {
        tituloCompleto = '${_codigoInmuebleController.text.trim()} - $tituloCompleto';
      }
      
      // Usar dirección ingresada o la de la propiedad seleccionada
      final direccionFinal = _direccionController.text.trim().isNotEmpty
          ? _direccionController.text.trim()
          : _propiedadSeleccionada?.direccion;
      
      // Generar ID temporal para subir fotos
      final tempTicketId = const Uuid().v4();
      
      // Subir fotos si existen
      List<String> fotosUrls = [];
      if (_fotos.isNotEmpty) {
        if (mounted) {
          // Mostrar diálogo de progreso
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFFFD700)),
                        const SizedBox(height: 16),
                        Text('Subiendo ${_fotos.length} foto(s)...'),
                        const Text(
                          'Esto puede tomar unos momentos',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        
        fotosUrls = await _storageService.uploadTicketPhotos(
          ticketId: tempTicketId,
          filePaths: _fotos,
          isResultPhotos: false,
        );
        
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de progreso
        }
      }
      
      await _ticketService.createTicket(
        titulo: tituloCompleto,
        descripcion: _descripcionController.text.trim(),
        tipoServicio: _tipoServicio,
        clienteId: user.uid,
        clienteNombre: user.nombre,
        clienteTelefono: _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() 
            : user.telefono,
        clienteEmail: user.email,
        prioridad: _prioridad,
        presupuestoEstimado: presupuesto,
        propiedadId: _propiedadSeleccionada?.id,
        propiedadDireccion: direccionFinal,
        fechaProgramada: fechaProgramada,
        notasCliente: 'Barrio: ${_barrioController.text.trim()}',
        fotosProblema: fotosUrls,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _fotos.isEmpty 
                ? '✅ Ticket creado exitosamente'
                : fotosUrls.length == _fotos.length
                  ? '✅ Ticket creado con ${fotosUrls.length} foto(s)'
                  : '⚠️ Ticket creado, pero solo ${fotosUrls.length}/${_fotos.length} foto(s) se subieron'
            ),
            backgroundColor: fotosUrls.length == _fotos.length || _fotos.isEmpty 
              ? Colors.green 
              : Colors.orange,
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

            // Código de inmueble (opcional)
            TextFormField(
              controller: _codigoInmuebleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Código de Inmueble (Opcional)',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Ej: INM-001, APT-205',
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
                prefixIcon: const Icon(Icons.tag, color: Color(0xFFFFD700)),
              ),
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _direccionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Dirección del Inmueble *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Calle, número, piso, apto',
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
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFFD700)),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ingresa la dirección' : null,
            ),
            const SizedBox(height: 16),

            // Barrio
            TextFormField(
              controller: _barrioController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Barrio *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Nombre del barrio o zona',
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
                prefixIcon: const Icon(Icons.map, color: Color(0xFFFFD700)),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ingresa el barrio' : null,
            ),
            const SizedBox(height: 16),

            // Teléfono de contacto
            TextFormField(
              controller: _telefonoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono de Contacto *',
                labelStyle: const TextStyle(color: Color(0xFFFFD700)),
                hintText: 'Número para coordinar la visita',
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
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFD700)),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Ingresa un teléfono' : null,
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
              onChanged: (value) {
                setState(() => _prioridad = value!);
                // Mostrar diálogo de emergencia si se selecciona "Urgente"
                if (value == TicketPriority.urgente) {
                  // Delay para que el dropdown se cierre primero
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      _showEmergencyDialog();
                    }
                  });
                }
              },
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

            // Fecha y hora preferida para visita
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
                      const Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Fecha y Hora Preferida para Visita',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectFechaVisita,
                          icon: const Icon(Icons.event),
                          label: Text(
                            _fechaVisitaPreferida == null
                                ? 'Seleccionar Fecha'
                                : '${_fechaVisitaPreferida!.day}/${_fechaVisitaPreferida!.month}/${_fechaVisitaPreferida!.year}',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFFFD700)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectHoraVisita,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _horaVisitaPreferida == null
                                ? 'Seleccionar Hora'
                                : '${_horaVisitaPreferida!.hour.toString().padLeft(2, '0')}:${_horaVisitaPreferida!.minute.toString().padLeft(2, '0')}',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFFFD700)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fechaVisitaPreferida != null || _horaVisitaPreferida != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nota: Esta es una preferencia. El técnico confirmará la disponibilidad.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
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

            // Fotos de los daños
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
                      const Icon(Icons.photo_camera, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Fotos de los Daños',
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${_fotos.length}/10',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sube fotos del problema que necesitas arreglar',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
