import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/archive_engine.dart';
import '../utils/vault_service.dart';
import '../utils/nexus_service.dart';

class ArchiveService extends ChangeNotifier {
  static final ArchiveService _instance = ArchiveService._internal();
  factory ArchiveService() => _instance;

  ArchiveService._internal() {
    loadState();
  }

  List<ArchiveItem> _archives = [];
  List<ArchiveItem> get archives => _archives;

  List<ArchiveSnapshot> _snapshots = [];
  List<ArchiveSnapshot> get snapshots => _snapshots;

  // Active status variables
  bool _isColdStoragePowerSave = false;
  bool get isColdStoragePowerSave => _isColdStoragePowerSave;

  void toggleColdStoragePowerSave(bool enabled) {
    _isColdStoragePowerSave = enabled;
    saveState();
    notifyListeners();
  }

  // Calculate dynamic metrics
  ArchiveHealthMetrics getHealthMetrics() {
    if (_archives.isEmpty) {
      return ArchiveHealthMetrics(
        overallScore: 100.0,
        totalCapacityBytes: 15 * 1024 * 1024 * 1024, // 15 GB
        usedCapacityBytes: 0,
        totalArchives: 0,
        immutableCount: 0,
        coldStorageCount: 0,
        longTermCount: 0,
        historicalCount: 0,
      );
    }

    double runningHealthSum = 0.0;
    int immuCount = 0;
    int coldCount = 0;
    int longTermCount = 0;
    int historicalCount = 0;
    int totalBytesUsed = 0;

    for (var item in _archives) {
      runningHealthSum += item.healthScore;
      if (item.isImmutable) immuCount++;
      if (item.state == ArchiveState.ColdStorage) coldCount++;
      if (item.state == ArchiveState.LongTerm) longTermCount++;
      if (item.state == ArchiveState.Historical) historicalCount++;
      totalBytesUsed += item.sizeInBytes;
    }

    double avgHealthScore = runningHealthSum / _archives.length;

    // Standard static allocation limit (e.g. 512 MB for local client storage sandbox)
    return ArchiveHealthMetrics(
      overallScore: avgHealthScore,
      totalCapacityBytes: 512 * 1024 * 1024, // 512 MB simulated capacity
      usedCapacityBytes: totalBytesUsed,
      totalArchives: _archives.length,
      immutableCount: immuCount,
      coldStorageCount: coldCount,
      longTermCount: longTermCount,
      historicalCount: historicalCount,
    );
  }

  // Create an archive from any active resource types
  void archiveResource({
    required String originalId,
    required String name,
    required String type,
    required int sizeInBytes,
    required ArchiveState state,
    required String category,
    required String description,
    bool isImmutable = false,
  }) {
    // Generate new unique ID
    final id = 'arc_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999)}';
    
    final newItem = ArchiveItem(
      id: id,
      originalId: originalId,
      name: name,
      type: type,
      sizeInBytes: sizeInBytes,
      state: state,
      healthScore: 98.0 + (math.Random().nextDouble() * 2.0), // Starts with pristine health score 98-100%
      isImmutable: isImmutable,
      archivedAt: DateTime.now(),
      lastSnapshotAt: DateTime.now(),
      retentionDays: state == ArchiveState.Historical ? 1800 : 365,
      ranking: 3 + math.Random().nextInt(3), // default 3 to 5 star
      category: category,
      description: description,
    );

    _archives.add(newItem);

    // Create its first integrity snapshot
    _createSnapshot(id, sizeInBytes);

    saveState();
    notifyListeners();
  }

  // Generate snapshot auditing
  void _createSnapshot(String archiveId, int size) {
    final snapshotId = 'snap_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999)}';
    final randomHex = List.generate(16, (index) => '0123456789abcdef'[math.Random().nextInt(16)]).join();
    final newSnap = ArchiveSnapshot(
      id: snapshotId,
      archiveId: archiveId,
      timestamp: DateTime.now(),
      sizeInBytes: size,
      integrityHash: 'sha256-$randomHex',
      status: 'Verified',
    );
    _snapshots.add(newSnap);
  }

