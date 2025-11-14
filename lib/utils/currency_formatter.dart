import 'package:flutter/services.dart';

/// Formateador de precios en formato colombiano
/// Ejemplo: 1250000 -> 1.250.000
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todos los caracteres no numéricos
    final numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numericString.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Formatear con puntos de miles
    final formatted = _formatWithDots(numericString);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(String number) {
    // Convertir a lista de caracteres y reversar
    final chars = number.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    // Reversar de nuevo para obtener el orden correcto
    return buffer.toString().split('').reversed.join('');
  }
}

/// Formatea un número a formato colombiano con puntos de miles
/// Ejemplo: 1250000 -> "1.250.000"
String formatCurrency(num value) {
  final intValue = value.toInt();
  final string = intValue.toString();
  final chars = string.split('').reversed.toList();
  final buffer = StringBuffer();

  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(chars[i]);
  }

  return buffer.toString().split('').reversed.join('');
}

/// Convierte un string formateado a número
/// Ejemplo: "1.250.000" -> 1250000
int? parseCurrencyString(String formattedValue) {
  final numericString = formattedValue.replaceAll('.', '');
  return int.tryParse(numericString);
}

/// Widget helper para formatear precios en display
/// Ejemplo: Text(formatCurrencyWithSymbol(1250000)) -> "\$1.250.000"
String formatCurrencyWithSymbol(num value, {String symbol = '\$'}) {
  return '$symbol${formatCurrency(value)}';
}
