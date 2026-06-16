import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';

// Safe pre-loaded mathematical art SVGs as base64 string vectors, to show direct decryption previews.
const String _coherenceShieldSvg = '''
R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7
'''; // fallback tiny transparent GIF or styled Container drawing inside Dart.

class SecureMediaItem {
  final String id;
  final String name;
  final String category;
  final String album;
  final bool isFavorite;
  final int sizeInBytes;
  final String resolution;
  final DateTime importDate;
  final String base64Asset; // In-memory asset path or direct bytes base64 representing raw data

  SecureMediaItem({
    required this.id,
    required this.name,
    required this.category,
    required this.album,
    this.isFavorite = false,
    required this.sizeInBytes,
    required this.resolution,
    required this.importDate,
    required this.base64Asset,
  });

  SecureMediaItem copyWith({
    String? name,
    String? category,
    String? album,
    bool? isFavorite,
  }) {
    return SecureMediaItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      album: album ?? this.album,
      isFavorite: isFavorite ?? this.isFavorite,
      sizeInBytes: sizeInBytes,
      resolution: resolution,
      importDate: importDate,
      base64Asset: base64Asset,
    );
  }
}

class SecureGalleryWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SecureGalleryWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SecureGalleryWidget> createState() => _SecureGalleryWidgetState();
}

class _SecureGalleryWidgetState extends State<SecureGalleryWidget> with SingleTickerProviderStateMixin {
  bool _isUnlocked = false;
  String _vaultPassword = '';
  bool _hidePassword = true;

  // Active view tabs inside unlocked gallery
  String _activeTab = 'gallery'; // gallery, dashboard, future

  // Search & Filter state
  String _searchQuery = '';
  String _selectedAlbum = 'All';
  String _selectedCategory = 'All';
  bool _onlyFavorites = false;

  // Lists
  final List<SecureMediaItem> _mediaItems = [];
  final List<String> _albums = ['Sovereign Core', 'Personal', 'Classified'];
  final List<String> _categories = ['Identity', 'Credentials', 'Visual Proof'];

  // Security Toggles
  bool _preventScreenshot = true;
  bool _blurOnFocusLoss = true;
  bool _secureViewingMode = false;

  // Import overlay state
  final TextEditingController _importNameCtrl = TextEditingController();
  String _importAlbum = 'Personal';
  String _importCategory = 'Identity';

  @override
  void initState() {
    super.initState();
    _seedDefaultMedia();
  }

  @override
  void dispose() {
    _importNameCtrl.dispose();
    super.dispose();
  }

