import React, { useState } from 'react';
import { 
  Key, FileCode, RefreshCw, Copy, BadgeCheck 
} from 'lucide-react';
import { 
  generateSecuredPassword, 
  generateRiemannKey, 
  generateImageKey, 
  generateTotpCode, 
  analyzeKeyStrength 
} from '../lib/crypto';
import { useTranslation } from '../lib/I18nContext';

interface KeyGenProps {
  onSuccess: (msg: string, type: 'success' | 'error') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
}

export const KeyGeneratorModule: React.FC<KeyGenProps> = ({ onSuccess, onSecurityLog }) => {
  const { t, locale } = useTranslation();

  // Passwords
  const [passLength, setPassLength] = useState<number>(24);
  const [generatedPass, setGeneratedPass] = useState<string>('');
  
  // Riemann seed keys
  const [riemannSeed, setRiemannSeed] = useState<number>(42);
  const [generatedRiemann, setGeneratedRiemann] = useState<string>('');
  
  // Image to key
  const [imageInput, setImageInput] = useState<string>('');
  const [generatedImageKey, setGeneratedImageKey] = useState<string>('');
  
  // TOTP Simulator
  const [totpSecret, setTotpSecret] = useState<string>('RIMAN-SECURE-KEY-BASE32');
  const [totpCode, setTotpCode] = useState<string>('------');
  const [totpSecondsRemaining, setTotpSecondsRemaining] = useState<number>(30);
  
  // Live Analysis
  const [analyzerInput, setAnalyzerInput] = useState<string>('');

  const handleGeneratePassword = () => {
    const pass = generateSecuredPassword(passLength);
    setGeneratedPass(pass);
    onSecurityLog('Sovereign password generated', 'info', `Length: ${passLength} characters. High-entropy.`);
    onSuccess(locale === 'ar' ? 'تم توليد مفتاح بالقوة السيادية بنجاح' : 'Sovereign-Grade key generated successfully', 'success');
  };

  const handleGenerateRiemannKey = () => {
    const key = generateRiemannKey(riemannSeed);
    setGeneratedRiemann(key);
    onSecurityLog('Riemann zero key coordinate derived', 'info', `Derived from zeta zero index: ${riemannSeed}`);
    onSuccess(locale === 'ar' ? 'تم اشتقاق مفتاح ريمان الصفري بنجاح' : 'Riemann Zero Key generated successfully', 'success');
  };

  const handleImageKeyDerivation = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result as string;
      setImageInput(file.name);
      const derived = generateImageKey(base64);
      setGeneratedImageKey(derived);
      onSecurityLog('Image Pixel Entropy key derivation completed', 'info', `File: ${file.name}. Derived entropy.`);
      onSuccess(locale === 'ar' ? 'تم فك بذور العشوائية من الصورة بنجاح' : 'Entropy Key derived from image successfully', 'success');
    };
    reader.readAsDataURL(file);
  };

  React.useEffect(() => {
    const timer = setInterval(() => {
      if (totpSecret) {
        const { code, secondsRemaining } = generateTotpCode(totpSecret);
        setTotpCode(code);
        setTotpSecondsRemaining(secondsRemaining);
      }
    }, 1000);
    return () => clearInterval(timer);
  }, [totpSecret]);

  const copyToClipboard = (text: string, title: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    onSuccess(locale === 'ar' ? `تم نسخ ${title} إلى الحافظة` : `${title} copied to clipboard`, 'success');
  };

  const strength = analyzeKeyStrength(analyzerInput);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Pass Generator Card */}
        <div className="glass-card p-6 rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <Key className="w-5 h-5 text-cyan-400" />
            <h3 className="font-display font-medium text-white">{t('pass_generator_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400">{t('pass_generator_desc')}</p>
          
          <div className="space-y-3">
            <div>
              <label className="flex justify-between text-xs text-neutral-500 font-mono mb-1">
                <span>{t('pass_length_label', { length: passLength })}</span>
              </label>
              <input 
                type="range" 
                min="12" 
                max="64" 
                value={passLength}
                onChange={(e) => setPassLength(+e.target.value)}
                className="w-full accent-cyan-400 bg-neutral-800"
              />
            </div>

            <button 
              onClick={handleGeneratePassword}
              className="w-full py-2.5 rounded-xl border border-cyan-800/60 hover:border-cyan-500 bg-cyan-950/20 hover:bg-cyan-950/40 text-cyan-400 text-sm font-sans font-semibold tracking-tight transition-all duration-300 active:scale-95 cursor-pointer"
            >
              {t('gen_symmetric_key_btn')}
            </button>

            {generatedPass && (
              <div className="mt-3 p-3 rounded-xl bg-neutral-900/50 border border-neutral-800/60 flex justify-between items-center">
                <span className="font-mono text-xs text-neutral-300 break-all pr-2">{generatedPass}</span>
                <button 
                  onClick={() => copyToClipboard(generatedPass, locale === 'ar' ? 'مفتاح المتماثل' : 'Symmetric Key')}
                  className="p-1.5 hover:bg-neutral-850 rounded transition cursor-pointer"
                >
                  <Copy className="w-4 h-4 text-cyan-400" />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Riemann Key Generator Card */}
        <div className="glass-card p-6 rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <FileCode className="w-5 h-5 text-purple-400" />
            <h3 className="font-display font-medium text-white">{t('riemann_derivation_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400">{t('riemann_derivation_desc')}</p>
          
          <div className="space-y-3">
            <div>
              <label className="flex justify-between text-xs text-neutral-500 font-mono mb-1">
                <span>{t('zeta_zero_matrix_expansion', { seed: riemannSeed })}</span>
              </label>
              <input 
                type="range" 
                min="0" 
                max="99" 
                value={riemannSeed}
                onChange={(e) => setRiemannSeed(+e.target.value)}
                className="w-full accent-purple-400 bg-neutral-800"
              />
            </div>

            <button 
              onClick={handleGenerateRiemannKey}
              className="w-full py-2.5 rounded-xl border border-purple-800/60 hover:border-purple-500 bg-purple-950/20 hover:bg-purple-950/40 text-purple-400 text-sm font-sans font-semibold tracking-tight transition-all duration-300 active:scale-95 cursor-pointer"
            >
              {t('derive_zeta_btn')}
            </button>

            {generatedRiemann && (
              <div className="mt-3 p-3 rounded-xl bg-neutral-900/50 border border-neutral-800/60 flex justify-between items-center">
                <span className="font-mono text-xs text-neutral-300 break-all pr-2">{generatedRiemann}</span>
                <button 
                  onClick={() => copyToClipboard(generatedRiemann, locale === 'ar' ? 'إحداثيات زيتا' : 'Zeta Key')}
                  className="p-1.5 hover:bg-neutral-850 rounded transition cursor-pointer"
                >
                  <Copy className="w-4 h-4 text-purple-400" />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Image Based Key Derivation Card */}
        <div className="glass-card p-6 rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <Key className="w-5 h-5 text-pink-400" />
            <h3 className="font-display font-medium text-white">{t('image_derivation_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400">{t('image_derivation_desc')}</p>
          
          <div className="space-y-3">
            <label className="flex flex-col items-center justify-center border-2 border-dashed border-neutral-800 hover:border-pink-500/50 rounded-xl p-4 cursor-pointer transition bg-neutral-900/30">
              <span className="text-xs text-neutral-500 mb-1">{imageInput || t('select_image_asset')}</span>
              <span className="text-[10px] text-pink-400 font-mono">{t('upload_png_jpg')}</span>
              <input 
                type="file" 
                accept="image/*" 
                onChange={handleImageKeyDerivation}
                className="hidden" 
              />
            </label>

            {generatedImageKey && (
              <div className="mt-3 p-3 rounded-xl bg-neutral-900/50 border border-neutral-800/60 flex justify-between items-center animate-fade-in">
                <span className="font-mono text-xs text-pink-300 break-all pr-2">{generatedImageKey}</span>
                <button 
                  onClick={() => copyToClipboard(generatedImageKey, locale === 'ar' ? 'مفتاح الصورة السري' : 'Image Key')}
                  className="p-1.5 hover:bg-neutral-850 rounded transition cursor-pointer"
                >
                  <Copy className="w-4 h-4 text-pink-400" />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* TOTP Engine Card */}
        <div className="glass-card p-6 rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <RefreshCw className="w-5 h-5 text-emerald-400" />
            <h3 className="font-display font-medium text-white">{t('totp_engine_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400">{t('totp_engine_desc')}</p>
          
          <div className="space-y-3">
            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('totp_shared_secret')}</label>
              <input 
                type="text"
                value={totpSecret}
                onChange={(e) => setTotpSecret(e.target.value)}
                className="w-full px-3 py-1.5 rounded-lg bg-neutral-900/60 border border-neutral-800/60 font-mono text-xs text-white focus:outline-none focus:border-emerald-500"
              />
            </div>

            <div className="mt-3 p-4 rounded-xl bg-neutral-900/50 border border-neutral-800/60 flex justify-between items-center">
              <div>
                <span className="block text-[10px] text-neutral-500 font-mono uppercase">{t('verification_token')}</span>
                <span className="text-2xl font-mono tracking-widest font-bold text-emerald-400 glow-text">{totpCode}</span>
              </div>
              <div className="text-right">
                <span className="block text-[10px] text-neutral-500 font-mono">{t('remaining_life')}</span>
                <span className="text-sm font-mono text-neutral-300">{totpSecondsRemaining}s</span>
              </div>
            </div>
          </div>
        </div>

      </div>

      {/* Analyzer Card */}
      <div className="glass-card p-6 rounded-2xl space-y-4">
        <div className="flex items-center gap-2">
          <BadgeCheck className="w-5 h-5 text-indigo-400" />
          <h3 className="font-display font-medium text-white">{t('key_strength_analyzer')}</h3>
        </div>
        <p className="text-xs text-neutral-400">{t('key_analyzer_desc')}</p>
        
        <div className="space-y-4">
          <input 
            type="text"
            placeholder={t('key_audit_placeholder')}
            value={analyzerInput}
            onChange={(e) => setAnalyzerInput(e.target.value)}
            className="w-full px-4 py-2.5 rounded-xl bg-neutral-900/60 border border-neutral-800/60 font-mono text-sm text-white focus:outline-none focus:border-indigo-500"
          />

          {analyzerInput && (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2 animate-fade-in">
              <div className="p-3 bg-neutral-950/40 rounded-xl border border-neutral-800/40">
                <div className="text-[10px] font-mono text-neutral-500">{t('audit_score')}</div>
                <div className="text-lg font-mono font-bold text-white mt-0.5">{strength.score}%</div>
              </div>

              <div className="p-3 bg-neutral-950/40 rounded-xl border border-neutral-800/40">
                <div className="text-[10px] font-mono text-neutral-500">{t('entropy_level')}</div>
                <div className="text-lg font-mono font-bold text-white mt-0.5">{strength.entropyBits} {locale === 'ar' ? 'بايت عشوائية' : 'Bits'}</div>
              </div>

              <div className="p-3 bg-neutral-950/40 rounded-xl border border-neutral-800/40">
                <div className="text-[10px] font-mono text-neutral-500">{t('grade_classification')}</div>
                <div className="text-lg font-mono font-bold mt-0.5" style={{
                  color: strength.label === 'Sovereign-Grade' ? '#22d3ee' : strength.label === 'Medium' ? '#a855f7' : strength.label === 'Vulnerable' ? '#f59e0b' : '#f43f5e'
                }}>
                  {strength.label === 'Sovereign-Grade' 
                    ? (locale === 'ar' ? 'مستوى سيادي' : 'Sovereign-Grade') 
                    : strength.label === 'Medium' 
                      ? (locale === 'ar' ? 'متوسط' : 'Medium')
                      : strength.label === 'Vulnerable'
                        ? (locale === 'ar' ? 'ضعيف' : 'Vulnerable')
                        : (locale === 'ar' ? 'حرجة للغاية' : 'Critical')
                  }
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

    </div>
  );
};
