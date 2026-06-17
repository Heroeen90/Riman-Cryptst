import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cloud_bridge.dart';
import 'archive_service.dart';

class CloudService extends ChangeNotifier {
  static final CloudService _instance = CloudService._internal();
  factory CloudService() => _instance;

  CloudService._internal() {
    loadState();
  }

  List<CloudProfile> _profiles = [];
  List<CloudProfile> get profiles => _profiles;

  List<SecureBackupPackage> _packages = [];
  List<SecureBackupPackage> get packages => _packages;

  List<SyncConflict> _conflicts = [];
  List<SyncConflict> get conflicts => _conflicts;

  CloudSyncMetrics? _metrics;
  CloudSyncMetrics get metrics => _metrics ?? CloudSyncMetrics(
        syncReadinessScore: 92.5,
        backupIntegrityScore: 100.0,
        syncSecurityScore: 98.0,
        lastCheckTime: DateTime.now(),
      );

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  double _syncProgress = 0.0;
  double get syncProgress => _syncProgress;

  String? _syncMessageEn;
  String? get syncMessageEn => _syncMessageEn;

  String? _syncMessageAr;
  String? get syncMessageAr => _syncMessageAr;

  // Toggle zero-knowledge mode safely
  void toggleZeroKnowledge(String profileId, bool enabled) {
    final idx = _profiles.indexWhere((p) => p.profileId == profileId);
    if (idx != -1) {
      final p = _profiles[idx];
      _profiles[idx] = CloudProfile(
        profileId: p.profileId,
        provider: p.provider,
        accountEmail: p.accountEmail,
        isConnected: p.isConnected,
        isolatedMetadataOnly: enabled,
        lastSyncTime: p.lastSyncTime,
      );
      _recalculateScores();
      saveState();
      notifyListeners();
    }
  }

  // Connect secondary providers safely
  void connectProvider(CloudProviderType provider, String email) {
    final newId = 'prof_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = CloudProfile(
      profileId: newId,
      provider: provider,
      accountEmail: email,
      isConnected: true,
      isolatedMetadataOnly: true,
      lastSyncTime: null,
    );

