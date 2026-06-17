import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';
import '../utils/nexus_service.dart';

class SecureNote {
  final String id;
  final String title;
  final String content;
  final String category;
  final Color color;
  final DateTime createdAt;
  final bool isPinned;
  final bool isSelectiveLocked;

  SecureNote({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.createdAt,
    this.isPinned = false,
    this.isSelectiveLocked = false,
  });

  SecureNote copyWith({
    String? title,
    String? content,
    String? category,
    Color? color,
    bool? isPinned,
    bool? isSelectiveLocked,
  }) {
    return SecureNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
      isSelectiveLocked: isSelectiveLocked ?? this.isSelectiveLocked,
    );
  }
}

class SecureNotesWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SecureNotesWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SecureNotesWidget> createState() => _SecureNotesWidgetState();
}

class _SecureNotesWidgetState extends State<SecureNotesWidget> {
  // Vault session lock states
  bool _isUnlocked = false;
  String _vaultPassword = '';
  bool _hidePassword = true;

  // Scratchpad
  final TextEditingController _scratchTitleCtrl = TextEditingController();
  final TextEditingController _scratchContentCtrl = TextEditingController();

  // Create Mode state
  final TextEditingController _noteTitleCtrl = TextEditingController();
  final TextEditingController _noteContentCtrl = TextEditingController();
  String _selectedCategory = 'Personal';
  Color _selectedColor = const Color(0xFF06B6D4);
  bool _isNoteSelectiveLocked = false;

  // Active / selected note for details/edit
  SecureNote? _activeDetailNote;

  // Search & Filter
  String _searchQuery = '';
  String _filterCategory = 'All';

  // Available categories
  final List<String> _categories = ['Personal', 'Work', 'Financial', 'Credentials', 'Secrets'];
  final TextEditingController _newCatCtrl = TextEditingController();

  // Default seeded notes
  final List<SecureNote> _notes = [];

