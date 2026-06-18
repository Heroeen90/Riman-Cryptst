# Riman Cryptst - Sovereign Cryptographic Suite

مجموعة برمجيات التشفير السري الهجين المتقدمة والمصممة خصيصاً للتثبيت والعمل على بيئات الهواتف الذكية ومتصفحات الويب المستقلة، مع واجهات وتكاملات رياضية متطورة تعتمد على أصفار ريمان (Riemann Zeta Zeros).

---

## 🏗️ مخطط الهيكل المعماري للمشروع (Definitive Architecture Directory Tree)

لقد تم توحيد هذا المشروع وتحصين بنيته بالكامل للعمل بنجاح في بيئات التطوير والإنتاج، وتأكيد البناء النظيف لتطبيق الأندرويد (APK) والويب على حد سواء. فيما يلي شجرة الدليل الشاملة والنهائية لجميع ملفات النظام ومجلداته:

```text
├── .github/
│   └── workflows/
│       └── rimating_pipeline.yml  <-- (خط الأنابيب الموحد والوحيد لـ CI/CD. تم حذف android-build.yml تماماً لمنع التعارض)
├── android/
│   ├── app/
│   │   ├── build.gradle           <-- (الإصدار المحصن: compileSdk=34، minSdk=21، targetSdk=34 وتوافق كامل لـ JDK 17)
│   │   └── src/main/kotlin/com/riman/cryptst/MainActivity.kt  <-- (تضمين FlutterActivity آمن وصحيح 100%)
│   ├── build.gradle               <-- (إعدادات المستودعات والمستودع المركزي لـ Google و Maven)
│   └── settings.gradle            <-- (روابط المكونات الإضافية وتوافق Kotlin 2.0+ و Gradle)
├── lib/
│   ├── main.dart                  <-- (المدخل الرئيسي للتطبيق مع التبويبات والمباني الرياضية الهجينة الـ 22)
│   ├── models/                    <-- (جداول وبنى البيانات الأساسية والمستودعات الأمنية لنظام التشفير)
│   │   ├── archive_engine.dart
│   │   ├── cloud_bridge.dart
│   │   ├── enterprise_core.dart
│   │   ├── forensics.dart
│   │   ├── intelligence.dart
│   │   ├── nexus.dart
│   │   ├── security_kernel.dart
│   │   ├── sentinel.dart
│   │   └── riman_x.dart
│   ├── utils/                     <-- (محركات التشفير المتقدمة ومحركات التشفير والتحليل الرياضي)
│   │   ├── forensic_service.dart
│   │   ├── in_memory_crypto_wrapper.dart
│   │   ├── keyboard_security_service.dart
│   │   ├── network_pinning_service.dart  <-- (مصحح بالكامل: معالجة SHA بنوع البيانات SHA.SHA256 الصحيح)
│   │   ├── secure_platform_channel.dart   <-- (مصحح بالكامل: ترتيب الاستيرادات في السطور الأولى بالاعلى)
│   │   ├── secret_splitter.dart
│   │   └── sentinel_service.dart
│   └── widgets/                   <-- (جميع واجهات ولوحات التحكم المتقدمة لواجهة المستخدم التفاعلية)
│       ├── archive_dashboard.dart
│       ├── cloud_dashboard.dart
│       ├── command_bar.dart
│       ├── deception_radar.dart
│       ├── file_shield.dart
│       ├── flutter_exporter.dart
│       ├── forensics_dashboard.dart
│       ├── hud_notification_overlay.dart
│       ├── intelligence_dashboard.dart
│       ├── kernel_dashboard.dart
│       ├── key_generator.dart
│       ├── nexus_dashboard.dart   <-- (مصحح: تحديث آمن للخصائص دون استخدام غير مباشر لـ notifyListeners)
│       ├── reorderable_dashboard_grid.dart
│       ├── riman_flagship_hub.dart
│       ├── riman_x_home.dart
│       ├── secure_gallery.dart
│       ├── secure_journal.dart
│       ├── secure_media.dart
│       ├── secure_notes.dart
│       ├── security_center.dart
│       ├── sentinel_dashboard.dart
│       ├── smart_category_selector.dart  <-- (مصحح: استخدام Colors.pink ومنع حدوث أخطاء تشغيل Platform على الويب)
│       ├── smart_vaults_tab.dart
│       ├── sovereign_dashboard.dart
│       ├── spectrum_analyzer_tab.dart
│       ├── text_shield.dart
│       ├── time_capsules.dart
│       └── workspace_dashboard.dart
├── test/
│   └── widget_test.dart          <-- (اختبارات التحقق من دورة حياة تطبيق MaterialApp بنجاح وموثوقية)
├── web/
│   ├── index.html                 <-- (مهيأ بـ base href="/Riman-Cryptst/" للرفع الصحيح على صفحات GitHub Pages)
│   └── manifest.json
└── pubspec.yaml                   <-- (الملف التعريفي لحزم Dart و Flutter وتكاملاتها بشكل آمن ومتوافق)
```

