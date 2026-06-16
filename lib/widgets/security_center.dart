import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';
import '../utils/vault_service.dart';

class SecurityCenterWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const SecurityCenterWidget({
    super.key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  });

  @override
  State<SecurityCenterWidget> createState() => _SecurityCenterWidgetState();
}

class _SecurityCenterWidgetState extends State<SecurityCenterWidget> {
  final VaultService _vaultService = VaultService();
  final TextEditingController _passCtrl = TextEditingController();

  // Password Analyzer states
  String _pwdStrength = 'Weak';
  int _pwdEntropy = 0;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  // Secure clipboard simulation test
  final TextEditingController _clipTestCtrl = TextEditingController();
  Timer? _clipboardTimer;
  int _clipSecondsLeft = 0;
  bool _hasCopiedData = false;

  @override
  void initState() {
    super.initState();
    _vaultService.addListener(_onServiceUpdate);
    _passCtrl.addListener(_analyzePassword);
  }

  @override
  void dispose() {
    _vaultService.removeListener(_onServiceUpdate);
    _passCtrl.dispose();
    _clipTestCtrl.dispose();
    _clipboardTimer?.cancel();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  // Real-time password analyzer logic
  void _analyzePassword() {
    final text = _passCtrl.text;
    if (text.isEmpty) {
      setState(() {
        _pwdStrength = 'Weak';
        _pwdEntropy = 0;
        _hasUpper = false;
        _hasLower = false;
        _hasNumber = false;
        _hasSpecial = false;
      });
      return;
    }

    final hasUpper = text.contains(RegExp(r'[A-Z]'));
    final hasLower = text.contains(RegExp(r'[a-z]'));
    final hasNumber = text.contains(RegExp(r'[0-9]'));
    final hasSpecial = text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    int poolSize = 0;
    if (hasLower) poolSize += 26;
    if (hasUpper) poolSize += 26;
    if (hasNumber) poolSize += 10;
    if (hasSpecial) poolSize += 32;

    final entropy = text.length * 4; // Simplified realistic approximate representation

    String strength = 'Weak';
    if (text.length >= 12 && hasUpper && hasLower && hasNumber && hasSpecial) {
      strength = 'Very Strong';
    } else if (text.length >= 8 && (hasUpper || hasNumber) && hasLower) {
      strength = 'Strong';
    } else if (text.length >= 6) {
      strength = 'Medium';
    }

    setState(() {
      _pwdStrength = strength;
      _pwdEntropy = entropy;
      _hasUpper = hasUpper;
      _hasLower = hasLower;
      _hasNumber = hasNumber;
      _hasSpecial = hasSpecial;
    });
  }

  // Security Score calculation logic identical to web spec
  int _calculateSecurityScore() {
    int score = 10; // Base baseline

    // Biometrics enabled (+15)
    if (_vaultService.biometricEnabled) {
      score += 15;
    }

    // Recovery Key generated (+20)
    if (_vaultService.recoveryKeyAvailable) {
      score += 20;
    }

    // Passphrase level
    if (_pwdStrength == 'Medium') {
      score += 15;
    } else if (_pwdStrength == 'Strong') {
      score += 30;
    } else if (_pwdStrength == 'Very Strong') {
      score += 55;
    }

    // Deducts
    if (_vaultService.vaults.isEmpty) {
      score -= 10;
    }

    if (score > 100) score = 100;
    if (score < 0) score = 0;

    return score;
  }

  // Trigger Fingerprint scan simulation
  void _triggerBiometricDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _BiometricScanDialog(
          locale: widget.locale,
          isTurningOn: !_vaultService.biometricEnabled,
          onComplete: (success) {
            if (success) {
              _vaultService.setBiometricEnabled(!_vaultService.biometricEnabled);
              widget.onSecurityLog(
                _vaultService.biometricEnabled ? 'Simulated biometric added' : 'Biometric credentials removed',
                'info',
                'Device biometrics state was requested and accepted.',
              );
              widget.onSuccess(
                _vaultService.biometricEnabled
                    ? _locVal('Fingerprint added successfully!', 'تم تسجيل البصمة بنجاح آلياً!')
                    : _locVal('Fingerprint removed!', 'تم إزالة البصمة من النظام!'),
                'success',
              );
            }
          },
        );
      },
    );
  }

  // Trigger Recovery generator dialog
  void _triggerRecoveryDialog() {
    _vaultService.generateRecoveryKey();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF06B6D4), width: 1),
          ),
          icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF06B6D4), size: 36),
          title: Text(
            _locVal('Quantum Recovery Key', 'مفتاح الطوارئ السيادي'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'monospace'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _locVal(
                  'Write down this generated offline seed. In case you lose your passphrases, this key can restore the file segments.',
                  'قم بحفظ وتدوين مفتاح الطوارئ هذا في مكان مادي آمن. في حال نسيان الرقم السري، لن يعمل أي تشفير وسيط دون هذا المفتاح.',
                ),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: SelectableText(
                  _vaultService.recoveryKey ?? 'N/A',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06B6D4),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _vaultService.recoveryKey ?? ''));
                widget.onSuccess(
                  _locVal('Recovery key copied to clipboard', 'تم نسخ مفتاح الطوارئ للحافظة'),
                  'success',
                );
                Navigator.of(context).pop();
              },
              child: Text(_locVal('COPY', 'نسخ'), style: const TextStyle(color: Color(0xFF06B6D4))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_locVal('CLOSE', 'إغلاق'), style: const TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  // Simulated secure clipboard copier action
  void _executeSecureClipboardCopy() {
    final text = _clipTestCtrl.text.trim();
    if (text.isEmpty) {
      widget.onSuccess(_locVal('Please enter some text to test', 'يرجى كتابة نص لتجربة الحافظة'), 'error');
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    _clipboardTimer?.cancel();

    final int duration = _vaultService.clipboardClearDurationSeconds;
    setState(() {
      _clipSecondsLeft = duration;
      _hasCopiedData = true;
    });

    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_clipSecondsLeft > 1) {
          _clipSecondsLeft--;
        } else {
          Clipboard.setData(const ClipboardData(text: ''));
          _clipSecondsLeft = 0;
          _hasCopiedData = false;
          timer.cancel();
          widget.onSecurityLog(
            'Secure Clipboard Cleared',
            'success',
            'Security timer expired. Clipboard buffers successfully zeroed out.',
          );
          _clipTestCtrl.clear();
        }
      });
    });

    widget.onSecurityLog(
      'Sovereign secure clipboard armed',
      'warning',
      'User copied data with a $duration second purge timer active.',
    );
    widget.onSuccess(
      _locVal('Copied! Clipboard will auto-clear in $duration seconds.', 'تم النسخ! سيتم تفريغ الحافظة تلقائياً بعد $duration ثانية.'),
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final int score = _calculateSecurityScore();
    Color scoreColor = const Color(0xFFEF4444); // At risk
    String scoreLabel = _locVal('AT RISK', 'غير آمن (حرج)');

    if (score >= 90) {
      scoreColor = const Color(0xFF10B981); // Excellent
      scoreLabel = _locVal('EXCELLENT', 'ممتاز وصارم');
    } else if (score >= 70) {
      scoreColor = const Color(0xFF06B6D4); // Good
      scoreLabel = _locVal('GOOD PROTECTION', 'أمان جيد');
    } else if (score >= 50) {
      scoreColor = Colors.amber; // Fair
      scoreLabel = _locVal('FAIR SECURITY', 'أمان متوسط');
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // HEADER ROW with Emergency Lock Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locVal('Sovereign Security Center', 'مركز أمان وإدارة التحقق'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _locVal('Sovereign mathematical score evaluation', 'تقييم معيار سلامة وحصانة الأصفار النشطة'),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _vaultService.setLocked(true);
                  widget.onSecurityLog('Emergency Lock Active', 'critical', 'Immediate manual panic protocol initialization.');
                  widget.onSuccess(
                    _locVal('Lock activated! System caches purged.', 'تم غلق وتجميد جميع الخزائن ومسح بيانات الجلسة!'),
                    'error',
                  );
                },
                icon: const Icon(Icons.emergency, size: 12, color: Colors.white),
                label: Text(
                  _locVal('EMERGENCY LOCK', 'قفل الطوارئ'),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B), // rose-800
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.black45,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFF43F5E), width: 0.5),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // TOP AREA (Score widget & Checklist layout)
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildScorePanel(score, scoreColor, scoreLabel)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildHealthChecklistList()),
                  ],
                )
              : Column(
                  children: [
                    _buildScorePanel(score, scoreColor, scoreLabel),
                    const SizedBox(height: 16),
                    _buildHealthChecklistList(),
                  ],
                ),
          const SizedBox(height: 16),

          // MIDDLE AREA (Password Strength Analyzer & Clipboard Setup)
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPasswordStrengthPanel()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildClipboardSecurityPanel()),
                  ],
                )
              : Column(
                  children: [
                    _buildPasswordStrengthPanel(),
                    const SizedBox(height: 16),
                    _buildClipboardSecurityPanel(),
                  ],
                ),
          const SizedBox(height: 16),

          // BOTTOM AREA (Active Protection Toggles)
          _buildProtectionSettingsAndRecommendations(),
        ],
      ),
    );
  }

  // 1. Dynamic Score Evaluation circular widget
  Widget _buildScorePanel(int score, Color scoreColor, String scoreLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Text(
            _locVal('Sovereign Security Score', 'درجة الفحص السيادي'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.04),
                  color: scoreColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontFamily: 'monospace'),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.2)),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(color: scoreColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          )
        ],
      ),
    );
  }

  // 3. Vault Health checklist showing active/inactive elements
  Widget _buildHealthChecklistList() {
    final bool isWeak = _pwdStrength == 'Weak';
    final bool isRecoveryConfigured = _vaultService.recoveryKeyAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Color(0xFF06B6D4), size: 14),
              const SizedBox(width: 8),
              Text(
                _locVal('Sovereign Vault Health Monitor', 'مراقب سلامة الخزائن وعمليات التشفير'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HealthIndicatorRow(
            title: _locVal('Encryption Core Active', 'نشاط محرك التشفير الأساسي'),
            status: _locVal('AES-256-GCM Locked', 'محكم بـ AES-256-GCM'),
            isHealthy: true,
          ),
          _HealthIndicatorRow(
            title: _locVal('Smart Vault Protected', 'حماية كتل الخزائن الموزعة'),
            status: _vaultService.vaults.isNotEmpty
                ? _locVal('${_vaultService.vaults.length} Vaults Online', 'الخزائن (${_vaultService.vaults.length}) مؤمنة')
                : _locVal('Database Empty', 'الخزائن شاغرة'),
            isHealthy: _vaultService.vaults.isNotEmpty,
          ),
          _HealthIndicatorRow(
            title: _locVal('Offline Key Recovery', 'مفتاح الاستعادة والإنقاذ'),
            status: isRecoveryConfigured ? _locVal('Configured', 'مفعّل وصارم') : _locVal('MISSING RECOVERY', 'مفقود (خطر)'),
            isHealthy: isRecoveryConfigured,
            isWarning: !isRecoveryConfigured,
          ),
          _HealthIndicatorRow(
            title: _locVal('Strong Master Passphrase', 'متانة أصفار المرور الفورية'),
            status: isWeak ? _locVal('WEAK KEY', 'ضعيف وغير آمن') : _locVal('SECURE ENTROPY', 'آمن وعشوائي'),
            isHealthy: !isWeak,
            isWarning: isWeak,
          ),
        ],
      ),
    );
  }

  // 2. Real-time Password Strength Analyzer Widget
  Widget _buildPasswordStrengthPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Color(0xFF06B6D4), size: 14),
              const SizedBox(width: 8),
              Text(
                _locVal('Passphrase Strength Auditor', 'محاكي ومدقق جودة أصفار المرور'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Enter a passphrase to test strength...', 'أدخل كلمة مرور لاختبار العشوائية المقدرة...'),
              hintStyle: TextStyle(color: Colors.grey.shade650, fontSize: 10, fontFamily: 'monospace'),
              filled: true,
              fillColor: Colors.black38,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF06B6D4)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locVal('Audit Class: ', 'درجة المتانة: '),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontFamily: 'monospace'),
              ),
              Text(
                _pwdStrength.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _pwdStrength == 'Weak' ? const Color(0xFFEF4444) :
                         _pwdStrength == 'Medium' ? Colors.amber :
                         _pwdStrength == 'Strong' ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locVal('Information Entropy: ', 'مؤشر العشوائية الكلي: '),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontFamily: 'monospace'),
              ),
              Text(
                '$_pwdEntropy bits',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 9, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Segmented progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _pwdStrength == 'Weak' ? const Color(0xFFEF4444) :
                           _pwdStrength == 'Medium' ? Colors.amber :
                           _pwdStrength == 'Strong' ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _pwdStrength == 'Weak' ? Colors.white.withOpacity(0.04) :
                           _pwdStrength == 'Medium' ? Colors.amber :
                           _pwdStrength == 'Strong' ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _pwdStrength == 'Weak' || _pwdStrength == 'Medium' ? Colors.white.withOpacity(0.04) :
                           _pwdStrength == 'Strong' ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _pwdStrength == 'Very Strong' ? const Color(0xFF10B981) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Secure Timer-Based Clipboard auto-clear panel
  Widget _buildClipboardSecurityPanel() {
    final int delay = _vaultService.clipboardClearDurationSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF06B6D4), size: 14),
              const SizedBox(width: 8),
              Text(
                _locVal('Sovereign Clipboard Controller', 'متحكم الحافظة الأمنية للتطبيق'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _locVal('Purge Timer: ', 'مؤقت التفريغ: '),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontFamily: 'monospace'),
              ),
              const Spacer(),
              Row(
                children: [30, 60, 120].map((sec) {
                  final active = delay == sec;
                  return GestureDetector(
                    onTap: () {
                      _vaultService.setClipboardClearDurationSeconds(sec);
                      widget.onSuccess(_locVal('Purge timer shifted to $sec seconds', 'تغير وقت الحذف لـ $sec ثانية'), 'success');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0F172A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? const Color(0xFF06B6D4) : Colors.white.withOpacity(0.04)),
                      ),
                      child: Text(
                        '${sec}s',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.grey.shade500,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Secure clipboard test area
          TextField(
            controller: _clipTestCtrl,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: _locVal('Type and copy sensitive data to test...', 'اكتب نصاً لنسخه واختبار الإتلاف...'),
              hintStyle: TextStyle(color: Colors.grey.shade655, fontSize: 10, fontFamily: 'monospace'),
              filled: true,
              fillColor: Colors.black38,
              suffixIcon: GestureDetector(
                onTap: _executeSecureClipboardCopy,
                child: const Icon(Icons.copy, color: Color(0xFF06B6D4), size: 16),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF06B6D4)),
              ),
            ),
          ),
          if (_hasCopiedData && _clipSecondsLeft > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.amber, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    _locVal('PURGING MEMORY IN ${_clipSecondsLeft}S', 'سيتم تفريغ الحافظة خلال ${_clipSecondsLeft} ثانية'),
                    style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  // 7. Protection setting toggle with recommendations cards
  Widget _buildProtectionSettingsAndRecommendations() {
    final bool bioEnabled = _vaultService.biometricEnabled;
    final bool isRecoveryConfigured = _vaultService.recoveryKeyAvailable;
    final bool isWeak = _pwdStrength == 'Weak';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_outlined, color: Color(0xFF06B6D4), size: 14),
              const SizedBox(width: 8),
              Text(
                _locVal('Sovereign Protection Settings & Recommendations', 'إعدادات الحماية والتوصيات النشطة'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Simulated Biometric setting
          SwitchListTile(
            value: bioEnabled,
            onChanged: (val) => _triggerBiometricDialog(),
            activeColor: const Color(0xFF06B6D4),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _locVal('Simulated Biometric Authentication', 'محاكاة البصمة الحيوية الفعالة'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
            ),
            subtitle: Text(
              _locVal('Forces biometric scan simulation checks inside decryption segments.', 'يتطلب الولوج وتأكيد مطابقة الهوية الحيوية قبل فك الأرشيفات.'),
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
            ),
          ),
          const Divider(height: 12, color: Colors.white10),
          
          // Simulated Recovery key configuration
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _locVal('Sovereign Offline Recovery Key', 'مفاتيح الاستعادة والإنقاذ بدون شبكة'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
            ),
            subtitle: Text(
              isRecoveryConfigured
                  ? _locVal('A recovery core backup is active.', 'رمز فك الرموز النشط جاهز ومرتسم.')
                  : _locVal('Emergency backup bypass offline key isn\'t configured.', 'لم تقم بتعيين مفتاح الاستعادة والإنقاذ المادي.'),
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
            ),
            trailing: ElevatedButton(
              onPressed: _triggerRecoveryDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D3A),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isRecoveryConfigured ? _locVal('REGENT', 'تحديث') : _locVal('CREATE KEY', 'توليد'),
                style: const TextStyle(fontSize: 8, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ),
          
          // Recommendations listings
          if (!isRecoveryConfigured || !bioEnabled || isWeak) ...[
            const SizedBox(height: 8),
            const Divider(height: 12, color: Colors.white10),
            const SizedBox(height: 6),
            Text(
              _locVal('Active Shield Recommendations', 'توصيات جدران الحماية المعلقة'),
              style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (!isRecoveryConfigured) 
                    _RecommendationCard(
                      title: _locVal('No Recovery Configuration (+20 pts)', 'توليد مفتاح الإنقاذ والاستيراد (+20)'),
                      btnLabel: _locVal('Create offline key →', 'توليد المفتاح الآن ←'),
                      onTap: _triggerRecoveryDialog,
                      color: const Color(0xFF991B1B).withOpacity(0.1),
                    ),
                  if (!bioEnabled) 
                    _RecommendationCard(
                      title: _locVal('Simulated Biometrics Off (+15 pts)', 'محاكاة البصمة غير نشطة (+15)'),
                      btnLabel: _locVal('Enable scan →', 'تفعيل المطابقة الحيوية الآن ←'),
                      onTap: _triggerBiometricDialog,
                      color: Colors.amber.withOpacity(0.05),
                    ),
                  if (isWeak) 
                    _RecommendationCard(
                      title: _locVal('Tighten Passphrase Entropy (+30 pts)', 'تقوية عشوائية المرور (+30)'),
                      btnLabel: _locVal('Use maximum entropy passphrase', 'أدخل كلمة مرور مطابقة للمعايير'),
                      onTap: () {},
                      color: const Color(0xFF0F2D3A).withOpacity(0.2),
                    ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _HealthIndicatorRow extends StatelessWidget {
  final String title;
  final String status;
  final bool isHealthy;
  final bool isWarning;

  const _HealthIndicatorRow({
    required this.title,
    required this.status,
    required this.isHealthy,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorTheme = const Color(0xFF10B981); // Solid Emerald Green
    IconData icon = Icons.check_circle_outline;

    if (isWarning) {
      indicatorTheme = Colors.amber;
      icon = Icons.warning_amber_outlined;
    } else if (!isHealthy) {
      indicatorTheme = const Color(0xFFEF4444);
      icon = Icons.error_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: indicatorTheme, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: indicatorTheme.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: indicatorTheme.withOpacity(0.1)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: indicatorTheme, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String btnLabel;
  final VoidCallback onTap;
  final Color color;

  const _RecommendationCard({
    required this.title,
    required this.btnLabel,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            child: Text(
              btnLabel,
              style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          )
        ],
      ),
    );
  }
}

class _BiometricScanDialog extends StatefulWidget {
  final String locale;
  final bool isTurningOn;
  final Function(bool) onComplete;

  const _BiometricScanDialog({
    required this.locale,
    required this.isTurningOn,
    required this.onComplete,
  });

  @override
  State<_BiometricScanDialog> createState() => _BiometricScanDialogState();
}

class _BiometricScanDialogState extends State<_BiometricScanDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _scanStatus = '';
  bool _scanSucceeded = false;

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  @override
  void initState() {
    super.initState();
    _scanStatus = _locVal('Place finger on screen scanner...', 'يرجى وضع الأصبع على مستشعر البصمة للمطابقة...');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startSimulatedScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startSimulatedScan() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _scanStatus = _locVal('ANALYZING CRYPTO-BIOMETRICS VECTOR...', 'جاري مطابقة إحداثيات البصمة التشفيرية...');
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _scanSucceeded = true;
          _scanStatus = _locVal('AUTHENTICATION VALIDATED. KEY DECRYPTED SUCCESS.', 'تم تأكيد البوية والتحقق من التناسق ثنائي الأصفار.');
        });

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onComplete(true);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1224),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF06B6D4), width: 0.8),
      ),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _locVal('Secure Biometrics Portal', 'نظام البصمة الحيوية الآمن'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _scanSucceeded
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF06B6D4).withOpacity(0.08 * _pulseController.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _scanSucceeded ? const Color(0xFF10B981) : const Color(0xFF06B6D4).withOpacity(0.3 + 0.7 * _pulseController.value),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 52,
                    color: _scanSucceeded ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _scanStatus,
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.white, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              height: 2,
              width: 140,
              color: _scanSucceeded ? const Color(0xFF10B981) : const Color(0xFF06B6D4).withOpacity(0.2),
            )
          ],
        ),
      ),
    );
  }
}
