import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/maestro_profile_service.dart';
import '../../models/maestro_profile_model.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
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
  final _maestroProfileService = MaestroProfileService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cargar credenciales guardadas
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;
      
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          if (rememberMe && savedEmail != null) {
            _emailController.text = savedEmail;
            if (savedPassword != null) {
              _passwordController.text = savedPassword;
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al cargar credenciales: $e');
      }
    }
  }

  // Guardar credenciales
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al guardar credenciales: $e');
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Login con timeout extendido a 45 segundos
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏱️ Tiempo de espera agotado. Verifica tu conexión a internet y vuelve a intentar.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return false;
        },
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (success) {
        // Guardar credenciales si "Recordarme" está activado
        await _saveCredentials();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.errorMessage ?? 'Error al iniciar sesión'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
        color: AppTheme.negro, // Fondo negro puro igual al logo
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
                
                // Logo completo de Su Todero con personaje y texto corporativo
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLG),
                    child: Image.asset(
                      'assets/images/sutodero_login_logo.png',
                      width: MediaQuery.of(context).size.width * 0.85,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback al logo antiguo si hay error
                        return Column(
                          children: [
                            Icon(
                              Icons.handyman,
                              size: 100,
                              color: AppTheme.dorado,
                            ),
                            SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'SU TODERO',
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
                          ],
                        );
                      },
                    ),
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.negro, // Negro sobre botón dorado = alta visibilidad
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Autenticando...',
                                  style: TextStyle(
                                    color: AppTheme.grisOscuro,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.grisClaro.withValues(alpha: 0.3))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                        child: Text(
                          'O',
                          style: TextStyle(color: AppTheme.grisClaro, fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.grisClaro.withValues(alpha: 0.3))),
                    ],
                  ),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  // Botón de ingreso rápido por rol
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showQuickLoginDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.blanco,
                        side: BorderSide(color: AppTheme.dorado.withValues(alpha: 0.5), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                      icon: Icon(Icons.speed, color: AppTheme.dorado, size: 24),
                      label: Text(
                        'INGRESO RÁPIDO POR ROL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppTheme.blanco,
                        ),
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
  
  /// Mostrar diálogo de ingreso rápido por rol
  Future<void> _showQuickLoginDialog() async {
    final selectedRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Row(
                children: [
                  Icon(Icons.speed, color: AppTheme.dorado, size: 28),
                  SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      'Ingreso Rápido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blanco,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spacingSM),
              
              Text(
                'Selecciona un rol para ingresar:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.blanco.withValues(alpha: 0.7),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Lista de roles
              ...UserRole.values.map((role) => Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
                child: _buildRoleOption(role, context),
              )),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                ),
                child: Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: AppTheme.grisClaro,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (selectedRole != null) {
      // Si es maestro, mostrar selector de perfiles
      if (selectedRole == UserRole.maestro) {
        final profile = await _showMaestroProfileSelector();
        if (profile != null) {
          await _handleQuickLogin(selectedRole, maestroId: profile.id, maestroNombre: profile.nombre);
        }
      } else {
        await _handleQuickLogin(selectedRole);
      }
    }
  }
  
  /// Widget de opción de rol
  Widget _buildRoleOption(UserRole role, BuildContext dialogContext) {
    IconData icon;
    Color color;
    
    switch (role) {
      case UserRole.administrador:
        icon = Icons.admin_panel_settings;
        color = Colors.red;
        break;
      case UserRole.coordinador:
        icon = Icons.supervised_user_circle;
        color = Colors.blue;
        break;
      case UserRole.maestro:
        icon = Icons.engineering;
        color = Colors.orange;
        break;
      case UserRole.inventarios:
        icon = Icons.inventory;
        color = Colors.green;
        break;
      case UserRole.cliente:
        icon = Icons.person;
        color = Colors.grey;
        break;
    }
    
    return InkWell(
      onTap: () => Navigator.pop(dialogContext, role),
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.negro,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSM),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Text(
                role.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blanco,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.grisClaro, size: 16),
          ],
        ),
      ),
    );
  }
  
  /// Manejar login rápido
  Future<void> _handleQuickLogin(UserRole role, {String? maestroId, String? maestroNombre}) async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final success = await authService.quickLoginByRole(
        role,
        maestroId: maestroId,
        maestroNombre: maestroNombre,
      );
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Ingreso como ${role.displayName}'),
                ),
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.errorMessage ?? 'Error al iniciar sesión rápida'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Mostrar selector de perfiles de maestros
  Future<MaestroProfileModel?> _showMaestroProfileSelector() async {
    List<MaestroProfileModel> profiles = [];
    
    try {
      if (kDebugMode) {
        debugPrint('🔍 Intentando cargar perfiles de maestros...');
      }
      
      // Intentar cargar perfiles activos con timeout
      profiles = await _maestroProfileService.getActiveMaestroProfiles()
          .timeout(const Duration(seconds: 5))
          .first;
      
      if (kDebugMode) {
        debugPrint('✅ Perfiles cargados: ${profiles.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error al cargar perfiles: $e');
        debugPrint('📝 Usando perfiles predeterminados en memoria...');
      }
      
      // Si hay error (Firebase no disponible), usar perfiles predeterminados en memoria
      final now = DateTime.now();
      profiles = [
        MaestroProfileModel(
          id: 'rodrigo',
          nombre: 'Rodrigo',
          telefono: '3001234567',
          email: 'rodrigo@sutodero.com',
          especialidad: 'Plomería y Electricidad',
          activo: true,
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
        MaestroProfileModel(
          id: 'alexander',
          nombre: 'Alexander',
          telefono: '3007654321',
          email: 'alexander@sutodero.com',
          especialidad: 'Carpintería y Albañilería',
          activo: true,
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
      ];
    }
    
    if (!mounted) return null;
    
    // Si después de intentar cargar no hay perfiles, crear los predeterminados
    if (profiles.isEmpty) {
      if (kDebugMode) {
        debugPrint('📝 No hay perfiles. Intentando crear perfiles predeterminados...');
      }
      
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              color: AppTheme.grisOscuro,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
                ),
                SizedBox(height: AppTheme.spacingMD),
                Text(
                  'Inicializando perfiles de maestros...',
                  style: TextStyle(color: AppTheme.blanco),
                ),
              ],
            ),
          ),
        ),
      );
      
      try {
        // Inicializar perfiles predeterminados
        final success = await _maestroProfileService.initializeDefaultProfiles()
            .timeout(const Duration(seconds: 10));
        
        if (!mounted) return null;
        
        // Cerrar diálogo de carga
        Navigator.of(context).pop();
        
        if (success) {
          // Recargar perfiles
          profiles = await _maestroProfileService.getActiveMaestroProfiles().first;
          
          if (kDebugMode) {
            debugPrint('✅ Perfiles creados y recargados: ${profiles.length}');
          }
        }
      } catch (e) {
        if (!mounted) return null;
        
        if (kDebugMode) {
          debugPrint('⚠️ Error al crear perfiles en Firebase: $e');
        }
        
        // Cerrar diálogo de carga si está abierto
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        // Usar perfiles en memoria como fallback
        final now = DateTime.now();
        profiles = [
          MaestroProfileModel(
            id: 'rodrigo',
            nombre: 'Rodrigo',
            telefono: '3001234567',
            email: 'rodrigo@sutodero.com',
            especialidad: 'Plomería y Electricidad',
            activo: true,
            fechaCreacion: now,
            fechaActualizacion: now,
          ),
          MaestroProfileModel(
            id: 'alexander',
            nombre: 'Alexander',
            telefono: '3007654321',
            email: 'alexander@sutodero.com',
            especialidad: 'Carpintería y Albañilería',
            activo: true,
            fechaCreacion: now,
            fechaActualizacion: now,
          ),
        ];
      }
    }
    
    if (!mounted) return null;
    
    // Si todavía no hay perfiles después de todos los intentos
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No se pudieron cargar los perfiles de maestros.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return null;
    }
    
    return await showDialog<MaestroProfileModel>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Row(
                children: [
                  Icon(Icons.engineering, color: AppTheme.dorado, size: 28),
                  SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      'Selecciona tu perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blanco,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spacingSM),
              
              Text(
                'Elige el maestro con el que deseas ingresar:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.blanco.withValues(alpha: 0.7),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXL),
              
              // Lista de perfiles
              ...profiles.map((profile) => Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingMD),
                child: _buildMaestroProfileOption(profile, context),
              )),
              
              SizedBox(height: AppTheme.spacingMD),
              
              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                ),
                child: Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: AppTheme.grisClaro,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Widget de opción de perfil de maestro
  Widget _buildMaestroProfileOption(MaestroProfileModel profile, BuildContext dialogContext) {
    return InkWell(
      onTap: () => Navigator.pop(dialogContext, profile),
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.negro,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.dorado.withValues(alpha: 0.2),
              child: Text(
                profile.nombre[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dorado,
                ),
              ),
            ),
            
            SizedBox(width: AppTheme.spacingMD),
            
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.blanco,
                    ),
                  ),
                  
                  if (profile.especialidad != null) ...[
                    SizedBox(height: 4),
                    Text(
                      profile.especialidad!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.dorado,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios, color: AppTheme.grisClaro, size: 16),
          ],
        ),
      ),
    );
  }
}
