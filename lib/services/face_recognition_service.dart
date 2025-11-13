import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de reconocimiento facial biométrico
/// Permite registro y autenticación mediante reconocimiento facial
class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  /// Registrar datos biométricos de un usuario
  /// Toma una foto del rostro y guarda características únicas en Firestore
  Future<bool> registerUserBiometrics({
    required String userId,
    required String imagePath,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Iniciando registro biométrico para usuario: $userId');
      }

      // Procesar imagen y detectar rostro
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No se detectó ningún rostro en la imagen');
        }
        return false;
      }

      if (faces.length > 1) {
        if (kDebugMode) {
          debugPrint('⚠️ Se detectaron múltiples rostros. Por favor, asegúrese de estar solo en la foto');
        }
        return false;
      }

      final face = faces.first;
      
      // Validar calidad del rostro detectado
      if (!_isGoodQualityFace(face)) {
        if (kDebugMode) {
          debugPrint('⚠️ Calidad del rostro insuficiente. Por favor, tome otra foto con mejor iluminación');
        }
        return false;
      }

      // Extraer características faciales (embeddings simplificados)
      final faceEmbedding = await _extractFaceEmbedding(imagePath, face);

      // Guardar en Firestore
      await _firestore.collection('user_biometrics').doc(userId).set({
        'userId': userId,
        'faceEmbedding': faceEmbedding,
        'registeredAt': FieldValue.serverTimestamp(),
        'faceQualityScore': _calculateQualityScore(face),
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'right': face.boundingBox.right,
          'bottom': face.boundingBox.bottom,
        },
      });

      if (kDebugMode) {
        debugPrint('✅ Datos biométricos registrados exitosamente');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al registrar biométricos: $e');
      }
      return false;
    }
  }

  /// Autenticar usuario mediante reconocimiento facial
  /// Compara el rostro capturado con los datos almacenados en Firestore
  Future<String?> authenticateWithFace({
    required String imagePath,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Iniciando autenticación facial...');
      }

      // Detectar rostro en la imagen capturada
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No se detectó ningún rostro');
        }
        return null;
      }

      if (faces.length > 1) {
        if (kDebugMode) {
          debugPrint('⚠️ Se detectaron múltiples rostros');
        }
        return null;
      }

      final face = faces.first;
      
      if (!_isGoodQualityFace(face)) {
        if (kDebugMode) {
          debugPrint('⚠️ Calidad del rostro insuficiente');
        }
        return null;
      }

      // Extraer características del rostro capturado
      final capturedEmbedding = await _extractFaceEmbedding(imagePath, face);

      // Obtener todos los usuarios con biometría registrada
      final biometricsSnapshot = await _firestore.collection('user_biometrics').get();
      
      if (biometricsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No hay usuarios con biometría registrada');
        }
        return null;
      }

      // Comparar con cada usuario registrado
      double bestSimilarity = 0.0;
      String? bestMatchUserId;
      const double threshold = 0.75; // Umbral de similitud (75%)

      for (final doc in biometricsSnapshot.docs) {
        final data = doc.data();
        final storedEmbedding = List<double>.from(data['faceEmbedding'] ?? []);
        
        final similarity = _calculateSimilarity(capturedEmbedding, storedEmbedding);
        
        if (kDebugMode) {
          debugPrint('📊 Similitud con usuario ${doc.id}: ${(similarity * 100).toStringAsFixed(1)}%');
        }

        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatchUserId = data['userId'] as String?;
        }
      }

      if (bestSimilarity >= threshold && bestMatchUserId != null) {
        if (kDebugMode) {
          debugPrint('✅ Usuario autenticado: $bestMatchUserId con ${(bestSimilarity * 100).toStringAsFixed(1)}% de similitud');
        }
        return bestMatchUserId;
      } else {
        if (kDebugMode) {
          debugPrint('❌ No se encontró coincidencia suficiente (mejor: ${(bestSimilarity * 100).toStringAsFixed(1)}%)');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en autenticación facial: $e');
      }
      return null;
    }
  }

  /// Verificar si un usuario tiene biometría registrada
  Future<bool> hasBiometricsRegistered(String userId) async {
    try {
      final doc = await _firestore.collection('user_biometrics').doc(userId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error verificando biometría: $e');
      }
      return false;
    }
  }

  /// Eliminar datos biométricos de un usuario
  Future<void> deleteBiometrics(String userId) async {
    try {
      await _firestore.collection('user_biometrics').doc(userId).delete();
      if (kDebugMode) {
        debugPrint('✅ Datos biométricos eliminados para usuario: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error eliminando biometría: $e');
      }
    }
  }

  /// Validar si el rostro detectado tiene buena calidad
  bool _isGoodQualityFace(Face face) {
    // Verificar que el rostro esté de frente (head euler angles)
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;
    
    // Ángulos aceptables: -20° a +20°
    if (headEulerAngleY.abs() > 20 || headEulerAngleZ.abs() > 20) {
      return false;
    }

    // Verificar probabilidad de sonrisa (mejor detección con expresión neutral)
    final smilingProbability = face.smilingProbability ?? 0.0;
    if (smilingProbability > 0.8) {
      if (kDebugMode) {
        debugPrint('⚠️ Por favor, mantenga expresión neutral (no sonría demasiado)');
      }
    }

    // Verificar que ambos ojos estén abiertos
    final leftEyeOpenProbability = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpenProbability = face.rightEyeOpenProbability ?? 0.0;
    
    if (leftEyeOpenProbability < 0.5 || rightEyeOpenProbability < 0.5) {
      return false;
    }

    return true;
  }

  /// Calcular score de calidad del rostro
  double _calculateQualityScore(Face face) {
    double score = 0.0;
    
    // Ángulos de la cabeza (max 30 puntos)
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;
    score += (30 - min(30, headEulerAngleY.abs() + headEulerAngleZ.abs()));
    
    // Ojos abiertos (max 40 puntos)
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;
    score += (leftEyeOpen + rightEyeOpen) * 20;
    
    // Tamaño del rostro (max 30 puntos) - rostros más grandes = mejor calidad
    final faceSize = face.boundingBox.width * face.boundingBox.height;
    score += min(30, (faceSize / 10000) * 30);
    
    return score; // Score de 0 a 100
  }

  /// Extraer embedding facial simplificado
  /// En producción, se usaría un modelo de deep learning (FaceNet, ArcFace, etc.)
  /// Esta es una implementación simplificada usando características geométricas
  Future<List<double>> _extractFaceEmbedding(String imagePath, Face face) async {
    final embedding = <double>[];
    
    // 1. Características geométricas de la caja delimitadora
    embedding.add(face.boundingBox.width.toDouble());
    embedding.add(face.boundingBox.height.toDouble());
    embedding.add(face.boundingBox.width / face.boundingBox.height); // Ratio
    
    // 2. Ángulos de la cabeza
    embedding.add(face.headEulerAngleX ?? 0.0);
    embedding.add(face.headEulerAngleY ?? 0.0);
    embedding.add(face.headEulerAngleZ ?? 0.0);
    
    // 3. Landmarks faciales (si están disponibles)
    if (face.landmarks.isNotEmpty) {
      // Ojo izquierdo
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      if (leftEye != null) {
        embedding.add(leftEye.position.x.toDouble());
        embedding.add(leftEye.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Ojo derecho
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      if (rightEye != null) {
        embedding.add(rightEye.position.x.toDouble());
        embedding.add(rightEye.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Nariz
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (nose != null) {
        embedding.add(nose.position.x.toDouble());
        embedding.add(nose.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Boca izquierda
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      if (leftMouth != null) {
        embedding.add(leftMouth.position.x.toDouble());
        embedding.add(leftMouth.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Boca derecha
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      if (rightMouth != null) {
        embedding.add(rightMouth.position.x.toDouble());
        embedding.add(rightMouth.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Mejilla izquierda
      final leftCheek = face.landmarks[FaceLandmarkType.leftCheek];
      if (leftCheek != null) {
        embedding.add(leftCheek.position.x.toDouble());
        embedding.add(leftCheek.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
      
      // Mejilla derecha
      final rightCheek = face.landmarks[FaceLandmarkType.rightCheek];
      if (rightCheek != null) {
        embedding.add(rightCheek.position.x.toDouble());
        embedding.add(rightCheek.position.y.toDouble());
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
    }
    
    // 4. Probabilidades de expresión
    embedding.add(face.smilingProbability ?? 0.0);
    embedding.add(face.leftEyeOpenProbability ?? 0.0);
    embedding.add(face.rightEyeOpenProbability ?? 0.0);
    
    // 5. Características adicionales de píxeles (análisis básico de textura)
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image != null) {
        // Extraer región del rostro
        final faceRegion = img.copyCrop(
          image,
          x: max(0, face.boundingBox.left.toInt()),
          y: max(0, face.boundingBox.top.toInt()),
          width: min(image.width, face.boundingBox.width.toInt()),
          height: min(image.height, face.boundingBox.height.toInt()),
        );
        
        // Calcular histogramas de color simplificados
        int totalR = 0, totalG = 0, totalB = 0;
        int pixelCount = 0;
        
        for (var y = 0; y < faceRegion.height; y++) {
          for (var x = 0; x < faceRegion.width; x++) {
            final pixel = faceRegion.getPixel(x, y);
            totalR += pixel.r.toInt();
            totalG += pixel.g.toInt();
            totalB += pixel.b.toInt();
            pixelCount++;
          }
        }
        
        if (pixelCount > 0) {
          embedding.add(totalR / pixelCount);
          embedding.add(totalG / pixelCount);
          embedding.add(totalB / pixelCount);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error extrayendo características de píxeles: $e');
      }
      // Agregar valores por defecto si falla la extracción
      embedding.add(0.0);
      embedding.add(0.0);
      embedding.add(0.0);
    }
    
    return embedding;
  }

  /// Calcular similitud entre dos embeddings usando distancia euclidiana normalizada
  double _calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      return 0.0;
    }
    
    // Calcular distancia euclidiana
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      sumSquaredDiff += diff * diff;
    }
    
    final distance = sqrt(sumSquaredDiff);
    
    // Normalizar a un rango de similitud (0 a 1)
    // Usamos una función exponencial inversa para convertir distancia a similitud
    final similarity = 1.0 / (1.0 + (distance / 100.0));
    
    return similarity;
  }

  /// Cerrar recursos
  void dispose() {
    _faceDetector.close();
  }
}