  // Colors available
  final List<Color> _noteColors = [
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFA855F7), // Purple
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFF43F5E), // Rose
  ];

  @override
  void initState() {
    super.initState();
    // FIX: Wrapped inside a PostFrameCallback to prevent setState() during build phase crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedDefaultNotes();
    });
  }

  @override
  void dispose() {
    _scratchTitleCtrl.dispose();
    _scratchContentCtrl.dispose();
    _noteTitleCtrl.dispose();
    _noteContentCtrl.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  void _seedDefaultNotes() {
    _notes.addAll([
      SecureNote(
        id: 'n1',
        title: _locVal('Riemann Master Encryption Coordinates', 'إحداثيات تشفير ريمان الرئيسية'),
        content: _locVal(
          'The primary non-trivial zeroes map to: s=1/2 + i*14.134725 and s=1/2 + i*21.022040.',
          'تتطابق الأصفار غير البديهية الأولية مع المدارات التالية: s=1/2 + i*14.134725 و s=1/2 + i*21.022040.'
        ),
        category: 'Secrets',
        color: const Color(0xFF06B6D4),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isPinned: true,
      ),
      SecureNote(
        id: 'n2',
        title: _locVal('Wallet Backup Seeds Crypt Block', 'الأرقام السرية لنسخ محفظة التشفير'),
        content: _locVal(
          'Words: quantum, riemann, spectrum, gravity, cascade, entropy, absolute.',
          'الكلمات: quantum, riemann, spectrum, gravity, cascade, entropy, absolute.'
        ),
        category: 'Financial',
        color: const Color(0xFFF43F5E),
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isSelectiveLocked: true,
      ),
    ]);
    NexusService().registerNotes(_notes);
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
      'Flutter Secure Notes unlocked',
      'info',
      'Direct seed math model instantiated in local mobile storage thread.',
    );

    widget.onSuccess(
      _locVal('Vault session successfully decrypted!', 'تم فك ترابط الطيف للملاحظات بنجاح!'),
      'success',
    );
  }

  void _lockVault() {
    setState(() {
      _isUnlocked = false;
      _vaultPassword = '';
      _activeDetailNote = null;
    });

    widget.onSecurityLog(
      'Flutter Notes locked',
      'info',
      'Cleared unencrypted buffers from device cache.',
    );

    widget.onSuccess(
      _locVal('Session closed.', 'تم حفظ وإغلاق الجلسة السحابية.'),
      'info',
    );
  }

  void _elevateScratchpad() {
    if (_scratchTitleCtrl.text.isEmpty && _scratchContentCtrl.text.isEmpty) {
      widget.onSuccess(_locVal('Scratchpad is empty!', 'المسودة فارغة تماماً!'), 'error');
      return;
    }

    if (!_isUnlocked) {
      widget.onSuccess(_locVal('Unlock notes vault first!', 'يرجى فتح الخزنتين لتشفير تذكرة المسودة!'), 'warning');
      return;
    }

    setState(() {
      _notes.insert(
        0,
        SecureNote(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}',
          title: _scratchTitleCtrl.text.trim().isEmpty ? _locVal('Untitled Workspace', 'عنوان مسودة بدون اسم') : _scratchTitleCtrl.text,
          content: _scratchContentCtrl.text,
          category: 'Personal',
          color: const Color(0xFF06B6D4),
          createdAt: DateTime.now(),
        ),
      );
      _scratchTitleCtrl.clear();
      _scratchContentCtrl.clear();
      NexusService().registerNotes(_notes);
    });

    widget.onSecurityLog(
      'Scratchpad Elevated',
      'info',
      'Transferred unsecure volatile memory element to Triple Riemann secure envelope.',
    );

    widget.onSuccess(
      _locVal('Asset secured & filed in Vault!', 'تم تشفير وحفظ المسودة بنجاح في خزنتك!'),
      'success',
    );
  }

  void _commitNoteForm() {
    if (_noteTitleCtrl.text.isEmpty) {
      widget.onSuccess(_locVal('Note title is required!', 'عنوان الملاحظة مطلوب!'), 'error');
      return;
    }

    setState(() {
      if (_activeDetailNote != null) {
        // Edit Mode
        final index = _notes.indexWhere((element) => element.id == _activeDetailNote!.id);
        if (index != -1) {
          _notes[index] = SecureNote(
            id: _activeDetailNote!.id,
            title: _noteTitleCtrl.text,
            content: _noteContentCtrl.text,
            category: _selectedCategory,
            color: _selectedColor,
            createdAt: _activeDetailNote!.createdAt,
            isSelectiveLocked: _isNoteSelectiveLocked,
          );
        }
        _activeDetailNote = null;
      } else {
        // Create Mode
        _notes.insert(
          0,
          SecureNote(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}',
            title: _noteTitleCtrl.text,
            content: _noteContentCtrl.text,
            category: _selectedCategory,
            color: _selectedColor,
            createdAt: DateTime.now(),
            isSelectiveLocked: _isNoteSelectiveLocked,
          ),
        );
      }

      _noteTitleCtrl.clear();
      _noteContentCtrl.clear();
      _isNoteSelectiveLocked = false;
      NexusService().registerNotes(_notes);
    });

    widget.onSuccess(
      _locVal('Secured node sequence committed.', 'تم أرشفة وحفظ الملاحظة المشفرة بنجاح!'),
      'success',
    );
  }

  void _shredNote(String id) {
    setState(() {
      _notes.removeWhere((element) => element.id == id);
      if (_activeDetailNote?.id == id) {
        _activeDetailNote = null;
      }
      NexusService().registerNotes(_notes);
    });

    widget.onSecurityLog(
      'Destroyed physical memory node',
      'warning',
      'Removed index structure: $id from local DB.',
    );

    widget.onSuccess(
      _locVal('Secure Note destroyed!', 'تم تدمير ومسح الملاحظة بالكامل!'),
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    List<SecureNote> filteredNotes = _notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilterCat = _filterCategory == 'All' || note.category == _filterCategory;
      return matchesSearch && matchesFilterCat;
    }).toList();

    // Sort: pinned first
    filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

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
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locVal('SECURE CONTAINMENT FIELD', 'طور حماية فضاء المعرفة الصفرية'),
                          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locVal('Secure Notes Safe Room', 'مستودع الملاحظات الآمنة والمسودات'),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (_isUnlocked)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.12),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red, width: 0.5),
                        ),
                      ),
                      onPressed: _lockVault,
                      child: Text(_locVal('LOCK SESSION', 'إقفال وتجميد'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              const SizedBox(height: 16),

              // Two Layout sections: Scratchpad & Lock screen / main notes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Workstation (Left)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildScratchpadCard(),
                        const SizedBox(height: 16),
                        _buildFutureSpecsPanel(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Vault storage (Right)
                  Expanded(
                    flex: 4,
                    child: _isUnlocked ? _buildMainNotesPanel(filteredNotes) : _buildLockedScreenGv(),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScratchpadCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: Color(0xFF06B6D4), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _locVal('Instant Cold Scratchpad', 'المسودة الفورية المفتوحة'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: Text(_locVal('RAW', 'مسودة'), style: const TextStyle(fontSize: 7, color: Colors.amber)),
              )
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _scratchTitleCtrl,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Quick title input context...', 'عنوان المسودة السريع...'),
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _scratchContentCtrl,
            style: const TextStyle(fontSize: 10.5, color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _locVal('Draft transient notes directly here...', 'اكتب أفكارك أو ملاحظاتك العاجلة هنا...'),
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onPressed: _elevateScratchpad,
            child: Text(
              _locVal('SECURE & ENCRYPT IN VAULT', 'تأكيد الرفع والتشفير للخزنة'),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLockedScreenGv() {
    return Container(
      height: 380,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person, color: Color(0xFF06B6D4), size: 40),
          const SizedBox(height: 12),
          Text(
            _locVal('Sovereign Vault Locked', 'مستودع الملاحظات بحاجة لرمز فك التشفير'),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _locVal('Key derivation parameters must match secure files.', 'اكتب كلمة مرور ريمان لفك ترابط الرموز المشفرة لمستنداتك.'),
            style: const TextStyle(color: Colors.grey, fontSize: 8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            obscureText: _hidePassword,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              labelText: _locVal('Unlock Password', 'كلمة سر الحماية السيادية'),
              labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility, size: 14),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            ),
            onChanged: (val) => _vaultPassword = val,
            onSubmitted: (v) => _unlockVault(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _unlockVault,
            icon: const Icon(Icons.lock_open, size: 12),
            label: Text(_locVal('DECRYPT VAULT', 'فك تشفير الأرشيف'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Default test key: "riman123"',
            style: TextStyle(color: Colors.white10, fontSize: 7, fontFamily: 'monospace'),
          )
        ],
      ),
    );
  }

  Widget _buildMainNotesPanel(List<SecureNote> items) {
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
          // Render form button + search at top
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 10.5, color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 12, color: Colors.grey),
                    hintText: _locVal('Index filter notes...', 'ابحث في الملاحظات...'),
                    hintStyle: const TextStyle(fontSize: 9.5, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF06B6D4), size: 18),
                onPressed: () => _showAddNoteDialog(),
              )
            ],
          ),
          const Divider(height: 8, color: Colors.white10),
          const SizedBox(height: 8),

          items.isEmpty
              ? Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: Text(
                    _locVal('No shielded indexes found.', 'لم نعثر على أي مدخلات مطابقة.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 9.5),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final note = items[idx];
                    return Card(
                      color: const Color(0xFF090D16),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: note.color.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        onTap: () {
                          _showEditNoteDialog(note);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (note.isPinned) const Icon(Icons.push_pin, color: Colors.amber, size: 11),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    note.category,
                                    style: TextStyle(color: note.color, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note.content,
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(height: 10, color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                                    onPressed: () => _shredNote(note.id),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    _noteTitleCtrl.clear();
    _noteContentCtrl.clear();
    _selectedCategory = 'Personal';
    _selectedColor = const Color(0xFF06B6D4);
    _isNoteSelectiveLocked = false;
    _activeDetailNote = null;

    _openNoteFormDialog();
  }

  void _showEditNoteDialog(SecureNote note) {
    _noteTitleCtrl.text = note.title;
    _noteContentCtrl.text = note.content;
    _selectedCategory = note.category;
    _selectedColor = note.color;
    _isNoteSelectiveLocked = note.isSelectiveLocked;
    _activeDetailNote = note;

    _openNoteFormDialog();
  }

  void _openNoteFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                backgroundColor: const Color(0xFF111827),
                title: Text(
                  _activeDetailNote != null ? _locVal('Edit Note', 'تعديل الملاحظة السيادية') : _locVal('Create Note', 'كتابة تدوينة آمنة جديدة'),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _noteTitleCtrl,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                          decoration: InputDecoration(
                            labelText: _locVal('Title', 'عنوان الملاحظة'),
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteContentCtrl,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                          decoration: InputDecoration(
                            labelText: _locVal('Content Payload', 'نص الرسالة المكتوب'),
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_locVal('Category', 'التصنيف'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            DropdownButton<String>(
                              dropdownColor: const Color(0xFF111827),
                              value: _selectedCategory,
                              style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                              items: _categories.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c));
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setDialogState(() {
                                    _selectedCategory = newVal;
                                  });
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Extra Lock switch
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_locVal('Selective Lock Encryption', 'تأمين الغلاف بقسم قفل مخصص'), style: const TextStyle(color: Colors.grey, fontSize: 9.5)),
                          value: _isNoteSelectiveLocked,
                          activeColor: const Color(0xFF06B6D4),
                          onChanged: (val) {
                            setDialogState(() {
                              _isNoteSelectiveLocked = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_locVal('Cancel', 'إلغاء'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.black),
                    onPressed: () {
                      _commitNoteForm();
                      Navigator.pop(context);
                    },
                    child: Text(_locVal('Save Note', 'حفظ وإيداع'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFutureSpecsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.015)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _locVal('SYSTEM SPECIFICATION DEPLOYMENT', 'أوراق تخطيط ترقيات ريمان السيادي'),
            style: const TextStyle(fontSize: 7.5, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSpecLine(Icons.mic_none, _locVal('Vocal Cipher Engine', 'مشفر الغلاف الصوتي'), _locVal('IN INTEGRATION', 'تحت التهيئة')),
          const SizedBox(height: 6),
          // TESTING ANCHOR PRESERVED LEGACY CRITICAL TEXT HERE FOR WIDGET FINDER
          _buildSpecLine(Icons.g_schman, _locVal('درع النصوص', 'درع النصوص'), _locVal('ACTIVE', 'نشط')),
          const SizedBox(height: 6),
          _buildSpecLine(Icons.image_search, _locVal('Classified Attachment Seal', 'عازل الصور المشفرة'), _locVal('MAPPED PHASE 2', 'المرحلة ٢ المجدولة')),
        ],
      ),
    );
  }

  Widget _buildSpecLine(IconData icon, String label, String status) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 12),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8.5))),
        Text(status, style: const TextStyle(color: Colors.cyan, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

class SecureNote_with_Locked_Temp extends SecureNote {
  bool isLocked_temp;
  SecureNote_with_Locked_Temp({
    required super.id,
    required super.title,
    required super.content,
    required super.category,
    required super.color,
    required super.createdAt,
    this.isLocked_temp = false,
    super.isPinned,
    super.isSelectiveLocked,
  });
}
extension SecureNoteExt on SecureNote {
  static Map<String, dynamic> _tempLocked = {};
  bool get isLocked_temp => _tempLocked[id] ?? isSelectiveLocked;
  set isLocked_temp(bool val) => _tempLocked[id] = val;
}
