import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/intelligence.dart';

class IntelligenceService extends ChangeNotifier {
  static final IntelligenceService _instance = IntelligenceService._internal();
  factory IntelligenceService() => _instance;

  IntelligenceService._internal() {
    loadState();
  }

  // Lists of intelligence metrics
  List<IntelligenceInsight> _insights = [];
  List<IntelligenceInsight> get insights => _insights;

  List<RiskMetricNode> _riskMetrics = [];
  List<RiskMetricNode> get riskMetrics => _riskMetrics;

  List<StorageTelemetryPoint> _storageHistory = [];
  List<StorageTelemetryPoint> get storageHistory => _storageHistory;

  List<BehaviorAuditReport> _behaviorReports = [];
  List<BehaviorAuditReport> get behaviorReports => _behaviorReports;

  // Intelligence Core Scores
  double _securityIntelligenceScore = 88.5; // Scale of 0 - 100
  double get securityIntelligenceScore => _securityIntelligenceScore;

  double _storageHealthScore = 92.0; // Scale of 0 - 100
  double get storageHealthScore => _storageHealthScore;

  // Generate dynamic recommendation or insight list
  void addInsight({
    required InsightCategory category,
    required String titleEn,
    required String titleAr,
    required String descEn,
    required String descAr,
    required InsightSeverity severity,
    required String recEn,
    required String recAr,
  }) {
    final now = DateTime.now();
    final newId = 'ins_${now.millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    
    final newInsight = IntelligenceInsight(
      insightId: newId,
      category: category,
      titleEn: titleEn,
      titleAr: titleAr,
      descriptionEn: descEn,
      descriptionAr: descAr,
      severity: severity,
      recommendationEn: recEn,
      recommendationAr: recAr,
      timestamp: now,
    );

    _insights.insert(0, newInsight);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Action / Mitigate an insight
  void resolveInsight(String id) {
    final idx = _insights.indexWhere((element) => element.insightId == id);
    if (idx != -1) {
      final old = _insights[idx];
      _insights[idx] = IntelligenceInsight(
        insightId: old.insightId,
        category: old.category,
        titleEn: old.titleEn,
        titleAr: old.titleAr,
        descriptionEn: old.descriptionEn,
        descriptionAr: old.descriptionAr,
        severity: old.severity,
        isResolved: true,
        recommendationEn: old.recommendationEn,
        recommendationAr: old.recommendationAr,
        timestamp: old.timestamp,
      );

      _recalculateScores();
      saveState();
      notifyListeners();
    }
  }

  // Terminate or remove an insight entirely
  void dismissInsight(String id) {
    _insights.removeWhere((element) => element.insightId == id);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Simulate logging a behavior pattern
  void recordUserBehavior({
    required String actorRole,
    required String operationEn,
    required String operationAr,
    required double anomalyConf,
    required bool atypic,
  }) {
    final now = DateTime.now();
    final newId = 'beh_${now.millisecondsSinceEpoch}_${math.Random().nextInt(100)}';

    final report = BehaviorAuditReport(
      recordId: newId,
      actorRole: actorRole,
      operationTypeEn: operationEn,
      operationTypeAr: operationAr,
      anomalyConfidence: anomalyConf,
      isSuspectedAtypical: atypic,
      eventTime: now,
    );

    _behaviorReports.insert(0, report);
    if (_behaviorReports.length > 50) {
      _behaviorReports.removeLast();
    }

    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Trigger local analyzer scanner
  void runFullIntelligenceReassessment() {
    final rand = math.Random();
    
    // Scrambling risk metric nodes subtly to represent live calculation
    for (int i = 0; i < _riskMetrics.length; i++) {
      final old = _riskMetrics[i];
      final adjustment = (rand.nextDouble() * 6.0) - 3.0; // +/- 3 points
      final newScore = (old.currentScore + adjustment).clamp(5.0, 95.0);
      
      String labelEn = 'Stable Operations';
      String labelAr = 'عمليات مستقرة وآمنة';
      if (newScore > 75.0) {
        labelEn = 'High Vulnerability Spike';
        labelAr = 'تهديد متنامي الخطورة';
      } else if (newScore > 50.0) {
        labelEn = 'Moderate Operational Drift';
        labelAr = 'مخاطر طفيفة تحت المراقبة';
      }

      _riskMetrics[i] = RiskMetricNode(
        metricId: old.metricId,
        nameEn: old.nameEn,
        nameAr: old.nameAr,
        currentScore: newScore,
        statusLabelEn: labelEn,
        statusLabelAr: labelAr,
      );
    }

    // append simulated storage telemetry point
    final lastPoint = _storageHistory.isNotEmpty 
        ? _storageHistory.last 
        : StorageTelemetryPoint(
            recordTime: DateTime.now().subtract(const Duration(days: 1)),
            totalFilesTracked: 13,
            symmetricCipherBytes: 15728640,
            asymmetricCipherBytes: 2097152,
            cumulativeGrowthRate: 2.1
          );

    final newFiles = lastPoint.totalFilesTracked + rand.nextInt(3);
    final addSymmetric = rand.nextInt(1048576) + 128000; // random byte increments
    final addAsymmetric = rand.nextInt(262144);
    
    _storageHistory.add(StorageTelemetryPoint(
      recordTime: DateTime.now(),
      totalFilesTracked: newFiles,
      symmetricCipherBytes: lastPoint.symmetricCipherBytes + addSymmetric,
      asymmetricCipherBytes: lastPoint.asymmetricCipherBytes + addAsymmetric,
      cumulativeGrowthRate: lastPoint.cumulativeGrowthRate + (rand.nextDouble() * 0.4),
    ));

    if (_storageHistory.length > 30) {
      _storageHistory.removeAt(0);
    }

    // Intelligently trigger behavior logs periodically
    if (rand.nextDouble() > 0.4) {
      final anomalyChance = rand.nextDouble();
      final isHighAnomaly = anomalyChance > 0.85;
      recordUserBehavior(
        actorRole: 'SecOpsOperator',
        operationEn: isHighAnomaly 
            ? 'Atypical Multi-Vault Access request bursts detected' 
            : 'Standard smart-vault storage queries accomplished',
        operationAr: isHighAnomaly
            ? 'اشتباه بطلبات متكررة للولوج إلى هرم الخزائن المشفرة'
            : 'استعلام نظامي وازن عن سجلات وملفات الخزنة الذكية',
        anomalyConf: anomalyChance,
        atypic: isHighAnomaly,
      );
    }

    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Dynamic formula based intelligence index calculation loops
  void _recalculateScores() {
    double secScore = 95.0;
    double storScore = 96.0;

    // 1. Deduct from Security Intelligence score for active insights
    for (var insight in _insights) {
      if (!insight.isResolved) {
        switch (insight.severity) {
          case InsightSeverity.critical:
            secScore -= 12.0;
            break;
          case InsightSeverity.high:
            secScore -= 6.5;
            break;
          case InsightSeverity.medium:
            secScore -= 3.0;
            break;
          case InsightSeverity.low:
            secScore -= 1.0;
            break;
        }
      }
    }

    // 2. Deduct security score for highly atypical behavior anomalies
    final highAnomalies = _behaviorReports.where((b) => b.isSuspectedAtypical).length;
    secScore -= (highAnomalies * 4.0);

    // 3. Storage index calculation based on unrecovered storage optimization entries
    final storageUnresolved = _insights.where((i) => i.category == InsightCategory.storage && !i.isResolved).length;
    storScore -= (storageUnresolved * 7.0);

    // 4. Incorporate active risk metrics high value flags
    for (var r in _riskMetrics) {
      if (r.currentScore > 75.0) {
        secScore -= 4.0;
      }
    }

    _securityIntelligenceScore = secScore.clamp(10.0, 100.0);
    _storageHealthScore = storScore.clamp(15.0, 100.0);
  }

  // Persistence methods
  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'insights': _insights.map((i) => i.toJson()).toList(),
        'riskMetrics': _riskMetrics.map((r) => r.toJson()).toList(),
        'storageHistory': _storageHistory.map((s) => s.toJson()).toList(),
        'behaviorReports': _behaviorReports.map((b) => b.toJson()).toList(),
        'securityIntelligenceScore': _securityIntelligenceScore,
        'storageHealthScore': _storageHealthScore,
      };

      final file = File('riman_intelligence_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Intelligence DB save failed (expected sandbox fallback): $e');
    }
  }

  void loadState() {
    try {
      final file = File('riman_intelligence_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['insights'] != null) {
          final li = map['insights'] as List;
          _insights = li.map((i) => IntelligenceInsight.fromJson(i as Map<String, dynamic>)).toList();
        }
        if (map['riskMetrics'] != null) {
          final lr = map['riskMetrics'] as List;
          _riskMetrics = lr.map((r) => RiskMetricNode.fromJson(r as Map<String, dynamic>)).toList();
        }
        if (map['storageHistory'] != null) {
          final ls = map['storageHistory'] as List;
          _storageHistory = ls.map((s) => StorageTelemetryPoint.fromJson(s as Map<String, dynamic>)).toList();
        }
        if (map['behaviorReports'] != null) {
          final lb = map['behaviorReports'] as List;
          _behaviorReports = lb.map((b) => BehaviorAuditReport.fromJson(b as Map<String, dynamic>)).toList();
        }
        _securityIntelligenceScore = (map['securityIntelligenceScore'] as num?)?.toDouble() ?? 88.5;
        _storageHealthScore = (map['storageHealthScore'] as num?)?.toDouble() ?? 92.0;
      } else {
        _seedDefaults();
      }
    } catch (e) {
      debugPrint('Intelligence engine loading failure, falling back to database seeding: $e');
      _seedDefaults();
    }
  }

