import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado y navegación para pantalla completa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Inicializar el controlador de video
      _controller = VideoPlayerController.asset('assets/videos/intro_video.mp4');
      
      // Configurar para NO hacer loop (se detiene automáticamente al terminar)
      _controller.setLooping(false);
      
      await _controller.initialize();
      
      setState(() {
        _isVideoInitialized = true;
      });

      // Reproducir el video
      await _controller.play();

      // Escuchar cuando el video termine
      _controller.addListener(() {
        // Cuando el video termina, el position es igual al duration
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToHome();
        }
      });

      // Timeout de seguridad: si el video no termina en 15 segundos, continuar
      Timer(const Duration(seconds: 15), () {
        if (mounted && !_controller.value.isPlaying) {
          _navigateToHome();
        }
      });
    } catch (e) {
      debugPrint('❌ Error inicializando video splash: $e');
      setState(() {
        _hasError = true;
      });
      // Si hay error, esperar 2 segundos y continuar
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToHome();
        }
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      // Restaurar barra de estado antes de navegar
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restaurar barra de estado al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // ✅ SIN SafeArea para pantalla completa sin bordes
      body: Stack(
        fit: StackFit.expand, // Expandir a toda la pantalla
        children: [
          // ✅ Video en pantalla completa SIN bordes negros
          if (_isVideoInitialized && !_hasError)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover, // ✅ Cubrir toda la pantalla (sin bordes)
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // Loading indicator mientras carga el video
          if (!_isVideoInitialized && !_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Error fallback
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando aplicación...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Botón para saltar (opcional) - con mejor posición
          if (_isVideoInitialized && !_hasError)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16, // Respeta notch
              right: 16,
              child: TextButton(
                onPressed: _navigateToHome,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Saltar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
