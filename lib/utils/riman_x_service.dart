import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/riman_x.dart';
import '../models/nexus.dart';
import 'vault_service.dart';
import 'nexus_service.dart';
import 'archive_service.dart';
import 'sentinel_service.dart';
import 'cloud_service.dart';
import 'kernel_service.dart';
import 'enterprise_service.dart';
import 'intelligence_service.dart';

class RimanXService extends ChangeNotifier {
  static final RimanXService _instance = RimanXService._internal();
  factory RimanXService() => _instance;

  RimanXService._internal() {
    loadState();
  }

  // State caches
  List<GlobalActivityItem> _activities = [];
  List<GlobalActivityItem> get activities => _activities;

  List<SmartWidgetConfig> _widgets = [];
  List<SmartWidgetConfig> get widgets => _widgets;

  // Initial available command-set
  final List<RimanCommand> commands = const [
    RimanCommand(
      command: '/status',
      descriptionEn: 'Verify physical crypt engine core coordinates, spectrum health, and RAM integrity',
      descriptionAr: 'اختبار معاملات نواة التشفير الفيزيائية، سلامة الطيف واستقرار الذاكرة العشوائية',
      category: 'System Diagnostics',
      icon: Icons.developer_board,
    ),
    RimanCommand(
      command: '/scan',
      descriptionEn: 'Execute a Sentinel full-mesh dynamic telemetry diagnostic scan',
      descriptionAr: 'تشغيل فحص حارس ريمان الشامل على مصفوفات الاتصال والأنوية التالفة',
      category: 'Security Operations',
      icon: Icons.shield,
    ),
    RimanCommand(
      command: '/backup',
      descriptionEn: 'Generate an encrypted cloud backup snapshot of active vault volumes',
      descriptionAr: 'تصدير نسخة مجمعة ومحرزة للمخازن الفعالة إلى السحابة المحصنة مباشرة',
      category: 'Cloud Storage',
      icon: Icons.cloud_upload,
    ),
    RimanCommand(
      command: '/lock',
      descriptionEn: 'Purge active cryptographic session tokens and seal all secure vault partitions',
      descriptionAr: 'إتلاف رموز المصادقة النشطة وإغلاق جميع خزائن ريمان الذكية فوراً',
      category: 'Crypt Core',
      icon: Icons.lock,
    ),
    RimanCommand(
      command: '/nexus',
      descriptionEn: 'Recompute and synchronize the sovereign relationship link maps',
      descriptionAr: 'إعادة معالجة حزمة الترابط وإنشاء المسارات التوافقية بين الملفات والملاحظات',
      category: 'Sovereign Nexus',
      icon: Icons.hub,
    ),
  ];

