import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'vault_service.dart';
import '../models/nexus.dart';

class NexusService extends ChangeNotifier {
  static final NexusService _instance = NexusService._internal();
  factory NexusService() => _instance;

  NexusService._internal() {
    loadLinks();
  }

  // Active relationships list
  List<NexusLink> _links = [];
  List<NexusLink> get links => _links;

  // Registered in-memory assets from widgets
  final List<NexusAsset> _registeredNotes = [];
  final List<NexusAsset> _registeredJournals = [];
  final List<NexusAsset> _registeredCapsules = [];
  final List<NexusAsset> _registeredMedia = [];

  // Register assets from visual tabs when loaded
  void registerNotes(List<dynamic> rawNotes) {
    _registeredNotes.clear();
    for (var note in rawNotes) {
      try {
        final id = note.id as String;
        final title = note.title as String;
        final cat = note.category as String;
        _registeredNotes.add(NexusAsset(
          id: id,
          name: title,
          type: 'note',
          details: 'Note in Category: $cat',
          category: cat,
        ));
      } catch (_) {}
    }
    notifyListeners();
  }

  void registerJournals(List<dynamic> rawJournals) {
    _registeredJournals.clear();
    for (var journal in rawJournals) {
      try {
        final id = journal.id as String;
        final title = journal.title as String;
        final mood = journal.mood as String;
        _registeredJournals.add(NexusAsset(
          id: id,
          name: title,
          type: 'journal',
          details: 'Journal Entry with mood $mood',
          category: 'Journal',
        ));
      } catch (_) {}
    }
    notifyListeners();
  }

  void registerCapsules(List<Map<String, dynamic>> capsules) {
    _registeredCapsules.clear();
    for (var cap in capsules) {
      _registeredCapsules.add(NexusAsset(
        id: cap['id'] ?? '',
        name: cap['name'] ?? '',
        type: 'capsule',
        details: 'Time Capsule locked status: ${cap['isLocked']}',
        category: 'Capsule',
      ));
    }
    notifyListeners();
  }

  void registerMedia(List<dynamic> rawMedia, String type) {
    _registeredMedia.clear();
    for (var item in rawMedia) {
      try {
        final id = item.id as String;
        final name = item.name as String;
        _registeredMedia.add(NexusAsset(
          id: id,
          name: name,
          type: type,
          details: 'Secure $type element',
          category: 'Media',
        ));
      } catch (_) {}
    }
    notifyListeners();
  }

  // Retrieve list of ALL potential target assets in the sovereign environment
  List<NexusAsset> getAvailableAssets() {
    final List<NexusAsset> results = [];

    // 1. Vaults from VaultService
    final vaults = VaultService().vaults;
    for (var v in vaults) {
      results.add(NexusAsset(
        id: v.id,
        name: v.name,
        type: 'vault',
        details: 'Vault: ${v.description}',
        category: 'Vault',
      ));

      // 2. Files contained in Vaults
      for (var f in v.files) {
        results.add(NexusAsset(
          id: f.id,
          name: f.originalName,
          type: 'file',
          details: 'Encrypted: ${f.encryptedName} (${f.sizeFormatted})',
          category: f.category,
        ));
      }
    }

    // 3. Notes
    results.addAll(_registeredNotes);

    // 4. Journals
    results.addAll(_registeredJournals);

    // 5. Capsules
    results.addAll(_registeredCapsules);

    // If registered lists are empty, seed some default representations for UX
    if (_registeredNotes.isEmpty) {
      results.add(NexusAsset(
        id: 'n1',
        name: 'Riemann Master Encryption Coordinates',
        type: 'note',
        details: 'Note in Category: Secrets',
        category: 'Secrets',
      ));
      results.add(NexusAsset(
        id: 'n2',
        name: 'Wallet Backup Seeds Crypt Block',
        type: 'note',
        details: 'Note in Category: Credentials',
        category: 'Credentials',
      ));
    }

    if (_registeredJournals.isEmpty) {
      results.add(NexusAsset(
        id: 'j1',
        name: 'Orbit Spectrum Convergence Test',
        type: 'journal',
        details: 'Journal Entry with mood serene',
        category: 'Journal',
      ));
      results.add(NexusAsset(
        id: 'j2',
        name: 'Entropy Leak Incident Resolve',
        type: 'journal',
        details: 'Journal Entry with mood vigilant',
        category: 'Journal',
      ));
    }

    if (_registeredCapsules.isEmpty) {
      results.add(NexusAsset(
        id: 'capsule_1',
        name: 'financial_ledger_2026.pdf',
        type: 'capsule',
        details: 'Time Capsule locked status: true',
        category: 'Capsule',
      ));
      results.add(NexusAsset(
        id: 'capsule_2',
        name: 'android_production_keystore.jks',
        type: 'capsule',
        details: 'Time Capsule locked status: false',
        category: 'Capsule',
      ));
    }

    return results;
  }

