import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/property_listing.dart';
import '../../services/property_listing_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

/// Pantalla para crear/editar captaciones de inmuebles
class AddEditPropertyListingScreen extends StatefulWidget {
  final PropertyListing? listing;

  const AddEditPropertyListingScreen({super.key, this.listing});

  @override
  State<AddEditPropertyListingScreen> createState() => _AddEditPropertyListingScreenState();
}

class _AddEditPropertyListingScreenState extends State<AddEditPropertyListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyListingService _listingService = PropertyListingService();
  
  late TextEditingController _tituloController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _barrioController;
  late TextEditingController _descripcionController;
  late TextEditingController _areaController;
  late TextEditingController _precioVentaController;
  late TextEditingController _precioArriendoController;
  late TextEditingController _administracionController;
  late TextEditingController _propietarioNombreController;
  late TextEditingController _propietarioTelefonoController;
  late TextEditingController _propietarioEmailController;
  
  String _tipo = 'casa';
  TransactionType _transaccionTipo = TransactionType.venta;
  int? _numeroHabitaciones;
  int? _numeroBanos;
  int? _numeroParqueaderos;
  int? _estrato;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.listing?.titulo ?? '');
    _direccionController = TextEditingController(text: widget.listing?.direccion ?? '');
    _ciudadController = TextEditingController(text: widget.listing?.ciudad ?? '');
    _barrioController = TextEditingController(text: widget.listing?.barrio ?? '');
    _descripcionController = TextEditingController(text: widget.listing?.descripcion ?? '');
    _areaController = TextEditingController(text: widget.listing?.area?.toString() ?? '');
    _precioVentaController = TextEditingController(text: widget.listing?.precioVenta?.toString() ?? '');
    _precioArriendoController = TextEditingController(text: widget.listing?.precioArriendo?.toString() ?? '');
    _administracionController = TextEditingController(text: widget.listing?.administracion?.toString() ?? '');
    _propietarioNombreController = TextEditingController(text: widget.listing?.propietarioNombre ?? '');
    _propietarioTelefonoController = TextEditingController(text: widget.listing?.propietarioTelefono ?? '');
    _propietarioEmailController = TextEditingController(text: widget.listing?.propietarioEmail ?? '');
    
    if (widget.listing != null) {
      _tipo = widget.listing!.tipo;
      _transaccionTipo = widget.listing!.transaccionTipo;
      _numeroHabitaciones = widget.listing!.numeroHabitaciones;
      _numeroBanos = widget.listing!.numeroBanos;
      _numeroParqueaderos = widget.listing!.numeroParqueaderos;
      _estrato = widget.listing!.estrato;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _barrioController.dispose();
    _descripcionController.dispose();
    _areaController.dispose();
    _precioVentaController.dispose();
    _precioArriendoController.dispose();
    _administracionController.dispose();
    _propietarioNombreController.dispose();
    _propietarioTelefonoController.dispose();
    _propietarioEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
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
      final listing = PropertyListing(
        id: widget.listing?.id ?? const Uuid().v4(),
        userId: user.uid,
        titulo: _tituloController.text.trim(),
        direccion: _direccionController.text.trim(),
        ciudad: _ciudadController.text.trim().isNotEmpty ? _ciudadController.text.trim() : null,
        barrio: _barrioController.text.trim().isNotEmpty ? _barrioController.text.trim() : null,
        tipo: _tipo,
        transaccionTipo: _transaccionTipo,
        descripcion: _descripcionController.text.trim().isNotEmpty ? _descripcionController.text.trim() : null,
        area: double.tryParse(_areaController.text),
        numeroHabitaciones: _numeroHabitaciones,
        numeroBanos: _numeroBanos,
        numeroParqueaderos: _numeroParqueaderos,
        estrato: _estrato,
        precioVenta: double.tryParse(_precioVentaController.text),
        precioArriendo: double.tryParse(_precioArriendoController.text),
        administracion: double.tryParse(_administracionController.text),
        propietarioNombre: _propietarioNombreController.text.trim().isNotEmpty 
            ? _propietarioNombreController.text.trim() : null,
        propietarioTelefono: _propietarioTelefonoController.text.trim().isNotEmpty 
            ? _propietarioTelefonoController.text.trim() : null,
        propietarioEmail: _propietarioEmailController.text.trim().isNotEmpty 
            ? _propietarioEmailController.text.trim() : null,
      );

      if (widget.listing == null) {
        await _listingService.createListing(listing);
      } else {
        await _listingService.updateListing(listing);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.listing == null 
                  ? '✅ Captación creada exitosamente'
                  : '✅ Captación actualizada exitosamente'
            ),
            backgroundColor: Colors.green,
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
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text(widget.listing == null ? 'Nueva Captación' : 'Editar Captación'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          children: [
            // Título
            _buildTextField(
              controller: _tituloController,
              label: 'Título del Inmueble *',
              hint: 'Ej: Apartamento moderno en Chapinero',
              icon: Icons.title,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa un título' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Dirección
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección *',
              hint: 'Calle, número, piso, apto',
              icon: Icons.location_on,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa la dirección' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Ciudad y Barrio
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ciudadController,
                    label: 'Ciudad',
                    hint: 'Bogotá',
                    icon: Icons.location_city,
                  ),
                ),
                SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: _buildTextField(
                    controller: _barrioController,
                    label: 'Barrio',
                    hint: 'Chapinero',
                    icon: Icons.map,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Tipo de inmueble y transacción
            _buildDropdown(
              label: 'Tipo de Inmueble *',
              value: _tipo,
              items: ['casa', 'apartamento', 'oficina', 'local', 'bodega', 'terreno'],
              displayNames: ['Casa', 'Apartamento', 'Oficina', 'Local', 'Bodega', 'Terreno'],
              onChanged: (value) => setState(() => _tipo = value!),
            ),
            SizedBox(height: AppTheme.spacingMD),

            _buildTransactionTypeSelector(),
            SizedBox(height: AppTheme.spacingMD),

            // Descripción
            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Describe las características del inmueble...',
              icon: Icons.description,
              maxLines: 4,
            ),
            SizedBox(height: AppTheme.spacingMD),

            // Números (habitaciones, baños, parqueaderos)
            _buildNumberFields(),
            SizedBox(height: AppTheme.spacingMD),

            // Precios
            _buildPrecioFields(),
            SizedBox(height: AppTheme.spacingMD),

            // Información del propietario
            _buildPropietarioSection(),
            SizedBox(height: AppTheme.spacingXL),

            // Botón guardar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: AppTheme.negro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.negro),
                        ),
                      )
                    : Text(
                        widget.listing == null ? 'CREAR CAPTACIÓN' : 'ACTUALIZAR CAPTACIÓN',
                        style: const TextStyle(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.blanco),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.dorado),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.dorado) : null,
        filled: true,
        fillColor: AppTheme.grisOscuro,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.dorado),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required List<String> displayNames,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.grisOscuro,
      style: const TextStyle(color: AppTheme.blanco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.dorado),
        filled: true,
        fillColor: AppTheme.grisOscuro,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
      ),
      items: List.generate(items.length, (index) {
        return DropdownMenuItem(
          value: items[index],
          child: Text(displayNames[index]),
        );
      }),
      onChanged: onChanged,
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Transacción *',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.dorado,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        Row(
          children: [
            Expanded(
              child: _buildTransactionTypeOption(TransactionType.venta, 'Venta', '💰'),
            ),
            SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: _buildTransactionTypeOption(TransactionType.arriendo, 'Arriendo', '🔑'),
            ),
            SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: _buildTransactionTypeOption(TransactionType.ventaArriendo, 'Ambos', '💰🔑'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTypeOption(TransactionType type, String label, String emoji) {
    final isSelected = _transaccionTipo == type;
    
    return GestureDetector(
      onTap: () => setState(() => _transaccionTipo = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dorado : AppTheme.grisOscuro,
          border: Border.all(
            color: isSelected ? AppTheme.dorado : AppTheme.grisClaro,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.negro : AppTheme.blanco,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Características',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.dorado,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Habitaciones',
                icon: Icons.bed,
                value: _numeroHabitaciones,
                onChanged: (val) => setState(() => _numeroHabitaciones = val),
              ),
            ),
            SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: _buildNumberField(
                label: 'Baños',
                icon: Icons.bathroom,
                value: _numeroBanos,
                onChanged: (val) => setState(() => _numeroBanos = val),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSM),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'Parqueaderos',
                icon: Icons.local_parking,
                value: _numeroParqueaderos,
                onChanged: (val) => setState(() => _numeroParqueaderos = val),
              ),
            ),
            SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: _buildNumberField(
                label: 'Estrato',
                icon: Icons.layers,
                value: _estrato,
                onChanged: (val) => setState(() => _estrato = val),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSM),
        _buildTextField(
          controller: _areaController,
          label: 'Área (m²)',
          hint: '85.5',
          icon: Icons.square_foot,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required IconData icon,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.dorado),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.grisClaro),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dorado),
                onPressed: () {
                  if (value != null && value > 0) {
                    onChanged(value - 1);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                value?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blanco,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.dorado),
                onPressed: () {
                  onChanged((value ?? 0) + 1);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrecioFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precios',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.dorado,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        if (_transaccionTipo == TransactionType.venta || 
            _transaccionTipo == TransactionType.ventaArriendo) ...[
          _buildTextField(
            controller: _precioVentaController,
            label: 'Precio de Venta',
            hint: '350000000',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppTheme.spacingSM),
        ],
        if (_transaccionTipo == TransactionType.arriendo || 
            _transaccionTipo == TransactionType.ventaArriendo) ...[
          _buildTextField(
            controller: _precioArriendoController,
            label: 'Precio de Arriendo (mensual)',
            hint: '2500000',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppTheme.spacingSM),
          _buildTextField(
            controller: _administracionController,
            label: 'Administración (mensual)',
            hint: '180000',
            icon: Icons.description,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildPropietarioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Propietario (Opcional)',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.dorado,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacingSM),
        _buildTextField(
          controller: _propietarioNombreController,
          label: 'Nombre',
          hint: 'Nombre del propietario',
          icon: Icons.person,
        ),
        SizedBox(height: AppTheme.spacingSM),
        _buildTextField(
          controller: _propietarioTelefonoController,
          label: 'Teléfono',
          hint: '3001234567',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: AppTheme.spacingSM),
        _buildTextField(
          controller: _propietarioEmailController,
          label: 'Email',
          hint: 'correo@ejemplo.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}
