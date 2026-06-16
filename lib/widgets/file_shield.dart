import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/translations.dart';

class FileShieldWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const FileShieldWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<FileShieldWidget> createState() => _FileShieldWidgetState();
}

class _FileShieldWidgetState extends State<FileShieldWidget> {
  // Preset raw files user can choose to "upload" virtually
  final List<Map<String, String>> _rawFilesList = [
    {'name': 'medical_index.db', 'size': '1.4 MB'},
    {'name': 'keys.pem', 'size': '4 KB'},
    {'name': 'private_vault.zip', 'size': '18.6 MB'},
  ];

  Map<String, String>? _selectedRawFile;

  // Encryption Inputs
  String _password = '';
  bool _sealAsTimeCapsule = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  bool _isEncrypting = false;
  bool _encryptionSuccess = false;
  String _generatedRimanFileName = '';

  // Decryption inputs
  String? _selectedRimanFile;
  String _decryptPassword = '';
  bool _isDecrypting = false;
  bool _timeLockActive = false;
  String _timeLockTargetStr = '';

  @override
  void initState() {
    super.initState();
    _selectedRawFile = _rawFilesList[0];
  }

  void _pickRawFileDirectly() {
    // Cycling files
    final int curIdx = _rawFilesList.indexOf(_selectedRawFile!);
    final int nextIdx = (curIdx + 1) % _rawFilesList.length;
    setState(() {
      _selectedRawFile = _rawFilesList[nextIdx];
    });
    widget.onSuccess(
      widget.locale == 'ar' 
          ? 'تم توريد الملف: ${_selectedRawFile!['name']} (${_selectedRawFile!['size']})' 
          : 'Selected file: ${_selectedRawFile!['name']} (${_selectedRawFile!['size']})',
      'success',
    );
  }

  Future<void> _selectUnlockDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectUnlockTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _runFileLockerEncryption() {
    if (_password.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى كتابة كلمة مرور حماية الملف' : 'Please provide file protection password',
        'error',
      );
      return;
    }

    setState(() {
      _isEncrypting = true;
    });

    widget.onSecurityLog(
      'Encapsulating raw file payload',
      'info',
      'File: ${_selectedRawFile!['name']} (${_selectedRawFile!['size']}). Sealed-Chrono: $_sealAsTimeCapsule',
    );

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;

      setState(() {
        _isEncrypting = false;
        _encryptionSuccess = true;
        _generatedRimanFileName = '${_selectedRawFile!['name']}.riman';
      });

      widget.onSecurityLog(
        'Binary asset sealed in mathematical matrix',
        'success',
        'Output compiled: $_generatedRimanFileName. MD5-Check: VALID.',
      );

