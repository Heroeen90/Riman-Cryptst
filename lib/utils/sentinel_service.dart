import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/sentinel.dart';
import 'vault_service.dart';
import 'forensics_service.dart';

class SentinelService extends ChangeNotifier {
  static final SentinelService _instance = SentinelService._internal();
  factory SentinelService() => _instance;

  SentinelService._internal() {
    loadState();
  }

  List<SentinelAnomaly> _anomalies = [];
  List<SentinelAnomaly> get anomalies => _anomalies;

  List<SentinelRecommendation> _recommendations = [];
  List<SentinelRecommendation> get recommendations => _recommendations;

  List<SentinelMission> _missions = [];
  List<SentinelMission> get missions => _missions;

  List<SentinelScoreHistory> _scoreHistory = [];
  List<SentinelScoreHistory> get scoreHistory => _scoreHistory;

  bool _isWatchdogEngaged = true;
  bool get isWatchdogEngaged => _isWatchdogEngaged;

  int _failedAccessAttempts = 0;
  DateTime? _lastFailureTime;

  double _currentSecurityScore = 92.0;
  double get currentSecurityScore => _currentSecurityScore;

  // Compute coverage percentages of different modules
  Map<String, double> get protectionCoverage {
    final vaults = VaultService().vaults;
    final totalFiles = vaults.fold(0, (sum, v) => sum + v.files.length);
    
    double vaultCoverage = vaults.isNotEmpty ? 100.0 : 40.0;
    double fileCoverage = totalFiles > 0 ? 95.0 : 50.0;
    double forensicCoverage = ForensicsService().isAutoWatchdogActive ? 100.0 : 60.0;
    double watchdogCoverage = _isWatchdogEngaged ? 100.0 : 45.0;

    return {
      'Vault Shield': vaultCoverage,
      'Crypt Vectors': fileCoverage,
      'Forensics Ledger': forensicCoverage,
      'Watchdog Sentinel': watchdogCoverage,
    };
  }

  void toggleWatchdog(bool val) {
    _isWatchdogEngaged = val;
    saveState();
    notifyListeners();
  }

  void logAccessAttempt(bool isSuccess, {String? details, String? resourceId}) {
    if (!isSuccess) {
      _failedAccessAttempts++;
      final now = DateTime.now();
      _lastFailureTime = now;

      if (_failedAccessAttempts >= 3 && _isWatchdogEngaged) {
        // Trigger high priority anomaly!
        final id = 'anom_${now.millisecondsSinceEpoch}';
        final newAnomaly = SentinelAnomaly(
          id: id,
          type: 'brute_force',
          severity: 'High',
          descriptionEn: 'Repeated failing access attempts recorded on crypto nodes within a brief period.',
          descriptionAr: 'تم تسجيل محاولات وصول فاشلة متكررة إلى كتل التشفير في فترة وجيزة.',
          detectedAt: now,
          isResolved: false,
          resourceId: resourceId,
        );
        _anomalies.insert(0, newAnomaly);
        _failedAccessAttempts = 0; // Reset counter for rate-limit
        
        // Push notification or trigger score rebuild
        recalculateAndArchiveScore();
      }
    } else {
      _failedAccessAttempts = 0;
    }
    saveState();
  }

  void injectEntropyAnomaly() {
    final now = DateTime.now();
    final id = 'anom_ent_${now.millisecondsSinceEpoch}';
    final newAnomaly = SentinelAnomaly(
      id: id,
      type: 'entropy_drop',
      severity: 'Medium',
      descriptionEn: 'Zero-matrix entropy levels dipped below 3.5 bits/symbol due to quiet storage cycles.',
      descriptionAr: 'انخفض مستوى عشوائية مصفوفة الصفر ريمان إلى أقل من 3.5 بت/رمز بسبب هدوء عمليات التخزين.',
      detectedAt: now,
      isResolved: false,
    );
    _anomalies.insert(0, newAnomaly);
    recalculateAndArchiveScore();
  }

  void resolveAnomaly(String id) {
    final idx = _anomalies.indexWhere((any) => any.id == id);
    if (idx != -1) {
      final old = _anomalies[idx];
      _anomalies[idx] = SentinelAnomaly(
        id: old.id,
        type: old.type,
        severity: old.severity,
        descriptionEn: old.descriptionEn,
        descriptionAr: old.descriptionAr,
        detectedAt: old.detectedAt,
        isResolved: true,
        resourceId: old.resourceId,
      );
      
      // Update missions / score if relevant
      _advanceMissionProgress('resolve_anomalies', 0.5);

      recalculateAndArchiveScore();
    }
  }

