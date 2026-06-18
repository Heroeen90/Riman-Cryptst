import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/forensics.dart';
import '../utils/vault_service.dart';
import '../utils/nexus_service.dart';
import '../utils/archive_service.dart';

class ForensicsService extends ChangeNotifier {
  static final ForensicsService _instance = ForensicsService._internal();
  factory ForensicsService() => _instance;

  ForensicsService._internal() {
    loadState();
  }

  List<ForensicFileIntegrity> _integrities = [];
  List<ForensicFileIntegrity> get integrities => _integrities;

  List<TamperEvent> _tamperEvents = [];
  List<TamperEvent> get tamperEvents => _tamperEvents;

  List<AuditLogEntry> _auditLogs = [];
  List<AuditLogEntry> get auditLogs => _auditLogs;

  bool _isAutoWatchdogActive = false;
  bool get isAutoWatchdogActive => _isAutoWatchdogActive;

  double get systemIntegrityScore {
    if (_integrities.isEmpty) return 100.0;
    int tampered = _integrities.where((item) => item.isTampered).length;
    double resolvedReduction = 0.0;
    for (var ev in _tamperEvents) {
      if (!ev.isResolved) {
        if (ev.severity == 'Critical') resolvedReduction += 12.0;
        else if (ev.severity == 'High') resolvedReduction += 8.0;
        else if (ev.severity == 'Medium') resolvedReduction += 4.0;
        else resolvedReduction += 1.5;
      }
    }
    double baseScore = ((_integrities.length - tampered) / _integrities.length) * 100.0;
    return (baseScore - resolvedReduction).clamp(0.0, 100.0);
  }

  void toggleAutoWatchdog(bool val) {
    _isAutoWatchdogActive = val;
    logAudit('TOGGLE_WATCHDOG', 'system', 'Real-time watchdog agent set to: ${val ? "ENGAGED" : "OFF"}');
    saveState();
    notifyListeners();
  }

  // Generates unique deterministic hashes (SHA-256 and SHA-512) for forensics simulation
  String _generateHash(String input, int length) {
    int hash1 = 5381;
    int hash2 = 33;
    for (int i = 0; i < input.length; i++) {
      hash1 = ((hash1 << 5) + hash1) + input.codeUnitAt(i);
      hash2 = ((hash2 << 7) + hash2) ^ input.codeUnitAt(i);
    }
    
    final alphabet = 'abcdef0123456789';
    final result = StringBuffer();
    for (int i = 0; i < length; i++) {
      final code = (hash1 ^ (hash2 * i) ^ (i * 997)) % 16;
      result.write(alphabet[code.abs()]);
    }
    return result.toString();
  }

  // Sync / Register all current active assets with forensics ledger
  void syncActiveResources() {
    final List<ForensicFileIntegrity> freshList = [];
    final timestamp = DateTime.now();

    // 1. Vaults and Files from VaultService
    final vaults = VaultService().vaults;
    for (var vault in vaults) {
      final vid = vault.id;
      final originalMeta = json.encode({
        'createdAt': vault.createdAt.toIso8601String(),
        'description': vault.description,
        'filesCount': vault.files.length,
      });

      // Check if already registered to keep state, or create new
      _getOrCreateIntegrity(
        freshList,
        resourceId: vid,
        name: vault.name,
        type: 'vault',
        meta: originalMeta,
      );

      for (var f in vault.files) {
        final fMeta = json.encode({
          'category': f.category,
          'sizeInBytes': f.sizeInBytes,
          'timestamp': f.createdAt.toIso8601String(),
        });
        _getOrCreateIntegrity(
          freshList,
          resourceId: f.id,
          name: f.originalName,
          type: 'file',
          meta: fMeta,
        );
      }
    }

    // 2. Available Assets from NexusService
    final nexusAssets = NexusService().getAvailableAssets();
    for (var asset in nexusAssets) {
      if (asset.type == 'vault' || asset.type == 'file') continue;
      final nMeta = json.encode({
        'category': asset.category,
        'details': asset.details,
      });
      _getOrCreateIntegrity(
        freshList,
        resourceId: asset.id,
        name: asset.name,
        type: asset.type,
        meta: nMeta,
      );
    }

    // 3. Archives in Quantum Archive
    final archives = ArchiveService().archives;
    for (var arc in archives) {
      final arcMeta = json.encode({
        'state': arc.state.name,
        'sizeInBytes': arc.sizeInBytes,
        'isImmutable': arc.isImmutable,
      });
      _getOrCreateIntegrity(
        freshList,
        resourceId: arc.id,
        name: arc.name,
        type: 'archive',
        meta: arcMeta,
      );
    }

    _integrities = freshList;
    logAudit('SYNC_LEDGER', 'ledger', 'Synchronized ${freshList.length} resource nodes with forensics block fingerprints.');
    saveState();
    notifyListeners();
  }