    _profiles.add(newProfile);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Terminate connection
  void disconnectProvider(String profileId) {
    _profiles.removeWhere((p) => p.profileId == profileId);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Build secure local backups (Bundling list of archive items and encrypting metadata via CryptoCore structure simulation)
  void buildAndRegisterBackupPackage({
    required String nameEn,
    required String nameAr,
    required List<String> archiveItemIds,
    required String activeKeyId,
  }) {
    final now = DateTime.now();
    final pId = 'pkg_${now.millisecondsSinceEpoch}';

    // Calculate total size of chosen archives
    int sizeBytes = 0;
    final allArchives = ArchiveService().archives;
    for (var actId in archiveItemIds) {
      final idx = allArchives.indexWhere((element) => element.id == actId);
      if (idx != -1) {
        sizeBytes += allArchives[idx].sizeInBytes;
      }
    }

    if (sizeBytes == 0) {
      sizeBytes = 250 * 1024; // standard size backup fallback
    }

    // Creating unique local structural isolation hashes (Zero plaintext leaked)
    final mockDigest = 'sha256_${math.Random().nextInt(99999999)}rimancryptstkeyhash';
    final mockFingerprint = 'rimankey_${activeKeyId.hashCode.toRadixString(16)}';

    final package = SecureBackupPackage(
      packageId: pId,
      nameEn: nameEn,
      nameAr: nameAr,
      bundledItemIds: archiveItemIds,
      totalBytes: sizeBytes,
      encryptedDigest: mockDigest,
      localKeyFingerprint: mockFingerprint,
      createdAt: now,
      status: SyncStatus.pending,
    );

    _packages.insert(0, package);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Resolve a synchronization/metadata conflict via custom resolution options
  void resolveConflict(String conflictId, String resolution) {
    final idx = _conflicts.indexWhere((c) => c.conflictId == conflictId);
    if (idx != -1) {
      final c = _conflicts[idx];
      _conflicts[idx] = SyncConflict(
        conflictId: c.conflictId,
        filenameEn: c.filenameEn,
        filenameAr: c.filenameAr,
        itemType: c.itemType,
        localTime: c.localTime,
        cloudTime: c.cloudTime,
        localSizeBytes: c.localSizeBytes,
        cloudSizeBytes: c.cloudSizeBytes,
        isResolved: true,
        chosenResolution: resolution,
      );

      _recalculateScores();
      saveState();
      notifyListeners();
    }
  }

  // Discard resolved conflicts
  void clearResolvedConflicts() {
    _conflicts.removeWhere((c) => c.isResolved);
    _recalculateScores();
    saveState();
    notifyListeners();
  }

  // Multi-step sync pipeline simulation
  void triggerSyncExecution(Function(String, String) onMessage) {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncProgress = 0.0;
    _syncMessageEn = 'Detecting structural isolated parameters...';
    _syncMessageAr = 'كشف معايير العزل الهيكلي للكبسولات...';
    notifyListeners();

    int step = 0;
    final List<String> stepsEn = [
      'Performing local integrity scanning...',
      'Verifying zero-knowledge key hash consistency...',
      'Assembling secure mathematical backup packages...',
      'Encrypting isolated metadata buffers...',
      'Uploading sealed packages to remote cloud bridge...',
      'Synchronization cycle achieved safely.'
    ];

    final List<String> stepsAr = [
      'إجراء فحص السلامة الميداني المحكم...',
      'مراجعة ترابط وعشوائية مفاتيح التشفير المحلية...',
      'تجميع كبسولات الدعم التراكمي في حزم البيانات...',
      'تشفير ترويسات وبيانات التعريف المعزولة بالكامل...',
      'ضخ الحزم المشفرة إلى الجسر السحابي المعزول...',
      'اكتملت دورة المزامنة السحابية بنجاح وبسرية تامة.'
    ];

    // Simple robust linear state update flow
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!_isSyncing) return false;

      step++;
      if (step < stepsEn.length) {
        _syncProgress = step / (stepsEn.length - 1);
        _syncMessageEn = stepsEn[step];
        _syncMessageAr = stepsAr[step];
        notifyListeners();
        return true;
      } else {
        // Successful sync execution updates
        _isSyncing = false;
        
        // Update pending packages to synced status
        _packages = _packages.map((pkg) {
          if (pkg.status == SyncStatus.pending || pkg.status == SyncStatus.syncing) {
            return SecureBackupPackage(
              packageId: pkg.packageId,
              nameEn: pkg.nameEn,
              nameAr: pkg.nameAr,
              bundledItemIds: pkg.bundledItemIds,
              totalBytes: pkg.totalBytes,
              encryptedDigest: pkg.encryptedDigest,
              localKeyFingerprint: pkg.localKeyFingerprint,
              createdAt: pkg.createdAt,
              syncedAt: DateTime.now(),
              status: SyncStatus.success,
            );
          }
          return pkg;
        }).toList();

        // Update profiles last sync timestamps
        _profiles = _profiles.map((p) {
          if (p.isConnected) {
            return CloudProfile(
              profileId: p.profileId,
              provider: p.provider,
              accountEmail: p.accountEmail,
              isConnected: p.isConnected,
              isolatedMetadataOnly: p.isolatedMetadataOnly,
              lastSyncTime: DateTime.now(),
            );
          }
          return p;
        }).toList();

        onMessage(
          'Dynamic cloud bridge synchronized.', 
          'تمت المزامنة وحفظ السجلات السحابية بصيغة صفرية المعرفة.'
        );

        _recalculateScores();
        saveState();
        notifyListeners();
        return false;
      }
    });
  }

  // Terminate active sync
  void cancelSync() {
    _isSyncing = false;
    _syncProgress = 0.0;
    _syncMessageEn = null;
    _syncMessageAr = null;
    notifyListeners();
  }

  // Recalculating dynamic security metrics
  void _recalculateScores() {
    double baseReadiness = 100.0;
    double baseIntegrity = 100.0;
    double baseSecurity = 100.0;

    // 1. Calculations for dynamic Sync Readiness index
    final hasActiveConnection = _profiles.any((p) => p.isConnected);
    if (!hasActiveConnection) {
      baseReadiness = 30.0; // low readiness without connection
    } else {
      // Deduct slightly for pending sync packages
      final pendingCount = _packages.where((p) => p.status == SyncStatus.pending).length;
      baseReadiness -= (pendingCount * 8.0);
    }

    // Deduct for unresolved conflicts
    final unresolvedConflictsCount = _conflicts.where((c) => !c.isResolved).length;
    baseReadiness -= (unresolvedConflictsCount * 15.0);
    baseReadiness = baseReadiness.clamp(10.0, 100.0);

    // 2. Backup Integrity Index calculations
    final failedPackagesCount = _packages.where((p) => p.status == SyncStatus.failed).length;
    baseIntegrity -= (failedPackagesCount * 25.0);

    // If active connections have metadata verification anomalies (unresolved conflicts)
    baseIntegrity -= (unresolvedConflictsCount * 10.0);
    baseIntegrity = baseIntegrity.clamp(20.0, 100.0);

    // 3. Sync Security Score evaluation rules
    // Metadata leakage vulnerability if IsolatedMetadataOnly (Zero Knowledge) is disabled
    final leakageProneProfilesCount = _profiles.where((p) => p.isConnected && !p.isolatedMetadataOnly).length;
    baseSecurity -= (leakageProneProfilesCount * 35.0);

    // Minor scoring reduction for legacy or weak local fingerprints
    for (var pkg in _packages) {
      if (pkg.localKeyFingerprint.isEmpty) {
        baseSecurity -= 5.0;
      }
    }
    baseSecurity = baseSecurity.clamp(15.0, 100.0);

    _metrics = CloudSyncMetrics(
      syncReadinessScore: baseReadiness,
      backupIntegrityScore: baseIntegrity,
      syncSecurityScore: baseSecurity,
      lastCheckTime: DateTime.now(),
    );
  }

  // Persistence methods
  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'profiles': _profiles.map((p) => p.toJson()).toList(),
        'packages': _packages.map((pkg) => pkg.toJson()).toList(),
        'conflicts': _conflicts.map((c) => c.toJson()).toList(),
        'metrics': _metrics?.toJson(),
      };

      final file = File('riman_cloud_bridge_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Cloud DB save fallback: $e');
    }
  }

  void loadState() {
    try {
      final file = File('riman_cloud_bridge_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['profiles'] != null) {
          final lp = map['profiles'] as List;
          _profiles = lp.map((p) => CloudProfile.fromJson(p as Map<String, dynamic>)).toList();
        }
        if (map['packages'] != null) {
          final lpkg = map['packages'] as List;
          _packages = lpkg.map((pkg) => SecureBackupPackage.fromJson(pkg as Map<String, dynamic>)).toList();
        }
        if (map['conflicts'] != null) {
          final lc = map['conflicts'] as List;
          _conflicts = lc.map((c) => SyncConflict.fromJson(c as Map<String, dynamic>)).toList();
        }
        if (map['metrics'] != null) {
          _metrics = CloudSyncMetrics.fromJson(map['metrics'] as Map<String, dynamic>);
        }
      } else {
        _seedDefaults();
      }
    } catch (e) {
      debugPrint('Cloud engine loading failure, fallback to seeding: $e');
      _seedDefaults();
    }
  }

  void resetCloudBridgeDataset() {
    _profiles.clear();
    _packages.clear();
    _conflicts.clear();
    _seedDefaults();
    notifyListeners();
  }

  void _seedDefaults() {
    final now = DateTime.now();

    // 1. Add baseline cloud connections and default zero-knowledge configurations
    _profiles = [
      CloudProfile(
        profileId: 'prof_gdrive_01',
        provider: CloudProviderType.googleDrive,
        accountEmail: 'secops.operator@riman.gov.sa',
        isConnected: true,
        isolatedMetadataOnly: true,
        lastSyncTime: now.subtract(const Duration(hours: 3)),
      ),
      CloudProfile(
        profileId: 'prof_dropbox_02',
        provider: CloudProviderType.dropbox,
        accountEmail: 'external.node@riman.io',
        isConnected: false,
        isolatedMetadataOnly: true,
        lastSyncTime: null,
      ),
    ];

    // 2. Seed a historical successfully synchronized backup package and a pending one
    _packages = [
      SecureBackupPackage(
        packageId: 'pkg_hist_01',
        nameEn: 'W7-Decentralized-Vault-Coherence',
        nameAr: 'أسبوع-7-ترابط-الخزائن-اللامركزية',
        bundledItemIds: ['item_v1', 'item_v2'],
        totalBytes: 15728640, // 15MB
        encryptedDigest: 'sha256_8cb23b1f9faeeed11299ef87bc772186',
        localKeyFingerprint: 'rimankey_aes256_0xdeadbeef',
        createdAt: now.subtract(const Duration(days: 1)),
        syncedAt: now.subtract(const Duration(days: 1, hours: 2)),
        status: SyncStatus.success,
      ),
      SecureBackupPackage(
        packageId: 'pkg_pend_02',
        nameEn: 'Pending-Identity-Tokens-Bundle',
        nameAr: 'حزمة-مؤشرات-الهوية-المعلقة',
        bundledItemIds: ['item_n1'],
        totalBytes: 524288, // 512KB
        encryptedDigest: 'sha256_5aee7b2c99aeb17772187f59e9bcee12',
        localKeyFingerprint: 'rimankey_kyber_0xfa11b1cc',
        createdAt: now.subtract(const Duration(minutes: 45)),
        status: SyncStatus.pending,
      ),
    ];

    // 3. Setup core conflict resolution engine seed problems (simulated replication conflicts)
    _conflicts = [
      SyncConflict(
        conflictId: 'conf_v1_01',
        filenameEn: 'Sealed-Capital-Reserves.note',
        filenameAr: 'الاحتياطيات-النظامية-المشفرة.note',
        itemType: 'note',
        localTime: now.subtract(const Duration(minutes: 10)),
        cloudTime: now.subtract(const Duration(minutes: 5)),
        localSizeBytes: 1024 * 12, // 12KB
        cloudSizeBytes: 1024 * 14, // 14KB
        isResolved: false,
      ),
      SyncConflict(
        conflictId: 'conf_v2_02',
        filenameEn: 'Sector-9-Quantum-Entropy.file',
        filenameAr: 'عشوائية-الكم-للقطاع-التاسع.file',
        itemType: 'file',
        localTime: now.subtract(const Duration(minutes: 30)),
        cloudTime: now.subtract(const Duration(minutes: 15)),
        localSizeBytes: 1024 * 512, // 512KB
        cloudSizeBytes: 1024 * 512, // Same size bytes conflict
        isResolved: false,
      ),
    ];

    _recalculateScores();
    saveState();
  }
}
