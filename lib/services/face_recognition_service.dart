import 'package:flutter/foundation.dart';

// ⚠️ MOCK SERVICE FOR WEB COMPATIBILITY
// The original service uses dart:io and google_mlkit_face_detection which are NOT supported on Web.
// This mock allows the app to compile and run on Web Preview.

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  Future<bool> registerUserBiometrics({
    required String userId,
    required String imagePath,
  }) async {
    if (kDebugMode) {
      debugPrint('⚠️ Face recognition is not supported on Web Preview');
    }
    return false;
  }

  Future<String?> authenticateWithFace({
    required String imagePath,
  }) async {
    if (kDebugMode) {
      debugPrint('⚠️ Face recognition is not supported on Web Preview');
    }
    return null;
  }

  Future<bool> hasBiometricsRegistered(String userId) async {
    return false;
  }

  Future<void> deleteBiometrics(String userId) async {
    // No-op
  }
}
