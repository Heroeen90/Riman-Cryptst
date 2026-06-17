import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/security_kernel.dart';

class KernelService extends ChangeNotifier {
  static final KernelService _instance = KernelService._internal();
  factory KernelService() => _instance;

  KernelService._internal() {
    loadState();
  }

  // Unified Key Manager data
  List<CryptographicKeyMeta> _keys = [];
  List<CryptographicKeyMeta> get keys => _keys;

  // Secure Memory Manager data
  List<MemoryPagePartition> _memoryPages = [];
  List<MemoryPagePartition> get memoryPages => _memoryPages;

  // Session Guardian data
  List<GuardianSession> _sessions = [];
  List<GuardianSession> get sessions => _sessions;

  // Access Policy Engine policies
  List<EnforcementPolicy> _policies = [];
  List<EnforcementPolicy> get policies => _policies;

  // Event Bus history
  List<KernelSecurityEvent> _events = [];
  List<KernelSecurityEvent> get events => _events;

  // Core system metrics configuration & telemetry fields
  double _entropyLevel = 0.9994;
  double get entropyLevel => _entropyLevel;

  void reloadEntropy() {
    final rand = math.Random();
    _entropyLevel = 0.995 + (rand.nextDouble() * 0.0049);
    notifyListeners();
  }

