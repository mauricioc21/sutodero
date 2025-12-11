import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for Google Maps static or interaction
import '../../../models/ticket_model.dart';
import '../../../services/ticket_service.dart';
import '../../../services/geolocation_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_api_service.dart'; // Import API Service
import '../../../config/app_theme.dart';

class CheckInCheckOutCard extends StatefulWidget {
  final TicketModel ticket;
  final VoidCallback onUpdate;
  final double allowedRange; // Configurable range

  const CheckInCheckOutCard({
    Key? key,
    required this.ticket,
    required this.onUpdate,
    this.allowedRange = 50.0, // Default 50m
  }) : super(key: key);

  @override
  State<CheckInCheckOutCard> createState() => _CheckInCheckOutCardState();
}

class _CheckInCheckOutCardState extends State<CheckInCheckOutCard> {
  bool _isLoading = false;
  final TicketService _ticketService = TicketService();
  final GeolocationService _geolocationService = GeolocationService();
  final LocationApiService _locationApi = LocationApiService(); // Usage of API Service

  Future<void> _performCheckIn() async {
    setState(() => _isLoading = true);

    try {
      // 1. Obtener Ubicación
      final position = await _geolocationService.getCurrentLocation();
      if (position == null) {
        _showError('No se pudo obtener la ubicación GPS. Verifique permisos.');
        setState(() => _isLoading = false);
        return;
      }

      // Enviar ubicación a "API" (Audit Log)
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      _locationApi.sendLocation(
        userId: user?.uid ?? 'unknown',
        lat: position.latitude,
        lng: position.longitude,
        ticketId: widget.ticket.id,
      );

      // 2. Validar cercanía
      double? distance;
      bool confirmDistance = true;
      
      if (widget.ticket.ubicacionLat != null && widget.ticket.ubicacionLng != null) {
        distance = _geolocationService.calculateDistance(
          position.latitude, position.longitude,
          widget.ticket.ubicacionLat!, widget.ticket.ubicacionLng!
        );

        // Usar rango configurable
        if (distance > widget.allowedRange) {
          confirmDistance = await _showDistanceWarning(distance, widget.allowedRange);
        }
      }

      if (!confirmDistance) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Foto Opcional
      String? photoPath;
      String? comment;
      
      final details = await _showDetailsDialog('Check-In');
      if (details != null) {
        photoPath = details['photo'];
        comment = details['comment'];
      }

      // 4. Ejecutar servicio
      final checkInObj = CheckIn(
        hora: DateTime.now(),
        lat: position.latitude,
        lng: position.longitude,
        foto: photoPath,
        comentario: comment,
        distanciaDesdeUbicacion: distance,
      );

      await _ticketService.performCheckIn(widget.ticket.id, checkInObj);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in registrado exitosamente'), backgroundColor: AppTheme.success),
      );
      widget.onUpdate();

    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performCheckOut() async {
    setState(() => _isLoading = true);

    try {
      final position = await _geolocationService.getCurrentLocation();
      if (position == null) {
        _showError('No se pudo obtener la ubicación GPS.');
        setState(() => _isLoading = false);
        return;
      }

      String? photoPath;
      String? comment;
      
      final details = await _showDetailsDialog('Check-Out');
      if (details != null) {
        photoPath = details['photo'];
        comment = details['comment'];
      }

      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      
      final checkOutObj = CheckOut(
        hora: DateTime.now(),
        lat: position.latitude,
        lng: position.longitude,
        foto: photoPath,
        comentario: comment,
      );

      await _ticketService.performCheckOut(widget.ticket.id, checkOutObj);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out registrado exitosamente'), backgroundColor: AppTheme.success),
      );
      widget.onUpdate();
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showDistanceWarning(double distance, double allowed) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Ubicación Lejana'),
        content: Text(
          'Estás a ${distance.toStringAsFixed(0)} metros del sitio registrado.\n'
          'El rango permitido es ${allowed.toStringAsFixed(0)}m.\n\n¿Deseas continuar de todas formas?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    ) ?? false;
  }

  Future<Map<String, dynamic>?> _showDetailsDialog(String action) async {
    final commentController = TextEditingController();
    String? photoPath;
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Detalles de $action'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comentario (Opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
                    if (picked != null) {
                      setState(() => photoPath = picked.path);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: photoPath != null
                        ? Image.file(File(photoPath!), fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.grey),
                              Text('Tomar Foto (Opcional)', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Saltar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, {
                  'comment': commentController.text,
                  'photo': photoPath, // En un caso real, subir a Storage y retornar URL
                }),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.ticket.check?.checkIn;
    final checkOut = widget.ticket.check?.checkOut;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROL DE ASISTENCIA',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // CHECK-IN SECTION
            if (checkIn == null)
              _buildCheckButton(
                'REGISTRAR CHECK-IN',
                Icons.login,
                Colors.green,
                _performCheckIn,
              )
            else
              _buildInfoCard(
                'CHECK-IN',
                checkIn.hora,
                checkIn.comentario,
                checkIn.distanciaDesdeUbicacion,
                checkIn.foto,
                true,
              ),

            const SizedBox(height: 16),

            // CHECK-OUT SECTION
            if (checkIn != null && checkOut == null)
               _buildCheckButton(
                'REGISTRAR CHECK-OUT',
                Icons.logout,
                Colors.redAccent,
                _performCheckOut,
              )
            else if (checkOut != null)
              _buildInfoCard(
                'CHECK-OUT',
                checkOut.hora,
                checkOut.comentario,
                null,
                checkOut.foto,
                false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Icon(icon, color: Colors.white),
        label: Text(_isLoading ? 'PROCESANDO...' : text, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, DateTime time, String? comment, double? dist, String? photo, bool isCheckIn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCheckIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCheckIn ? Colors.green : Colors.red, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckIn ? Icons.login : Icons.logout,
              color: isCheckIn ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(time),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (dist != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dist > widget.allowedRange ? Colors.orange : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Distancia: ${dist.toStringAsFixed(0)}m',
                      style: TextStyle(
                        fontSize: 10,
                        color: dist > widget.allowedRange ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (photo != null && File(photo).existsSync())
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photo),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