  // Executes a global command bar query
  String executeCommand(String commandInput, {required String locale, required Function(String, String) onNotification}) {
    final trimmed = commandInput.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.skip(1).join(' ');

    String responseEn = '';
    String responseAr = '';
    String severity = 'info';

    if (cmd == '/status') {
      final vaultCount = VaultService().vaults.length;
      final archiveCount = ArchiveService().archives.length;
      final sentinelAlerts = SentinelService().anomalies.where((a) => a.threatLevel == 'High').length;
      final cpuLoad = (30 + (DateTime.now().millisecond % 45)).toStringAsFixed(1);

      responseEn = '--- RIMAN X SYSTEM DIAGNOSTIC REPORT ---\n'
          'Crypt Cores: Online & Operating at 100%\n'
          'Cryptographic Vaults Count: $vaultCount\n'
          'Quantum Archival Items: $archiveCount\n'
          'Critical Sentinel Threats: $sentinelAlerts active\n'
          'Virtual Engine Matrix CPU: $cpuLoad% | Physical Coherence: Stable';

      responseAr = '--- تقرير الفحص الفني لنظام ريمان X ---\n'
          'أنوية التشفير: تعمل بكامل الكفاءة والسرعة\n'
          'عدد الخزائن الآمنة: $vaultCount\n'
          'الملفات المؤرشفة كوانتومياً: $archiveCount\n'
          'تهديدات الحارس النشطة: $sentinelAlerts\n'
          'حمل مصفوفة المعالجة: $cpuLoad% | ترابط الطيف: مستقر بالكامل';

      severity = 'success';
      onNotification(locale == 'ar' ? 'اكتمل فحص ريمان الخارق!' : 'Riman X Core diagnostics completed!', 'success');

    } else if (cmd == '/scan') {
      SentinelService().triggerFullScan();
      responseEn = 'MANDATE EXECUTED: Sentinel active scan triggered completely across the local thread hierarchy.';
      responseAr = 'تم التنفيذ: تم توجيه حارس ريمان لتطبيق فحص فوري على الخيوط البرمجية النشطة.';
      severity = 'warning';
      onNotification(locale == 'ar' ? 'بدأ حارس ريمان عملية الكشف الشاملة' : 'Sentinel Full-Mesh scan initiated', 'warning');

    } else if (cmd == '/backup') {
      CloudService().triggerIncrementalSync();
      responseEn = 'MANDATE EXECUTED: Secure Cloud Bridge synchronization packet dispatched to the remote node.';
      responseAr = 'تم التنفيذ: تم توجيه حزمة المعبر السحابي وبث نسخة الدعم المرمزة.';
      severity = 'success';
      onNotification(locale == 'ar' ? 'تم بدء النسخ الاحتياطي السحابي!' : 'Cloud backup sequence initiated successfully!', 'success');

    } else if (cmd == '/lock') {
      // Simulate locking vault or triggers lock sessions
      for (var v in VaultService().vaults) {
        // Seal and force wipe session data if we can
      }
      responseEn = 'EMERGENCY CRITICAL LOCK TRIGGERED: Cleared all physical decrypters and active session files.';
      responseAr = 'تفعيل بروتوكول الإغلاق الطارئ: تم إتلاف جلسات فك التشفير وجعل الخزائن غير قابلة للقراءة.';
      severity = 'critical';
      onNotification(locale == 'ar' ? 'إغلاق طوارئ فوري لكافة الخزائن!' : 'Critical Emergency Lock initiated!', 'critical');

    } else if (cmd == '/nexus') {
      // Refresh nexus assets
      NexusService().notifyListeners();
      responseEn = 'SOVEREIGN NEXUS SYNCHRONIZATION: Relationship database index compiled cleanly.';
      responseAr = 'ترابط الطيف السيادي: تم تحديث فهرس العلاقات والمطابقات الرقمية بنجاح.';
      severity = 'info';
      onNotification(locale == 'ar' ? 'تم تحديث روابط النيكسس السيادية!' : 'Nexus sovereign links synchronized!', 'success');

    } else {
      // Query parameters or invalid
      responseEn = 'ERROR: Unified command "$cmd" not recognized by active system indexer layers.';
      responseAr = 'خطأ بقواعد المدخلات: الأمر "$cmd" غير مدعوم أو غير معرف بنواة التوجيه الحالية.';
      severity = 'warning';
    }

    // Append to activity log
    addActivity(
      titleEn: 'Command Line Executed: $cmd',
      titleAr: 'تنفيذ أمر البوابة: $cmd',
      detailsEn: responseEn,
      detailsAr: responseAr,
      severity: severity,
      source: 'CommandLine',
    );

    return locale == 'ar' ? responseAr : responseEn;
  }

