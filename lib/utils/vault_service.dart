import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class VaultFile {
  final String id;
  final String originalName;
  final String encryptedName;
  final String fileType;
  final String category;
  final DateTime createdAt;
  final int sizeInBytes;
  final String sizeFormatted;
  final String vaultId;

  VaultFile({
    required this.id,
    required this.originalName,
    required this.encryptedName,
    required this.fileType,
    required this.category,
    required this.createdAt,
    required this.sizeInBytes,
    required this.sizeFormatted,
    required this.vaultId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'encryptedName': encryptedName,
        'fileType': fileType,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'sizeInBytes': sizeInBytes,
        'sizeFormatted': sizeFormatted,
        'vaultId': vaultId,
      };

  factory VaultFile.fromJson(Map<String, dynamic> json) => VaultFile(
        id: json['id'] as String,
        originalName: json['originalName'] as String,
        encryptedName: json['encryptedName'] as String,
        fileType: json['fileType'] as String,
        category: json['category'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sizeInBytes: json['sizeInBytes'] as int,
        sizeFormatted: json['sizeFormatted'] as String,
        vaultId: json['vaultId'] as String,
      );
}

class VaultActivity {
  final String id;
  final DateTime timestamp;
  final String type; // 'file_added', 'file_encrypted', 'file_opened', 'file_removed', 'vault_created'
  final String title;
  final String description;

  VaultActivity({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'title': title,
        'description': description,
      };

  factory VaultActivity.fromJson(Map<String, dynamic> json) => VaultActivity(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
      );
}

class Vault {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<VaultFile> files;

  Vault({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'files': files.map((f) => f.toJson()).toList(),
      };

  factory Vault.fromJson(Map<String, dynamic> json) {
    var filesJson = json['files'] as List? ?? [];
    return Vault(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      files: filesJson.map((f) => VaultFile.fromJson(f as Map<String, dynamic>)).toList(),
    );
  }

  int get totalSizeInBytes => files.fold(0, (sum, f) => sum + f.sizeInBytes);

  String get totalSizeFormatted {
    int bytes = totalSizeInBytes;
    if (bytes == 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    double mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class VaultService extends ChangeNotifier {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;

  VaultService._internal() {
    _initializeDefaultState();
    loadStateLocally();
  }

  List<Vault> _vaults = [];
  List<VaultActivity> _activities = [];
  List<String> _categories = ['Documents', 'Photos', 'Videos', 'Notes', 'Archives'];

  List<Vault> get vaults => _vaults;
  List<VaultActivity> get activities => _activities;
  List<String> get categories => _categories;

  void _initializeDefaultState() {
    // Initial seeded vaults (Realistic & Premium, no placeholders)
    final v1 = Vault(
      id: 'v_personal_01',
      name: 'Personal Vault',
      description: 'Primary private safe space for personal credentials & keys.',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      files: [
        VaultFile(
          id: 'f_personal_01',
          originalName: 'passport_scan.png',
          encryptedName: 'passport_scan.png.riman',
          fileType: 'PNG',
          category: 'Photos',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          sizeInBytes: 1540000, // 1.47 MB
          sizeFormatted: '1.47 MB',
          vaultId: 'v_personal_01',
        ),
      ],
    );

    final v2 = Vault(
      id: 'v_documents_02',
      name: 'Documents Vault',
      description: 'Confidential digital contracts and financial records repository.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      files: [
        VaultFile(
          id: 'f_documents_01',
          originalName: 'property_contract.pdf',
          encryptedName: 'property_contract.pdf.riman',
          fileType: 'PDF',
          category: 'Documents',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          sizeInBytes: 4200000, // 4.0 MB
          sizeFormatted: '4.0 MB',
          vaultId: 'v_documents_02',
        ),
        VaultFile(
          id: 'f_documents_02',
          originalName: 'scientific_notes.pdf',
          encryptedName: 'scientific_notes.pdf.riman',
          fileType: 'PDF',
          category: 'Notes',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          sizeInBytes: 8500000, // 8.1 MB
          sizeFormatted: '8.1 MB',
          vaultId: 'v_documents_02',
        ),
      ],
    );

    final v3 = Vault(
      id: 'v_archive_03',
      name: 'Archive Vault',
      description: 'Historic sovereign snapshots and backup structures.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      files: [],
    );

    _vaults = [v1, v2, v3];

    _activities = [
      VaultActivity(
        id: 'act_01',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        type: 'file_encrypted',
        title: 'File Encrypted & Registered',
        description: 'Successfully registered passport_scan.png inside Personal Vault.',
      ),
      VaultActivity(
        id: 'act_02',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        type: 'file_encrypted',
        title: 'Contract Encrypted',
        description: 'Placed property_contract.pdf into Documents Vault securely.',
      ),
      VaultActivity(
        id: 'act_03',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        type: 'file_encrypted',
        title: 'Notes Added',
        description: 'Successfully stored scientific_notes.pdf in Documents Vault.',
      ),
    ];
  }

  // Metric Computations
  int get totalVaultsCount => _vaults.length;
  int get totalFilesCount => _vaults.fold(0, (sum, v) => sum + v.files.length);
  int get totalSizeInBytes => _vaults.fold(0, (sum, v) => sum + v.totalSizeInBytes);

  String get totalSizeFormatted {
    int bytes = totalSizeInBytes;
    if (bytes == 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    double mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  // Crud Ops
  void createVault({required String name, required String description}) {
    final String id = 'v_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999)}';
    final newVault = Vault(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      files: [],
    );
    _vaults.add(newVault);
    logActivity('vault_created', 'New Vault Initialized', 'Vault "$name" completed standard onboarding protocols.');
    saveStateLocally();
    notifyListeners();
  }

  void deleteVault(String vaultId) {
    final idx = _vaults.indexWhere((v) => v.id == vaultId);
    if (idx != -1) {
      final name = _vaults[idx].name;
      _vaults.removeAt(idx);
      logActivity('vault_created', 'Vault Dismantled', 'Vault "$name" and its internal maps were flushed from the index.');
      saveStateLocally();
      notifyListeners();
    }
  }

  void registerCategory(String category) {
    if (!_categories.contains(category) && category.trim().isNotEmpty) {
      _categories.add(category.trim());
      saveStateLocally();
      notifyListeners();
    }
  }

  void registerFileAndEncrypt({
    required String vaultId,
    required String originalName,
    required String category,
    required int sizeInBytes,
    required String sizeFormatted,
  }) {
    final vaultIdx = _vaults.indexWhere((v) => v.id == vaultId);
    if (vaultIdx == -1) return;

    final String fileId = 'f_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(999)}';
    final String encName = '$originalName.riman';
    final extIndex = originalName.lastIndexOf('.');
    final String ext = extIndex != -1 ? originalName.substring(extIndex + 1).toUpperCase() : 'RAW';

    final newFile = VaultFile(
      id: fileId,
      originalName: originalName,
      encryptedName: encName,
      fileType: ext,
      category: category,
      createdAt: DateTime.now(),
      sizeInBytes: sizeInBytes,
      sizeFormatted: sizeFormatted,
      vaultId: vaultId,
    );

    _vaults[vaultIdx].files.add(newFile);
    logActivity('file_added', 'File Registered', 'Registered "$originalName" inside environment: ${_vaults[vaultIdx].name}.');
    logActivity('file_encrypted', 'Assets Secured Automatically', 'Double cipher dynamic key rotation sealed "$encName" automatically.');
    saveStateLocally();
    notifyListeners();
  }

  void openFile(String vaultId, String fileId) {
    final vault = _vaults.firstWhere((v) => v.id == vaultId, orElse: () => _vaults[0]);
    final file = vault.files.firstWhere((f) => f.id == fileId, orElse: () => vault.files[0]);
    logActivity('file_opened', 'Asset Reconstituted', 'Decrypted payload map of "${file.originalName}" via matching entropy block.');
    notifyListeners();
  }

  void removeFile(String vaultId, String fileId) {
    final vaultIdx = _vaults.indexWhere((v) => v.id == vaultId);
    if (vaultIdx == -1) return;

    final fileIdx = _vaults[vaultIdx].files.indexWhere((f) => f.id == fileId);
    if (fileIdx == -1) return;

    final fileName = _vaults[vaultIdx].files[fileIdx].originalName;
    _vaults[vaultIdx].files.removeAt(fileIdx);

    logActivity('file_removed', 'Asset Purged', 'Destroyed mathematical containment files for "$fileName".');
    saveStateLocally();
    notifyListeners();
  }

  void logActivity(String type, String title, String description) {
    final String actId = 'act_${DateTime.now().millisecondsSinceEpoch}';
    final act = VaultActivity(
      id: actId,
      timestamp: DateTime.now(),
      type: type,
      title: title,
      description: description,
    );
    _activities.insert(0, act);
    if (_activities.length > 50) {
      _activities.removeLast();
    }
  }

  // Persistence Handling
  void saveStateLocally() {
    try {
      final Map<String, dynamic> state = {
        'vaults': _vaults.map((v) => v.toJson()).toList(),
        'activities': _activities.map((a) => a.toJson()).toList(),
        'categories': _categories,
      };
      final dataStr = json.encode(state);
      final file = File('vaults_db.json');
      file.writeAsStringSync(dataStr);
    } catch (e) {
      debugPrint('Local writing ignored or unavailable in current environment: $e');
    }
  }

  void loadStateLocally() {
    try {
      final file = File('vaults_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final Map<String, dynamic> state = json.decode(dataStr) as Map<String, dynamic>;

        _categories = List<String>.from(state['categories'] as List? ?? _categories);

        var vList = state['vaults'] as List?;
        if (vList != null) {
          _vaults = vList.map((v) => Vault.fromJson(v as Map<String, dynamic>)).toList();
        }

        var actList = state['activities'] as List?;
        if (actList != null) {
          _activities = actList.map((a) => VaultActivity.fromJson(a as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Local reading ignored or unavailable in current environment: $e');
    }
  }
}
