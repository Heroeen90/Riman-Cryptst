import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';
import 'package:riman_cryptst/utils/vault_service.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // FORCE UNLOCK: Bypass lock screen status safely
    VaultService().setLocked(false);

    // Build App
    await tester.pumpWidget(const RimanCryptstApp());

    // Advance time to bypass splash screen (splash screen transitions take 2.5 seconds)
    for (int i = 0; i < 110; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();

    // Verify Tab Icons are fully visible and active inside dashboard viewport (Language Independent)
    expect(find.byIcon(Icons.monitor_heart), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.security), findsAtLeastNWidgets(1));

    // Swap language to English using the global language selector button
    final Finder languageButton = find.byIcon(Icons.language);
    expect(languageButton, findsOneWidget);
    await tester.tap(languageButton);
    await tester.pumpAndSettle();

    // Verify interface components remain operational post language toggling
    expect(find.byIcon(Icons.language), findsOneWidget);
  });
}
