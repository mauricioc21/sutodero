import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/face_recognition_service.dart';
import '../../config/app_theme.dart';
import '../home_screen.dart';

/// Pantalla para capturar y registrar datos biométricos faciales
class BiometricRegistrationScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const BiometricRegistrationScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<BiometricRegistrationScreen> createState() => _BiometricRegistrationScreenState();
}

class _BiometricRegistrationScreenState extends State<BiometricRegistrationScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _statusMessage;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      // Buscar cámara frontal
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error al inicializar la cámara: $e';
        });
      }
    }
  }

  Future<void> _captureAndRegister() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showMessage('La cámara no está lista', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturando rostro...';
    });

    try {
      // Capturar imagen
      final image = await _cameraController!.takePicture();
      
      setState(() => _statusMessage = 'Procesando rostro...');

      // Registrar biometría
      final success = await _faceService.registerUserBiometrics(
        userId: widget.userId,
        imagePath: image.path,
      );

      if (success) {
        // Eliminar imagen temporal
        try {
          await File(image.path).delete();
        } catch (e) {
          // Ignorar error al eliminar
        }

        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showMessage(
          'No se pudo registrar el rostro. Asegúrate de estar bien iluminado y de frente a la cámara.',
          isError: true,
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showMessage('Error al capturar foto: $e', isError: true);
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.dorado,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.dorado, size: 32),
            const SizedBox(width: 12),
            const Text(
              '¡Éxito!',
              style: TextStyle(color: AppTheme.blanco),
            ),
          ],
        ),
        content: const Text(
          'Tu rostro ha sido registrado exitosamente. Ahora podrás ingresar con reconocimiento facial.',
          style: TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              'CONTINUAR',
              style: TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _skipBiometricRegistration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: const Text(
          'Omitir registro facial',
          style: TextStyle(color: AppTheme.blanco),
        ),
        content: const Text(
          '¿Estás seguro de que quieres omitir el registro facial? Podrás activarlo más tarde desde tu perfil.',
          style: TextStyle(color: AppTheme.blanco),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppTheme.grisClaro),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text(
              'OMITIR',
              style: TextStyle(color: AppTheme.dorado, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negro,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.dorado),
              )
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    child: Column(
                      children: [
                        Text(
                          '¡Bienvenido, ${widget.userName}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dorado,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacingSM),
                        const Text(
                          'Configura el reconocimiento facial para ingresar más rápido',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grisClaro,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Instrucciones
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
                    padding: EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppTheme.grisOscuro,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.dorado, size: 32),
                        SizedBox(height: AppTheme.spacingSM),
                        const Text(
                          'Instrucciones:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blanco,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSM),
                        _buildInstructionItem('Busca buena iluminación'),
                        _buildInstructionItem('Mira de frente a la cámara'),
                        _buildInstructionItem('Mantén expresión neutral'),
                        _buildInstructionItem('No uses gafas de sol o gorras'),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLG),

                  // Vista previa de la cámara
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        border: Border.all(color: AppTheme.dorado, width: 3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _cameraController != null && _cameraController!.value.isInitialized
                          ? Stack(
                              children: [
                                CameraPreview(_cameraController!),
                                // Overlay con guías faciales
                                Center(
                                  child: Container(
                                    width: 250,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.dorado,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(150),
                                    ),
                                  ),
                                ),
                                // Mensaje de estado
                                if (_statusMessage != null)
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.negro.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.dorado,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Center(
                              child: Text(
                                _statusMessage ?? 'Error al cargar cámara',
                                style: const TextStyle(color: AppTheme.blanco),
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLG),

                  // Botones de acción
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      children: [
                        // Botón de capturar
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _captureAndRegister,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.grisOscuro),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(
                              _isProcessing ? 'PROCESANDO...' : 'CAPTURAR ROSTRO',
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
                              elevation: 0,
                            ),
                          ),
                        ),

                        SizedBox(height: AppTheme.spacingMD),

                        // Botón de omitir
                        TextButton(
                          onPressed: _isProcessing ? null : _skipBiometricRegistration,
                          child: const Text(
                            'Omitir por ahora',
                            style: TextStyle(
                              color: AppTheme.grisClaro,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppTheme.dorado, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.blanco,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
