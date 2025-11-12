import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Logo del maestro todero con efecto moderno de resplandor
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Resplandor dorado suave y difuso
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        // Segundo nivel de resplandor más intenso
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          blurRadius: 100,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/maestro_todero_nobg.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.handyman,
                            size: 100,
                            color: Color(0xFFFFD700),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                  const SizedBox(height: 24),
                  
                  const Text(
                    'SU TODERO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Servicios de Reparación y Mantenimiento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Accede a tu cuenta',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Correo Electrónico',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.email, color: Color(0xFFFFD700)),
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
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFD700)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
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
                          return 'Ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Checkbox "Recordarme"
                  Row(
                    children: [
                      Theme(
                        data: ThemeData(
                          checkboxTheme: CheckboxThemeData(
                            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFFFD700);
                              }
                              return Colors.transparent;
                            }),
                            checkColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
                            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                          ),
                        ),
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? true);
                          },
                        ),
                      ),
                      const Text(
                        'Recordarme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF2C2C2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[700])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[700])),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  OutlinedButton(
                    onPressed: _navigateToRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                  
                  const SizedBox(height: 32),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo'),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
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
    );
  }
}
