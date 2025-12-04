import 'package:flutter/material.dart';
import '../../services/empleado_service.dart';
import '../../config/app_theme.dart';

class AddEmpleadoScreen extends StatefulWidget {
  final String cargoPreseleccionado;
  final String nombreCargo;

  const AddEmpleadoScreen({
    super.key,
    required this.cargoPreseleccionado,
    required this.nombreCargo,
  });

  @override
  State<AddEmpleadoScreen> createState() => _AddEmpleadoScreenState();
}

class _AddEmpleadoScreenState extends State<AddEmpleadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmpleadoService _empleadoService = EmpleadoService();
  
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _notasController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _saveEmpleado() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _empleadoService.createEmpleado(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        cargo: widget.cargoPreseleccionado,
        notas: _notasController.text.trim().isEmpty 
            ? null 
            : _notasController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${widget.nombreCargo} agregado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text('Agregar ${widget.nombreCargo}'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y título
              Icon(
                Icons.person_add,
                size: 60,
                color: AppTheme.dorado,
              ),
              SizedBox(height: AppTheme.spacingMD),
              
              Text(
                'Nuevo ${widget.nombreCargo}',
                style: const TextStyle(
                  color: AppTheme.dorado,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.spacingSM),
              
              Text(
                'Completa la información del empleado',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Nombre
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo *',
                  labelStyle: const TextStyle(color: AppTheme.dorado),
                  hintText: 'Ej: Juan Pérez',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.person, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.dorado),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Correo
              TextFormField(
                controller: _correoController,
                style: const TextStyle(color: AppTheme.blanco),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico *',
                  labelStyle: const TextStyle(color: AppTheme.dorado),
                  hintText: 'ejemplo@correo.com',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.email, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.dorado),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el correo';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Teléfono
              TextFormField(
                controller: _telefonoController,
                style: const TextStyle(color: AppTheme.blanco),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono *',
                  labelStyle: const TextStyle(color: AppTheme.dorado),
                  hintText: '+57 300 123 4567',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.dorado),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el teléfono';
                  }
                  if (value.length < 7) {
                    return 'Ingresa un teléfono válido';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Cargo (solo lectura)
              TextFormField(
                initialValue: widget.nombreCargo,
                enabled: false,
                style: TextStyle(color: Colors.grey[600]),
                decoration: InputDecoration(
                  labelText: 'Cargo',
                  labelStyle: const TextStyle(color: AppTheme.dorado),
                  prefixIcon: const Icon(Icons.work, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Notas (opcional)
              TextFormField(
                controller: _notasController,
                style: const TextStyle(color: AppTheme.blanco),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notas (Opcional)',
                  labelStyle: const TextStyle(color: AppTheme.dorado),
                  hintText: 'Información adicional sobre el empleado...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.note, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.dorado),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Botón guardar
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveEmpleado,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.grisOscuro,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'GUARDANDO...' : 'GUARDAR EMPLEADO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.grisOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
