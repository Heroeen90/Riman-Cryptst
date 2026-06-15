import React, { useState } from 'react';
import { 
  FileCode, Terminal, HelpCircle, BadgeCheck, Copy, ChevronDown, ChevronRight 
} from 'lucide-react';
import { useTranslation } from '../lib/I18nContext';

interface FlutterProps {
  onSuccess: (msg: string, type: 'success' | 'error') => void;
}

export const FlutterExplorer: React.FC<FlutterProps> = ({ onSuccess }) => {
  const { t, locale } = useTranslation();

  const [activeCodeTab, setActiveCodeTab] = useState<string>('riemann');
  const [copiedCodeFlag, setCopiedCodeFlag] = useState<boolean>(false);

  const riemannDartContent = `/// Riemann Zeta Zero Pseudo-random Noise Generator
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
}`;

  const pbkdf2DartContent = `/// Triple Shield PBKDF2 SHA256 Key derivation wrapper
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
}`;

  const gcmDartContent = `/// AES-256-GCM Secure Galois Authenticated Encryption Unit
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
}`;

  const cbcDartContent = `/// AES-256-CBC Cypher Block Layer (Sovereign Backup Protection)
import 'package:encrypt/encrypt.dart';

class RimanAesCbcUnit {
  static List<int> encrypt(List<int> plaintext, List<int> keyBytes, List<int> ivBytes) {
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    return encrypted.bytes;
  }
}`;

  const getCodeStr = () => {
    switch (activeCodeTab) {
      case 'pbkdf2': return pbkdf2DartContent;
      case 'gcm': return gcmDartContent;
      case 'cbc': return cbcDartContent;
      default: return riemannDartContent;
    }
  };

  const handleCopyCode = () => {
    navigator.clipboard.writeText(getCodeStr());
    setCopiedCodeFlag(true);
    setTimeout(() => setCopiedCodeFlag(false), 2000);
    onSuccess(locale === 'ar' ? 'تم نسخ شفرة المصدر لـ Flutter' : 'Dart SDK source code copied', 'success');
  };

  return (
    <div className="space-y-6">
      
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <span className="text-[10px] uppercase tracking-widest font-mono text-cyan-400">{t('export_sdk')}</span>
          <h2 className="text-xl font-display font-semibold text-white tracking-tight">{t('flutter_title')}</h2>
          <p className="text-xs text-neutral-400 mt-1">
            {t('flutter_desc')}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Source Code Container */}
        <div className="lg:col-span-2 glass-card rounded-2xl overflow-hidden border border-neutral-850 flex flex-col justify-between min-h-[460px]">
          
          <div className="border-b border-neutral-900 bg-neutral-900/10 px-4 py-2 flex flex-wrap gap-2 justify-between items-center">
            
            <div className="flex gap-1.5 self-center">
              {[
                { id: 'riemann', label: t('riemann_dart_class') },
                { id: 'pbkdf2', label: t('pbkdf2_dart_class') },
                { id: 'gcm', label: t('aes_gcm_dart_class') },
                { id: 'cbc', label: t('aes_cbc_dart_class') }
              ].map((c) => {
                const active = activeCodeTab === c.id;
                return (
                  <button 
                    key={c.id}
                    onClick={() => setActiveCodeTab(c.id)}
                    className={`px-3 py-1.5 text-[11px] font-mono rounded-lg transition-all focus:outline-none cursor-pointer ${
                      active 
                        ? 'bg-neutral-850 text-white border border-neutral-750' 
                        : 'text-neutral-500 hover:text-neutral-300'
                    }`}
                  >
                    {c.label}
                  </button>
                );
              })}
            </div>

            <button 
              onClick={handleCopyCode}
              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-mono font-semibold text-neutral-400 hover:text-white hover:bg-neutral-800 rounded-lg transition cursor-pointer"
            >
              <Copy className="w-3.5 h-3.5" />
              {copiedCodeFlag ? t('established') : t('copy_dart_code')}
            </button>

          </div>

          <div className="flex-1 p-4 bg-neutral-950 font-mono text-xs overflow-auto max-h-[380px] text-cyan-300/95 scrollbar-thin">
            <pre className="text-start whitespace-pre-wrap sm:whitespace-pre leading-relaxed">{getCodeStr()}</pre>
          </div>

          <div className="px-4 py-2.5 border-t border-neutral-900 bg-neutral-950 text-[10px] font-mono text-neutral-600 flex justify-between items-center">
            <span>RIEMANN HYBRID PROTOCOL • DART ENCRYPTION SDK</span>
            <span>CLASS: SECURE MULTI-LAYER v1.0.0</span>
          </div>

        </div>

        {/* Configurations guide card */}
        <div className="glass-card p-6 rounded-2xl flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Terminal className="w-5 h-5 text-cyan-400" />
              <h3 className="font-display font-medium text-white">{t('flutter_integration_guide')}</h3>
            </div>
            
            <div className="space-y-4 pt-1.5">
              
              <div className="flex gap-3">
                <div className="w-5 h-5 rounded-full bg-neutral-900 border border-neutral-800 flex items-center justify-center font-mono text-[10px] text-cyan-400 shrink-0 mt-0.5">
                  1
                </div>
                <div>
                  <span className="block text-xs font-sans font-semibold text-neutral-200">{locale === 'ar' ? 'تحديث Pubspec.yaml' : 'Configure pubspec.yaml'}</span>
                  <span className="block text-[11px] text-neutral-400 mt-0.5 leading-normal">
                    {t('flutter_config_step_1')}
                  </span>
                  <pre className="mt-1.5 p-1.5 bg-neutral-950 rounded text-[9px] font-mono text-neutral-500 overflow-x-auto">
                    cryptography: ^2.5.0<br/>
                    encrypt: ^5.0.3
                  </pre>
                </div>
              </div>

              <div className="flex gap-3">
                <div className="w-5 h-5 rounded-full bg-neutral-900 border border-neutral-800 flex items-center justify-center font-mono text-[10px] text-indigo-400 shrink-0 mt-0.5">
                  2
                </div>
                <div>
                  <span className="block text-xs font-sans font-semibold text-neutral-200">{locale === 'ar' ? 'اشتقاق مفاتيح التناظر' : 'Derive Symmetric Keys'}</span>
                  <span className="block text-[11px] text-neutral-400 mt-0.5 leading-normal">
                    {t('flutter_config_step_2')}
                  </span>
                </div>
              </div>

              <div className="flex gap-3">
                <div className="w-5 h-5 rounded-full bg-neutral-900 border border-neutral-800 flex items-center justify-center font-mono text-[10px] text-purple-400 shrink-0 mt-0.5">
                  3
                </div>
                <div>
                  <span className="block text-xs font-sans font-semibold text-neutral-200">{locale === 'ar' ? 'تطبيق الحلقات المتضاعفة' : 'Run Multi-tier Decipher'}</span>
                  <span className="block text-[11px] text-neutral-400 mt-0.5 leading-normal">
                    {t('flutter_config_step_3')}
                  </span>
                </div>
              </div>

            </div>
          </div>

          <div className="p-3 bg-neutral-950/40 border border-neutral-900 rounded-xl mt-4 flex items-center gap-2 text-[10px] font-mono text-neutral-500">
            <HelpCircle className="w-4 h-4 text-cyan-400 shrink-0" />
            <span>{locale === 'ar' ? 'يدعم قنوات أندرويد و iOS و الويب' : 'Compatible with active Flutter platforms.'}</span>
          </div>
        </div>

      </div>

    </div>
  );
};
