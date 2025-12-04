import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_property.dart';
import '../../services/inventory_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final InventoryProperty? property;
  const AddEditPropertyScreen({super.key, this.property});
  
  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  
  // Controladores de texto
  late TextEditingController _paisController;
  late TextEditingController _ciudadController;
  late TextEditingController _municipioController;
  late TextEditingController _barrioController;
  late TextEditingController _direccionController;
  late TextEditingController _numeroInteriorController;
  late TextEditingController _areaController;
  late TextEditingController _areaLoteController;
  late TextEditingController _codigoInternoController;
  late TextEditingController _clienteNombreController;
  late TextEditingController _clienteTelefonoController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioAlquilerController;
  late TextEditingController _nombreAgenteController;
  late TextEditingController _numeroDocumentoController;
  
  PropertyType _selectedType = PropertyType.apartamento;
  String _tipoDocumento = 'C.C.'; // Tipo de documento por defecto
  int? _numeroNiveles;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con valores existentes o vacíos
    _paisController = TextEditingController(text: widget.property?.pais ?? 'CO');
    _ciudadController = TextEditingController(text: widget.property?.ciudad ?? '');
    _municipioController = TextEditingController(text: widget.property?.municipio ?? '');
    _barrioController = TextEditingController(text: widget.property?.barrio ?? '');
    _direccionController = TextEditingController(text: widget.property?.direccion ?? '');
    _numeroInteriorController = TextEditingController(text: widget.property?.numeroInterior ?? '');
    _areaController = TextEditingController(text: widget.property?.area?.toString() ?? '');
    _areaLoteController = TextEditingController(text: widget.property?.areaLote?.toString() ?? '');
    _codigoInternoController = TextEditingController(text: widget.property?.codigoInterno ?? '');
    _clienteNombreController = TextEditingController(text: widget.property?.clienteNombre ?? '');
    _clienteTelefonoController = TextEditingController(text: widget.property?.clienteTelefono ?? '');
    _descripcionController = TextEditingController(text: widget.property?.descripcion ?? '');
    _precioAlquilerController = TextEditingController(text: widget.property?.precioAlquilerDeseado?.toString() ?? '');
    _nombreAgenteController = TextEditingController(text: widget.property?.nombreAgente ?? '');
    _numeroDocumentoController = TextEditingController(text: widget.property?.numeroDocumento ?? '');
    
    if (widget.property != null) {
      _selectedType = widget.property!.tipo;
      _numeroNiveles = widget.property!.numeroNiveles;
      _tipoDocumento = widget.property!.tipoDocumento ?? 'C.C.';
    }
  }

  @override
  void dispose() {
    _paisController.dispose();
    _ciudadController.dispose();
    _municipioController.dispose();
    _barrioController.dispose();
    _direccionController.dispose();
    _numeroInteriorController.dispose();
    _areaController.dispose();
    _areaLoteController.dispose();
    _codigoInternoController.dispose();
    _clienteNombreController.dispose();
    _clienteTelefonoController.dispose();
    _descripcionController.dispose();
    _precioAlquilerController.dispose();
    _nombreAgenteController.dispose();
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;
    
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text(isEdit ? 'Actualizar información' : 'Nueva Propiedad'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          children: [
            // Sección: Datos del inmueble
            const Text(
              'Datos del inmueble',
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),
            const Text(
              'Información básica',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.grisClaro,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // País
            _buildTextField(
              controller: _paisController,
              label: 'País *',
              hint: 'CO',
              icon: Icons.flag,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa el país' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Ciudad
            _buildTextField(
              controller: _ciudadController,
              label: 'Ciudad *',
              hint: 'Bogotá',
              icon: Icons.location_city,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa la ciudad' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Municipio
            _buildTextField(
              controller: _municipioController,
              label: 'Municipio/Departamento',
              hint: 'Mosquera, Cundinamarca',
              icon: Icons.place,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Barrio/Colonia
            _buildTextField(
              controller: _barrioController,
              label: 'Barrio/Colonia *',
              hint: 'Castilla',
              icon: Icons.map,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa el barrio' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Dirección completa
            _buildTextField(
              controller: _direccionController,
              label: 'Dirección completa *',
              hint: 'KENNEDY_C797_92025',
              icon: Icons.location_on,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa la dirección' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Número de casa, apto, etc (opcional)
            _buildTextField(
              controller: _numeroInteriorController,
              label: 'Número de casa, apto, etc (opcional)',
              hint: 'apto 350 interior 9A',
              icon: Icons.numbers,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // ¿Cuántos niveles tiene?
            _buildNumberField(
              label: '¿Cuántos niveles tiene? *',
              icon: Icons.layers,
              value: _numeroNiveles,
              onChanged: (val) => setState(() => _numeroNiveles = val),
              isRequired: true,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Título de sección: Tipo de inmueble
            const Text(
              'Tipo de inmueble',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Tipo de propiedad
            _buildDropdown(
              label: 'Tipo de propiedad *',
              value: _selectedType,
              items: PropertyType.values.where((t) => t != PropertyType.otro).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Área construida
            _buildTextField(
              controller: _areaController,
              label: 'Área construida *',
              hint: '61',
              icon: Icons.square_foot,
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Ingresa el área construida' : null,
              suffixText: 'm²',
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Área lote (opcional)
            _buildTextField(
              controller: _areaLoteController,
              label: 'Área lote (opcional)',
              hint: '0',
              icon: Icons.landscape,
              keyboardType: TextInputType.number,
              suffixText: 'm²',
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Código interno (opcional)
            _buildTextField(
              controller: _codigoInternoController,
              label: 'Código interno (opcional)',
              hint: 'KENNEDY_C797_92025',
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Este código pertenece a la Agencia inmobiliaria',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grisClaro,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingXL),
            
            // Información del cliente (opcional)
            const Text(
              'Información del Cliente (Opcional)',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacingSM),
            _buildTextField(
              controller: _clienteNombreController,
              label: 'Nombre del Cliente',
              hint: 'Nombre completo',
              icon: Icons.person,
            ),
            SizedBox(height: AppTheme.spacingSM),
            _buildTextField(
              controller: _clienteTelefonoController,
              label: 'Teléfono',
              hint: '3001234567',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Documento de identidad
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de tipo de documento
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.grisOscuro,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.grisClaro.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tipoDocumento,
                        dropdownColor: AppTheme.grisOscuro,
                        style: const TextStyle(color: AppTheme.blanco),
                        items: ['C.C.', 'C.E.', 'NIT'].map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _tipoDocumento = value!);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Campo de número de documento
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _numeroDocumentoController,
                    label: 'Número de documento',
                    hint: '1234567890',
                    icon: Icons.badge,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMD),
            
            // Precio de alquiler deseado
            _buildTextField(
              controller: _precioAlquilerController,
              label: 'Precio de alquiler deseado',
              hint: '1500000',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: AppTheme.spacingSM),
            
            // Nombre del agente
            _buildTextField(
              controller: _nombreAgenteController,
              label: 'Nombre del Agente',
              hint: 'Nombre del agente inmobiliario',
              icon: Icons.work,
            ),
            SizedBox(height: AppTheme.spacingXL),
            
            // Botón Continuar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: AppTheme.negro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.negro),
                        ),
                      )
                    : const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            
            // Botón Eliminar propiedad (solo en modo edición)
            if (isEdit) ...[
              SizedBox(height: AppTheme.spacingMD),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _deleteProperty,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                  child: const Text(
                    'Eliminar propiedad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
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
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.blanco),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.dorado),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.dorado) : null,
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: AppTheme.grisClaro),
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
    required PropertyType value,
    required List<PropertyType> items,
    required Function(PropertyType?) onChanged,
  }) {
    return DropdownButtonFormField<PropertyType>(
      value: value,
      dropdownColor: AppTheme.grisOscuro,
      style: const TextStyle(color: AppTheme.blanco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.dorado),
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
      items: items.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text('${type.icon} ${type.displayName}'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField({
    required String label,
    required IconData icon,
    required int? value,
    required Function(int?) onChanged,
    bool isRequired = false,
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
            style: TextStyle(
              fontSize: 12, 
              color: AppTheme.grisClaro,
              fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar número de niveles
    if (_numeroNiveles == null || _numeroNiveles! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, indica cuántos niveles tiene la propiedad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      if (widget.property != null) {
        // Actualizar propiedad existente
        final updated = widget.property!.copyWith(
          pais: _paisController.text.trim(),
          ciudad: _ciudadController.text.trim(),
          municipio: _municipioController.text.trim().isNotEmpty 
              ? _municipioController.text.trim() : null,
          barrio: _barrioController.text.trim(),
          direccion: _direccionController.text.trim(),
          numeroNiveles: _numeroNiveles,
          numeroInterior: _numeroInteriorController.text.trim().isNotEmpty 
              ? _numeroInteriorController.text.trim() : null,
          tipo: _selectedType,
          area: double.tryParse(_areaController.text),
          areaLote: double.tryParse(_areaLoteController.text),
          codigoInterno: _codigoInternoController.text.trim().isNotEmpty 
              ? _codigoInternoController.text.trim() : null,
          clienteNombre: _clienteNombreController.text.trim().isNotEmpty 
              ? _clienteNombreController.text.trim() : null,
          clienteTelefono: _clienteTelefonoController.text.trim().isNotEmpty 
              ? _clienteTelefonoController.text.trim() : null,
          precioAlquilerDeseado: double.tryParse(_precioAlquilerController.text),
          nombreAgente: _nombreAgenteController.text.trim().isNotEmpty 
              ? _nombreAgenteController.text.trim() : null,
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim().isNotEmpty 
              ? _numeroDocumentoController.text.trim() : null,
        );
        await _inventoryService.updateProperty(updated);
      } else {
        // Crear nueva propiedad
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Esperar a que AuthService termine de cargar el usuario
        int attempts = 0;
        const maxAttempts = 50; // 5 segundos (50 * 100ms)
        
        while (authService.isLoading && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
        
        if (attempts >= maxAttempts) {
          throw Exception('Timeout: No se pudo cargar la información del usuario. Por favor, reinicia la aplicación.');
        }
        
        final user = authService.currentUser;
        if (user == null) {
          throw Exception('Por favor, inicia sesión nuevamente para crear inventarios');
        }
        
        await _inventoryService.createProperty(
          userId: user.uid,
          pais: _paisController.text.trim(),
          ciudad: _ciudadController.text.trim(),
          municipio: _municipioController.text.trim().isNotEmpty 
              ? _municipioController.text.trim() : null,
          barrio: _barrioController.text.trim(),
          direccion: _direccionController.text.trim(),
          numeroNiveles: _numeroNiveles,
          numeroInterior: _numeroInteriorController.text.trim().isNotEmpty 
              ? _numeroInteriorController.text.trim() : null,
          tipo: _selectedType,
          area: double.tryParse(_areaController.text),
          areaLote: double.tryParse(_areaLoteController.text),
          codigoInterno: _codigoInternoController.text.trim().isNotEmpty 
              ? _codigoInternoController.text.trim() : null,
          clienteNombre: _clienteNombreController.text.trim().isNotEmpty 
              ? _clienteNombreController.text.trim() : null,
          clienteTelefono: _clienteTelefonoController.text.trim().isNotEmpty 
              ? _clienteTelefonoController.text.trim() : null,
          precioAlquilerDeseado: double.tryParse(_precioAlquilerController.text),
          nombreAgente: _nombreAgenteController.text.trim().isNotEmpty 
              ? _nombreAgenteController.text.trim() : null,
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim().isNotEmpty 
              ? _numeroDocumentoController.text.trim() : null,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.property == null 
                  ? '✅ Propiedad creada exitosamente'
                  : '✅ Propiedad actualizada exitosamente'
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProperty() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          '¿Eliminar propiedad?',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Estás seguro?',
          style: TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.grisClaro)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirm != true || widget.property == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      await _inventoryService.deleteProperty(widget.property!.id);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Propiedad eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
