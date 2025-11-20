import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'inventory/inventories_screen.dart';
import 'tickets/tickets_screen.dart';
import 'tickets/dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'camera_360/camera_360_capture_screen.dart';
import 'property_listing/property_listings_screen.dart';

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
                color: AppTheme.dorado,
                boxShadow: AppTheme.goldGlow,
              ),
              child: const Icon(
                Icons.handyman,
                color: AppTheme.negro,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('SU TODERO'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _handleLogout(context, authService),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppTheme.paddingAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta de bienvenida con logo
                _buildWelcomeCard(context, authService),
                
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Grid de funcionalidades
                _buildFeaturesGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de bienvenida
  Widget _buildWelcomeCard(BuildContext context, AuthService authService) {
    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
        withShadow: true,
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppTheme.goldGlow,
            ),
            child: Image.asset(
              'assets/images/logo_sutodero_transparente.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.dorado.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.handyman,
                    size: 60,
                    color: AppTheme.dorado,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Saludo personalizado
          Text(
            authService.currentUser?.obtenerSaludoPersonalizado() ?? 
            '¡Bienvenido/a!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.dorado,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingSmall),
          
          // Subtítulo
          Text(
            'Servicios de Reparación y Mantenimiento',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisClaro,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Grid de funcionalidades
  Widget _buildFeaturesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppTheme.spacingMedium,
      crossAxisSpacing: AppTheme.spacingMedium,
      childAspectRatio: 0.95,
      children: [
        _buildFeatureCard(
          context,
          icon: Icons.inventory_2,
          title: 'Inventarios',
          description: 'Gestiona propiedades y espacios',
          iconColor: AppTheme.dorado,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoriesScreen()),
          ),
        ),
        _buildFeatureCard(
          context,
          icon: Icons.home_work,
          title: 'Captación',
          description: 'Inmuebles en venta/arriendo',
          iconColor: const Color(0xFF4CAF50),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyListingsScreen()),
          ),
        ),
        _buildFeatureCard(
          context,
          icon: Icons.build_circle,
          title: 'Tickets',
          description: 'Solicitudes de reparación',
          iconColor: const Color(0xFFFF6B00),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketsScreen()),
          ),
        ),
        _buildFeatureCard(
          context,
          icon: Icons.dashboard,
          title: 'Dashboard',
          description: 'Estadísticas y métricas',
          iconColor: const Color(0xFF9C27B0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          ),
        ),
        _buildFeatureCard(
          context,
          icon: Icons.panorama_photosphere,
          title: 'Captura 360°',
          description: 'Toma fotos panorámicas',
          iconColor: const Color(0xFF2196F3),
          onTap: () {
            // Para HomeScreen necesitamos una propiedad genérica o ir a inventarios
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecciona una propiedad primero desde Inventarios'),
                backgroundColor: AppTheme.warning,
              ),
            );
          },
        ),

        _buildFeatureCard(
          context,
          icon: Icons.architecture,
          title: 'Planos',
          description: 'Genera planos automáticos',
          iconColor: const Color(0xFF4CAF50),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecciona una propiedad primero desde Inventarios'),
                backgroundColor: AppTheme.warning,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Tarjeta de funcionalidad
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: AppTheme.containerDecoration(
            withBorder: false,
          ),
          padding: const EdgeInsets.all(16).copyWith(
            top: AppTheme.spacingLarge,
            bottom: AppTheme.spacingLarge,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con fondo circular
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: iconColor,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingMedium),
              
              // Título
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blanco,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppTheme.spacingSmall),
              
              // Descripción
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisClaro,
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

  /// Manejar cierre de sesión
  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: const Text(
          '¿Estás seguro de cerrar sesión?',
          style: TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.blanco,
            ),
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
  }
}
