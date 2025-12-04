import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/role_change_service.dart';
import '../../services/auth_service.dart';
import '../../models/role_change_request_model.dart';
import 'package:intl/intl.dart';
import 'manage_users_screen.dart';

class RoleRequestsScreen extends StatefulWidget {
  const RoleRequestsScreen({super.key});

  @override
  State<RoleRequestsScreen> createState() => _RoleRequestsScreenState();
}

class _RoleRequestsScreenState extends State<RoleRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
    await roleChangeService.loadPendingRequests();
  }

  Future<void> _handleApprove(RoleChangeRequest request) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
    final admin = authService.currentUser;
    
    if (admin == null) return;
    
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text(
          'Aprobar Solicitud',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          '¿Aprobar cambio de rol de ${request.userName}?\n\n${request.currentRoleDisplayName} → ${request.requestedRoleDisplayName}',
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.grisClaro)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('APROBAR'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final success = await roleChangeService.approveRequest(
      requestId: request.id,
      adminId: admin.uid,
      adminName: admin.nombre,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '✅ Solicitud aprobada correctamente' 
              : '❌ Error al aprobar solicitud'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(RoleChangeRequest request) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final roleChangeService = Provider.of<RoleChangeService>(context, listen: false);
    final admin = authService.currentUser;
    
    if (admin == null) return;
    
    // Mostrar diálogo para ingresar comentarios
    String? comments;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final commentController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.grisOscuro,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          title: const Text(
            'Rechazar Solicitud',
            style: TextStyle(color: AppTheme.dorado),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Rechazar solicitud de ${request.userName}?',
                style: const TextStyle(color: AppTheme.blanco),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Motivo del rechazo (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                maxLines: 3,
                style: const TextStyle(color: AppTheme.blanco),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: AppTheme.grisClaro)),
            ),
            ElevatedButton(
              onPressed: () {
                comments = commentController.text;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('RECHAZAR'),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    final success = await roleChangeService.rejectRequest(
      requestId: request.id,
      adminId: admin.uid,
      adminName: admin.nombre,
      comments: comments,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '✅ Solicitud rechazada' 
              : '❌ Error al rechazar solicitud'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Cambio de Rol'),
        backgroundColor: AppTheme.grisOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Gestionar Usuarios',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageUsersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: Consumer<RoleChangeService>(
          builder: (context, roleChangeService, child) {
            if (roleChangeService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.dorado),
              );
            }
            
            if (roleChangeService.pendingRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: AppTheme.grisClaro.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay solicitudes pendientes',
                      style: TextStyle(
                        color: AppTheme.grisClaro.withValues(alpha: 0.7),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: _loadRequests,
              color: AppTheme.dorado,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: roleChangeService.pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = roleChangeService.pendingRequests[index];
                  return _buildRequestCard(request);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(RoleChangeRequest request) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.grisOscuro,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.dorado, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con usuario y fecha
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.dorado,
                  child: Text(
                    request.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.grisOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          color: AppTheme.blanco,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.userEmail,
                        style: TextStyle(
                          color: AppTheme.grisClaro.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateFormat.format(request.requestDate),
                  style: TextStyle(
                    color: AppTheme.grisClaro.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cambio de rol solicitado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grisClaro.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      request.currentRoleDisplayName,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, color: AppTheme.dorado),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      request.requestedRoleDisplayName,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('RECHAZAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APROBAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
