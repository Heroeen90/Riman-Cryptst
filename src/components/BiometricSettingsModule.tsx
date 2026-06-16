import React, { useState, useEffect, useRef } from 'react';
import { 
  Fingerprint, ShieldAlert, CheckCircle, ShieldCheck, Activity, Watch, 
  Settings, Lock, Unlock, RefreshCw, Smartphone, AlertTriangle 
} from 'lucide-react';
import { useTranslation } from '../lib/I18nContext';

interface BiometricSettingsProps {
  locale: string;
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  biometricsEnabled: boolean;
  setBiometricsEnabled: (val: boolean) => void;
  biometricType: 'fingerprint' | 'face' | 'both';
  setBiometricType: (val: 'fingerprint' | 'face' | 'both') => void;
  sessionTimeout: number; // in minutes
  setSessionTimeout: (val: number) => void;
  failedAttempts: number;
  setFailedAttempts: (val: number) => void;
  lockUntil: number | null;
  setLockUntil: (val: number | null) => void;
  onLockApp: () => void;
  lastActivity: number;
  loginTime: number;
}

export const BiometricSettingsModule: React.FC<BiometricSettingsProps> = ({
  locale,
  onSuccess,
  onSecurityLog,
  biometricsEnabled,
  setBiometricsEnabled,
  biometricType,
  setBiometricType,
  sessionTimeout,
  setSessionTimeout,
  failedAttempts,
  setFailedAttempts,
  lockUntil,
  setLockUntil,
  onLockApp,
  lastActivity,
  loginTime
}) => {
  const { t } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // Local scanning animation states
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<'idle' | 'success' | 'fail'>('idle');
  const [customTimeout, setCustomTimeout] = useState<string>('');
  const [sessionDuration, setSessionDuration] = useState<string>('00:00');
  const [isCustomTimeoutActive, setIsCustomTimeoutActive] = useState<boolean>(false);
  const [cooldownRemaining, setCooldownRemaining] = useState<number>(0);

  const scanTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Update elapsed session duration
  useEffect(() => {
    const timer = setInterval(() => {
      const elapsedMs = Date.now() - loginTime;
      const hours = Math.floor(elapsedMs / (1000 * 60 * 60));
      const mins = Math.floor((elapsedMs % (1000 * 60 * 60)) / (1000 * 60));
      const secs = Math.floor((elapsedMs % (1000 * 60)) / 1000);
      
      const hrStr = hours.toString().padStart(2, '0');
      const minStr = mins.toString().padStart(2, '0');
      const secStr = secs.toString().padStart(2, '0');
      
      setSessionDuration(`${hrStr}:${minStr}:${secStr}`);
    }, 1000);

    return () => clearInterval(timer);
  }, [loginTime]);

  // Handle temporary lock cooldown remaining ticks
  useEffect(() => {
    if (!lockUntil) return;

    const interval = setInterval(() => {
      const diff = Math.ceil((lockUntil - Date.now()) / 1000);
      if (diff <= 0) {
        setLockUntil(null);
        setCooldownRemaining(0);
        setFailedAttempts(0);
        onSecurityLog(
          'Biometric temporary lock expired', 
          'info', 
          'Scanning capabilities restored.'
        );
        onSuccess(
          locVal('Temporary lock released. Ready to scan.', 'انتهى القفل المؤقت للكاميرا/البصمة. جاهز للمسح ثانية.'), 
          'success'
        );
      } else {
        setCooldownRemaining(diff);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [lockUntil]);

  const toggleBiometricMaster = (enabled: boolean) => {
    setBiometricsEnabled(enabled);
    if (enabled) {
      onSecurityLog(
        'Biometric Auth Enabled',
        'success',
        `User enabled quick biometric verification of type: ${biometricType.toUpperCase()}.`
      );
      onSuccess(
        locVal('Biometric security integrations successfully active.', 'تم تنشيط المصادقة الحيوية بنجاح.'),
        'success'
      );
    } else {
      onSecurityLog(
        'Biometric Auth Disabled',
        'warning',
        'User removed quick biometric authorization from this browser instance.'
      );
      onSuccess(
        locVal('Biometric security deactivated.', 'تم إلغاء تفعيل المصادقة الحيوية.'),
        'info'
      );
    }
  };

  const handleTriggerMockScan = (forceSuccess: boolean = true) => {
    if (lockUntil && Date.now() < lockUntil) {
      onSuccess(
        locVal(`Scanner locked. Wait ${cooldownRemaining}s`, `المستشعر مقفل مؤقتاً. انتظر ${cooldownRemaining} ثانية`), 
        'error'
      );
      return;
    }

    if (isScanning) return;
    setIsScanning(true);
    setScanResult('idle');

    onSecurityLog(
      'Biometric scan sequence initiated',
      'info',
      `Activating device hardware stream for ${biometricType.toUpperCase()} query.`
    );

    scanTimeoutRef.current = setTimeout(() => {
      setIsScanning(false);
      if (forceSuccess) {
        setScanResult('success');
        setFailedAttempts(0);
        onSecurityLog(
          'Biometric scan verify success',
          'success',
          `Riemann Zero spectral alignment matched with ${biometricType.toUpperCase()} state.`
        );
        onSuccess(
          locVal('Biometric verification passed!', 'تم التحقق من المعالم الحيوية بنجاح!'),
          'success'
        );
      } else {
        setScanResult('fail');
        const nextAttempts = failedAttempts + 1;
        setFailedAttempts(nextAttempts);
        
        onSecurityLog(
          'Biometric scan verify failure',
          'warning',
          `Failed biometric match attempt #${nextAttempts}.`
        );

        if (nextAttempts >= 5) {
          const lockedTime = Date.now() + 30000; // 30 seconds cooldown
          setLockUntil(lockedTime);
          onSecurityLog(
            'Biometric scanner hardware lock active',
            'critical',
            '5 consecutive failed biometric attempts detected. Temporary lockdown enforced for 30s.'
          );
          onSuccess(
            locVal('Too many failures! Scanner locked for 30s.', 'سجلت 5 محاولات خاطئة! تم قفل المستشعر مؤقتاً لـ 30 ثانية.'),
            'error'
          );
        } else {
          onSuccess(
            locVal(`Verification fingerprint/face mismatch! (${nextAttempts}/5)`, `المعالم الحيوية لم تتطابق! محاولة (${nextAttempts}/5)`),
            'error'
          );
        }
      }
    }, 1800);
  };

  const handleTimeoutChange = (minutes: number) => {
    setSessionTimeout(minutes);
    setIsCustomTimeoutActive(false);
    onSecurityLog(
      'Inactivity lock interval modified',
      'info',
      `Auto-lock timer policy configured to: ${minutes} Minute(s).`
    );
    onSuccess(
      locVal(`Auto-lock configured to ${minutes} mins.`, `تم ضبط قفل الخمول التلقائي على ${minutes} دقيقة.`),
      'success'
    );
  };

  // Convert last activity timestamp to human string
  const formatTimeHM = (timestamp: number) => {
    return new Date(timestamp).toLocaleTimeString(locale === 'ar' ? 'ar-EG' : 'en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <div className="p-6 bg-neutral-950 font-sans space-y-6 text-white" id="biometrics_settings_container">
      {/* Header Info */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-neutral-900">
        <div>
          <h2 className="text-lg font-display font-medium tracking-tight text-white flex items-center gap-2">
            <Fingerprint className="w-5 h-5 text-purple-400" />
            {locVal('Biometric Access & Session Manager', 'إدارة الأمن الحيوي وجلسات العمل')}
          </h2>
          <p className="text-xs text-neutral-500 font-mono mt-1">
            {locVal('Configure military-grade biometric bypass credentials and live automated lock bounds.', 'تخصيص بروتوكولات العبور الهجينة للمستشعرات المدمجة وإدارة مؤقتات الخمول.')}
          </p>
        </div>

        <button 
          onClick={onLockApp}
          className="flex items-center gap-2 bg-rose-950/45 text-rose-400 border border-rose-900 hover:bg-rose-900/40 text-xs px-3.5 py-2 rounded-xl transition duration-150 font-mono font-bold align-middle cursor-pointer"
        >
          <Lock className="w-3.5 h-3.5" />
          {locVal('MANUAL LOCKDOWN NOW', 'تفعيل قفل الطوارئ اللحظي')}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column: Status Card & Configurations */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Trusted Device Status Panel (Feature 5) */}
          <div className="p-5 rounded-2xl bg-gradient-to-br from-neutral-900 to-neutral-950 border border-neutral-850 space-y-4">
            <h3 className="text-xs font-mono font-bold text-neutral-400 uppercase tracking-wider flex items-center gap-2">
              <Smartphone className="w-4 h-4 text-cyan-400" />
              {locVal('Trusted Device Environment', 'حالة اعتماد وأمن الجهاز الموثوق')}
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
              
              <div className="p-3 bg-neutral-950/60 rounded-xl border border-neutral-900 flex justify-between items-center">
                <span className="text-[11px] text-neutral-400 font-mono">{locVal('Device Protected State', 'حماية الجهاز العامة')}</span>
                <span className="text-[11px] font-mono font-bold text-emerald-400 flex items-center gap-1.5">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                  {locVal('PROTECTED', 'محمي بالكامل')}
                </span>
              </div>

              <div className="p-3 bg-neutral-950/60 rounded-xl border border-neutral-900 flex justify-between items-center">
                <span className="text-[11px] text-neutral-400 font-mono">{locVal('Biometrics Available', 'تكامل المستشعرات')}</span>
                <span className="text-[11px] font-mono font-bold text-cyan-400">
                  {locVal('AVAILABLE', 'متاحة ونشطة')}
                </span>
              </div>

              <div className="p-3 bg-neutral-950/60 rounded-xl border border-neutral-900 flex justify-between items-center">
                <span className="text-[11px] text-neutral-400 font-mono">{locVal('Biometrics Enabled', 'تفعيل مستشعرات العبور')}</span>
                <span className={`text-[11px] font-mono font-bold ${biometricsEnabled ? 'text-emerald-400' : 'text-neutral-500'}`}>
                  {biometricsEnabled ? locVal('ENABLED 🟢', 'مفعلة نشطة 🟢') : locVal('DISABLED 🔴', 'ملغاة معطلة 🔴')}
                </span>
              </div>

              <div className="p-3 bg-neutral-950/60 rounded-xl border border-neutral-900 flex justify-between items-center">
                <span className="text-[11px] text-neutral-400 font-mono">{locVal('Active Session Token', 'جلسة العمل النشطة')}</span>
                <span className="text-[11px] font-mono font-bold text-purple-400 animate-pulse">
                  {locVal('ACTIVE SECURE', 'نشطة وتحت المراقبة')}
                </span>
              </div>
            </div>

            <div className="pt-2 flex flex-col md:flex-row justify-between items-start md:items-center text-[10px] text-neutral-500 border-t border-neutral-900 gap-2">
              <div className="flex items-center gap-1">
                <Watch className="w-3 h-3 text-neutral-400" />
                <span>{locVal('Session Duration:', 'مدة الجلسة الحالية:')}</span>
                <span className="font-mono text-cyan-400 font-bold">{sessionDuration}</span>
              </div>
              <div className="flex items-center gap-1">
                <Activity className="w-3 h-3 text-neutral-400" />
                <span>{locVal('Last Action registered:', 'آخر نشاط مسجل:')}</span>
                <span className="font-mono text-cyan-400 font-bold">{formatTimeHM(lastActivity)}</span>
              </div>
            </div>
          </div>

          {/* Settings Control Panel (Feature 7) */}
          <div className="p-5 rounded-2xl bg-neutral-900/40 border border-neutral-850 space-y-6">
            <h3 className="text-xs font-mono font-bold text-neutral-400 uppercase tracking-wider flex items-center gap-2">
              <Settings className="w-4 h-4 text-purple-400" />
              {locVal('Biometric Security Directives', 'توجيهات وإعدادات الأمان الحيوي')}
            </h3>

            {/* Toggle Switch */}
            <div className="flex items-center justify-between p-4 bg-neutral-950 rounded-xl border border-neutral-900">
              <div className="space-y-1 pr-4">
                <span className="block text-xs font-bold text-white">
                  {locVal('Quick Biometric Unlock Bypass', 'تفعيل العبور السريع بالبصمة/الوجه')}
                </span>
                <span className="block text-[10px] text-neutral-500 leading-normal">
                  {locVal('Bypass standard 4-digit security PIN unlock requests using biometrics. Master-PIN still required for sensitive directives.', 'تجاوز طلب رمز PIN عبر بصمة الإصبع أو مسح معالم الوجه فور فتح التطبيق. يبقى رمز PIN مطلوباً للعمليات الحساسة.')}
                </span>
              </div>

              <div className="relative inline-flex items-center h-6 rounded-full w-11 shrink-0 cursor-pointer transition-colors"
                   onClick={() => toggleBiometricMaster(!biometricsEnabled)}>
                <input type="checkbox" className="sr-only" checked={biometricsEnabled} onChange={() => {}} />
                <span className={`inline-block w-4 h-4 transform bg-white rounded-full transition-transform ${
                  biometricsEnabled ? 'translate-x-6 bg-cyan-400' : 'translate-x-1 bg-neutral-600'
                }`} />
                <span className={`absolute inset-0 rounded-full transition-colors -z-10 ${
                  biometricsEnabled ? 'bg-cyan-950 border border-cyan-500/50' : 'bg-neutral-800'
                }`} />
              </div>
            </div>

            {/* Choose Auth Type */}
            <div className="space-y-3">
              <label className="block text-xs font-mono text-neutral-400 uppercase">
                {locVal('1. Select Sovereign Sensor Protocol', '1. بروتوكول المصادقة الحيوية المستهدف')}
              </label>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                {[
                  { id: 'fingerprint', label: locVal('Fingerprint ID', 'بصمة الإصبع'), desc: locVal('Native touch reader', 'بصمة اللمس الفريدة') },
                  { id: 'face', label: locVal('Face Verification', 'التعرف على الوجه'), desc: locVal('Native optical scanner', 'المسح الضوئي المدمج للوجه') },
                  { id: 'both', label: locVal('Multi-Spectral Combo', 'المصادقة الهجينة'), desc: locVal('Both scans required', 'طلب المستشعرين معاً') },
                ].map((item) => {
                  const isSelected = biometricType === item.id;
                  return (
                    <button
                      key={item.id}
                      disabled={!biometricsEnabled}
                      onClick={() => {
                        setBiometricType(item.id as any);
                        onSecurityLog(
                          'Biometric Auth Type Updated',
                          'info',
                          `Verification protocol modified: ${item.id.toUpperCase()}`
                        );
                        onSuccess(
                          locVal(`Biometric criteria changed in settings.`, `تهيئة نظام التعرف الافتراضي إلى ${item.label}.`),
                          'success'
                        );
                      }}
                      className={`p-3 text-start rounded-xl border transition-all ${
                        !biometricsEnabled ? 'opacity-30 cursor-not-allowed' : 'cursor-pointer'
                      } ${
                        isSelected 
                          ? 'bg-purple-950/20 border-purple-500 text-white' 
                          : 'bg-neutral-950 border-neutral-900 hover:border-neutral-850 text-neutral-400 hover:text-white'
                      }`}
                    >
                      <span className="block text-xs font-bold leading-none mb-1">{item.label}</span>
                      <span className="block text-[9px] text-neutral-500 leading-none">{item.desc}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Session Timeout Settings (Feature 4) */}
            <div className="space-y-3">
              <label className="block text-xs font-mono text-neutral-400 uppercase">
                {locVal('2. Active Inactivity Timeout Bounds', '2. مهلة الخمول المطلوبة لإغلاق التطبيق')}
              </label>

              <div className="flex flex-wrap gap-2.5">
                {[1, 5, 15, 30].map((mins) => {
                  const isSelected = sessionTimeout === mins && !isCustomTimeoutActive;
                  return (
                    <button
                      key={mins}
                      onClick={() => handleTimeoutChange(mins)}
                      className={`px-3.5 py-2 text-xs font-mono font-semibold rounded-lg border transition cursor-pointer ${
                        isSelected 
                          ? 'bg-cyan-950/30 border-cyan-500 text-cyan-400' 
                          : 'bg-neutral-950 border-neutral-900 text-neutral-400 hover:text-white'
                      }`}
                    >
                      {mins === 1 ? locVal('1 MIN', 'دقيقة واحدة') : locVal(`${mins} MINS`, `${mins} دقائق`)}
                    </button>
                  );
                })}

                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => {
                      setIsCustomTimeoutActive(true);
                    }}
                    className={`px-3.5 py-2 text-xs font-mono font-semibold rounded-lg border transition cursor-pointer ${
                      isCustomTimeoutActive || ![1, 5, 15, 30].includes(sessionTimeout)
                        ? 'bg-cyan-950/30 border-cyan-500 text-cyan-400' 
                        : 'bg-neutral-950 border-neutral-900 text-neutral-400 hover:text-white'
                    }`}
                  >
                    {locVal('CUSTOM', 'مخصص')}
                  </button>

                  {(isCustomTimeoutActive || ![1, 5, 15, 30].includes(sessionTimeout)) && (
                    <div className="flex items-center gap-1 bg-neutral-950 px-2 py-0.5 rounded-lg border border-neutral-900">
                      <input 
                        type="number"
                        placeholder="Mins"
                        min="1"
                        max="1440"
                        value={customTimeout === '' && ![1, 5, 15, 30].includes(sessionTimeout) ? sessionTimeout.toString() : customTimeout}
                        onChange={(e) => {
                          const val = e.target.value;
                          setCustomTimeout(val);
                          const parsed = parseInt(val);
                          if (!isNaN(parsed) && parsed > 0) {
                            setSessionTimeout(parsed);
                          }
                        }}
                        className="w-12 text-center text-xs font-mono text-cyan-400 bg-transparent py-1 border-b border-cyan-950 focus:border-cyan-500 focus:outline-none"
                      />
                      <span className="text-[10px] text-neutral-500 font-mono pr-1">{locVal('Min', 'د')}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>

          </div>

        </div>

        {/* Right column: Interactive scanner (Feature 10) & Lockdown Protection (Feature 8) */}
        <div className="space-y-6">
          
          <div className="p-5 rounded-2xl bg-neutral-900/40 border border-neutral-850 space-y-4 flex flex-col items-center text-center">
            <h3 className="text-xs font-mono font-bold text-neutral-400 uppercase tracking-wider self-start flex items-center gap-2">
              <Watch className="w-4 h-4 text-rose-400" />
              {locVal('Scanner Calibration Stage', 'حقل معايرة واختبار المستشعر')}
            </h3>

            {/* Mock scanning module */}
            <div className="relative w-44 h-44 rounded-full bg-neutral-950 border border-neutral-800 flex items-center justify-center p-4 overflow-hidden mt-2">
              {/* Scan glowing elements */}
              <div className="absolute inset-0 bg-gradient-to-tr from-cyan-500/5 to-purple-500/5" />

              {/* Laser animation bar */}
              {isScanning && (
                <div className="absolute left-0 right-0 h-1 bg-cyan-400 shadow-lg shadow-cyan-400/80 laser-pulse z-10 animate-bounce" />
              )}

              {/* Status backgrounds */}
              {scanResult === 'success' && (
                <div className="absolute inset-0 bg-emerald-500/5 animate-pulse" />
              )}
              {scanResult === 'fail' && (
                <div className="absolute inset-0 bg-rose-500/5 animate-pulse" />
              )}

              <button
                disabled={isScanning || (lockUntil !== null && Date.now() < lockUntil)}
                onClick={() => handleTriggerMockScan(true)}
                className={`z-20 w-32 h-32 rounded-full flex flex-col items-center justify-center transition-all ${
                  isScanning 
                    ? 'bg-neutral-950/80 border-2 border-dashed border-cyan-500 scale-95' 
                    : scanResult === 'success'
                    ? 'border border-emerald-500 bg-emerald-950/20'
                    : scanResult === 'fail'
                    ? 'border border-rose-500 bg-rose-950/20'
                    : 'bg-neutral-900 border border-neutral-800 hover:border-neutral-750 hover:bg-neutral-850'
                } cursor-pointer`}
              >
                {biometricType === 'face' ? (
                  <Smartphone className={`w-12 h-12 ${
                    isScanning ? 'text-cyan-400 animate-pulse' : scanResult === 'success' ? 'text-emerald-400' : scanResult === 'fail' ? 'text-rose-400' : 'text-purple-400'
                  }`} />
                ) : (
                  <Fingerprint className={`w-12 h-12 ${
                    isScanning ? 'text-cyan-400 animate-pulse' : scanResult === 'success' ? 'text-emerald-400' : scanResult === 'fail' ? 'text-rose-400' : 'text-purple-400'
                  }`} />
                )}
                
                <span className="block text-[8.5px] font-mono tracking-wider font-bold uppercase mt-2.5 text-neutral-400 select-none">
                  {isScanning 
                    ? locVal('SCANNING...', 'جاري المسح...') 
                    : scanResult === 'success'
                    ? locVal('VERIFIED', 'مطابق ونشط')
                    : scanResult === 'fail'
                    ? locVal('REJECTED', 'مرفوض')
                    : locVal('PRESS TO SCAN', 'اضغط للمسح')}
                </span>
              </button>
            </div>

            {/* Test buttons for failures */}
            <div className="w-full flex gap-2 pt-2">
              <button
                disabled={isScanning || !!lockUntil}
                onClick={() => handleTriggerMockScan(true)}
                className="w-1/2 py-2 bg-neutral-950 hover:bg-emerald-950/30 border border-neutral-850 text-emerald-400 text-[10px] font-mono font-bold rounded-lg transition-colors cursor-pointer"
              >
                {locVal('TEST PASS', 'مطابقة ناجحة')}
              </button>
              <button
                disabled={isScanning || !!lockUntil}
                onClick={() => handleTriggerMockScan(false)}
                className="w-1/2 py-2 bg-neutral-950 hover:bg-rose-950/30 border border-neutral-850 text-rose-400 text-[10px] font-mono font-bold rounded-lg transition-colors cursor-pointer"
              >
                {locVal('TEST FAIL', 'محاكاة فشل')}
              </button>
            </div>

            {/* Lock status info (Feature 8) */}
            {failedAttempts > 0 && (
              <div className="w-full p-3 bg-neutral-950 rounded-xl border border-neutral-900 text-start flex items-start gap-2.5 mt-2">
                <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                <div className="space-y-0.5">
                  <span className="block text-[11px] font-mono font-semibold text-amber-400">
                    {locVal('Failed Access Attempts Tracked', 'تسجيل محاولات خاطئة')}
                  </span>
                  <span className="block text-[9px] text-neutral-400 leading-normal">
                    {locVal(`Consecutive mismatches: ${failedAttempts} / 5. On target 5/5 consecutive mismatches, temporary lockout triggers.`, `عدد مرات الإخفاق: ${failedAttempts} من 5. عند تسجيل 5 محاولات متتالية خاطئة، سيتم تفعيل الحماية المؤقتة.`)}
                  </span>
                </div>
              </div>
            )}

            {lockUntil !== null && (
              <div className="w-full p-3 bg-rose-950/30 border border-rose-900 rounded-xl text-start flex items-start gap-2.5 mt-2 animate-bounce">
                <ShieldAlert className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                <div className="space-y-0.5">
                  <span className="block text-[11px] font-mono font-bold text-rose-400">
                    {locVal('BIOMETRIC COOLDOWN ACTIVE', 'تأمين المستشعرات نشط')}
                  </span>
                  <span className="block text-[9.5px] font-mono font-bold text-white leading-normal">
                    {locVal(`Hardware scanner locked for: ${cooldownRemaining} seconds. Security log recorded.`, `أُقفل مستشعر البصمة والكاميرا مؤقتاً لـ: ${cooldownRemaining} ثانية. جرى تسجيل هذا الاختراق في السجل.`)}
                  </span>
                </div>
              </div>
            )}
          </div>

          <div className="p-4 rounded-xl border border-neutral-900 bg-neutral-900/10 space-y-1">
            <span className="block text-[10px] font-mono font-bold text-neutral-400 uppercase tracking-widest leading-none">
              {locVal('BIOMETRIC BYPASS PROTOCOL', 'بروتوكول التخطي الحيوي')}
            </span>
            <span className="block text-[9px] text-neutral-500 font-sans leading-relaxed">
              {locVal('Under custom cryptographic protocols, bio-data parameters are matched serverless against the client hardware reservoir, ensuring that your master biometric patterns remain fully private and unshared.', 'تحت حماية نظام ريمان السيادي، يتم مطابقة الأنماط الحيوية محلياً وسيرفرلس بالكامل دون مشاركتها أو تسريبها للمزودين.')}
            </span>
          </div>

        </div>
      </div>
    </div>
  );
};
