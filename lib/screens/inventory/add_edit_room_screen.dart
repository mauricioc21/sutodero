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
  final _anchoController = TextEditingController();
  final _largoController = TextEditingController();
  final _alturaController = TextEditingController();
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
      _anchoController.text = widget.room!.ancho?.toString() ?? '';
      _largoController.text = widget.room!.largo?.toString() ?? '';
      _alturaController.text = widget.room!.altura?.toString() ?? '';
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
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _anchoController.dispose();
    _largoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  /// Calcula el área en m² (ancho × largo)
  double? get _areaCalculada {
    final ancho = double.tryParse(_anchoController.text);
    final largo = double.tryParse(_largoController.text);
    if (ancho != null && largo != null && ancho > 0 && largo > 0) {
      return ancho * largo;
    }
    return null;
  }

  /// Calcula el volumen en m³ (ancho × largo × altura)
  double? get _volumenCalculado {
    final ancho = double.tryParse(_anchoController.text);
    final largo = double.tryParse(_largoController.text);
    final altura = double.tryParse(_alturaController.text);
    if (ancho != null && largo != null && altura != null && 
        ancho > 0 && largo > 0 && altura > 0) {
      return ancho * largo * altura;
    }
    return null;
  }

  /// Calcula el área de piso en m² (ancho × largo)
  /// Útil para calcular materiales de piso (cerámica, madera, etc.)
  double? get _areaPisoCalculada {
    final ancho = double.tryParse(_anchoController.text);
    final largo = double.tryParse(_largoController.text);
    if (ancho != null && largo != null && ancho > 0 && largo > 0) {
      return ancho * largo;
    }
    return null;
  }

  /// Calcula el área de paredes y techo en m²
  /// Fórmula: 2(ancho × altura) + 2(largo × altura) + (ancho × largo)
  /// Útil para calcular pintura o revestimientos
  double? get _areaParedesCalculada {
    final ancho = double.tryParse(_anchoController.text);
    final largo = double.tryParse(_largoController.text);
    final altura = double.tryParse(_alturaController.text);
    if (ancho != null && largo != null && altura != null &&
        ancho > 0 && largo > 0 && altura > 0) {
      // Dos paredes anchas + dos paredes largas + techo
      final paredAncha = 2 * (ancho * altura);
      final paredLarga = 2 * (largo * altura);
      final techo = ancho * largo;
      
      return paredAncha + paredLarga + techo;
    }
    return null;
  }

  /// Valida que las dimensiones estén en rangos razonables
  String? _validarDimension(String? value, String dimensionName, {double min = 0.1, double max = 50.0}) {
    if (value == null || value.isEmpty) {
      return null; // Las dimensiones son opcionales
    }
    
    final dimension = double.tryParse(value);
    if (dimension == null) {
      return 'Ingresa un número válido';
    }
    
    if (dimension <= 0) {
      return '$dimensionName debe ser mayor a 0';
    }
    
    if (dimension < min) {
      return '$dimensionName muy pequeño (mín: ${min}m)';
    }
    
    if (dimension > max) {
      return '⚠️ $dimensionName inusual (máx: ${max}m). ¿Estás seguro?';
    }
    
    return null;
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
            
            // Sección de DIMENSIONES
            const Divider(thickness: 2),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '📏 Dimensiones del Espacio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa las medidas en metros para generar planos precisos',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anchoController,
                    decoration: const InputDecoration(
                      labelText: 'Ancho (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.swap_horiz),
                      hintText: 'Ej: 3.5',
                      helperText: 'Rango: 0.1m - 50m',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validarDimension(v, 'Ancho'),
                    onChanged: (_) => setState(() {}), // Para actualizar el área
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _largoController,
                    decoration: const InputDecoration(
                      labelText: 'Largo (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.swap_vert),
                      hintText: 'Ej: 4.2',
                      helperText: 'Rango: 0.1m - 50m',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validarDimension(v, 'Largo'),
                    onChanged: (_) => setState(() {}), // Para actualizar el área
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _alturaController,
                    decoration: const InputDecoration(
                      labelText: 'Altura (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                      hintText: 'Ej: 2.7',
                      helperText: 'Rango: 1.8m - 10m',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validarDimension(v, 'Altura', min: 1.8, max: 10.0),
                    onChanged: (_) => setState(() {}), // Para actualizar el volumen
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Área calculada',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _areaCalculada != null
                              ? '${_areaCalculada!.toStringAsFixed(2)} m²'
                              : '-- m²',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _areaCalculada != null ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Volumen calculado (si hay altura)
            if (_volumenCalculado != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.view_in_ar, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Text(
                          'Volumen (espacio 3D)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${_volumenCalculado!.toStringAsFixed(2)} m³',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Área de piso (para calcular materiales)
            if (_areaPisoCalculada != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_on, color: Colors.orange),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Área de piso',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Material de piso (cerámica, madera, etc.)',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${_areaPisoCalculada!.toStringAsFixed(2)} m²',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            if (_areaPisoCalculada != null)
              const SizedBox(height: 16),
            
            // Área de paredes y techo (para pintura)
            if (_areaParedesCalculada != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_paint, color: Colors.green),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Área paredes + techo',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pintura y revestimientos',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${_areaParedesCalculada!.toStringAsFixed(2)} m²',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
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
      final ancho = _anchoController.text.isEmpty ? null : double.tryParse(_anchoController.text);
      final largo = _largoController.text.isEmpty ? null : double.tryParse(_largoController.text);
      final altura = _alturaController.text.isEmpty ? null : double.tryParse(_alturaController.text);
      
      if (widget.room != null) {
        final updated = widget.room!.copyWith(
          nombre: _nombreController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
          estado: _selectedCondition,
          ancho: ancho,
          largo: largo,
          altura: altura,
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
          ancho: ancho,
          largo: largo,
          altura: altura,
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