  // Execute manual security key generation
  void generateKey({
    required String algorithm,
    required int bitStrength,
    required String owner,
  }) {
    final now = DateTime.now();
    final newId = 'key_${now.millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
    final keyMeta = CryptographicKeyMeta(
      keyId: newId,
      algorithm: algorithm,
      status: KeyStatus.active,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 90)),
      bitStrength: bitStrength,
      contextOwner: owner,
    );

    _keys.add(keyMeta);
    broadcastEvent(
      category: 'KEY_OP',
      en: 'Central Key Ring issued new dynamic metadata entry: $newId',
      ar: 'أصدر حلقة المفاتيح المركزية مؤشراً تشفيرياً جديداً: $newId',
      level: 'low',
    );

    saveState();
    notifyListeners();
  }

  // Rotate key (suspend old, create new)
  void rotateKey(String oldKeyId) {
    final idx = _keys.indexWhere((k) => k.keyId == oldKeyId);
    if (idx != -1) {
      final old = _keys[idx];
      _keys[idx] = CryptographicKeyMeta(
        keyId: old.keyId,
        algorithm: old.algorithm,
        status: KeyStatus.suspended,
        createdAt: old.createdAt,
        expiresAt: old.expiresAt,
        bitStrength: old.bitStrength,
        contextOwner: old.contextOwner,
      );

      // Generate replacement
      generateKey(
        algorithm: old.algorithm,
        bitStrength: old.bitStrength,
        owner: old.contextOwner + ' (Rotated)',
      );

      broadcastEvent(
        category: 'KEY_OP',
        en: 'Suspanded old key $oldKeyId, trigger auto rotation pipeline with full entropy cycle.',
        ar: 'تم تعليق المفتاح القديم $oldKeyId، وتفعيل خط تدفق الاستبدال التلقائي بدورة كاملة.',
        level: 'medium',
      );
    }
  }

  // Set key status to destroyed (Zeroize)
  void destroyKey(String keyId) {
    final idx = _keys.indexWhere((k) => k.keyId == keyId);
    if (idx != -1) {
      final old = _keys[idx];
      _keys[idx] = CryptographicKeyMeta(
        keyId: old.keyId,
        algorithm: old.algorithm,
        status: KeyStatus.destroyed,
        createdAt: old.createdAt,
        expiresAt: old.expiresAt,
        bitStrength: old.bitStrength,
        contextOwner: old.contextOwner,
      );

      broadcastEvent(
        category: 'KEY_OP',
        en: 'Destroyed and zeroized keyspace allocation for token: $keyId',
        ar: 'تم تصفير وإتلاف خلية الذاكرة للمعرف الحصين: $keyId',
        level: 'high',
      );

      saveState();
      notifyListeners();
    }
  }

  // Secure Memory Scrub execution (Memory Sanitizer)
  void scrubMemory() {
    final now = DateTime.now();
    for (int i = 0; i < _memoryPages.length; i++) {
      final page = _memoryPages[i];
      _memoryPages[i] = MemoryPagePartition(
        pageIndex: page.pageIndex,
        allocatedBytes: page.allocatedBytes,
        dataClassification: page.dataClassification,
        lastAccessTime: now,
        isScrubbed: true,
      );
    }

    // Trigger full garbage collection emulation signal
    broadcastEvent(
      category: 'MEMORY_OP',
      en: 'Executed zero-fill memory scrub. Purged temporary decrypted caches from registers completely.',
      ar: 'تم تنفيذ تنظيف الذاكرة وتصفير المدخلات. تم غمر خلايا الكاش المشفرة غير الثابتة بالكامل.',
      level: 'medium',
    );

    saveState();
    notifyListeners();
  }

  // Simulate allocate memory page
  void allocateMemoryPage(String category, int bytes) {
    final now = DateTime.now();
    final newIdx = '0x${(now.millisecondsSinceEpoch & 0xFFFFFFFF).toRadixString(16).toUpperCase()}';
    _memoryPages.add(MemoryPagePartition(
      pageIndex: newIdx,
      allocatedBytes: bytes,
      dataClassification: category,
      lastAccessTime: now,
      isScrubbed: false,
    ));

    broadcastEvent(
      category: 'MEMORY_OP',
      en: 'Allocated dynamic secure partition segment $newIdx ($bytes bytes) for classification: $category',
      ar: 'تم تخصيص قطاع للذاكرة المعزولة $newIdx ($bytes بايت) بنوع تصنيف: $category',
      level: 'low',
    );

    saveState();
    notifyListeners();
  }

  // Session Guardian routines
  void createGuardianSession(String profileId, int ttlSeconds) {
    final now = DateTime.now();
    final rand = math.Random();
    final newSessionId = 'sess_${now.millisecondsSinceEpoch}_${rand.nextInt(1000)}';
    
    // Generate simulated token checksum hash
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final tokenBuf = StringBuffer();
    for (int i = 0; i < 24; i++) {
      tokenBuf.write(chars[rand.nextInt(chars.length)]);
    }

    final sess = GuardianSession(
      sessionId: newSessionId,
      tokenHash: 'SHA-256|' + tokenBuf.toString(),
      associatedProfileId: profileId,
      createdAt: now,
      expiresAt: now.add(Duration(seconds: ttlSeconds)),
      timeToLiveSeconds: ttlSeconds,
      isActive: true,
    );

    _sessions.insert(0, sess);
    if (_sessions.length > 20) {
      _sessions.removeLast();
    }

    broadcastEvent(
      category: 'SESSION_OP',
      en: 'Guardian Session registered. Secure Lease granted for client token hash context ($newSessionId).',
      ar: 'تم تسجيل جلسة الحراسة الآمنة. منح الترخيص الآمن لمؤشر التحقق للعميل ($newSessionId).',
      level: 'medium',
    );

    saveState();
    notifyListeners();
  }

  void terminateSession(String sessId) {
    final idx = _sessions.indexWhere((s) => s.sessionId == sessId);
    if (idx != -1) {
      final old = _sessions[idx];
      _sessions[idx] = GuardianSession(
        sessionId: old.sessionId,
        tokenHash: old.tokenHash,
        associatedProfileId: old.associatedProfileId,
        createdAt: old.createdAt,
        expiresAt: DateTime.now(),
        timeToLiveSeconds: old.timeToLiveSeconds,
        isActive: false,
      );

      broadcastEvent(
        category: 'SESSION_OP',
        en: 'Session $sessId revorked and pruned from current secure active table.',
        ar: 'تم إبطال وإلغاء الجلسة $sessId من جدول الجلسات النشطة الحالية.',
        level: 'high',
      );

      saveState();
      notifyListeners();
    }
  }

  // Toggling specific security access policy rule
  void togglePolicy(String policyId) {
    final idx = _policies.indexWhere((p) => p.policyId == policyId);
    if (idx != -1) {
      final old = _policies[idx];
      final targetState = !old.isEnforced;
      _policies[idx] = EnforcementPolicy(
        policyId: old.policyId,
        labelEn: old.labelEn,
        labelAr: old.labelAr,
        scope: old.scope,
        isEnforced: targetState,
        severityMultiplier: old.severityMultiplier,
      );

      broadcastEvent(
        category: 'POLICY_BREACH',
        en: 'Access Policy Engine altered: rule "${old.policyId}" forced to status: ${targetState ? "ENFORCED" : "BYPASSED"}',
        ar: 'تم تعديل محرك السياسات: تم إجبار القاعدة "${old.policyId}" للحالة: ${targetState ? "مطبقة" : "متجاوزة"}',
        level: targetState ? 'medium' : 'high',
      );

      saveState();
      notifyListeners();
    }
  }

  // Simulate policy evaluation breaches/tests
  void runPolicyVerificationScan() {
    int totalBreachesDetected = 0;
    
    // Check if critical policies are disabled -> triggers events
    for (var policy in _policies) {
      if (!policy.isEnforced && policy.severityMultiplier >= 2) {
        totalBreachesDetected++;
        broadcastEvent(
          category: 'POLICY_BREACH',
          en: 'Verification Warning: High-tier Policy compliance rule "${policy.policyId}" has been set to bypass!',
          ar: 'تحذير تحقق: تم اكتشاف تجاوز قاعدة كبرى للسياسة المعتمدة "${policy.policyId}"!',
          level: 'high',
        );
      }
    }

    if (totalBreachesDetected == 0) {
      broadcastEvent(
        category: 'POLICY_BREACH',
        en: 'Full compliance scan accomplished. All evaluated nodes respond green with zero violations.',
        ar: 'اكتمل فحص مطابقة قواعد الأمان الموحدة. كافة النوى المقيّمة تظهر باللون الأخضر وخالية من التجاوزات.',
        level: 'low',
      );
    }

    notifyListeners();
  }

  // Broadcasting event in localized channels
  void broadcastEvent({
    required String category,
    required String en,
    required String ar,
    required String level,
  }) {
    final now = DateTime.now();
    final ev = KernelSecurityEvent(
      eventId: 'evt_${now.millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      eventCategory: category,
      detailsEn: en,
      detailsAr: ar,
      threatLevel: level,
      timestamp: now,
    );

    _events.insert(0, ev);
    if (_events.length > 50) {
      _events.removeLast();
    }
    notifyListeners();
  }

  // Calculate high performance core security score
  Map<String, dynamic> calculateKernelHealth() {
    double baseHealth = 100.0;
    
    // Deduct physical points if crucial policies are disabled
    int disabledWeight = 0;
    for (var p in _policies) {
      if (!p.isEnforced) {
        disabledWeight += (3 * p.severityMultiplier);
      }
    }
    baseHealth -= disabledWeight;

    // Deduct points for destroyed keys or lack of keys
    int activeKeys = _keys.where((k) => k.status == KeyStatus.active).length;
    if (activeKeys == 0) {
      baseHealth -= 15.0;
    }

    // Deduct points if memory manager holds unscrubbed dynamic components
    int unscrubbedPages = _memoryPages.where((p) => !p.isScrubbed).length;
    baseHealth -= (unscrubbedPages * 1.5);

    double finalHealth = baseHealth.clamp(5.0, 100.0);

    // Compute live telemetry variables
    int totalBytesAllocated = _memoryPages.fold<int>(0, (sum, page) => sum + page.allocatedBytes);
    int activeSessions = _sessions.where((s) => s.isActive && s.expiresAt.isAfter(DateTime.now())).length;

    return {
      'score': finalHealth,
      'gradeEn': finalHealth >= 90.0
          ? 'KERNEL UNBROKEN'
          : finalHealth >= 75.0
              ? 'KERNEL STABLE / DEGRADED CORES'
              : 'CRITICAL SHIELD BREACHED',
      'gradeAr': finalHealth >= 90.0
          ? 'نواة أمن سليمة ومحصنة بالكامل'
          : finalHealth >= 75.0
              ? 'نواة مستقرة / قنوات ترشيح معطلة جزئياً'
              : 'خطر فوري / جدار الحماية متصدع',
      'allocatedMemory': totalBytesAllocated,
      'unscrubbedCount': unscrubbedPages,
      'activeSessions': activeSessions,
      'activeKeys': activeKeys,
      'totalKeys': _keys.length,
    };
  }

  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'keys': _keys.map((k) => k.toJson()).toList(),
        'memoryPages': _memoryPages.map((m) => m.toJson()).toList(),
        'sessions': _sessions.map((s) => s.toJson()).toList(),
        'policies': _policies.map((p) => p.toJson()).toList(),
        'events': _events.map((e) => e.toJson()).toList(),
      };
      
      final file = File('security_kernel_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Kernel DB save error (simulated/handled directory): $e');
    }
  }

  void loadState() {
    try {
      final file = File('security_kernel_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['keys'] != null) {
          final lk = map['keys'] as List;
          _keys = lk.map((k) => CryptographicKeyMeta.fromJson(k as Map<String, dynamic>)).toList();
        }
        if (map['memoryPages'] != null) {
          final lm = map['memoryPages'] as List;
          _memoryPages = lm.map((m) => MemoryPagePartition.fromJson(m as Map<String, dynamic>)).toList();
        }
        if (map['sessions'] != null) {
          final ls = map['sessions'] as List;
          _sessions = ls.map((s) => GuardianSession.fromJson(s as Map<String, dynamic>)).toList();
        }
        if (map['policies'] != null) {
          final lp = map['policies'] as List;
          _policies = lp.map((p) => EnforcementPolicy.fromJson(p as Map<String, dynamic>)).toList();
        }
        if (map['events'] != null) {
          final le = map['events'] as List;
          _events = le.map((e) => KernelSecurityEvent.fromJson(e as Map<String, dynamic>)).toList();
        }
      } else {
        _seedDefaultSecurityKernel();
      }
    } catch (e) {
      debugPrint('Kernel DB reading issue, fallback seeding: $e');
      _seedDefaultSecurityKernel();
    }
  }

  void resetKernelDataset() {
    _keys.clear();
    _memoryPages.clear();
    _sessions.clear();
    _policies.clear();
    _events.clear();
    _seedDefaultSecurityKernel();
    notifyListeners();
  }

  void _seedDefaultSecurityKernel() {
    // 1. Initial Keys setup
    final now = DateTime.now();
    _keys = [
      CryptographicKeyMeta(
        keyId: 'kern_root_symmetric_01',
        algorithm: 'AES-256-GCM',
        status: KeyStatus.active,
        createdAt: now.subtract(const Duration(days: 10)),
        expiresAt: now.add(const Duration(days: 80)),
        bitStrength: 256,
        contextOwner: 'KernelRoot',
      ),
      CryptographicKeyMeta(
        keyId: 'quantum_hybrid_kyber_a9',
        algorithm: 'Quantum-Kyber',
        status: KeyStatus.active,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 89)),
        bitStrength: 1024,
        contextOwner: 'SpectrumSync',
      ),
      CryptographicKeyMeta(
        keyId: 'temporary_deprec_chacha',
        algorithm: 'ChaCha20-Poly1305',
        status: KeyStatus.suspended,
        createdAt: now.subtract(const Duration(days: 30)),
        expiresAt: now.subtract(const Duration(days: 1)),
        bitStrength: 256,
        contextOwner: 'ZeroTrustLegacy',
      ),
    ];

    // 2. Initial Physical memory page reservations
    _memoryPages = [
      MemoryPagePartition(
        pageIndex: '0x00E0F911',
        allocatedBytes: 1048576, // 1MB
        dataClassification: 'Keys',
        lastAccessTime: now,
        isScrubbed: false,
      ),
      MemoryPagePartition(
        pageIndex: '0x00C12AAB',
        allocatedBytes: 4194304, // 4MB
        dataClassification: 'DecryptedCache',
        lastAccessTime: now.subtract(const Duration(minutes: 15)),
        isScrubbed: true,
      ),
      MemoryPagePartition(
        pageIndex: '0x05BC8870',
        allocatedBytes: 256128, // 250KB
        dataClassification: 'IdentityTokens',
        lastAccessTime: now,
        isScrubbed: false,
      ),
    ];

    // 3. Setup core Sessions table
    _sessions = [
      GuardianSession(
        sessionId: 'sess_g_10294_992',
        tokenHash: 'SHA-256|f39b1a5cf87e10c0aa29ffbeccdb39',
        associatedProfileId: 'prof_personal',
        createdAt: now.subtract(const Duration(minutes: 12)),
        expiresAt: now.add(const Duration(minutes: 18)),
        timeToLiveSeconds: 1800,
        isActive: true,
      ),
    ];

    // 4. Default Enforcement Policies
    _policies = [
      EnforcementPolicy(
        policyId: 'policy_mfa_mandatory',
        labelEn: 'Mandatory Overlapping MFA Authentication',
        labelAr: 'فرض لزوم المصادقة الثنائية المتداخلة لكامل الصلاحيات',
        scope: 'MFA',
        isEnforced: true,
        severityMultiplier: 3,
      ),
      EnforcementPolicy(
        policyId: 'policy_zero_sharing',
        labelEn: 'Anti-Cross-Tenant Leaks Protection',
        labelAr: 'منع تسريب وتبادل البيانات المشتركة بين البيئات',
        scope: 'RESOURCE_ISOLATION',
        isEnforced: true,
        severityMultiplier: 2,
      ),
      EnforcementPolicy(
        policyId: 'policy_block_export',
        labelEn: 'Forbid Plaintext Decrypted Export Paths',
        labelAr: 'حظر تصدير وتدفق البيانات غير المشفرة خارج الحيازة',
        scope: 'MEDIA_EXPORT',
        isEnforced: false,
        severityMultiplier: 1, // Optional lower severity default
      ),
      EnforcementPolicy(
        policyId: 'policy_rotate_frequ',
        labelEn: 'High Fidelity 48-Hour Key Rotation Intervals',
        labelAr: 'دوران استبدال المفاتيح الإجباري كل 48 ساعة لمنع الفك',
        scope: 'KEY_ROTATION',
        isEnforced: true,
        severityMultiplier: 2,
      ),
    ];

    // 5. Initial events log preseed
    _events = [
      KernelSecurityEvent(
        eventId: 'evt_seed_90',
        eventCategory: 'SESSION_OP',
        detailsEn: 'Kernel Kernel Engine booted successfully on Device Memory.',
        detailsAr: 'نواة تشغيل ومراقبة أمن ريمان (Kernel) اشتغلت في الذاكرة بنجاح.',
        threatLevel: 'low',
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
      KernelSecurityEvent(
        eventId: 'evt_seed_91',
        eventCategory: 'KEY_OP',
        detailsEn: 'Preloaded Kyber secure certificate chain credentials into root.',
        detailsAr: 'تحميل مصفوفة تحقق الشهادات وحراسة الكيز (Kyber) المشفرة بالكامل.',
        threatLevel: 'low',
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
    ];

    saveState();
  }
}