  // Core Mutation methods
  void toggleImmutability(String id, bool val) {
    final idx = _archives.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _archives[idx];
      // Build a copy since they are final fields
      _archives[idx] = ArchiveItem(
        id: old.id,
        originalId: old.originalId,
        name: old.name,
        type: old.type,
        sizeInBytes: old.sizeInBytes,
        state: old.state,
        healthScore: old.healthScore,
        isImmutable: val,
        archivedAt: old.archivedAt,
        lastSnapshotAt: DateTime.now(),
        retentionDays: old.retentionDays,
        ranking: old.ranking,
        category: old.category,
        description: old.description,
      );
      _createSnapshot(id, old.sizeInBytes);
      saveState();
      notifyListeners();
    }
  }

  void updateArchiveState(String id, ArchiveState newState) {
    final idx = _archives.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _archives[idx];
      if (old.isImmutable) return; // Immutable archives cannot be altered

      _archives[idx] = ArchiveItem(
        id: old.id,
        originalId: old.originalId,
        name: old.name,
        type: old.type,
        sizeInBytes: old.sizeInBytes,
        state: newState,
        healthScore: old.healthScore,
        isImmutable: old.isImmutable,
        archivedAt: old.archivedAt,
        lastSnapshotAt: DateTime.now(),
        retentionDays: newState == ArchiveState.ColdStorage ? 1000 : old.retentionDays,
        ranking: old.ranking,
        category: old.category,
        description: old.description,
      );
      _createSnapshot(id, old.sizeInBytes);
      saveState();
      notifyListeners();
    }
  }

  void deleteArchive(String id) {
    final item = _archives.firstWhere((element) => element.id == id);
    if (item.isImmutable) return; // Cannot delete immutable node

    _archives.removeWhere((item) => item.id == id);
    _snapshots.removeWhere((snap) => snap.archiveId == id);
    saveState();
    notifyListeners();
  }

  void updateRanking(String id, int newRank) {
    final idx = _archives.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _archives[idx];
      _archives[idx] = ArchiveItem(
        id: old.id,
        originalId: old.originalId,
        name: old.name,
        type: old.type,
        sizeInBytes: old.sizeInBytes,
        state: old.state,
        healthScore: old.healthScore,
        isImmutable: old.isImmutable,
        archivedAt: old.archivedAt,
        lastSnapshotAt: old.lastSnapshotAt,
        retentionDays: old.retentionDays,
        ranking: newRank.clamp(1, 5),
        category: old.category,
        description: old.description,
      );
      saveState();
      notifyListeners();
    }
  }

  // DEEP SEARCH SYSTEM: Aggregates everything in Vaults, Notes, Journals, Media, and Archives
  List<SearchResult> performDeepSearch(String query) {
    final List<SearchResult> results = [];
    if (query.isEmpty) return results;

    final q = query.toLowerCase();

    // 1. Search vaults and inner files
    final vaults = VaultService().vaults;
    for (var vault in vaults) {
      if (vault.name.toLowerCase().contains(q) || vault.description.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: vault.id,
          title: vault.name,
          subtitle: vault.description,
          type: 'vault',
          details: 'Vault created on ${vault.createdAt.day}/${vault.createdAt.month}',
          relevanceScore: 9.0,
        ));
      }
      for (var file in vault.files) {
        if (file.originalName.toLowerCase().contains(q) || file.category.toLowerCase().contains(q)) {
          results.add(SearchResult(
            id: file.id,
            title: file.originalName,
            subtitle: 'Category: ${file.category} (GCM AES Crypt)',
            type: 'file',
            details: 'Located inside ${vault.name} (${file.sizeFormatted})',
            relevanceScore: file.originalName.toLowerCase().startsWith(q) ? 10.0 : 8.0,
          ));
        }
      }
    }

    // 2. Search available assets via Nexus mapping (Notes/Journals/Capsules)
    final assets = NexusService().getAvailableAssets();
    for (var asset in assets) {
      // Avoid adding duplicate IDs from Vault/File processed above
      if (asset.type == 'vault' || asset.type == 'file') continue;

      if (asset.name.toLowerCase().contains(q) || asset.details.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: asset.id,
          title: asset.name,
          subtitle: asset.details,
          type: asset.type,
          details: 'Module: ${asset.category}',
          relevanceScore: asset.name.toLowerCase().startsWith(q) ? 9.5 : 7.0,
        ));
      }
    }

    // 3. Search Archived items themselves
    for (var src in _archives) {
      if (src.name.toLowerCase().contains(q) || src.description.toLowerCase().contains(q) || src.category.toLowerCase().contains(q)) {
        results.add(SearchResult(
          id: src.id,
          title: src.name,
          subtitle: 'Archived Metadata (${src.state.name.toUpperCase()})',
          type: 'archive',
          details: 'Archive Score: ${src.healthScore.toStringAsFixed(1)}% | Ranking: ${src.ranking} Stars',
          relevanceScore: 11.0, // highly relevant if found in archives
        ));
      }
    }

    // Sort results by relevance score descending
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  // Load/Save state
  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'archives': _archives.map((a) => a.toJson()).toList(),
        'snapshots': _snapshots.map((s) => s.toJson()).toList(),
        'isColdStoragePowerSave': _isColdStoragePowerSave,
      };
      final file = File('archives_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Archive DB writing skipped: $e');
    }
  }

  void loadState() {
    try {
      final file = File('archives_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;
        
        if (map['archives'] != null) {
          final listArc = map['archives'] as List;
          _archives = listArc.map((a) => ArchiveItem.fromJson(a as Map<String, dynamic>)).toList();
        }
        if (map['snapshots'] != null) {
          final listSnap = map['snapshots'] as List;
          _snapshots = listSnap.map((s) => ArchiveSnapshot.fromJson(s as Map<String, dynamic>)).toList();
        }
        _isColdStoragePowerSave = map['isColdStoragePowerSave'] as bool? ?? false;
      } else {
        _seedDefaultArchives();
      }
    } catch (e) {
      debugPrint('Archive DB reading skipped / seeded defaults: $e');
      _seedDefaultArchives();
    }
  }

  void _seedDefaultArchives() {
    _archives = [
      ArchiveItem(
        id: 'arc_seeded_1',
        originalId: 'note_12',
        name: 'Quantum Ledger Riemann Coefficients 2025',
        type: 'note',
        sizeInBytes: 24500,
        state: ArchiveState.ColdStorage,
        healthScore: 99.4,
        isImmutable: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 34)),
        lastSnapshotAt: DateTime.now().subtract(const Duration(days: 1)),
        retentionDays: 1000,
        ranking: 5,
        category: 'Secrets',
        description: 'Seeded master key coordinates frozen in cold store.',
      ),
      ArchiveItem(
        id: 'arc_seeded_2',
        originalId: 'file_99',
        name: 'corporate_patent_v9.pdf',
        type: 'file',
        sizeInBytes: 15420000, // 15.4 MB
        state: ArchiveState.LongTerm,
        healthScore: 97.2,
        isImmutable: false,
        archivedAt: DateTime.now().subtract(const Duration(days: 120)),
        lastSnapshotAt: DateTime.now().subtract(const Duration(days: 4)),
        retentionDays: 365,
        ranking: 4,
        category: 'Legal',
        description: 'Coherent product patent design schematic cold-archived.',
      ),
      ArchiveItem(
        id: 'arc_seeded_3',
        originalId: 'journal_42',
        name: 'Prime Conjecture Collision Logs',
        type: 'journal',
        sizeInBytes: 4200,
        state: ArchiveState.Historical,
        healthScore: 100.0,
        isImmutable: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 200)),
        lastSnapshotAt: DateTime.now().subtract(const Duration(days: 10)),
        retentionDays: 1800,
        ranking: 4,
        category: 'Research',
        description: 'Serene state observations mapped to the Riemann zero matrix.',
      ),
    ];

    _snapshots = [
      ArchiveSnapshot(
        id: 'snap_seeded_1',
        archiveId: 'arc_seeded_1',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        sizeInBytes: 24500,
        integrityHash: 'sha256-a1b2c3d4e5f60718293a4b5c6d7e8f90',
        status: 'Verified',
      ),
      ArchiveSnapshot(
        id: 'snap_seeded_2',
        archiveId: 'arc_seeded_2',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        sizeInBytes: 15420000,
        integrityHash: 'sha256-ffeeddccbbaa99887766554433221100',
        status: 'Verified',
      ),
      ArchiveSnapshot(
        id: 'snap_seeded_3',
        archiveId: 'arc_seeded_3',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        sizeInBytes: 4200,
        integrityHash: 'sha256-99aa88bb77cc66dd55ee44ff33bb22cc',
        status: 'Verified',
      ),
    ];
  }
}

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'vault', 'file', 'note', 'journal', 'capsule', 'archive', 'media'
  final String details;
  final double relevanceScore;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.details,
    required this.relevanceScore,
  });
}
