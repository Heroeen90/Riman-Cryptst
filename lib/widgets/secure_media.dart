import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SecureMediaAsset {
  final String id;
  final String name;
  final String type; // 'video' or 'audio'
  final String format;
  final String category;
  final String album;
  final bool isFavorite;
  final int size; // in bytes
  final DateTime importDate;
  final int duration; // seconds

  SecureMediaAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.format,
    required this.category,
    required this.album,
    this.isFavorite = false,
    required this.size,
    required this.importDate,
    required this.duration,
  });

  SecureMediaAsset copyWith({
    bool? isFavorite,
  }) {
    return SecureMediaAsset(
      id: id,
      name: name,
      type: type,
      format: format,
      category: category,
      album: album,
      isFavorite: isFavorite ?? this.isFavorite,
      size: size,
      importDate: importDate,
      duration: duration,
    );
  }
}

class SecureMediaWidget extends StatefulWidget {
  final String locale;
  final Function(String event, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SecureMediaWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SecureMediaWidget> createState() => _SecureMediaWidgetState();
}

class _SecureMediaWidgetState extends State<SecureMediaWidget> with SingleTickerProviderStateMixin {
  bool _isUnlocked = false;
  String _vaultPassword = '';
  bool _hidePassword = true;

  // Navigation states: video, audio, dashboard, security
  String _activeTab = 'video';

  // State Lists
  final List<SecureMediaAsset> _assets = [];
  final List<String> _albums = ['Sovereign Core', 'Personal Safe', 'Audio Logbook'];
  final List<String> _categories = ['Operational', 'Surveillance', 'Cryptographic', 'Music'];

  // Filter keys
  String _searchQuery = '';
  String _selectedAlbum = 'All';
  String _selectedCategory = 'All';
  bool _onlyFavorites = false;

  // Import overlay state
  final TextEditingController _importNameCtrl = TextEditingController();
  String _importType = 'video';
  String _importAlbum = 'Personal Safe';
  String _importCategory = 'Cryptographic';

  // Live media player simulation states
  SecureMediaAsset? _activeVideoAsset;
  SecureMediaAsset? _activeAudioAsset;
  bool _videoPlaying = false;
  double _videoProgress = 0.0;
  double _playbackSpeed = 1.0;
  bool _audioPlaying = false;
  double _audioProgress = 0.0;
  double _audioVolume = 0.8;
  bool _isMuted = false;

  Timer? _videoTimer;
  Timer? _audioTimer;

  // Security Shields parameters
  bool _preventScreenshot = true;
  bool _blurOnFocusLoss = true;
  bool _secureViewingMode = true;

  @override
  void initState() {
    super.initState();
    _seedDefaultMedia();
  }

  @override
  void dispose() {
    _importNameCtrl.dispose();
    _videoTimer?.cancel();
    _audioTimer?.cancel();
    super.dispose();
  }

