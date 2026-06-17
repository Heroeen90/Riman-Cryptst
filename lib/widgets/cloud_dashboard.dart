import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cloud_bridge.dart';
import '../utils/cloud_service.dart';
import '../utils/archive_service.dart';

class CloudDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const CloudDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<CloudDashboardWidget> createState() => _CloudDashboardWidgetState();
}

class _CloudDashboardWidgetState extends State<CloudDashboardWidget> {
  final CloudService _cloudService = CloudService();
  
  // Tab index: 0 = Sync Hub, 1 = Conflict Engine, 2 = Package Bundler, 3 = Historical logs
  int _activeTab = 0;

  // New package bundler form values
  final TextEditingController _titleEnController = TextEditingController(text: 'E9-Confidential-Operations-Token');
  final TextEditingController _titleArController = TextEditingController(text: 'دفعة-مؤشرات-العمليات-السرية-E9');
  final List<String> _selectedLocalItemIds = [];

  // Manual provider connect email values
  final TextEditingController _emailController = TextEditingController(text: 'external.auditor@riman.gov.sa');

  @override
  void initState() {
    super.initState();
    _cloudService.addListener(_stateListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSecurityLog(
        'Riman Secure Cloud Bridge Initialized',
        'info',
        'Dynamic Zero-Knowledge sync core online. Active Security Index: ${_cloudService.metrics.syncSecurityScore.toStringAsFixed(1)}%'
      );
    });
  }

  @override
  void dispose() {
    _cloudService.removeListener(_stateListener);
    _titleEnController.dispose();
    _titleArController.dispose();
    _emailController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final metrics = _cloudService.metrics;

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // Deepest secure dark background
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBridgeHeader(metrics),
              const SizedBox(height: 8),
              _buildGaugesRow(metrics),
              const SizedBox(height: 12),
              _buildDashboardNavigationTabs(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _resolveActiveTabContents(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBridgeHeader(CloudSyncMetrics metrics) {
    final bool isHighlySecure = metrics.syncSecurityScore >= 80.0;
    
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isHighlySecure ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _locVal('RIMAN SECURE CLOUD BRIDGE (v23.0)', 'سحابة غلاف ريمان المحصنة - الفئة v23.0'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _locVal(
                    'ZERO-KNOWLEDGE METADATA STORAGE BOUNDED',
                    'حدود أمان الروزنامة السحابية صفرية-المعرفة نشطة',
                  ),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Tiny quick action popmenu targeting cloud core settings
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.grey, size: 14),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'reset') {
                _cloudService.resetCloudBridgeDataset();
                widget.onSuccess(
                  _locVal('Cloud sync datasets restored to default factory standards.', 'تم تصفير وإعادة تعيين سجلات الجسر السحابي للقيم الافتراضية.'),
                  'info',
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'reset',
                child: Text(
                  _locVal('Reset Cloud Settings', 'إعادة تعيين سجلات السحابة'),
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGaugesRow(CloudSyncMetrics metrics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.01)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGaugeMetricItem(
            _locVal('Sync Readiness', 'جاهزية المزامنة'),
            metrics.syncReadinessScore,
            const Color(0xFF10B981),
          ),
          _buildGaugeMetricItem(
            _locVal('Backup Integrity', 'سلامة المنسوخات'),
            metrics.backupIntegrityScore,
            const Color(0xFF3B82F6),
          ),
          _buildGaugeMetricItem(
            _locVal('Sync Security', 'أمان الاتصال السحابي'),
            metrics.syncSecurityScore,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeMetricItem(String label, double val, Color activeColor) {
    return Column(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: CustomPaint(
            painter: CloudGaugePainter(
              value: val,
              activeColor: activeColor,
              trackColor: Colors.white.withOpacity(0.05),
            ),
            child: Center(
              child: Text(
                '${val.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDashboardNavigationTabs() {
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.sync, 'label': _locVal('Provider Hub', 'مركز المزودين')},
      {'icon': Icons.gavel, 'label': _locVal('Conflict Engine', 'محرك النزاعات')},
      {'icon': Icons.archive, 'label': _locVal('Package Bundler', 'حزم الإيداع آمن')},
      {'icon': Icons.list_alt, 'label': _locVal('Secure Logs', 'السجلات التاريخية')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _activeTab == idx;
          final tab = tabs[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = idx;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: idx == tabs.length - 1 ? 0 : 2,
                  left: idx == 0 ? 0 : 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.01),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 11,
                      color: isSelected ? const Color(0xFFEF4444) : Colors.grey,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 7.2,
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _resolveActiveTabContents() {
    switch (_activeTab) {
      case 0:
        return _buildSyncHubTab();
      case 1:
        return _buildConflictEngineTab();
      case 2:
        return _buildPackageBundlerTab();
      case 3:
        return _buildHistoricalLogsTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 0: SYNC HUB (PROVIDERS & TIMEFRAME CLOUD SYNC PIPELINE)
  Widget _buildSyncHubTab() {
    final profiles = _cloudService.profiles;
    final isSyncing = _cloudService.isSyncing;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle(_locVal('ACTIVE CRYPTO CLOUD CONNECTIONS', 'الروابط السحابية النشطة مع الكيانات الموثوقة')),
        const SizedBox(height: 6),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profiles.length,
          itemBuilder: (context, idx) {
            final p = profiles[idx];
            IconData provIcon = Icons.cloud;
            String provName = 'Generic Cloud';

            switch (p.provider) {
              case CloudProviderType.googleDrive:
                provIcon = Icons.add_to_drive;
                provName = 'Google Drive';
                break;
              case CloudProviderType.dropbox:
                provIcon = Icons.cloud_done;
                provName = 'Dropbox Secure Cloud';
                break;
              case CloudProviderType.oneDrive:
                provIcon = Icons.cloud_queue;
                provName = 'OneDrive Sealed Bridge';
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.01)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: p.isConnected ? const Color(0xFF10B981).withOpacity(0.12) : Colors.grey.withOpacity(0.1),
                        child: Icon(provIcon, color: p.isConnected ? const Color(0xFF10B981) : Colors.grey, size: 11),
                      ),
                      title: Text(
                        provName,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        p.accountEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 7.5),
                      ),
                      trailing: Text(
                        p.isConnected ? _locVal('CONNECTED', 'متصل') : _locVal('DISCONNECTED', 'غير متصل'),
                        style: TextStyle(
                          color: p.isConnected ? const Color(0xFF10B981) : Colors.grey,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  // Divider line within container bounds
                  Container(height: 0.5, color: Colors.white.withOpacity(0.05)),

                  // Metadata Isolation Switch Panel (Zero-Knowledge Metaphor)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Color(0xFFEF4444), size: 10),
                            const SizedBox(width: 5),
                            Text(
                              _locVal('Zero-Knowledge Isolation Only', 'فرض العزل الصفري للمعرفة فقط'),
                              style: const TextStyle(color: Colors.grey, fontSize: 7.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Switch(
                          value: p.isolatedMetadataOnly,
                          activeColor: const Color(0xFFEF4444),
                          activeTrackColor: const Color(0xFFEF4444).withOpacity(0.2),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.black26,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            _cloudService.toggleZeroKnowledge(p.profileId, val);
                            widget.onSuccess(
                              _locVal(
                                val ? 'Zero-Knowledge parameters strict block active.' : 'Warning: Strict encryption bounds relaxed.',
                                val ? 'تم تشديد معايير الأمان لحجب المعرفة السحابية كلياً.' : 'تحذير: تم توسيع نطاقات الربط بما يسمح بالتحقق الخارجي.',
                              ),
                              val ? 'success' : 'warning'
                            );
                            widget.onSecurityLog(
                              'Profile metadata isolation configuration changed',
                              val ? 'info' : 'warning',
                              'Profile ID: ${p.profileId} - Isolation strict toggle: $val'
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  
                  if (p.isConnected)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _locVal('Last synchronisation:', 'آخر مزامنة ناجحة:'),
                            style: const TextStyle(color: Colors.grey, fontSize: 6.5),
                          ),
                          Text(
                            p.lastSyncTime != null 
                                ? '${p.lastSyncTime!.hour}:${p.lastSyncTime!.minute}:${p.lastSyncTime!.second}'
                                : _locVal('Awaiting sync run', 'انتظار المزامنة الأولى'),
                            style: const TextStyle(color: Colors.white, fontSize: 6.5, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Connect a mock backup target form
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _locVal('AUTHORISE EXTERNAL CLOUD PROVIDER', 'تخويل واعتماد جسر سحابي خارجي جديد'),
                style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5),
                        decoration: const InputDecoration(
                          hintText: 'account@provider.com',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 8),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  // Connect Drive Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.isNotEmpty) {
                        _cloudService.connectProvider(CloudProviderType.googleDrive, email);
                        widget.onSuccess(
                          _locVal('Decentralized Google Drive cluster connected under strict isolation.', 'تم ربط مصفوفة Google Drive تحت سقف العزل صفري المعرفة.'),
                          'success',
                        );
                      }
                    },
                    child: Text(
                      _locVal('+ Drive', '+ غوغل رايف'),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Connect Dropbox button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.isNotEmpty) {
                        _cloudService.connectProvider(CloudProviderType.dropbox, email);
                        widget.onSuccess(
                          _locVal('Sealed Dropbox bridge connected successfully.', 'تم توصيل واعتماد خادوم دروب بوكس كمتلقي معزول.'),
                          'success',
                        );
                      }
                    },
                    child: Text(
                      _locVal('+ Dropbox', '+ دروب بوكس'),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Synchronize engine visual queue
        if (isSyncing)
          _buildActiveSyncingProgressIndicator()
        else
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              widget.onSecurityLog(
                'Manual cross-cloud sync requested',
                'info',
                'Operational trigger issued. Analyzing encrypted metadata packages...'
              );
              _cloudService.triggerSyncExecution((en, ar) {
                widget.onSuccess(_locVal(en, ar), 'success');
                widget.onSecurityLog(
                  'Cloud Bridge Synchronization finalized',
                  'info',
                  'Cross cloud status synchronized safely without key leaks'
                );
              });
            },
            icon: const Icon(Icons.sync_lock, color: Colors.white, size: 14),
            label: Text(
              _locVal('TRIGGER FULL ZERO-KNOWLEDGE CROSS-SYNC', 'تشغيل المزامنة صفرية-المعرفة الكاملة'),
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
        const SizedBox(height: 12),

        _buildCloudSovereigntyDisclaimer(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildActiveSyncingProgressIndicator() {
    final msgEn = _cloudService.syncMessageEn ?? 'Syncing...';
    final msgAr = _cloudService.syncMessageAr ?? 'جاري المزامنة...';
    final progress = _cloudService.syncProgress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locVal('ACTIVE CRYPTO LINK IN FLIGHT', 'قناة الربط التشفيري نشطة حالياً'),
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 7.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _locVal(msgEn, msgAr),
            style: const TextStyle(color: Colors.grey, fontSize: 7.5),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              _cloudService.cancelSync();
              widget.onSuccess(_locVal('Synchronisation cycle aborted.', 'تم إحباط دورة النقل والربط السحابي بقوة يدوية.'), 'warning');
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _locVal('ABORT PIPELINE FORCEALLY', 'إحباط دورة النقل فوراً'),
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCloudSovereigntyDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.01)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFF10B981), size: 12),
              const SizedBox(width: 6),
              Text(
                _locVal('ZERO-KNOWLEDGE INTEGRITY HOOK', 'وحدة التحقق والتكامل المدمج'),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.3),
              children: [
                TextSpan(text: _locVal('This client utilizes local CryptoCore vectors. It complements the local text shield ', 'يعتمد هذا النظام الكامن على مفاتيح تشفير عشوائية محلية. كما يرتبط ترابطاً كاملاً ببرمجة ')),
                const TextSpan(
                  text: '"درع النصوص"',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
                TextSpan(text: _locVal(' to ensure that all metadata is sealed and isolated locally. Your plain-text files never reach external cloud indices.', ' بهدف استغلال طبقة فك وتشفير النصوص محلياً مع ضمان عدم تسريب أي مؤشر أو كود للخارج.')),
              ],
            ),
          )
        ],
      ),
    );
  }

  // TAB 1: CONFLICT RESOLUTION ENGINE
  Widget _buildConflictEngineTab() {
    final conflicts = _cloudService.conflicts;
    final unresolved = conflicts.where((c) => !c.isResolved).toList();
    final resolved = conflicts.where((c) => c.isResolved).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(_locVal('SYNCHRONIZATION CONFLICT RESOLUTIONS', 'وحدة فض وحل النزاعات السحابية النشطة')),
            Text(
              '${unresolved.length} ${_locVal('pending', 'معلق')}',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 7.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(height: 6),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              if (unresolved.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(
                    _locVal('Conflict center clean! All metadata files fully synchronized.', 'مصفوفة فض النزاعات نظيفة بالكامل وجميع الملفات النقل مترابطة.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unresolved.length,
                  itemBuilder: (context, index) {
                    final c = unresolved[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(0x22F59E0B),
                                child: Icon(Icons.warning, color: Color(0xFFF59E0B), size: 10),
                              ),
                              title: Text(
                                _locVal(c.filenameEn, c.filenameAr),
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.grey, fontSize: 7, height: 1.3),
                                  children: [
                                    TextSpan(text: _locVal('Local: ', 'المحلي: ')),
                                    TextSpan(text: '${c.localTime.month}/${c.localTime.day} ${c.localTime.hour}:${c.localTime.minute} ', style: const TextStyle(color: Colors.white)),
                                    TextSpan(text: _locVal('| Cloud: ', ' | السحابي: ')),
                                    TextSpan(text: '${c.cloudTime.month}/${c.cloudTime.day} ${c.cloudTime.hour}:${c.cloudTime.minute}', style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Operational choice triggers inside conflict
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locVal('SELECT MATHEMATICAL RESOLUTION STRATEGY', 'اختر استراتيجية المعالجة الرياضية'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    // Use local
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _cloudService.resolveConflict(c.conflictId, 'use_local');
                                          widget.onSuccess(
                                            _locVal('Conflict resolved: Preferred local physical file.', 'تم فض النزاع بنجاح: تم ترجيح النسخة المحلية النظامية.'),
                                            'success'
                                          );
                                          widget.onSecurityLog(
                                            'Conflict resolved by override',
                                            'info',
                                            'Conflict: ${c.conflictId} - Resolution: Use Local'
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                          ),
                                          child: Text(
                                            _locVal('Use Local', 'الترجيح المحلي'),
                                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Use Cloud
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _cloudService.resolveConflict(c.conflictId, 'use_cloud');
                                          widget.onSuccess(
                                            _locVal('Conflict resolved: Preferred cloud sealed payload.', 'تم حل النزاع: تم ترجيح النسخة السحابية المحفوظة.'),
                                            'success'
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                                          ),
                                          child: Text(
                                            _locVal('Use Cloud', 'الترجيع السحابي'),
                                            style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 7, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Cryptographic merge
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _cloudService.resolveConflict(c.conflictId, 'merge');
                                          widget.onSuccess(
                                            _locVal('Conflict merged: Consolidated dual hash branches.', 'تم دمج وتكامل الفروع وتوحيد توقيع الموترات التالفة بسلامة.'),
                                            'warning'
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                                          ),
                                          child: Text(
                                            _locVal('Merge', 'دمج التواقيع'),
                                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 7, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
              _buildSectionTitle(_locVal('HISTORICAL CONFLICT RESOLUTIONS RECORD', 'الأرشيف التاريخي للقرارات المعتمدة')),
              const SizedBox(height: 6),
              
              if (resolved.isEmpty)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_locVal('No archived resolved conflicts.', 'لا توجد قرارات فض مؤرشفة حالياً.'), style: const TextStyle(color: Colors.grey, fontSize: 8)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resolved.length,
                  itemBuilder: (context, index) {
                    final item = resolved[index];
                    return Card(
                      color: Colors.black26,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locVal(item.filenameEn, item.filenameAr),
                                    style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(
                                    '${_locVal('Mitigation method: ', 'طريقة الحل المطبقة: ')} ${item.chosenResolution?.toUpperCase()}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 7, fontFamily: 'monospace'),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
              if (resolved.isNotEmpty)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _cloudService.clearResolvedConflicts();
                    widget.onSuccess(_locVal('Historical conflict reports dismissed.', 'تم تصفير الأرشيف التاريخي للنزاعات.'), 'info');
                  },
                  child: Text(
                    _locVal('CLEAR HISTORICAL RECORDS', 'تنظيف ومسح السجل التاريخي للقرارات'),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 2: SECURE BACKUP PACKAGE BUNDLER
  Widget _buildPackageBundlerTab() {
    final archives = ArchiveService().archives;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle(_locVal('BUILD ZERO-KNOWLEDGE BACKUP PACKAGE', 'تحزيم وتشفير مجاميع الخلايا الرقمية للتصدير')),
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Package Name English
              Text(
                _locVal('PACKAGE LABEL (ENGLISH)', 'اسم حزمة النسخ الاحتياطي (بالإنكليزية)'),
                style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                height: 32,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: TextField(
                  controller: _titleEnController,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Package Name Arabic
              Text(
                _locVal('PACKAGE LABEL (ARABIC)', 'اسم حزمة النسخ الاحتياطي (بالعربية)'),
                style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                height: 32,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: TextField(
                  controller: _titleArController,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Archive list selection
              Text(
                _locVal('CHOOSE SECURE FILES / THE UNIT VECTOR', 'اختر المحتويات المعزولة للتحزيم المشفر'),
                style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              if (archives.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _locVal('No active standard archives found. Default test nodes will bundle.', 'لم يعثر على أرشيفات محلية. سيتم استخدام حزمة دلالية افتراضية للإنشاء.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: archives.length,
                    itemBuilder: (context, idx) {
                      final item = archives[idx];
                      final isSelected = _selectedLocalItemIds.contains(item.id);

                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        title: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.type.toUpperCase()} | ${item.sizeFormatted}', style: const TextStyle(color: Colors.grey, fontSize: 7)),
                        activeColor: const Color(0xFFEF4444),
                        checkColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedLocalItemIds.add(item.id);
                            } else {
                              _selectedLocalItemIds.remove(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  final enTitle = _titleEnController.text.trim();
                  final arTitle = _titleArController.text.trim();
                  
                  if (enTitle.isEmpty || arTitle.isEmpty) {
                    widget.onSuccess(_locVal('Please fulfill both labels.', 'يرجى كتابة وتدوين عناوين الحزم بكلا اللغتين.'), 'warning');
                    return;
                  }

                  // Bundling packages via local mock verification
                  _cloudService.buildAndRegisterBackupPackage(
                    nameEn: enTitle,
                    nameAr: arTitle,
                    archiveItemIds: List<String>.from(_selectedLocalItemIds),
                    activeKeyId: 'riman_aes_keyroot_quantum_0098',
                  );

                  _selectedLocalItemIds.clear();
                  _titleEnController.text = 'E9-Confidential-Operations-Token';
                  _titleArController.text = 'دفعة-مؤشرات-العمليات-السرية-E9';
                  
                  widget.onSuccess(
                    _locVal('Secure Backup Package built. Transferred to pending cloud queue.', 'تم تفريز وبناء حزمة التصدير وإدراجها ضمن المتتالية السحابية المعلقة.'),
                    'success',
                  );

                  widget.onSecurityLog(
                    'Backup package generated locally',
                    'info',
                    'Package Label: $enTitle - Items count: ${_selectedLocalItemIds.length}'
                  );

                  setState(() {});
                },
                icon: const Icon(Icons.lock, color: Colors.white, size: 12),
                label: Text(
                  _locVal('CREATE SECURED SYNC PACKAGE (CRYPTO)', 'توليد وتشفير حزمة التصدير'),
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // TAB 3: BRIDGE SECURITY AUDIT LOGS
  Widget _buildHistoricalLogsTab() {
    final packages = _cloudService.packages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(_locVal('ENCRYPTED PACKAGES & REPLICATION ARTIFACTS', 'سجل الحزم والمنسوخات المشفرة تاريخياً')),
        const SizedBox(height: 4),

        Expanded(
          child: packages.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Text(_locVal('No integrated packages logged.', 'قائمة وثائق التحزيم السحابي خالية بالكامل.'), style: const TextStyle(color: Colors.grey, fontSize: 9)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: packages.length,
                  itemBuilder: (context, idx) {
                    final item = packages[idx];
                    
                    Color statColor = Colors.grey;
                    IconData statIcon = Icons.query_builder;
                    if (item.status == SyncStatus.success) {
                      statColor = const Color(0xFF10B981);
                      statIcon = Icons.cloud_done;
                    } else if (item.status == SyncStatus.failed) {
                      statColor = const Color(0xFFEF4444);
                      statIcon = Icons.cloud_off;
                    } else if (item.status == SyncStatus.syncing) {
                      statColor = const Color(0xFF3B82F6);
                      statIcon = Icons.sync;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.01)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.packageId,
                                style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontFamily: 'monospace'),
                              ),
                              Row(
                                children: [
                                  Icon(statIcon, color: statColor, size: 8.5),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.status.name.toUpperCase(),
                                    style: TextStyle(color: statColor, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                  )
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locVal(item.nameEn, item.nameAr),
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${item.sizeFormatted} | Fingerprint: ${item.localKeyFingerprint}',
                            style: const TextStyle(color: Colors.white70, fontSize: 7, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local Hash Digest: ${item.encryptedDigest}',
                            style: const TextStyle(color: Colors.grey, fontSize: 6, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.syncedAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${_locVal('Pushed At:', 'تم الرفع:')} ${item.syncedAt!.toLocal().hour}:${item.syncedAt!.toLocal().minute}:${item.syncedAt!.toLocal().second}',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 6.5, fontFamily: 'monospace'),
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

  Widget _buildSectionTitle(String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        val.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// Custom Painter providing top class graphic circles for security gauges
class CloudGaugePainter extends CustomPainter {
  final double value; // 0.0 to 100.0
  final Color activeColor;
  final Color trackColor;

  CloudGaugePainter({
    required this.value,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 3.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final double sweepAngle = 2 * math.pi * (value / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CloudGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
