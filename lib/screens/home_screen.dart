import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/role_change_service.dart';
import 'inventory/inventories_screen.dart';
import 'tickets/tickets_screen.dart';
import 'tickets/my_assigned_tickets_screen.dart';
import 'tickets/dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'property_listing/property_listings_screen.dart';
import 'profile/user_profile_screen.dart';
import 'admin/role_requests_screen.dart';
import 'admin/manage_maestro_profiles_screen.dart';
import 'camera_360/camera_360_capture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingRequestsCount();
  }

  Future<void> _loadPendingRequestsCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    // Solo cargar para administradores
    if (user != null && user.hasAdminAccess) {
      final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
      final count = await roleChangeService.getPendingRequestsCount();
      if (mounted) {
        setState(() {
          _pendingRequestsCount = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
          ),
        ),
        title: Image.asset(
          'assets/images/logo_sutodero_transparente.png',
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('SU TODERO');
          },
        ),
        centerTitle: true,
        actions: [
          // Badge de solicitudes pendientes (solo para administradores)
          if (authService.currentUser?.hasAdminAccess == true)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: 'Solicitudes de Rol',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleRequestsScreen()),
                      );
                      // Recargar contador después de ver solicitudes
                      _loadPendingRequestsCount();
                    },
                  ),
                  if (_pendingRequestsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _pendingRequestsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _handleLogout(context, authService),
            ),
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
    final user = authService.currentUser;
    final genero = user?.detectarGenero() ?? 'neutro';
    final primerNombre = user?.nombre.split(' ').first ?? 'Usuario';
    
    String saludo;
    if (genero == 'masculino') {
      saludo = '¡Bienvenido $primerNombre!';
    } else if (genero == 'femenino') {
      saludo = '¡Bienvenida $primerNombre!';
    } else {
      saludo = '¡Bienvenido/a $primerNombre!';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.containerDecoration(
        color: AppTheme.grisOscuro,
        withBorder: true,
        withShadow: true,
      ),
      child: Column(
        children: [
          // Saludo personalizado más compacto
          Text(
            saludo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.dorado,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Subtítulo más pequeño
          Text(
            'Servicios de Reparación y Mantenimiento',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grisClaro,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Grid de funcionalidades
  Widget _buildFeaturesGrid(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        
        // DEBUG: Verificar usuario
        if (kDebugMode) {
          debugPrint('🏠 HomeScreen - Usuario: ${user?.nombre}');
          debugPrint('🏠 Rol: ${user?.rol}');
          debugPrint('🏠 isCliente: ${user?.isCliente}');
          debugPrint('🏠 isMaestro: ${user?.isMaestro}');
          debugPrint('🏠 hasAdminAccess: ${user?.hasAdminAccess}');
        }
        
        final isMaestro = user?.isMaestro ?? false;
        
        // Lista de opciones disponibles según el rol
        final List<Widget> features = [];
        
        // ❌ Dashboard - SOLO para administradores y coordinadores (NO para clientes)
        if (user?.hasAdminAccess == true && !user!.isCliente) {
          features.add(_buildWideFeatureCard(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            description: 'Estadísticas y métricas',
            iconColor: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ));
          features.add(const SizedBox(height: AppTheme.spacingMedium));
          
          // ❌ Gestión de Perfiles de Maestros - SOLO administradores (NO para clientes)
          features.add(_buildWideFeatureCard(
            context,
            icon: Icons.engineering,
            title: 'Perfiles de Maestros',
            description: 'Gestiona los perfiles de Rodrigo y Alexander',
            iconColor: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMaestroProfilesScreen()),
            ),
          ));
          features.add(const SizedBox(height: AppTheme.spacingMedium));
        }
        
        // Grid de opciones
        final List<Widget> gridItems = [];
        
        // ✅ TICKETS - DISPONIBLE PARA TODOS (clientes, coordinadores, administradores)
        // Los clientes pueden crear y ver sus tickets
        // Los administradores pueden gestionar todos los tickets
        if (user != null && !isMaestro) {
          if (kDebugMode) {
            debugPrint('✅ Agregando Tickets para: ${user.nombre}');
          }
          
          gridItems.add(_buildFeatureCard(
            context,
            icon: Icons.build_circle,
            title: 'Tickets',
            description: user.hasAdminAccess 
                ? 'Gestiona todas las solicitudes'
                : 'Crea y consulta tus solicitudes',
            iconColor: const Color(0xFFFF6B00),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TicketsScreen()),
            ),
          ));
        }
        
        // ✅ CAPTURA 360° - DISPONIBLE PARA USUARIOS REGISTRADOS (clientes, coordinadores, administradores)
        if (user != null && !isMaestro) {
          if (kDebugMode) {
            debugPrint('✅ Agregando Captura 360° para: ${user.nombre}');
          }
          
          gridItems.add(_buildFeatureCard(
            context,
            icon: Icons.panorama_photosphere,
            title: 'Captura 360°',
            description: 'Toma fotos panorámicas',
            iconColor: const Color(0xFF2196F3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Camera360CaptureScreen(),
                ),
              );
            },
          ));
        }
        
        // ❌ Inventarios - SOLO para administradores e inventarios (NO para clientes)
        if (!isMaestro && user != null && !user.isCliente && user.canManageInventories) {
          gridItems.add(_buildFeatureCard(
            context,
            icon: Icons.inventory_2,
            title: 'Inventarios',
            description: 'Gestiona propiedades y espacios',
            iconColor: AppTheme.dorado,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoriesScreen()),
            ),
          ));
        }
        
        // ❌ Captaciones - SOLO para administradores (NO para clientes)
        if (!isMaestro && user != null && !user.isCliente && user.canManageCaptaciones) {
          gridItems.add(_buildFeatureCard(
            context,
            icon: Icons.home_work,
            title: 'Captaciones',
            description: 'Inmuebles en venta/arriendo',
            iconColor: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PropertyListingsScreen()),
            ),
          ));
        }
        
        // Mis Tickets Asignados - SOLO PARA MAESTROS
        if (isMaestro) {
          // Añadir como tarjeta ancha para mayor relevancia
          features.add(_buildWideFeatureCard(
            context,
            icon: Icons.assignment_ind,
            title: 'Mis Tickets',
            description: 'Gestiona tus tickets asignados',
            iconColor: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyAssignedTicketsScreen()),
            ),
          ));
          features.add(const SizedBox(height: AppTheme.spacingMedium));
        }
        
        // Agregar grid si hay opciones
        if (gridItems.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('📊 Mostrando grid con ${gridItems.length} elementos');
          }
          
          features.add(GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spacingMedium,
            crossAxisSpacing: AppTheme.spacingMedium,
            childAspectRatio: 0.95,
            children: gridItems,
          ));
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Grid items está vacío!');
          }
        }
        
        // DEBUG: Mostrar total de features
        if (kDebugMode) {
          debugPrint('📋 Total features: ${features.length}');
        }
        
        return Column(children: features);
      },
    );
  }


  /// Botón ancho que ocupa 2 columnas
  Widget _buildWideFeatureCard(
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              // Icono con fondo circular
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blanco,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grisClaro,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icono de flecha
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.dorado,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
