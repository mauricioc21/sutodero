import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/role_change_service.dart';
import '../../models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedGenero;
  String? _photoURL;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  Uint8List? _imageBytes;
  String? _imageName;
  UserRole? _selectedRole;
  bool _hasPendingRequest = false;
  bool _isAdminCheckboxSelected = false;
  final _adminCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      _nombreController.text = user.nombre;
      _telefonoController.text = user.telefono;
      _direccionController.text = user.direccion ?? '';
      _emailController.text = user.email;
      _selectedGenero = user.genero ?? user.detectarGenero();
      _photoURL = user.photoURL;
      _selectedRole = user.userRole;
      
      // Verificar si tiene solicitud pendiente
      final hasPending = await roleChangeService.hasPendingRequest(user.uid);
      if (mounted) {
        setState(() {
          _hasPendingRequest = hasPending;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageBytes == null) return null;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) return null;
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');
      
      await ref.putData(_imageBytes!);
      final downloadURL = await ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _verifyAdminCode() async {
    const adminCode = 'SuToderoAdmon2025';
    final enteredCode = _adminCodeController.text.trim();
    
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Por favor ingresa el código de administrador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (enteredCode != adminCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Código incorrecto. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      _adminCodeController.clear();
      return;
    }
    
    // Código correcto, cambiar a administrador
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Actualizar rol en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'rol': 'administrador',
      });
      
      // Actualizar usuario actual en memoria
      final updatedUser = user.copyWith(rol: 'administrador');
      authService.updateCurrentUser(updatedUser);
      
      setState(() {
        _isLoading = false;
        _isAdminCheckboxSelected = false;
        _adminCodeController.clear();
        _selectedRole = UserRole.administrador;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Felicidades! Ahora eres Administrador'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Mostrar diálogo de confirmación
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.grisOscuro,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            title: Row(
              children: [
                Icon(Icons.verified_user, color: AppTheme.dorado, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '¡Rol Actualizado!',
                    style: TextStyle(color: AppTheme.dorado),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Tu rol ha sido actualizado a Administrador.\n\n'
              'Ahora tienes acceso completo a:\n'
              '• Gestionar usuarios\n'
              '• Aprobar solicitudes de rol\n'
              '• Asignar roles a otros usuarios\n'
              '• Todas las funciones administrativas',
              style: TextStyle(color: AppTheme.blanco, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: AppTheme.grisOscuro,
                ),
                child: const Text('ENTENDIDO'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestRoleChange() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null || _selectedRole == null || _selectedRole == user.userRole) return;
    
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text(
          'Solicitar Cambio de Rol',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          '¿Deseas solicitar cambiar tu rol de ${user.userRole.displayName} a ${_selectedRole!.displayName}?\n\nEsta solicitud debe ser aprobada por un administrador.',
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.grisClaro)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado,
              foregroundColor: AppTheme.grisOscuro,
            ),
            child: const Text('SOLICITAR'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    final success = await roleChangeService.createRoleChangeRequest(
      userId: user.uid,
      userName: user.nombre,
      userEmail: user.email,
      currentRole: user.userRole,
      requestedRole: _selectedRole!,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        setState(() => _hasPendingRequest = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(roleChangeService.errorMessage ?? 'Error al enviar solicitud'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) return;
      
      // Subir imagen si hay una nueva
      String? newPhotoURL = _photoURL;
      if (_imageBytes != null) {
        newPhotoURL = await _uploadProfileImage();
      }
      
      // Actualizar perfil en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'nombre': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'genero': _selectedGenero,
        if (newPhotoURL != null) 'photoURL': newPhotoURL,
      });
      
      // Actualizar usuario local
      final updatedUser = currentUser.copyWith(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        genero: _selectedGenero,
        photoURL: newPhotoURL,
      );
      
      authService.updateCurrentUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa ambos campos de contraseña'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.changePassword(_passwordController.text);
      
      if (mounted) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isChangingPassword = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Contraseña cambiada exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar contraseña: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar cambios',
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                  ),
                )
              : SingleChildScrollView(
                  padding: AppTheme.paddingAll,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Foto de perfil
                        _buildProfilePhoto(),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Formulario de datos
                        _buildFormFields(),
                        
                        const SizedBox(height: AppTheme.spacingLarge),
                        
                        // Sección de cambio de contraseña
                        _buildPasswordSection(),
                        
                        const SizedBox(height: AppTheme.spacingXLarge),
                        
                        // Botón guardar
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dorado,
                            foregroundColor: AppTheme.negro,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.dorado,
                width: 3,
              ),
              boxShadow: AppTheme.goldGlow,
            ),
            child: ClipOval(
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    )
                  : _photoURL != null && _photoURL!.isNotEmpty
                      ? Image.network(
                          _photoURL!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.dorado,
                shape: BoxShape.circle,
                boxShadow: AppTheme.goldGlow,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: AppTheme.negro),
                onPressed: _pickImage,
                tooltip: 'Cambiar foto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.grisOscuro,
      child: const Icon(
        Icons.person,
        size: 60,
        color: AppTheme.dorado,
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Información Personal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.dorado,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Nombre
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: const Icon(Icons.person, color: AppTheme.dorado),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Teléfono
          TextFormField(
            controller: _telefonoController,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: const Icon(Icons.phone, color: AppTheme.dorado),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu teléfono';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Dirección
          TextFormField(
            controller: _direccionController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              prefixIcon: const Icon(Icons.location_on, color: AppTheme.dorado),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Género
          DropdownButtonFormField<String>(
            value: _selectedGenero,
            decoration: InputDecoration(
              labelText: 'Género',
              prefixIcon: const Icon(Icons.wc, color: AppTheme.dorado),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGenero = value;
              });
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Email (solo lectura)
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email, color: AppTheme.dorado),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              helperText: 'El correo no se puede modificar',
            ),
            readOnly: true,
            enabled: false,
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Rol del usuario
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: const Icon(Icons.badge, color: AppTheme.dorado),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  helperText: _hasPendingRequest 
                      ? 'Tienes una solicitud pendiente de aprobación'
                      : 'Selecciona un rol diferente para solicitar cambio\n* El rol Administrador solo puede ser asignado por otro Administrador',
                  helperMaxLines: 3,
                  helperStyle: TextStyle(
                    color: _hasPendingRequest ? Colors.orange : AppTheme.grisClaro,
                  ),
                ),
                items: UserRole.values
                    .where((role) => role != UserRole.administrador) // Excluir Administrador
                    .map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: _hasPendingRequest ? null : (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              
              if (_selectedRole != null && 
                  _selectedRole != Provider.of<AuthService>(context, listen: false).currentUser?.userRole &&
                  !_hasPendingRequest) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _requestRoleChange,
                  icon: const Icon(Icons.send),
                  label: const Text('SOLICITAR CAMBIO DE ROL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dorado,
                    foregroundColor: AppTheme.grisOscuro,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              
              // Sección de código de administrador (solo si no es admin)
              if (Provider.of<AuthService>(context, listen: false).currentUser?.userRole != UserRole.administrador) ...[
                const SizedBox(height: 24),
                const Divider(color: AppTheme.grisClaro),
                const SizedBox(height: 16),
                
                // Checkbox "Soy administrador"
                CheckboxListTile(
                  value: _isAdminCheckboxSelected,
                  onChanged: (value) {
                    setState(() {
                      _isAdminCheckboxSelected = value ?? false;
                      if (!_isAdminCheckboxSelected) {
                        _adminCodeController.clear();
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppTheme.dorado, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Soy Administrador',
                        style: TextStyle(
                          color: AppTheme.blanco,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Tengo un código de administrador',
                    style: TextStyle(
                      color: AppTheme.grisClaro,
                      fontSize: 12,
                    ),
                  ),
                  activeColor: AppTheme.dorado,
                  checkColor: AppTheme.grisOscuro,
                  contentPadding: EdgeInsets.zero,
                ),
                
                // Campo de código (aparece cuando se activa el checkbox)
                if (_isAdminCheckboxSelected) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.grisClaro.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.dorado.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock, color: AppTheme.dorado, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Código de Administrador',
                              style: TextStyle(
                                color: AppTheme.dorado,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _adminCodeController,
                          obscureText: true,
                          style: const TextStyle(
                            color: AppTheme.blanco,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ingresa el código secreto',
                            hintStyle: TextStyle(color: AppTheme.grisClaro),
                            prefixIcon: const Icon(Icons.vpn_key, color: AppTheme.dorado),
                            filled: true,
                            fillColor: AppTheme.grisOscuro,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _verifyAdminCode(),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _verifyAdminCode,
                          icon: const Icon(Icons.verified_user),
                          label: const Text('VERIFICAR CÓDIGO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dorado,
                            foregroundColor: AppTheme.grisOscuro,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Este código te dará acceso completo como Administrador',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cambiar Contraseña',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.dorado,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isChangingPassword ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.dorado,
                ),
                onPressed: () {
                  setState(() {
                    _isChangingPassword = !_isChangingPassword;
                  });
                },
              ),
            ],
          ),
          
          if (_isChangingPassword) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Nueva contraseña
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock, color: AppTheme.dorado),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                helperText: 'Mínimo 6 caracteres',
              ),
              obscureText: true,
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Confirmar contraseña
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.dorado),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              obscureText: true,
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Botón cambiar contraseña
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: AppTheme.blanco,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Text('Actualizar Contraseña'),
            ),
          ],
        ],
      ),
    );
  }
}
