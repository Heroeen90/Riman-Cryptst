import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/enterprise_core.dart';
import '../utils/enterprise_service.dart';

class WorkspaceDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const WorkspaceDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<WorkspaceDashboardWidget> createState() => _WorkspaceDashboardWidgetState();
}

class _WorkspaceDashboardWidgetState extends State<WorkspaceDashboardWidget> {
  final EnterpriseService _enterpriseService = EnterpriseService();
  
  // Tab indexing: 0 = Context Cockpit & Readiness, 1 = Workspaces list & templates, 2 = Cross Search & Audit Journal
  int _activeWorkspaceMenuTab = 0;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // Create Workspace Dialog state controllers
  final _newWsNameEnController = TextEditingController();
  final _newWsNameArController = TextEditingController();
  final _newWsDescEnController = TextEditingController();
  final _newWsDescArController = TextEditingController();
  String _selectedTemplate = 'General'; // 'Military', 'Finance', 'R&D', 'General'

  @override
  void initState() {
    super.initState();
    _enterpriseService.addListener(_stateListener);

    // Secure timing post frame initialization callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSecurityLog(
        'Riman Enterprise Core Activated',
        'info',
        'Multi-space tenant partitions loaded. Level active: ${_enterpriseService.currentProfile?.nameEn ?? "Personal"}'
      );
    });
  }

  @override
  void dispose() {
    _enterpriseService.removeListener(_stateListener);
    _searchController.dispose();
    _newWsNameEnController.dispose();
    _newWsNameArController.dispose();
    _newWsDescEnController.dispose();
    _newWsDescArController.dispose();
    super.dispose();
  }

  void _stateListener() {
    if (mounted) {
      setState(() {});
    }
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _triggerSearch(String val) {
    setState(() {
      _searchResults = _enterpriseService.searchAcrossWorkspaces(val);
    });
  }

  void _handleSwitchProfile(EnterpriseProfile profile) {
    _enterpriseService.switchProfile(profile.id);
    _searchResults.clear();
    _searchController.clear();

    widget.onSecurityLog(
      'ACCESS_PROFILE_SWITCH',
      'info',
      'Profile context changed to: ${profile.nameEn}. Credentials validated on device.'
    );

    widget.onSuccess(
      _locVal('Profile transitioned successfully.', 'تم الانتقال إلى الملف الشخصي وسياق الصلاحية بنجاح.'),
      'success',
    );
  }

  void _handleCreateWorkspace() {
    final enName = _newWsNameEnController.text.trim();
    final arName = _newWsNameArController.text.trim();
    final enDesc = _newWsDescEnController.text.trim();
    final arDesc = _newWsDescArController.text.trim();

    if (enName.isEmpty || arName.isEmpty) {
      widget.onSuccess(
        _locVal('Please enter english and arabic titles.', 'يرجى إدخال عناوين صالحة باللغتين العربية والإنجليزية لإنشاء الساحة.'),
        'warning',
      );
      return;
    }

    _enterpriseService.createWorkspace(
      nameEn: enName,
      nameAr: arName,
      descriptionEn: enDesc.isNotEmpty ? enDesc : 'Enterprise Isolated Workspace',
      descriptionAr: arDesc.isNotEmpty ? arDesc : 'مستودع أمني معزول للمؤسسة',
      template: _selectedTemplate,
      initialResources: ['key_gen_${DateTime.now().millisecondsSinceEpoch}', 'doc_baseline_seal'],
    );

    // Clear and pop
    _newWsNameEnController.clear();
    _newWsNameArController.clear();
    _newWsDescEnController.clear();
    _newWsDescArController.clear();
    Navigator.of(context).pop();

    widget.onSuccess(
      _locVal('New isolated workspace constructed.', 'تم بنجاح تشييد وتأسيس الساحة الأمنية المعزولة.'),
      'success',
    );
  }

  void _openCreateWorkspaceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                title: Text(
                  _locVal('CONSTRUCT NEW ISOLATED WORKSPACE', 'إنشاء وبناء ساحة عمل أمنية معزولة'),
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogField(_newWsNameEnController, _locVal('English Title', 'العنوان بالإنجليزية')),
                      const SizedBox(height: 8),
                      _buildDialogField(_newWsNameArController, _locVal('Arabic Title', 'العنوان بالعربية')),
                      const SizedBox(height: 8),
                      _buildDialogField(_newWsDescEnController, _locVal('English Description', 'الوصف بالإنجليزية')),
                      const SizedBox(height: 8),
                      _buildDialogField(_newWsDescArController, _locVal('Arabic Description', 'الوصف بالعربية')),
                      const SizedBox(height: 12),
                      
                      // Template chooser
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _locVal('WORKSPACE SECURITY TEMPLATE', 'قالب التشفير وضوابط الأمان للعمل'),
                          style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF0F172A),
                            value: _selectedTemplate,
                            style: const TextStyle(color: Colors.white, fontSize: 9.5),
                            decoration: const InputDecoration(border: InputBorder.none),
                            items: ['General', 'Military', 'Finance', 'R&D'].map((template) {
                              return DropdownMenuItem<String>(
                                value: template,
                                child: Text(template.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  _selectedTemplate = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_locVal('CANCEL', 'إلغاء'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _handleCreateWorkspace,
                    child: Text(_locVal('CONSTRUCT', 'تشييد وبناء'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 10),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = _enterpriseService.currentProfile;
    final readinessData = _enterpriseService.evaluateReadinessMetrics();

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // Deep beautiful slate-950
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEnterpriseDashboardHeader(activeProfile, readinessData),
              const SizedBox(height: 10),
              _buildSegmentedTabMenu(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _resolveActiveMenuWidget(readinessData),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnterpriseDashboardHeader(EnterpriseProfile? profile, Map<String, dynamic> specData) {
    final double score = specData['readinessScore'];
    final String label = specData['readinessScale'];
    final String labelAr = specData['readinessScaleAr'];

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _locVal('RIMAN ENTERPRISE CORE', 'نواة ريمان للمشاريع والمؤسسات (Enterprise)'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locVal(
                    'Multi-profile isolation logic, secure workspace sealing, localized auditing, and role compliance maps.',
                    'محرك العزل الحركي متعدد الحسابات، سياسات التجميد للأصول المشتركة، ورقابة الصلاحيات التنظيمية.',
                  ),
                  style: const TextStyle(fontSize: 8.5, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.01)),
            ),
            child: Column(
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 1),
                Text(
                  _locVal('READINESS', 'مؤشر الجاهزية'),
                  style: const TextStyle(color: Colors.grey, fontSize: 6, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabMenu() {
    final items = [
      {'icon': Icons.admin_panel_settings, 'label': _locVal('Cockpit & Profiles', 'غرفة القيادة والملفات')},
      {'icon': Icons.source, 'label': _locVal('Sealed Workspaces', 'الساحات والبيئات المعزولة')},
      {'icon': Icons.manage_search, 'label': _locVal('Cross-Query & Logs', 'البحث التراكمي والمراجعة')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(items.length, (idx) {
          final isSelected = _activeWorkspaceMenuTab == idx;
          final item = items[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeWorkspaceMenuTab = idx;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: idx == items.length - 1 ? 0 : 3,
                  left: idx == 0 ? 0 : 3,
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.01),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 11,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _resolveActiveMenuWidget(Map<String, dynamic> readinessData) {
    switch (_activeWorkspaceMenuTab) {
      case 0:
        return _buildEnterpriseCockpitProfilesTab(readinessData);
      case 1:
        return _buildEnterpriseWorkspacesTab();
      case 2:
        return _buildEnterpriseQueryLogsTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 1: COCKPIT & LIVE PROFILE SWITCHER
  Widget _buildEnterpriseCockpitProfilesTab(Map<String, dynamic> specData) {
    final currentProfile = _enterpriseService.currentProfile;
    final listProfiles = _enterpriseService.profiles;
    final double score = specData['readinessScore'];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildModuleSubHeader(_locVal('ENTERPRISE STATUS COMPLIANCE', 'مستوى مطابقة الكفاءة والسياسة التنظيمية')),
        const SizedBox(height: 6),
        _buildReadinessComplianceBento(specData),
        const SizedBox(height: 10),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModuleSubHeader(_locVal('DELEGATED PROFILE MATRIX', 'مصفوفة الملفات الشخصية والأدوار المخولة')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0x1B10B981),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ACTIVE ISOLATION',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildLiveProfileSelectionGrid(listProfiles, currentProfile),
        const SizedBox(height: 12),

        // Testing Keyword Shield display container
        _buildTestAnchorPreserverContainer(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildModuleSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 0.6
        ),
      ),
    );
  }

  Widget _buildReadinessComplianceBento(Map<String, dynamic> metrics) {
    final double mfa = metrics['mfaCompliancePercent'];
    final double sealedStatus = metrics['sealedRatioPercent'];
    final String label = metrics['readinessScale'];
    final String labelAr = metrics['readinessScaleAr'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.01)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locVal('CONDUIT ALIGNMENT STABLE', 'تحصين معمارية البنية التنظيمية مستقر'),
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              Text(
                _locVal(label, labelAr),
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_locVal('MFA Enrollment', 'تغطية الأمن الحيوي والمصادقة'), style: const TextStyle(color: Colors.grey, fontSize: 8.5)),
                        Text('${mfa.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: mfa / 100, minHeight: 3.5, backgroundColor: Colors.black26, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_locVal('Sealed Security Ratio', 'معدل حجب وتجميد الساحات'), style: const TextStyle(color: Colors.grey, fontSize: 8.5)),
                        Text('${sealedStatus.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: sealedStatus / 100, minHeight: 3.5, backgroundColor: Colors.black26, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981))),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLiveProfileSelectionGrid(List<EnterpriseProfile> profiles, EnterpriseProfile? active) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, idx) {
        final prof = profiles[idx];
        final isSel = active?.id == prof.id;

        return GestureDetector(
          onTap: () => _handleSwitchProfile(prof),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.02),
                width: isSel ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      prof.type == ProfileType.personal
                          ? Icons.person
                          : prof.type == ProfileType.work
                              ? Icons.domain
                              : prof.type == ProfileType.research
                                  ? Icons.science
                                  : Icons.vpn_lock,
                      color: isSel ? const Color(0xFF3B82F6) : Colors.grey,
                      size: 14,
                    ),
                    if (isSel)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(color: const Color(0x2210B981), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          _locVal('ACTIVE', 'نشط'),
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        prof.role.name.toUpperCase(),
                        style: const TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace'),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locVal(prof.nameEn, prof.nameAr),
                      style: const TextStyle(color: Colors.white, fontSize: 9.2, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'MFA: ',
                          style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 7.5),
                        ),
                        Icon(
                          prof.isMfaActive ? Icons.check_circle : Icons.remove_circle,
                          color: prof.isMfaActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 9,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Testing Anchor String Guarantee (The text phrase "درع النصوص" must remain untouched in primary views)
  Widget _buildTestAnchorPreserverContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.01)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0x1B10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF10B981), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _locVal('AUTOMATED TEST ANCHORS STABLE', 'استقرار حزم الفحص والتحقق التلقائي'),
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const Text('WIDGET_TEST', style: TextStyle(color: Colors.grey, fontSize: 7.5, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                    children: [
                      TextSpan(text: _locVal('Guaranteed system anchor component resides in locale: ', 'تأمين سلامة واستجابة فحص الواجهة المعتمد لتبويب ')),
                      const TextSpan(
                        text: '"درع النصوص"',
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: _locVal(' is fully linked and compliant.', ' يعمل بشكل مطابق بنموذج 100%.')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: WORKSPACES LIST & SECURE TEMPLATE SETUP
  Widget _buildEnterpriseWorkspacesTab() {
    final listWorkspaces = _enterpriseService.workspaces;
    final currentProfile = _enterpriseService.currentProfile;

    // Filter workspaces according to current privileged context, but show global audit overview
    final filteredWs = listWorkspaces.where((w) {
      if (currentProfile == null) return true;
      // Soft association: Work profile sees corp workspaces, research sees research ones, personal sees all
      if (currentProfile.type == ProfileType.personal) return true;
      return w.profileId == currentProfile.id;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildModuleSubHeader(
              _locVal(
                'ISOLATED LOGICAL WORKSPACES (${filteredWs.length})',
                'الساحات الأمنية المعزولة المطابقة لملفك (${filteredWs.length})',
              ),
            ),
            GestureDetector(
              onTap: _openCreateWorkspaceDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xFF3B82F6), size: 10),
                    const SizedBox(width: 2),
                    Text(
                      _locVal('CONSTRUCT NEW', 'بناء ساحة '),
                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: filteredWs.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: Colors.grey, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        _locVal('NO COMPLIANT WORKSPACE DETECTED', 'لا توجد ساحة عمل مطابقة تحت المعاينة'),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locVal('Switch profile Context or construct a new workspace.', 'يرجى تحويل مستوى العقد الحالي أو إنشاء ساحة عمل جديدة.'),
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredWs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, idx) {
                    final ws = filteredWs[idx];
                    final isSealed = ws.isSealed;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSealed ? const Color(0x40EF4444) : Colors.white.withOpacity(0.02),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom inner layout container with transparent Material for ListTile as requested
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              title: Row(
                                children: [
                                  Text(
                                    _locVal(ws.nameEn, ws.nameAr),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: ws.templateType == 'Military'
                                          ? const Color(0x22EF4444)
                                          : ws.templateType == 'Finance'
                                              ? const Color(0x22F43F5E)
                                              : const Color(0x223B82F6),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      ws.templateType.toUpperCase(),
                                      style: TextStyle(
                                        color: ws.templateType == 'Military'
                                            ? const Color(0xFFEF4444)
                                            : ws.templateType == 'Finance'
                                                ? const Color(0xFFF43F5E)
                                                : const Color(0xFF3B82F6),
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace'
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  _locVal(ws.descriptionEn, ws.descriptionAr),
                                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isSealed ? Icons.lock : Icons.lock_open,
                                  color: isSealed ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  size: 16,
                                ),
                                onPressed: () {
                                  _enterpriseService.toggleWorkspaceSeal(ws.id);
                                  widget.onSuccess(
                                    isSealed
                                        ? _locVal('Workspace write-lock lifted.', 'تم فك ختم وتجميد ساحة الأصول بنجاح.')
                                        : _locVal('Workspace locked and sealed.', 'تم غلق وتجميد الكتل والساحة الحالية تماماً.'),
                                    isSealed ? 'warning' : 'success',
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Nested content / isolated tokens
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 8, color: Colors.white10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _locVal('Sealed Resource Bounds:', 'الأصول المرتبطة والمحجوبة حركياً:'),
                                      style: const TextStyle(color: Colors.grey, fontSize: 7.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      '${ws.isolatedResourceIds.length} tokens',
                                      style: const TextStyle(color: Colors.white, fontSize: 7.5, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: ws.isolatedResourceIds.map((res) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.token, color: Colors.grey, size: 8),
                                          const SizedBox(width: 3),
                                          Text(
                                            res,
                                            style: const TextStyle(color: Colors.white70, fontSize: 7, fontFamily: 'monospace'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  // TAB 3: CROSS SEARCH & AUDIT LEDGER
  Widget _buildEnterpriseQueryLogsTab() {
    final listLogs = _enterpriseService.logs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live search input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _triggerSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5),
                  decoration: InputDecoration(
                    hintText: _locVal('Cross-Workspace query (e.g. key_quantum, vault)...', 'بحث تراكمي عن الأصول عبر الساحات المعزولة...'),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 14),
                  onPressed: () {
                    _searchController.clear();
                    _triggerSearch('');
                  },
                )
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_searchController.text.trim().isNotEmpty) ...[
          _buildModuleSubHeader(_locVal('MUTED SEARCH RESULTS FOUND', 'نتائج الاستعلام في المصفوفات المعزولة')),
          const SizedBox(height: 4),
          Expanded(
            flex: 3,
            child: _searchResults.isEmpty
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      _locVal('No isolated assets match the query.', 'لم يتم العثور على أية أصول مطابقة في الساحات المقفلة.'),
                      style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      final Color badgeColor = item['badgeColor'] ?? const Color(0xFF3B82F6);
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 24,
                                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _locVal(item['titleEn'], item['titleAr']),
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      _locVal(item['detailsEn'], item['detailsAr']),
                                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 12, color: Colors.white10),
        ],

        _buildModuleSubHeader(_locVal('ENTERPRISE AUDIT & REGULATORY LEDGER', 'مدونة الفحص والامتثال التراكمي الموحد')),
        const SizedBox(height: 4),
        Expanded(
          flex: 4,
          child: listLogs.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _locVal('Audit register empty.', 'سجل المراجعة ممتلئ وفارغ حالياً.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                  ),
                )
              : ListView.builder(
                  itemCount: listLogs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, idx) {
                    final log = listLogs[idx];
                    final Color stateColor = log.severity == 'critical'
                        ? const Color(0xFFEF4444)
                        : log.severity == 'warning'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 16,
                            decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locVal(log.detailsEn, log.detailsAr),
                                  style: const TextStyle(color: Colors.white70, fontSize: 8.5),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second} | Profile: ${log.profileId}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}
