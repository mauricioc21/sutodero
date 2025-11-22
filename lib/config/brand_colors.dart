import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';

/// Colores corporativos de SU TODERO
/// Basados en el logo y la identidad de marca
class BrandColors {
  BrandColors._();

  // ==========================================
  // COLORES PRINCIPALES DE MARCA
  // ==========================================
  
  /// Dorado corporativo - Color principal de la marca
  /// Usado en: Logo, botones principales, acentos importantes
  static const Color primary = Color(0xFFFAB334);
  static const PdfColor primaryPdf = PdfColor(0.98, 0.70, 0.20); // FAB334
  
  /// Negro corporativo - Color de fondo y texto
  /// Usado en: Fondos, textos principales, contrastes
  static const Color dark = Color(0xFF1A1A1A);
  static const PdfColor darkPdf = PdfColor(0.10, 0.10, 0.10); // 1A1A1A
  
  /// Gris oscuro - Superficies secundarias
  /// Usado en: Cards, fondos de secciones, AppBar
  static const Color darkGray = Color(0xFF2C2C2C);
  static const PdfColor darkGrayPdf = PdfColor(0.17, 0.17, 0.17); // 2C2C2C
  
  /// Blanco - Texto y elementos claros
  /// Usado en: Texto sobre fondos oscuros, iconos, highlights
  static const Color white = Color(0xFFFFFFFF);
  static const PdfColor whitePdf = PdfColor(1.0, 1.0, 1.0);
  
  /// Beige claro - Fondos suaves, cajas de información
  /// Usado en: Fondos de secciones en PDFs, cajas informativas
  static const Color beigeClair = Color(0xFFF5E6C8);
  static const PdfColor beigeClairPdf = PdfColor(0.96, 0.90, 0.78); // F5E6C8
  
  // ==========================================
  // COLORES SECUNDARIOS
  // ==========================================
  
  /// Naranja - Acciones especiales (360°, alertas importantes)
  static const Color orange = Color(0xFFFF6B00);
  static const PdfColor orangePdf = PdfColor(1.0, 0.42, 0.0);
  
  /// Verde - Éxito, confirmaciones, estados positivos
  static const Color success = Color(0xFF4CAF50);
  static const PdfColor successPdf = PdfColor(0.30, 0.69, 0.31);
  
  /// Rojo - Errores, eliminaciones, estados negativos
  static const Color error = Color(0xFFF44336);
  static const PdfColor errorPdf = PdfColor(0.96, 0.26, 0.21);
  
  /// Amarillo - Advertencias, pendientes
  static const Color warning = Color(0xFFFFC107);
  static const PdfColor warningPdf = PdfColor(1.0, 0.76, 0.03);
  
  /// Azul - Información, enlaces, detalles
  static const Color info = Color(0xFF2196F3);
  static const PdfColor infoPdf = PdfColor(0.13, 0.59, 0.95);
  
  // ==========================================
  // GRADIENTES CORPORATIVOS
  // ==========================================
  
  /// Gradiente principal - Fondo de pantallas importantes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C2C2C), // Gris oscuro
      Color(0xFF1A1A1A), // Negro
    ],
  );
  
  /// Gradiente dorado - Para elementos destacados
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAB334), // Dorado
      Color(0xFFFF6B00), // Naranja
    ],
  );
  
  // ==========================================
  // SOMBRAS CORPORATIVAS
  // ==========================================
  
  /// Sombra dorada - Efecto glow para elementos importantes
  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 5,
    ),
  ];
  
  /// Sombra suave - Para elevación de cards
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ==========================================
  // LOGOS CORPORATIVOS
  // ==========================================
  
  /// Path del logo principal (con fondo transparente)
  static const String logoMain = 'assets/images/logo_sutodero_corporativo.png';
  
  /// Path del logo para fondos oscuros (amarillo)
  static const String logoYellow = 'assets/images/sutodero_logo_yellow.png';
  
  /// Path del logo para fondos claros (blanco)
  static const String logoWhite = 'assets/images/sutodero_logo_white.png';
  
  /// Path del logo transparente grande
  static const String logoTransparent = 'assets/images/logo_sutodero_transparente.png';
  
  /// Path del maestro todero (mascota)
  static const String logoMaestro = 'assets/images/maestro_todero_nobg.png';
  
  // ==========================================
  // INFORMACIÓN CORPORATIVA
  // ==========================================
  
  static const String companyName = 'SU TODERO';
  static const String companySlogan = 'No existe reparación, mantenimiento o remodelación que no hagamos';
  static const String companyPhone = '+57 313 816 0439';
  static const String companyEmail = 'info@sutodero.com';
  static const String companyWebsite = 'www.sutodero.com';
  static const String companyAddress = 'Cra 14b #112-85 Segundo Piso, Bogotá, Colombia';
  
  // ==========================================
  // HELPERS PARA PDF
  // ==========================================
  
  /// Obtener color PDF desde hex
  static PdfColor pdfColorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
    final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
    final b = int.parse(hex.substring(4, 6), radix: 16) / 255;
    return PdfColor(r, g, b);
  }
}
