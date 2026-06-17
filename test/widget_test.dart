import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // 1. ضخ التطبيق داخل بيئة الاختبار
    await tester.pumpWidget(const RimanCryptstApp());

    // 2. التحقق من وجود عناصر شاشة الإقلاع (Splash Screen)
    expect(find.byIcon(Icons.all_inclusive), findsOneWidget);

    // 3. تمرير الوقت برمجياً لتجاوز المؤقت الدوري وتخطي شاشة الإقلاع
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // 4. تأكيد استقرار الواجهة بعد العبور
    await tester.pump();
  });
}
