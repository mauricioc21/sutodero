import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../models/inventory_property.dart';
import '../../models/acta_model.dart';
import '../../services/acta_service.dart';
import '../../config/app_theme.dart';

/// Pantalla para crear Acta de Entrega a Arrendatario
class ActaEntregaScreen extends StatefulWidget {
  final InventoryProperty property;

  const ActaEntregaScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<ActaEntregaScreen> createState() => _ActaEntregaScreenState();
}

class _ActaEntregaScreenState extends State<ActaEntregaScreen> {
  final ActaService _actaService = ActaService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _arrendatarioController = TextEditingController();
  final _cedulaRecibeController = TextEditingController();
  final _cedulaEntregaController = TextEditingController();
  
  // Observaciones
  final List<TextEditingController> _observacionesControllers = [];
  
  // Firmas
  final SignatureController _firmaRecibeController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  final SignatureController _firmaEntregaController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Agregar campos iniciales de observaciones
    for (int i = 0; i < 5; i++) {
      _observacionesControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _arrendatarioController.dispose();
    _cedulaRecibeController.dispose();
    _cedulaEntregaController.dispose();
    for (var controller in _observacionesControllers) {
      controller.dispose();
    }
    _firmaRecibeController.dispose();
    _firmaEntregaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.dorado,
              onPrimary: AppTheme.grisOscuro,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveActa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar firmas
    if (_firmaRecibeController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Falta la firma de quien recibe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_firmaEntregaController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Falta la firma de quien entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
          ),
        ),
      );

      // Convertir firmas a base64
      final firmaRecibeData = await _firmaRecibeController.toPngBytes();
      final firmaEntregaData = await _firmaEntregaController.toPngBytes();
      
      final firmaRecibeBase64 = 'data:image/png;base64,${firmaRecibeData != null ? String.fromCharCodes(firmaRecibeData) : ''}';
      final firmaEntregaBase64 = 'data:image/png;base64,${firmaEntregaData != null ? String.fromCharCodes(firmaEntregaData) : ''}';

      // Recopilar observaciones no vacías
      final observaciones = _observacionesControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Crear acta
      final acta = ActaModel(
        id: '',
        propertyId: widget.property.id,
        propertyAddress: widget.property.direccion,
        propertyType: widget.property.tipo.displayName,
        tipoActa: 'entrega',
        arrendatarioNombre: _arrendatarioController.text.trim(),
        arrendatarioCedula: _cedulaRecibeController.text.trim(),
        fecha: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        novedades: observaciones,
        firmaRecibido: firmaRecibeBase64,
        firmaEntrega: firmaEntregaBase64,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _actaService.guardarActa(acta);

      // Cerrar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Acta de Entrega guardada exitosamente'),
            backgroundColor: AppTheme.dorado,
          ),
        );
      }

      // Volver
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error al guardar acta: $e');
      
      // Cerrar loading
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar acta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grisOscuro,
      appBar: AppBar(
        title: const Text(
          'Acta de Entrega a Arrendatario',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.grisOscuro,
          ),
        ),
        backgroundColor: AppTheme.dorado,
        iconTheme: const IconThemeData(color: AppTheme.grisOscuro),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header con logo Century 21
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    'CENTURY 21 INC',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.dorado,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'INVENTARIO ENTREGA DE INMUEBLE',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.blanco,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VIVIENDA',
                            style: TextStyle(fontSize: 12, color: AppTheme.grisClaro),
                          ),
                          Text(
                            widget.property.tipo.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.blanco,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'N° ${widget.property.id.substring(0, 4)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.dorado,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Información del inmueble
            _buildSectionTitle('Información del Inmueble'),
            _buildInfoRow('DIRECCIÓN', widget.property.direccion),
            _buildInfoRow('GARAJE', widget.property.garaje ? 'SÍ' : 'NO'),

            const SizedBox(height: 25),

            // Fecha
            _buildSectionTitle('Fecha'),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.grisOscuro,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dorado),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                        color: AppTheme.blanco,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppTheme.dorado),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Arrendatario
            _buildSectionTitle('Arrendatario'),
            TextFormField(
              controller: _arrendatarioController,
              style: const TextStyle(color: AppTheme.blanco),
              decoration: _inputDecoration('Nombre completo del arrendatario'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),

            const SizedBox(height: 25),

            // Texto del acta
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.dorado, width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTA DE ENTREGA A ARRENDATARIO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dorado,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'El arrendatario conoce y acepta las normas establecidas por el Código de Policía en lo pertinente a la buena convivencia vecinal, especialmente en lo que se refiere al manejo del ruido como instrumento de recreación o laboral destinado al aprendizaje.\n\n'
                    'El arrendatario no aceptará reclamos por pintura de muros, carpintería de ventanas, cerradura para la obtención del contrato de arrendamiento.\n\n'
                    'A partir de la fecha del contrato del arrendamiento, debe iniciar a nuestra oficina los comprobantes y obtenidos.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grisClaro,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Observaciones del inventario
            _buildSectionTitle('Observaciones del Inventario'),
            const Text(
              'Registre aquí las condiciones encontradas en el inmueble',
              style: TextStyle(fontSize: 12, color: AppTheme.grisClaro),
            ),
            const SizedBox(height: 15),
            ..._observacionesControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: entry.value,
                  style: const TextStyle(color: AppTheme.blanco),
                  decoration: _inputDecoration('Observación ${entry.key + 1}'),
                  maxLines: 2,
                ),
              );
            }).toList(),

            const SizedBox(height: 25),

            // Sección de firmas
            _buildSectionTitle('Firmas'),
            
            // Firma Recibe Inmueble
            const Text(
              'RECIBE INMUEBLE:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dorado, width: 2),
              ),
              child: Signature(
                controller: _firmaRecibeController,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cedulaRecibeController,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: _inputDecoration('C.C.'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _firmaRecibeController.clear(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Limpiar'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Firma Entrega Inmueble
            const Text(
              'ENTREGA INMUEBLE:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.dorado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dorado, width: 2),
              ),
              child: Signature(
                controller: _firmaEntregaController,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cedulaEntregaController,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: _inputDecoration('C.C.'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _firmaEntregaController.clear(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Limpiar'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Botón guardar
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveActa,
              icon: const Icon(Icons.save),
              label: const Text(
                'GUARDAR ACTA DE ENTREGA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.negro,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.dorado,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.grisClaro,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.blanco,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.grisClaro),
      filled: true,
      fillColor: AppTheme.grisOscuro,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dorado),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dorado),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.dorado, width: 2),
      ),
    );
  }
}

