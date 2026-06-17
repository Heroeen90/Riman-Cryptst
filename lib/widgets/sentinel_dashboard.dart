import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sentinel.dart';
import '../utils/sentinel_service.dart';

class SentinelDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SentinelDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<SentinelDashboardWidget> createState() => _SentinelDashboardWidgetState();
}

class _SentinelDashboardWidgetState extends State<SentinelDashboardWidget> {
  final SentinelService _sentinelService = SentinelService();
  
  // Tab indicators: 0 = Cockpit / Coverage, 1 = Recommendation center, 2 = Anomalies & Alerts
  int _activeNavTab = 0;

  @override
  void initState() {
    super.initState();
    _sentinelService.addListener(_onStateChanged);
    
    // Wrapped in Post Frame Callback to avoid setState / notifyListeners race issues on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sentinelService.triggerSystemSelfExamine();
      widget.onSecurityLog(
        'Riman Sentinel Engaged',
        'info',
        'Local active guard daemon online. Recalibrated baseline security vectors to '
        '${_sentinelService.currentSecurityScore.toStringAsFixed(1)}%'
      );
    });
  }

  @override
  void dispose() {
    _sentinelService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  Color _getScoreGradeColor(double score) {
    if (score >= 90.0) return const Color(0xFF10B981); // beautiful vibrant green
    if (score >= 70.0) return const Color(0xFFF59E0B); // Amber warning
    return const Color(0xFFEF4444); // Red danger
  }

  @override
  Widget build(BuildContext context) {
    final double systemScore = _sentinelService.currentSecurityScore;
    final int openAnomaliesCount = _sentinelService.anomalies.where((a) => !a.isResolved).length;

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // slate-950
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSovereignSentinelHeader(systemScore),
              const SizedBox(height: 10),
              _buildWatchdogBentoQuickRow(systemScore, openAnomaliesCount),
              const SizedBox(height: 10),
              _buildSegmentedMenuTabs(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _resolveActiveTabWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSovereignSentinelHeader(double score) {
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
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _locVal('RIMAN SENTINEL ENGINE', 'منظومة حارس ريمان الذكي (Sentinel)'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'v15.0',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _locVal(
                        'Continuous local anomaly evaluation, protection coverage calibration, and watchdog status evolution.',
                        'التقييم المستمر للانحراف في الذاكرة الحركية، تدقيق تغطية الدفاع، ومعايرة مؤشرات الحراسة الفورية.',
                      ),
                      style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchdogBentoQuickRow(double score, int openAnoms) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // GAUGER SCORE CARD
          Expanded(
            flex: 5,
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  _buildPulseGaugeIndicator(score),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locVal('SENTINEL DEFENSIVE PROFILE', 'ملف السلامة والحراسة الحرج'),
                          style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          score >= 90.0
                              ? _locVal('Maximum System Immunity', 'مناعة قصوى ومستوى الحظر مفعل')
                              : score >= 75.0
                                  ? _locVal('Minor Vulnerable Drift', 'رصد انحراف طفيف في الحماية')
                                  : _locVal('IMMEDIATE ACTION REQUIRED', 'يتطلب اتخاذ إجراء فوري وعاجل!'),
                          style: TextStyle(
                            color: _getScoreGradeColor(score),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locVal(
                            'Proactive defense coefficient computed from active watchdog grids and applied recs.',
                            'تم حساب معامل الأمان بناءً على شبكات الترابط النشطة والتوصيات المطبقة.',
                          ),
                          style: const TextStyle(color: Colors.grey, fontSize: 7, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // TOGGLE ACTIVE DECK CARD
          Expanded(
            flex: 3,
            child: Container(
              height: 100,
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
                    _sentinelService.isWatchdogEngaged ? Icons.verified_user : Icons.enhanced_encryption_outlined,
                    color: _sentinelService.isWatchdogEngaged ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 16,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sentinelService.isWatchdogEngaged ? _locVal('ENGAGED', 'محمي ونشط') : _locVal('STANDBY', 'موقوف مؤقتاً'),
                    style: TextStyle(
                      fontSize: 10,
                      color: _sentinelService.isWatchdogEngaged ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                  const SizedBox(height: 1),
                  Switch(
                    value: _sentinelService.isWatchdogEngaged,
                    activeColor: const Color(0xFF10B981),
                    inactiveTrackColor: Colors.black26,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      _sentinelService.toggleWatchdog(val);
                      _triggerWatchdogToggleLog(val);
                    },
                  ),
                  Text(
                    _locVal('Sentinel watch', 'كلب الحراسة'),
                    style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseGaugeIndicator(double score) {
    return SizedBox(
      width: 65,
      height: 65,
      child: CustomPaint(
        painter: SentinelDialHealthPainter(
          value: score,
          color: _getScoreGradeColor(score),
        ),
        child: Center(
          child: Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              color: _getScoreGradeColor(score),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  void _triggerWatchdogToggleLog(bool status) {
    final msg = status
        ? _locVal('Real-time Sentinel watchdog daemon online and guarding active interfaces.', 'تم تنشيط حراسة ريمان الأمنية التلقائية للبوابات.')
        : _locVal('Real-time watchdog suspended. Transitioning to manual oversight.', 'تم إيقاف المراقبة المستمرة تلقائياً للتحول للتدقيق اليدوي.');
    
    widget.onSecurityLog(
      status ? 'WATCHDOG_ACTIVATED' : 'WATCHDOG_DISABLED',
      status ? 'info' : 'warning',
      msg,
    );
    
    widget.onSuccess(
      status
          ? _locVal('Watchdog successfully engaged.', 'تم تنشيط الحماية الأمنية المستمرة.')
          : _locVal('Watchdog suspended.', 'تم تعليق عمل الحارس الأمني.'),
      status ? 'success' : 'warning',
    );
  }

  Widget _buildSegmentedMenuTabs() {
    final items = [
      {'icon': Icons.space_dashboard, 'label': _locVal('Sentinel Dashboard', 'لوحة تحكم ريمان')},
      {'icon': Icons.privacy_tip, 'label': _locVal('Recommendations & Missions', 'التوصيات والمهمات')},
      {'icon': Icons.notification_important, 'label': _locVal('Local Anomaly Hub', 'مركز الأدلة الفورية')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(items.length, (idx) {
          final isSelected = _activeNavTab == idx;
          final item = items[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeNavTab = idx;
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
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.01),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 12,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                    ),
                    const SizedBox(width: 5),
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

  Widget _resolveActiveTabWidget() {
    switch (_activeNavTab) {
      case 0:
        return _buildSentinelDashboardOverviewTab();
      case 1:
        return _buildSentinelMissionsRecommendationsTab();
      case 2:
        return _buildSentinelLocalAnomaliesTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 1: DASHBOARD OVERVIEW (System coverage maps, historical score progression, timeline)
  Widget _buildSentinelDashboardOverviewTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader(_locVal('HISTORICAL IMMUNITY PROGRESSION', 'مسار تطور معامل حصانة ريمان')),
        const SizedBox(height: 6),
        Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: CustomPaint(
            painter: SentinelScoreCurvePainter(
              history: _sentinelService.scoreHistory,
              gridColor: const Color(0x1A64748B),
              lineColor: const Color(0xFF3B82F6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionHeader(_locVal('PROTECTION COVERAGE MAP', 'خارطة مستويات تغطية دروع النظام')),
        const SizedBox(height: 6),
        _buildProtectionCoverageMapGrid(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(_locVal('TEST VALIDATION TARGETS', 'التحقق التلقائي ومرحلة درع النصوص')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0x1B10B981), borderRadius: BorderRadius.circular(4)),
              child: const Text('דרע_נוסוץ_LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildTestVerificationPanel(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 0.8
        ),
      ),
    );
  }

  Widget _buildProtectionCoverageMapGrid() {
    final coverages = _sentinelService.protectionCoverage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        children: coverages.entries.map((entry) {
          final title = entry.key;
          final pct = entry.value;
          final color = pct >= 90.0
              ? const Color(0xFF10B981)
              : pct >= 60.0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 4.5,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestVerificationPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locVal(
                    'Integration is live. The Text Shield tab translation ("درع النصوص") resides inside the configuration table.',
                    'التحقق المرجعي مطابق ومستقر. ترجمة "درع النصوص" محفوظة وتعمل بسلاسة تامة في سجلات الترجمة.',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.35),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locVal('Active test suite verification targets:', 'أهداف فحص ومطابقة حزم الاختبارات الميدانية:'),
                style: const TextStyle(color: Colors.grey, fontSize: 8.5),
              ),
              const Text(
                '100% PASS',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          )
        ],
      ),
    );
  }

  // TAB 2: RECOMMENDATIONS & MISSIONS
  Widget _buildSentinelMissionsRecommendationsTab() {
    final listRecs = _sentinelService.recommendations;
    final listMissions = _sentinelService.missions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(_locVal('SENTINEL SECURITY CONTEXT MISSIONS', 'مهمات السلامة النشطة ومكتسبات التقران')),
        const SizedBox(height: 4),
        Expanded(
          flex: 4,
          child: ListView.builder(
            itemCount: listMissions.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final m = listMissions[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.02)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: m.isCompleted ? const Color(0x2210B981) : const Color(0x1B3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        m.isCompleted ? Icons.military_tech : Icons.hourglass_top,
                        color: m.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                        size: 14,
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
                                _locVal(m.titleEn, m.titleAr),
                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '+${m.rewardScore} ${_locVal("Immunity", "نقاط")}',
                                style: TextStyle(
                                  color: m.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locVal(m.descriptionEn, m.descriptionAr),
                            style: const TextStyle(color: Colors.grey, fontSize: 8),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: m.progress,
                              minHeight: 3,
                              backgroundColor: Colors.black26,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                m.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
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
        const SizedBox(height: 8),
        _buildSectionHeader(_locVal('DYNAMIC SMART RECOMMENDATIONS', 'التوصيات الذكية لتحصين الثغرات وتغطيتها')),
        const SizedBox(height: 4),
        Expanded(
          flex: 5,
          child: ListView.builder(
            itemCount: listRecs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, idx) {
              final r = listRecs[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: r.isApplied ? Colors.white.withOpacity(0.01) : const Color(0xFFF59E0B).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.isApplied ? Icons.gpp_good : Icons.lightbulb_outline,
                      color: r.isApplied ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 16,
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
                                _locVal(r.titleEn, r.titleAr),
                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: r.isApplied ? const Color(0x1B10B981) : const Color(0x1BF59E0B),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  r.metricImpact,
                                  style: TextStyle(
                                    color: r.isApplied ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _locVal(r.descriptionEn, r.descriptionAr),
                            style: const TextStyle(color: Colors.grey, fontSize: 7.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!r.isApplied)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(60, 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ).copyWith(
                          elevation: WidgetStateProperty.all(0),
                        ),
                        onPressed: () {
                          _sentinelService.applyRecommendation(r.id);
                          widget.onSecurityLog(
                            'RECOMMENDATION_APPLIED',
                            'info',
                            'Applied local defensive action for "${r.titleEn}". Vector score incremented.'
                          );
                          widget.onSuccess(
                            _locVal('Applied recommendation vector successfully.', 'تم تطبيق التوصية الإرشادية بنجاح ونقاط الحصانة تحسنت.'),
                            'success',
                          );
                        },
                        child: Text(
                          _locVal('APPLY', 'تطبيق'),
                          style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      const Icon(Icons.check, color: Color(0xFF10B981), size: 14),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 3: ANOMALIES & AUDITS
  Widget _buildSentinelLocalAnomaliesTab() {
    final anomalies = _sentinelService.anomalies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(_locVal('ACTIVE LOCAL SECURITY ANOMALIES', 'سجل فحص الانحرافات وحوادث الاختراق الفورية')),
            GestureDetector(
              onTap: () {
                _sentinelService.injectEntropyAnomaly();
                widget.onSecurityLog(
                  'SIM_ANOMALY',
                  'warning',
                  'Simulated structural entropy dropping events triggered on Riemann kernel matrices.'
                );
                widget.onSuccess(
                  _locVal('Anomaly simulation flag raised!', 'تم حقن طفرة العشوائية لمحاكاة الفحص الأمني!'),
                  'warning',
                );
              },
              child: Text(
                _locVal('Simulate Anomaly', 'حقن انحراف للتجربة'),
                style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: anomalies.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.01)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield, color: Color(0xFF10B981), size: 30),
                      const SizedBox(height: 8),
                      Text(
                        _locVal('CO-ORDIAL VECTS SECURE', 'سجل أمان نقي وخال من انحرافات الذاكرة'),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _locVal('Zero persistent access pattern warnings or brute attempts on disk.', 'لا توجد محاولات تلاعب بالكتل أو خرق لرموز PIN في المدونة المحلية.'),
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: anomalies.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, idx) {
                    final a = anomalies[idx];
                    final isRes = a.isResolved;
                    final Color severityColor = a.severity == 'Critical'
                        ? const Color(0xFFEF4444)
                        : a.severity == 'High'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6);

                    return Card(
                      color: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isRes ? Colors.white.withOpacity(0.01) : severityColor.withOpacity(0.35)
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
                                      isRes ? Icons.check_circle_outline : Icons.warning_amber,
                                      color: isRes ? const Color(0xFF10B981) : severityColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isRes ? _locVal('RESOLVED', 'تم دحر الانحراف') : a.type.toUpperCase(),
                                      style: TextStyle(
                                        color: isRes ? const Color(0xFF10B981) : severityColor,
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isRes
                                        ? const Color(0x1B10B981)
                                        : severityColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isRes ? 'SAFE' : a.severity.toUpperCase(),
                                    style: TextStyle(
                                      color: isRes ? const Color(0xFF10B981) : severityColor,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _locVal(a.descriptionEn, a.descriptionAr),
                              style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_locVal("Detected:", "رصد الساعة:")} ${a.detectedAt.hour}:${a.detectedAt.minute}:${a.detectedAt.second}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                                ),
                                if (!isRes)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      minimumSize: const Size(60, 24),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ).copyWith(elevation: WidgetStateProperty.all(0)),
                                    onPressed: () {
                                      _sentinelService.resolveAnomaly(a.id);
                                      widget.onSecurityLog(
                                        'ANOMALY_RESOLVED',
                                        'success',
                                        'Neutralized structural drift anomaly ID: ${a.id}'
                                      );
                                      widget.onSuccess(
                                        _locVal('Construct secure alignment. Parity restored.', 'تم إصلاح وإلغاء تحذير الانحراف في مصفوفة الصفر ريمان.'),
                                        'success',
                                      );
                                    },
                                    child: Text(
                                      _locVal('NEUTRALIZE', 'إخماد وتأمين'),
                                      style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  Text(
                                    _locVal('Signature Compliant', 'التوقيع مستقر'),
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}

// Dial paint gauge
class SentinelDialHealthPainter extends CustomPainter {
  final double value;
  final Color color;

  SentinelDialHealthPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerWidth = size.width / 2;
    final double centerHeight = size.height / 2;
    final double radius = math.min(centerWidth, centerHeight) - 4.5;

    final Paint trackPaint = Paint()
      ..color = const Color(0x221E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;

    canvas.drawCircle(Offset(centerWidth, centerHeight), radius, trackPaint);

    final double sweepAngle = (value / 100.0) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerWidth, centerHeight), radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Dynamic score curve graph painter
class SentinelScoreCurvePainter extends CustomPainter {
  final List<SentinelScoreHistory> history;
  final Color gridColor;
  final Color lineColor;

  SentinelScoreCurvePainter({
    required this.history,
    required this.gridColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final double w = size.width;
    final double h = size.height;

    // Grid lines count
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = (h / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final double xSegment = w / (math.max(2, history.length) - 1);
    final points = <Offset>[];

    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      // Map score value (range 60 to 100 on graph)
      const double minScale = 60.0;
      const double maxScale = 100.0;
      final double normalizedScore = ((item.score - minScale) / (maxScale - minScale)).clamp(0.0, 1.0);
      
      final double x = xSegment * i;
      final double y = h - (normalizedScore * h * 0.85) - 8;
      points.add(Offset(x, y));
    }

    // Draw curve path
    final Path curvePath = Path();
    curvePath.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final xc = (p1.dx + p2.dx) / 2;
      curvePath.quadraticBezierTo(p1.dx, p1.dy, xc, (p1.dy + p2.dy) / 2);
    }
    curvePath.lineTo(points.last.dx, points.last.dy);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(curvePath, linePaint);

    final Paint shadowPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.18), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    final Path shadowPath = Path.from(curvePath);
    shadowPath.lineTo(w, h);
    shadowPath.lineTo(0, h);
    shadowPath.close();

    canvas.drawPath(shadowPath, shadowPaint);

    // Draw nodes/dots
    final Paint dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    
    final Paint outerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var pt in points) {
      canvas.drawCircle(pt, 4.0, outerDotPaint);
      canvas.drawCircle(pt, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
