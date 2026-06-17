import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../utils/vault_service.dart';
import '../utils/nexus_service.dart';
import '../models/nexus.dart';

class NexusDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const NexusDashboardWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<NexusDashboardWidget> createState() => _NexusDashboardWidgetState();
}

class _NexusDashboardWidgetState extends State<NexusDashboardWidget> with SingleTickerProviderStateMixin {
  final NexusService _nexusService = NexusService();
  final VaultService _vaultService = VaultService();

  // Active view tab: 0 = Graph, 1 = Explorer, 2 = Insights
  int _subTabIndex = 0;

  // Selected asset from graph
  String? _selectedAssetId;

  // Search filter
  String _searchQuery = '';

  // Link form states
  String? _formSourceId;
  String? _formTargetId;
  String _formRelation = 'reference';
  final TextEditingController _formDescCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nexusService.addListener(_onNexusChanged);
    _vaultService.addListener(_onVaultChanged);

    // Dynamic initial registration of file/vault elements to the relationship pool
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSync();
    });
  }

  @override
  void dispose() {
    _nexusService.removeListener(_onNexusChanged);
    _vaultService.removeListener(_onVaultChanged);
    _formDescCtrl.dispose();
    super.dispose();
  }

  void _onNexusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onVaultChanged() {
    if (mounted) {
      setState(() {
        _triggerSync();
      });
    }
  }

  void _triggerSync() {
    // Collect all in-memory assets and update Nexus catalogs
    _nexusService.notifyListeners();
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _establishConnection() {
    if (_formSourceId == null || _formTargetId == null) {
      widget.onSuccess(
        _locVal('Select both Source and Target assets!', 'يرجى تحديد الأصول البرمجية المصدر والهدف لتأمين المسار!'),
        'error',
      );
      return;
    }

    if (_formSourceId == _formTargetId) {
      widget.onSuccess(
        _locVal('Connection must be between two distinct assets.', 'لا يمكن ربط الأصل البرمجي بنفسه!'),
        'error',
      );
      return;
    }

    final assets = _nexusService.getAvailableAssets();
    final source = assets.firstWhere((a) => a.id == _formSourceId);
    final target = assets.firstWhere((a) => a.id == _formTargetId);

    _nexusService.addLink(
      sourceId: source.id,
      sourceType: source.type,
      sourceName: source.name,
      targetId: target.id,
      targetType: target.type,
      targetName: target.name,
      relationType: _formRelation,
      description: _formDescCtrl.text.trim(),
    );

    widget.onSecurityLog(
      'Nexus Relationship Established',
      'success',
      'Unified relationship: "${source.name}" <--[${_formRelation.toUpperCase()}]--> "${target.name}".',
    );

    widget.onSuccess(
      _locVal('Nexus established security coherence successfully.', 'تم تشفير وتأمين مسار الترابط المزدوج بنجاح!'),
      'success',
    );

    setState(() {
      _formDescCtrl.clear();
      _formSourceId = null;
      _formTargetId = null;
    });
  }

  void _severConnection(String linkId) {
    final link = _nexusService.links.firstWhere((l) => l.id == linkId);
    _nexusService.deleteLink(linkId);

    widget.onSecurityLog(
      'Nexus Connection Severed',
      'warning',
      'Severed relationship: "${link.sourceName}" <--x--> "${link.targetName}".',
    );

    widget.onSuccess(
      _locVal('Relational linkage disconnected successfully.', 'تم تدمير وفك مسار الترابط ونقاط الوصول بنجاح!'),
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: const Color(0xFF030712), // neutral-950
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Headings Banner
            _buildHeadingBanner(),

            const SizedBox(height: 12),

            // Inside navigation tabs
            _buildSubTabBar(),

            const SizedBox(height: 12),

            // Main Content Area matching subTabIndex
            Expanded(
              child: ClipRect(
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadingBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1B4B), // Indigo dark
            const Color(0xFF111827).withOpacity(0.5)
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub, color: Color(0xFFA855F7), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _locVal('RIMAN NEXUS', 'وحدة الترابط السيادي ريمان'),
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
                        color: const Color(0xFF06B6D4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'v11.0',
                        style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locVal(
                    'Multi-layer intelligence mapping secure links between accounts, modules, and logs.',
                    'شبكة ترابط كوانتومية ذكية لمراقبة مسارات وتفاصيل الأصول المشفرة وبياناتها البيئية.',
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

  Widget _buildSubTabBar() {
    final tabs = [
      {'icon': Icons.bubble_chart, 'label': _locVal('Interactive Graph', 'الرسم البياني كمي')},
      {'icon': Icons.swap_horiz, 'label': _locVal('Links database', 'قاعدة البيانات')},
      {'icon': Icons.psychology, 'label': _locVal('Smart Heuristics', 'التحليل الذكي والحلول')},
    ];

    return Row(
      children: List.generate(tabs.length, (idx) {
        final item = tabs[idx];
        final isSelected = _subTabIndex == idx;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _subTabIndex = idx;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                right: idx == tabs.length - 1 ? 0 : 4,
                left: idx == 0 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFFA855F7) : Colors.white.withOpacity(0.02),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 12,
                    color: isSelected ? const Color(0xFFA855F7) : Colors.grey,
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
    );
  }

  Widget _buildMainContent() {
    switch (_subTabIndex) {
      case 0:
        return _buildInteractiveGraphView();
      case 1:
        return _buildLinksExplorerView();
      case 2:
        return _buildSecurityHeuristicsView();
      default:
        return const SizedBox();
    }
  }

  // Interactive Graph View Screen
  Widget _buildInteractiveGraphView() {
    final assets = _nexusService.getAvailableAssets();
    final links = _nexusService.links;

    return Column(
      children: [
        // Helper tips
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF06B6D4), size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locVal(
                    'Interactive Map: Tap any coordinate node to explore its bidirectional relationship matrix.',
                    'مخطط تفاعلي: انقر على أي أصل لعرض مسار البيانات وعلاقاته الثنائية المشفرة.',
                  ),
                  style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),

        // Interactive Graph Canvas Screen
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size size = Size(constraints.maxWidth, constraints.maxHeight);
                final positions = _getNodePositions(assets, size);

                return GestureDetector(
                  onTapUp: (details) {
                    _handleGraphTap(details.localPosition, size);
                  },
                  child: Stack(
                    children: [
                      // Canvas painting nodes/edges
                      CustomPaint(
                        size: size,
                        painter: NexusGraphPainter(
                          assets: assets,
                          links: links,
                          positions: positions,
                          selectedId: _selectedAssetId,
                        ),
                      ),

                      // Floating key indicators
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIndicatorBadge('Vault', const Color(0xFF06B6D4)),
                              _buildIndicatorBadge('File', const Color(0xFF10B981)),
                              _buildIndicatorBadge('Note', const Color(0xFFA855F7)),
                              _buildIndicatorBadge('Journal', const Color(0xFFF59E0B)),
                              _buildIndicatorBadge('Capsule/Other', const Color(0xFFF43F5E)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Graph item detail sheet (if selected)
        _buildGraphDetailPanel(),
      ],
    );
  }

  Map<String, Offset> _getNodePositions(List<NexusAsset> assets, Size size) {
    final Map<String, Offset> positions = {};
    if (assets.isEmpty) return positions;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    // Strict margin scaling
    final double radius = math.min(size.width, size.height) * 0.35;

    for (int i = 0; i < assets.length; i++) {
      final double angle = (2 * math.pi * i) / assets.length;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);
      positions[assets[i].id] = Offset(x, y);
    }
    return positions;
  }

  void _handleGraphTap(Offset localPos, Size size) {
    final assets = _nexusService.getAvailableAssets();
    final positions = _getNodePositions(assets, size);

    String? tappedId;
    double minDistance = 24.0; // hit tolerance bounds

    positions.forEach((id, offset) {
      final dist = (localPos - offset).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tappedId = id;
      }
    });

    if (tappedId != _selectedAssetId) {
      setState(() {
        _selectedAssetId = tappedId;
      });
      if (tappedId != null) {
        final selectedAsset = assets.firstWhere((a) => a.id == tappedId);
        widget.onSecurityLog(
          'Nexus Matrix Target Audited',
          'info',
          'Auditing coordinates for selected secure module: "${selectedAsset.name}" [${selectedAsset.type.toUpperCase()}].',
        );
      }
    }
  }

  Widget _buildIndicatorBadge(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 7.5, color: Colors.grey, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildGraphDetailPanel() {
    if (_selectedAssetId == null) {
      return Container(
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        alignment: Alignment.center,
        child: Text(
          _locVal('Select a node above to audit relations', 'يرجى تحديد نقطة توافق بالأعلى لبدء الفحص المتبادل'),
          style: const TextStyle(color: Colors.grey, fontSize: 9.5),
        ),
      );
    }

    final assets = _nexusService.getAvailableAssets();
    final asset = assets.firstWhere((a) => a.id == _selectedAssetId, orElse: () => assets[0]);
    final links = _nexusService.getLinksForAsset(asset.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNodeColor(asset.type).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.type.toUpperCase(),
                            style: TextStyle(color: _getNodeColor(asset.type), fontSize: 7.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            asset.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.details,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 8.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 14),
                onPressed: () {
                  setState(() {
                    _selectedAssetId = null;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 12, color: Colors.white10),

          // Coherence linkages
          Text(
            _locVal('COHERENT CHANNELS (${links.length})', 'القنوات والاتصالات المتزامنة (${links.length})'),
            style: const TextStyle(color: Color(0xFFA855F7), fontSize: 7.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          links.isEmpty
              ? Text(
                  _locVal('No direct security relationship links.', 'لم يتم إنشاء أي قنوات ربط لهذا الملف حتى الآن.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 8.5),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: links.length,
                  itemBuilder: (context, idx) {
                    final l = links[idx];
                    final partnerName = l.sourceId == asset.id ? l.targetName : l.sourceName;
                    final partnerType = l.sourceId == asset.id ? l.targetType : l.sourceType;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Color(0xFF06B6D4), size: 10),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _getNodeColor(partnerType).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    partnerType.toUpperCase(),
                                    style: TextStyle(color: _getNodeColor(partnerType), fontSize: 6.5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    partnerName,
                                    style: const TextStyle(fontSize: 8.5, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l.relationType.toUpperCase(),
                              style: const TextStyle(color: Color(0xFFA855F7), fontSize: 6.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Base list & CRUD form to setup links
  Widget _buildLinksExplorerView() {
    final assets = _nexusService.getAvailableAssets();
    final links = _nexusService.links;

    // Filtered relationships list matching user inputs
    final filteredLinks = links.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.sourceName.toLowerCase().contains(q) ||
          l.targetName.toLowerCase().contains(q) ||
          l.relationType.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two pane: top forms and bottom list
        _buildCreateLinkFormPanel(assets),

        const SizedBox(height: 12),

        // List Header / Search Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _locVal('NEXUS ACTIVE CONNECTIONS', 'سجل الاتصالات والروابط النشطة'),
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(
              width: 140,
              height: 24,
              child: TextField(
                style: const TextStyle(fontSize: 9.5, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  prefixIcon: const Icon(Icons.filter_list, size: 10, color: Colors.grey),
                  hintText: _locVal('Filter database...', 'ابحث في السجلات...'),
                  hintStyle: const TextStyle(fontSize: 8.5, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(
          child: filteredLinks.isEmpty
              ? Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Text(
                    _locVal('No active security relationships mapped.', 'قاعدة بيانات الطيف خالية من روابط العلاقات الجارية.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredLinks.length,
                  itemBuilder: (context, idx) {
                    final l = filteredLinks[idx];
                    return Card(
                      color: const Color(0xFF090D16),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                                      _buildCompactAssetBadge(l.sourceName, l.sourceType),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_right_alt, color: Color(0xFF06B6D4), size: 12),
                                      const SizedBox(width: 4),
                                      _buildCompactAssetBadge(l.targetName, l.targetType),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA855F7).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l.relationType.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFFA855F7), fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            if (l.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                l.description,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 8),
                              ),
                            ],
                            const Divider(height: 10, color: Colors.white10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _locVal(
                                    'Securely aligned: ${l.createdAt.day}/${l.createdAt.month}/${l.createdAt.year}',
                                    'تاريخ الربط السيادي: ${l.createdAt.day}/${l.createdAt.month}/${l.createdAt.year}',
                                  ),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 7.5),
                                ),
                                InkWell(
                                  onTap: () => _severConnection(l.id),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_sweep, color: Colors.pink, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        _locVal('Sever', 'فسخ الرابط'),
                                        style: const TextStyle(color: Colors.pink, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
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

  Widget _buildCompactAssetBadge(String name, String type) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _getNodeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: TextStyle(color: _getNodeColor(type), fontSize: 7.5, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCreateLinkFormPanel(List<NexusAsset> assets) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _locVal('ESTABLISH NEW SECURE NEXUS CHANNEL', 'مزامنة وتجذير قناة ربط أصل تزامنية جديدة'),
            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 8.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Side-by-Side Dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 9.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      filled: true,
                      fillColor: Colors.black26,
                      labelText: _locVal('Source Asset', 'الموقع الأول (المرابط)'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    value: _formSourceId,
                    items: assets.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('[${a.type.toUpperCase()}] ${a.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _formSourceId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.sync_alt, color: Colors.grey, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 9.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      filled: true,
                      fillColor: Colors.black26,
                      labelText: _locVal('Target Asset', 'الموقع الثاني (المربوط)'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    value: _formTargetId,
                    items: assets.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('[${a.type.toUpperCase()}] ${a.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _formTargetId = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9.5, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      labelText: _locVal('Relationship Type', 'نمط وأثر الترابط الميكانيكي'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    value: _formRelation,
                    items: [
                      DropdownMenuItem(value: 'sync', child: Text(_locVal('SYNCHRONIZED CONNECTION', 'مزامنة ثنائية خط الترابط'))),
                      DropdownMenuItem(value: 'extends', child: Text(_locVal('MODULE EXTENSION', 'تمديد وتحديث تكميلي لبيانات'))),
                      DropdownMenuItem(value: 'backup', child: Text(_locVal('RECOVERY BACKUP ANCHOR', 'ارتكاز نسخ احتياطي طارئ'))),
                      DropdownMenuItem(value: 'reference', child: Text(_locVal('DATA PIVOT REFERENCE', 'مرجع وصفي للبحث المشترك'))),
                      DropdownMenuItem(value: 'credentials', child: Text(_locVal('CREDENTIAL AUTHORIZATION', 'فحص أمان التحقق والترخيص'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _formRelation = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _formDescCtrl,
                    style: const TextStyle(fontSize: 9.5, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      labelText: _locVal('Core description logs...', 'ملاحظات وسجلات الوصف...'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 8.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _establishConnection,
                child: Text(
                  _locVal('LINK', 'ربط'),
                  style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Smart insights diagnostics view
  Widget _buildSecurityHeuristicsView() {
    final orphanAssets = _nexusService.getOrphanAssets();
    final connectedAssets = _nexusService.getConnectedAssets();
    final recoveryAssets = _nexusService.getRecoveryCriticalAssets();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Diagnostics Summary
          _buildInsightHeuristicHeads(orphanAssets.length, connectedAssets.length, recoveryAssets.length),

          const SizedBox(height: 12),

          // Section 1: Recovery Critical Audit Check
          _buildDiagnosticSection(
            title: _locVal('RECOVERY CRITICAL ASSETS AUDIT', 'تدقيق وفحص أصول الطوارئ الحيوية'),
            description: _locVal(
              'Identifies recovery codes, backup seeds, and master keys that need relational binding to preserve secure reference histories.',
              'تحليل دقيق لوثائق النسخ وسجلات الاسترداد وكلمات السر لربطها بمسارات حيوية تمنع الفقدان.',
            ),
            assets: recoveryAssets,
            isRecovery: true,
          ),

          const SizedBox(height: 12),

          // Section 2: Isolated/Orphan Files
          _buildDiagnosticSection(
            title: _locVal('ISOLATED ORPHAN FILES', 'الملفات والأصول المعزولة (غير المرتبطة)'),
            description: _locVal(
              'Identifies files that exist alone without metadata references or corresponding journaling. Linking them increases contextual search safety.',
              'ملفات مخزنة وحدها ليس لها أي سجل ترابط وصفي أو مرجعي. يفضل ربطها بمسودات مفيدة لحمايتها.',
            ),
            assets: orphanAssets,
            isRecovery: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightHeuristicHeads(int orphans, int connected, int critical) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF06B6D4), size: 14),
              const SizedBox(width: 8),
              Text(
                _locVal('SYSTEM DIAGNOSTIC HEURISTICS', 'قراءة المؤشرات والذكاء البيئي'),
                style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeuristicCell(
                orphans > 0 ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                orphans.toString(),
                _locVal('Orphans Detect', 'الأصول المعزولة'),
              ),
              _buildHeuristicCell(
                const Color(0xFF06B6D4),
                connected.toString(),
                _locVal('Nodes Hooked', 'الأصول المترابطة'),
              ),
              _buildHeuristicCell(
                critical > 0 ? const Color(0xFFF59E0B) : Colors.grey,
                critical.toString(),
                _locVal('Critical Tracked', 'الاسترداد فائق'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeuristicCell(Color mainColor, String value, String subtitle) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainColor, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 7.5, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDiagnosticSection({
    required String title,
    required String description,
    required List<NexusAsset> assets,
    required bool isRecovery,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: isRecovery ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 8, color: Colors.grey, height: 1.3),
          ),
          const Divider(height: 12, color: Colors.white10),

          assets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                      const SizedBox(width: 8),
                      Text(
                        _locVal('Clean. System standard integrity fully satisfied.', 'نظيف بالكامل. جودة المعايير والترابط مستقرة ومثالية!'),
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 8),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assets.length > 5 ? 5 : assets.length,
                  itemBuilder: (context, idx) {
                    final item = assets[idx];
                    final hasConnection = _nexusService.links.any((l) => l.sourceId == item.id || l.targetId == item.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getNodeIconData(item.type),
                            color: _getNodeColor(item.type),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  item.details,
                                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Recommendation badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasConnection ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF43F5E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasConnection ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFF43F5E).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              hasConnection
                                  ? _locVal('SECURE REFERENCE', 'ترابط معتمد')
                                  : (isRecovery ? _locVal('UNLINKED SEED', 'مفتاح غير مؤمن') : _locVal('SOLITARY / ORPHAN', 'معزول مفرط')),
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: hasConnection ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// Draw futuristic relational map network layout
class NexusGraphPainter extends CustomPainter {
  final List<NexusAsset> assets;
  final List<NexusLink> links;
  final Map<String, Offset> positions;
  final String? selectedId;

  NexusGraphPainter({
    required this.assets,
    required this.links,
    required this.positions,
    required this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (assets.isEmpty) return;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // 1. Draw central orbit core ring
    final Paint ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final double mainRadius = math.min(size.width, size.height) * 0.35;
    canvas.drawCircle(Offset(centerX, centerY), mainRadius, ringPaint);
    canvas.drawCircle(Offset(centerX, centerY), mainRadius * 0.5, ringPaint);

    // 2. Draw linkage lines
    for (var l in links) {
      final pSrc = positions[l.sourceId];
      final pTgt = positions[l.targetId];

      if (pSrc != null && pTgt != null) {
        final isHighlighted = selectedId == l.sourceId || selectedId == l.targetId;

        final Paint linePaint = Paint()
          ..color = isHighlighted
              ? const Color(0xFFA855F7).withOpacity(0.6)
              : Colors.white.withOpacity(0.08)
          ..strokeWidth = isHighlighted ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(pSrc, pTgt, linePaint);

        // Draw small flow arrow/node mid-way
        if (isHighlighted) {
          final mid = Offset((pSrc.dx + pTgt.dx) / 2, (pSrc.dy + pTgt.dy) / 2);
          final Paint flowPaint = Paint()
            ..color = const Color(0xFF06B6D4)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(mid, 3.0, flowPaint);
        }
      }
    }

    // 3. Draw asset nodes
    for (var asset in assets) {
      final pos = positions[asset.id];
      if (pos == null) continue;

      final isSelected = selectedId == asset.id;
      final Color nodeColor = _getNodeColor(asset.type);

      // Node background shadow ring
      final Paint glowPaint = Paint()
        ..color = nodeColor.withOpacity(isSelected ? 0.35 : 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isSelected ? 15.0 : 10.0, glowPaint);

      // Node solid fill dot
      final Paint solidPaint = Paint()
        ..color = Color.lerp(nodeColor, Colors.black, isSelected ? 0.1 : 0.3) ?? nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isSelected ? 8.0 : 5.0, solidPaint);

      // Node border ring
      final Paint borderPaint = Paint()
        ..color = isSelected ? const Color(0xFFA855F7) : nodeColor.withOpacity(0.7)
        ..strokeWidth = isSelected ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, isSelected ? 8.0 : 5.0, borderPaint);

      // 4. Draw node label text carefully to prevent overflow issues
      final String shortName = asset.name.length > 10 ? '${asset.name.substring(0, 10)}..' : asset.name;
      final textSpan = TextSpan(
        text: shortName,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade400,
          fontFamily: 'monospace',
          fontSize: isSelected ? 8.0 : 7.0,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // offset computation centered below node dot
      final double labelY = pos.dy + (isSelected ? 10.0 : 7.0);
      final double labelX = pos.dx - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant NexusGraphPainter oldDelegate) {
    return oldDelegate.assets.length != assets.length ||
        oldDelegate.links.length != links.length ||
        oldDelegate.selectedId != selectedId;
  }
}

Color _getNodeColor(String type) {
  switch (type) {
    case 'vault':
      return const Color(0xFF06B6D4); // Cyan
    case 'file':
      return const Color(0xFF10B981); // Emerald / Green
    case 'note':
      return const Color(0xFFA855F7); // Purple
    case 'journal':
      return const Color(0xFFF59E0B); // Amber
    default:
      return const Color(0xFFF43F5E); // Rose
  }
}

IconData _getNodeIconData(String type) {
  switch (type) {
    case 'vault':
      return Icons.security;
    case 'file':
      return Icons.insert_drive_file;
    case 'note':
      return Icons.text_snippet;
    case 'journal':
      return Icons.book;
    case 'capsule':
      return Icons.lock_clock;
    default:
      return Icons.tag;
  }
}
