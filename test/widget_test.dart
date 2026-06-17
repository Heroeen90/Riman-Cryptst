import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';
import 'package:riman_cryptst/utils/vault_service.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // FORCE UNLOCK: bypass the lock screen programmatically for safe pipeline runner compliance
    VaultService().setLocked(false);

    // Build App
    await tester.pumpWidget(const RimanCryptstApp());

    // Advance time to bypass splash screen (splash screen transitions take 2.5 seconds)
    for (int i = 0; i < 110; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();

    // Verify Arabic tabs are now fully visible since vault is unlocked cleanly
    expect(find.text('مكتب المراقبة'), findsOneWidget);
    expect(find.text('درع النصوص'), findsOneWidget);

    // Swap language to English using the language selector button
    final Finder languageButton = find.byIcon(Icons.language);
    expect(languageButton, findsOneWidget);
    await tester.tap(languageButton);
    await tester.pumpAndSettle();

    // Verify English tabs are now visible
    expect(find.text('Monitor Desk'), findsOneWidget);
    expect(find.text('Text Shield'), findsOneWidget);
  });
}
