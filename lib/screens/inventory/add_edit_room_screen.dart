import 'package:flutter/material.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../models/room_features.dart';
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
  
  // Nuevos campos opcionales de características
  FloorType? _tipoPiso;
  KitchenType? _tipoCocina;
  CountertopMaterial? _materialMeson;
  BathroomType? _tipoBano;
  BathroomFinish? _acabadoBano;
  ClosetType? _tipoCloset;
  ViewType? _vista;
  NaturalLighting? _iluminacionNatural;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nombreController.text = widget.room!.nombre;
      _descripcionController.text = widget.room!.descripcion ?? '';
      _selectedType = widget.room!.tipo;
      _selectedCondition = widget.room!.estado;
      _tipoPiso = widget.room!.tipoPiso;
      _tipoCocina = widget.room!.tipoCocina;
      _materialMeson = widget.room!.materialMeson;
      _tipoBano = widget.room!.tipoBano;
      _acabadoBano = widget.room!.acabadoBano;
      _tipoCloset = widget.room!.tipoCloset;
      _vista = widget.room!.vista;
      _iluminacionNatural = widget.room!.iluminacionNatural;
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
            
            // Sección de características detalladas
            const Divider(thickness: 2),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Características Detalladas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de piso (para todos los espacios)
            DropdownButtonFormField<FloorType>(
              value: _tipoPiso,
              decoration: const InputDecoration(
                labelText: 'Tipo de Piso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.view_module),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No especificado')),
                ...FloorType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
              ],
              onChanged: (v) => setState(() => _tipoPiso = v),
            ),
            const SizedBox(height: 16),
            
            // Campos específicos para COCINAS
            if (_selectedType == RoomType.cocina) ...[
              DropdownButtonFormField<KitchenType>(
                value: _tipoCocina,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cocina',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.kitchen),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...KitchenType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _tipoCocina = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CountertopMaterial>(
                value: _materialMeson,
                decoration: const InputDecoration(
                  labelText: 'Material del Mesón',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.countertops),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...CountertopMaterial.values.map((material) {
                    return DropdownMenuItem(
                      value: material,
                      child: Text(material.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _materialMeson = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Campos específicos para BAÑOS
            if (_selectedType == RoomType.bano) ...[
              DropdownButtonFormField<BathroomType>(
                value: _tipoBano,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Baño',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bathroom),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...BathroomType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _tipoBano = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BathroomFinish>(
                value: _acabadoBano,
                decoration: const InputDecoration(
                  labelText: 'Acabado del Baño',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.texture),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...BathroomFinish.values.map((finish) {
                    return DropdownMenuItem(
                      value: finish,
                      child: Text(finish.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _acabadoBano = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Tipo de closet (principalmente para dormitorios, pero disponible para todos)
            if (_selectedType == RoomType.dormitorio || _selectedType == RoomType.estudio) ...[
              DropdownButtonFormField<ClosetType>(
                value: _tipoCloset,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Closet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.door_sliding),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...ClosetType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _tipoCloset = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Vista (para espacios con ventanas)
            if (_selectedType != RoomType.bodega && _selectedType != RoomType.pasillo) ...[
              DropdownButtonFormField<ViewType>(
                value: _vista,
                decoration: const InputDecoration(
                  labelText: 'Vista',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No especificado')),
                  ...ViewType.values.map((view) {
                    return DropdownMenuItem(
                      value: view,
                      child: Text(view.displayName),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _vista = v),
              ),
              const SizedBox(height: 16),
            ],
            
            // Iluminación natural (para todos los espacios)
            DropdownButtonFormField<NaturalLighting>(
              value: _iluminacionNatural,
              decoration: const InputDecoration(
                labelText: 'Iluminación Natural',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wb_sunny),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No especificado')),
                ...NaturalLighting.values.map((lighting) {
                  return DropdownMenuItem(
                    value: lighting,
                    child: Text(lighting.displayName),
                  );
                }).toList(),
              ],
              onChanged: (v) => setState(() => _iluminacionNatural = v),
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
          tipoPiso: _tipoPiso,
          tipoCocina: _tipoCocina,
          materialMeson: _materialMeson,
          tipoBano: _tipoBano,
          acabadoBano: _acabadoBano,
          tipoCloset: _tipoCloset,
          vista: _vista,
          iluminacionNatural: _iluminacionNatural,
        );
        await _inventoryService.updateRoom(updated);
      } else {
        // Para crear necesitamos actualizar el modelo después de la creación
        final room = await _inventoryService.createRoom(
          propertyId: widget.propertyId,
          nombre: _nombreController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
          estado: _selectedCondition,
        );
        // Actualizar con los campos adicionales
        final updated = room.copyWith(
          tipoPiso: _tipoPiso,
          tipoCocina: _tipoCocina,
          materialMeson: _materialMeson,
          tipoBano: _tipoBano,
          acabadoBano: _acabadoBano,
          tipoCloset: _tipoCloset,
          vista: _vista,
          iluminacionNatural: _iluminacionNatural,
        );
        await _inventoryService.updateRoom(updated);
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
