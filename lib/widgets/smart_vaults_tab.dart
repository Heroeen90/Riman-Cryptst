import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../utils/vault_service.dart';

class SmartVaultsTab extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SmartVaultsTab({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SmartVaultsTab> createState() => _SmartVaultsTabState();
}

class _SmartVaultsTabState extends State<SmartVaultsTab> {
  final VaultService _vaultService = VaultService();

  // Active highlighted vault ID (null means all / none selected)
  String? _selectedVaultId;

  // New Vault Form inputs
  final TextEditingController _vaultNameCtrl = TextEditingController();
  final TextEditingController _vaultDescCtrl = TextEditingController();

  // New Category input
  final TextEditingController _newCategoryCtrl = TextEditingController();

  // Register file inputs
  String? _selectedFileVaultId;
  String? _selectedFileCategory;
  final TextEditingController _fileNameCtrl = TextEditingController();
  final TextEditingController _filePasswordCtrl = TextEditingController();
  
  // Simulated available files list to choose from (realistic names for prompt requirements)
  final List<Map<String, dynamic>> _simulatedUploadFiles = [
    {'name': 'military_coordinates.kml', 'size': 456000, 'size_str': '445 KB'},
    {'name': 'blockchain_ledger.xlsx', 'size': 12050000, 'size_str': '11.4 MB'},
    {'name': 'private_key_entropy.pem', 'size': 2048, 'size_str': '2 KB'},
    {'name': 'intelligence_brief.docx', 'size': 675000, 'size_str': '659 KB'},
    {'name': 'classified_images.zip', 'size': 34500000, 'size_str': '32.9 MB'},
  ];
  Map<String, dynamic>? _selectedRawUploadFile;

  bool _isAutoEncrypting = false;

  @override
  void initState() {
    super.initState();
    _selectedRawUploadFile = _simulatedUploadFiles[0];
    _vaultService.addListener(_onVaultServiceUpdate);
    
    // Default form values
    if (_vaultService.vaults.isNotEmpty) {
      _selectedFileVaultId = _vaultService.vaults[0].id;
    }
    if (_vaultService.categories.isNotEmpty) {
      _selectedFileCategory = _vaultService.categories[0];
    }
  }

  @override
  void dispose() {
    _vaultService.removeListener(_onVaultServiceUpdate);
    _vaultNameCtrl.dispose();
    _vaultDescCtrl.dispose();
    _newCategoryCtrl.dispose();
    _fileNameCtrl.dispose();
    _filePasswordCtrl.dispose();
    super.dispose();
  }

  void _onVaultServiceUpdate() {
    if (mounted) {
      setState(() {
        if (_selectedFileVaultId == null && _vaultService.vaults.isNotEmpty) {
          _selectedFileVaultId = _vaultService.vaults[0].id;
        }
      });
    }
  }

  // Translates custom key or maps back to translations
  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  void _createNewVault() {
    final name = _vaultNameCtrl.text.trim();
    final desc = _vaultDescCtrl.text.trim();

    if (name.isEmpty) {
      widget.onSuccess(
        _locVal('Vault name cannot be empty', 'اسم الخزنة لا يمكن أن يكون فارغاً'),
        'error',
      );
      return;
    }

    _vaultService.createVault(name: name, description: desc);
    _vaultNameCtrl.clear();
    _vaultDescCtrl.clear();
    Navigator.of(context).pop();

    widget.onSuccess(
      _locVal('Successfully initialized "$name"', 'تم تهيئة الخزنة "$name" بنجاح'),
      'success',
    );
  }

  void _registerCustomCategory() {
    final catRaw = _newCategoryCtrl.text.trim();
    if (catRaw.isEmpty) return;

    if (_vaultService.categories.contains(catRaw)) {
      widget.onSuccess(_locVal('Category already exists', 'هذا التصنيف متوفر بالفعل'), 'error');
      return;
    }

    _vaultService.registerCategory(catRaw);
    _newCategoryCtrl.clear();
    setState(() {
      _selectedFileCategory = catRaw;
    });

    widget.onSuccess(
      _locVal('Added category: $catRaw', 'تمت إضافة التصنيف: $catRaw'),
      'success',
    );
  }

  // Handle auto-encryption flow
  void _executeSmartImport() {
    if (_selectedFileVaultId == null) {
      widget.onSuccess(_locVal('Please select a target vault', 'يرجى تحديد الخزنة المستهدفة'), 'error');
      return;
    }
    if (_selectedFileCategory == null) {
      widget.onSuccess(_locVal('Select or register a file category', 'يرجى تحديد أو تسجيل تصنيف للملف'), 'error');
      return;
    }
    if (_filePasswordCtrl.text.isEmpty) {
      widget.onSuccess(_locVal('Sovereign password is required', 'كلمة سر الحماية مطلوبة للتشفير تلقائياً'), 'error');
      return;
    }

    setState(() {
      _isAutoEncrypting = true;
    });

    final targetVault = _vaultService.vaults.firstWhere((v) => v.id == _selectedFileVaultId);
    final fileObj = _selectedRawUploadFile!;

    widget.onSecurityLog(
      'Automated Vault Import Initiated',
      'info',
      'Integrating "${fileObj['name']}" into "${targetVault.name}". Preparing cipher matrix.',
    );

    // Simulate standard triple pipeline delays
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      _vaultService.registerFileAndEncrypt(
        vaultId: _selectedFileVaultId!,
        originalName: fileObj['name'],
        category: _selectedFileCategory!,
        sizeInBytes: fileObj['size'],
        sizeFormatted: fileObj['size_str'],
      );

      widget.onSecurityLog(
        'Asset Encrypted Automatically',
        'success',
        'Secured payload coordinates for "${fileObj['name']}" (category: $_selectedFileCategory) using matching key parameters.',
      );

      setState(() {
        _isAutoEncrypting = false;
        _filePasswordCtrl.clear();
        // Cycle file to simulate another select options
        final curIdx = _simulatedUploadFiles.indexOf(_selectedRawUploadFile!);
        final nextIdx = (curIdx + 1) % _simulatedUploadFiles.length;
        _selectedRawUploadFile = _simulatedUploadFiles[nextIdx];
      });

      widget.onSuccess(
        _locVal('Asset encrypted & registered in "${targetVault.name}"!', 'تم تشفير وتثبيت الملف في الخزنة "${targetVault.name}" تلقائياً!'),
        'success',
      );
    });
  }

  Widget _buildActivityIcon(String type) {
    switch (type) {
      case 'file_encrypted':
        return const Icon(Icons.enhanced_encryption, color: Color(0xFF06B6D4), size: 14);
      case 'file_added':
        return const Icon(Icons.file_present, color: Color(0xFFA855F7), size: 14);
      case 'file_opened':
        return const Icon(Icons.lock_open, color: Color(0xFF10B981), size: 14);
      case 'file_removed':
        return const Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 14);
      default:
        return const Icon(Icons.offline_bolt, color: Colors.blueAccent, size: 14);
    }
  }

  // Show Vault Creation Sheet or Dialog
  void _showCreateVaultDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111827),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _locVal('Create Sovereign Vault', 'تأسيس خزنة سيادية جديدة'),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _locVal('Introduce a separate vault structure with specialized metadata context.', 'قم بإنشاء هيكل خزنة مستقل مع محددات توجيهية فريدة للبيانات.'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _vaultNameCtrl,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _locVal('Vault Name', 'اسم الخزنة'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vaultDescCtrl,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _locVal('Vault Description', 'وصف أو مهمة الخزنة'),
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_locVal('Cancel', 'إلغاء'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _createNewVault,
                child: Text(_locVal('Initialize', 'تهيئة وتفويض'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 850;

    return Directionality(
      textDirection: widget.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Feature 2: Vault Dashboard Summary Widget
            _buildVaultDashboardSummary(screenWidth),
            
            const SizedBox(height: 16),
            
            // Core layout splitting
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vault list (Left)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVaultSectionHeader(),
                            const SizedBox(height: 8),
                            _buildVaultsListGrid(gridCount: 2),
                            const SizedBox(height: 16),
                            _buildVaultFilesGrid(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Import/Register controls & timeline (Right)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSmartRegisterCard(),
                            const SizedBox(height: 16),
                            _buildCategoryManagerPanel(),
                            const SizedBox(height: 16),
                            _buildRecentActivityTimeline(),
                          ],
                        ),
                      ),
                    ]
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildVaultSectionHeader(),
                      const SizedBox(height: 8),
                      _buildVaultsListGrid(gridCount: 1),
                      const SizedBox(height: 16),
                      _buildSmartRegisterCard(),
                      const SizedBox(height: 16),
                      _buildVaultFilesGrid(),
                      const SizedBox(height: 16),
                      _buildCategoryManagerPanel(),
                      const SizedBox(height: 16),
                      _buildRecentActivityTimeline(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Dashboard Overview Metrics Panel
  Widget _buildVaultDashboardSummary(double screenWidth) {
    final int vCount = _vaultService.totalVaultsCount;
    final int fCount = _vaultService.totalFilesCount;
    final String fSize = _vaultService.totalSizeFormatted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate card base
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 16),
              const SizedBox(width: 8),
              Text(
                _locVal('SMART VAULT SYSTEM OVERVIEW', 'نظام إدارة الخزائن الذكية السيادي'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _locVal('V2.0 FOUNDATION', 'الإصدار 2.0 التأسيسي'),
                  style: const TextStyle(fontSize: 8, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isNarrow ? 1 : 3,
                childAspectRatio: isNarrow ? 4.0 : 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildDashboardMetricTile(
                    label: _locVal('Total Vaults', 'إجمالي الخزائن'),
                    val: vCount.toString(),
                    icon: Icons.dns_outlined,
                    color: const Color(0xFF06B6D4),
                  ),
                  _buildDashboardMetricTile(
                    label: _locVal('Total Files', 'إجمالي الملفات'),
                    val: fCount.toString(),
                    icon: Icons.file_copy_outlined,
                    color: const Color(0xFFA855F7),
                  ),
                  _buildDashboardMetricTile(
                    label: _locVal('Protected Size', 'حجم البيانات المحمية'),
                    val: fSize,
                    icon: Icons.speed,
                    color: const Color(0xFF10B981),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildDashboardMetricTile({
    required String label,
    required String val,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVaultSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.storage_rounded, color: Color(0xFF06B6D4), size: 16),
            const SizedBox(width: 8),
            Text(
              _locVal('Active Vault Managers', 'الخزائن المعزولة المفوضة'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
            foregroundColor: const Color(0xFF06B6D4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF06B6D4), width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          onPressed: _showCreateVaultDialog,
          icon: const Icon(Icons.add, size: 12),
          label: Text(
            _locVal('New Vault', 'خزنة جديدة'),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildVaultsListGrid({required int gridCount}) {
    final vaults = _vaultService.vaults;
    if (vaults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _locVal('No Active Vaults. Initialize your first safe room.', 'لا توجد خزائن معزولة مفعلة. أنشئ خزنة جديدة لبدء الحماية.'),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vaults.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, idx) {
            final v = vaults[idx];
            final isHighlighted = _selectedVaultId == v.id;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedVaultId = isHighlighted ? null : v.id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHighlighted ? const Color(0xFF1E1B4B) : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHighlighted ? const Color(0xFFA855F7) : Colors.white.withOpacity(0.04),
                    width: isHighlighted ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_special,
                          color: isHighlighted ? const Color(0xFFA855F7) : const Color(0xFF06B6D4),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Quick Delete
                        if (v.id != 'v_personal_01' && v.id != 'v_documents_02')
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 12),
                            onPressed: () {
                              _vaultService.deleteVault(v.id);
                              if (_selectedVaultId == v.id) _selectedVaultId = null;
                              widget.onSuccess(_locVal('Dismantled Vault!', 'تم إلغاء وتفكيك الخزنة!'), 'success');
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        v.description,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 8.5, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(height: 12, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _locVal('Files: ${v.files.length}', 'الملفات: ${v.files.length}'),
                          style: const TextStyle(fontSize: 8, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          v.totalSizeFormatted,
                          style: const TextStyle(fontSize: 8, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  // Feature 4 & 5: Smart File Registration and Automatic Encryption Front-end
  Widget _buildSmartRegisterCard() {
    final availableVaults = _vaultService.vaults;
    final availableCategories = _vaultService.categories;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF06B6D4), size: 16),
              const SizedBox(width: 8),
              Text(
                _locVal('Smart File Registration', 'التسجيل الذكي المشفر للملفات'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _locVal('Select a target file & destination vault. Asset is automatically encrypted via Riemann dual flow upon entry.', 'اختر ملف تصويري وخزنة مستهدفة. سيقوم النظام بتشفير الملف تلقائياً فور تسجيله.'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
          ),
          const Divider(height: 24, color: Colors.white12),

          // File Cycle Selector
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: Color(0xFF06B6D4), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedRawUploadFile!['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedRawUploadFile!['size_str'],
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Cycles raw file list
                    final curIdx = _simulatedUploadFiles.indexOf(_selectedRawUploadFile!);
                    final nextIdx = (curIdx + 1) % _simulatedUploadFiles.length;
                    setState(() {
                      _selectedRawUploadFile = _simulatedUploadFiles[nextIdx];
                    });
                    widget.onSuccess(_locVal('File target changed!', 'تم تغيير ملف الاستهداف!'), 'success');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _locVal('Browse', 'تغيير الملف'),
                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Target Vault Dropdown Selector
          Text(
            _locVal('Target Sovereign Vault', 'الخزنة المستهدفة للإيداع'),
            style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (availableVaults.isEmpty)
            Text(
              _locVal('Please create a vault first', 'يرجى تهيئة خزنة واحدة أولاً'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 9),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: const Color(0xFF111827),
                  isExpanded: true,
                  value: _selectedFileVaultId ?? (availableVaults.isNotEmpty ? availableVaults[0].id : null),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  items: availableVaults.map((v) {
                    return DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(v.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFileVaultId = val;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Category Dropdown List
          Text(
            _locVal('Asset Category', 'تصنيف مستندات الملف'),
            style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF111827),
                isExpanded: true,
                value: _selectedFileCategory ?? (availableCategories.isNotEmpty ? availableCategories[0] : null),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                items: availableCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedFileCategory = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Security Protection Password input
          Text(
            _locVal('File Encryption Password', 'كلمة سر التفويض والتشفير'),
            style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: TextField(
              controller: _filePasswordCtrl,
              obscureText: true,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _locVal('Password to secure this asset...', 'أدخل كلمة مرور قوية لقفل الملف...'),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 9.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Register Action trigger
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              disabledForegroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isAutoEncrypting ? null : _executeSmartImport,
            child: _isAutoEncrypting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _locVal('Encrypting & Logging Payload...', 'تشفير وحظر الطيف للبيانات...'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    ],
                  )
                : Text(
                    _locVal('REGISTER & ENCRYPT ASSET', 'تأكيد التسجيل والتشفير الذكي'),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
          )
        ],
      ),
    );
  }

  // Files of selected Vault grid
  Widget _buildVaultFilesGrid() {
    final String? activeId = _selectedVaultId;
    if (activeId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Text(
          _locVal('💡 Select a Specific Vault to inspect files and structures.', '💡 حدد خزنة معينة لمراجعة محتوياتها من الملفات والأغلفة.'),
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      );
    }

    final targetVault = _vaultService.vaults.firstWhere((v) => v.id == activeId, orElse: () => _vaultService.vaults[0]);
    final filesList = targetVault.files;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.topic, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locVal('Contained Files: ${targetVault.name}', 'المحتويات المؤرشفة بـ (${targetVault.name})'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                targetVault.totalSizeFormatted,
                style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              )
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          if (filesList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                _locVal('No shielded files inside this vault container.', 'لا توجد مستندات مسجلة بداخل فضاء هذه الخزنة.'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filesList.length,
              itemBuilder: (context, idx) {
                final f = filesList[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f.fileType,
                          style: const TextStyle(fontSize: 8, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.originalName,
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    f.category,
                                    style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f.sizeFormatted,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      // Action Buttons
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.vpn_key, color: Color(0xFF0369A1), size: 14),
                        onPressed: () {
                          _vaultService.openFile(targetVault.id, f.id);
                          widget.onSuccess(_locVal('Sovereign Decryption Tag verified! Original extracted.', 'تم التحقق من تطابق القفل! وفك تشفير الملف بنجاح.'), 'success');
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete, color: Color(0xFF991B1B), size: 14),
                        onPressed: () {
                          _vaultService.removeFile(targetVault.id, f.id);
                          widget.onSuccess(_locVal('File registration purged!', 'تم سحب وإلغاء تسجيل الملف تماماً!'), 'success');
                        },
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Feature 3: File Category Manager & Registrator
  Widget _buildCategoryManagerPanel() {
    final activeCategories = _vaultService.categories;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: Color(0xFFA855F7), size: 16),
              const SizedBox(width: 8),
              Text(
                _locVal('Sovereign Categories', 'التصنيفات المعتمدة للملفات'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _locVal('Manage metadata classification clusters.', 'تتبع وتصنيف الكيانات والمستندات حسب الأغراض المتنوعة.'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
          ),
          const Divider(height: 20, color: Colors.white12),

          // Wrap of chips representing categories
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: activeCategories.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.2)),
                ),
                child: Text(
                  c,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: TextField(
                    controller: _newCategoryCtrl,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _locVal('Add custom category...', 'أضف تصنيف مخصص...'),
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _registerCustomCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA855F7), width: 0.5),
                  ),
                  child: Text(
                    _locVal('Add', 'إضافة'),
                    style: const TextStyle(fontSize: 10, color: Color(0xFFA855F7), fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // Feature 6: Recent Activity timeline
  Widget _buildRecentActivityTimeline() {
    final activitiesList = _vaultService.activities;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off, color: Color(0xFF06B6D4), size: 16),
              const SizedBox(width: 8),
              Text(
                _locVal('Recent Vault Activity', 'سجل العمليات الأخير للخزنات'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _locVal('Dynamic timeline track of internal operations.', 'تدريج زمني دقيق يسجل حركات حفظ وتفكيك وقفل البيانات.'),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
          ),
          const Divider(height: 20, color: Colors.white12),

          if (activitiesList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  _locVal('No activity recorded.', 'لا توجد نشاطات مسجلة بعد.'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(activitiesList.length, 6),
              itemBuilder: (context, idx) {
                final act = activitiesList[idx];
                final String timeStr = '${act.timestamp.hour.toString().padLeft(2, '0')}:${act.timestamp.minute.toString().padLeft(2, '0')}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: _buildActivityIcon(act.type),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              act.description,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 8, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace'),
                      ),
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
