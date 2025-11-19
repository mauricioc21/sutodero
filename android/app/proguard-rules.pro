# ProGuard rules for SU TODERO
# Optimizaciones para rendimiento sin romper funcionalidad

# ============================================================================
# REGLAS GENERALES DE FLUTTER
# ============================================================================

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ============================================================================
# FIREBASE
# ============================================================================

# Firebase Core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }

# Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# ============================================================================
# BLUETOOTH (Flutter Blue Plus)
# ============================================================================

-keep class com.boskokg.flutter_blue_plus.** { *; }
-dontwarn com.boskokg.flutter_blue_plus.**

# Android Bluetooth
-keep class android.bluetooth.** { *; }
-dontwarn android.bluetooth.**

# ============================================================================
# IMAGE COMPRESSION
# ============================================================================

-keep class com.flutter_image_compress.** { *; }
-dontwarn com.flutter_image_compress.**

# ============================================================================
# CAMERA & IMAGE PICKER
# ============================================================================

-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# ============================================================================
# PERMISSIONS
# ============================================================================

-keep class com.baseflow.permissionhandler.** { *; }

# ============================================================================
# PATH PROVIDER
# ============================================================================

-keep class io.flutter.plugins.pathprovider.** { *; }

# ============================================================================
# CACHED NETWORK IMAGE
# ============================================================================

-keep class com.example.flutter_cache_manager.** { *; }

# ============================================================================
# PDF GENERATION
# ============================================================================

-keep class net.sf.andpdf.** { *; }
-dontwarn net.sf.andpdf.**

# ============================================================================
# QR CODE
# ============================================================================

-keep class net.touchcapture.qr.flutterqr.** { *; }

# ============================================================================
# ML KIT (Face Detection)
# ============================================================================

-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ============================================================================
# KOTLIN & COROUTINES
# ============================================================================

-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ============================================================================
# GSON (si se usa para serialización)
# ============================================================================

-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# ============================================================================
# MODELOS DE DATOS
# ============================================================================

# Mantener todos los modelos de datos (para serialización JSON)
-keep class sutodero.app.models.** { *; }
-keepclassmembers class sutodero.app.models.** { *; }

# ============================================================================
# OPTIMIZACIONES GENERALES
# ============================================================================

# Optimización de código
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Mantener números de línea para debugging
-keepattributes SourceFile,LineNumberTable

# Renombrar archivos de origen para ofuscar
-renamesourcefileattribute SourceFile

# ============================================================================
# PREVENIR ADVERTENCIAS
# ============================================================================

# Ignorar advertencias de librerías externas
-dontwarn com.google.android.gms.**
-dontwarn org.apache.http.**
-dontwarn android.net.http.**

# ============================================================================
# NATIVE LIBRARIES
# ============================================================================

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================================================
# ENUMS
# ============================================================================

# Mantener enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================================
# PARCELABLES
# ============================================================================

-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ============================================================================
# FIN DE REGLAS
# ============================================================================
