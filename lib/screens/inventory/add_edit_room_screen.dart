import 'package:flutter/material.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../services/inventory_service.dart';

class AddEditRoomScreen extends StatefulWidget {
  final String propertyId;
  final PropertyRoom? room;
  const AddEditRoomScreen({super.key, required this.propertyId, this.room});
  
  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  RoomType _selectedType = RoomType.otro;
  SpaceCondition _selectedCondition = SpaceCondition.bueno;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nombreController.text = widget.room!.nombre;
      _descripcionController.text = widget.room!.descripcion ?? '';
      _selectedType = widget.room!.tipo;
      _selectedCondition = widget.room!.estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.room != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Espacio' : 'Nuevo Espacio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Espacio *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoomType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Espacio',
                border: OutlineInputBorder(),
              ),
              items: RoomType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text('${type.icon} ${type.displayName}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SpaceCondition>(
              value: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: SpaceCondition.values.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text('${condition.emoji} ${condition.displayName}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCondition = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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
      if (widget.room != null) {
        final updated = widget.room!.copyWith(
          nombre: _nombreController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
          estado: _selectedCondition,
        );
        await _inventoryService.updateRoom(updated);
      } else {
        await _inventoryService.createRoom(
          propertyId: widget.propertyId,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
          estado: _selectedCondition,
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
