import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/inventory/inventories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SuToderoApp());
}

class SuToderoApp extends StatelessWidget {
  const SuToderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SU TODERO',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700), // Amarillo dorado
          primary: const Color(0xFFFFD700),
          secondary: const Color(0xFFFF6B00), // Naranja
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Color(0xFF2C2C2C), // Gris oscuro
          foregroundColor: Color(0xFFFFD700), // Amarillo dorado
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF2C2C2C),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    
    // Navegar a la pantalla principal después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2C), // Gris oscuro
              Color(0xFF1A1A1A), // Negro
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Imagen del maestro todero con sombra
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/maestro_todero_nobg.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2C2C2C),
                                child: const Icon(
                                  Icons.handyman,
                                  size: 120,
                                  color: Color(0xFFFFD700),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Logo de texto
                        const Text(
                          'SU TODERO',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Eslogan
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'No existe reparación, mantenimiento\no remodelación que no hagamos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Indicador de carga
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    strokeWidth: 3,
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.handyman,
                color: Color(0xFF2C2C2C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SU TODERO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de bienvenida
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_sutodero_nobg.png',
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
                        const SizedBox(height: 20),
                        const Text(
                          '¡Bienvenido a SU TODERO!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tu solución profesional para gestión de inventarios, tickets de reparación y captura 360°',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Grid de funcionalidades
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildFeatureCard(
                      context,
                      icon: Icons.inventory_2,
                      title: 'Inventarios',
                      description: 'Gestiona propiedades y espacios',
                      color: const Color(0xFFFFD700),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoriesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.build,
                      title: 'Tickets',
                      description: 'Reparación y mantenimiento',
                      color: const Color(0xFFFF6B00),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Módulo de Tickets - Próximamente'),
                            backgroundColor: Color(0xFFFF6B00),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.camera_alt,
                      title: 'Captura 360°',
                      description: 'Fotos y videos remotos',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Captura 360° - Próximamente'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.apartment,
                      title: 'Planos',
                      description: 'Generación automática',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generación de Planos - Próximamente'),
                            backgroundColor: Color(0xFF2196F3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Información de contacto
                Card(
                  color: const Color(0xFF2C2C2C),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 48,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Soporte y Contacto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(
                          icon: Icons.email,
                          text: 'info@c21sutodero.com',
                        ),
                        const SizedBox(height: 8),
                        _buildContactRow(
                          icon: Icons.phone,
                          text: '+57 313 816 0439',
                        ),
                      ],
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

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
