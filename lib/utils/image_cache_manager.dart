import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Gestor de caché optimizado para imágenes de la app
/// Reduce uso de datos y mejora velocidad de carga
class ImageCacheManager {
  /// Widget optimizado para mostrar imágenes de Firebase
  /// Incluye caché, placeholders y manejo de errores
  static Widget buildCachedImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Placeholder mientras carga
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
        ),
        // Error si falla la carga
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        ),
        // Configuración de caché
        maxHeightDiskCache: 1080, // Máximo alto en caché
        maxWidthDiskCache: 1920, // Máximo ancho en caché
        memCacheHeight: 540, // Altura en memoria
        memCacheWidth: 960, // Ancho en memoria
      ),
    );
  }

  /// Thumbnails optimizados (para listas y grids)
  static Widget buildThumbnail({
    required String imageUrl,
    double size = 100,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        // Caché agresivo para thumbnails
        maxHeightDiskCache: 200,
        maxWidthDiskCache: 200,
        memCacheHeight: 100,
        memCacheWidth: 100,
      ),
    );
  }

  /// Limpiar caché de imágenes (útil para liberar espacio)
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }

  /// Obtener tamaño de caché
  static Future<int> getCacheSize() async {
    final cacheInfo = await DefaultCacheManager().getFileFromCache('');
    return 0; // Implementar si es necesario
  }
}
