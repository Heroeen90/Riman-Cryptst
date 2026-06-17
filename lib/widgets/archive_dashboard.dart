import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/archive_engine.dart';
import '../utils/archive_service.dart';
import '../utils/nexus_service.dart';

class ArchiveDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const ArchiveDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<ArchiveDashboardWidget> createState() => _ArchiveDashboardWidgetState();
}

class _ArchiveDashboardWidgetState extends State<ArchiveDashboardWidget> {
  final ArchiveService _archiveService = ArchiveService();
  
  // Dashboard view tab: 0 = Health & Allocation, 1 = Archive Vault Explorer, 2 = Deep Search Matrix
  int _tabIndex = 0;

  // Search parameters
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  List<SearchResult> _searchResults = [];

  // Create Archive Form state
  String? _selectedAssetId;
  ArchiveState _selectedState = ArchiveState.ColdStorage;
  bool _isImmutableForm = false;
  final TextEditingController _archiveDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _archiveService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _archiveService.removeListener(_onStateChanged);
    _searchCtrl.dispose();
    _archiveDescCtrl.dispose();
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

  void _triggerSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchResults = _archiveService.performDeepSearch(query);
    });
  }

  void _createArchive() {
    final assets = NexusService().getAvailableAssets();
    if (_selectedAssetId == null) {
      widget.onSuccess(
        _locVal('Select an active resource to archive!', 'يرجى تحديد عنصر نشط لأرشفته!'),
        'error',
      );
      return;
    }

    final targetAsset = assets.firstWhere((a) => a.id == _selectedAssetId, orElse: () => assets[0]);
    
    // Simulate size if unknown
    int size = 1500;
    if (targetAsset.type == 'file') {
      size = 1450000; // 1.45 MB
    } else if (targetAsset.type == 'vault') {
      size = 34500000; // 34.5 MB
    }

    _archiveService.archiveResource(
      originalId: targetAsset.id,
      name: targetAsset.name,
      type: targetAsset.type,
      sizeInBytes: size,
      state: _selectedState,
      category: targetAsset.category,
      description: _archiveDescCtrl.text.trim().isEmpty 
          ? _locVal('Archived quantum state for security freeze.', 'تجميد وحفظ آمن مشفر للحماية القصوى.')
          : _archiveDescCtrl.text.trim(),
      isImmutable: _isImmutableForm,
    );

    widget.onSecurityLog(
      'Resource Archived',
      'success',
      'Resource "${targetAsset.name}" successfully committed to Quantum Cold Storage.',
    );

    widget.onSuccess(
      _locVal('Asset committed to cold partition successfully.', 'تم نقل وتجميد الأصل المشفر في القسم البارد بنجاح!'),
      'success',
    );

    setState(() {
      _selectedAssetId = null;
      _archiveDescCtrl.clear();
      _isImmutableForm = false;
    });
  }

  void _restoreItem(ArchiveItem item) {
    if (item.isImmutable) {
      widget.onSuccess(
        _locVal('Immutable archives cannot be altered or restored.', 'خطأ: الأرشيف غير القابل للتعديل محمي تمامًا ويمنع فكه!'),
        'error',
      );
      return;
    }

    _archiveService.deleteArchive(item.id);

    widget.onSecurityLog(
      'Archive Restored',
      'info',
      'Archived item "${item.name}" restored and unfrozen to normal hot partition.',
    );

    widget.onSuccess(
      _locVal('Archive unfrozen and returned to hot runtime memory.', 'تم إذابة وإعادة الملف المؤرشف إلى الذاكرة النشطة بنجاح!'),
      'success',
    );
  }

  void _toggleImmutability(ArchiveItem item) {
    bool nextVal = !item.isImmutable;
    _archiveService.toggleImmutability(item.id, nextVal);

    widget.onSecurityLog(
      'Immutability Toggled',
      nextVal ? 'warning' : 'info',
      'Archive "${item.name}" immutability set to: ${nextVal.toString().toUpperCase()}.',
    );

    widget.onSuccess(
      nextVal
          ? _locVal('Archive locked. Immutability protection active.', 'تم تأمين الملف بشكل نهائي. الأرشيف غير قابل للتعديل الآن!')
          : _locVal('Immutability lock dissolved.', 'تم فك حماية عدم التعديل بنجاح.'),
      'success',
    );
  }

  void _updateRanking(ArchiveItem item, int rank) {
    _archiveService.updateRanking(item.id, rank);
    widget.onSuccess(
      _locVal('Archive search priority rank updated.', 'تم تحديث أولوية البحث وفحص الأرشفة بنجاح.'),
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617), // slate-950 dark background
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 12),
              _buildDashboardTabBar(),
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

  Widget _buildTopHeader() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.archive, color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _locVal('QUANTUM ARCHIVE ENGINE', 'محرك الأرشفة الكمي ريمان'),
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
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'v12.0',
                        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locVal(
                    'Immutable system state freezing, cold storage, absolute integrity, and multi-component index.',
                    'تجميد مرن للملفات والأصل غير القابل للتغيير، وضغط تخزين الأقراص، ومؤشرات المزامنة.',
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

  Widget _buildDashboardTabBar() {
    final items = [
      {'icon': Icons.insights, 'label': _locVal('Health & Allocation', 'قراءة البيانات والقدرة')},
      {'icon': Icons.storage, 'label': _locVal('Archive Vaults', 'قسم الأرشيف المشفر')},
      {'icon': Icons.find_in_page, 'label': _locVal('Deep Search Matrix', 'مصفوفة البحث العميق')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(items.length, (idx) {
          final item = items[idx];
          final isSelected = _tabIndex == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tabIndex = idx;
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
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.02),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 13,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 8.5,
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
    switch (_tabIndex) {
      case 0:
        return _buildHealthAndAllocationTab();
      case 1:
        return _buildArchiveVaultExplorerTab();
      case 2:
        return _buildDeepSearchMatrixTab();
      default:
        return const SizedBox();
    }
  }

  // SUB-TAB 0: Health Center, Power Saving, Dynamic Charts
  Widget _buildHealthAndAllocationTab() {
    final metrics = _archiveService.getHealthMetrics();
    final bool isColdPower = _archiveService.isColdStoragePowerSave;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row containing overall Integrity health score radial ring
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CustomPaint(
                          painter: HealthGaugePainter(
                            score: metrics.overallScore,
                            trackColor: Colors.grey.shade900,
                            fillColor: const Color(0xFF10B981),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${metrics.overallScore.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _locVal('HEALTH', 'الصحة'),
                                  style: const TextStyle(color: Colors.grey, fontSize: 6.5, fontWeight: FontWeight.bold),
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
                              _locVal('INTEGRITY LEVEL', 'مستوى سلامة الأرشيف'),
                              style: const TextStyle(color: Colors.grey, fontSize: 7.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metrics.overallScore >= 95.0
                                  ? _locVal('Optimal Stability', 'استقرار فائق ومثالي')
                                  : _locVal('Verify Integrity Snapshots', 'يرجى مراجعة السلامة'),
                              style: TextStyle(
                                color: metrics.overallScore >= 95.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _locVal(
                                'Averaged mathematical checksum of all registered immutable blocks.',
                                'مجموع حسابي دقيق لكافة كتل المعايير غير القابلة للتلاعب بالأرشيف.',
                              ),
                              style: const TextStyle(color: Colors.grey, fontSize: 7, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total count card
              Expanded(
                flex: 2,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metrics.totalArchives.toString(),
                        style: const TextStyle(fontSize: 28, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locVal('TOTAL ARCHIVES', 'إجمالي الأرشيف'),
                        style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${metrics.immutableCount} ${_locVal('Immutable', 'غير قابل للتعديل')}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom storage partitions distribution bar chart
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _locVal('COLD STORAGE SPACE ALLOCATION MAP', 'خارطة التوزيع ومساحة التخزين البارد'),
                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Text(
                  _locVal(
                    'Real-time physical segment partition mapping based on file type footprint.',
                    'تخصيص مساحات الأقراص المباشر حسب نوع الملف والفرز الموزع تزامنيًا.',
                  ),
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
                const SizedBox(height: 16),

                // Bar Visualization
                SizedBox(
                  height: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: PartitionBarPainter(
                        cold: metrics.coldStorageCount,
                        longTerm: metrics.longTermCount,
                        historical: metrics.historicalCount,
                        empty: metrics.totalArchives == 0 ? 1 : 0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendCell(const Color(0xFF3B82F6), 'Cold Storage', metrics.coldStorageCount),
                    _buildLegendCell(const Color(0xFFF59E0B), 'Long-Term', metrics.longTermCount),
                    _buildLegendCell(const Color(0xFF10B981), 'Historical', metrics.historicalCount),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cold Storage Compression config (Power saving / performance slider)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locVal('COLD RECLAIM POWER-OPTIMIZATION', 'تحسين استهلاك طاقة الأقراص وتحجيم الملفات'),
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locVal(
                              'When enabled, cold storage archives undergo secondary entropy compression to minimize active sector reads at rest.',
                              'عند التفعيل، تخضع الأراشيف القديمة لفرز تكراري عالي الدقة لتقليل حجم القراءة التراكمية.',
                            ),
                            style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isColdPower,
                      activeColor: const Color(0xFF3B82F6),
                      inactiveTrackColor: Colors.black45,
                      onChanged: (val) {
                        _archiveService.toggleColdStoragePowerSave(val);
                        widget.onSecurityLog(
                          'Cold Storage Optimization State Changed',
                          'info',
                          'Secondary Entropy compression state: ${val.toString().toUpperCase()}',
                        );
                        widget.onSuccess(
                          val
                              ? _locVal('Entropy optimizations committed successfully.', 'تم تفعيل وتهيئة ضغط القطاعات بنجاح!')
                              : _locVal('Entropy optimizations paused.', 'تم إيقاف تحسين طاقة الأقراص.'),
                          'success',
                        );
                      },
                    ),
                  ],
                ),
                if (isColdPower) ...[
                  const Divider(height: 16, color: Colors.white10),
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locVal(
                            'Active compressing profile: RIEMANN-CBC-LZ4. System saves ~34.2% active memory bandwidth.',
                            'نمط الضغط الفعال الحالي: RIEMANN-CBC-LZ4. وفر النظام ما يقارب 34.2% من حجم تداول الذاكرة.',
                          ),
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8.5, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Archive integrity logs
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _locVal('COHERENT SECURITY BLOCK SNAPSHOTS (${_archiveService.snapshots.length})', 'سجلات تدقيق وفحص سلامة الكتل (${_archiveService.snapshots.length})'),
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),

                _archiveService.snapshots.isEmpty
                    ? Text(
                        _locVal('No integrity snapshots logged yet.', 'لا يوجد أي لقطات سلامة مسجلة في قسم الكتل بعد.'),
                        style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _archiveService.snapshots.length > 5 ? 5 : _archiveService.snapshots.length,
                        itemBuilder: (context, idx) {
                          final s = _archiveService.snapshots[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fingerprint, color: Color(0xFF10B981), size: 12),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.integrityHash,
                                        style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_locVal('Verified on', 'تم التحقق بنجاح:')} ${s.timestamp.hour}:${s.timestamp.minute} (${s.sizeInBytes} B)',
                                        style: const TextStyle(color: Colors.grey, fontSize: 7.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.status.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendCell(Color col, String label, int count) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  // SUB-TAB 1: Vault Explorer (creation form + interactive table lists with ranking/immutability edits)
  Widget _buildArchiveVaultExplorerTab() {
    final archives = _archiveService.archives;
    final assets = NexusService().getAvailableAssets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Archive Creation Block
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _locVal('FREEZE ACTIVE RESOURCE TO ARCHIVE', 'تجميد وحفظ كتلة نشطة جديدة للأرشيف الكمي'),
                style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white, fontSize: 9.5),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          filled: true,
                          fillColor: Colors.black26,
                          labelText: _locVal('Target Component', 'الأصل والموقع المراد تجميده'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        value: _selectedAssetId,
                        items: assets.map((a) {
                          return DropdownMenuItem<String>(
                            value: a.id,
                            child: Text('[${a.type.toUpperCase()}] ${a.name}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAssetId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<ArchiveState>(
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 9.5, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          labelText: _locVal('Freeze Space Profile', 'مستوى الأرشفة وطبيعة القسم'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        value: _selectedState,
                        items: [
                          DropdownMenuItem(value: ArchiveState.ColdStorage, child: Text(_locVal('Cold Storage Archive (Frozen)', 'تخزين بارد مشفر (متوسط الأولوية)'))),
                          DropdownMenuItem(value: ArchiveState.LongTerm, child: Text(_locVal('Long-Term Core Vault (Sealed)', 'أرشيف تكميلي طويل المدى (ثابت)'))),
                          DropdownMenuItem(value: ArchiveState.Historical, child: Text(_locVal('Historical Chrono Index', 'سجل تاريخي تراكمي (مؤشر زمني)'))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedState = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _archiveDescCtrl,
                        style: const TextStyle(fontSize: 9.5, color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          labelText: _locVal('Optional description...', 'ملاحظات اختيارية للكتلة...'),
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Text(
                        _locVal('Immutable', 'غير قابل للتعديل'),
                        style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      Checkbox(
                        value: _isImmutableForm,
                        activeColor: const Color(0xFF3B82F6),
                        checkColor: Colors.black,
                        onChanged: (val) {
                          setState(() {
                            _isImmutableForm = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _createArchive,
                    child: Text(
                      _locVal('FREEZE', 'تجميد'),
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _locVal('ARCHIVED CODES & COMPONENT CATALOG', 'كتالوج ومستودع الأصول المجمدة'),
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(
          child: archives.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Text(
                    _locVal('Archive is empty.', 'المستودع خالي من أي أصول مجمدة تمامًا.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: archives.length,
                  itemBuilder: (context, idx) {
                    final arc = archives[idx];
                    return Card(
                      color: const Color(0xFF0F172A),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.02)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getArchiveIconData(arc.type),
                                        color: _getArchiveColor(arc.state),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          arc.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // State badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _getArchiveColor(arc.state).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    arc.state.name.toUpperCase(),
                                    style: TextStyle(color: _getArchiveColor(arc.state), fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            if (arc.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                arc.description,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
                              ),
                            ],

                            const Divider(height: 12, color: Colors.white10),

                            // Controls Row (Immutability toggle, Ranking star selection, Restore)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Immutability and details
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleImmutability(arc),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: arc.isImmutable ? const Color(0xFF10B981).withOpacity(0.1) : Colors.black26,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              arc.isImmutable ? Icons.lock : Icons.lock_open,
                                              color: arc.isImmutable ? const Color(0xFF10B981) : Colors.grey,
                                              size: 10,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              arc.isImmutable ? _locVal('IMMUTABLE', 'محكم وثابت') : _locVal('MUTABLE', 'قابل للتعديل'),
                                              style: TextStyle(
                                                color: arc.isImmutable ? const Color(0xFF10B981) : Colors.grey,
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${arc.sizeFormatted} | ${arc.category}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 7.5, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),

                                // Star Rankings & Restore
                                Row(
                                  children: [
                                    // Ranking icons 1 to 5
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        final activeStar = starIdx < arc.ranking;
                                        return InkWell(
                                          onTap: arc.isImmutable ? null : () => _updateRanking(arc, starIdx + 1),
                                          child: Icon(
                                            activeStar ? Icons.star : Icons.star_border,
                                            color: activeStar ? const Color(0xFFF1C40F) : Colors.grey.shade700,
                                            size: 11,
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 10),

                                    // Restore action
                                    InkWell(
                                      onTap: arc.isImmutable ? null : () => _restoreItem(arc),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: arc.isImmutable ? Colors.grey.shade900 : const Color(0xFF3B82F6).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.settings_backup_restore,
                                              color: arc.isImmutable ? Colors.grey.shade600 : const Color(0xFF3B82F6),
                                              size: 10,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _locVal('Restore', 'فك التجميد'),
                                              style: TextStyle(
                                                color: arc.isImmutable ? Colors.grey.shade600 : const Color(0xFF3B82F6),
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                ),
        ),
      ],
    );
  }

  IconData _getArchiveIconData(String type) {
    switch (type) {
      case 'vault':
        return Icons.inventory_2;
      case 'file':
        return Icons.insert_drive_file;
      case 'note':
        return Icons.sticky_note_2;
      case 'journal':
        return Icons.book;
      default:
        return Icons.archive;
    }
  }

  Color _getArchiveColor(ArchiveState st) {
    switch (st) {
      case ArchiveState.ColdStorage:
        return const Color(0xFF3B82F6);
      case ArchiveState.LongTerm:
        return const Color(0xFFF59E0B);
      case ArchiveState.Historical:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  // SUB-TAB 2: Deep Search Matrix
  Widget _buildDeepSearchMatrixTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper Tips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Color(0xFF3B82F6), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locVal(
                    'Multi-Quadrant Cross Search: Access decrypted system memory. Queries Vaults, Notes, Journals, Media, and Cold Archives simultaneously.',
                    'مصفوفة بحث كوانتومية رباعية الاتجاهات لفحص ذاكرة الأجهزة والملفات والأرشيف والأصول المشفرة.',
                  ),
                  style: const TextStyle(fontSize: 8.5, color: Colors.grey, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Live Search Input Box
        SizedBox(
          height: 38,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF3B82F6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 12, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _triggerSearch('');
                      },
                    )
                  : null,
              labelText: _locVal('Initiate deep query matrix...', 'اكتب لبدء الاستعلام الموحد للعمق...'),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 9.5),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
            ),
            onChanged: _triggerSearch,
          ),
        ),

        const SizedBox(height: 12),

        // Result Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_locVal('SYSTEM ENTRIES LOCATED', 'نتائج الاستدلال الموحد')}: ${_searchResults.length}',
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'monospace'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(
          child: _searchQuery.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.travel_explore, color: Colors.grey, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        _locVal('Ready. Input a search token above.', 'بانتظار المدخلات لمسح القطاعات المشهودة.'),
                        style: const TextStyle(color: Colors.grey, fontSize: 9.5),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.report_problem, color: Colors.grey, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            _locVal('No matches across decrypted buffers.', 'لم يتم العثور على أي تطابق في مساحات الذاكرة والمخازن.'),
                            style: const TextStyle(color: Colors.grey, fontSize: 9.5),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, idx) {
                        final r = _searchResults[idx];
                        return Card(
                          color: const Color(0xFF0F172A),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withOpacity(0.02)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getSearchTypeColor(r.type).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getSearchTypeIcon(r.type),
                                  color: _getSearchTypeColor(r.type),
                                  size: 14,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.type.toUpperCase(),
                                      style: TextStyle(color: _getSearchTypeColor(r.type), fontSize: 6.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.subtitle,
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.details,
                                      style: const TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${r.relevanceScore.toStringAsFixed(1)}',
                                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      _locVal('SCORE', 'الأثر'),
                                      style: const TextStyle(color: Colors.grey, fontSize: 5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
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

  Color _getSearchTypeColor(String type) {
    switch (type) {
      case 'vault':
        return const Color(0xFF3B82F6);
      case 'file':
        return const Color(0xFF10B981);
      case 'note':
        return const Color(0xFFA855F7);
      case 'journal':
        return const Color(0xFFF59E0B);
      case 'archive':
        return const Color(0xFFF43F5E);
      default:
        return Colors.grey;
    }
  }

  IconData _getSearchTypeIcon(String type) {
    switch (type) {
      case 'vault':
        return Icons.inventory_2;
      case 'file':
        return Icons.insert_drive_file;
      case 'note':
        return Icons.sticky_note_2;
      case 'journal':
        return Icons.book;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.info_outline;
    }
  }
}

// Draw dynamic circle charts (Material state score gauges)
class HealthGaugePainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final Color fillColor;

  HealthGaugePainter({
    required this.score,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    double sweepAngle = (2 * math.pi) * (score / 100.0);
    // Draw starting from top
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HealthGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

// Draw partitioned bars (Cold, Long-term, Historical archives distribution)
class PartitionBarPainter extends CustomPainter {
  final int cold;
  final int longTerm;
  final int historical;
  final int empty;

  PartitionBarPainter({
    required this.cold,
    required this.longTerm,
    required this.historical,
    required this.empty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = cold + longTerm + historical + empty;
    if (total == 0) return;

    final double width = size.width;
    final double height = size.height;

    final double coldW = width * (cold / total);
    final double longW = width * (longTerm / total);
    final double histW = width * (historical / total);
    final double emptyW = width * (empty / total);

    final Paint p = Paint()..style = PaintingStyle.fill;

    double curX = 0.0;

    if (coldW > 0) {
      p.color = const Color(0xFF3B82F6);
      canvas.drawRect(Rect.fromLTWH(curX, 0, coldW, height), p);
      curX += coldW;
    }

    if (longW > 0) {
      p.color = const Color(0xFFF59E0B);
      canvas.drawRect(Rect.fromLTWH(curX, 0, longW, height), p);
      curX += longW;
    }

    if (histW > 0) {
      p.color = const Color(0xFF10B981);
      canvas.drawRect(Rect.fromLTWH(curX, 0, histW, height), p);
      curX += histW;
    }

    if (emptyW > 0) {
      p.color = Colors.grey.shade900;
      canvas.drawRect(Rect.fromLTWH(curX, 0, emptyW, height), p);
    }
  }

  @override
  bool shouldRepaint(covariant PartitionBarPainter oldDelegate) {
    return oldDelegate.cold != cold || oldDelegate.longTerm != longTerm || oldDelegate.historical != historical || oldDelegate.empty != empty;
  }
}
