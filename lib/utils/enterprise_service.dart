import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/enterprise_core.dart';

class EnterpriseService extends ChangeNotifier {
  static final EnterpriseService _instance = EnterpriseService._internal();
  factory EnterpriseService() => _instance;

  EnterpriseService._internal() {
    loadState();
  }

  List<EnterpriseProfile> _profiles = [];
  List<EnterpriseProfile> get profiles => _profiles;

  List<SecureWorkspace> _workspaces = [];
  List<SecureWorkspace> get workspaces => _workspaces;

  List<WorkspaceActivityLog> _logs = [];
  List<WorkspaceActivityLog> get logs => _logs;

  EnterpriseProfile? _currentProfile;
  EnterpriseProfile? get currentProfile => _currentProfile;

  SecureWorkspace? _currentWorkspace;
  SecureWorkspace? get currentWorkspace => _currentWorkspace;

  // Change currently active security profile
  void switchProfile(String id) {
    final idx = _profiles.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _currentProfile = _profiles[idx];
      
      // Auto-switch to the first matching workspace of this profile
      final matchingWorkspaces = _workspaces.where((w) => w.profileId == id).toList();
      if (matchingWorkspaces.isNotEmpty) {
        _currentWorkspace = matchingWorkspaces.first;
      } else {
        _currentWorkspace = null;
      }

      logActivity(
        workspaceId: _currentWorkspace?.id ?? 'global',
        profileId: _currentProfile!.id,
        en: 'Transited access level to context: ${_currentProfile!.nameEn}',
        ar: 'تم تحويل مستوى الصلاحية إلى سياق: ${_currentProfile!.nameAr}',
        severity: 'info',
      );

      saveState();
      notifyListeners();
    }
  }

  // Switch workspace
  void switchWorkspace(String id) {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    if (idx != -1) {
      final w = _workspaces[idx];
      // Allow switching if we are the correct profile or if we bypass (cross-tenant compliance)
      _currentWorkspace = w;

      logActivity(
        workspaceId: _currentWorkspace!.id,
        profileId: _currentProfile?.id ?? 'global',
        en: 'Set active secure zone boundary to: ${w.nameEn}',
        ar: 'تم تنشيط حيازة الفرز الأمني للكتلة: ${w.nameAr}',
        severity: 'info',
      );

      saveState();
      notifyListeners();
    }
  }

  // Create workspace with dedicated templates
  void createWorkspace({
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    required String template, // 'Military', 'Finance', 'R&D', 'General'
    required List<String> initialResources,
  }) {
    final now = DateTime.now();
    final newId = 'ws_${now.millisecondsSinceEpoch}';
    final profileId = _currentProfile?.id ?? 'prof_personal';

    // Add pre-configured security baseline according to template selection
    final List<String> finalResources = List.from(initialResources);
    if (template == 'Military') {
      finalResources.addAll(['key_quantum_01', 'shield_tunnel_01']);
    } else if (template == 'Finance') {
      finalResources.add('ledger_accounting_01');
    } else if (template == 'R&D') {
      finalResources.add('matrix_parity_01');
    }

    final ws = SecureWorkspace(
      id: newId,
      profileId: profileId,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      templateType: template,
      isolatedResourceIds: finalResources,
      createdAt: now,
      isSealed: false,
    );

    _workspaces.add(ws);
    _currentWorkspace = ws;

    logActivity(
      workspaceId: newId,
      profileId: profileId,
      en: 'Created new isolated workspace "$nameEn" on $template guidelines.',
      ar: 'تم تشييد ساحة أمنية معزولة "$nameAr" وفق ضوابط $template.',
      severity: 'warning',
    );

    saveState();
    notifyListeners();
  }

  // Toggle workspace sealing (Resource read-only/immutable state lock)
  void toggleWorkspaceSeal(String id) {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    if (idx != -1) {
      final old = _workspaces[idx];
      final newStatus = !old.isSealed;
      _workspaces[idx] = SecureWorkspace(
        id: old.id,
        profileId: old.profileId,
        nameEn: old.nameEn,
        nameAr: old.nameAr,
        descriptionEn: old.descriptionEn,
        descriptionAr: old.descriptionAr,
        templateType: old.templateType,
        isolatedResourceIds: old.isolatedResourceIds,
        createdAt: old.createdAt,
        isSealed: newStatus,
      );

      if (_currentWorkspace?.id == id) {
        _currentWorkspace = _workspaces[idx];
      }

      logActivity(
        workspaceId: old.id,
        profileId: _currentProfile?.id ?? 'unknown',
        en: newStatus
            ? 'Applied strict write lock. Resources sealed against non-owner modifications.'
            : 'Unsealed core resource write-locks. Interop channels opened.',
        ar: newStatus
            ? 'تم تطبيق قفل التعديل الصارم. تم تجميد الموارد وتأمين الأصول الموصولة.'
            : 'تم فك ختم كود المراجعة المشترك وتنشيط قنوات التعديل المتبادل.',
        severity: newStatus ? 'critical' : 'warning',
      );

      saveState();
      notifyListeners();
    }
  }

  // Add keys / notes / files to isolated boundary
  void addResourceToActiveWorkspace(String resourceId) {
    if (_currentWorkspace == null) return;
    
    final idx = _workspaces.indexWhere((w) => w.id == _currentWorkspace!.id);
    if (idx != -1) {
      final old = _workspaces[idx];
      if (old.isSealed) return; // Prevent edits if sealed

      final updatedResources = List<String>.from(old.isolatedResourceIds);
      if (!updatedResources.contains(resourceId)) {
        updatedResources.add(resourceId);
      }

      _workspaces[idx] = SecureWorkspace(
        id: old.id,
        profileId: old.profileId,
        nameEn: old.nameEn,
        nameAr: old.nameAr,
        descriptionEn: old.descriptionEn,
        descriptionAr: old.descriptionAr,
        templateType: old.templateType,
        isolatedResourceIds: updatedResources,
        createdAt: old.createdAt,
        isSealed: old.isSealed,
      );
      
      _currentWorkspace = _workspaces[idx];

      logActivity(
        workspaceId: old.id,
        profileId: _currentProfile?.id ?? 'unknown',
        en: 'Associated signature item token "$resourceId" to isolated group context.',
        ar: 'ربط المعرف الحصين للأصل "$resourceId" في سياق العزل الحالي.',
        severity: 'info',
      );

      saveState();
      notifyListeners();
    }
  }

  // Cross-workspace search logic
  List<Map<String, dynamic>> searchAcrossWorkspaces(String query) {
    if (query.trim().isEmpty) return [];
    
    final cleanQuery = query.toLowerCase().trim();
    final List<Map<String, dynamic>> results = [];

    for (var ws in _workspaces) {
      bool matchedWs = ws.nameEn.toLowerCase().contains(cleanQuery) ||
          ws.nameAr.toLowerCase().contains(cleanQuery) ||
          ws.descriptionEn.toLowerCase().contains(cleanQuery) ||
          ws.descriptionAr.toLowerCase().contains(cleanQuery);

      if (matchedWs) {
        results.add({
          'type': 'workspace',
          'workspaceId': ws.id,
          'titleEn': ws.nameEn,
          'titleAr': ws.nameAr,
          'detailsEn': 'Workspace template: ${ws.templateType}',
          'detailsAr': 'قالب سياق العمل: ${ws.templateType}',
          'badgeColor': const Color(0xFF3B82F6),
        });
      }

      // Check workspace resources matching query
      for (var resource in ws.isolatedResourceIds) {
        if (resource.toLowerCase().contains(cleanQuery)) {
          results.add({
            'type': 'resource',
            'workspaceId': ws.id,
            'workspaceNameEn': ws.nameEn,
            'workspaceNameAr': ws.nameAr,
            'titleEn': 'Component Token: $resource',
            'titleAr': 'مؤشر أصل حرج: $resource',
            'detailsEn': 'Contained in sealed storage cluster of ${ws.nameEn}',
            'detailsAr': 'محفوظ ضمن مصفوفة حيازة ${ws.nameAr}',
            'badgeColor': const Color(0xFF10B981),
          });
        }
      }
    }

    return results;
  }

  // Calculate high quality enterprise readiness index metrics
  Map<String, dynamic> evaluateReadinessMetrics() {
    double baseScore = 70.0;
    
    int totalMfaActive = _profiles.where((p) => p.isMfaActive).length;
    double mfaFactor = _profiles.isNotEmpty ? (totalMfaActive / _profiles.length) * 15.0 : 0.0;

    int totalSealed = _workspaces.where((w) => w.isSealed).length;
    double sealFactor = _workspaces.isNotEmpty ? (totalSealed / _workspaces.length) * 10.0 : 0.0;

    double templateVarietyFactor = _workspaces.map((w) => w.templateType).toSet().length * 1.5;

    double netReadiness = (baseScore + mfaFactor + sealFactor + templateVarietyFactor).clamp(10.0, 100.0);

    return {
      'readinessScore': netReadiness,
      'mfaCompliancePercent': _profiles.isNotEmpty ? (totalMfaActive / _profiles.length) * 100 : 0.0,
      'sealedRatioPercent': _workspaces.isNotEmpty ? (totalSealed / _workspaces.length) * 100 : 0.0,
      'activeWorkspacesCount': _workspaces.length,
      'readinessScale': netReadiness >= 90.0
          ? 'SECURE ENTERPRISE LAYER'
          : netReadiness >= 75.0
              ? 'COMPLIANT ARCHITECTURE'
              : 'BASIC OFFCE SEGMENT',
      'readinessScaleAr': netReadiness >= 90.0
          ? 'تحصين مؤسسي متطور'
          : netReadiness >= 75.0
              ? 'بنية معمارية مطابقة للسياسة'
              : 'بيئة تنظيمية أولية أساسية',
    };
  }

  void logActivity({
    required String workspaceId,
    required String profileId,
    required String en,
    required String ar,
    required String severity,
  }) {
    final now = DateTime.now();
    final log = WorkspaceActivityLog(
      id: 'log_${now.millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      profileId: profileId,
      detailsEn: en,
      detailsAr: ar,
      severity: severity,
      timestamp: now,
    );
    _logs.insert(0, log);
    if (_logs.length > 40) {
      _logs.removeLast();
    }
    saveState();
  }

  void saveState() {
    try {
      final Map<String, dynamic> state = {
        'profiles': _profiles.map((p) => p.toJson()).toList(),
        'workspaces': _workspaces.map((w) => w.toJson()).toList(),
        'logs': _logs.map((l) => l.toJson()).toList(),
        'currentProfileId': _currentProfile?.id,
        'currentWorkspaceId': _currentWorkspace?.id,
      };
      final file = File('enterprise_core_db.json');
      file.writeAsStringSync(json.encode(state));
    } catch (e) {
      debugPrint('Enterprise DB write error (simulated/handled directory): $e');
    }
  }

  void loadState() {
    try {
      final file = File('enterprise_core_db.json');
      if (file.existsSync()) {
        final dataStr = file.readAsStringSync();
        final map = json.decode(dataStr) as Map<String, dynamic>;

        if (map['profiles'] != null) {
          final lp = map['profiles'] as List;
          _profiles = lp.map((p) => EnterpriseProfile.fromJson(p as Map<String, dynamic>)).toList();
        }
        if (map['workspaces'] != null) {
          final lw = map['workspaces'] as List;
          _workspaces = lw.map((w) => SecureWorkspace.fromJson(w as Map<String, dynamic>)).toList();
        }
        if (map['logs'] != null) {
          final ll = map['logs'] as List;
          _logs = ll.map((l) => WorkspaceActivityLog.fromJson(l as Map<String, dynamic>)).toList();
        }

        final cpId = map['currentProfileId'] as String?;
        if (cpId != null) {
          final idx = _profiles.indexWhere((p) => p.id == cpId);
          if (idx != -1) _currentProfile = _profiles[idx];
        } else if (_profiles.isNotEmpty) {
          _currentProfile = _profiles.first;
        }

        final cwId = map['currentWorkspaceId'] as String?;
        if (cwId != null) {
          final idx = _workspaces.indexWhere((w) => w.id == cwId);
          if (idx != -1) _currentWorkspace = _workspaces[idx];
        } else if (_workspaces.isNotEmpty) {
          _currentWorkspace = _workspaces.first;
        }
      } else {
        _seedDefaultEnterpriseCore();
      }
    } catch (e) {
      debugPrint('Enterprise DB read error, seeding defaults: $e');
      _seedDefaultEnterpriseCore();
    }
  }

  void resetEnterpriseDataset() {
    _profiles.clear();
    _workspaces.clear();
    _logs.clear();
    _seedDefaultEnterpriseCore();
    notifyListeners();
  }

  void _seedDefaultEnterpriseCore() {
    // 1. Preseed multi-profiles
    _profiles = [
      EnterpriseProfile(
        id: 'prof_personal',
        nameEn: 'Sovereign Root / Personal',
        nameAr: 'الجذر السيادي / الشخصي',
        type: ProfileType.personal,
        role: EnterpriseRole.owner,
        credentialToken: 'ROOT_DECOY_NODE_01',
        isMfaActive: true,
      ),
      EnterpriseProfile(
        id: 'prof_work',
        nameEn: 'Corporate Operations Workspace',
        nameAr: 'حيازة العمليات والمؤسسة المشتركة',
        type: ProfileType.work,
        role: EnterpriseRole.developer,
        credentialToken: 'CORP_OP_V17_TOKEN',
        isMfaActive: true,
      ),
      EnterpriseProfile(
        id: 'prof_research',
        nameEn: 'Quantum Matrix Research Core',
        nameAr: 'مختبر بحوث الطيف والتحليل الرياضي',
        type: ProfileType.research,
        role: EnterpriseRole.auditor,
        credentialToken: 'RESEARCH_COHER_DDA4',
        isMfaActive: false,
      ),
      EnterpriseProfile(
        id: 'prof_private',
        nameEn: 'Shielded Zero-Knowledge Private Vaults',
        nameAr: 'خزائن كتم الأسرار الخاضعة للمصادقة المزدوجة',
        type: ProfileType.private,
        role: EnterpriseRole.restricted,
        credentialToken: 'ZK_EMERGENCY_OVERRIDE_09',
        isMfaActive: true,
      ),
    ];

    _currentProfile = _profiles.first;

    // 2. Preseed isolated workspaces
    _workspaces = [
      SecureWorkspace(
        id: 'ws_operations',
        profileId: 'prof_work',
        nameEn: 'Operations Shield',
        nameAr: 'درع العمليات الاستراتيجية',
        descriptionEn: 'Confidential corporate files holding network mappings, ciphers, and transaction ledgers.',
        descriptionAr: 'قالب سياق العمليات: ملفات وبيانات الشبكة، سجلات التداول والمخططات المعمارية.',
        templateType: 'Finance',
        isolatedResourceIds: ['vault_01', 'file_accounting_q2', 'file_routing_core'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isSealed: true,
      ),
      SecureWorkspace(
        id: 'ws_quantum_lab',
        profileId: 'prof_research',
        nameEn: 'Spectre Parity R&D Labs',
        nameAr: 'مستودع بحوث تكافؤ الطيف العشوائي',
        descriptionEn: 'Mathematical seed files, entropy reservoirs, and zero-index matrix structures.',
        descriptionAr: 'قالب سياق البحوث: مصفوفات التكافؤ، خزان العشوائية، والمفاتيح الرياضية للتشفير.',
        templateType: 'R&D',
        isolatedResourceIds: ['vault_quantum_spectral', 'note_spectrum_constants', 'key_reserve_01'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isSealed: false,
      ),
      SecureWorkspace(
        id: 'ws_personal_safehouse',
        profileId: 'prof_personal',
        nameEn: 'Sovereign Core Safehouse',
        nameAr: 'الملجأ السيادي الآمن المستقل',
        descriptionEn: 'Personal seed phrases, private journals, and isolated backup media archives.',
        descriptionAr: 'مستوى الفرز الفردي: كلمات المرور العشوائية، المذكرات الخاصة، ونسخ الاحتياط.',
        templateType: 'General',
        isolatedResourceIds: ['personal_vault_01', 'journal_secrets_2026'],
        createdAt: DateTime.now(),
        isSealed: false,
      ),
    ];

    _currentWorkspace = _workspaces.last;

    // 3. Preseed activity records
    final now = DateTime.now();
    _logs = [
      WorkspaceActivityLog(
        id: 'log_seed_1',
        workspaceId: 'ws_operations',
        profileId: 'prof_work',
        detailsEn: 'Applied strict seal state override on Operations Shield.',
        detailsAr: 'تطبيق التجميد والحماية الصارمة لدرع العمليات الاستراتيجية بنجاح.',
        severity: 'critical',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      WorkspaceActivityLog(
        id: 'log_seed_2',
        workspaceId: 'ws_quantum_lab',
        profileId: 'prof_research',
        detailsEn: 'Injected mathematical spectrum parameters inside Spectre Parity workspace.',
        detailsAr: 'ربط أصل رياضي متقدم بنجاح في مستودع بحوث تكافؤ الطيف العشوائي.',
        severity: 'info',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ];

    saveState();
  }
}
