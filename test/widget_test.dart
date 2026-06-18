import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riman_cryptst/main.dart';

void main() {
  testWidgets('Verify Riman Cryptst layout loads cleanly', (WidgetTester tester) async {
    // 1. ضخ بذور التطبيق داخل بيئة المحاكاة التلقائية للواجهة
    await tester.pumpWidget(const RimanCryptstApp());

    // 2. التحقق من أن شاشة الإقلاع أو البنية الأساسية تعمل وتجد العناصر الفريدة
    expect(find.byType(MaterialApp), findsOneWidget);

    // 3. محاكاة قفزات زمنية سريعة لتخطي أي مؤقتات نشطة في الـ Splash Screen
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // 4. استقرار وتصفية الواجهة النهائية بنجاح
    await tester.pump();
  });
}
