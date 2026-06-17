import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/forensics.dart';
import '../utils/forensics_service.dart';

class ForensicsDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const ForensicsDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<ForensicsDashboardWidget> createState() => _ForensicsDashboardWidgetState();
}

class _ForensicsDashboardWidgetState extends State<ForensicsDashboardWidget> {
  final ForensicsService _forensicsService = ForensicsService();
  
  // Dashboard view tab: 0 = Integrity Monitor; 1 = Security Actions/Tampers; 2 = Verification Timeline
  int _activeTab = 0;
  
  // Selected resource for deep metadata analysis inspector
  ForensicFileIntegrity? _selectedInspectorItem;

  @override
  void initState() {
    super.initState();
    _forensicsService.addListener(_onStateChange);
    
    // STRICT FLUTTER TIMING RULE: Wrap post frame callbacks for init triggers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forensicsService.syncActiveResources();
      _forensicsService.verifyIntegrityAll();
      widget.onSecurityLog(
        'Forensics Suite Initialized',
        'info',
        'SHA-512 comparison engines and byte-parity modules loaded into kernel space successfully.'
      );
    });
  }

  @override
  void dispose() {
    _forensicsService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _triggerAuditSweep() {
    final success = _forensicsService.verifyIntegrityAll();
    
    widget.onSecurityLog(
      'System Audit Decalibrated Sweep',
      success ? 'success' : 'crisis',
      'Completed integrity inspection of ${_forensicsService.integrities.length} nodes. State: ${success ? "SAFE" : "TAMPERED"}.'
    );

    if (success) {
      widget.onSuccess(
        _locVal('Integrity check: 100% compliant. Zero tamper vectors.', 'فحص السلامة: مطابق بنسبة 100%. خالي تمامًا من الانحراف التكويني.'),
        'success',
      );
    } else {
      widget.onSuccess(
        _locVal('Integrity drift detected! Tamper alerts raised.', 'تحذير: تم الكشف عن انحراف في التواقيع المشفرة!'),
        'warning',
      );
    }
  }

  void _triggerSyncLedger() {
    _forensicsService.syncActiveResources();
    widget.onSuccess(
      _locVal('Active ledger synchronized with forensic block records.', 'تم مزامنة المستودع الفعلي وعناصر ترابط التواقيع بنجاح.'),
      'success',
    );
  }

  void _injectCorruption(ForensicFileIntegrity item) {
    _forensicsService.injectTamperSimulation(
      item.resourceId,
      customDetails: _locVal('Simulated byte mutation on cryptographic parity indexes.', 'طفرة مشفرة محاكاة في توازن مؤشرات التوقيع والتحكم.')
    );
    
    widget.onSecurityLog(
      'Tamper Simulation Injected',
      'warning',
      'Simulated bitrot corruption committed on "${item.resourceName}" integrity block.'
    );

    widget.onSuccess(
      _locVal('Simulation success. Node corrupted.', 'تم محاكاة التخريب بنجاح. أثيرت أجهزة التنبيه الحمراء!'),
      'warning',
    );
  }

  void _repairIntegrity(ForensicFileIntegrity item) {
    _forensicsService.repairResource(item.resourceId);
    
    widget.onSecurityLog(
      'Node Signature Reset',
      'info',
      'SHA-512 signatures & bitwise alignment fully restored on "${item.resourceName}".'
    );

    widget.onSuccess(
      _locVal('Cryptographic recalibration completed. Parity restored.', 'تمت إعادة المعايرة بنجاح. استقرت تواقيع الملف الآن.'),
      'success',
    );

    if (_selectedInspectorItem?.id == item.id) {
      setState(() {
        _selectedInspectorItem = _forensicsService.integrities.firstWhere(
          (x) => x.id == item.id,
          orElse: () => item,
        );
      });
    }
  }

  void _clearAllEvents() {
    _forensicsService.clearTamperLogs();
    widget.onSuccess(
      _locVal('Tamper history purged and system scores recalibrated.', 'تم تصفير سجلات التحذيرات وإعادة معايرة معاملات السلامة.'),
      'success',
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90.0) return const Color(0xFF10B981); // Emerald
    if (score >= 60.0) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final double score = _forensicsService.systemIntegrityScore;
    final int activeAlerts = _forensicsService.tamperEvents.where((ev) => !ev.isResolved).length;

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // slate-950 deep dark
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModernHeader(),
              const SizedBox(height: 12),
              _buildSecurityStatusDeck(score, activeAlerts),
              const SizedBox(height: 12),
              _buildFunctionalControlRow(),
              const SizedBox(height: 12),
              _buildTabNavigationBar(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCurrentTabContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate-900
            Color(0xFF020617), // Slate-950
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 0.9],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _locVal('RIMAN FORENSICS LAB', 'مختبر الأدلة الجنائية المشفر للتحقق ريمان'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'v13.0',
                        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locVal(
                    'Real-time cryptographic audit trail, SHA-512 byte sanity, tamper notifications, and signature preservation.',
                    'مراقبة فورية للكتل والتغيرات الفيزيائية بترميز SHA-512، وكشف عمليات تلاعب البيانات بدقة متناهية.',
                  ),
                  style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusDeck(double score, int activeAlerts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // GAUGER CARD
          Expanded(
            flex: 5,
            child: Container(
              height: 105,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CustomPaint(
                      painter: ForensicHealthGaugePainter(
                        score: score,
                        trackColor: const Color(0x331E293B),
                        fillColor: _getScoreColor(score),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${score.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _locVal('INTEGRITY', 'سلامة البنية'),
                              style: const TextStyle(color: Colors.grey, fontSize: 6, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locVal('SYSTEM CRYP-HEALTH SCORE', 'معدل الترابط البياني والتوافقي'),
                          style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          score >= 95.0
                              ? _locVal('Optimal Security Guard', 'أقصى مؤشرات الحماية والحيود صفر')
                              : score >= 70.0
                                  ? _locVal('Minor Sign Drift Detected', 'رصد انحراف جزئي تكميلي')
                                  : _locVal('CRITICAL VIOLATION WARNING', 'تصلب كتل أمني خطر للغاية!'),
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locVal(
                            'Parity checksum calculations of vaults, cold logs and matrix layers.',
                            'تدقيق خوارزميات ريمان والتواقيع المرجعية للذواكر الموزعة والملفات.',
                          ),
                          style: const TextStyle(color: Colors.grey, fontSize: 7, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ALERT DECK COUNTERS
          Expanded(
            flex: 3,
            child: Container(
              height: 105,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activeAlerts > 0 ? Icons.error_outline : Icons.gpp_good,
                    color: activeAlerts > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeAlerts.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      color: activeAlerts > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _locVal('ACTIVE ALERTS', 'التهديدات النشطة'),
                    style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (activeAlerts > 0)
                    GestureDetector(
                      onTap: _clearAllEvents,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0x22EF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _locVal('PURGE SYSTEM', 'تطهير وإخلاء'),
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 6.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Text(
                      _locVal('Shield Locked', 'الدروع محكمة'),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 6.5, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionalControlRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Row(
          children: [
            // Verify and Sweep
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ).copyWith(
                  elevation: WidgetStateProperty.all(0),
                ),
                onPressed: _triggerAuditSweep,
                icon: const Icon(Icons.saved_search, size: 14, color: Colors.black),
                label: Text(
                  _locVal('VERIFY SIGNATURES', 'فحص ومطابقة التواقيع'),
                  style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Sync active elements
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ).copyWith(
                  elevation: WidgetStateProperty.all(0),
                ),
                onPressed: _triggerSyncLedger,
                icon: const Icon(Icons.sync_alt, size: 14, color: Colors.white),
                label: Text(
                  _locVal('SYNC SYSTEM DIRECTORY', 'مزامنة دليل الأصول'),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigationBar() {
    final items = [
      {'icon': Icons.fingerprint, 'label': _locVal('Integrity Monitor Nodes', 'بصمات التواقيع المشفرة')},
      {'icon': Icons.add_alert, 'label': _locVal('Security Evidence Center', 'مركز الأدلة والتخريب المفتعل')},
      {'icon': Icons.history_edu, 'label': _locVal('Investigation Timeline', 'تتبع تاريخ التدقيق الميداني')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(items.length, (idx) {
          final isSelected = _activeTab == idx;
          final item = items[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = idx;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: idx == items.length - 1 ? 0 : 4,
                  left: idx == 0 ? 0 : 4,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.01),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 13,
                      color: isSelected ? const Color(0xFF10B981) : Colors.grey,
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

  Widget _buildCurrentTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildIntegrityMonitorTab();
      case 1:
        return _buildSecurityEvidenceTab();
      case 2:
        return _buildVerificationTimelineTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 1: INTEGRITY MONITOR (List directory blocks, with inspector triggers and mock simulations)
  Widget _buildIntegrityMonitorTab() {
    final list = _forensicsService.integrities;
    if (list.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _locVal('No active nodes registered. Trigger Sync directory.', 'لا توجد أصول مراقبة في السجل الحالي. انقر مزامنة أولًا.'),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _locVal('ACTIVE ASSETS BLOCK FINGERPRINTS', 'دليل تواقيع ورموز سلامة الأصول المعتمدة'),
              style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  _locVal('Automatic Watchdog Daemon', 'كلب الحراسة التلقائي الذكي'),
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _forensicsService.isAutoWatchdogActive,
                  activeColor: const Color(0xFF10B981),
                  inactiveTrackColor: Colors.black38,
                  onChanged: (val) {
                    setState(() {
                      _forensicsService.toggleAutoWatchdog(val);
                    });
                    widget.onSuccess(
                      val
                          ? _locVal('Forensics Watchdog activated in background.', 'تم تشغيل برنامج الحراسة وحساب التموجات الخلفية.')
                          : _locVal('Watchdog disabled. Manual controls only.', 'تم تعليق الحارس التلقائي لفحص التغيرات.'),
                      'success',
                    );
                  },
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final item = list[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isTampered ? const Color(0xFFEF4444).withOpacity(0.4) : Colors.white.withOpacity(0.01),
                  ),
                ),
                // ListTile requires wrap in transparent Material inside colored containers
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: item.isTampered 
                          ? const Color(0x33EF4444) 
                          : const Color(0x1A10B981),
                      radius: 16,
                      child: Icon(
                        _getResourceIcon(item.resourceType),
                        color: item.isTampered ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 14,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.resourceName,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.isTampered 
                                ? const Color(0x33EF4444) 
                                : const Color(0x2210B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isTampered 
                                ? _locVal('TAMPERED / FAILED', 'انحراف / فشل المطابقة') 
                                : _locVal('VERIFIED', 'مطابق سليم'),
                            style: TextStyle(
                              color: item.isTampered ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHA-512: ${item.sha512Hash.substring(0, 32)}...',
                            style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${item.resourceType.toUpperCase()} | ',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_locVal("Registered:", "تاريخ المزامنة:")} ${item.registeredAt.hour}:${item.registeredAt.minute}',
                                style: const TextStyle(color: Colors.grey, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                          onPressed: () => _openInspectorModal(item),
                          tooltip: _locVal('Inspect Metadata', 'تفاصيل التواقيع والخصائص'),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.tune, color: Colors.grey, size: 16),
                          dropdownColor: const Color(0xFF0F172A),
                          onSelected: (val) {
                            if (val == 'corrupt') {
                              _injectCorruption(item);
                            } else if (val == 'repair') {
                              _repairIntegrity(item);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'corrupt',
                              enabled: !item.isTampered,
                              child: Text(
                                _locVal('Inject Mutation (Simulate)', 'حقن تخريب محاكاة للتجربة'),
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9.5),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'repair',
                              enabled: item.isTampered,
                              child: Text(
                                _locVal('Restore & Recalibrate Sig', 'إعادة معايرة واصلاح التوقيع'),
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 2: SECURITY EVIDENCE CENTER (Lists detailed unresolved/resolved Tamper Alert Incidents)
  Widget _buildSecurityEvidenceTab() {
    final list = _forensicsService.tamperEvents;
    if (list.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_good, color: Color(0xFF10B981), size: 36),
            const SizedBox(height: 12),
            Text(
              _locVal('SYSTEM RECORD UNBLEMISHED', 'سجل أمان نقي وخال من الاختراقات'),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _locVal('Zero malicious alterations or parity misalignments detected.', 'لم يسجل النظام أي تغيرات غير مصرح بها أو انحرافات توازن حتى الآن.'),
              style: const TextStyle(color: Colors.grey, fontSize: 8.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _locVal('TAMPER DETECTIONS AND AUDIT EVIDENCE log', 'سجل البراهين وحالات تلاعب الملفات المضبوطة'),
              style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _clearAllEvents,
              child: Text(
                _locVal('Reset History', 'تصفير الحالات'),
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final ev = list[idx];
              final Color sevColor = ev.severity == 'Critical' 
                  ? const Color(0xFFEF4444) 
                  : ev.severity == 'High' 
                      ? const Color(0xFFF59E0B) 
                      : const Color(0xFF3B82F6);

              return Card(
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: ev.isResolved ? Colors.white.withOpacity(0.01) : sevColor.withOpacity(0.3)
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                ev.isResolved ? Icons.check_circle_outline : Icons.warning_amber,
                                color: ev.isResolved ? const Color(0xFF10B981) : sevColor,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ev.resourceName,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ev.isResolved 
                                  ? const Color(0x2210B981) 
                                  : sevColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ev.isResolved 
                                  ? _locVal('RESOLVED', 'تم إصلاح الخلل') 
                                  : ev.severity.toUpperCase(),
                              style: TextStyle(
                                color: ev.isResolved ? const Color(0xFF10B981) : sevColor,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ev.details,
                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_locVal("Time of incident:", "توقيت ورصد الحادثة:")} ${ev.timestamp.hour}:${ev.timestamp.minute}:${ev.timestamp.second}',
                            style: const TextStyle(color: Colors.grey, fontSize: 8),
                          ),
                          if (!ev.isResolved)
                            GestureDetector(
                              onTap: () {
                                final target = _forensicsService.integrities.firstWhere(
                                  (element) => element.resourceId == ev.resourceId
                                );
                                _repairIntegrity(target);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _locVal('REBUILD STATE', 'إعادة بناء التوقيع'),
                                  style: const TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (ev.isResolved && ev.resolutionNotes.isNotEmpty) ...[
                        const Divider(height: 12, color: Colors.white10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.edit_note, color: Color(0xFF10B981), size: 11),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_locVal("Resolution notes:", "خطوات ومعالجة الترابط:")} ${ev.resolutionNotes}',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, height: 1.25),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 3: VERIFICATION INVESTIGATION TIMELINE
  Widget _buildVerificationTimelineTab() {
    final list = _forensicsService.auditLogs;
    if (list.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          _locVal('No audit events logged.', 'لا توجد أنشطة تدقيق أو خطوات فحص سابقة.'),
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _locVal('HISTORICAL SYSTEM AUDIT TRAIL', 'مسار تدقيق النظام والتحقق المرجعي الفوري'),
          style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final log = list[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.01)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getTimelineDotColor(log.action),
                        shape: BoxShape.circle,
                      ),
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
                                log.action.toUpperCase(),
                                style: TextStyle(
                                  color: _getTimelineDotColor(log.action),
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 8, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.details,
                            style: const TextStyle(color: Colors.white70, fontSize: 8.5, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inspector: ${log.inspector}',
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
        ),
      ],
    );
  }

  Color _getTimelineDotColor(String action) {
    if (action.contains('ALERT') || action.contains('TAMPER')) return const Color(0xFFEF4444);
    if (action.contains('REPAIR') || action.contains('SUCCESS')) return const Color(0xFF10B981);
    if (action.contains('SYNC') || action.contains('LEDGER')) return const Color(0xFF3B82F6);
    return Colors.grey;
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'vault':
        return Icons.folder_zip;
      case 'file':
        return Icons.insert_drive_file;
      case 'note':
        return Icons.note_alt;
      case 'journal':
        return Icons.book;
      case 'archive':
        return Icons.inventory;
      default:
        return Icons.lock;
    }
  }

  void _openInspectorModal(ForensicFileIntegrity item) {
    setState(() {
      _selectedInspectorItem = item;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeItem = _forensicsService.integrities.firstWhere(
              (x) => x.id == item.id,
              orElse: () => item,
            );
            
            return Directionality(
              textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(_getResourceIcon(activeItem.resourceType), color: const Color(0xFF10B981), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeItem.resourceName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: Colors.white10),
                      
                      // Hash values boxes
                      _buildInspectorField('RESOURCE ID', activeItem.resourceId),
                      _buildInspectorField('ASSET NODE LEVEL', activeItem.resourceType.toUpperCase()),
                      _buildInspectorField('REGISTRATION REGISTER', activeItem.registeredAt.toUtc().toIso8601String()),
                      _buildInspectorField('LAST SANITY INSPECTION', activeItem.lastCheckedAt.toUtc().toIso8601String()),
                      
                      const SizedBox(height: 8),
                      // SHA-256
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED SHA-256 SIGNATURE',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 3),
                            SelectableText(
                              activeItem.sha256Hash,
                              style: const TextStyle(color: Colors.grey, fontSize: 8.5, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // SHA-512
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED SHA-512 SIGNATURE',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 3),
                            SelectableText(
                              activeItem.sha512Hash,
                              style: const TextStyle(color: Colors.grey, fontSize: 8.5, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Structured original JSON metadata inspector representation
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'PARITY BLOCK METADATA JSON',
                              style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              activeItem.originalMetadata,
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (activeItem.isTampered)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () {
                                _repairIntegrity(activeItem);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.build, size: 12),
                              label: Text(_locVal('Recalibrate Block Signatures', 'إعادة معايرة واصلاح البصمة'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () {
                                _injectCorruption(activeItem);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.bug_report, size: 12),
                              label: Text(_locVal('Inject Simulated Corruption', 'حقن عشوائية وانحراف البصمة'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildInspectorField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Radar-style circular dashboard guage painter
class ForensicHealthGaugePainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color fillColor;

  ForensicHealthGaugePainter({
    required this.score,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 2.5, trackPaint);

    double sweepAngle = (score / 100.0) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2.5),
      -math.pi / 2, // Start from the top
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ForensicHealthGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}
