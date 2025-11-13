import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/face_recognition_service.dart';
import '../../config/app_theme.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true; // Por defecto activado
  final _faceRecognitionService = FaceRecognitionService();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  /// Login con reconocimiento facial
  Future<void> _handleFacialLogin() async {
    try {
      setState(() => _isLoading = true);
      
      // Mostrar diálogo de instrucciones
      if (!mounted) return;
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.grisOscuro,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          title: Row(
            children: [
              Icon(Icons.face, color: AppTheme.dorado, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Reconocimiento Facial',
                style: TextStyle(color: AppTheme.blanco, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Instrucciones:',
                style: TextStyle(
                  color: AppTheme.blanco,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionRow('Busca buena iluminación'),
              _buildInstructionRow('Mira de frente a la cámara'),
              _buildInstructionRow('Mantén expresión neutral'),
              _buildInstructionRow('No uses gafas de sol'),
            ],
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
              child: const Text('CONTINUAR'),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) {
        setState(() => _isLoading = false);
        return;
      }

      // Solicitar permiso y capturar foto
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Mostrar progreso
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.grisOscuro,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.dorado),
                SizedBox(height: AppTheme.spacingLG),
                const Text(
                  'Procesando rostro...',
                  style: TextStyle(color: AppTheme.blanco, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );

      // Autenticar con reconocimiento facial
      final userId = await _faceRecognitionService.authenticateWithFace(
        imagePath: photo.path,
      );

      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);

      if (userId != null && mounted) {
        // Login exitoso con reconocimiento facial
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Autenticar usando el userId reconocido
        final success = await authService.loginWithUserId(userId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Reconocimiento facial exitoso'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al autenticar usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No se reconoció el rostro. Por favor, intenta de nuevo o usa tu contraseña.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Cerrar cualquier diálogo abierto
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
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

  Widget _buildInstructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppTheme.dorado, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.blanco, fontSize: 14),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacing2XL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                SizedBox(height: AppTheme.spacingLG),
                
                // Logo del maestro todero con efecto moderno de resplandor
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.goldGlow,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/maestro_todero_nobg.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.handyman,
                            size: 100,
                            color: AppTheme.dorado,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                  SizedBox(height: AppTheme.spacingXL),
                  
                  Text(
                    'SU TODERO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dorado,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingSM),
                  
                  Text(
                    'Servicios de Reparación y Mantenimiento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.blanco.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacing3XL),
                  
                  Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blanco,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingSM),
                  
                  Text(
                    'Accede a tu cuenta',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.blanco.withValues(alpha: 0.6),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  Container(
                    decoration: AppTheme.containerDecoration(
                      color: AppTheme.grisOscuro,
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppTheme.blanco),
                      decoration: InputDecoration(
                        hintText: 'Correo Electrónico',
                        hintStyle: TextStyle(color: AppTheme.grisClaro),
                        prefixIcon: Icon(Icons.email, color: AppTheme.dorado),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLG,
                          vertical: AppTheme.spacingMD,
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
                  
                  Container(
                    decoration: AppTheme.containerDecoration(
                      color: AppTheme.grisOscuro,
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: AppTheme.blanco),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(color: AppTheme.grisClaro),
                        prefixIcon: Icon(Icons.lock, color: AppTheme.dorado),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLG,
                          vertical: AppTheme.spacingMD,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingMD),
                  
                  // Checkbox "Recordarme"
                  Row(
                    children: [
                      Theme(
                        data: ThemeData(
                          checkboxTheme: CheckboxThemeData(
                            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppTheme.dorado;
                              }
                              return Colors.transparent;
                            }),
                            checkColor: WidgetStateProperty.all(AppTheme.grisOscuro),
                            side: BorderSide(color: AppTheme.dorado, width: 2),
                          ),
                        ),
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? true);
                          },
                        ),
                      ),
                      Text(
                        'Recordarme',
                        style: TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppTheme.spacingMD),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dorado,
                        foregroundColor: AppTheme.grisOscuro,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.grisOscuro,
                                ),
                              ),
                            )
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.grisClaro)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                        child: Text(
                          'O',
                          style: TextStyle(
                            color: AppTheme.grisClaro,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.grisClaro)),
                    ],
                  ),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  // Botón de reconocimiento facial
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleFacialLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dorado,
                        side: BorderSide(color: AppTheme.dorado, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        backgroundColor: AppTheme.negro,
                      ),
                      icon: const Icon(Icons.face, size: 28),
                      label: const Text(
                        'RECONOCIMIENTO FACIAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingMD),
                  
                  OutlinedButton(
                    onPressed: _navigateToRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dorado,
                      side: BorderSide(color: AppTheme.dorado, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                    ),
                    child: const Text(
                      'CREAR CUENTA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo'),
                          ),
                        );
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: AppTheme.dorado,
                          fontSize: 14,
                        ),
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
}
