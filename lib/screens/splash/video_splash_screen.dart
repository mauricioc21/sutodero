import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../auth/login_screen.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoReady = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Cargar TU video desde assets
      _controller = VideoPlayerController.asset('assets/videos/splash_video.mp4');
      
      if (kDebugMode) {
        debugPrint('🎬 Inicializando video splash...');
      }
      
      await _controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ Timeout inicializando video - navegando a login');
          }
          throw TimeoutException('Video initialization timeout');
        },
      );
      
      if (!mounted) return;
      
      if (kDebugMode) {
        debugPrint('✅ Video inicializado correctamente');
        debugPrint('📹 Duración: ${_controller.value.duration}');
      }
      
      setState(() {
        _isVideoReady = true;
      });
      
      // Reproducir el video
      await _controller.play();
      
      if (kDebugMode) {
        debugPrint('▶️ Video reproduciéndose');
      }
      
      // Escuchar cuando termine el video
      _controller.addListener(_checkVideoCompletion);
      
      // Timeout de seguridad: máximo 10 segundos
      Future.delayed(const Duration(seconds: 10), () {
        if (!_hasNavigated) {
          if (kDebugMode) {
            debugPrint('⏱️ Timeout de seguridad - navegando a login');
          }
          _navigateToLogin();
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error cargando video: $e');
        debugPrint('🔄 Navegando a login en 2 segundos...');
      }
      
      await Future.delayed(const Duration(seconds: 2));
      _navigateToLogin();
    }
  }

  void _checkVideoCompletion() {
    if (_hasNavigated) return;
    
    // Verificar si el video terminó
    if (_controller.value.position >= _controller.value.duration) {
      if (kDebugMode) {
        debugPrint('🎬 Video completado - navegando a login');
      }
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    if (kDebugMode) {
      debugPrint('🚀 Navegando a LoginScreen');
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoCompletion);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideoReady
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFAB334)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando Su Todero...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
