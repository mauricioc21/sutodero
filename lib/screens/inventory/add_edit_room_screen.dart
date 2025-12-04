import 'dart:convert';
import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_room.dart';
import '../../models/inventory_property.dart';
import '../../models/room_features.dart';
import '../../models/room_item.dart';
import '../../services/inventory_service.dart';
import '../../config/app_theme.dart';

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
  final _nivelController = TextEditingController();
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
  
  // Lista de items/elementos del inventario
  List<RoomItem> _items = [];
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nombreController.text = widget.room!.nombre;
      _descripcionController.text = widget.room!.descripcion ?? '';
      _anchoController.text = widget.room!.ancho?.toString() ?? '';
      _largoController.text = widget.room!.largo?.toString() ?? '';
      _alturaController.text = widget.room!.altura?.toString() ?? '';
      _nivelController.text = widget.room!.nivel ?? '';
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
      _items = List.from(widget.room!.items);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _anchoController.dispose();
    _largoController.dispose();
    _alturaController.dispose();
    _nivelController.dispose();
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
              controller: _nivelController,
              decoration: const InputDecoration(
                labelText: 'Nivel (opcional)',
                hintText: 'Ej: Nivel 1, Nivel 2, Sótano, Ático',
                border: OutlineInputBorder(),
              ),
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
            
            // 📋 SECCIÓN DE ELEMENTOS/ITEMS DEL INVENTARIO
            _buildItemsSection(),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.negro,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Actualizar Espacio' : 'Guardar Espacio'),
            ),
          ],
        ),
      ),
    );
  }

  /// Sincroniza las fotos de los elementos con las fotos del espacio
  Future<void> _syncElementPhotosToRoom(String roomId) async {
    try {
      // Obtener el room actualizado
      final room = await _inventoryService.getRoom(roomId);
      if (room == null) return;
      
      // Obtener todas las fotos de todos los elementos
      final Set<String> elementPhotos = {};
      for (final item in _items) {
        elementPhotos.addAll(item.fotos);
      }
      
      // Obtener fotos actuales del espacio
      final Set<String> currentRoomPhotos = Set.from(room.fotos);
      
      // Agregar solo las fotos que no están ya en el espacio
      final photosToAdd = elementPhotos.difference(currentRoomPhotos);
      
      // Agregar cada foto nueva al espacio
      for (final photo in photosToAdd) {
        await _inventoryService.addRoomPhoto(roomId, photo);
      }
    } catch (e) {
      // Silenciosamente fallar, no interrumpir el guardado del espacio
      debugPrint('⚠️ Error al sincronizar fotos de elementos: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final ancho = _anchoController.text.isEmpty ? null : double.tryParse(_anchoController.text);
      final largo = _largoController.text.isEmpty ? null : double.tryParse(_largoController.text);
      final altura = _alturaController.text.isEmpty ? null : double.tryParse(_alturaController.text);
      final nivel = _nivelController.text.isEmpty ? null : _nivelController.text;
      
      if (widget.room != null) {
        final updated = widget.room!.copyWith(
          nombre: _nombreController.text,
          descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          tipo: _selectedType,
          estado: _selectedCondition,
          ancho: ancho,
          largo: largo,
          altura: altura,
          nivel: nivel,
          tipoPiso: _tipoPiso,
          tipoCocina: _tipoCocina,
          materialMeson: _materialMeson,
          tipoBano: _tipoBano,
          acabadoBano: _acabadoBano,
          tipoCloset: _tipoCloset,
          vista: _vista,
          iluminacionNatural: _iluminacionNatural,
          items: _items,
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
          nivel: nivel,
          tipoPiso: _tipoPiso,
          tipoCocina: _tipoCocina,
          materialMeson: _materialMeson,
          tipoBano: _tipoBano,
          acabadoBano: _acabadoBano,
          tipoCloset: _tipoCloset,
          vista: _vista,
          iluminacionNatural: _iluminacionNatural,
          items: _items,
        );
        await _inventoryService.updateRoom(updated);
        
        // Agregar fotos de elementos a las fotos del espacio
        await _syncElementPhotosToRoom(updated.id);
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

  // 📋 SECCIÓN DE ELEMENTOS/ITEMS DEL INVENTARIO
  Widget _buildItemsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dorado.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: AppTheme.dorado, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Elementos del Inventario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dorado,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.dorado.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_items.length} ${_items.length == 1 ? 'elemento' : 'elementos'}',
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra cada elemento con su cantidad, material y estado',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grisClaro,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de items
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.negro.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grisClaro.withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No hay elementos registrados',
                    style: TextStyle(color: AppTheme.grisClaro),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Agrega pisos, paredes, puertas, etc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(item, index);
            }).toList(),
          
          const SizedBox(height: 16),
          
          // Botón agregar elemento
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(),
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.dorado),
              label: const Text(
                'Agregar Elemento',
                style: TextStyle(color: AppTheme.dorado),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dorado, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(RoomItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.negro.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grisClaro.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cantidad badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dorado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.cantidad}x',
                  style: const TextStyle(
                    color: AppTheme.negro,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Nombre del elemento
              Expanded(
                child: Text(
                  item.nombreElemento.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blanco,
                  ),
                ),
              ),
              
              // Estado emoji
              Text(
                item.estado.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              
              // Botones de acción
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: AppTheme.dorado),
                onPressed: () => _showEditItemDialog(item, index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Material
          Row(
            children: [
              const Icon(Icons.category, size: 14, color: AppTheme.grisClaro),
              const SizedBox(width: 4),
              Text(
                'Material: ${item.nombreMaterial}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.grisClaro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Estado
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: AppTheme.grisClaro),
              const SizedBox(width: 4),
              Text(
                'Estado: ${item.estado.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.grisClaro,
                ),
              ),
            ],
          ),
          
          // Comentarios si existen
          if (item.comentarios != null && item.comentarios!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 14, color: AppTheme.dorado),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.comentarios!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.blanco,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper para construir widget de imagen según tipo de ruta
  Widget _buildImagePreview(String imagePath, {double? width, double? height}) {
    // Data URL (base64) - usado en web
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[800],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }
    
    // URL (http/https) - network image
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
    
    // Fallback para path local
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog(null, null);
  }

  void _showEditItemDialog(RoomItem item, int index) {
    _showItemDialog(item, index);
  }

  void _showItemDialog(RoomItem? existingItem, int? index) {
    final cantidadController = TextEditingController(
      text: existingItem?.cantidad.toString() ?? '1',
    );
    final comentariosController = TextEditingController(
      text: existingItem?.comentarios ?? '',
    );
    final nombrePersonalizadoController = TextEditingController(
      text: existingItem?.nombrePersonalizado ?? '',
    );
    final materialPersonalizadoController = TextEditingController(
      text: existingItem?.materialPersonalizado ?? '',
    );
    
    ItemType selectedTipo = existingItem?.tipo ?? ItemType.pisos;
    MaterialType selectedMaterial = existingItem?.material ?? MaterialType.concreto;
    ItemCondition selectedEstado = existingItem?.estado ?? ItemCondition.bueno;
    List<String> elementoFotos = List<String>.from(existingItem?.fotos ?? []);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.grisOscuro,
            title: Text(
              existingItem == null ? 'Agregar Elemento' : 'Editar Elemento',
              style: const TextStyle(color: AppTheme.dorado),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cantidad
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      labelText: 'Cantidad *',
                      labelStyle: const TextStyle(color: AppTheme.dorado),
                      prefixIcon: const Icon(Icons.numbers, color: AppTheme.dorado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dorado),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tipo de elemento
                  DropdownButtonFormField<ItemType>(
                    value: selectedTipo,
                    dropdownColor: AppTheme.negro,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      labelText: 'Tipo de Elemento *',
                      labelStyle: const TextStyle(color: AppTheme.dorado),
                      prefixIcon: const Icon(Icons.category, color: AppTheme.dorado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dorado),
                      ),
                    ),
                    items: ItemType.values.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.displayName),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedTipo = v);
                      }
                    },
                  ),
                  
                  // Campo personalizado si es "Otro"
                  if (selectedTipo == ItemType.otro) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombrePersonalizadoController,
                      style: const TextStyle(color: AppTheme.blanco),
                      decoration: InputDecoration(
                        labelText: 'Especificar elemento',
                        labelStyle: const TextStyle(color: AppTheme.dorado),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.dorado),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Material
                  DropdownButtonFormField<MaterialType>(
                    value: selectedMaterial,
                    dropdownColor: AppTheme.negro,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      labelText: 'Material *',
                      labelStyle: const TextStyle(color: AppTheme.dorado),
                      prefixIcon: const Icon(Icons.texture, color: AppTheme.dorado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dorado),
                      ),
                    ),
                    items: MaterialType.values.map((material) {
                      return DropdownMenuItem(
                        value: material,
                        child: Text(material.displayName),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedMaterial = v);
                      }
                    },
                  ),
                  
                  // Campo personalizado de material si es "Otro"
                  if (selectedMaterial == MaterialType.otro) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: materialPersonalizadoController,
                      style: const TextStyle(color: AppTheme.blanco),
                      decoration: InputDecoration(
                        labelText: 'Especificar material',
                        labelStyle: const TextStyle(color: AppTheme.dorado),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.dorado),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Estado
                  DropdownButtonFormField<ItemCondition>(
                    value: selectedEstado,
                    dropdownColor: AppTheme.negro,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      labelText: 'Estado *',
                      labelStyle: const TextStyle(color: AppTheme.dorado),
                      prefixIcon: const Icon(Icons.check_circle, color: AppTheme.dorado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dorado),
                      ),
                    ),
                    items: ItemCondition.values.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text('${estado.emoji} ${estado.displayName}'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedEstado = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Comentarios
                  TextField(
                    controller: comentariosController,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      labelText: 'Comentarios (opcional)',
                      labelStyle: const TextStyle(color: AppTheme.dorado),
                      prefixIcon: const Icon(Icons.comment, color: AppTheme.dorado),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.dorado),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón Agregar fotografía
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFiles = await picker.pickMultiImage();
                      
                      if (pickedFiles.isNotEmpty) {
                        // Convertir imágenes a data URL (base64) para compatibilidad web
                        for (var file in pickedFiles) {
                          try {
                            final bytes = await file.readAsBytes();
                            final base64String = base64Encode(bytes);
                            final mimeType = file.path.endsWith('.png') ? 'image/png' : 'image/jpeg';
                            final dataUrl = 'data:$mimeType;base64,$base64String';
                            
                            setDialogState(() {
                              elementoFotos.add(dataUrl);
                            });
                          } catch (e) {
                            print('Error al procesar imagen: $e');
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate, color: AppTheme.dorado),
                    label: Text(
                      'Agregar fotografía ${elementoFotos.isEmpty ? '' : '(${elementoFotos.length})'}',
                      style: const TextStyle(color: AppTheme.dorado),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.dorado, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  
                  // Vista previa de fotos del elemento
                  if (elementoFotos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: elementoFotos.length,
                        itemBuilder: (context, fotoIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImagePreview(
                                    elementoFotos[fotoIndex],
                                    width: 80,
                                    height: 80,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        elementoFotos.removeAt(fotoIndex);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.grisClaro)),
              ),
              ElevatedButton(
                onPressed: () {
                  final cantidad = int.tryParse(cantidadController.text) ?? 1;
                  
                  final item = RoomItem(
                    id: existingItem?.id ?? _uuid.v4(),
                    roomId: widget.room?.id ?? '',
                    cantidad: cantidad,
                    tipo: selectedTipo,
                    nombrePersonalizado: selectedTipo == ItemType.otro 
                        ? nombrePersonalizadoController.text.trim() 
                        : null,
                    material: selectedMaterial,
                    materialPersonalizado: selectedMaterial == MaterialType.otro 
                        ? materialPersonalizadoController.text.trim() 
                        : null,
                    estado: selectedEstado,
                    comentarios: comentariosController.text.trim().isEmpty 
                        ? null 
                        : comentariosController.text.trim(),
                    fotos: elementoFotos,
                  );
                  
                  setState(() {
                    if (index != null) {
                      _items[index] = item;
                    } else {
                      _items.add(item);
                    }
                  });
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: AppTheme.negro,
                ),
                child: Text(existingItem == null ? 'Agregar' : 'Actualizar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          '¿Eliminar elemento?',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.grisClaro)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
