import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_theme.dart';
import '../../models/maestro_profile_model.dart';
import '../../services/maestro_profile_service.dart';

class ManageMaestroProfilesScreen extends StatefulWidget {
  const ManageMaestroProfilesScreen({super.key});

  @override
  State<ManageMaestroProfilesScreen> createState() => _ManageMaestroProfilesScreenState();
}

class _ManageMaestroProfilesScreenState extends State<ManageMaestroProfilesScreen> {
  final _service = MaestroProfileService();
  List<MaestroProfileModel> _profiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar método híbrido que combina Firebase + Local
      final profiles = await _service.getAllProfiles();

      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
        
        if (kDebugMode) {
          debugPrint('✅ Perfiles cargados exitosamente: ${profiles.length}');
          for (var profile in profiles) {
            final source = profile.id.startsWith('local_') ? '💾 Local' : '☁️ Firebase';
            debugPrint('   $source - ${profile.nombre}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al cargar perfiles: $e');
      }
      
      if (mounted) {
        setState(() {
          // Usar perfiles predeterminados como último recurso
          final now = DateTime.now();
          _profiles = [
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
          _errorMessage = 'No se pudieron cargar perfiles guardados. Mostrando perfiles predeterminados.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles de Maestros'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar Nuevo Maestro',
            onPressed: () => _showEditDialog(null),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.gradientBackground,
        ),
        child: _buildProfilesList(),
      ),
    );
  }

  Widget _buildProfilesList() {
    // Mostrar loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dorado),
        ),
      );
    }

    // Mostrar error
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar perfiles',
              style: TextStyle(
                color: AppTheme.blanco,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.grisClaro,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dorado,
                foregroundColor: AppTheme.grisOscuro,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Lista vacía
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.engineering,
              size: 80,
              color: AppTheme.grisClaro.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay perfiles de maestros',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.blanco,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para agregar maestros',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grisClaro,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lista de perfiles
    return RefreshIndicator(
      onRefresh: _loadProfiles,
      color: AppTheme.dorado,
      child: ListView.builder(
        padding: AppTheme.paddingAll,
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          return _buildProfileCard(profile);
        },
      ),
    );
  }

  Widget _buildProfileCard(MaestroProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: AppTheme.containerDecoration(
        withBorder: false,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditDialog(profile),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.dorado.withValues(alpha: 0.2),
                  child: Text(
                    profile.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dorado,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.blanco,
                              ),
                            ),
                          ),
                          if (!profile.activo)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Inactivo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      if (profile.especialidad != null)
                        Text(
                          profile.especialidad!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.dorado,
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.grisClaro,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.telefono,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.grisClaro,
                            ),
                          ),
                        ],
                      ),
                      
                      if (profile.email != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14,
                              color: AppTheme.grisClaro,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.email!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.grisClaro,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Botones de acción
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.dorado),
                      onPressed: () => _showEditDialog(profile),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(
                        profile.activo ? Icons.toggle_on : Icons.toggle_off,
                        color: profile.activo ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleActive(profile),
                      tooltip: profile.activo ? 'Desactivar' : 'Activar',
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

  Future<void> _toggleActive(MaestroProfileModel profile) async {
    final updated = profile.copyWith(
      activo: !profile.activo,
      fechaActualizacion: DateTime.now(),
    );

    final success = await _service.updateMaestroProfile(profile.id, updated);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.activo
                ? '✅ ${profile.nombre} activado'
                : '⚠️ ${profile.nombre} desactivado',
          ),
          backgroundColor: updated.activo ? Colors.green : Colors.orange,
        ),
      );
      
      // Recargar la lista de perfiles
      await _loadProfiles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al actualizar perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditDialog(MaestroProfileModel? profile) async {
    final nameController = TextEditingController(text: profile?.nombre ?? '');
    final phoneController = TextEditingController(text: profile?.telefono ?? '');
    final emailController = TextEditingController(text: profile?.email ?? '');
    final specialtyController = TextEditingController(text: profile?.especialidad ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        title: Text(
          profile == null ? 'Nuevo Maestro' : 'Editar Maestro',
          style: const TextStyle(color: AppTheme.dorado),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  labelStyle: TextStyle(color: AppTheme.grisClaro),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: AppTheme.blanco),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono *',
                  labelStyle: TextStyle(color: AppTheme.grisClaro),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppTheme.blanco),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppTheme.grisClaro),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grisClaro),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specialtyController,
                style: const TextStyle(color: AppTheme.blanco),
                decoration: InputDecoration(
                  labelText: 'Especialidad',
                  labelStyle: TextStyle(color: AppTheme.grisClaro),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grisClaro),
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dorado,
              foregroundColor: AppTheme.grisOscuro,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();

      if (name.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Nombre y teléfono son obligatorios'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final now = DateTime.now();

      if (profile == null) {
        // Crear nuevo
        try {
          final newProfile = MaestroProfileModel(
            id: '',
            nombre: name,
            telefono: phone,
            email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
            especialidad: specialtyController.text.trim().isEmpty ? null : specialtyController.text.trim(),
            activo: true,
            fechaCreacion: now,
            fechaActualizacion: now,
          );

          final id = await _service.createMaestroProfile(newProfile)
              .timeout(const Duration(seconds: 10));

          if (mounted) {
            if (id != null) {
              // Determinar dónde se guardó
              final isLocal = id.startsWith('local_');
              final saveLocation = isLocal ? 'localmente 💾' : 'en Firebase ☁️';
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Maestro creado exitosamente $saveLocation'),
                  backgroundColor: isLocal ? Colors.orange : Colors.green,
                  duration: Duration(seconds: isLocal ? 5 : 3),
                ),
              );
              
              // Mostrar mensaje adicional si se guardó localmente
              if (isLocal) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💡 El perfil se sincronizará con Firebase cuando se corrijan los permisos'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                });
              }
              
              // Recargar la lista de perfiles
              await _loadProfiles();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ No se pudo guardar. Intenta nuevamente.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error al crear maestro: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            
            if (kDebugMode) {
              debugPrint('❌ Error detallado al crear maestro: $e');
            }
          }
        }
      } else {
        // Actualizar existente
        try {
          final updated = profile.copyWith(
            nombre: name,
            telefono: phone,
            email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
            especialidad: specialtyController.text.trim().isEmpty ? null : specialtyController.text.trim(),
            fechaActualizacion: now,
          );

          final success = await _service.updateMaestroProfile(profile.id, updated)
              .timeout(const Duration(seconds: 10));

          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Maestro actualizado exitosamente'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              
              // Recargar la lista de perfiles
              await _loadProfiles();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ No se pudo actualizar en Firebase. Verifica tu conexión.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error al actualizar maestro: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            
            if (kDebugMode) {
              debugPrint('❌ Error detallado al actualizar maestro: $e');
            }
          }
        }
      }
    }
  }
}
