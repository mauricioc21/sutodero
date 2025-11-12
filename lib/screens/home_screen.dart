import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'inventory/inventories_screen.dart';
import 'tickets/tickets_screen.dart';
import 'tickets/dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'qr/qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
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
        actions: [
          // Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro de cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de bienvenida
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6C8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo_sutodero_transparente.png',
                        height: 150, // Reducido de 200 a 150 para evitar overflow
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.handyman,
                            size: 80, // Reducido de 100 a 80
                            color: Color(0xFFFFD700),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        authService.currentUser?.obtenerSaludoPersonalizado() ?? 
                        '¡Bienvenido/a!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                  childAspectRatio: 1.0, // Ajustado de 0.85 a 1.0 para evitar overflow
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
                      icon: Icons.build_circle,
                      title: 'Tickets',
                      description: 'Solicitudes de reparación',
                      color: const Color(0xFFFF6B00),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TicketsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      description: 'Estadísticas y métricas',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.panorama_photosphere,
                      title: 'Captura 360°',
                      description: 'Toma fotos panorámicas',
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo'),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.qr_code_scanner,
                      title: 'Escanear QR',
                      description: 'Escanea códigos QR',
                      color: const Color(0xFF9C27B0), // Púrpura
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      icon: Icons.architecture,
                      title: 'Planos',
                      description: 'Genera planos automáticos',
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo'),
                          ),
                        );
                      },
                    ),
                  ],
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6C8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
