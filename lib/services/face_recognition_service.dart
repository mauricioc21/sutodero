import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Servicio de reconocimiento facial usando Google ML Kit
/// Permite registrar rostros y autenticar usuarios
class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  late final FaceDetector _faceDetector;
  bool _isInitialized = false;

  /// Inicializar el detector de rostros
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      );

      _faceDetector = FaceDetector(options: options);
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ Face Recognition Service inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al inicializar Face Recognition: $e');
      }
      rethrow;
    }
  }

  /// Detectar rostros en una imagen
  Future<List<Face>> detectFaces(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (kDebugMode) {
        debugPrint('✅ Detectados ${faces.length} rostro(s)');
      }

      return faces;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al detectar rostros: $e');
      }
      return [];
    }
  }

  /// Registrar rostro de usuario
  Future<bool> registerUserFace({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No se detectaron rostros en la imagen');
        }
        return false;
      }

      if (faces.length > 1) {
        if (kDebugMode) {
          debugPrint('⚠️ Se detectaron múltiples rostros. Usar imagen con un solo rostro');
        }
        return false;
      }

      // Extraer características del rostro
      final face = faces.first;
      final faceFeatures = _extractFaceFeatures(face);

      // Guardar características en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('face_features_$userId', jsonEncode(faceFeatures));
      await prefs.setString('face_image_$userId', imagePath);

      if (kDebugMode) {
        debugPrint('✅ Rostro registrado para usuario: $userId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al registrar rostro: $e');
      }
      return false;
    }
  }

  /// Autenticar usuario por reconocimiento facial
  Future<String?> authenticateUser(String imagePath) async {
    try {
      final faces = await detectFaces(imagePath);

      if (faces.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No se detectaron rostros');
        }
        return null;
      }

      if (faces.length > 1) {
        if (kDebugMode) {
          debugPrint('⚠️ Múltiples rostros detectados');
        }
        return null;
      }

      final face = faces.first;
      final currentFeatures = _extractFaceFeatures(face);

      // Obtener todos los rostros registrados
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('face_features_'));

      String? matchedUserId;
      double highestSimilarity = 0.0;

      for (final key in keys) {
        final userId = key.replaceFirst('face_features_', '');
        final storedFeaturesJson = prefs.getString(key);
        
        if (storedFeaturesJson != null) {
          final storedFeatures = Map<String, double>.from(jsonDecode(storedFeaturesJson));
          final similarity = _calculateSimilarity(currentFeatures, storedFeatures);

          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            matchedUserId = userId;
          }
        }
      }

      // Umbral de similitud (ajustable)
      const similarityThreshold = 0.75;

      if (highestSimilarity >= similarityThreshold) {
        if (kDebugMode) {
          debugPrint('✅ Usuario autenticado: $matchedUserId (similitud: ${(highestSimilarity * 100).toStringAsFixed(1)}%)');
        }
        return matchedUserId;
      }

      if (kDebugMode) {
        debugPrint('⚠️ No se encontró coincidencia (máxima similitud: ${(highestSimilarity * 100).toStringAsFixed(1)}%)');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en autenticación facial: $e');
      }
      return null;
    }
  }

  /// Extraer características del rostro
  Map<String, double> _extractFaceFeatures(Face face) {
    final features = <String, double>{};

    // Características geométricas
    features['boundingBoxWidth'] = face.boundingBox.width;
    features['boundingBoxHeight'] = face.boundingBox.height;
    features['boundingBoxAspectRatio'] = face.boundingBox.width / face.boundingBox.height;

    // Ángulos de rotación
    if (face.headEulerAngleX != null) features['headEulerAngleX'] = face.headEulerAngleX!;
    if (face.headEulerAngleY != null) features['headEulerAngleY'] = face.headEulerAngleY!;
    if (face.headEulerAngleZ != null) features['headEulerAngleZ'] = face.headEulerAngleZ!;

    // Probabilidades de expresión
    if (face.smilingProbability != null) {
      features['smilingProbability'] = face.smilingProbability!;
    }
    if (face.leftEyeOpenProbability != null) {
      features['leftEyeOpenProbability'] = face.leftEyeOpenProbability!;
    }
    if (face.rightEyeOpenProbability != null) {
      features['rightEyeOpenProbability'] = face.rightEyeOpenProbability!;
    }

    // Landmarks (puntos clave del rostro)
    final landmarks = face.landmarks;
    if (landmarks.isNotEmpty) {
      for (final landmark in landmarks.entries) {
        final point = landmark.value?.position;
        if (point != null) {
          features['landmark_${landmark.key.name}_x'] = point.x.toDouble();
          features['landmark_${landmark.key.name}_y'] = point.y.toDouble();
        }
      }
    }

    return features;
  }

  /// Calcular similitud entre dos conjuntos de características
  double _calculateSimilarity(
    Map<String, double> features1,
    Map<String, double> features2,
  ) {
    // Características comunes
    final commonKeys = features1.keys.where((k) => features2.containsKey(k)).toList();

    if (commonKeys.isEmpty) return 0.0;

    // Calcular similitud euclidiana normalizada
    double sumSquaredDiff = 0.0;
    int count = 0;

    for (final key in commonKeys) {
      final val1 = features1[key]!;
      final val2 = features2[key]!;

      // Normalizar diferencia
      final diff = (val1 - val2).abs();
      final maxVal = val1.abs() > val2.abs() ? val1.abs() : val2.abs();
      final normalizedDiff = maxVal > 0 ? diff / maxVal : 0.0;

      sumSquaredDiff += normalizedDiff * normalizedDiff;
      count++;
    }

    // Similitud: 1 - distancia normalizada
    final distance = count > 0 ? sumSquaredDiff / count : 1.0;
    final similarity = 1.0 - distance.clamp(0.0, 1.0);

    return similarity;
  }

  /// Verificar si un usuario tiene rostro registrado
  Future<bool> hasRegisteredFace(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('face_features_$userId');
  }

  /// Eliminar rostro registrado de un usuario
  Future<void> deleteUserFace(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('face_features_$userId');
      await prefs.remove('face_image_$userId');

      if (kDebugMode) {
        debugPrint('✅ Rostro eliminado para usuario: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al eliminar rostro: $e');
      }
    }
  }

  /// Obtener imagen de rostro registrado
  Future<String?> getUserFaceImage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('face_image_$userId');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener imagen de rostro: $e');
      }
      return null;
    }
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
    }
  }
}