  void resetIntelligenceDataset() {
    _insights.clear();
    _riskMetrics.clear();
    _storageHistory.clear();
    _behaviorReports.clear();
    _seedDefaults();
    notifyListeners();
  }

  void _seedDefaults() {
    final now = DateTime.now();

    // 1. Storage trends points seed (simulating growth over 5 periods)
    _storageHistory = [
      StorageTelemetryPoint(
        recordTime: now.subtract(const Duration(days: 4)),
        totalFilesTracked: 8,
        symmetricCipherBytes: 8388608, // 8MB
        asymmetricCipherBytes: 524288, // 512KB
        cumulativeGrowthRate: 1.0,
      ),
      StorageTelemetryPoint(
        recordTime: now.subtract(const Duration(days: 3)),
        totalFilesTracked: 10,
        symmetricCipherBytes: 11534336, // 11MB
        asymmetricCipherBytes: 1048576, // 1MB
        cumulativeGrowthRate: 1.4,
      ),
      StorageTelemetryPoint(
        recordTime: now.subtract(const Duration(days: 2)),
        totalFilesTracked: 11,
        symmetricCipherBytes: 14680064, // 14MB
        asymmetricCipherBytes: 1048576, // 1MB
        cumulativeGrowthRate: 1.8,
      ),
      StorageTelemetryPoint(
        recordTime: now.subtract(const Duration(days: 1)),
        totalFilesTracked: 13,
        symmetricCipherBytes: 15728640, // 15MB
        asymmetricCipherBytes: 2097152, // 2MB
        cumulativeGrowthRate: 2.1,
      ),
    ];

    // 2. Behavioral Logs seed
    _behaviorReports = [
      BehaviorAuditReport(
        recordId: 'audit_b_01',
        actorRole: 'SystemRootAdmin',
        operationTypeEn: 'Dynamic key entropy refreshment sequence executed',
        operationTypeAr: 'تنفيذ سلسلة تنشيط العشوائية (Entropy) للمفاتيح',
        anomalyConfidence: 0.05,
        isSuspectedAtypical: false,
        eventTime: now.subtract(const Duration(hours: 4)),
      ),
      BehaviorAuditReport(
        recordId: 'audit_b_02',
        actorRole: 'SecOpsOperator',
        operationTypeEn: 'Bulk Vault asset classification modifications queried',
        operationTypeAr: 'الاستعلام عن تعديلات تصنيف الأصول في الخزائن المجمعة',
        anomalyConfidence: 0.68,
        isSuspectedAtypical: false,
        eventTime: now.subtract(const Duration(hours: 2)),
      ),
      BehaviorAuditReport(
        recordId: 'audit_b_03',
        actorRole: 'UnknownOperatorNode',
        operationTypeEn: 'Consecutive decryption failures on capsule container "cap_9"',
        operationTypeAr: 'فشل تكرار فك تشفير محتوى الكبسولة الزمنية "cap_9"',
        anomalyConfidence: 0.92,
        isSuspectedAtypical: true,
        eventTime: now.subtract(const Duration(minutes: 15)),
      ),
    ];

    // 3. Default optimization, security, and storage insights
    _insights = [
      IntelligenceInsight(
        insightId: 'opt_ins_01',
        category: InsightCategory.storage,
        titleEn: 'Orphaned Plaintext Remnant Caches',
        titleAr: 'عناصر كاش غير مترابطة وخالية من المفاتيح التناظرية',
        descriptionEn: 'The Analyzer detected 2 unassociated raw storage blocks in Vault 4. These parts lack active key metadata mapping.',
        descriptionAr: 'كشف محلل الأصول عن وجود قطاعين من البيانات غير النشطة في الخزنة رقم 4 بدون خريطة تشفير معرفة.',
        severity: InsightSeverity.high,
        recommendationEn: 'Authorize automated garbage collector to scrub the orphan vault space immediately.',
        recommendationAr: 'تخويل منسق البيانات لتطهير قطاع الخزن المفقود في السجلات نهائياً لحماية الأداء.',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      IntelligenceInsight(
        insightId: 'opt_ins_02',
        category: InsightCategory.security,
        titleEn: 'Suboptimal Key Rotation Frequency',
        titleAr: 'تجاوز توقيت التحديث الإجباري للمفاتيح التناظرية',
        descriptionEn: 'The rotation schedule for AES keys in the Smart Vault layer has exceeded the 48-hour mandatory interval.',
        descriptionAr: 'تجاوزت فترة صلاحية دوران المفاتيح الأساسية الخاصة بخزائن الملفات الرقمية الفاصل الزمني البالغ 48 ساعة.',
        severity: InsightSeverity.medium,
        recommendationEn: 'Trigger central key ring rotation cycle to issue replacement vector structures.',
        recommendationAr: 'تفعيل دورة دوران حلقة المفاتيح لإعادة ترشيح الموترات والبدلات التشفيرية.',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      IntelligenceInsight(
        insightId: 'opt_ins_03',
        category: InsightCategory.behavior,
        titleEn: 'Atypical Out-of-hours Capsule Access Profile',
        titleAr: 'نمط وصول غير اعتيادي خارج أوقات العمل للكبسولات الكبرى',
        descriptionEn: 'Operator profile made redundant read attempts on locked time capsule archives between 02:00 and 04:00.',
        descriptionAr: 'رصد المتتبع محاولات قراءة متكررة للكبسولات المقفلة زمنياً بواسطة حساب تشغيل خارج الساعات النظامية.',
        severity: InsightSeverity.critical,
        recommendationEn: 'Temporarily lock active session token leases and demand secondary hardware verification.',
        recommendationAr: 'تعليق نشاط مؤشرات التحقق وتفعيل مصادقة الأمن المزدوجة المتداخلة.',
        timestamp: now.subtract(const Duration(hours: 10)),
      ),
    ];

    // 4. Default risk metric nodes
    _riskMetrics = [
      RiskMetricNode(
        metricId: 'risk_key_strength',
        nameEn: 'Entropy Degradation Drift',
        nameAr: 'مؤشر انحلال قوة العشوائية للمفاتيح',
        currentScore: 12.5,
        statusLabelEn: 'Fully Secure (99.9% Entropy)',
        statusLabelAr: 'قوة قصوى مشبعة (99.9% عشوائية)',
      ),
      RiskMetricNode(
        metricId: 'risk_data_leakage',
        nameEn: 'Cross-Tenant Port Vulnerability',
        nameAr: 'احتمالية تسريب البيانات بين قنوات الاتصال',
        currentScore: 35.0,
        statusLabelEn: 'Safe Partition Bounds Enforced',
        statusLabelAr: 'آمن، تم فرض عزل حدود مساحات الذاكرة يدوياً',
      ),
      RiskMetricNode(
        metricId: 'risk_access_anomaly',
        nameEn: 'Dynamic User Behavior Deviation Rate',
        nameAr: 'معدل انحراف سلوكيات المستخدمين عن الوضع النمطي',
        currentScore: 58.2,
        statusLabelEn: 'Atypical Burst Detected',
        statusLabelAr: 'ارتفاع متوسط في محاولات الوصول الفاشلة للرموز الخشنة',
      ),
    ];

    _recalculateScores();
    saveState();
  }
}