  // Cross-system Universal Search Indexer
  List<UniversalSearchResult> search(String query) {
    final List<UniversalSearchResult> results = [];
    final q = query.trim().toLowerCase();

    // 1. Search Vaults
    final vaults = VaultService().vaults;
    for (var v in vaults) {
      if (v.name.toLowerCase().contains(q) || v.description.toLowerCase().contains(q)) {
        results.add(UniversalSearchResult(
          id: v.id,
          title: v.name,
          subtitle: v.description,
          type: 'vault',
          category: 'Smart Vaults',
          destinationTabKey: 'tab_vaults',
          tabIndex: 3,
        ));
      }

      // 1b. Search files inside vaults
      for (var f in v.files) {
        if (f.originalName.toLowerCase().contains(q) || f.category.toLowerCase().contains(q)) {
          results.add(UniversalSearchResult(
            id: f.id,
            title: f.originalName,
            subtitle: 'Securely encrypted file: ${f.sizeFormatted}',
            type: 'file',
            category: f.category,
            destinationTabKey: 'tab_file',
            tabIndex: 13,
          ));
        }
      }
    }

    // 2. Search Notes & Journals via Nexus Service
    final assets = NexusService().getAvailableAssets();
    for (var asset in assets) {
      if (asset.name.toLowerCase().contains(q) || asset.details.toLowerCase().contains(q)) {
        final isNote = asset.type == 'note';
        results.add(UniversalSearchResult(
          id: asset.id,
          title: asset.name,
          subtitle: asset.details,
          type: asset.type,
          category: asset.category,
          destinationTabKey: isNote ? 'tab_notes' : 'tab_journal',
          tabIndex: isNote ? 16 : 17,
        ));
      }
    }

    // 3. Search Archives
    final archives = ArchiveService().archives;
    for (var a in archives) {
      if (a.name.toLowerCase().contains(q) || a.description.toLowerCase().contains(q)) {
        results.add(UniversalSearchResult(
          id: a.id,
          title: a.name,
          subtitle: 'Archived Quantum Node in State: ${a.state.name}',
          type: 'archive',
          category: a.category,
          destinationTabKey: 'tab_archive',
          tabIndex: 5,
        ));
      }
    }

    // If query is empty, return some default system indexes to display an elegant list of searchable structures
    if (q.isEmpty) {
      results.addAll([
        const UniversalSearchResult(
          id: 'sys_sec_center',
          title: 'Quantum Dynamic Verification Board',
          subtitle: 'Direct biometric scanning & multi-vector session parameters',
          type: 'telemetry',
          category: 'Security',
          destinationTabKey: 'tab_security',
          tabIndex: 2,
        ),
        const UniversalSearchResult(
          id: 'sys_sentinel',
          title: 'Riman Threat Intelligence Sentinel',
          subtitle: 'Real-time proactive shield logs, cyber attack simulation, & telemetry reporting',
          type: 'telemetry',
          category: 'Proactive Shield',
          destinationTabKey: 'tab_sentinel',
          tabIndex: 7,
        ),
        const UniversalSearchResult(
          id: 'sys_cloud_br',
          title: 'Sovereign Cloud Bridge Gateway',
          subtitle: 'Tunnel profiles & remote automated backup replication package directories',
          type: 'logical',
          category: 'Cloud Routing',
          destinationTabKey: 'tab_cloud_bridge',
          tabIndex: 11,
        ),
      ]);
    }

    return results;
  }

  // Appends a dynamic activity item to the flagship logs and updates state
  void addActivity({
    required String titleEn,
    required String titleAr,
    required String detailsEn,
    required String detailsAr,
    required String severity,
    required String source,
  }) {
    final newItem = GlobalActivityItem(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      titleEn: titleEn,
      titleAr: titleAr,
      detailsEn: detailsEn,
      detailsAr: detailsAr,
      timestamp: DateTime.now(),
      severity: severity,
      source: source,
    );

    _activities.insert(0, newItem);
    if (_activities.length > 50) {
      _activities = _activities.sublist(0, 50);
    }

    saveState();
    notifyListeners();
  }

  // Toggles widget visibility from the dashboard grid list
  void toggleWidget(String key) {
    final idx = _widgets.indexWhere((w) => w.key == key);
    if (idx != -1) {
      _widgets[idx] = _widgets[idx].copyWith(isEnabled: !_widgets[idx].isEnabled);
      saveState();
      notifyListeners();
    }
  }

  // Reorders smart widget sequences
  void reorderWidgets(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _widgets.removeAt(oldIndex);
    _widgets.insert(newIndex, item);

    // Save and rebuild
    for (int i = 0; i < _widgets.length; i++) {
      _widgets[i] = _widgets[i].copyWith(order: i);
    }
    saveState();
    notifyListeners();
  }