  void _getOrCreateIntegrity(
    List<ForensicFileIntegrity> targetList, {
    required String resourceId,
    required String name,
    required String type,
    required String meta,
  }) {
    final idx = _integrities.indexWhere((item) => item.resourceId == resourceId);
    if (idx != -1) {
      final old = _integrities[idx];
      targetList.add(ForensicFileIntegrity(
        id: old.id,
        resourceId: old.resourceId,
        resourceName: name,
        resourceType: type,
        sha256Hash: old.sha256Hash,
        sha512Hash: old.sha512Hash,
        registeredAt: old.registeredAt,
        lastCheckedAt: DateTime.now(),
        isTampered: old.isTampered,
        originalMetadata: meta,
      ));
    } else {
      final newId = 'for_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';
      targetList.add(ForensicFileIntegrity(
        id: newId,
        resourceId: resourceId,
        resourceName: name,
        resourceType: type,
        sha256Hash: _generateHash('$resourceId-$name-$type-sha256', 64),
        sha512Hash: _generateHash('$resourceId-$name-$type-sha512', 128),
        registeredAt: DateTime.now(),
        lastCheckedAt: DateTime.now(),
        isTampered: false,
        originalMetadata: meta,
      ));
    }
  }

  // Audit / Verification cycle - triggers on button click in forensics desk
  bool verifyIntegrityAll() {
    bool hasViolations = false;
    final timestamp = DateTime.now();

    logAudit('AUDIT_START', 'engine', 'Initiated system-wide byte-parity and SHA-512 forensic audit.');

    for (int i = 0; i < _integrities.length; i++) {
      final item = _integrities[i];
      
      // Simulate integrity checks. Certain nodes gets randomly flagging if watchdog or simulated errors exist.
      // But we check if mock tampered state is true
      _integrities[i] = ForensicFileIntegrity(
        id: item.id,
        resourceId: item.resourceId,
        resourceName: item.resourceName,
        resourceType: item.resourceType,
        sha256Hash: item.sha256Hash,
        sha512Hash: item.sha512Hash,
        registeredAt: item.registeredAt,
        lastCheckedAt: timestamp,
        isTampered: item.isTampered,
        originalMetadata: item.originalMetadata,
      );

      if (item.isTampered) {
        hasViolations = true;
      }
    }

    logAudit('AUDIT_COMPLETE', 'engine', 'Forensic sweep completed. Verified ${_integrities.length} nodes. Violations: ${hasViolations ? "FOUND" : "NONE"}');
    saveState();
    notifyListeners();
    return !hasViolations;
  }

  // Inject a simulated tamper corruption on a resource to trigger forensics alert center of Riman suite!!
  void injectTamperSimulation(String resourceId, {String? customDetails}) {
    final idx = _integrities.indexWhere((item) => item.resourceId == resourceId);
    if (idx != -1) {
      final old = _integrities[idx];
      _integrities[idx] = ForensicFileIntegrity(
        id: old.id,
        resourceId: old.resourceId,
        resourceName: old.resourceName,
        resourceType: old.resourceType,
        sha256Hash: old.sha256Hash,
        sha512Hash: old.sha512Hash,
        registeredAt: old.registeredAt,
        lastCheckedAt: DateTime.now(),
        isTampered: true, // Marker of tampered node!
        originalMetadata: old.originalMetadata,
      );

      final sevList = ['Medium', 'High', 'Critical'];
      final chosenSev = sevList[math.Random().nextInt(sevList.length)];
      final details = customDetails ?? 'Signature misalignment detected on zero-matrix block parity bits.';

      final newEvent = TamperEvent(
        id: 'tamp_${DateTime.now().millisecondsSinceEpoch}',
        resourceId: resourceId,
        resourceName: old.resourceName,
        details: 'Severity: $chosenSev. $details',
        timestamp: DateTime.now(),
        severity: chosenSev,
        isResolved: false,
      );

      _tamperEvents.add(newEvent);
      logAudit('TAMPER_DETECTED', old.resourceType, 'ALERT: Cryptographic drift / parity failure in ${old.resourceName}.');
      saveState();
      notifyListeners();
    }
  }

