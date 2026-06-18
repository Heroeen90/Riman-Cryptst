import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // Build App
    await tester.pumpWidget(const RimanCryptstApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Arabic tabs are visible by default
    expect(find.text('مكتب المراقبة'), findsWidgets);

    // Swap language to English using the language selector button
    final languageButton = find.byIcon(Icons.language);
    expect(languageButton, findsOneWidget);
    await tester.tap(languageButton);
    await tester.pumpAndSettle();

    // Verify English tabs are now visible
    expect(find.text('Monitor Desk'), findsWidgets);
  });
}
