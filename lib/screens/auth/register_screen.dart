import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import 'biometric_registration_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.maestro; // Rol por defecto
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.register(
      _nombreController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _telefonoController.text.trim(),
      _selectedRole, // Pasar el rol seleccionado
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Preguntar si desea activar reconocimiento facial
      _showBiometricOptionDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'Error al crear cuenta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBiometricOptionDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      // Si no hay usuario, navegar al login
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            Icon(Icons.face, color: AppTheme.dorado, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reconocimiento Facial',
                style: TextStyle(color: AppTheme.blanco, fontSize: 20),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas activar el reconocimiento facial para ingresar con más facilidad sin tener que ingresar tus datos cada vez?',
          style: TextStyle(color: AppTheme.blanco, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver al login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Cuenta creada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'AHORA NO',
              style: TextStyle(color: AppTheme.grisClaro),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BiometricRegistrationScreen(
                    userId: user.uid,
                    userName: user.nombre,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.face),
            label: const Text('SÍ, ACTIVAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado,
              foregroundColor: AppTheme.grisOscuro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingMD),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.dorado),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                    vertical: AppTheme.spacingLG,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo pequeño
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              boxShadow: AppTheme.goldGlow,
                            ),
                            child: Image.asset(
                              'assets/images/maestro_todero_nobg.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.handyman,
                                  size: 60,
                                  color: AppTheme.dorado,
                                );
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXL),
                        
                        // Título
                        Text(
                          'CREAR CUENTA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blanco,
                            letterSpacing: 1,
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingSM),
                        
                        // Subtexto
                        Text(
                          'Regístrate para comenzar',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.blanco.withValues(alpha: 0.6),
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXL),
                
                // Campo de nombre completo
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Nombre Completo',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFFAB334)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu nombre completo';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMD),
                
                // Campo de correo electrónico
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Correo Electrónico',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFFFAB334)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu correo electrónico';
                      }
                      if (!value.contains('@')) {
                        return 'Correo electrónico inválido';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMD),
                
                // Campo de teléfono
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Teléfono',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFFFAB334)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu teléfono';
                      }
                      if (value.length < 7) {
                        return 'Teléfono inválido';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMD),
                
                // Selector de Rol
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    dropdownColor: AppTheme.grisOscuro,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Rol de Usuario',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.badge, color: Color(0xFFFAB334)),
                      helperText: '* El rol Administrador solo puede ser asignado por otro Administrador',
                      helperMaxLines: 2,
                      helperStyle: TextStyle(color: AppTheme.grisClaro, fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    items: UserRole.values
                        .where((role) => role != UserRole.administrador) // Excluir Administrador
                        .map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(
                          role.displayName,
                          style: const TextStyle(color: AppTheme.blanco),
                        ),
                      );
                    }).toList(),
                    onChanged: (UserRole? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFAB334)),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMD),
                
                // Campo de contraseña
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFFAB334)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.grisClaro,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMD),
                
                // Campo de confirmar contraseña
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.grisOscuro,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: AppTheme.blanco),
                    decoration: InputDecoration(
                      hintText: 'Confirmar Contraseña',
                      hintStyle: TextStyle(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFAB334)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.grisClaro,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXL),
                
                // Botón de crear cuenta
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dorado,
                      foregroundColor: AppTheme.grisOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2C2C2C),
                              ),
                            ),
                          )
                        : const Text(
                            'CREAR CUENTA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Términos y condiciones
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Al crear una cuenta, aceptas nuestros Términos y Condiciones y Política de Privacidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grisClaro,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                      ],
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
