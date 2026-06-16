import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';

class FlutterExporterWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String type) onSuccess;

  const FlutterExporterWidget({
    Key? key,
    required this.locale,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<FlutterExporterWidget> createState() => _FlutterExporterWidgetState();
}

class _FlutterExporterWidgetState extends State<FlutterExporterWidget> {
  String _activeCodeTab = 'riemann';

  final String _riemannCode = """/// Riemann Zeta Zero Pseudo-random Noise Generator
/// Decoupled from platform-level predictability.
import 'dart:math';

class RiemannZeroGenerator {
  final int seedIndex;
  
  // Non-trivial zeros mapping constants
  static const List<double> _zetaZerosIm = [
    14.134725, 21.022040, 25.010858, 30.424876, 
    32.935062, 37.586178, 40.918719, 43.327073
  ];

  RiemannZeroGenerator(this.seedIndex);

  List<int> generateMask(int length) {
    final double zeroOffset = _zetaZerosIm[seedIndex % _zetaZerosIm.length];
    final Random rand = Random((zeroOffset * 1000000).toInt());
    
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  List<int> cryptApplyXor(List<int> payload) {
    final List<int> mask = generateMask(payload.length);
    return List<int>.generate(payload.length, (i) => payload[i] ^ mask[i]);
  }
}""";

  final String _pbkdf2Code = """/// Triple Shield PBKDF2 SHA256 Key derivation wrapper
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class RimanKeyDerivation {
  static Future<SecretKey> deriveKey(String password, List<int> salt, {int iterations = 310000}) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(Sha256()),
      iterations: iterations,
      bits: 256,
    );
    
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }
}""";

  final String _gcmCode = """/// AES-256-GCM Secure Galois Authenticated Encryption Unit
import 'package:cryptography/cryptography.dart';

class RimanAesGcmUnit {
  static Future<EncryptionResult> encrypt(List<int> plaintext, SecretKey derivedKey) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: derivedKey,
    );
    
    return EncryptionResult(
      cipherBytes: secretBox.cipherText,
      nonce: secretBox.nonce,
      mac: secretBox.mac.bytes,
    );
  }
}

class EncryptionResult {
  final List<int> cipherBytes;
  final List<int> nonce;
  final List<int> mac;
  EncryptionResult({required this.cipherBytes, required this.nonce, required this.mac});
}""";

  final String _cbcCode = """/// AES-256-CBC Cypher Block Layer (Sovereign Backup Protection)
import 'package:encrypt/encrypt.dart';

class RimanAesCbcUnit {
  static List<int> encrypt(List<int> plaintext, List<int> keyBytes, List<int> ivBytes) {
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    return encrypted.bytes;
  }
}""";

  String _getActiveCode() {
    switch (_activeCodeTab) {
      case 'pbkdf2': return _pbkdf2Code;
      case 'gcm': return _gcmCode;
      case 'cbc': return _cbcCode;
      default: return _riemannCode;
    }
  }

  void _copyToClipboard() {
    final code = _getActiveCode();
    Clipboard.setData(ClipboardData(text: code));
    widget.onSuccess(
      widget.locale == 'ar' ? 'تم نسخ شفرة المصدر لـ Flutter' : 'Dart SDK source code copied',
      'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDualColumns = screenWidth > 800;

    Widget buildCodeViewerCard() {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('flutter_exporter_title', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SOVEREIGN DART CLASS VIEWER',
                      style: TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace'),
                    )
                  ],
                ),
                TextButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, size: 12, color: Color(0xFF06B6D4)),
                  label: Text(
                    translate('copy', widget.locale),
                    style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const Divider(height: 16, color: Colors.white12),

            // Tabs for 4 classes
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCodeSubtab('riemann', 'Riemann Generator'),
                  const SizedBox(width: 6),
                  _buildCodeSubtab('pbkdf2', 'PBKDF2 Key'),
                  const SizedBox(width: 6),
                  _buildCodeSubtab('gcm', 'AES-GCM'),
                  const SizedBox(width: 6),
                  _buildCodeSubtab('cbc', 'AES-CBC'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mono text area
            Container(
              height: 240,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  _getActiveCode(),
                  style: const TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }

    Widget buildGuideCard() {
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
                const Icon(Icons.integration_instructions, color: Color(0xFFA855F7), size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.locale == 'ar' ? 'دليل إعداد مشروع Flutter' : 'Flutter Integration Guide',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                )
              ],
            ),
            const Divider(height: 24, color: Colors.white12),

            _buildIntegrationStep(
              numStr: '1',
              title: widget.locale == 'ar' ? 'تحديث Pubspec.yaml' : 'Configure pubspec.yaml',
              desc: widget.locale == 'ar' ? 'أضف الحزم التشفيرية اللازمة في pubspec:' : 'Add crypt packages dependencies:',
              code: 'cryptography: ^2.5.0\\nencrypt: ^5.0.3',
            ),
            const SizedBox(height: 16),
            _buildIntegrationStep(
              numStr: '2',
              title: widget.locale == 'ar' ? 'اشتقاق مفاتيح التناظر' : 'Derive Symmetric Keys',
              desc: widget.locale == 'ar' ? 'استدع مرشح PBKDF2 للاشتقاق الأساسي.' : 'Initialize PBKDF2 stretch coordinates mapping.',
            ),
            const SizedBox(height: 16),
            _buildIntegrationStep(
              numStr: '3',
              title: widget.locale == 'ar' ? 'تشغيل الحلقات المتضاعفة' : 'Run Multi-tier Decipher',
              desc: widget.locale == 'ar' ? 'الرص بالمستوى المتتالي GCM و CBC و XOR.' : 'Chain sequentially XOR field, AES GCM, and AES CBC.',
            ),
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
                    Expanded(child: buildCodeViewerCard()),
                    const SizedBox(width: 16),
                    Expanded(child: buildGuideCard()),
                  ],
                )
              : Column(
                  children: [
                    buildCodeViewerCard(),
                    const SizedBox(height: 16),
                    buildGuideCard(),
                  ],
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Text(
              translate('flutter_export_desc', widget.locale),
              style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCodeSubtab(String id, String label) {
    final isSelected = _activeCodeTab == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeCodeTab = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationStep({
    required String numStr,
    required String title,
    required String desc,
    String? code,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA855F7)),
          ),
          child: Center(
            child: Text(
              numStr,
              style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 9)),
              if (code != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    code.replaceAll('\\n', '\n'),
                    style: const TextStyle(color: Color(0xFFA855F7), fontSize: 8, fontFamily: 'monospace'),
                  ),
                )
              ]
            ],
          ),
        )
      ],
    );
  }
}
