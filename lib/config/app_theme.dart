import 'package:flutter/material.dart';

/// Tema corporativo unificado de SU TODERO
/// Colores: Negro, Blanco, Gris, Amarillo Corporativo
class AppTheme {
  // Colores Corporativos
  static const Color negro = Color(0xFF000000);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisOscuro = Color(0xFF2C2C2C);
  static const Color grisClaro = Color(0xFF757575);
  static const Color dorado = Color(0xFFFAB334); // Amarillo corporativo Su Todero
  static const Color beigeClaro = Color(0xFFF5E6C8);
  
  // Colores de Estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Tema principal de la app
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Colores primarios
      primaryColor: dorado,
      scaffoldBackgroundColor: negro,
      
      // ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: dorado,
        secondary: dorado,
        surface: grisOscuro,
        background: negro,
        error: error,
        onPrimary: negro,
        onSecondary: negro,
        onSurface: blanco,
        onBackground: blanco,
        onError: blanco,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: grisOscuro,
        foregroundColor: dorado,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dorado,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(color: dorado),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 4,
        color: grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Botones Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dorado,
          foregroundColor: negro,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          elevation: 4,
        ),
      ),
      
      // Botones de Texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dorado,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Botones con Borde
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dorado,
          side: const BorderSide(color: dorado, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Inputs/TextFields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grisOscuro,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dorado, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: grisClaro),
        hintStyle: const TextStyle(color: grisClaro),
        prefixIconColor: dorado,
        suffixIconColor: grisClaro,
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: dorado,
        foregroundColor: negro,
        elevation: 6,
      ),
      
      // IconTheme
      iconTheme: const IconThemeData(
        color: dorado,
        size: 24,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: grisOscuro,
        thickness: 1,
        space: 32,
      ),
      
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: grisOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dorado,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: blanco,
        ),
      ),
      
      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: grisOscuro,
        contentTextStyle: TextStyle(color: blanco),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return dorado;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(negro),
        side: const BorderSide(color: dorado, width: 2),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return dorado;
          }
          return grisClaro;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return dorado.withValues(alpha: 0.5);
          }
          return grisOscuro;
        }),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: dorado,
      ),
      
      // Text Themes
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: dorado),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: blanco),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: blanco),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: blanco),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: blanco),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: blanco),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: blanco),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: blanco),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: blanco),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: blanco),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: blanco),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: grisClaro),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: blanco),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: blanco),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: grisClaro),
      ),
    );
  }

  /// Decoración de container corporativo
  static BoxDecoration containerDecoration({
    Color? color,
    bool withBorder = false,
    bool withShadow = false,
  }) {
    return BoxDecoration(
      color: color ?? grisOscuro,
      borderRadius: BorderRadius.circular(16),
      border: withBorder ? Border.all(color: dorado, width: 2) : null,
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: dorado.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Gradiente corporativo
  static LinearGradient get gradientBackground {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A1A1A),
        negro,
      ],
    );
  }

  /// Sombra dorada
  static List<BoxShadow> get goldGlow {
    return [
      BoxShadow(
        color: dorado.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ];
  }

  /// Padding estándar
  static const EdgeInsets paddingAll = EdgeInsets.all(24);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets paddingSmall = EdgeInsets.all(12);
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  
  /// Espaciado estándar
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;
  
  // Alias de spacing
  static const double spacingSM = spacingSmall;
  static const double spacingMD = spacingMedium;
  static const double spacingLG = 20.0;
  static const double spacingXL = spacingLarge;
  static const double spacing2XL = spacingXLarge;
  static const double spacing3XL = 48.0;
  
  /// Border Radius estándar
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;
  
  // Alias de radius
  static const double radiusSM = radiusSmall;
  static const double radiusMD = radiusMedium;
  static const double radiusLG = radiusLarge;
}
