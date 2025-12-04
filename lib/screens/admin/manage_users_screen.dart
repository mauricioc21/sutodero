import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:flutter/foundation.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      final snapshot = await _firestore
          .collection('users')
          .orderBy('nombre')
          .get();
      
      setState(() {
        _users = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading users: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAdmin = authService.currentUser;
    
    if (currentAdmin == null || !currentAdmin.isAdministrador) {
      _showErrorDialog('Solo administradores pueden asignar el rol de Administrador');
      return;
    }

    // Confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text(
          'Confirmar Cambio de Rol',
          style: TextStyle(color: AppTheme.dorado),
        ),
        content: Text(
          '¿Asignar rol de ${newRole.displayName} a ${user.nombre}?\n\n'
          'Este cambio será inmediato y no requiere aprobación.',
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
              backgroundColor: AppTheme.dorado,
              foregroundColor: AppTheme.grisOscuro,
            ),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      
      // Actualizar rol en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'rol': newRole.name,
      });
      
      // Recargar usuarios
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rol actualizado a ${newRole.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al actualizar rol: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.dorado)),
          ),
        ],
      ),
    );
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      final nameLower = user.nombre.toLowerCase();
      final emailLower = user.email.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || emailLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    // Verificar que sea administrador
    if (currentUser == null || !currentUser.isAdministrador) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: AppTheme.grisOscuro,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: AppTheme.grisClaro.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Solo administradores pueden acceder a esta pantalla',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.grisClaro.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
        backgroundColor: AppTheme.grisOscuro,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.dorado),
                  filled: true,
                  fillColor: AppTheme.grisOscuro,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppTheme.blanco),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Lista de usuarios
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.dorado),
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty 
                                ? 'No hay usuarios registrados'
                                : 'No se encontraron usuarios',
                            style: TextStyle(
                              color: AppTheme.grisClaro.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: AppTheme.dorado,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _buildUserCard(user, currentUser);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, UserModel currentUser) {
    final isCurrentUser = user.uid == currentUser.uid;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.grisOscuro,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isCurrentUser ? AppTheme.dorado : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.dorado,
          child: Text(
            user.nombre[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.grisOscuro,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nombre,
                style: const TextStyle(
                  color: AppTheme.blanco,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.dorado.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TÚ',
                  style: TextStyle(
                    color: AppTheme.dorado,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: AppTheme.grisClaro.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.badge,
                  size: 14,
                  color: _getRoleColor(user.userRole),
                ),
                const SizedBox(width: 4),
                Text(
                  user.userRole.displayName,
                  style: TextStyle(
                    color: _getRoleColor(user.userRole),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isCurrentUser
            ? null
            : PopupMenuButton<UserRole>(
                icon: const Icon(Icons.more_vert, color: AppTheme.dorado),
                color: AppTheme.grisOscuro,
                onSelected: (role) => _updateUserRole(user, role),
                itemBuilder: (context) => UserRole.values.map((role) {
                  final isCurrent = role == user.userRole;
                  return PopupMenuItem<UserRole>(
                    value: role,
                    enabled: !isCurrent,
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.check : Icons.badge,
                          color: _getRoleColor(role),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            color: isCurrent ? AppTheme.dorado : AppTheme.blanco,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return Colors.red;
      case UserRole.coordinador:
        return Colors.orange;
      case UserRole.maestro:
        return Colors.blue;
      case UserRole.inventarios:
        return Colors.green;
      case UserRole.duppla:
        return Colors.purple;
    }
  }
}
