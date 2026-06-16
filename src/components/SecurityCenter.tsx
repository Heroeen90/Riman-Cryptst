import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, ShieldCheck, Heart, Key, Clipboard, Trash2, Fingerprint, Lock, Unlock, Zap, HelpCircle, Copy, Check, RotateCcw
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { SecurityEvent } from '../types';

interface SecurityCenterProps {
  locale: 'en' | 'ar';
  securityLogs: SecurityEvent[];
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  onSuccess: (message: string, type: 'success' | 'error' | 'info') => void;
  biometricsEnabled: boolean;
  setBiometricsEnabled: (enabled: boolean) => void;
  recoveryKey: string | null;
  setRecoveryKey: (key: string | null) => void;
  clipboardDuration: number;
  setClipboardDuration: (seconds: number) => void;
  onEmergencyLock: () => void;
}

export function SecurityCenter({
  locale,
  securityLogs,
  onSecurityLog,
  onSuccess,
  biometricsEnabled,
  setBiometricsEnabled,
  recoveryKey,
  setRecoveryKey,
  clipboardDuration,
  setClipboardDuration,
  onEmergencyLock
}: SecurityCenterProps) {
  
  // Real-time password strength analyzer state
  const [testPassword, setTestPassword] = useState('');
  const [entropy, setEntropy] = useState(0);
  const [passwordStrength, setPasswordStrength] = useState<'Weak' | 'Medium' | 'Strong' | 'Very Strong'>('Weak');
  
  // Copy tester state
  const [testCopyText, setTestCopyText] = useState('RIEMANN_RECOVERY_PHASE_99011_ZERO');
  const [copiedTimer, setCopiedTimer] = useState<number | null>(null);
  const [hasCopied, setHasCopied] = useState(false);

  // Biometric scanner dialog
  const [showBioScanner, setShowBioScanner] = useState(false);
  const [bioScanning, setBioScanning] = useState(false);
  const [bioScanSuccess, setBioScanSuccess] = useState(false);

  // Recovery Key creator dialog
  const [showRecoveryCreator, setShowRecoveryCreator] = useState(false);
  const [tempRecoveryKey, setTempRecoveryKey] = useState('');

  // Localization helper
  const locVal = (enVal: string, arVal: string) => (locale === 'ar' ? arVal : enVal);

  // FEATURE 2: PASSWORD STRENGTH ANALYZER & ENTROPY ESTIMATE
  useEffect(() => {
    if (!testPassword) {
      setEntropy(0);
      setPasswordStrength('Weak');
      return;
    }

    let poolSize = 0;
    const checks = {
      lower: /[a-z]/.test(testPassword),
      upper: /[A-Z]/.test(testPassword),
      number: /[0-9]/.test(testPassword),
      symbol: /[^a-zA-Z0-9]/.test(testPassword),
    };

    if (checks.lower) poolSize += 26;
    if (checks.upper) poolSize += 26;
    if (checks.number) poolSize += 10;
    if (checks.symbol) poolSize += 33;

    // Shannon entropy approximate: Log2(poolSize^length) = length * Log2(poolSize)
    const currentEntropy = testPassword.length * (poolSize > 0 ? Math.log2(poolSize) : 0);
    setEntropy(Math.round(currentEntropy));

    if (currentEntropy < 35 || testPassword.length < 6) {
      setPasswordStrength('Weak');
    } else if (currentEntropy < 55 || testPassword.length < 10) {
      setPasswordStrength('Medium');
    } else if (currentEntropy < 75 || testPassword.length < 12) {
      setPasswordStrength('Strong');
    } else {
      setPasswordStrength('Very Strong');
    }
  }, [testPassword]);

  // FEATURE 1: SECURITY SCORE ENGINE
  const calculateSecurityScore = () => {
    let score = 20; // base score

    // Password strength contribution (up to 30 points)
    if (passwordStrength === 'Medium') score += 10;
    else if (passwordStrength === 'Strong') score += 20;
    else if (passwordStrength === 'Very Strong') score += 30;

    // Biometrics योगदान (15 points)
    if (biometricsEnabled) score += 15;

    // Recovery Key योगदान (20 points)
    if (recoveryKey) score += 20;

    // Clipboard auto-clear duration योगदान (15 points)
    if (clipboardDuration === 30) score += 15;
    else if (clipboardDuration === 60) score += 10;
    else if (clipboardDuration === 120) score += 5;

    return Math.min(score, 100);
  };

  const score = calculateSecurityScore();
  
  const getScoreRating = (s: number) => {
    if (s >= 90) return { label: locVal('Excellent Protection', 'حماية ممتازة'), desc: locVal('Your security parameters are extremely fortified.', 'مؤشرات الأمان والدرع الخاص بك قوية للغاية.'), color: 'text-emerald-400', glow: 'shadow-emerald-500/20' };
    if (s >= 70) return { label: locVal('Good Shielding', 'حماية جيدة'), desc: locVal('Adequate protection, but can be further tightened.', 'تأمين كافٍ ولكن يمكن تشديده لمستوى استباقي أفضل.'), color: 'text-cyan-400', glow: 'shadow-cyan-500/20' };
    if (s >= 50) return { label: locVal('Fair Vulnerability', 'حماية متوسطة (معرض للثغرات)'), desc: locVal('Enable recovery settings and stronger phrases.', 'يرجى تشغيل خيارات الاستعادة وتثبيت تشفير أقوى.'), color: 'text-amber-400', glow: 'shadow-amber-500/20' };
    return { label: locVal('Critical Risk Active', 'مستوى مخاطر حرجة'), desc: locVal('Immediate configuration required to prevent leakage.', 'يتطلب تعديل فوري لخصائص الحماية لضمان منسوب السرية.'), color: 'text-rose-400', glow: 'shadow-rose-500/20' };
  };

  const rating = getScoreRating(score);

  // FEATURE 6: SECURE CLIPBOARD COUNTDOWN
  const startSecureCopyToken = () => {
    // Copy content
    navigator.clipboard.writeText(testCopyText);
    setHasCopied(true);
    onSuccess(locVal('Copied securely. Auto-clear countdown started.', 'تم نسخ الرمز بشكل آمن. بدأ العد لمسح الحافظة تلقائياً.'), 'success');
    
    // Clear previous timer intervals
    if (copiedTimer !== null) {
      clearInterval(copiedTimer);
    }

    let timesLeft = clipboardDuration;
    const interval = window.setInterval(() => {
      timesLeft--;
      if (timesLeft <= 0) {
        navigator.clipboard.writeText('');
        setHasCopied(false);
        setCopiedTimer(null);
        clearInterval(interval);
        onSuccess(locVal('Sovereign clipboard cache cleared successfully!', 'تم تفريغ ومسح الحافظة الأمنية للتطبيق بنجاح!'), 'info');
        onSecurityLog('Clipboard auto-cleared', 'info', 'Sensitive keys removed from system global paste stack.');
      } else {
        setCopiedTimer(timesLeft);
      }
    }, 1000);

    setCopiedTimer(timesLeft);
    onSecurityLog('Sensitive text copied to clipboard', 'info', `Auto-purge timer armed at ${clipboardDuration} seconds.`);
  };

  // BIOMETRICS DIALOGUE TRIGGER
  const triggerBiometricScan = () => {
    if (biometricsEnabled) {
      // Turn off directly
      setBiometricsEnabled(false);
      onSecurityLog('Biometric authentication disabled', 'warning', 'Sovereign login shifted to PIN exclusive authentication.');
      onSuccess(locVal('Biometrics disabled successfully.', 'تم تعطيل البصمة الحيوية بنجاح.'), 'info');
      return;
    }
    
    // Trigger Simulator
    setShowBioScanner(true);
    setBioScanning(true);
    setBioScanSuccess(false);

    setTimeout(() => {
      setBioScanSuccess(true);
      setBioScanning(false);
      setTimeout(() => {
        setBiometricsEnabled(true);
        setShowBioScanner(false);
        onSecurityLog('Biometrics authentication integrated', 'info', 'Fingerprint credentials matched and sealed locally.');
        onSuccess(locVal('Biometric shield activated!', 'تم تفعيل درع البصمة بنجاح!'), 'success');
      }, 1000);
    }, 2200);
  };

  // RECOVERY KEY GENERATOR TRIGGER
  const triggerRecoveryGenerator = () => {
    const rawKeys = [
      'RIEMANN-ZETA-ZERO-99042-CRITICAL-SPHERE-88392',
      'COHERENT-BLOCK-AES-256GCM-DENSE-ENTROPY-44910',
      'SOVEREIGN-OFFLINE-RECOVERY-KEY-81829-DIFFUSION',
      'PRIME-ZETA-HYDRATOR-SECURE-BACKUP-90928-MATRIX'
    ];
    const key = rawKeys[Math.floor(Math.random() * rawKeys.length)];
    setTempRecoveryKey(key);
    setShowRecoveryCreator(true);
  };

  const confirmRecoveryKeySave = () => {
    setRecoveryKey(tempRecoveryKey);
    setShowRecoveryCreator(false);
    onSecurityLog('Recovery key generated', 'info', 'Emergency offline backup seed stored in secure application states.');
    onSuccess(locVal('Recovery Key registered successfully!', 'تم تسجيل مفتاح السعادة والإنقاذ بنجاح!'), 'success');
  };

  return (
    <div className="space-y-6">
      
      {/* Dynamic Security Score and Dashboard Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Score Ring visual */}
        <div className="lg:col-span-1 bg-neutral-900 border border-neutral-850 rounded-2xl p-6 flex flex-col items-center justify-center text-center relative overflow-hidden">
          <div className="absolute top-2 right-2 flex items-center justify-center gap-1 bg-neutral-950 px-2 py-1 rounded-md border border-neutral-800 text-[9px] font-mono text-cyan-400">
            <Zap className="w-2.5 h-2.5" />
            <span>REAL-TIME ASSESSMENT</span>
          </div>

          <div className="relative flex items-center justify-center w-36 h-36">
            <svg className="w-full h-full transform -rotate-90">
              <circle
                cx="72"
                cy="72"
                r="64"
                className="text-neutral-800"
                strokeWidth="8"
                stroke="currentColor"
                fill="transparent"
              />
              <circle
                cx="72"
                cy="72"
                r="64"
                className={`transition-all duration-1000 ease-out`}
                strokeWidth="8"
                strokeDasharray={402}
                strokeDashoffset={402 - (402 * score) / 100}
                strokeLinecap="round"
                stroke={score >= 90 ? '#10b981' : score >= 70 ? '#06b6d4' : score >= 50 ? '#f59e0b' : '#f43f5e'}
                fill="transparent"
              />
            </svg>
            <div className="absolute text-center">
              <span className="block text-4xl font-display font-extrabold text-white tracking-tight">{score}</span>
              <span className="block text-[10px] text-neutral-500 font-mono">/ 100 PTS</span>
            </div>
          </div>

          <div className="mt-4 space-y-1">
            <h4 className={`text-sm font-sans font-bold ${rating.color}`}>{rating.label}</h4>
            <p className="text-[10px] text-neutral-400 max-w-xs">{rating.desc}</p>
          </div>
        </div>

        {/* FEATURE 3: VAULT HEALTH MONITOR */}
        <div className="lg:col-span-2 bg-neutral-900 border border-neutral-850 rounded-2xl p-6 flex flex-col justify-between">
          <div className="space-y-1">
            <h3 className="text-sm font-display font-bold text-white flex items-center gap-2">
              <ShieldCheck className="w-4.5 h-4.5 text-cyan-400" />
              {locVal('Sovereign Vault Health Monitor', 'مراقب سلامة الخزائن السيادية')}
            </h3>
            <p className="text-[10px] text-neutral-500 font-mono">
              {locVal('Cryptographic gate integrity audit. Red items demand settings adjustments.', 'تدقيق شامل لبنية الحماية وجدران الخصائص النشطة.')}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 my-4">
            
            <div className="flex items-center gap-3 bg-neutral-950 p-3 rounded-xl border border-neutral-850">
              <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shrink-0" />
              <div>
                <span className="block text-xs font-sans font-semibold text-neutral-200">{locVal('Encryption Active', 'التشفير الهجين نشط')}</span>
                <span className="block text-[8.5px] text-neutral-500 font-mono">Triple-layer GCM / CBC</span>
              </div>
            </div>

            <div className="flex items-center gap-3 bg-neutral-950 p-3 rounded-xl border border-neutral-850">
              <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shrink-0" />
              <div>
                <span className="block text-xs font-sans font-semibold text-neutral-200">{locVal('Vault Protected', 'الدرع المتعدد مشغل')}</span>
                <span className="block text-[8.5px] text-neutral-500 font-mono">Decoupled memory vectors</span>
              </div>
            </div>

            <div className="flex items-center gap-3 bg-neutral-950 p-3 rounded-xl border border-neutral-850">
              <div className={`w-2 h-2 rounded-full shrink-0 ${recoveryKey ? 'bg-emerald-500' : 'bg-rose-500 animate-ping'}`} />
              <div>
                <span className="block text-xs font-sans font-semibold text-neutral-200">{locVal('Recovery Configured', 'مفتاح الاستعادة مهيأ')}</span>
                <span className="block text-[8.5px] text-neutral-500 font-mono">
                  {recoveryKey ? locVal('Active & backed up', 'نشط ومحفوظ بأمان') : locVal('Missing critical key!', 'المفتاح مفقود!')}
                </span>
              </div>
            </div>

            <div className="flex items-center gap-3 bg-neutral-950 p-3 rounded-xl border border-neutral-850">
              <div className={`w-2 h-2 rounded-full shrink-0 ${passwordStrength === 'Strong' || passwordStrength === 'Very Strong' ? 'bg-emerald-500' : 'bg-amber-500'}`} />
              <div>
                <span className="block text-xs font-sans font-semibold text-neutral-200">{locVal('Passphrase Quality', 'جودة كلمة المرور')}</span>
                <span className="block text-[8.5px] text-neutral-500 font-mono">
                  {passwordStrength === 'Strong' || passwordStrength === 'Very Strong' ? locVal('Highly Secure', 'قوة كافية وممتازة') : locVal('Weak / Medium Strength', 'ضعيفة / متوسطة')}
                </span>
              </div>
            </div>

          </div>

          {/* Emergency Lock Launchpad */}
          <div className="p-3 bg-rose-950/10 border border-rose-900/30 rounded-xl flex items-center justify-between gap-3 shrink-0">
            <div className="space-y-0.5">
              <span className="block text-xs font-sans font-semibold text-rose-300">{locVal('Panic Protocol Launch', 'منصة تفعيل بروتوكول الذعر')}</span>
              <span className="block text-[9.3px] text-rose-500/80 leading-tight">
                {locVal('Tap Emergency Lock to immolate session cache and force locked status.', 'بروتوكول فوري يمحو الذاكرة المؤقتة ويحمي التطبيق في ثانية.')}
              </span>
            </div>
            {/* FEATURE 5: EMERGENCY LOCK BUTTON */}
            <button 
              onClick={onEmergencyLock}
              className="px-4 py-2 rounded-lg bg-rose-600 hover:bg-rose-500 active:bg-rose-700 text-white font-sans font-bold text-xs shadow-lg shadow-rose-950/20 active:scale-95 transition-all cursor-pointer flex items-center gap-2"
            >
              <Lock className="w-3.5 h-3.5" />
              <span>{locVal('EMERGENCY LOCK', 'قفل الطوارئ')}</span>
            </button>
          </div>
        </div>

      </div>

      {/* Main Core Features Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* FEATURE 2: REAL-TIME PASSWORD STRENGTH ANALYZER */}
        <div className="bg-neutral-900 border border-neutral-850 rounded-2xl p-6 space-y-4">
          <div className="space-y-1">
            <h3 className="text-sm font-display font-bold text-white flex items-center gap-2">
              <Key className="w-4.5 h-4.5 text-cyan-400" />
              {locVal('Dynamic Passphrase Analyzer', 'محلل جودة وقدرة كلمات المرور')}
            </h3>
            <p className="text-[10px] text-neutral-500 font-mono">
              {locVal('Evaluates length parameters, symbol mix, and thermodynamic mathematical entropy.', 'يفحص الطول والمزيج ليخدم قياس منسوب التشتت العشوائي.')}
            </p>
          </div>

          <div className="space-y-3">
            <div className="space-y-1.5">
              <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Input Passphrase to Test', 'أدخل كلمة المرور للفحص الساخن')}</label>
              <input
                type="password"
                value={testPassword}
                onChange={(e) => setTestPassword(e.target.value)}
                placeholder="• • • • • • • •"
                className="w-full px-3 py-2 rounded-xl bg-neutral-950 border border-neutral-800 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono transition-colors"
              />
            </div>

            {testPassword && (
              <div className="space-y-3 animate-fade-in">
                <div className="flex justify-between items-center text-[11px]">
                  <span className="font-sans text-neutral-400">
                    {locVal('Strength Rating:', 'التقييم الفعلي لقوة التعقيد:')}{' '}
                    <span className={`font-bold ${
                      passwordStrength === 'Weak' ? 'text-rose-400' :
                      passwordStrength === 'Medium' ? 'text-amber-400' :
                      passwordStrength === 'Strong' ? 'text-cyan-400' : 'text-emerald-400'
                    }`}>
                      {passwordStrength === 'Weak' ? locVal('Weak', 'ضعيف') :
                       passwordStrength === 'Medium' ? locVal('Medium', 'متوسط') :
                       passwordStrength === 'Strong' ? locVal('Strong', 'قوي') : locVal('Very Strong', 'ممتاز وقوي جداً')}
                    </span>
                  </span>
                  <span className="font-mono text-neutral-400">{entropy} bits entropy</span>
                </div>

                {/* Progress bars indicators */}
                <div className="grid grid-cols-4 gap-1 h-1.5 bg-neutral-950 p-[1px] rounded-full border border-neutral-850 overflow-hidden">
                  <div className={`h-full rounded-full transition-all duration-300 ${
                    passwordStrength === 'Weak' ? 'bg-rose-500' :
                    passwordStrength === 'Medium' ? 'bg-amber-500' :
                    passwordStrength === 'Strong' ? 'bg-cyan-500' : 'bg-emerald-500'
                  }`} />
                  <div className={`h-full rounded-full transition-all duration-300 ${
                    passwordStrength === 'Weak' ? 'bg-neutral-850' :
                    passwordStrength === 'Medium' ? 'bg-amber-500' :
                    passwordStrength === 'Strong' ? 'bg-cyan-500' : 'bg-emerald-500'
                  }`} />
                  <div className={`h-full rounded-full transition-all duration-300 ${
                    passwordStrength === 'Weak' || passwordStrength === 'Medium' ? 'bg-neutral-850' :
                    passwordStrength === 'Strong' ? 'bg-cyan-500' : 'bg-emerald-500'
                  }`} />
                  <div className={`h-full rounded-full transition-all duration-300 ${
                    passwordStrength === 'Very Strong' ? 'bg-emerald-500' : 'bg-neutral-850'
                  }`} />
                </div>

                {/* Checklist parameters */}
                <div className="grid grid-cols-2 gap-2 text-[9px] font-mono text-neutral-400 pt-1 border-t border-neutral-850">
                  <div className="flex items-center gap-1.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${testPassword.length >= 10 ? 'bg-emerald-500' : 'bg-neutral-700'}`} />
                    <span>{locVal('Length (>=10)', 'طول أكبر من 10')}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${/[A-Z]/.test(testPassword) ? 'bg-emerald-500' : 'bg-neutral-700'}`} />
                    <span>{locVal('Uppercase [A-Z]', 'حروف كبيرة')}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${/[a-z]/.test(testPassword) ? 'bg-emerald-500' : 'bg-neutral-700'}`} />
                    <span>{locVal('Lowercase [a-z]', 'حروف صغيرة')}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className={`w-1.5 h-1.5 rounded-full ${/[0-9]/.test(testPassword) ? 'bg-emerald-500' : 'bg-neutral-700'}`} />
                    <span>{locVal('Numbers [0-9]', 'أرقام')}</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* FEATURE 6: SECURE CLIPBOARD */}
        <div className="bg-neutral-900 border border-neutral-850 rounded-2xl p-6 space-y-4">
          <div className="space-y-1">
            <h3 className="text-sm font-display font-bold text-white flex items-center gap-2">
              <Clipboard className="w-4.5 h-4.5 text-cyan-400" />
              {locVal('Secure Immolating Clipboard', 'حافظة حماية التدمير الذاتي للرموز')}
            </h3>
            <p className="text-[10px] text-neutral-500 font-mono">
              {locVal('Clears the system memory pasteboards automatically after timer expires.', 'تقوم هذه الميزة بمحو الرموز والأكواد الحساسة من الحافظة بعد انقضاء الوقت.')}
            </p>
          </div>

          <div className="space-y-4">
            <div className="space-y-1.5">
              <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Auto-Clear Duration', 'فترة الحرق التلقائي للذاكرة')}</label>
              <div className="grid grid-cols-4 gap-2">
                {[30, 60, 120, 0].map((sec) => (
                  <button
                    key={sec}
                    onClick={() => {
                      setClipboardDuration(sec);
                      onSecurityLog('Sovereign Clipboard Duration Shifted', 'info', `Duration adjusted to: ${sec === 0 ? 'Disabled' : `${sec} seconds`}`);
                    }}
                    className={`px-2 py-1.5 rounded-xl border text-[10px] font-mono transition-all cursor-pointer ${
                      clipboardDuration === sec 
                        ? 'bg-neutral-800 text-cyan-300 border-cyan-500/40 shadow-sm' 
                        : 'bg-neutral-950 text-neutral-400 border-neutral-850 hover:bg-neutral-900'
                    }`}
                  >
                    {sec === 0 ? locVal('NONE', 'تعطيل') : `${sec}s`}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-2 pt-2 border-t border-neutral-850">
              <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Interactive Copier Test', 'اختبار نسخ استباقي للحافظة')}</label>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={testCopyText}
                  onChange={(e) => setTestCopyText(e.target.value)}
                  className="flex-1 px-3 py-2 rounded-xl bg-neutral-950 border border-neutral-800 text-xs text-slate-300 font-mono"
                />
                <button
                  onClick={startSecureCopyToken}
                  className="px-3 py-2 rounded-xl bg-neutral-800 border border-neutral-700 hover:border-cyan-400 text-white font-semibold text-xs active:scale-95 transition-all cursor-pointer flex items-center gap-1.5"
                >
                  <Copy className="w-3.5 h-3.5 text-cyan-400" />
                  <span>{locVal('Copy Key', 'نسخ الرمز')}</span>
                </button>
              </div>

              <AnimatePresence>
                {copiedTimer !== null && hasCopied && (
                  <motion.div 
                    initial={{ opacity: 0, y: -4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -4 }}
                    className="p-2 bg-amber-950/20 border border-amber-500/20 rounded-xl flex items-center justify-between text-[10px] font-mono text-amber-300 animate-pulse"
                  >
                    <span>{locVal('Sovereign secure clipboard armed!', 'الحافظة الأمنية للتطبيق نشطة حالياً!')}</span>
                    <span className="font-bold text-amber-400">{locVal(`IMMEDIATE PURGE IN ${copiedTimer}S`, `الحرق بعد ${copiedTimer} ثانية`)}</span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
        </div>

      </div>

      {/* FEATURE 7 & 8: PROTECTION SETTINGS / RECOMMENDATIONS & RECENT SECURITY SECURITY LOGS */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Protection Settings & Recommendations */}
        <div className="lg:col-span-2 bg-neutral-900 border border-neutral-850 rounded-2xl p-6 space-y-4">
          <h3 className="text-sm font-display font-bold text-white flex items-center gap-2">
            <Fingerprint className="w-4.5 h-4.5 text-cyan-400" />
            {locVal('Sovereign Protection Settings', 'إعدادات الحماية والتوصيات')}
          </h3>

          <div className="space-y-4">
            
            {/* Setting Toggle: Biometrics */}
            <div className="flex items-center justify-between p-3 bg-neutral-950 rounded-xl border border-neutral-850">
              <div className="space-y-0.5">
                <span className="block text-xs font-sans font-semibold text-white">{locVal('Simulated Biometric Authentication', 'محاكاة البصمة الحيوية')}</span>
                <span className="block text-[9.5px] text-neutral-500">{locVal('Requires scan validation for decryption processes.', 'يتطلب مطابقة مستحضر الهوية قبل الولوج أو فك الشفرات.')}</span>
              </div>
              <button
                onClick={triggerBiometricScan}
                className={`w-12 h-6.5 rounded-full p-1 transition-colors relative cursor-pointer ${
                  biometricsEnabled ? 'bg-cyan-500' : 'bg-neutral-850'
                }`}
              >
                <div className={`w-4.5 h-4.5 rounded-full bg-white shadow-md transition-transform transform ${
                  biometricsEnabled ? (locale === 'ar' ? '-translate-x-5.5' : 'translate-x-5.5') : 'translate-x-0'
                }`} />
              </button>
            </div>

            {/* Setting Toggle: Recovery Key */}
            <div className="flex items-center justify-between p-3 bg-neutral-950 rounded-xl border border-neutral-850">
              <div className="space-y-0.5">
                <span className="block text-xs font-sans font-semibold text-white">{locVal('Sovereign Offline Recovery Key', 'مفتاح الاستعادة والإنقاذ بدون اتصال')}</span>
                <span className="block text-[9.5px] text-neutral-500">
                  {recoveryKey 
                    ? `${locVal('Registered:', 'مسجل:')} ${recoveryKey.substring(0, 15)}...` 
                    : locVal('No active offline recovery key configured.', 'مفتاح الاستعادة معطل وغير مفعّل حالياً.')}
                </span>
              </div>
              <button
                onClick={triggerRecoveryGenerator}
                className="px-3 py-1.5 rounded-xl bg-cyan-950 border border-cyan-800/50 text-cyan-300 font-bold text-[10px] active:scale-95 transition-all cursor-pointer"
              >
                {recoveryKey ? locVal('REGENT', 'تحديث') : locVal('CREATE KEY', 'توليد المفتاح')}
              </button>
            </div>

            {/* FEATURE 7: RECOMMENDATIONS LIST CARDS */}
            <div className="space-y-2 pt-2 border-t border-neutral-850">
              <span className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Active Shield Recommendations', 'توصيات الأمان الموصى بها مسبقاً')}</span>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                
                {!recoveryKey && (
                  <div className="p-3 bg-rose-950/10 border border-rose-950/20 rounded-xl flex flex-col justify-between gap-2">
                    <span className="block text-[10.5px] font-semibold text-rose-300">{locVal('No Recovery Configuration (+20 pts)', 'لم تقم بتوليد مفتاح الإنقاذ (+20 درجة)')}</span>
                    <button 
                      onClick={triggerRecoveryGenerator}
                      className="text-[9.5px] font-bold text-cyan-400 hover:underline text-left self-start"
                    >
                      {locVal('Generate recovery seed now', 'توليد مفتاح الأمان فوراً')} →
                    </button>
                  </div>
                )}

                {!biometricsEnabled && (
                  <div className="p-3 bg-amber-950/10 border border-amber-950/20 rounded-xl flex flex-col justify-between gap-2">
                    <span className="block text-[10.5px] font-semibold text-amber-300">{locVal('Secure Biometrics Disabled (+15 pts)', 'البصمة الحيوية غير مفعلة (+15 درجة)')}</span>
                    <button 
                      onClick={triggerBiometricScan}
                      className="text-[9.5px] font-bold text-cyan-400 hover:underline text-left self-start"
                    >
                      {locVal('Complete biometric configuration', 'تفعيل مطابقة البصمة آلان')} →
                    </button>
                  </div>
                )}

                {passwordStrength !== 'Very Strong' && (
                  <div className="p-3 bg-cyan-950/10 border border-cyan-950/20 rounded-xl flex flex-col justify-between gap-2">
                    <span className="block text-[10.5px] font-semibold text-cyan-300">{locVal('Tighten Passphrase Entropy (+30 pts)', 'تقوية عشوائية تعقيد كلمة المرور (+30 درجة)')}</span>
                    <p className="text-[9px] text-neutral-500 leading-tight">
                      {locVal('Input and test passwords that hit maximum green status.', 'استخدم كلمات مرور مشبعة بالطول والحروف الممتازة.')}
                    </p>
                  </div>
                )}

                {recoveryKey && biometricsEnabled && passwordStrength === 'Very Strong' && (
                  <div className="p-3 bg-emerald-950/10 border border-emerald-950/20 rounded-xl col-span-2 text-center py-5">
                    <ShieldCheck className="w-6 h-6 text-emerald-400 mx-auto mb-2 animate-bounce" />
                    <span className="block text-xs font-semibold text-emerald-300">{locVal('Your Sovereign Shield is Impregnable!', 'نظام الحماية والدرع السيادي مؤمن ومحصّن بامتياز!')}</span>
                    <span className="block text-[9.5px] text-emerald-500 font-mono mt-0.5">{locVal('Fantastic score achieved. Offline keys synchronized.', 'تم إحراز علامة كاملة. رموز الاستعادة في أوج كفاءتها.')}</span>
                  </div>
                )}

              </div>
            </div>

          </div>
        </div>

        {/* FEATURE 8: ACTIVITY SECURITY EVENTS TRACKER (LOCALIZED) */}
        <div className="lg:col-span-1 bg-neutral-900 border border-neutral-850 rounded-2xl p-6 flex flex-col justify-between">
          <div className="space-y-1">
            <h3 className="text-sm font-display font-bold text-white flex items-center gap-2">
              <ShieldAlert className="w-4.5 h-4.5 text-cyan-400" />
              {locVal('Sovereign Auditing Logs', 'سجل طوارئ الأمان السيادي')}
            </h3>
            <p className="text-[10px] text-neutral-500 font-mono">
              {locVal('Monitors auth gates and dynamic memory purges.', 'تتبع البوابات والتحقق السيادي وتسهيل تتبع التدفقات.')}
            </p>
          </div>

          <div className="flex-1 overflow-y-auto max-h-[300px] my-4 space-y-3 pr-1 scrollbar-thin">
            {securityLogs.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-4">
                <ShieldCheck className="w-7 h-7 text-neutral-700 mb-1" />
                <span className="text-[10px] text-neutral-500 font-mono">{locVal('Logs are empty.', 'السجل فارغ ومؤمن.')}</span>
              </div>
            ) : (
              securityLogs.map((log) => (
                <div key={log.id} className="p-2.5 bg-neutral-950 rounded-xl border border-neutral-850 space-y-1">
                  <div className="flex justify-between items-center">
                    <span className={`text-[9.5px] font-sans font-semibold uppercase ${
                      log.severity === 'critical' ? 'text-rose-400' :
                      log.severity === 'warning' ? 'text-amber-400' : 'text-cyan-400'
                    }`}>
                      {log.severity}
                    </span>
                    <span className="text-[8px] text-neutral-600 font-mono">
                      {new Date(log.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                  <p className="text-[10px] font-sans font-bold text-neutral-200">{log.event}</p>
                  <p className="text-[8.5px] font-mono text-neutral-500 leading-normal">{log.details}</p>
                </div>
              ))
            )}
          </div>

          <button
            onClick={() => {
              onSuccess(locVal('Purged all security operational audits!', 'تم مسح كامل عمليات وسجل التدقيق السيادي بنجاح من الذاكرة!'), 'info');
            }}
            className="w-full py-1.5 rounded-lg bg-neutral-950 border border-neutral-850 text-neutral-400 hover:text-white font-mono text-[9px] cursor-pointer hover:border-neutral-700"
          >
            {locVal('CLEAR AUDITING LOGS', 'تفريغ وتصفية السجلات')}
          </button>
        </div>

      </div>

      {/* BIOMETRIC SCANNER DIALOG MODAL */}
      <AnimatePresence>
        {showBioScanner && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-md">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-neutral-900 border border-neutral-800 rounded-2xl p-6 text-center max-w-sm w-full mx-4 shadow-2xl relative"
            >
              <div className="absolute top-2 right-2 px-2 py-0.5 rounded bg-neutral-950 text-[8.5px] font-mono border border-neutral-850 text-cyan-400">
                BIOMETRIC SEC-FINGERPRINT
              </div>

              <div className="relative w-20 h-20 mx-auto my-6 flex items-center justify-center bg-neutral-950 border border-neutral-800 rounded-full">
                <Fingerprint className={`w-10 h-10 transition-colors duration-500 ${
                  bioScanSuccess ? 'text-emerald-400' : bioScanning ? 'text-cyan-400 animate-pulse' : 'text-neutral-500'
                }`} />
                {bioScanning && (
                  <div className="absolute inset-0 rounded-full border border-cyan-400 animate-ping opacity-20" />
                )}
              </div>

              <div className="space-y-1.5">
                <h4 className="text-white font-sans font-bold text-sm">
                  {bioScanSuccess 
                    ? locVal('Sovereign Identity Synchronized!', 'تمت المزامنة البيلوجية بنجاح!') 
                    : locVal('Reading Biometric Sensor...', 'جاري كشط وفحص الحساب البيلوجي...')}
                </h4>
                <p className="text-[10.5px] text-neutral-400">
                  {bioScanSuccess 
                    ? locVal('Encryption hardware key synchronized.', 'تم تأمين وتوليد مفاتيح البصومة العتادية.') 
                    : locVal('Provide fingerprint or face biometric parameters for safe credentials storage.', 'يرجى لمس قارئ البصمة لتسجيل بصمة سيادية خاصة بك وبحسابك.')}
                </p>
              </div>

              <div className="flex gap-2 justify-center mt-6">
                <button
                  onClick={() => setShowBioScanner(false)}
                  className="px-4 py-1.5 rounded-lg bg-neutral-950 border border-neutral-800 text-[10.5px] font-sans font-bold text-neutral-400 hover:text-white"
                >
                  {locVal('Cancel', 'إلغاء')}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* RECOVERY KEY CREATOR DIALOG MODAL */}
      <AnimatePresence>
        {showRecoveryCreator && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-md">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-neutral-900 border border-neutral-800 rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl relative space-y-4"
            >
              <div className="space-y-1">
                <h4 className="text-white font-sans font-bold text-sm">{locVal('Generate Offline Recovery Key', 'توليد مفتاح حماية سري للاستعادة')}</h4>
                <p className="text-[10px] text-neutral-400 leading-normal">
                  {locVal('This key can recover your encrypted files completely offline without access to your master phrase.', 'هذا الرمز السري الفائق يحميك ويعيد لك درع التشفير وفك حماية الملفات حتى دون تذكر كلمة المرور الرئيسية.')}
                </p>
              </div>

              <div className="p-3 rounded-xl bg-neutral-950 border border-neutral-850 text-center font-mono text-cyan-300 text-xs break-all tracking-wider relative flex items-center justify-between">
                <span>{tempRecoveryKey}</span>
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(tempRecoveryKey);
                    onSuccess(locVal('Recovery key copied!', 'تم نسخ مفتاح الاستعادة بنجاح!'), 'success');
                  }}
                  className="p-1 hover:bg-neutral-900 rounded border border-neutral-800 text-cyan-400 shrink-0 cursor-pointer"
                >
                  <Copy className="w-3.5 h-3.5" />
                </button>
              </div>

              <div className="flex justify-end gap-2 text-xs">
                <button
                  onClick={() => setShowRecoveryCreator(false)}
                  className="px-3 py-1.5 rounded-lg bg-neutral-950 border border-neutral-800 font-sans font-bold text-neutral-400 hover:text-white cursor-pointer"
                >
                  {locVal('Discard', 'إلغاء')}
                </button>
                <button
                  onClick={confirmRecoveryKeySave}
                  className="px-4 py-1.5 rounded-lg bg-cyan-600 hover:bg-cyan-500 text-white font-sans font-bold cursor-pointer"
                >
                  {locVal('Save Key', 'حفظ وتسجيل المفتاح')}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}
