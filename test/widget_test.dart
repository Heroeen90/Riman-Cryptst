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
    expect(find.text('مكتب المراقبة'), findsOneWidget);

    // Scroll to find the Text Shield tab
    final textShieldFinder = find.text('درع النصوص');
    final scrollableFinder = find.byType(Scrollable);
    await tester.scrollUntilVisible(textShieldFinder, 500.0, scrollable: scrollableFinder);
    expect(textShieldFinder, findsOneWidget);

    // Swap language to English using the language selector button
    final Finder languageButton = find.byIcon(Icons.language);
    expect(languageButton, findsOneWidget);
    await tester.tap(languageButton);
    await tester.pumpAndSettle();

    // Verify English tabs are now visible
    expect(find.text('Monitor Desk'), findsOneWidget);

    final textShieldEnFinder = find.text('Text Shield');
    await tester.scrollUntilVisible(textShieldEnFinder, 500.0, scrollable: scrollableFinder);
    expect(textShieldEnFinder, findsOneWidget);
  });
}