  // Relations CRUD
  void addLink({
    required String sourceId,
    required String sourceType,
    required String sourceName,
    required String targetId,
    required String targetType,
    required String targetName,
    required String relationType,
    String description = '',
  }) {
    // Prevent duplicate links
    final duplicate = _links.any((l) =>
        (l.sourceId == sourceId && l.targetId == targetId) ||
        (l.sourceId == targetId && l.targetId == sourceId));

    if (duplicate) return;

    final newLink = NexusLink(
      id: 'link_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999)}',
      sourceId: sourceId,
      sourceType: sourceType,
      sourceName: sourceName,
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
      relationType: relationType,
      createdAt: DateTime.now(),
      description: description,
    );

    _links.add(newLink);
    saveLinks();
    notifyListeners();
  }

  void deleteLink(String id) {
    _links.removeWhere((l) => l.id == id);
    saveLinks();
    notifyListeners();
  }

  // SMART GROUPS ANALYSIS
  
  // 1. Orphan Assets: Assets that have absolutely no relationships defined
  List<NexusAsset> getOrphanAssets() {
    final allAssets = getAvailableAssets();
    final List<NexusAsset> orphans = [];

    for (var asset in allAssets) {
      final hasLink = _links.any((l) => l.sourceId == asset.id || l.targetId == asset.id);
      if (!hasLink) {
        orphans.add(asset);
      }
    }
    return orphans;
  }

  // 2. Connected Assets: Assets with 1 or more relationships defined
  List<NexusAsset> getConnectedAssets() {
    final allAssets = getAvailableAssets();
    final List<NexusAsset> connected = [];

    for (var asset in allAssets) {
      final hasLink = _links.any((l) => l.sourceId == asset.id || l.targetId == asset.id);
      if (hasLink) {
        connected.add(asset);
      }
    }
    return connected;
  }

  // 3. Recovery Critical Assets: Assets essential for backup and system recovery
  List<NexusAsset> getRecoveryCriticalAssets() {
    final allAssets = getAvailableAssets();
    final List<NexusAsset> critical = [];

    for (var asset in allAssets) {
      final nameLower = asset.name.toLowerCase();
      final catLower = asset.category.toLowerCase();
      final detailsLower = asset.details.toLowerCase();

      final isCritical = nameLower.contains('recovery') ||
          nameLower.contains('backup') ||
          nameLower.contains('seed') ||
          nameLower.contains('master') ||
          nameLower.contains('key') ||
          nameLower.contains('keystore') ||
          nameLower.contains('contract') ||
          nameLower.contains('ledger') ||
          catLower.contains('secrets') ||
          catLower.contains('credentials') ||
          detailsLower.contains('secrets') ||
          detailsLower.contains('credentials');

      if (isCritical) {
        critical.add(asset);
      }
    }
    return critical;
  }

  // Bidirectional link fetcher
  List<NexusLink> getLinksForAsset(String assetId) {
    return _links.where((l) => l.sourceId == assetId || l.targetId == assetId).toList();
  }

  // Persist Relationship DB Locally
  void saveLinks() {
    try {
      final state = _links.map((l) => l.toJson()).toList();
      final file = File('nexus_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Nexus writing ignored locally: $e');
    }
  }

  void loadLinks() {
    try {
      final file = File('nexus_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final list = json.decode(dataStr) as List;
        _links = list.map((l) => NexusLink.fromJson(l as Map<String, dynamic>)).toList();
      } else {
        _seedDefaultRelationships();
      }
    } catch (e) {
      debugPrint('Nexus reading ignored locally: $e');
      _seedDefaultRelationships();
    }
  }

  void _seedDefaultRelationships() {
    _links = [
      NexusLink(
        id: 'dlink_1',
        sourceId: 'v_documents_02',
        sourceType: 'vault',
        sourceName: 'Documents Vault',
        targetId: 'n1',
        targetType: 'note',
        targetName: 'Riemann Master Encryption Coordinates',
        relationType: 'reference',
        description: 'Mathematical references supporting documents decryption.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      NexusLink(
        id: 'dlink_2',
        sourceId: 'capsule_2',
        sourceType: 'capsule',
        sourceName: 'android_production_keystore.jks',
        targetId: 'n2',
        targetType: 'note',
        targetName: 'Wallet Backup Seeds Crypt Block',
        relationType: 'credentials',
        description: 'Backup secure seed credentials matching the production keystore.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