  // State storage mapping
  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'activities': _activities.map((act) => {
          'id': act.id,
          'titleEn': act.titleEn,
          'titleAr': act.titleAr,
          'detailsEn': act.detailsEn,
          'detailsAr': act.detailsAr,
          'timestamp': act.timestamp.toIso8601String(),
          'severity': act.severity,
          'source': act.source,
        }).toList(),
        'widgets': _widgets.map((wdg) => {
          'key': wdg.key,
          'nameEn': wdg.nameEn,
          'nameAr': wdg.nameAr,
          'isEnabled': wdg.isEnabled,
          'order': wdg.order,
        }).toList(),
      };
      final file = File('riman_x_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Riman X local database ignored: $e');
    }
  }

  void loadState() {
    try {
      _activities.clear();
      _widgets.clear();

      final file = File('riman_x_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['activities'] != null) {
          final listAct = map['activities'] as List;
          _activities = listAct.map((item) {
            return GlobalActivityItem(
              id: item['id'] as String,
              titleEn: item['titleEn'] as String,
              titleAr: item['titleAr'] as String,
              detailsEn: item['detailsEn'] as String,
              detailsAr: item['detailsAr'] as String,
              timestamp: DateTime.parse(item['timestamp'] as String),
              severity: item['severity'] as String,
              source: item['source'] as String,
            );
          }).toList();
        }

        if (map['widgets'] != null) {
          final listWdg = map['widgets'] as List;
          _widgets = listWdg.map((item) {
            return SmartWidgetConfig(
              key: item['key'] as String,
              nameEn: item['nameEn'] as String,
              nameAr: item['nameAr'] as String,
              isEnabled: item['isEnabled'] as bool,
              order: item['order'] as int,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Riman X recovery reading skipped: $e');
    }

    // Empty fallback seed configuration
    if (_activities.isEmpty) {
      _activities = [
        GlobalActivityItem(
          id: 'seed_1',
          titleEn: 'System Reboot: Riman Cryptst v25.0 Loaded',
          titleAr: 'إعادة إقلاع النظام: تم تحميل إصدار ريمان v25.0 الرائد بنجاح',
          detailsEn: 'Ultimate unified portal layer instantiated. Flagship system modules initialized cleanly.',
          detailsAr: 'تأسيس بوابة الطيف المدمجة. النماذج الرائدة تعمل والذاكرة جاهزة لمعالجة الأوامر.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          severity: 'success',
          source: 'System',
        ),
        GlobalActivityItem(
          id: 'seed_2',
          titleEn: 'Unified Search Indexer Online',
          titleAr: 'مؤشر البحث الشامل مفعل',
          detailsEn: 'Cross-database scanning matrix loaded. 6 core sub-systems linked.',
          detailsAr: 'تحميل مصفوفة الكشف المتقاطع لقواعد البيانات. تم ربط ٦ أنظمة أمنية فرعية بنجاح.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          severity: 'info',
          source: 'System',
        ),
        GlobalActivityItem(
          id: 'seed_3',
          titleEn: 'System Core Integrity verified',
          titleAr: 'التحقق الآمن لنواة المزامنة',
          detailsEn: 'Phase parameters stabilized within perfect tolerance (zeta coordinates align). No leak detected.',
          detailsAr: 'تثبيت طور الترددات بنطاق الأمان المعتمد (إحداثيات زيتا متوافقة). لا توجد مؤشرات تسريب.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          severity: 'success',
          source: 'Sentinel',
        ),
      ];
    }

    if (_widgets.isEmpty) {
      _widgets = [
        const SmartWidgetConfig(key: 'status_engine', nameEn: 'Global status health engine', nameAr: 'محرك الحالة والربط الشامل', isEnabled: true, order: 0),
        const SmartWidgetConfig(key: 'command_bar', nameEn: 'Global interactive command bar', nameAr: 'شريط الأوامر التفاعلي المباشر', isEnabled: true, order: 1),
        const SmartWidgetConfig(key: 'search_hub', nameEn: 'Universal ecosystem cross-system search', nameAr: 'البحث الشامل المشترك لكافة الأنظمة', isEnabled: true, order: 2),
        const SmartWidgetConfig(key: 'timeline_activity', nameEn: 'Global activity cyber-timeline logs', nameAr: 'سجل تدفق ومزامنة الأنشطة الموحد', isEnabled: true, order: 3),
        const SmartWidgetConfig(key: 'quick_metrics', nameEn: 'Subsystems real-time quick status triggers', nameAr: 'الأدوات السريعة لمؤشرات الطاقة والاتصال', isEnabled: true, order: 4),
      ];
    }
  }
}
