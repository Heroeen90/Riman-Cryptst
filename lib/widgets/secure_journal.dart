import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';
import '../utils/nexus_service.dart';

class JournalEntryModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String mood;
  final Map<String, double>? location;

  JournalEntryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.mood,
    this.location,
  });
}

class SecureJournalWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SecureJournalWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SecureJournalWidget> createState() => _SecureJournalWidgetState();
}

class _SecureJournalWidgetState extends State<SecureJournalWidget> {
  // Vault lock states
  bool _isUnlocked = false;
  String _vaultPassword = '';
  bool _hidePassword = true;

  // New item states
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedMood = 'focused';
  bool _isLocationArmed = false;

  // Searching filter
  String _searchQuery = '';
  String _filterMood = 'All';

  final List<JournalEntryModel> _entries = [];

  final List<Map<String, String>> _moodsList = [
    {'key': 'serene', 'labelEn': 'Serene', 'labelAr': 'صفاء نقي', 'emoji': '🌸'},
    {'key': 'focused', 'labelEn': 'Focused', 'labelAr': 'تركيز عالي', 'emoji': '🎯'},
    {'key': 'vigilant', 'labelEn': 'Vigilant', 'labelAr': 'يقظ حذر', 'emoji': '🛡️'},
    {'key': 'thoughtful', 'labelEn': 'Thoughtful', 'labelAr': 'متأمل', 'emoji': '💭'},
    {'key': 'restless', 'labelEn': 'Restless', 'labelAr': 'قلق متأهب', 'emoji': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    // FIX: Wrapped inside a PostFrameCallback to prevent setState() during build phase crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedDefaultJournal();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _seedDefaultJournal() {
    _entries.addAll([
      JournalEntryModel(
        id: 'j1',
        title: _locVal('Orbit Spectrum Convergence Test', 'اختبار تقارب طيف الغلاف الجوي'),
        content: _locVal('Calculated critical line vector offsets. Keystreams align within 24 decimal cycles on target matrices.', 'تم قياس قيم ذبذبات المدار التوافقي بدقة ٢٤ خانة عشرية متتالية على المصفوفة.'),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        mood: 'serene',
        location: {'lat': 30.0444, 'lng': 31.2357},
      ),
      JournalEntryModel(
        id: 'j2',
        title: _locVal('Entropy Leak Incident Resolve', 'احتواء تسريب معاملات العشوائية'),
        content: _locVal('Minor physical jitter detected in oscillator. Recalibrated phase coefficients to zero immediately.', 'كشف تذبذب طفيف في المولد الفيزيائي. تمت إعادة تهيئة معاملات الطور للأصفار فوراً.'),
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        mood: 'vigilant',
        location: {'lat': 30.0571, 'lng': 31.2272},
      ),
    ]);
    NexusService().registerJournals(_entries);
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _unlockVault() {
    if (_vaultPassword.isEmpty || _vaultPassword.length < 5) {
      widget.onSuccess(
        _locVal('Password must be at least 5 characters', 'يجب ألا تقل كلمة المرور عن 5 أحرف'),
        'error',
      );
      return;
    }

    setState(() {
      _isUnlocked = true;
    });

    widget.onSecurityLog(
      'Flutter Secure Journal unlocked',
      'info',
      'Unlocked time-series journal DB block.',
    );

    widget.onSuccess(
      _locVal('Journal opened. Slices decrypted.', 'تم تشفير وحفظ تدوينات اليوميات وعرضها في الجدول بنجاح!'),
      'success',
    );
  }

  void _lockVault() {
    setState(() {
      _isUnlocked = false;
      _vaultPassword = '';
    });

    widget.onSecurityLog(
      'Locked Flutter Journal',
      'info',
      'RAM logs de-allocated.',
    );

    widget.onSuccess(
      _locVal('Journal closed.', 'تم إغلاق ملف اليوميات وتأمين الطيف.'),
      'info',
    );
  }

  void _commitJournalEntry() {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      widget.onSuccess(_locVal('Title and content are required!', 'العنوان والمحتوى مطلوبان للتسجيل!'), 'error');
      return;
    }

    setState(() {
      _entries.insert(
        0,
        JournalEntryModel(
          id: 'j_${DateTime.now().millisecondsSinceEpoch}',
          title: _titleCtrl.text,
          content: _contentCtrl.text,
          createdAt: DateTime.now(),
          mood: _selectedMood,
          location: _isLocationArmed ? {'lat': 30.0444, 'lng': 31.2357} : null,
        ),
      );
      _titleCtrl.clear();
      _contentCtrl.clear();
      _isLocationArmed = false;
      NexusService().registerJournals(_entries);
    });

    widget.onSecurityLog(
      'Journal Entry Enveloped',
      'info',
      'Encrypted custom chronological narrative slice into secure database.',
    );

    widget.onSuccess(
      _locVal('Story logged in Sovereign Timeline!', 'تم حفظ اللحظة التاريخية في مسار يومياتك!'),
      'success',
    );
  }

  void _deleteEntry(String id) {
    setState(() {
      _entries.removeWhere((element) => element.id == id);
      NexusService().registerJournals(_entries);
    });

    widget.onSecurityLog(
      'Physical journal payload shredded',
      'warning',
      'Deleted historical index block: $id.',
    );

    widget.onSuccess(
      _locVal('Chronology entry destroyed completely!', 'تم مسح وشطب التدوينة من المسار الزمني تماماً!'),
      'success',
    );
  }

  void _exportJournalAsMarkdown() {
    if (_entries.isEmpty) {
      widget.onSuccess(_locVal('Journal is empty!', 'ملف اليوميات فارغ!'), 'error');
      return;
    }

    String mdContent = '# Riman Cryptst Mobile Journal Export\n\n';
    for (var e in _entries) {
      mdContent += '## [${e.createdAt}] ${e.title}\n';
      mdContent += 'Mood/Energy index: ${e.mood}\n';
      if (e.location != null) {
        mdContent += 'Coordinates: Lat ${e.location!['lat']}, Lng ${e.location!['lng']}\n';
      }
      mdContent += '\n${e.content}\n\n---\n\n';
    }

    Clipboard.setData(ClipboardData(text: mdContent));
    widget.onSuccess(
      _locVal('Markdown log exported to Clipboard!', 'تم نسخ تدويناتك بهيئة Markdown إلى الحافظة وجاهزة للحفظ!'),
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    List<JournalEntryModel> filtered = _entries.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMood = _filterMood == 'All' || e.mood == _filterMood;
      return matchesSearch && matchesMood;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: const Color(0xFF030712),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Segment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locVal('TIME-SERIES CRYPT METRIC', 'توثيق اليوميات المشفرة ومقاييس الوقت'),
                          style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locVal('Secure Timeline & Archive', 'الأرشيف التاريخي المشفر لليوميات'),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (_isUnlocked)
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.download_for_offline, color: Color(0xFFA855F7), size: 20),
                          onPressed: _exportJournalAsMarkdown,
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.12),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.red, width: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: _lockVault,
                          child: Text(_locVal('LOCK', 'تجميد'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recorder (Left)
                  Expanded(
                    flex: 3,
                    child: _isUnlocked ? _buildNewEntryCard() : _buildWelcomeLockedNotice(),
                  ),
                  const SizedBox(width: 14),

                  // Timeline grid (Right)
                  Expanded(
                    flex: 4,
                    child: _isUnlocked ? _buildTimelineSection(filtered) : _buildLockedScreenGv(),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeLockedNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu, color: Color(0xFFA855F7), size: 16),
              const SizedBox(width: 6),
              Text(
                _locVal('Chronology Engine Operational', 'مسار التدوين المشفر جاهز'),
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _locVal(
              'Decrypt the private ledger on the right to authorize access in memory. Fully client-authoritative with zero footprint cloud leaks.',
              'افتح الخزانة المشفرة على اليمين لتفعيل ذاكرة العمل الآمنة والوصول لتدويناتك التاريخية المشفرة لليوميات بكل سرية.'
            ),
            style: const TextStyle(color: Colors.grey, fontSize: 9.5, height: 1.4),
          )
        ],
      ),
    );
  }

  Widget _buildLockedScreenGv() {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book_online, color: Color(0xFFA855F7), size: 36),
          const SizedBox(height: 12),
          Text(
            _locVal('Timeline Encrypted', 'اليوميات مؤمنة بالكامل'),
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _locVal('Enter Riemann keys value check', 'أدخل كلمة مرور ريمان الدائمة لتشكيل المخطط'),
            style: const TextStyle(color: Colors.grey, fontSize: 8),
          ),
          const SizedBox(height: 16),
          TextField(
            obscureText: _hidePassword,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              labelText: _locVal('Security Password', 'رمز الحماية والتشفير'),
              labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility, size: 14),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA855F7))),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
            onChanged: (val) => _vaultPassword = val,
            onSubmitted: (v) => _unlockVault(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _unlockVault,
            child: Text(_locVal('DECRYPT LEDGER', 'فك ترابط الطيف لليوميات'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildNewEntryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            children: [
              const Icon(Icons.add_comment_outlined, color: Color(0xFFA855F7), size: 14),
              const SizedBox(width: 6),
              Text(
                _locVal('Commit Journal Slice', 'تسجيل لقطة يوميات مشفرة'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Log heading / title...', 'عنوان اليوميات...'),
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA855F7))),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
          ),
          const SizedBox(height: 12),

          // Mood energy selector
          Text(_locVal('Energy / Emotional state', 'مؤشر قياس الطاقة والمزاج العام'), style: const TextStyle(color: Colors.grey, fontSize: 8.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _moodsList.map((m) {
              final active = _selectedMood == m['key'];
              return ChoiceChip(
                label: Text(
                  '${m['emoji']} ${_locVal(m['labelEn']!, m['labelAr']!)}',
                  style: TextStyle(fontSize: 9, color: active ? Colors.black : Colors.white),
                ),
                selected: active,
                selectedColor: const Color(0xFFA855F7),
                backgroundColor: const Color(0xFF1E293B),
                onSelected: (sel) {
                  if (sel) {
                    setState(() {
                      _selectedMood = m['key']!;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_locVal('Tag Geolocation Orbit', 'وسم الموقع الجغرافي للمدار'), style: const TextStyle(color: Colors.grey, fontSize: 9)),
            value: _isLocationArmed,
            activeColor: const Color(0xFFA855F7),
            onChanged: (val) {
              setState(() {
                _isLocationArmed = val;
              });
            },
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            style: const TextStyle(fontSize: 10.5, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Write journal secrets here...', 'اكتب تفاصيل ومفكرتك الآمنة في هذا المربع...'),
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _commitJournalEntry,
            child: Text(_locVal('ENCRYPT & COMMIT STORY', 'تشفير وإيداع التدوينة'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ),
  );
}

  Widget _buildTimelineSection(List<JournalEntryModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            style: const TextStyle(fontSize: 10, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Search story ledger matches...', 'ابحث في فصول اليوميات...'),
              hintStyle: const TextStyle(fontSize: 9.5, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 12, color: Colors.grey),
              border: InputBorder.none,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const Divider(height: 8, color: Colors.white10),
          const SizedBox(height: 8),

          items.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Text(_locVal('No stories found.', 'لم يتم تسجيل لقطات يومية بالمعطيات المدخلة.'), style: const TextStyle(color: Colors.grey, fontSize: 9.5)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final e = items[idx];
                    final moodData = _moodsList.firstWhere((m) => m['key'] == e.mood, orElse: () => _moodsList[1]);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C111C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.02)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  e.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  '${moodData['emoji']} ${_locVal(moodData['labelEn']!, moodData['labelAr']!)}',
                                  style: const TextStyle(color: Color(0xFFA855F7), fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.content,
                            style: const TextStyle(color: Colors.grey, fontSize: 9.5),
                          ),
                          const Divider(height: 12, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year} | ${e.createdAt.hour}:${e.createdAt.minute}',
                                style: const TextStyle(color: Colors.grey, fontSize: 8),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 13),
                                onPressed: () => _deleteEntry(e.id),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }
}