  // Repair/Resolve tamper issues
  void repairResource(String resourceId) {
    final idx = _integrities.indexWhere((item) => item.resourceId == resourceId);
    if (idx != -1) {
      final old = _integrities[idx];
      _integrities[idx] = ForensicFileIntegrity(
        id: old.id,
        resourceId: old.resourceId,
        resourceName: old.resourceName,
        resourceType: old.resourceType,
        sha256Hash: old.sha256Hash,
        sha512Hash: old.sha512Hash,
        registeredAt: old.registeredAt,
        lastCheckedAt: DateTime.now(),
        isTampered: false, // Repaired!
        originalMetadata: old.originalMetadata,
      );

      // Resolve corresponding tamper events
      for (int i = 0; i < _tamperEvents.length; i++) {
        final ev = _tamperEvents[i];
        if (ev.resourceId == resourceId && !ev.isResolved) {
          _tamperEvents[i] = TamperEvent(
            id: ev.id,
            resourceId: ev.resourceId,
            resourceName: ev.resourceName,
            details: ev.details,
            timestamp: ev.timestamp,
            severity: ev.severity,
            isResolved: true,
            resolutionNotes: 'Parity bits restored. SHA-512 hashes recalibrated to master state.',
          );
        }
      }

      logAudit('REPAIR_SUCCESS', old.resourceType, 'Recalibrated sha512 signatures for ${old.resourceName}. Safe parity restored.');
      saveState();
      notifyListeners();
    }
  }

  void clearTamperLogs() {
    _tamperEvents.clear();
    for (int i = 0; i < _integrities.length; i++) {
      final old = _integrities[i];
      _integrities[i] = ForensicFileIntegrity(
        id: old.id,
        resourceId: old.resourceId,
        resourceName: old.resourceName,
        resourceType: old.resourceType,
        sha256Hash: old.sha256Hash,
        sha512Hash: old.sha512Hash,
        registeredAt: old.registeredAt,
        lastCheckedAt: DateTime.now(),
        isTampered: false,
        originalMetadata: old.originalMetadata,
      );
    }
    logAudit('CLEAR_EVENTS', 'system', 'Purged all tamper events and reset status scores.');
    saveState();
    notifyListeners();
  }

  void logAudit(String action, String entityType, String details) {
    final entry = AuditLogEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(99)}',
      action: action,
      entityType: entityType,
      details: details,
      timestamp: DateTime.now(),
      inspector: 'SHA-512 Forensic Daemon v13.0',
    );
    _auditLogs.insert(0, entry);
    if (_auditLogs.length > 50) {
      _auditLogs.removeLast();
    }
  }

  // Load / Save DB State
  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'integrities': _integrities.map((i) => i.toJson()).toList(),
        'tamperEvents': _tamperEvents.map((e) => e.toJson()).toList(),
        'auditLogs': _auditLogs.map((l) => l.toJson()).toList(),
        'isAutoWatchdogActive': _isAutoWatchdogActive,
      };
      final file = File('forensics_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Forensics DB writing skipped: $e');
    }
  }

  void loadState() {
    try {
      final file = File('forensics_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['integrities'] != null) {
          final listInt = map['integrities'] as List;
          _integrities = listInt.map((i) => ForensicFileIntegrity.fromJson(i as Map<String, dynamic>)).toList();
        }
        if (map['tamperEvents'] != null) {
          final listTamp = map['tamperEvents'] as List;
          _tamperEvents = listTamp.map((e) => TamperEvent.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (map['auditLogs'] != null) {
          final listAud = map['auditLogs'] as List;
          _auditLogs = listAud.map((l) => AuditLogEntry.fromJson(l as Map<String, dynamic>)).toList();
        }
        _isAutoWatchdogActive = map['isAutoWatchdogActive'] as bool? ?? false;
      } else {
        _seedDefaultForensics();
      }
    } catch (e) {
      debugPrint('Forensics DB reading skipped / seeded defaults: $e');
      _seedDefaultForensics();
    }
  }

  void _seedDefaultForensics() {
    _isAutoWatchdogActive = true;
    _integrities = [];
    _tamperEvents = [];
    _auditLogs = [
      AuditLogEntry(
        id: 'aud_seed_1',
        action: 'INITIALIZE',
        entityType: 'system',
        details: 'Self-Check verified: Entropy Parity zero discrepancies detected.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        inspector: 'SHA-512 Forensic Daemon v13.0',
      ),
    ];
    // We will call syncActiveResources() inside initialization post frame callbacks or lazily
  }
}