  void applyRecommendation(String id) {
    final idx = _recommendations.indexWhere((rec) => rec.id == id);
    if (idx != -1) {
      final old = _recommendations[idx];
      if (!old.isApplied) {
        _recommendations[idx] = SentinelRecommendation(
          id: old.id,
          titleEn: old.titleEn,
          titleAr: old.titleAr,
          descriptionEn: old.descriptionEn,
          descriptionAr: old.descriptionAr,
          metricImpact: old.metricImpact,
          category: old.category,
          isApplied: true,
        );

        // Advance specific protection mission
        if (old.category == 'watchdog') {
          _advanceMissionProgress('engage_watchdog', 1.0);
        } else if (old.category == 'vault') {
          _advanceMissionProgress('harden_vaults', 0.5);
        }

        recalculateAndArchiveScore();
      }
    }
  }

  void triggerSystemSelfExamine() {
    // Regenerate recommendations and sync score safely
    _populateDynamicRecommendations();
    recalculateAndArchiveScore();
  }

  void _advanceMissionProgress(String actionType, double amount) {
    for (int i = 0; i < _missions.length; i++) {
      final m = _missions[i];
      if (m.id == actionType && !m.isCompleted) {
        double newProg = (m.progress + amount).clamp(0.0, 1.0);
        bool completed = newProg >= 1.0;
        _missions[i] = SentinelMission(
          id: m.id,
          titleEn: m.titleEn,
          titleAr: m.titleAr,
          descriptionEn: m.descriptionEn,
          descriptionAr: m.descriptionAr,
          progress: newProg,
          isCompleted: completed,
          rewardScore: m.rewardScore,
        );
      }
    }
    saveState();
  }

  void recalculateAndArchiveScore() {
    double baseScore = 95.0;

    // Reductions for open anomalies
    for (var anomaly in _anomalies) {
      if (!anomaly.isResolved) {
        if (anomaly.severity == 'Critical') {
          baseScore -= 15.0;
        } else if (anomaly.severity == 'High') {
          baseScore -= 10.0;
        } else if (anomaly.severity == 'Medium') {
          baseScore -= 4.0;
        } else {
          baseScore -= 1.5;
        }
      }
    }

    // Bonuses for completed missions
    for (var m in _missions) {
      if (m.isCompleted) {
        baseScore += (m.rewardScore / 2.0); // Limit influence
      }
    }

    // Bonuses for applied recommendations
    for (var r in _recommendations) {
      if (r.isApplied) {
        baseScore += 3.0;
      }
    }

    // Verify watchdog is alive status
    if (!_isWatchdogEngaged) {
      baseScore -= 8.0;
    }

    _currentSecurityScore = baseScore.clamp(5.0, 100.0);

    // Keep history clean and trim to last 15 ticks
    final entry = SentinelScoreHistory(
      timestamp: DateTime.now(),
      score: _currentSecurityScore,
    );
    _scoreHistory.add(entry);
    if (_scoreHistory.length > 25) {
      _scoreHistory.removeAt(0);
    }

    saveState();
    notifyListeners();
  }

  void clearSentinelDatabase() {
    _anomalies.clear();
    _scoreHistory.clear();
    _seedDefaultSentinel();
    notifyListeners();
  }

