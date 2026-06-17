import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/intelligence.dart';
import '../utils/intelligence_service.dart';

class IntelligenceDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const IntelligenceDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<IntelligenceDashboardWidget> createState() => _IntelligenceDashboardWidgetState();
}

class _IntelligenceDashboardWidgetState extends State<IntelligenceDashboardWidget> {
  final IntelligenceService _intelService = IntelligenceService();
  
  // Sub-tabs: 0 = Scores & Risks, 1 = Optimization Center, 2 = Storage Insights, 3 = Behavior Log
  int _activeSubTab = 0;

  // New manual anomaly simulator inputs
  String _simActor = 'SecOpsOperator';
  String _simOperationEn = 'External credential challenge failure';
  String _simOperationAr = 'فشل التحقق من صلاحية الاعتماد الخارجي للمخدم';
  double _simAnomalyVal = 0.75;

  @override
  void initState() {
    super.initState();
    _intelService.addListener(_stateListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSecurityLog(
        'Riman Intelligence Center Online',
        'info',
        'Intelligence evaluation services launched. Live Security Index: ${_intelService.securityIntelligenceScore.toStringAsFixed(1)}'
      );
    });
  }

  @override
  void dispose() {
    _intelService.removeListener(_stateListener);
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
    final double secScore = _intelService.securityIntelligenceScore;
    final double storScore = _intelService.storageHealthScore;

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // Deep slate background
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntelligenceHeroHeader(secScore, storScore),
              const SizedBox(height: 8),
              _buildTabSelectorNavigationBar(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _resolveActiveSubTabBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceHeroHeader(double secScore, double storScore) {
    final bool isHealthy = secScore >= 80.0;
    
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
                        color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _locVal('RIMAN INTELLIGENCE NETWORK (v21.0)', 'شبكة ريمان الاستخباراتية للأمن الموحد (v21.0)'),
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
                    isHealthy ? 'COHESIVE THREAT SHIELD ACTIVE' : 'INTELLIGENCE WARNING: ACTION REQUIRED',
                    isHealthy ? 'نظام الحماية الاستباقي مستقر وفعال' : 'تحذير استخباراتي: ثغرات أمنية قيد المراقبة',
                  ),
                  style: TextStyle(
                    fontSize: 8,
                    color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Dual score gauges
          Row(
            children: [
              _buildMiniScoreIndicator(_locVal('SECURITY', 'الأمان'), secScore, const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _buildMiniScoreIndicator(_locVal('STORAGE', 'الخزن'), storScore, const Color(0xFF3B82F6)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniScoreIndicator(String label, double val, Color colorTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        children: [
          Text(
            '${val.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorTheme,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 6, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelectorNavigationBar() {
    final tabs = [
      {'icon': Icons.analytics, 'label': _locVal('Metrics & Risks', 'التقييم والمخاطر')},
      {'icon': Icons.auto_mode, 'label': _locVal('Optimization', 'مركز التحسين')},
      {'icon': Icons.storage, 'label': _locVal('Storage growth', 'الذكاء السحابي للبيانات')},
      {'icon': Icons.psychology, 'label': _locVal('Behavior Monitor', 'محلل سلوك العميل')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _activeSubTab == idx;
          final tab = tabs[idx];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSubTab = idx;
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

  Widget _resolveActiveSubTabBody() {
    switch (_activeSubTab) {
      case 0:
        return _buildMetricsAndRisksLayout();
      case 1:
        return _buildOptimizationCenterLayout();
      case 2:
        return _buildStorageGrowthLayout();
      case 3:
        return _buildBehaviorMonitorLayout();
      default:
        return const SizedBox();
    }
  }

  // SUBTAB 0: METRICS AND INTEROPERATIVE RISK ENGINE
  Widget _buildMetricsAndRisksLayout() {
    final metrics = _intelService.riskMetrics;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader(_locVal('CORE COMPLIANCE VERIFICATION MATRIX', 'مصفوفة التحقق الاستخباراتية النشطة')),
        const SizedBox(height: 6),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final node = metrics[index];
            final double score = node.currentScore;
            
            Color valColor = const Color(0xFF10B981);
            if (score > 70.0) {
              valColor = const Color(0xFFEF4444);
            } else if (score > 40.0) {
              valColor = const Color(0xFFF59E0B);
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
                        _locVal(node.nameEn, node.nameAr),
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _locVal(node.statusLabelEn, node.statusLabelAr),
                        style: TextStyle(color: valColor, fontSize: 7, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100.0,
                            backgroundColor: Colors.black26,
                            valueColor: AlwaysStoppedAnimation<Color>(valColor),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () {
            _intelService.runFullIntelligenceReassessment();
            widget.onSuccess(
              _locVal('Executed comprehensive vulnerability audit cycle.', 'تم تشغيل دورة فحص وتقييم المخاطر الميدانية الفورية.'),
              'success',
            );
          },
          icon: const Icon(Icons.psychology_alt, color: Color(0xFFEF4444), size: 14),
          label: Text(
            _locVal('RE-SCAN PHYSICAL VULNERABILITY VECTORS', 'إعادة فحص واختبار قنوات الثغرات والتهديدات'),
            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 12),

        // Anchor preservation rule compliance
        _buildSecurityEngineAnchorDisclaimer(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSecurityEngineAnchorDisclaimer() {
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
              const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 12),
              const SizedBox(width: 6),
              Text(
                _locVal('COGNITIVE COHERENCE INTEGRITY', 'موثوقية وتناغم الطبقات المشتركة'),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.3),
              children: [
                TextSpan(text: _locVal('This analytical dashboard establishes direct compliance hooks with ', 'تعزز وحدة القياس والمعالجة الاستخبارية سياق الربط التلقائي والفعال مع التبويب المعتمد ')),
                const TextSpan(
                  text: '"درع النصوص"',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
                TextSpan(text: _locVal(' indicating total coherence between active encryption vectors and plain-text buffers.', ' لتأمين وحماية طبقة تشفير النصوص والملفات على حد سواء.')),
              ],
            ),
          )
        ],
      ),
    );
  }

  // SUBTAB 1: HIGH FIDELITY OPTIMIZATION CENTER (INSIGHTS)
  Widget _buildOptimizationCenterLayout() {
    final insights = _intelService.insights;
    final activeInsights = insights.where((i) => !i.isResolved).toList();
    final resolvedInsights = insights.where((i) => i.isResolved).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(_locVal('INTELLIGENT SEC-OPS ACTION ITEMS', 'توصيات معالجة وحجب التهديدات النشطة')),
            Text(
              '${activeInsights.length} ${widget.locale == 'ar' ? 'معلق' : 'pending'}',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 7.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(height: 6),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              if (activeInsights.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(
                    _locVal('Intelligence report clear! No pending optimize recommendations.', 'تقرير الاستخبارات سليم! لا توجد توصيات معالجة نشطة حالياً.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeInsights.length,
                  itemBuilder: (context, index) {
                    final item = activeInsights[index];
                    
                    Color severityColor = const Color(0xFF3B82F6);
                    if (item.severity == InsightSeverity.critical) {
                      severityColor = const Color(0xFFEF4444);
                    } else if (item.severity == InsightSeverity.high) {
                      severityColor = const Color(0xFFF59E0B);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: severityColor.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 10,
                                backgroundColor: severityColor.withOpacity(0.12),
                                child: Text(
                                  item.severity.name[0].toUpperCase(),
                                  style: TextStyle(color: severityColor, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                _locVal(item.titleEn, item.titleAr),
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _locVal(item.descriptionEn, item.descriptionAr),
                                style: const TextStyle(color: Colors.grey, fontSize: 7.5, height: 1.3),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locVal('RECOMMENDED COUNTERMEASURE', 'الإجراء المضاد المقترح من النظام'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _locVal(item.recommendationEn, item.recommendationAr),
                                  style: const TextStyle(color: Colors.white70, fontSize: 7.5),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _intelService.resolveInsight(item.insightId);
                                        widget.onSuccess(
                                          _locVal('SecOps countermeasures applied.', 'تم تطبيق التدابير الوقائية الموصى بها بنجاح.'),
                                          'success',
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                        ),
                                        child: Text(
                                          _locVal('Apply Action', 'تطبيق الإجراء'),
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        _intelService.dismissInsight(item.insightId);
                                        widget.onSuccess(
                                          _locVal('Recommendation dismissed.', 'تم صرف النظر وتجاهل التوصية الاستخباراتية بشكل يدوي.'),
                                          'info',
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _locVal('Dismiss', 'تجاهل'),
                                          style: const TextStyle(color: Colors.grey, fontSize: 7),
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
                
              _buildSectionHeader(_locVal('HISTORIC MITIGATIONS RESOLVED', 'سجل التهديدات والتحسينات المكتملة')),
              const SizedBox(height: 6),
              
              if (resolvedInsights.isEmpty)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_locVal('No historical resolved events.', 'لا توجد معالجات مؤرشفة.'), style: const TextStyle(color: Colors.grey, fontSize: 8)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resolvedInsights.length,
                  itemBuilder: (context, index) {
                    final item = resolvedInsights[index];
                    return Card(
                      color: Colors.black26,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locVal(item.titleEn, item.titleAr),
                                    style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough),
                                  ),
                                  Text(
                                    _locVal('Successfully mitigated with zero data degradation.', 'تم الفض والأرشفة بنجاح مع سلامة مطلقة للأصول الرقمية.'),
                                    style: const TextStyle(color: Colors.grey, fontSize: 6.5),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  // SUBTAB 2: DATA INTEGRATION & GROWTH TIMELINE GRAPH (STORAGE INTELLIGENCE)
  Widget _buildStorageGrowthLayout() {
    final history = _intelService.storageHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(_locVal('SMART STORAGE GROWTH COHERENCE', 'نمو الأصول المشفرة التاريخي المترابط')),
        const SizedBox(height: 4),
        
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: history.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Text(_locVal('No telemetry data available.', 'لا توجد مؤشرات في قاعدة البيانات البيئية.'), style: const TextStyle(color: Colors.grey, fontSize: 8.5)),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(history.length, (idx) {
                    final point = history[idx];
                    final double totalMB = (point.symmetricCipherBytes + point.asymmetricCipherBytes) / (1024 * 1024);
                    // Standardizing max capacity scale to 50MB for visualization
                    final double heightPct = (totalMB / 30.0).clamp(0.1, 1.0);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${totalMB.toStringAsFixed(1)}M',
                            style: const TextStyle(color: Colors.white, fontSize: 6.5, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 60 * heightPct,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${point.recordTime.month}/${point.recordTime.day}',
                            style: const TextStyle(color: Colors.grey, fontSize: 5.5, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
        const SizedBox(height: 10),

        _buildSectionHeader(_locVal('LIVE VAULT VAULT EXPORTS AND HISTORIC TIMELINE', 'سجلات تدفق البيانات وخزائن الرفع والتصدير')),
        const SizedBox(height: 4),

        Expanded(
          child: history.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[history.length - 1 - index];
                    final symMB = item.symmetricCipherBytes / (1024 * 1024);
                    final asymMB = item.asymmetricCipherBytes / (1024 * 1024);

                    return Card(
                      color: Colors.black26,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle_notifications, color: Color(0xFF3B82F6), size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TELEMETRY CELL: ${item.recordTime.hour}:${item.recordTime.minute}',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                      Text(
                                        'Growth: +${item.cumulativeGrowthRate.toStringAsFixed(2)}%',
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Files Indexed: ${item.totalFilesTracked} | Sym: ${symMB.toStringAsFixed(2)}MB | Asym: ${asymMB.toStringAsFixed(2)}MB',
                                    style: const TextStyle(color: Colors.white70, fontSize: 7.5, fontFamily: 'monospace'),
                                  )
                                ],
                              ),
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

  // SUBTAB 3: USER BEHAVIOR AUDITING & ANOMALY DETECTOR LOGS
  Widget _buildBehaviorMonitorLayout() {
    final reports = _intelService.behaviorReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(_locVal('CLIENT ANOMALY SIMULATOR (TEST BED)', 'لوحة محاكاة واختبار سلوك المستخدم الاستباقي')),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF0F172A),
                          value: _simActor,
                          style: const TextStyle(color: Colors.white, fontSize: 8.5),
                          items: ['SystemRootAdmin', 'SecOpsOperator', 'UnknownOperatorNode'].map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _simActor = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locVal('Anomaly confidence: ${(_simAnomalyVal * 100).toStringAsFixed(0)}%', 'معامل الانحراف السلوكي: ${(_simAnomalyVal * 100).toStringAsFixed(0)}%'),
                          style: const TextStyle(color: Colors.white, fontSize: 7.5),
                        ),
                        Slider(
                          value: _simAnomalyVal,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFFEF4444),
                          onChanged: (val) {
                            setState(() {
                              _simAnomalyVal = val;
                            });
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  final isAtypical = _simAnomalyVal >= 0.85;
                  _intelService.recordUserBehavior(
                    actorRole: _simActor,
                    operationEn: _simOperationEn,
                    operationAr: _simOperationAr,
                    anomalyConf: _simAnomalyVal,
                    atypic: isAtypical,
                  );

                  // If high anomaly simulated, auto spawn compliance optimization recommendation
                  if (isAtypical) {
                    _intelService.addInsight(
                      category: InsightCategory.behavior,
                      titleEn: 'Atypical Operation: $_simActor',
                      titleAr: 'نشاط شاذ ومثير للشبهة: $_simActor',
                      descEn: 'Dynamic analyzer caught an atypical confidence score above the security threshold.',
                      descAr: 'التقط محلل الحركة ومقاومة هجمات الهندسة العكسية معامل انحراف فوق الحد المسموح به.',
                      severity: InsightSeverity.high,
                      recEn: 'Enforce overlay authorization and verify login telemetry credentials.',
                      recAr: 'يرجى مراجعة الصلاحيات والتحقق الفوري من صحة ترويسة الاتصال.',
                    );
                  }

                  widget.onSuccess(
                    _locVal('User behavior pattern logged to database.', 'تم تسجيل وضخ ترويسة محاكاة السلوك إلى مصفوفة الرقابة.'),
                    'warning',
                  );
                },
                child: Text(
                  _locVal('RECORD USER BEHAVIOR RECORD', 'تسجيل وحقن السلوك السلوكي'),
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        _buildSectionHeader(_locVal('LOCAL USER BEHAVIOR ANOMALY CHRONOLOGY', 'التسلسل الزمني لمراقبة وتدقيق سلوكيات التشغيل')),
        const SizedBox(height: 4),

        Expanded(
          child: reports.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Text(_locVal('No behavior audit reports.', 'سجل الحسابات متناسق ونظيف بالكامل.'), style: const TextStyle(color: Colors.grey, fontSize: 9)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final rap = reports[index];
                    final double confPct = rap.anomalyConfidence * 100;
                    
                    Color statusColor = const Color(0xFF10B981);
                    if (rap.isSuspectedAtypical) {
                      statusColor = const Color(0xFFEF4444);
                    } else if (confPct > 40) {
                      statusColor = const Color(0xFFF59E0B);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: rap.isSuspectedAtypical ? const Color(0x33EF4444) : Colors.white.withOpacity(0.01),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 24,
                            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rap.actorRole,
                                      style: TextStyle(color: rap.isSuspectedAtypical ? const Color(0xFFEF4444) : Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Anomaly: ${confPct.toStringAsFixed(0)}%',
                                      style: TextStyle(color: statusColor, fontSize: 7, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _locVal(rap.operationTypeEn, rap.operationTypeAr),
                                  style: const TextStyle(color: Colors.white70, fontSize: 7.5),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Time: ${rap.eventTime.hour}:${rap.eventTime.minute}:${rap.eventTime.second} | ID: ${rap.recordId}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 6, fontFamily: 'monospace'),
                                )
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

  Widget _buildSectionHeader(String val) {
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
