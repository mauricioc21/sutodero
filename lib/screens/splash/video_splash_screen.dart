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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // ✅ SOLUCIÓN RÁPIDA: Navegar directamente al login después de 1 segundo
    if (kDebugMode) {
      debugPrint('🚀 Cargando SU TODERO...');
    }
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Color oscuro corporativo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Logo o ícono de SU TODERO
            Icon(
              Icons.home_repair_service,
              size: 80,
              color: Color(0xFFFAB334), // Dorado
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFAB334)),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'SU TODERO',
              style: TextStyle(
                color: Color(0xFFFAB334),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cargando...',
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