  void _populateDynamicRecommendations() {
    final vaults = VaultService().vaults;
    final List<SentinelRecommendation> list = [];

    // Recommendation 1: Always add if not applied
    list.add(SentinelRecommendation(
      id: 'rec_watchdog',
      titleEn: 'Equip Real-Time Sentinel Gatekeeper',
      titleAr: 'تفعيل حارس البوابة الفوري المتقدم',
      descriptionEn: 'Ensure the automatic watchdog daemon is active to identify decryption brute forces.',
      descriptionAr: 'ضمان تنشيط نظام المراقبة التلقائي للتحذير من محاولات التخمين وفك التشفير المتكررة.',
      metricImpact: '+8% Score',
      category: 'watchdog',
      isApplied: _isWatchdogEngaged,
    ));

    // Recommendation 2: Vault coverage
    bool lowVaultCount = vaults.length < 2;
    list.add(SentinelRecommendation(
      id: 'rec_decoy',
      titleEn: 'Construct Multi-Tier Decoy Vaults',
      titleAr: 'إنشاء خزائن تمويه متعددة المستويات',
      descriptionEn: 'Create secondary decoy matrix spaces to isolate real mathematical keys.',
      descriptionAr: 'تكوين مساحات تخزين مرسلة مموهة لعزل تواقيع ومفاتيح التشييد الحقيقية.',
      metricImpact: '+12% Score',
      category: 'vault',
      isApplied: !lowVaultCount,
    ));

    // Recommendation 3: Backup schedule check
    list.add(SentinelRecommendation(
      id: 'rec_quantum_backups',
      titleEn: 'Seal Master Keys in Quantum Archive',
      titleAr: 'ختم المفاتيح المرجعية بمستودع الأرشيف الكمي',
      descriptionEn: 'Preserve zero-index byte alignments from master cryptographic tables.',
      descriptionAr: 'حفظ بصمات ترابط الكتل المشفرة وتصدير ملفاتها إلى خيمة الأرشيف الحصين.',
      metricImpact: '+10% Score',
      category: 'backups',
      isApplied: false,
    ));

    _recommendations = list;
  }

  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'anomalies': _anomalies.map((a) => a.toJson()).toList(),
        'recommendations': _recommendations.map((r) => r.toJson()).toList(),
        'missions': _missions.map((m) => m.toJson()).toList(),
        'scoreHistory': _scoreHistory.map((h) => h.toJson()).toList(),
        'isWatchdogEngaged': _isWatchdogEngaged,
        'currentSecurityScore': _currentSecurityScore,
      };
      final file = File('sentinel_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Sentinel DB write error (handled / simulated): $e');
    }
  }

  void loadState() {
    try {
      final file = File('sentinel_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['anomalies'] != null) {
          final listAnom = map['anomalies'] as List;
          _anomalies = listAnom.map((a) => SentinelAnomaly.fromJson(a as Map<String, dynamic>)).toList();
        }
        if (map['recommendations'] != null) {
          final listRec = map['recommendations'] as List;
          _recommendations = listRec.map((r) => SentinelRecommendation.fromJson(r as Map<String, dynamic>)).toList();
        }
        if (map['missions'] != null) {
          final listMiss = map['missions'] as List;
          _missions = listMiss.map((m) => SentinelMission.fromJson(m as Map<String, dynamic>)).toList();
        }
        if (map['scoreHistory'] != null) {
          final listHist = map['scoreHistory'] as List;
          _scoreHistory = listHist.map((h) => SentinelScoreHistory.fromJson(h as Map<String, dynamic>)).toList();
        }
        _isWatchdogEngaged = map['isWatchdogEngaged'] as bool? ?? true;
        _currentSecurityScore = (map['currentSecurityScore'] as num? ?? 92.0).toDouble();
      } else {
        _seedDefaultSentinel();
      }
    } catch (e) {
      debugPrint('Sentinel DB read error, seeding defaults: $e');
      _seedDefaultSentinel();
    }
  }

  void _seedDefaultSentinel() {
    _isWatchdogEngaged = true;
    _currentSecurityScore = 94.0;

    // Seed historical score progression
    final timeBase = DateTime.now();
    _scoreHistory = [
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 6)), score: 86.0),
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 5)), score: 88.0),
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 4)), score: 85.0),
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 3)), score: 91.0),
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 2)), score: 91.0),
      SentinelScoreHistory(timestamp: timeBase.subtract(const Duration(days: 1)), score: 94.0),
      SentinelScoreHistory(timestamp: timeBase, score: 94.0),
    ];

    // Seed initial vulnerabilities/anomalies (clean logs by default, 1 solved, 1 unsolved)
    _anomalies = [
      SentinelAnomaly(
        id: 'anom_seed_1',
        type: 'decryption_failure',
        severity: 'Low',
        descriptionEn: 'Mild parity mismatch during external cipher decryption tests.',
        descriptionAr: 'مسح آمن: عدم تطابق هامشي طفيف في الفحص الدوري لمعاملات التماثل بمفاتيح ريمان.',
        detectedAt: DateTime.now().subtract(const Duration(hours: 18)),
        isResolved: true,
      ),
      SentinelAnomaly(
        id: 'anom_seed_2',
        type: 'access_pattern',
        severity: 'Medium',
        descriptionEn: 'Unexpected metadata sweep patterns observed over virtual note layers.',
        descriptionAr: 'أنماط تبدير عشوائية تم رصدها على كتل ترشيح الملاحظات المؤمنة.',
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isResolved: false,
      ),
    ];

    // Seed dynamic missions to complete
    _missions = [
      SentinelMission(
        id: 'resolve_anomalies',
        titleEn: 'Neutralize Algorithmic Anomaly Flags',
        titleAr: 'تطهير انحرافات الأنظمة والكتل المنبهة',
        descriptionEn: 'Locate and resolve active security warnings in any database module or key system.',
        descriptionAr: 'البحث عن وتأمين مسارات التنبيه الأمنية وحصاد شهادات الاستعادة.',
        progress: 0.5,
        isCompleted: false,
        rewardScore: 12,
      ),
      SentinelMission(
        id: 'engage_watchdog',
        titleEn: 'Engage Watchdog Sentinel Daemon',
        titleAr: 'تثبيت حوكمة كلب الحراسة التلقائي',
        descriptionEn: 'Keep the real-time sentinel gatekeeper on high sensitivity to shield brute attempts.',
        descriptionAr: 'تشغيل الحارس الفوري لحماية الترابطات ومصائد السجلات البسيطة.',
        progress: 1.0,
        isCompleted: true,
        rewardScore: 10,
      ),
      SentinelMission(
        id: 'harden_vaults',
        titleEn: 'Construct Multi-Space Sovereignty',
        titleAr: 'توطين البنية التحتية للخزائن المتعددة',
        descriptionEn: 'Harden system storage profile coverage through nested folders and quantum blocks.',
        descriptionAr: 'تعزيز مستويات التخطيط الأمني وتوسيع الخزائن المتكاملة في النظام.',
        progress: 0.0,
        isCompleted: false,
        rewardScore: 15,
      ),
    ];

    _populateDynamicRecommendations();
    saveState();
  }
}
