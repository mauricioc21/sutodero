import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/activity_log_service.dart';
import '../../config/app_theme.dart';
import '../auth/login_screen.dart';

/// Pantalla de perfil de usuario con edición completa
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
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  final _activityLog = ActivityLogService();
  
  bool _isLoading = false;
  String? _profileImageUrl;

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
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      setState(() {
        _nombreController.text = user.nombre;
        _telefonoController.text = user.telefono;
        _direccionController.text = user.direccion ?? '';
        _profileImageUrl = user.photoUrl;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.updateProfile(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        photoUrl: _profileImageUrl,
      );

      if (mounted) {
        // Log activity
        if (authService.currentUser != null) {
          _activityLog.logActivity(
            userId: authService.currentUser!.uid,
            type: ActivityType.other,
            action: 'Actualizó su perfil de usuario',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar perfil: $e'),
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

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  labelStyle: const TextStyle(color: AppTheme.grisClaro),
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.dorado),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  labelStyle: const TextStyle(color: AppTheme.grisClaro),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.dorado),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  labelStyle: const TextStyle(color: AppTheme.grisClaro),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.dorado),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: const BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.grisClaro)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Las contraseñas no coinciden'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado,
              foregroundColor: AppTheme.negro,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Contraseña cambiada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Log activity
          if (authService.currentUser != null) {
            _activityLog.logActivity(
              userId: authService.currentUser!.uid,
              type: ActivityType.other,
              action: 'Cambió su contraseña',
            );
          }
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
  }

  Future<void> _changeProfilePhoto() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Cambiar Foto de Perfil',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.dorado),
              title: const Text('Tomar Foto', style: TextStyle(color: AppTheme.blanco)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.dorado),
              title: const Text('Galería', style: TextStyle(color: AppTheme.blanco)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        setState(() => _isLoading = true);

        final XFile? photo = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
        );

        if (photo != null && mounted) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final userId = authService.currentUser?.uid;

          if (userId != null) {
            if (kDebugMode) {
              debugPrint('📸 Subiendo foto de perfil para usuario: $userId');
              debugPrint('📁 Ruta del archivo: ${photo.path}');
            }
            
            // Subir foto a Storage
            final photoUrl = await _storageService.uploadProfilePhoto(
              userId: userId,
              filePath: photo.path,
            );

            if (photoUrl != null && mounted) {
              if (kDebugMode) {
                debugPrint('✅ Foto subida exitosamente: $photoUrl');
              }
              
              // Actualizar en el estado local
              setState(() {
                _profileImageUrl = photoUrl;
              });
              
              // Guardar en AuthService y Firestore
              final success = await authService.updateProfile(
                photoUrl: photoUrl,
              );
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Foto de perfil actualizada'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Foto subida pero no se guardó en perfil'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Error al subir foto'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al cambiar foto: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isLoadingAuth = authService.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
      ),
      body: isLoadingAuth
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.dorado),
                  SizedBox(height: 16),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(color: AppTheme.blanco),
                  ),
                ],
              ),
            )
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: AppTheme.grisClaro,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay usuario autenticado',
                        style: TextStyle(color: AppTheme.blanco),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dorado,
                          foregroundColor: AppTheme.negro,
                        ),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.paddingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.dorado, width: 3),
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImageUrl == null
                                ? Center(
                                    child: Text(
                                      user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.dorado,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeProfilePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.dorado,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppTheme.negro,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppTheme.spacingXL),

                    // Email (no editable)
                    Container(
                      padding: EdgeInsets.all(AppTheme.paddingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.grisOscuro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: AppTheme.dorado),
                          SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    color: AppTheme.grisClaro,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: AppTheme.blanco,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppTheme.spacingMD),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: AppTheme.blanco),
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        labelStyle: const TextStyle(color: AppTheme.grisClaro),
                        prefixIcon: const Icon(Icons.person, color: AppTheme.dorado),
                        filled: true,
                        fillColor: AppTheme.grisOscuro,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu nombre';
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
                        labelText: 'Teléfono',
                        labelStyle: const TextStyle(color: AppTheme.grisClaro),
                        prefixIcon: const Icon(Icons.phone, color: AppTheme.dorado),
                        filled: true,
                        fillColor: AppTheme.grisOscuro,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu teléfono';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: AppTheme.spacingMD),

                    // Dirección
                    TextFormField(
                      controller: _direccionController,
                      style: const TextStyle(color: AppTheme.blanco),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        labelStyle: const TextStyle(color: AppTheme.grisClaro),
                        prefixIcon: const Icon(Icons.home, color: AppTheme.dorado),
                        filled: true,
                        fillColor: AppTheme.grisOscuro,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: AppTheme.spacingXL),

                    // Botón Guardar
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dorado,
                        foregroundColor: AppTheme.negro,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.negro),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Guardando...' : 'GUARDAR CAMBIOS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    SizedBox(height: AppTheme.spacingMD),

                    // Botón Cambiar Contraseña
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _changePassword,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dorado,
                        side: const BorderSide(color: AppTheme.dorado, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                      icon: const Icon(Icons.lock),
                      label: const Text(
                        'CAMBIAR CONTRASEÑA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    SizedBox(height: AppTheme.spacing2XL),

                    // Información adicional
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.safeBottomPadding),
                      child: Container(
                      padding: EdgeInsets.all(AppTheme.paddingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.grisOscuro,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de la Cuenta',
                            style: TextStyle(
                              color: AppTheme.dorado,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMD),
                          _buildInfoRow('Rol', user.rol.toUpperCase()),
                          _buildInfoRow('ID de Usuario', user.uid.substring(0, 12) + '...'),
                          if (user.fechaCreacion != null)
                            _buildInfoRow(
                              'Miembro desde',
                              '${user.fechaCreacion!.day}/${user.fechaCreacion!.month}/${user.fechaCreacion!.year}',
                            ),
                        ],
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.grisClaro,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.blanco,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
