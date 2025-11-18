import 'package:flutter/material.dart';
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
  final _direccionController = TextEditingController();
  final _clienteNombreController = TextEditingController();
  final _clienteTelefonoController = TextEditingController();
  final _descripcionController = TextEditingController();
  PropertyType _selectedType = PropertyType.casa;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _direccionController.text = widget.property!.direccion;
      _clienteNombreController.text = widget.property!.clienteNombre ?? '';
      _clienteTelefonoController.text = widget.property!.clienteTelefono ?? '';
      _descripcionController.text = widget.property!.descripcion ?? '';
      _selectedType = widget.property!.tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Propiedad' : 'Nueva Propiedad')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.paddingMD),
          children: [
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            ),
            SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<PropertyType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Propiedad',
                border: OutlineInputBorder(),
              ),
              items: PropertyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text('${type.icon} ${type.displayName}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _clienteNombreController,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _clienteTelefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: AppTheme.spacingXL),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (widget.property != null) {
        final updated = widget.property!.copyWith(
          direccion: _direccionController.text,
          clienteNombre: _clienteNombreController.text.isEmpty ? null : _clienteNombreController.text,
          clienteTelefono: _clienteTelefonoController.text.isEmpty ? null : _clienteTelefonoController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
        );
        await _inventoryService.updateProperty(updated);
      } else {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // ✅ FIX: Esperar a que AuthService termine de cargar el usuario
        // ✅ IMPROVEMENT: Agregar timeout para prevenir loops infinitos
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
          direccion: _direccionController.text,
          clienteNombre: _clienteNombreController.text.isEmpty ? null : _clienteNombreController.text,
          clienteTelefono: _clienteTelefonoController.text.isEmpty ? null : _clienteTelefonoController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
