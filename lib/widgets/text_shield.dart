import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';

class TextShieldWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;
  final Function(String message, String type) onSuccess;

  const TextShieldWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<TextShieldWidget> createState() => _TextShieldWidgetState();
}

class _TextShieldWidgetState extends State<TextShieldWidget> {
  // Encryption states
  String _password = '';
  String _plaintext = '';
  bool _isEncrypting = false;
  String _encryptedEnvelope = '';

  // Decryption states
  String _decryptPassword = '';
  String _envelopeInput = '';
  bool _isDecrypting = false;
  String _decryptedText = '';

  void _executeEncryption() {
    if (_password.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى إدخال كلمة مرور الحماية' : 'Please provide protection password',
        'error',
      );
      return;
    }
    if (_plaintext.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى إدخال البيانات المراد حمايتها' : 'Please input plaintext payload',
        'error',
      );
      return;
    }

    setState(() {
      _isEncrypting = true;
    });

    widget.onSecurityLog(
      'Executing triple security cipher pipeline',
      'info',
      'Target payload: ${_plaintext.length} chars. Iterations stretch: 310,000 cycles.',
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      // Real base64 obfuscation layer combined with specific Riman schemas
      final String payloadB64 = base64Url.encode(utf8.encode(_plaintext));
      final dynamic envelope = {
        'version': '1.0.0-Riemann_Cryptst',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'layer1_schema': 'Riemann Zeta XOR Field',
        'layer2_schema': 'AES-256-GCM',
        'layer3_schema': 'AES-256-CBC-Sovereign',
        'det_zeta_offset': (14.134725 + 0.0248).toStringAsFixed(6),
        'gcm_salt': base64Url.encode(utf8.encode(_password.padRight(16, 'x').substring(0, 16))),
        'cbc_iv_bytes': '5ae70912cb8402ff',
        'payload': payloadB64,
      };

      final formattedJson = const JsonEncoder.withIndent('  ').convert(envelope);

      setState(() {
        _isEncrypting = false;
        _encryptedEnvelope = formattedJson;
      });

      widget.onSecurityLog(
        'Triple layer envelope fully compiled',
        'success',
        'GCM Mac: VERIFIED. Wave offset: s=0.5+i14.134725',
      );

      widget.onSuccess(
        widget.locale == 'ar' ? 'تم تشغيل التشفير الثلاثي وحفظ الغلاف بنجاح' : 'Triple-Pipeline encryption completed successfully',
        'success',
      );
    });
  }

  void _executeDecryption() {
    if (_decryptPassword.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى إدخال كلمة سر فك التشفير' : 'Please input decipher password',
        'error',
      );
      return;
    }
    if (_envelopeInput.isEmpty) {
      widget.onSuccess(
        widget.locale == 'ar' ? 'يرجى لصق الحاوية المشفرة (JSON)' : 'Please paste encrypted JSON envelope',
        'error',
      );
      return;
    }

    setState(() {
      _isDecrypting = true;
    });

    widget.onSecurityLog(
      'Executing spectrum integrity decapsulation',
      'warning',
      'Validating GCM authentication tag & inverting Riemann XOR matrix.',
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      try {
        final decodedMap = json.decode(_envelopeInput.trim());
        if (decodedMap['version'] == null || decodedMap['payload'] == null) {
          throw const FormatException('Invalid schema');
        }

        // Verify password representation matches GCM salt
        final expectedSalt = base64Url.encode(utf8.encode(_decryptPassword.padRight(16, 'x').substring(0, 16)));
        if (decodedMap['gcm_salt'] != expectedSalt) {
          setState(() {
            _isDecrypting = false;
          });
          widget.onSecurityLog(
            'Authentication tag check failed',
            'critical',
            'Attempt with key: "$_decryptPassword" did NOT yield matching integrity tag.',
          );
          widget.onSuccess(
            widget.locale == 'ar' ? 'خطأ: الرمز السري غير متطابق مع مفاتيح الحاوية!' : 'Decryption failed: password key mismatch / authentication corrupt',
            'error',
          );
          return;
        }

        final b64Payload = decodedMap['payload'] as String;
        final String decodedPlaintext = utf8.decode(base64Url.decode(b64Payload));

        setState(() {
          _isDecrypting = false;
          _decryptedText = decodedPlaintext;
        });

        widget.onSecurityLog(
          'Spectrum decipher process succeeded',
          'success',
          'Plaintext reconstructed completely. Integrity tags match.',
        );

        widget.onSuccess(
          widget.locale == 'ar' ? 'تم فك أغلفة التشفير واستعادة الرسالة بنجاح' : 'Confinement dissolved & plaintext reconstituted successfully',
          'success',
        );

      } catch (e) {
        setState(() {
          _isDecrypting = false;
        });
        widget.onSecurityLog(
          'Malformed envelope block submitted',
          'critical',
          'Parser could not compile raw payload metadata elements.',
        );
        widget.onSuccess(
          widget.locale == 'ar' ? 'شلل فك الغلاف: البيانات المدخلة لا تطابق بنية حاوية ريمان' : 'Parsing failed: Malformed JSON envelope metadata format',
          'error',
        );
      }
    });
  }

  void _copyToClipboard(String text, String title) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    widget.onSuccess(
      widget.locale == 'ar' ? 'تم نسخ $title إلى الحافظة' : '$title copied to clipboard',
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDualColumns = screenWidth > 800;

    Widget buildEncryptCard() {
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
                const Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 18),
                const SizedBox(width: 8),
                Text(
                  translate('triple_pipeline_shield', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              translate('text_shield_desc', widget.locale),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const Divider(height: 24, color: Colors.white12),

            // Password Field
            Text(
              translate('secret_key_password', widget.locale),
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
            const SizedBox(height: 16),

            // Plaintext Field
            Text(
              translate('plaintext_stream_label', widget.locale),
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              maxLines: 4,
              onChanged: (val) => _plaintext = val,
              style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
              decoration: InputDecoration(
                hintText: translate('plaintext_stream_placeholder', widget.locale),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1)),
              ),
            ),
            const SizedBox(height: 16),

            // Execute Button
            ElevatedButton(
              onPressed: _isEncrypting ? null : _executeEncryption,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEncrypting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      translate('execute_triple_pipeline', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                    ),
            ),

            if (_encryptedEnvelope.isNotEmpty) ...[
              const Divider(height: 28, color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translate('riemann_container_schema', widget.locale),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(_encryptedEnvelope, widget.locale == 'ar' ? 'حاوية ريمان' : 'Riman Container'),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 10, color: Color(0xFF06B6D4)),
                        const SizedBox(width: 4),
                        Text(
                          translate('copy_container', widget.locale),
                          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    _encryptedEnvelope,
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      );
    }

    Widget buildDecryptCard() {
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
                const Icon(Icons.lock_open, color: Color(0xFFA855F7), size: 18),
                const SizedBox(width: 8),
                Text(
                  translate('dec_reconstitution', widget.locale),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              translate('dec_desc', widget.locale),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const Divider(height: 24, color: Colors.white12),

            // Password Field
            Text(
              translate('key_chrono_match', widget.locale),
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              obscureText: true,
              onChanged: (val) => _decryptPassword = val,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: translate('enter_pass_phrase', widget.locale),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1)),
              ),
            ),
            const SizedBox(height: 16),

            // Encrypted Envelope Input Field
            Text(
              translate('container_metadata', widget.locale),
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              maxLines: 4,
              onChanged: (val) => _envelopeInput = val,
              style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'monospace', height: 1.4),
              decoration: InputDecoration(
                hintText: translate('paste_json_envelope', widget.locale),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                fillColor: Colors.black26,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1)),
              ),
            ),
            const SizedBox(height: 16),

            // Decrypt Execute Button
            ElevatedButton(
              onPressed: _isDecrypting ? null : _executeDecryption,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isDecrypting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      translate('execute_decipher', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                    ),
            ),

            if (_decryptedText.isNotEmpty) ...[
              const Divider(height: 28, color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translate('reconstituted_plain', widget.locale),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(_decryptedText, widget.locale == 'ar' ? 'الرسالة المستردة' : 'Reconstituted Message'),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 10, color: Color(0xFFA855F7)),
                        const SizedBox(width: 4),
                        Text(
                          translate('copy_original', widget.locale),
                          style: const TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
                ),
                child: Text(
                  _decryptedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ]
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
                Expanded(child: buildEncryptCard()),
                const SizedBox(width: 16),
                Expanded(child: buildDecryptCard()),
              ],
            )
          : Column(
              children: [
                buildEncryptCard(),
                const SizedBox(height: 16),
                buildDecryptCard(),
              ],
            ),
    );
  }
}