---

## 🛠️ تفاصيل المشاكل التي تم تتبعها واصلاحها لضمان بناء APK سليم

تم تتبع وفهم المشروع بالكامل واكتشاف كافة الأخطاء الناتجة عن تعارض الشيفرات وخصائص التحليل والترجمة، وتمت تسويتها بنجاح تام لتسهيل عملية البناء المباشر للـ APK دون أي عوائق:

1. **إصلاح خطأ `network_pinning_service.dart`**:
   - **السبب**: كان هناك تعارض في إرسال متغير نصي `"SHA256"` إلى بارامتر يتوقع كائناً من فئة الـ `SHA` المخصصة بالمكتبة.
   - **الحل**: تعديل السطر رقم 10 ليتعامل مع الـ Enumerator الصحيح والمخصص من المكتبة وهو `SHA.SHA256` لتتوافق أنواع البيانات تماماً.

2. **إصلاح خطأ `secure_platform_channel.dart`**:
   - **السبب**: وجود توجيه الاستيراد `import 'dart:convert';` في أسفل الملف بعد تعريف الكلاس والدوال، وهو ما يخالف قواعد الفحص البرمجي الصارمة لـ Dart التي تتطلب وجود جميع الاستيرادات في السطر الأول قبل الإعلانات البرمجية.
   - **الحل**: تم نقل استيراد مكتبة التحويل التلقائي للأعلى مع المستوردات وتمت تصفية بقية الأكواد بشكل سليم.

3. **إصلاح خطأ `smart_category_selector.dart`**:
   - **السبب (الأول)**: محاولة استخدام `Colors.rose` وهو غير معرف في فئة مكتبة الألوان الافتراضية للـ Material Design في إطار Flutter، مما تسبب في فشل الترجمة.
   - **الحل**: تم استبداله باللون المعتمد والمحبب للواجهة `Colors.pink` بشكل متوافق 100%.
   - **السبب (الثاني)**: استدعاء `Platform.environment` على الويب بطريقة عشوائية كان يؤدي في بعض الحالات لخلل، وتم تضمين شرط آمن لمعالجة بيئة فحص الويب تلقائياً باستخدام `kIsWeb` لمنع الانهيار أثناء تشغيل التطبيق في المتصفح.

4. **إصلاح خطأ استدعاء `notifyListeners()` في لوحة التحكم**:
   - **السبب**: كان كود `nexus_dashboard.dart` يستدعي التابع المحمي `_nexusService.notifyListeners();` مباشرة من خارج فئته، وهو ما يمنعه محلل Dart الصارم.
   - **الحل**: تم توفير دالة واجهة برمجية آمنة وموثقة بداخل ملف `nexus_service.dart` باسم `triggerUpdate()` والتي تقوم باستدعاء `notifyListeners()` داخلياً ومحلياً، واستبدال الاستدعاء الخارجي بها ليكون مطابقاً لأعلى معايير جودة الشيفرة لـ Flutter.

5. **توحيد خط الأنابيب (CI/CD Workflows)**:
   - **السبب**: تشغيل ملفين منفصلين هما `android-build.yml` و`rimating_pipeline.yml` كان يسبب صراعات وتعقيدات برمجية على خوادم GitHub Runner ويبعث بنتائج خاطئة.
   - **الحل**: تم مسح ملف `android-build.yml` نهائياً، وتم توجيه كامل عمليات الفحص البرمجي (Linter Analysis)، الاختبارات (Tests)، وبناء الويب وتصدير الـ APK (بصيغتي Debug و Release) وتلقيمهما بخاصية تخطي فحص اعتمادات النظام الأندرويدي المحدثة `--android-skip-build-dependency-validation` بأمان داخل مستند موحد وقوي هو `rimating_pipeline.yml`.

---

## 📲 كيفية البناء والتجربة محلياً على جهاز الأندرويد المحمول

لإنشاء وتصدير تطبيقك بنجاح من داخل مستودع التطوير الذاتي الخاص بك:

```bash
# 1. تنظيف الكاشات السابقة وإعادة هيكلة الملفات
flutter clean

# 2. استدعاء وتوريد كافة الحزم والاعتمادات الحديثة
flutter pub get

# 3. التأكد من خلو المشروع تماماً من أي عيوب تحليلية
flutter analyze

# 4. تشغيل اختبارات التحقق من بيئة العمل والتنفيذ
flutter test

# 5. إصدار ملف الـ APK المخصص
flutter build apk --release --android-skip-build-dependency-validation
```

الملف المخرج سيكون متاحاً بشكل مباشر بداخل المسار:
`build/app/outputs/flutter-apk/app-release.apk`
ويمكنك نقله وتثبيته فوراً على جهاز الأندرويد الخاص بك والتمتع بالحقيبة التشفيرية الفائقة والمتكاملة!