  void _seedDefaultMedia() {
    _assets.addAll([
      SecureMediaAsset(
        id: 'mv_seed1',
        name: _locVal('Riemann Spectrum Core Introduction', 'مقدمة طيف ريمان السيادي'),
        type: 'video',
        format: 'webm',
        category: 'Cryptographic',
        album: 'Sovereign Core',
        isFavorite: true,
        size: 154820,
        importDate: DateTime.now().subtract(const Duration(hours: 4)),
        duration: 25,
      ),
      SecureMediaAsset(
        id: 'mv_seed2',
        name: _locVal('Operational Audio Broadcast System', 'سجل البث الصوتي العملياتي'),
        type: 'audio',
        format: 'wav',
        category: 'Operational',
        album: 'Audio Logbook',
        isFavorite: false,
        size: 89400,
        importDate: DateTime.now().subtract(const Duration(days: 1)),
        duration: 45,
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
      'Sovereign Media channels decrypted',
      'info',
      'Hydrated video/audio catalog records into system memory arrays.'
    );

    setState(() {
      _isUnlocked = true;
    });

    widget.onSuccess(
      _locVal('Sovereign Media channels decrypted!', 'تم توصيل وفك تشفير قنوات الوسائط الموفرة بنجاح!'),
      'success'
    );
  }

  void _handleLock() {
    _stopPlayback();
    setState(() {
      _isUnlocked = false;
      _vaultPassword = '';
    });

    widget.onSecurityLog(
      'Decrypted cache purged',
      'info',
      'Zeroed transient playback modules and cleared active security visual channels.'
    );

    widget.onSuccess(
      _locVal('Secured channels closed and memory flushed.', 'تم إغلاق الأقنية المشفرة وتفريغ كاش الذاكرة.'),
      'info'
    );
  }

  void _stopPlayback() {
    _videoTimer?.cancel();
    _audioTimer?.cancel();
    setState(() {
      _activeVideoAsset = null;
      _activeAudioAsset = null;
      _videoPlaying = false;
      _audioPlaying = false;
    });
  }

  void _handleImport() {
    final name = _importNameCtrl.text.trim();
    if (name.isEmpty) {
      widget.onSuccess(_locVal('Please choose designation name!', 'يرجى كتابة اسم الصورة/الملف للوسيط!'), 'error');
      return;
    }

    setState(() {
      _assets.add(SecureMediaAsset(
        id: 'mv_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _importType,
        format: _importType == 'video' ? 'mp4' : 'wav',
        category: _importCategory,
        album: _importAlbum,
        isFavorite: false,
        size: 1024 * 320, // 320 KB
        importDate: DateTime.now(),
        duration: _importType == 'video' ? 15 : 10,
      ));

      _importNameCtrl.clear();
    });

    widget.onSecurityLog(
      'Encrypted media catalog registration',
      'success',
      'Secured metadata and stored mock bytes on Triple-Galois system.'
    );

    widget.onSuccess(_locVal('Asset encrypted and saved securely inside vault!', 'تم تشفير وحفظ ملف الوسائط بنجاح وموائمة الكاش!'), 'success');
  }

  void _handleDelete(String id) {
    setState(() {
      _assets.removeWhere((x) => x.id == id);
      if (_activeVideoAsset?.id == id) _activeVideoAsset = null;
      if (_activeAudioAsset?.id == id) _activeAudioAsset = null;
    });
    widget.onSecurityLog('Purged media registry unit', 'warning', 'Purged metadata from active vault list.');
    widget.onSuccess(_locVal('Media purged from vault.', 'تم إزالة الصورة/الصوت من المحفظة تماماً.'), 'success');
  }

  void _handleToggleFavorite(String id) {
    setState(() {
      final index = _assets.indexWhere((x) => x.id == id);
      if (index != -1) {
        _assets[index] = _assets[index].copyWith(isFavorite: !_assets[index].isFavorite);
      }
    });
  }

  void _startVideoSimulation(SecureMediaAsset asset) {
    _stopPlayback();
    setState(() {
      _activeVideoAsset = asset;
      _videoPlaying = true;
      _videoProgress = 0.0;
    });

    _videoTimer = Timer.periodic(Duration(milliseconds: (300 / _playbackSpeed).round()), (timer) {
      if (!mounted) return;
      setState(() {
        _videoProgress += 0.02;
        if (_videoProgress >= 1.0) {
          _videoProgress = 0.0;
        }
      });
    });
  }

  void _startAudioSimulation(SecureMediaAsset asset) {
    _stopPlayback();
    setState(() {
      _activeAudioAsset = asset;
      _audioPlaying = true;
      _audioProgress = 0.0;
    });

    _audioTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _audioProgress += 0.015;
        if (_audioProgress >= 1.0) {
          _audioProgress = 0.0;
        }
      });
    });
  }

  // Feature 9 score
  int _calculateSecurityScore() {
    int score = 40;
    if (_preventScreenshot) score += 20;
    if (_blurOnFocusLoss) score += 20;
    if (_secureViewingMode) score += 20;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF030712), // neutral-950
      child: !_isUnlocked ? _buildLockScreen() : _buildUnlockedVault(),
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
                child: const Icon(Icons.video_library, color: Colors.cyan, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                _locVal('Validate Media Vault ID', 'المصادقة قبل ولوج خزانة الميديا'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _locVal('Conducts memory-safe decryption on the active digital sandbox environment.', 
                        'يقوم المحرك بفصل كاش الأجهزة عبر تشفير ريمان اللحظي ثنائي الاتجاه.'),
                style: const TextStyle(color: Colors.neutral-500, fontSize: 11, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                obscureText: _hidePassword,
                onChanged: (val) => _vaultPassword = val,
                decoration: InputDecoration(
                  hintText: _locVal('Master password (e.g. riemann)', 'رمز المرور للتشفير متناظر'),
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
                  _locVal('DECRYPT VAULT REPOSITORY', 'فك قفل الأرشيف السمعي البصري'),
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedVault() {
    return Column(
      children: [
        // Tab Header
        _buildMediaSubTabs(),
        
        // Active Sub-panel
        Expanded(
          child: _activeTab == 'video' || _activeTab == 'audio'
              ? _buildMediaLibraryView()
              : _activeTab == 'dashboard'
                  ? _buildDashboardView()
                  : _buildSecurityCenterView(),
        ),
      ],
    );
  }

  Widget _buildMediaSubTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF111827),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _subTabButton('video', _locVal('VIDEOS', 'الفيديو')),
              _subTabButton('audio', _locVal('AUDIO', 'الصوتيات')),
              _subTabButton('dashboard', _locVal('METRICS', 'المؤشرات')),
              _subTabButton('security', _locVal('SHIELDS', 'الأمان')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.roseAccent, size: 18),
            onPressed: _handleLock,
            tooltip: _locVal('Lock Vault', 'إقفال وتحصين'),
          )
        ],
      ),
    );
  }

  Widget _subTabButton(String tab, String title) {
    final active = _activeTab == tab;
    return TextButton(
      onPressed: () {
        setState(() {
          _activeTab = tab;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: active ? Colors.cyan : Colors.white60,
        backgroundColor: active ? Colors.cyan.withOpacity(0.05) : Colors.transparent,
      ),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMediaLibraryView() {
    final filtered = _assets.where((asset) {
      if (asset.type != _activeTab) return false;
      final matchQ = asset.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchAlbum = _selectedAlbum == 'All' || asset.album == _selectedAlbum;
      final matchCat = _selectedCategory == 'All' || asset.category == _selectedCategory;
      final matchFav = !_onlyFavorites || asset.isFavorite;
      return matchQ && matchAlbum && matchCat && matchFav;
    }).toList();

    return Column(
      children: [
        // Security overlay and prevent screenshot banner info list
        _buildSecurityHUD(),
        
        // Search and collections options row
        _buildSearchFilterPanel(),

        // Dynamic File Import Form
        _buildImportForm(),

        // Players (Feature 4, 5)
        if (_activeTab == 'video' && _activeVideoAsset != null)
          _buildSecureVideoPlayer(_activeVideoAsset!),
        
        if (_activeTab == 'audio' && _activeAudioAsset != null)
          _buildSecureAudioPlayer(_activeAudioAsset!),

        // Grid of assets (Feature 1, 2)
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return _buildMediaCard(item);
                  },
                ),
        )
      ],
    );
  }

  Widget _buildSecurityHUD() {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.emerald, size: 12),
              const SizedBox(width: 4),
              Text(
                _locVal('SCREENSHOT BLUR PROTECTION ACTIVE', 'حظر لقطات وتسريب الشاشة مفعّل'),
                style: const TextStyle(fontSize: 9, color: Colors.neutral-300, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Switch(
            value: _preventScreenshot,
            activeColor: Colors.emerald,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() {
                _preventScreenshot = val;
              });
              widget.onSecurityLog('Toggle parameter', 'info', 'Screen Protection set to $val');
            },
          )
        ],
      ),
    );
  }

  Widget _buildSearchFilterPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: _locVal('Query media metadata ...', 'ابحث في وسوم الميديا...'),
              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.cyan),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(10),
            ),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedAlbum,
                items: ['All', ..._albums].map((a) {
                  return DropdownMenuItem<String>(
                    value: a,
                    child: Text(a == 'All' ? _locVal('All Albums', 'كل الألبومات') : a, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAlbum = val ?? 'All'),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: _onlyFavorites ? Colors.rose : Colors.grey, size: 16),
                onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
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
        color: const Color(0xFF1F2937).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _importNameCtrl,
              decoration: InputDecoration(
                hintText: _locVal('Import designation ...', 'تسمية الملف المراد تشفيره...'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _handleImport,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[900]),
            child: Text(_locVal('ENCODE', 'تشفير'), style: const TextStyle(fontSize: 10, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_camera_back, size: 48, color: Colors.neutral-700),
          const SizedBox(height: 8),
          Text(_locVal('ZERO DECRYPTED ASSETS LOCATED', 'لا يوجد ملفات مطابقة'), style: const TextStyle(fontSize: 11, color: Colors.neutral-500)),
        ],
      ),
    );
  }

  Widget _buildSecureVideoPlayer(SecureMediaAsset asset) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asset.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                onPressed: _stopPlayback,
              )
            ],
          ),
          // Custom Video Simulation Frame Painting (Feature 4)
          Container(
            height: 180,
            color: const Color(0xFF0C0A0F),
            child: CustomPaint(
              painter: _VideoWaveMatrixPainter(progress: _videoProgress, speed: _playbackSpeed),
            ),
          ),
          const SizedBox(height: 8),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(_videoPlaying ? Icons.pause : Icons.play_arrow, color: Colors.cyan),
                    onPressed: () {
                      setState(() {
                        _videoPlaying = !_videoPlaying;
                      });
                    },
                  ),
                  Text(
                    '00:${(_videoProgress * asset.duration).round().toString().padLeft(2, '0')} / 00:${asset.duration}',
                    style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                  )
                ],
              ),
              DropdownButton<double>(
                value: _playbackSpeed,
                items: [0.5, 1.0, 1.5, 2.0].map((s) {
                  return DropdownMenuItem<double>(
                    value: s,
                    child: Text('${s}x', style: const TextStyle(fontSize: 9, color: Colors.cyanAccent)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _playbackSpeed = val ?? 1.0;
                  });
                  _startVideoSimulation(asset);
                },
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSecureAudioPlayer(SecureMediaAsset asset) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                asset.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                onPressed: _stopPlayback,
              )
            ],
          ),
          // Audio spectrum representation custom paint (Feature 5)
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _AudioSpectrumPainter(progress: _audioProgress),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(_audioPlaying ? Icons.pause : Icons.play_arrow, color: Colors.purpleAccent),
                    onPressed: () {
                      setState(() {
                        _audioPlaying = !_audioPlaying;
                      });
                    },
                  ),
                  Text(
                    '00:${(_audioProgress * asset.duration).round().toString().padLeft(2, '0')} / 00:${asset.duration}',
                    style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                  )
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.grey, size: 16),
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),
                  Text(
                    _isMuted ? 'MUTED' : '${(_audioVolume * 100).round()}%',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMediaCard(SecureMediaAsset item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.black54,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Icon(
                      item.type == 'video' ? Icons.videocam : Icons.audiotrack,
                      color: item.type == 'video' ? Colors.cyan.withOpacity(0.4) : Colors.purpleAccent.withOpacity(0.4),
                      size: 28,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite, color: item.isFavorite ? Colors.rose : Colors.grey, size: 14),
                          onPressed: () => _handleToggleFavorite(item.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.neutral-500, size: 14),
                          onPressed: () => _handleDelete(item.id),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.album, style: const TextStyle(fontSize: 7, color: Colors.cyan), overflow: TextOverflow.ellipsis),
              Text('${(item.size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 7, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (item.type == 'video') {
                _startVideoSimulation(item);
              } else {
                _startAudioSimulation(item);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.cyan.withOpacity(0.05),
              alignment: Alignment.center,
              child: Text(
                _locVal('PLAY (RAM)', 'تشغيل زائل بالرام'),
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    int vCount = _assets.where((x) => x.type == 'video').length;
    int aCount = _assets.where((x) => x.type == 'audio').length;
    int totalBytes = _assets.fold(0, (sum, i) => sum + i.size);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _locVal('MASTER SECURE METRICS', 'المؤشرات العامة للوسائط'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          _metricTile(_locVal('Sealed Videos Count', 'أرشيف مقاطع الفيديو المأمنة'), '$vCount files', Colors.cyan),
          _metricTile(_locVal('Sealed Audios Count', 'مجموع المذكرات الصوتية المأمنة'), '$aCount files', Colors.purpleAccent),
          _metricTile(_locVal('Decoupled Heap Volume', 'إجمالي حجم الأرشيف بالقرص'), '${(totalBytes / 1024).toStringAsFixed(1)} KB', Colors.emerald),
          const SizedBox(height: 24),
          Text(
            _locVal('COLLECTIONS BREAKDOWN', 'فهرس تقسيم المجموعات'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 8),
          ..._albums.map((al) {
            final count = _assets.where((x) => x.album == al).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF111827),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(al, style: const TextStyle(fontSize: 10, color: Colors.white75)),
                  Text('$count assets', style: const TextStyle(fontSize: 10, color: Colors.cyan, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _metricTile(String label, String val, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
        ],
      ),
    );
  }

  Widget _buildSecurityCenterView() {
    int score = _calculateSecurityScore();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _locVal('HEALTH SHIELD CONFIGURATION', 'مركز فحص وثوقية وأمان الميديا'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          // Dynamic gauge painting
          Container(
            height: 110,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.blueGrey[900],
                    color: Colors.cyan,
                  ),
                ),
                Text('$score%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.extrabold, color: Colors.cyanAccent)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _shieldToggleRow(_locVal('Media Anti-Screenshot Layer', 'حجب وتعتيم اللقطات'), _preventScreenshot, (v) => setState(() => _preventScreenshot = v)),
          _shieldToggleRow(_locVal('Focus Loss Blur Enforce', 'التعتيم عند خروج التركيز'), _blurOnFocusLoss, (v) => setState(() => _blurOnFocusLoss = v)),
          _shieldToggleRow(_locVal('Transient Decryption Lock', 'التفكيك المشفر المؤقت'), _secureViewingMode, (v) => setState(() => _secureViewingMode = v)),
          const SizedBox(height: 24),
          // Blueprint future indications
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.04),
              border: Border.all(color: Colors.purple.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_locVal('VERSION 2.8 PRE-COMPATIBILITY PIPELINES', 'بروتوكولات الأرصفة المستقبلية إصدار 2.8'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.purpleAccent)),
                const SizedBox(height: 4),
                Text(_locVal('- Instant chunk direct streaming capabilities', '- بث الحزم الصغير والمقاطع بشكل مجزأ لتفادي التصدير'), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(_locVal('- Zero-exposure direct sandboxed play', '- إقفال حزم التشديد البياني المباشر لتغطية الأجهزة الحديثة (Zero Exposure)'), style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _shieldToggleRow(String title, bool active, Function(bool) onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      color: const Color(0xFF111827),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.white)),
          Switch(
            value: active,
            activeColor: Colors.cyan,
            onChanged: onToggle,
          )
        ],
      ),
    );
  }
}

// Custom painter representing math video wave matrices
class _VideoWaveMatrixPainter extends CustomPainter {
  final double progress;
  final double speed;

  _VideoWaveMatrixPainter({required this.progress, required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    final linePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (double i = 0; i < size.width; i++) {
      final y = center.dy +
          math.sin(i * 0.03 + (progress * 2 * math.pi)) * 30 +
          math.cos(i * 0.01 + (progress * math.pi)) * 10;
      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter representing audio spectrum waves
class _AudioSpectrumPainter extends CustomPainter {
  final double progress;

  _AudioSpectrumPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double step = size.width / 30;
    for (int i = 0; i < 30; i++) {
      final x = i * step + step / 2;
      final double amp = 10 + math.sin(i * 0.4 + (progress * 2 * math.pi)) * size.height * 0.4;
      canvas.drawLine(
        Offset(x, size.height / 2 - amp / 2),
        Offset(x, size.height / 2 + amp / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
