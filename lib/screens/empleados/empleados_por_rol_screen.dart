import 'package:flutter/material.dart';
import '../../models/empleado_model.dart';
import '../../services/empleado_service.dart';
import '../../config/app_theme.dart';
import 'add_empleado_screen.dart';

class EmpleadosPorRolScreen extends StatefulWidget {
  final String cargo;
  final String nombreCargo;
  final Color colorCargo;

  const EmpleadosPorRolScreen({
    super.key,
    required this.cargo,
    required this.nombreCargo,
    required this.colorCargo,
  });

  @override
  State<EmpleadosPorRolScreen> createState() => _EmpleadosPorRolScreenState();
}

class _EmpleadosPorRolScreenState extends State<EmpleadosPorRolScreen> {
  final EmpleadoService _empleadoService = EmpleadoService();
  List<EmpleadoModel> _empleados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmpleados();
  }

  Future<void> _loadEmpleados() async {
    setState(() => _isLoading = true);
    
    final empleados = await _empleadoService.getEmpleadosByCargo(widget.cargo);
    
    if (mounted) {
      setState(() {
        _empleados = empleados;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmpleado(EmpleadoModel empleado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: const Text(
          '¿Eliminar Empleado?',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${empleado.nombre}?',
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _empleadoService.deleteEmpleado(empleado.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${empleado.nombre} eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEmpleados();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el empleado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      appBar: AppBar(
        title: Text('${widget.nombreCargo}s'),
        backgroundColor: AppTheme.grisOscuro,
        foregroundColor: AppTheme.dorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmpleados,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.dorado),
            )
          : _empleados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                      SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'No hay ${widget.nombreCargo.toLowerCase()}s registrados',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingSM),
                      Text(
                        'Toca el botón + para agregar uno',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEmpleados,
                  color: AppTheme.dorado,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppTheme.paddingMD),
                    itemCount: _empleados.length,
                    itemBuilder: (context, index) {
                      final empleado = _empleados[index];
                      return _buildEmpleadoCard(empleado);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEmpleadoScreen(
                cargoPreseleccionado: widget.cargo,
                nombreCargo: widget.nombreCargo,
              ),
            ),
          );
          
          if (result == true) {
            _loadEmpleados();
          }
        },
        backgroundColor: widget.colorCargo,
        foregroundColor: AppTheme.grisOscuro,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Empleado'),
      ),
    );
  }

  Widget _buildEmpleadoCard(EmpleadoModel empleado) {
    return Card(
      color: AppTheme.grisOscuro,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y acciones
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.colorCargo.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: widget.colorCargo,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppTheme.spacingMD),
                
                // Nombre y cargo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empleado.nombre,
                        style: const TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingSM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.colorCargo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.nombreCargo,
                          style: TextStyle(
                            color: widget.colorCargo,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menú de opciones
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.blanco),
                  color: AppTheme.grisOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    side: BorderSide(color: AppTheme.dorado, width: 1),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteEmpleado(empleado);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.spacingMD),
            Divider(color: Colors.grey[800]),
            SizedBox(height: AppTheme.spacingMD),
            
            // Información de contacto
            _buildInfoRow(
              icon: Icons.email,
              label: 'Correo',
              value: empleado.correo,
            ),
            SizedBox(height: AppTheme.spacingSM),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Teléfono',
              value: empleado.telefono,
            ),
            
            if (empleado.notas != null && empleado.notas!.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingMD),
              Divider(color: Colors.grey[800]),
              SizedBox(height: AppTheme.spacingMD),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: Colors.grey[600], size: 18),
                  SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Text(
                      empleado.notas!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
