import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/property_listing.dart';
import '../../services/property_listing_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../config/app_theme.dart';
import '../../utils/currency_formatter.dart';

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
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
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

  // Photo management
  List<String> _photoUrls = [];
  List<String> _photo360Urls = [];
  String? _plano2DUrl;
  String? _plano3DUrl;
  
  // Local file paths (for new photos not yet uploaded)
  List<XFile> _localPhotos = [];
  List<XFile> _localPhotos360 = [];
  XFile? _localPlano2D;
  XFile? _localPlano3D;
  
  bool _isUploadingPhotos = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.listing?.titulo ?? '');
    _direccionController = TextEditingController(text: widget.listing?.direccion ?? '');
    _ciudadController = TextEditingController(text: widget.listing?.ciudad ?? '');
    _barrioController = TextEditingController(text: widget.listing?.barrio ?? '');
    _descripcionController = TextEditingController(text: widget.listing?.descripcion ?? '');
    _areaController = TextEditingController(text: widget.listing?.area?.toString() ?? '');
    // ✅ FIX: Formatear precios con puntos de miles al cargar
    _precioVentaController = TextEditingController(
      text: widget.listing?.precioVenta != null 
        ? formatCurrency(widget.listing!.precioVenta!) 
        : ''
    );
    _precioArriendoController = TextEditingController(
      text: widget.listing?.precioArriendo != null 
        ? formatCurrency(widget.listing!.precioArriendo!) 
        : ''
    );
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
      
      // Load existing photos
      _photoUrls = List<String>.from(widget.listing!.fotos);
      _photo360Urls = List<String>.from(widget.listing!.fotos360);
      _plano2DUrl = widget.listing!.plano2DUrl;
      _plano3DUrl = widget.listing!.plano3DUrl;
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

  // Photo selection methods
  Future<void> _pickRegularPhotos() async {
    // Mostrar opciones: Cámara o Galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Fotos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        // Tomar una foto con la cámara
        final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          setState(() {
            _localPhotos.add(photo);
          });
        }
      } else {
        // Seleccionar múltiples fotos de galería
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _localPhotos.addAll(images);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con fotos: $e')),
        );
      }
    }
  }

  Future<void> _pick360Photos() async {
    // Mostrar opciones: Cámara o Galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Fotos 360°'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto 360°'),
              subtitle: const Text('Panorama manual'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              subtitle: const Text('Fotos 360° existentes'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        // Tomar una foto panorámica con la cámara
        final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          setState(() {
            _localPhotos360.add(photo);
          });
        }
      } else {
        // Seleccionar múltiples fotos 360° de galería
        final List<XFile> images = await _imagePicker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _localPhotos360.addAll(images);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con fotos 360°: $e')),
        );
      }
    }
  }

  Future<void> _pickPlano2D() async {
    // Mostrar opciones: Cámara o Galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Plano 2D'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _localPlano2D = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con plano 2D: $e')),
        );
      }
    }
  }

  Future<void> _pickPlano3D() async {
    // Mostrar opciones: Cámara o Galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Plano 3D'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _localPlano3D = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con plano 3D: $e')),
        );
      }
    }
  }

  // Upload photos to Firebase Storage
  Future<void> _uploadPhotos(String listingId) async {
    setState(() {
      _isUploadingPhotos = true;
      _uploadProgress = 0.0;
    });

    try {
      int totalPhotos = _localPhotos.length + _localPhotos360.length +
          (_localPlano2D != null ? 1 : 0) + (_localPlano3D != null ? 1 : 0);
      int uploadedCount = 0;

      // Upload regular photos
      if (_localPhotos.isNotEmpty) {
        final urls = await _storageService.uploadPropertyListingPhotos(
          listingId: listingId,
          filePaths: _localPhotos.map((f) => f.path).toList(),
          photoType: 'regular',
          onProgress: (current, total) {
            setState(() {
              _uploadProgress = (uploadedCount + current) / totalPhotos;
            });
          },
        );
        _photoUrls.addAll(urls);
        uploadedCount += _localPhotos.length;
      }

      // Upload 360° photos
      if (_localPhotos360.isNotEmpty) {
        final urls = await _storageService.uploadPropertyListingPhotos(
          listingId: listingId,
          filePaths: _localPhotos360.map((f) => f.path).toList(),
          photoType: '360',
          onProgress: (current, total) {
            setState(() {
              _uploadProgress = (uploadedCount + current) / totalPhotos;
            });
          },
        );
        _photo360Urls.addAll(urls);
        uploadedCount += _localPhotos360.length;
      }

      // Upload plano 2D
      if (_localPlano2D != null) {
        final url = await _storageService.uploadPropertyListingPhoto(
          listingId: listingId,
          filePath: _localPlano2D!.path,
          photoType: 'plan2d',
        );
        if (url != null) {
          _plano2DUrl = url;
        }
        uploadedCount++;
        setState(() => _uploadProgress = uploadedCount / totalPhotos);
      }

      // Upload plano 3D
      if (_localPlano3D != null) {
        final url = await _storageService.uploadPropertyListingPhoto(
          listingId: listingId,
          filePath: _localPlano3D!.path,
          photoType: 'plan3d',
        );
        if (url != null) {
          _plano3DUrl = url;
        }
        uploadedCount++;
        setState(() => _uploadProgress = uploadedCount / totalPhotos);
      }

      // Clear local files after upload
      _localPhotos.clear();
      _localPhotos360.clear();
      _localPlano2D = null;
      _localPlano3D = null;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo fotos: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploadingPhotos = false;
        _uploadProgress = 0.0;
      });
    }
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
      // Generate or use existing listing ID
      final listingId = widget.listing?.id ?? const Uuid().v4();

      // Upload photos if there are any local files
      if (_localPhotos.isNotEmpty || _localPhotos360.isNotEmpty || 
          _localPlano2D != null || _localPlano3D != null) {
        await _uploadPhotos(listingId);
      }

      // Create listing object with uploaded photo URLs
      final listing = PropertyListing(
        id: listingId,
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
        fotos: _photoUrls,
        fotos360: _photo360Urls,
        plano2DUrl: _plano2DUrl,
        plano3DUrl: _plano3DUrl,
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

            // Photo management sections
            _buildPhotoSection(
              title: '📷 Fotos del Inmueble',
              description: 'Agrega fotos regulares del inmueble',
              photoCount: _photoUrls.length + _localPhotos.length,
              onAddPressed: _pickRegularPhotos,
              photos: _photoUrls,
              localPhotos: _localPhotos,
              onRemoveUrl: (url) {
                setState(() => _photoUrls.remove(url));
              },
              onRemoveLocal: (file) {
                setState(() => _localPhotos.remove(file));
              },
            ),
            SizedBox(height: AppTheme.spacingMD),

            _buildPhotoSection(
              title: '🌐 Fotos 360°',
              description: 'Agrega fotos panorámicas 360°',
              photoCount: _photo360Urls.length + _localPhotos360.length,
              onAddPressed: _pick360Photos,
              photos: _photo360Urls,
              localPhotos: _localPhotos360,
              onRemoveUrl: (url) {
                setState(() => _photo360Urls.remove(url));
              },
              onRemoveLocal: (file) {
                setState(() => _localPhotos360.remove(file));
              },
            ),
            SizedBox(height: AppTheme.spacingMD),

            _buildSinglePhotoSection(
              title: '📐 Plano 2D',
              description: 'Plano arquitectónico en 2D',
              photoUrl: _plano2DUrl,
              localPhoto: _localPlano2D,
              onAddPressed: _pickPlano2D,
              onRemoveUrl: () {
                setState(() => _plano2DUrl = null);
              },
              onRemoveLocal: () {
                setState(() => _localPlano2D = null);
              },
            ),
            SizedBox(height: AppTheme.spacingMD),

            _buildSinglePhotoSection(
              title: '🏗️ Plano 3D',
              description: 'Modelo arquitectónico en 3D',
              photoUrl: _plano3DUrl,
              localPhoto: _localPlano3D,
              onAddPressed: _pickPlano3D,
              onRemoveUrl: () {
                setState(() => _plano3DUrl = null);
              },
              onRemoveLocal: () {
                setState(() => _localPlano3D = null);
              },
            ),
            SizedBox(height: AppTheme.spacingXL),

            // Upload progress indicator
            if (_isUploadingPhotos)
              Column(
                children: [
                  const Text(
                    'Subiendo fotos...',
                    style: TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppTheme.grisOscuro,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                  ),
                  SizedBox(height: AppTheme.spacingSM),
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppTheme.grisClaro),
                  ),
                  SizedBox(height: AppTheme.spacingXL),
                ],
              ),

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
    List<TextInputFormatter>? inputFormatters,  // ✅ FIX: Agregar soporte para formatters
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.blanco),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,  // ✅ FIX: Aplicar formatters
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
            hint: '350.000.000',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
          ),
          SizedBox(height: AppTheme.spacingSM),
        ],
        if (_transaccionTipo == TransactionType.arriendo || 
            _transaccionTipo == TransactionType.ventaArriendo) ...[
          _buildTextField(
            controller: _precioArriendoController,
            label: 'Precio de Arriendo (mensual)',
            hint: '2.500.000',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
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

  Widget _buildPhotoSection({
    required String title,
    required String description,
    required int photoCount,
    required VoidCallback onAddPressed,
    required List<String> photos,
    required List<XFile> localPhotos,
    required Function(String) onRemoveUrl,
    required Function(XFile) onRemoveLocal,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.dorado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.grisClaro,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.dorado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$photoCount fotos',
                  style: const TextStyle(
                    color: AppTheme.dorado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMD),
          
          // Photo grid
          if (photos.isNotEmpty || localPhotos.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Existing uploaded photos
                ...photos.map((url) => _buildPhotoThumbnail(
                  imageProvider: NetworkImage(url),
                  onRemove: () => onRemoveUrl(url),
                )),
                // Local photos pending upload
                ...localPhotos.map((file) => _buildPhotoThumbnail(
                  imageProvider: FileImage(File(file.path)),
                  onRemove: () => onRemoveLocal(file),
                  isPending: true,
                )),
              ],
            ),
          
          if (photos.isNotEmpty || localPhotos.isNotEmpty)
            SizedBox(height: AppTheme.spacingSM),
          
          // Add button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_photo_alternate, color: AppTheme.dorado),
              label: const Text(
                'Agregar fotos',
                style: TextStyle(color: AppTheme.dorado),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dorado),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePhotoSection({
    required String title,
    required String description,
    required String? photoUrl,
    required XFile? localPhoto,
    required VoidCallback onAddPressed,
    required VoidCallback onRemoveUrl,
    required VoidCallback onRemoveLocal,
  }) {
    final hasPhoto = photoUrl != null || localPhoto != null;
    
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.grisOscuro,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.dorado.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.dorado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.grisClaro,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhoto)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.dorado.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.dorado,
                    size: 16,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMD),
          
          // Photo preview
          if (hasPhoto)
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: AppTheme.dorado),
                      image: DecorationImage(
                        image: photoUrl != null
                            ? NetworkImage(photoUrl) as ImageProvider
                            : FileImage(File(localPhoto!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: photoUrl != null ? onRemoveUrl : onRemoveLocal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (localPhoto != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Pendiente de subir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          if (hasPhoto)
            SizedBox(height: AppTheme.spacingSM),
          
          // Add/Replace button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddPressed,
              icon: Icon(
                hasPhoto ? Icons.swap_horiz : Icons.add_photo_alternate,
                color: AppTheme.dorado,
              ),
              label: Text(
                hasPhoto ? 'Reemplazar' : 'Agregar plano',
                style: const TextStyle(color: AppTheme.dorado),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dorado),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail({
    required ImageProvider imageProvider,
    required VoidCallback onRemove,
    bool isPending = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPending ? Colors.orange : AppTheme.dorado,
              width: 2,
            ),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        if (isPending)
          Positioned(
            bottom: 2,
            left: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Pendiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