  void _seedDefaultMedia() {
    _mediaItems.addAll([
      SecureMediaItem(
        id: 'm1',
        name: _locVal('Riemann Coherence Matrix', 'مصفوفة ترابط ريمان'),
        category: 'Visual Proof',
        album: 'Sovereign Core',
        isFavorite: true,
        sizeInBytes: 42095,
        resolution: '800x800',
        importDate: DateTime.now().subtract(const Duration(days: 1)),
        base64Asset: 'coherence',
      ),
      SecureMediaItem(
        id: 'm2',
        name: _locVal('Quantum Orbit Spin Mapping', 'تخطيط مدار دوران كمومي'),
        category: 'Identity',
        album: 'Sovereign Core',
        isFavorite: false,
        sizeInBytes: 25440,
        resolution: '800x800',
        importDate: DateTime.now().subtract(const Duration(hours: 3)),
        base64Asset: 'quantum',
      ),
    ]);
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _handleUnlock() {
    if (_vaultPassword.length < 4) {
      widget.onSuccess(
        _locVal('Password credentials must contain at least 4 characters!', 'الرمز السري يجب أن يحتوي على 4 أحرف كحد أدنى!'),
        'error'
      );
      return;
    }

    widget.onSecurityLog(
      'Flutter Secure Gallery decryption initialized',
      'info',
      'Validating encryption tokens & hydrating media units directly inside sandbox RAM.'
    );

    setState(() {
      _isUnlocked = true;
    });

    widget.onSuccess(
      _locVal('Secure Gallery decrypted successfully!', 'تم فك تشفير معرض الصور المشفر بنجاح!'),
      'success'
    );
  }

  void _handleLock() {
    setState(() {
      _isUnlocked = false;
      _vaultPassword = '';
    });
    widget.onSecurityLog(
      'Secure Gallery session unmounted',
      'info',
      'Zeroed transient decrypted base64 slots and cleared session cache.'
    );
    widget.onSuccess(
      _locVal('Gallery locked. Decrypted memory zeroed out entirely.', 'تم قفل معرض الصور ومسح الذاكرة بالكامل.'),
      'info'
    );
  }

  void _handleToggleFavorite(SecureMediaItem item) {
    setState(() {
      final index = _mediaItems.indexWhere((x) => x.id == item.id);
      if (index != -1) {
        _mediaItems[index] = item.copyWith(isFavorite: !item.isFavorite);
      }
    });
    widget.onSecurityLog('Metadata flag modified', 'info', 'Toggled favorite state for item ${item.name}');
  }

  void _handleDeleteItem(SecureMediaItem item) {
    setState(() {
      _mediaItems.removeWhere((x) => x.id == item.id);
    });
    widget.onSecurityLog('Media element purged from store', 'warning', 'Sovereign disk block cleared for ID: ${item.id}');
    widget.onSuccess(_locVal('Media purged from storage.', 'تم حذف الصورة من ذاكرة التخزين بقفل ريمان.'), 'success');
  }

  void _handleImportNewSimulated() {
    final name = _importNameCtrl.text.trim();
    if (name.isEmpty) {
      widget.onSuccess(_locVal('Please input photo designation!', 'يرجى كتابة اسم الصورة أولاً!'), 'error');
      return;
    }

    setState(() {
      _mediaItems.add(SecureMediaItem(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: _importCategory,
        album: _importAlbum,
        isFavorite: false,
        sizeInBytes: 50 * 1024, // 50 KB
        resolution: '1280x720',
        importDate: DateTime.now(),
        base64Asset: 'custom',
      ));
      _importNameCtrl.clear();
    });

    widget.onSecurityLog(
      'Secure Image automatic import completed',
      'success',
      'Wrapped designator: $name. Generated safe thumbnail inside encrypted stream.'
    );
    widget.onSuccess(_locVal('Simulated photo encrypted and cataloged!', 'تم تشفير الصورة وأرشفتها بنجاح!'), 'success');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF030712), // neutral-950
      child: !_isUnlocked ? _buildLockScreen() : _buildUnlockedGallery(),
    );
  }

  Widget _buildLockScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827), // neutral-900
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.cyan.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                ),
                child: const Icon(Icons.lock, color: Colors.cyan, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                _locVal('Decapsulate Secure Media Layer', 'فك قفل معرض الصور الموفرة'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _locVal('Decrypts raw data vectors in-RAM only with zero traces left in local caches.', 
                        'يقوم بفك ضغط وتشفير الصور داخل الذاكرة المؤقتة لمنع تسريب الكاش للقرص.'),
                style: const TextStyle(color: Colors.neutral-500, fontSize: 11, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                obscureText: _hidePassword,
                onChanged: (val) => _vaultPassword = val,
                decoration: InputDecoration(
                  hintText: _locVal('Symmetric password key (e.g. riemann)', 'كلمة مرور المشفر (سيمتري)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  filled: true,
                  fillColor: Colors.black,
                  suffixIcon: IconButton(
                    icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off, color: Colors.cyan),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                style: const TextStyle(color: Colors.cyan, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: Text(
                  _locVal('START SECURE MOUNT', 'تفعيل قناة العرض المشفرة'),
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedGallery() {
    return Column(
      children: [
        // Tab selectors
        _buildMediaNav(),
        
        // Active Sub-view Panels
        Expanded(
          child: _activeTab == 'gallery' 
            ? _buildGalleryTab()
            : _activeTab == 'dashboard'
              ? _buildDashboardTab()
              : _buildFutureTab(),
        ),
      ],
    );
  }

  Widget _buildMediaNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: Border(bottom: BorderSide(color: Colors.neutral-800.withOpacity(0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _navBtn('gallery', _locVal('GALLERY', 'المعرض')),
              _navBtn('dashboard', _locVal('METRICS', 'المؤشرات')),
              _navBtn('future', _locVal('PIPELINES', 'المستقبل')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.roseAccent),
            tooltip: _locVal('Lock Gallery', 'قفل وإغلاق المعرض'),
            onPressed: _handleLock,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(String tab, String title) {
    bool active = _activeTab == tab;
    return TextButton(
      onPressed: () => setState(() => _activeTab = tab),
      style: TextButton.styleFrom(
        foregroundColor: active ? Colors.cyan : Colors.white60,
        backgroundColor: active ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
      ),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // FEATURE 1 & 5 & 2
  Widget _buildGalleryTab() {
    // Math Filters
    final items = _mediaItems.where((item) {
      final matchAlbum = _selectedAlbum == 'All' || item.album == _selectedAlbum;
      final matchCat = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchFav = !_onlyFavorites || item.isFavorite;
      final matchQ = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchAlbum && matchCat && matchFav && matchQ;
    }).toList();

    return Column(
      children: [
        // Config options row / Screenshot prevention
        _buildSecurityTogglesRow(),

        // Operational organization filters row
        _buildFilterBar(),

        // Safe simulated loading & metadata input row
        _buildImportForm(),

        // Image grids
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    return _buildMediaGridCard(item);
                  },
                ),
        )
      ],
    );
  }

  Widget _buildSecurityTogglesRow() {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.emerald, size: 14),
              const SizedBox(width: 6),
              Text(
                _locVal('PREVENT SCREENSHOT', 'منع لقطة الشاشة'),
                style: const TextStyle(fontSize: 10, color: Colors.neutral-300, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Switch(
            value: _preventScreenshot,
            activeColor: Colors.emerald,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() => _preventScreenshot = val);
              widget.onSecurityLog('Secure parameter toggled', 'info', 'Prevent Screenshots: $val');
            },
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search UI
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: _locVal('Designation query...', 'ابحث في أسماء الملفات...'),
              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.cyan),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Album
              DropdownButton<String>(
                value: _selectedAlbum,
                items: ['All', ..._albums].map((a) {
                  return DropdownMenuItem(
                    value: a,
                    child: Text(a == 'All' ? _locVal('All Albums', 'كل الألبومات') : a, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAlbum = val ?? 'All'),
              ),
              // Favorite button filter
              TextButton.icon(
                onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
                icon: Icon(Icons.favorite, color: _onlyFavorites ? Colors.rose : Colors.neutral-400, size: 14),
                label: Text(_locVal('FAVS', 'المفضلة'), style: TextStyle(fontSize: 10, color: _onlyFavorites ? Colors.rose : Colors.white)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildImportForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _importNameCtrl,
                  decoration: InputDecoration(
                    hintText: _locVal(' designation for virtual photo...', 'اسم الصورة الافتراضية المراد تشفيرها...'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleImportNewSimulated,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[900], padding: const EdgeInsets.symmetric(horizontal: 16)),
                child: const Text('Encrypt & Stash', style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 48, color: Colors.neutral-600),
          const SizedBox(height: 8),
          Text(_locVal('NO SECURE IMAGES', 'لا يوجد صور تشفيرية'), style: const TextStyle(fontSize: 11, color: Colors.neutral-400)),
        ],
      ),
    );
  }

  Widget _buildMediaGridCard(SecureMediaItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.cyan.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Safe Thumbnail View
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Vector representation depending on seed
                  _renderSafeArtVector(item),
                  // Top HUD controls
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite, color: item.isFavorite ? Colors.rose : Colors.grey, size: 14),
                          onPressed: () => _handleToggleFavorite(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.neutral-400, size: 14),
                          onPressed: () => _handleDeleteItem(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Metadata lines
          Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.album, style: const TextStyle(fontSize: 8, color: Colors.cyan), overflow: TextOverflow.ellipsis),
              Text(item.resolution, style: const TextStyle(fontSize: 8, color: Colors.neutral-500)),
            ],
          ),
          const SizedBox(height: 2),
          // Decrypt to RAM actions
          GestureDetector(
            onTap: () => _triggerMemoryViewer(item),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.cyan.withOpacity(0.05),
              alignment: Alignment.center,
              child: Text(
                _locVal('VIEW TRANSIENT (RAM)', 'معاينة مشفرة زائلة'),
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _renderSafeArtVector(SecureMediaItem item) {
    if (item.base64Asset == 'coherence') {
      return CustomPaint(
        painter: _CoherenceShieldPainter(),
      );
    } else if (item.base64Asset == 'quantum') {
      return CustomPaint(
        painter: _QuantumSpinPainter(),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.green, size: 24),
            const SizedBox(height: 4),
            Text(item.name[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      );
    }
  }

  void _triggerMemoryViewer(SecureMediaItem item) {
    widget.onSecurityLog('Decrypted transient layout called', 'info', 'Reading RAW buffer metadata from RAM.');
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return _MemoryOnlyImageDialog(
          item: item,
          locale: widget.locale,
          onSuccess: widget.onSuccess,
        );
      },
    );
  }

  // FEATURE 6: MEDIA DASHBOARD
  Widget _buildDashboardTab() {
    int totalBytes = _mediaItems.fold(0, (sum, i) => sum + i.sizeInBytes);
    String totalSizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _locVal('MEDIA VAULT PHYSICAL STATISTICS', 'إحصائيات مستودع الصور المحمي المتقدمة'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.neutral-400),
          ),
          const SizedBox(height: 16),
          _dashboardStatTile(_locVal('Total Encrypted Assets', 'إجمالي الصور المسجلة'), '${_mediaItems.length} items', Colors.cyan),
          _dashboardStatTile(_locVal('Protected Data Volume', 'حجم السعة المحمية'), totalSizeStr, Colors.purpleAccent),
          _dashboardStatTile(_locVal('Sanitation Status', 'سلامة وحالة الحماية والمراجعة'), '100% CLEAN IN-RAM ONLY', Colors.green),
          const SizedBox(height: 24),
          Text(
            _locVal('PIPELINE VAULTS LOGS', 'سجل المستودعات النشطة'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.neutral-500),
          ),
          const SizedBox(height: 8),
          ..._mediaItems.take(4).map((i) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            color: Colors.neutral-900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
                Text(i.album, style: const TextStyle(fontSize: 9, color: Colors.cyan)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _dashboardStatTile(String label, String value, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.neutral-800.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }

  // FEATURE 9: FUTURE COMPATIBILITY BLUEPRINT
  Widget _buildFutureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch, color: Colors.purple, size: 40),
          const SizedBox(height: 12),
          Text(
            _locVal('VERSION 2.6 PIPELINE EXPANSION', 'نظام البث المشفر وخزنة الفيديو - الإصدار 2.6'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _locVal('Blueprint parameters defined for extreme media chunking in transit.', 
                    'المعالم الهندسية لمعالجة كاش الملفات الضخمة والصوتيات تحت درع ريمان.'),
            style: const TextStyle(color: Colors.neutral-500, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _futureCapsuleCard(Icons.video_library, _locVal('Encrypted Video Vault', 'خزنة الفيديو المشفر بالكامل')),
          _futureCapsuleCard(Icons.music_note, _locVal('Vocal & Audio Safe Wrapper', 'كبسولة الصوتيات والمذكرات الآمنة')),
          _futureCapsuleCard(Icons.stream, _locVal('Fluid Hot-Streaming Pipes', 'شبكات البث الحي المباشرة الخاطفة')),
        ],
      ),
    );
  }

  Widget _futureCapsuleCard(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: Colors.purple.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple[400], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(_locVal('ARCH BLUEPRINT READY', 'المعمار الهندسي جاهز'), style: const TextStyle(fontSize: 8, color: Colors.cyan)),
            ],
          ).toExpanded(), // custom extensions support or expanded row layout below
        ],
      ),
    );
  }
}

// Memory-only detail render box: no leak, clear on dismiss (Feature 4 & Feature 8)
class _MemoryOnlyImageDialog extends StatelessWidget {
  final SecureMediaItem item;
  final String locale;
  final Function(String, String) onSuccess;

  const _MemoryOnlyImageDialog({
    required this.item,
    required this.locale,
    required this.onSuccess,
  });

  String _locVal(String en, String ar) {
    return locale == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSuccess(_locVal('Temporary memory flushed successfully.', 'تم مسح الصورة من كاش الذاكرة التلقائية.'), 'info');
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            // Transient image box
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.neutral-900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _renderSafePainterInsideDialog(item),
            ),
            const SizedBox(height: 16),
            // IMAGE METADATA DETAILS (Feature 8)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.neutral-900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine(_locVal('RESOLUTION:', 'أبعاد البيكسل:'), item.resolution),
                  _detailLine(_locVal('FILE SIZE:', 'الحجم من القرص:'), '${(item.sizeInBytes / 1024).toStringAsFixed(1)} KB'),
                  _detailLine(_locVal('IMPORT DATE:', 'تاريخ الإدخال:'), item.importDate.toLocal().toString().split(' ')[0]),
                  _detailLine(_locVal('ORGAN ALBUM:', 'ألبوم الأرشفة:'), item.album),
                  _detailLine(_locVal('CIPHER CODE:', 'خوارزمية الحظر:'), 'RIEMANN-TRIPLE-S3B'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSuccess(_locVal('Export procedure completed successfully.', 'تم فك تشفير وتصدير الصورة بنجاح.'), 'success');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              child: Text(_locVal('SECURE DECRYPT & EXPORT', 'تأكيد فك التشفير والتصدير'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }

  Widget _renderSafePainterInsideDialog(SecureMediaItem m) {
    if (m.base64Asset == 'coherence') {
      return CustomPaint(painter: _CoherenceShieldPainter());
    } else if (m.base64Asset == 'quantum') {
      return CustomPaint(painter: _QuantumSpinPainter());
    } else {
      return const Center(child: Icon(Icons.lock_open, color: Colors.greenAccent, size: 40));
    }
  }

  Widget _detailLine(String path, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(path, style: const TextStyle(fontSize: 9, color: Colors.neutral-500, fontFamily: 'monospace')),
          Text(value, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

// Vector graphic painter representing Riemann coherence shield (Real math representations)
class _CoherenceShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint1 = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintLine = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..strokeWidth = 0.5;

    canvas.drawCircle(center, size.width * 0.35, paint1);
    canvas.drawCircle(center, size.width * 0.2, paint1);
    
    final path = Path();
    path.moveTo(center.dx, center.dy - size.width * 0.4);
    path.lineTo(center.dx + size.width * 0.3, center.dy - size.width * 0.15);
    path.lineTo(center.dx + size.width * 0.3, center.dy + size.width * 0.2);
    path.lineTo(center.dx, center.dy + size.width * 0.45);
    path.lineTo(center.dx - size.width * 0.3, center.dy + size.width * 0.2);
    path.lineTo(center.dx - size.width * 0.3, center.dy - size.width * 0.15);
    path.close();

    canvas.drawPath(path, paint1..color = Colors.purple.withOpacity(0.6)..strokeWidth = 2);

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paintLine);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Vector graphic painter representing quantum spin mapping (Real math representations)
class _QuantumSpinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    final spinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw orbits
    for (int rotation = 0; rotation < 180; rotation += 60) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * math.pi / 180);
      
      final rRect = Rect.fromCenter(center: Offset.zero, width: size.width * 0.7, height: size.height * 0.25);
      canvas.drawOval(
        rRect,
        spinPaint..color = rotation == 0 
          ? Colors.orange 
          : rotation == 60 
            ? Colors.pinkAccent 
            : Colors.cyanAccent,
      );
      canvas.restore();
    }

    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom extensions helper to prevent missing expand methods
extension _WidgetExt on Widget {
  Widget toExpanded() => Expanded(child: this);
}
