import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/translations.dart';

class TimeCapsulesWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const TimeCapsulesWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<TimeCapsulesWidget> createState() => _TimeCapsulesWidgetState();
}

class _TimeCapsulesWidgetState extends State<TimeCapsulesWidget> {
  late Timer _countdownTimer;

  // Real-time ticking down duration representing a locked premium asset (financial_ledger_2026.pdf)
  int _secondsRemaining = 43200 + 1800 + 42; // ~12 hours, 30 minutes, 42 seconds

  // List of Capsules
  late List<Map<String, dynamic>> _capsules;
  Map<String, dynamic>? _selectedCapsule;

  String _passwordInput = '';
  bool _isDissolving = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _initCapsules();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
      });
    });
  }

  void _initCapsules() {
    _capsules = [
      {
        'id': 'capsule_1',
        'name': 'financial_ledger_2026.pdf',
        'size': '1.4 MB',
        'created': '2026-06-01',
        'isLocked': true,
      },
      {
        'id': 'capsule_2',
        'name': 'android_production_keystore.jks',
        'size': '4 KB',
        'created': '2026-05-12',
        'isLocked': false,
      },
    ];
    _selectedCapsule = _capsules[0];
  }

  String _formattedTimeSpan() {
    final int days = _secondsRemaining ~/ 86400;
    final int hours = (_secondsRemaining % 86400) ~/ 3600;
    final int minutes = (_secondsRemaining % 3600) ~/ 60;
    final int seconds = _secondsRemaining % 60;

    final String dayLabel = translate('day_short', widget.locale);
    final String hourLabel = translate('hour_short', widget.locale);
    final String minLabel = translate('minute_short', widget.locale);
    final String secLabel = translate('second_short', widget.locale);

    return '${days}$dayLabel ${hours}$hourLabel ${minutes}$minLabel ${seconds}$secLabel';
  }

  void _dissolveTimeConfinement() {
    if (_selectedCapsule == null) {
      widget.onSuccess(
        translate('select_active_capsule', widget.locale),
        'error',
      );
      return;
    }
    if (_passwordInput.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى إدخال كلمة سر فك التشفير والتذويب' : 'Enter decapsulation password',
        'error',
      );
      return;
    }

    if (_selectedCapsule!['isLocked'] == true) {
      widget.onSecurityLog(
        'Decapsulation denied: Block constraint still solid',
        'critical',
        'Capsule: ${_selectedCapsule!['name']}. Chronological time lock expires in $_secondsRemaining seconds.',
      );
      widget.onSuccess(
        widget.locale == 'ar' ? 'صلاحية مرفوضة: الوقت المتبقي للقفل التزامني لم يستكمل بعد' : 'Confinement error: Lock period has not elapsed yet!',
        'error',
      );
      return;
    }

    if (_passwordInput != 'riman123') {
      widget.onSecurityLog(
        'Decapsulation key mismatch',
        'critical',
        'Capsule: ${_selectedCapsule!['name']}. Typed key: "$_passwordInput" did not match ledger secret key.',
      );
      widget.onSuccess(
        widget.locale == 'ar' ? 'كلمة المرور غير صحيحة! تلميح: استخدم "riman123"' : 'Invalid password pattern! Hint: use "riman123"',
        'error',
      );
      return;
    }

    setState(() {
      _isDissolving = true;
    });

    widget.onSecurityLog(
      'Dissolving capsule chronological confinement field',
      'warning',
      'Asset: ${_selectedCapsule!['name']}. Re-extracting keystore parameters...',
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isDissolving = false;
      });

      widget.onSecurityLog(
        'Capsule successfully dissolved',
        'success',
        'Extracted: ${_selectedCapsule!['name']}. SHA1 Fingerprint: AFF92CB01A843E822DEC8976C01',
      );

      widget.onSuccess(
        widget.locale == 'ar' ? 'تم استخراج وحفظ أرشيف المفاتيح ${_selectedCapsule!['name']} بنجاح!' : 'Keystore decapsulated and extracted successfully!',
        'success',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDualColumns = screenWidth > 800;

    Widget buildCapsulesList() {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.av_timer, color: Color(0xFFEC4899), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      translate('active_quantum_seals', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    translate('chrono_buffer_active', widget.locale),
                    style: const TextStyle(fontSize: 8, color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                )
              ],
            ),
            const Divider(height: 24, color: Colors.white12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _capsules.length,
              itemBuilder: (context, index) {
                final cap = _capsules[index];
                final isSelected = _selectedCapsule?['id'] == cap['id'];
                final isLocked = cap['isLocked'] as bool;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCapsule = cap;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1F2937) : Colors.black12,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEC4899)
                            : Colors.white.withOpacity(0.04),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isLocked ? Icons.lock : Icons.lock_open,
                                color: isLocked ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cap['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${translate('created_at', widget.locale)}: ${cap['created']} • ${translate('size_label', widget.locale)}: ${cap['size']}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isLocked) ...[
                              Text(
                                translate('chrono_lock_counter', widget.locale),
                                style: const TextStyle(fontSize: 7, color: Colors.white38, fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formattedTimeSpan(),
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              )
                            ] else ...[
                              Text(
                                translate('ready_decryption', widget.locale),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      );
    }

    Widget buildInteractiveSealCard() {
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
                const Icon(Icons.blur_circular, color: Color(0xFFEC4899), size: 18),
                const SizedBox(width: 8),
                Text(
                  translate('dissolve_seal_title', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              translate('dissolve_seal_desc', widget.locale),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const Divider(height: 24, color: Colors.white12),

            _selectedCapsule != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${translate('selected_archive', widget.locale)}:',
                        style: const TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCapsule!['name'] as String,
                        style: const TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      Text(
                        translate('capsule_pass_key', widget.locale),
                        style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        obscureText: true,
                        onChanged: (val) => _passwordInput = val,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: translate('enter_decryption_password_placeholder', widget.locale),
                          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: Colors.black26,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        translate('demo_password_hint', widget.locale),
                        style: const TextStyle(color: Colors.grey, fontSize: 8, height: 1.3),
                      ),
                      const SizedBox(height: 18),

                      // Dynamic button
                      ElevatedButton(
                        onPressed: _isDissolving ? null : _dissolveTimeConfinement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isDissolving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                translate('dissolve_confinement_btn', widget.locale),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                      )
                    ],
                  )
                : Text(
                    translate('select_active_capsule', widget.locale),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  )
          ],
        ),
      );
    }

    Widget buildMathProofMatrixBanner() {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.functions, color: Colors.indigoAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  translate('proof_matrix_title', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent, fontSize: 11),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              translate('proof_matrix_desc', widget.locale),
              style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          useDualColumns
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildCapsulesList()),
                    const SizedBox(width: 16),
                    Expanded(child: buildInteractiveSealCard()),
                  ],
                )
              : Column(
                  children: [
                    buildCapsulesList(),
                    const SizedBox(height: 16),
                    buildInteractiveSealCard(),
                  ],
                ),
          buildMathProofMatrixBanner(),
        ],
      ),
    );
  }
}
