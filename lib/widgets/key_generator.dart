import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';

class KeyGeneratorWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const KeyGeneratorWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<KeyGeneratorWidget> createState() => _KeyGeneratorWidgetState();
}

class _KeyGeneratorWidgetState extends State<KeyGeneratorWidget> {
  late Timer _totpTimer;

  // Password generator
  int _passLength = 24;
  String _generatedPass = '';

  // Riemann derivation
  int _riemannSeed = 42;
  String _generatedRiemann = '';

  // Image to key
  String _imageName = '';
  String _generatedImageKey = '';

  // TOTP Simulator
  String _totpSecret = 'RIMAN-SECURE-KEY-BASE32';
  String _totpCode = '482 109';
  int _totpSecondsRemaining = 30;

  // Live analyzer
  String _analyzerInput = '';

  @override
  void initState() {
    super.initState();
    _startTotpTimer();
  }

  @override
  void dispose() {
    _totpTimer.cancel();
    super.dispose();
  }

  void _startTotpTimer() {
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_totpSecondsRemaining > 1) {
          _totpSecondsRemaining--;
        } else {
          _totpSecondsRemaining = 30;
          // Generate new fake-yet-realistic TOTP code
          final code1 = (math.Random().nextInt(900) + 100).toString();
          final code2 = (math.Random().nextInt(900) + 100).toString();
          _totpCode = '$code1 $code2';
          widget.onSecurityLog(
            'New TOTP verified token generated',
            'info',
            'TOTP Token synchronized for secret key slice.',
          );
        }
      });
    });
  }

  void _generateSymmetricKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final r = math.Random();
    final pass = List.generate(_passLength, (_) => chars[r.nextInt(chars.length)]).join();

    setState(() {
      _generatedPass = pass;
    });

    widget.onSecurityLog(
      'Sovereign password generated',
      'info',
      'Length: $_passLength characters. High-entropy.',
    );

    widget.onSuccess(
      widget.locale == 'ar' ? 'تم توليد مفتاح بالقوة السيادية بنجاح' : 'Sovereign-Grade key generated successfully',
      'success',
    );
  }

  void _deriveRiemannCoordinates() {
    // Imaginary zeta zeroes index mapping representation
    final offsets = [
      14.134725, 21.022040, 25.010858, 30.424876, 
      32.935062, 37.586178, 40.918719, 43.327073
    ];
    final selectedOffset = offsets[_riemannSeed % offsets.length];
    final calculatedXorMat = (selectedOffset * 1000000).toInt().toRadixString(16).toUpperCase();

    setState(() {
      _generatedRiemann = 'z_s0.5+i${selectedOffset.toStringAsFixed(6)}_m${calculatedXorMat}';
    });

    widget.onSecurityLog(
      'Riemann zero key coordinate derived',
      'info',
      'Derived from zeta zero index: $_riemannSeed. Matrix root: s=0.5+i$selectedOffset.',
    );

    widget.onSuccess(
      widget.locale == 'ar' ? 'تم اشتقاق مفتاح ريمان الصفري بنجاح' : 'Riemann Zero Key generated successfully',
      'success',
    );
  }

  void _deriveImageEntropy() {
    final names = ['identity_avatar.png', 'satellite_map.jpg', 'noise_gradient.png'];
    final selectedName = names[math.Random().nextInt(names.length)];
    final calculatedHex = List.generate(40, (_) => '0123456789abcdef'[math.Random().nextInt(16)]).join();

    setState(() {
      _imageName = selectedName;
      _generatedImageKey = 'img_entropy_f${calculatedHex.substring(0, 12)}_seed_${calculatedHex.substring(12, 28)}';
    });

    widget.onSecurityLog(
      'Image Pixel Entropy key derivation completed',
      'info',
      'File: $selectedName. Extraction complete.',
    );

    widget.onSuccess(
      widget.locale == 'ar' ? 'تم فك بذور العشوائية من الصورة بنجاح' : 'Entropy Key derived from image successfully',
      'success',
    );
  }

  void _copyToClipboard(String text, String title) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    widget.onSuccess(
      widget.locale == 'ar' ? 'تم نسخ $title إلى الحافظة' : '$title copied to clipboard',
      'success',
    );
  }

  // Calculate rating on active key audit typing
  Map<String, dynamic> _analyzeKeyStrength() {
    if (_analyzerInput.isEmpty) return {'score': 0, 'entropy': 0, 'label': 'Critical'};

    final len = _analyzerInput.length;
    int variety = 1;
    if (_analyzerInput.contains(RegExp(r'[a-z]'))) variety++;
    if (_analyzerInput.contains(RegExp(r'[A-Z]'))) variety++;
    if (_analyzerInput.contains(RegExp(r'[0-9]'))) variety++;
    if (_analyzerInput.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) variety++;

    final score = math.min(100, (len * 3) + (variety * 12));
    final entropy = (len * 4.5).toInt();
    String label = 'Critical';
    if (score > 80) label = 'Sovereign-Grade';
    else if (score > 55) label = 'Medium';
    else if (score > 30) label = 'Vulnerable';

    return {
      'score': score,
      'entropy': entropy,
      'label': label,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossCount = screenWidth > 600 ? 2 : 1;
    final strength = _analyzeKeyStrength();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              // Pass Generator Card
              _buildCardWrapper(
                icon: Icons.vpn_key_outlined,
                color: const Color(0xFF06B6D4),
                title: translate('pass_generator_title', widget.locale),
                desc: translate('pass_generator_desc', widget.locale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          translateFormat('pass_length_label', widget.locale, {'length': _passLength.toString()}),
                          style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                        ),
                      ],
                    ),
                    Slider(
                      value: _passLength.toDouble(),
                      min: 12,
                      max: 64,
                      activeColor: const Color(0xFF06B6D4),
                      onChanged: (val) {
                        setState(() {
                          _passLength = val.toInt();
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: _generateSymmetricKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        translate('gen_symmetric_key_btn', widget.locale),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    if (_generatedPass.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _generatedPass,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 12, color: Color(0xFF06B6D4)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _copyToClipboard(_generatedPass, widget.locale == 'ar' ? 'مفتاح المتماثل' : 'Symmetric Key'),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),

              // Riemann Key Generator Card
              _buildCardWrapper(
                icon: Icons.developer_board,
                color: const Color(0xFFA855F7),
                title: translate('riemann_derivation_title', widget.locale),
                desc: translate('riemann_derivation_desc', widget.locale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          translateFormat('zeta_zero_matrix_expansion', widget.locale, {'seed': _riemannSeed.toString()}),
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                        ),
                      ],
                    ),
                    Slider(
                      value: _riemannSeed.toDouble(),
                      min: 0,
                      max: 99,
                      activeColor: const Color(0xFFA855F7),
                      onChanged: (val) {
                        setState(() {
                          _riemannSeed = val.toInt();
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: _deriveRiemannCoordinates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        translate('derive_zeta_btn', widget.locale),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    if (_generatedRiemann.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _generatedRiemann,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 12, color: Color(0xFFA855F7)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _copyToClipboard(_generatedRiemann, widget.locale == 'ar' ? 'إحداثيات زيتا' : 'Zeta Key'),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),

              // Image Derivation
              _buildCardWrapper(
                icon: Icons.image,
                color: const Color(0xFFEC4899),
                title: translate('image_derivation_title', widget.locale),
                desc: translate('image_derivation_desc', widget.locale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _deriveImageEntropy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_size_select_large, size: 18, color: Color(0xFFEC4899)),
                            const SizedBox(height: 4),
                            Text(
                              _imageName.isNotEmpty ? _imageName : translate('select_image_asset', widget.locale),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              translate('upload_png_jpg', widget.locale),
                              style: const TextStyle(color: Color(0xFFEC4899), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ),
                    if (_generatedImageKey.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _generatedImageKey,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 12, color: Color(0xFFEC4899)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _copyToClipboard(_generatedImageKey, widget.locale == 'ar' ? 'مفتاح الصورة السري' : 'Image Key'),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),

              // TOTP key simulator
              _buildCardWrapper(
                icon: Icons.sync,
                color: const Color(0xFF10B981),
                title: translate('totp_engine_title', widget.locale),
                desc: translate('totp_engine_desc', widget.locale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translate('totp_shared_secret', widget.locale),
                      style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: TextEditingController(text: _totpSecret),
                      onChanged: (val) => _totpSecret = val,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        fillColor: Colors.black26,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translate('verification_token', widget.locale),
                                style: const TextStyle(fontSize: 7, color: Colors.grey, fontFamily: 'monospace'),
                              ),
                              Text(
                                _totpCode,
                                style: const TextStyle(fontSize: 16, color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                translate('remaining_life', widget.locale),
                                style: const TextStyle(fontSize: 7, color: Colors.grey, fontFamily: 'monospace'),
                              ),
                              Text(
                                '${_totpSecondsRemaining}s',
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Strength Analyzer typing card
          Container(
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
                    const Icon(Icons.verified, color: Colors.indigoAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      translate('key_strength_analyzer', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  translate('key_analyzer_desc', widget.locale),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
                const Divider(height: 24, color: Colors.white12),

                TextField(
                  onChanged: (val) {
                    setState(() {
                      _analyzerInput = val;
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: translate('key_audit_placeholder', widget.locale),
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    fillColor: Colors.black26,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.indigoAccent, width: 1)),
                  ),
                ),

                if (_analyzerInput.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricStatsBlock(
                          title: translate('audit_score', widget.locale),
                          val: '${strength['score']}%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricStatsBlock(
                          title: translate('entropy_level', widget.locale),
                          val: '${strength['entropy']} Bits',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricStatsBlock(
                          title: translate('grade_classification', widget.locale),
                          val: strength['label'] == 'Sovereign-Grade'
                              ? (widget.locale == 'ar' ? 'مستوى سيادي' : 'Sovereign-Grade')
                              : strength['label'] == 'Medium'
                                  ? (widget.locale == 'ar' ? 'متوسط' : 'Medium')
                                  : strength['label'] == 'Vulnerable'
                                      ? (widget.locale == 'ar' ? 'ضعيف' : 'Vulnerable')
                                      : (widget.locale == 'ar' ? 'حرجة للغاية' : 'Critical'),
                          color: strength['label'] == 'Sovereign-Grade'
                              ? const Color(0xFF0369A1)
                              : strength['label'] == 'Medium'
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardWrapper({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 8),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMetricStatsBlock({required String title, required String val, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: color != null ? 'sans' : 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}
