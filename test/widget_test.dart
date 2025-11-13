// Test básico para SUTODERO app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sutodero/main.dart';

void main() {
  testWidgets('SUTODERO app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SuToderoApp());

    // Verificar que el splash screen se muestra
    expect(find.text('SUTODERO'), findsOneWidget);
  });
}
