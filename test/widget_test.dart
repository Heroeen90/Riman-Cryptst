import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // Build App
    await tester.pumpWidget(const RimanCryptstApp());

    // Verify tabs are visible
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Encryption'), findsOneWidget);
    expect(find.text('Key Generator'), findsOneWidget);
  });
}
