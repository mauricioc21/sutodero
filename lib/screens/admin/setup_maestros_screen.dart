import 'package:flutter/material.dart';
import '../../scripts/create_maestros_planta.dart';
import '../../config/app_theme.dart';

class SetupMaestrosScreen extends StatefulWidget {
  const SetupMaestrosScreen({super.key});

  @override
  State<SetupMaestrosScreen> createState() => _SetupMaestrosScreenState();
}

class _SetupMaestrosScreenState extends State<SetupMaestrosScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _createMaestros() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      await createMaestrosPlanta();
      
      if (mounted) {
        setState(() {
          _result = '✅ Maestros de planta creados exitosamente\n\n'
              '📋 CREDENCIALES DE ACCESO:\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
              '👤 Rodrigo:\n'
              '   Email: rodrigo.maestro@sutodero.com\n'
              '   Password: SuTodero2025!\n\n'
              '👤 Alexander:\n'
              '   Email: alexander.maestro@sutodero.com\n'
              '   Password: SuTodero2025!\n\n'
              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
              '✅ Los maestros ahora pueden iniciar sesión';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Maestros creados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = '⚠️ Error al crear maestros:\n$e\n\n'
              'Si los usuarios ya existen, esto es normal.\n'
              'Verifica en la sección de Gestión de Usuarios.';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: const Text('Configurar Maestros de Planta'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono y título
            Icon(
              Icons.engineering,
              size: 80,
              color: AppTheme.dorado,
            ),
            SizedBox(height: AppTheme.spacingLG),
            
            Text(
              'Configuración Inicial',
              style: TextStyle(
                color: AppTheme.dorado,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.spacingSM),
            
            Text(
              'Crea los maestros de planta predeterminados',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Información de los maestros
            Container(
              padding: EdgeInsets.all(AppTheme.paddingLG),
              decoration: BoxDecoration(
                color: AppTheme.grisOscuro,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.dorado.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.dorado, size: 20),
                      SizedBox(width: AppTheme.spacingSM),
                      Text(
                        'Maestros a Crear',
                        style: TextStyle(
                          color: AppTheme.dorado,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  
                  // Rodrigo
                  _buildMaestroInfo(
                    nombre: 'Rodrigo',
                    email: 'rodrigo.maestro@sutodero.com',
                    telefono: '+57 300 123 4567',
                  ),
                  
                  SizedBox(height: AppTheme.spacingMD),
                  
                  // Alexander
                  _buildMaestroInfo(
                    nombre: 'Alexander',
                    email: 'alexander.maestro@sutodero.com',
                    telefono: '+57 301 234 5678',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppTheme.spacingXL),
            
            // Botón crear maestros
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createMaestros,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.grisOscuro),
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(
                  _isLoading ? 'CREANDO MAESTROS...' : 'CREAR MAESTROS DE PLANTA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dorado,
                  foregroundColor: AppTheme.grisOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
              ),
            ),
            
            // Resultado
            if (_result.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingXL),
              Container(
                padding: EdgeInsets.all(AppTheme.paddingLG),
                decoration: BoxDecoration(
                  color: _result.contains('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(
                    color: _result.contains('✅')
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result.contains('✅') ? Icons.check_circle : Icons.warning,
                          color: _result.contains('✅') ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        SizedBox(width: AppTheme.spacingSM),
                        Expanded(
                          child: Text(
                            'Resultado',
                            style: TextStyle(
                              color: _result.contains('✅') ? Colors.green : Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingMD),
                    Text(
                      _result,
                      style: const TextStyle(
                        color: AppTheme.blanco,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaestroInfo({
    required String nombre,
    required String email,
    required String telefono,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: AppTheme.negro.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.dorado, size: 20),
              SizedBox(width: AppTheme.spacingSM),
              Text(
                nombre,
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSM),
          Row(
            children: [
              Icon(Icons.email, color: Colors.grey[600], size: 16),
              SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSM),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.grey[600], size: 16),
              SizedBox(width: AppTheme.spacingSM),
              Text(
                telefono,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