      widget.onSuccess(
        widget.locale == 'ar' ? 'تم تشفير الملف وضمانه سيادياً بنجاح!' : 'File secured as sovereign quantum container',
        'success',
      );
    });
  }

  void _selectEncryptedContainer() {
    if (!_encryptionSuccess) {
      // populate standard demo
      setState(() {
        _selectedRimanFile = 'financial_ledger_2026.pdf.riman';
        _timeLockActive = true;
        _timeLockTargetStr = '2026-12-25 12:00:00 UTC';
      });
      widget.onSuccess(
        widget.locale == 'ar' ? 'تم إرفاق ملف عرض من تفعيل الكبسولة الكرونولوجية' : 'Attached demo time-locked archive',
        'success',
      );
    } else {
      setState(() {
        _selectedRimanFile = _generatedRimanFileName;
        if (_sealAsTimeCapsule) {
          _timeLockActive = true;
          _timeLockTargetStr = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00 UTC';
        } else {
          _timeLockActive = false;
        }
      });
      widget.onSuccess(
        widget.locale == 'ar' ? 'تم تحديد أرشيفك المشفر بنجاح' : 'Attached encrypted riman archive',
        'success',
      );
    }
  }

  void _reconstituteOriginalAsset() {
    if (_selectedRimanFile == null) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى اختيار ملف ريمان المشفر أولاً' : 'Please select encrypted Riman archive (.riman)',
        'error',
      );
      return;
    }
    if (_decryptPassword.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى كتابة كلمة مرور الأرشيف' : 'Please provide decryption key password',
        'error',
      );
      return;
    }

    if (_timeLockActive) {
      widget.onSecurityLog(
        'Decapsulation denied: Time-lock constraint actively blocking',
        'critical',
        'Archive: $_selectedRimanFile. Lock expires at UTC: $_timeLockTargetStr.',
      );
      widget.onSuccess(
        widget.locale == 'ar' ? 'صلاحية فك التشفير مرفوضة: الملف مغلق بقفل زمني!' : 'Access denied: Capsule time-lock confinement is still active!',
        'error',
      );
      return;
    }

    setState(() {
      _isDecrypting = true;
    });

    widget.onSecurityLog(
      'Reconstituting raw binary stream',
      'warning',
      'Inverting 3rd, 2nd, and 1st mathematics layers for $_selectedRimanFile.',
    );

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;

      setState(() {
        _isDecrypting = false;
      });

      widget.onSecurityLog(
        'Binary file stream reconstituted',
        'success',
        'Filename: ${_selectedRimanFile!.replaceAll('.riman', '')}. Extraction completed cleanly.',
      );

      widget.onSuccess(
        widget.locale == 'ar' ? 'تم التحقق من التوقيع الرقمي واسترداد الملف بنجاح!' : 'Digital tags verified and original file extracted successfully!',
        'success',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDualColumns = screenWidth > 800;

    Widget buildLockerCard() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.file_copy, color: Color(0xFF06B6D4), size: 18),
                const SizedBox(width: 8),
                Text(
                  translate('file_locker_title', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              translate('file_locker_desc', widget.locale),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const Divider(height: 24, color: Colors.white12),

            // Dashed Picker Representation
            InkWell(
              onTap: _pickRawFileDirectly,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 24, color: Color(0xFF06B6D4)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRawFile != null
                          ? '${_selectedRawFile!['name']} (${_selectedRawFile!['size']})'
                          : translate('select_drag_file', widget.locale),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: Center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translate('change_file', widget.locale),
                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Protection
            Text(
              translate('protection_password', widget.locale),
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              obscureText: true,
              onChanged: (val) => _password = val,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: translate('enter_encryption_password', widget.locale),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1)),
              ),
            ),
            const SizedBox(height: 12),

            // Seal Chrono Toggle
            Row(
              children: [
                Checkbox(
                  value: _sealAsTimeCapsule,
                  activeColor: const Color(0xFF06B6D4),
                  onChanged: (val) {
                    setState(() {
                      _sealAsTimeCapsule = val ?? false;
                    });
                  },
                ),
                Text(
                  translate('seal_chrono_capsule', widget.locale),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                )
              ],
            ),

            if (_sealAsTimeCapsule) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectUnlockDate,
                      icon: const Icon(Icons.date_range, size: 14, color: Color(0xFF06B6D4)),
                      label: Text(
                        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectUnlockTime,
                      icon: const Icon(Icons.access_time, size: 14, color: Color(0xFF06B6D4)),
                      label: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  )
                ],
              )
            ],
            const SizedBox(height: 12),

            // Encrypt button
            ElevatedButton(
              onPressed: _isEncrypting ? null : _runFileLockerEncryption,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEncrypting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      translate('encrypt_secure_btn', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
            ),

            if (_encryptionSuccess) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  widget.onSuccess(
                    widget.locale == 'ar' ? 'جاري محاكاة تحميل ملف $_generatedRimanFileName' : 'Downloading secured archive $_generatedRimanFileName...',
                    'success',
                  );
                },
                icon: const Icon(Icons.download, size: 14, color: Color(0xFF34D399)),
                label: Text(
                  translate('download_secured_btn', widget.locale),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF34D399)),
                ),
              )
            ]
          ],
        ),
      );
    }

    Widget buildDecryptorCard() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.unarchive, color: Color(0xFFA855F7), size: 18),
                const SizedBox(width: 8),
                Text(
                  translate('dec_portal_title', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              translate('dec_portal_desc', widget.locale),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const Divider(height: 24, color: Colors.white12),

            // Encrypted attachment box representation
            InkWell(
              onTap: _selectEncryptedContainer,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_person, size: 24, color: Color(0xFFA855F7)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedRimanFile ?? translate('upload_riman_placeholder', widget.locale),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: Center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translate('change_container', widget.locale),
                      style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Match password
            Text(
              translate('capsule_match_password', widget.locale),
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              obscureText: true,
              onChanged: (val) => _decryptPassword = val,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: translate('master_decrypt_placeholder', widget.locale),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1)),
              ),
            ),
            const SizedBox(height: 12),

            // Time Lock warning if active
            if (_timeLockActive) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          translate('time_lock_restriction', widget.locale),
                          style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translateFormat(
                        'time_lock_remaining_utc',
                        widget.locale,
                        {'time': _timeLockTargetStr},
                      ),
                      style: const TextStyle(color: Colors.amber, fontSize: 8),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Reconstitute button
            ElevatedButton(
              onPressed: _isDecrypting ? null : _reconstituteOriginalAsset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isDecrypting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      translate('auth_reconstitute_btn', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      textAlign: Center,
                    ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: useDualColumns
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildLockerCard()),
                const SizedBox(width: 16),
                Expanded(child: buildDecryptorCard()),
              ],
            )
          : Column(
              children: [
                buildLockerCard(),
                const SizedBox(height: 16),
                buildDecryptorCard(),
              ],
            ),
    );
  }
}
