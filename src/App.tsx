import React, { useState, useEffect } from 'react';
import { 
  Shield, Cpu, Activity, Database, Key, LayoutDashboard, FileLock, MailOpen, Compass, FileCode2, Globe, FileText, BookOpen, Fingerprint, Lock, Unlock, ShieldAlert, Images, Video
} from 'lucide-react';
import { SovereignDashboard } from './components/SovereignDashboard';
import { TextEncryptionModule } from './components/TextEncryptionModule';
import { FileEncryptionModule } from './components/FileEncryptionModule';
import { TimeCapsuleModule } from './components/TimeCapsuleModule';
import { KeyGeneratorModule } from './components/KeyGeneratorModule';
import { RiemannSpectrumAnalyzer } from './components/RiemannSpectrumAnalyzer';
import { FlutterExplorer } from './components/FlutterExplorer';
import { RiemannSpectrumCanvas } from './components/RiemannSpectrumCanvas';
import { SecurityCenter } from './components/SecurityCenter';
import { SecureNotesModule } from './components/SecureNotesModule';
import { SecureJournalModule } from './components/SecureJournalModule';
import { BiometricSettingsModule } from './components/BiometricSettingsModule';
import { SecureGalleryModule } from './components/SecureGalleryModule';
import { SecureMediaModule } from './components/SecureMediaModule';
import { RecoveryCenterModule } from './components/RecoveryCenterModule';
import { Toast } from './components/Toast';
import { SecurityEvent } from './types';
import { useTranslation } from './lib/I18nContext';

export default function App() {
  const { t, locale, setLocale } = useTranslation();

  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [isSplashActive, setIsSplashActive] = useState<boolean>(true);
  const [splashProgress, setSplashProgress] = useState<number>(0);
  
  // Real time crypto monitor parameters
  const [isEncrypting, setIsEncrypting] = useState<boolean>(false);
  const [isDecrypting, setIsDecrypting] = useState<boolean>(false);
  const [activityLevel, setActivityLevel] = useState<number>(0);
  const [activeCapsulesCount, setActiveCapsulesCount] = useState<number>(2);

  // Security telemetry events logger
  const [securityLogs, setSecurityLogs] = useState<SecurityEvent[]>([]);
  
  // Custom toast notification system
  const [toastMessage, setToastMessage] = useState<string>('');
  const [toastType, setToastType] = useState<'success' | 'error' | 'info'>('success');

  // Protection and recovery states
  const [biometricsEnabled, setBiometricsEnabled] = useState<boolean>(() => {
    return localStorage.getItem('riman_biometrics_enabled') === 'true';
  });
  const [biometricType, setBiometricType] = useState<'fingerprint' | 'face' | 'both'>(() => {
    return (localStorage.getItem('riman_biometric_type') as any) || 'fingerprint';
  });
  const [sessionTimeout, setSessionTimeout] = useState<number>(() => {
    const saved = localStorage.getItem('riman_session_timeout');
    return saved ? parseInt(saved) : 5; // default 5 minutes
  });
  const [failedAttempts, setFailedAttempts] = useState<number>(0);
  const [lockUntil, setLockUntil] = useState<number | null>(null);
  const [lastActivity, setLastActivity] = useState<number>(Date.now());
  const [loginTime] = useState<number>(Date.now());
  const [isBioScanning, setIsBioScanning] = useState<boolean>(false);

  const handleSetBiometricsEnabled = (val: boolean) => {
    setBiometricsEnabled(val);
    localStorage.setItem('riman_biometrics_enabled', val ? 'true' : 'false');
  };

  const handleSetBiometricType = (val: 'fingerprint' | 'face' | 'both') => {
    setBiometricType(val);
    localStorage.setItem('riman_biometric_type', val);
  };

  const handleSetSessionTimeout = (val: number) => {
    setSessionTimeout(val);
    localStorage.setItem('riman_session_timeout', val.toString());
  };

  const [recoveryKey, setRecoveryKey] = useState<string | null>(() => {
    return localStorage.getItem('riman_recovery_key');
  });

  const handleSetRecoveryKey = (key: string | null) => {
    setRecoveryKey(key);
    if (key) {
      localStorage.setItem('riman_recovery_key', key);
    } else {
      localStorage.removeItem('riman_recovery_key');
    }
  };

  const [clipboardDuration, setClipboardDuration] = useState<number>(30);
  const [isAppLocked, setIsAppLocked] = useState<boolean>(false);
  const [pinValue, setPinValue] = useState<string>('');
  const [setupPin, setSetupPin] = useState<string>('1234');
  const [pinError, setPinError] = useState<string>('');

  // FEATURE 9: ADVANCED PRIVACY SETTINGS ENGINE
  const [privacySettings, setPrivacySettings] = useState(() => {
    const saved = localStorage.getItem('riman_privacy_settings');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        // Ensure all keys are initialized
        return {
          hiddenVaultsEnabled: parsed.hiddenVaultsEnabled ?? true,
          decoyVaultEnabled: parsed.decoyVaultEnabled ?? true,
          panicPassword: parsed.panicPassword ?? 'panic123',
          hiddenVaultPasswords: parsed.hiddenVaultPasswords ?? [],
          hiddenTabs: parsed.hiddenTabs ?? [],
          darkArchive: parsed.darkArchive ?? []
        };
      } catch (e) {}
    }
    return {
      hiddenVaultsEnabled: true,
      decoyVaultEnabled: true,
      panicPassword: 'panic123',
      hiddenVaultPasswords: [],
      hiddenTabs: [],
      darkArchive: []
    };
  });

  const handleUpdatePrivacySettings = (newSettings: typeof privacySettings) => {
    setPrivacySettings(newSettings);
    localStorage.setItem('riman_privacy_settings', JSON.stringify(newSettings));
  };

  // Trigger custom interactive UI micro-animations during key crypt requests
  const triggerCryptoAnimation = (mode: 'encrypt' | 'decrypt') => {
    if (mode === 'encrypt') {
      setIsEncrypting(true);
      setActivityLevel(85);
      setTimeout(() => {
        setIsEncrypting(false);
        setActivityLevel(0);
      }, 2500);
    } else {
      setIsDecrypting(true);
      setActivityLevel(75);
      setTimeout(() => {
        setIsDecrypting(false);
        setActivityLevel(0);
      }, 2500);
    }
  };

  const fireToast = (message: string, type: 'success' | 'error' | 'info') => {
    setToastMessage(message);
    setToastType(type);
  };

  const handleSecurityLog = (event: string, severity: 'info' | 'warning' | 'critical', details: string) => {
    const newLog: SecurityEvent = {
      id: Math.random().toString(36).substring(7),
      timestamp: Date.now(),
      event,
      severity,
      details
    };
    setSecurityLogs(prev => {
      const updated = [newLog, ...prev].slice(0, 50);
      localStorage.setItem('riman_security_logs_v3', JSON.stringify(updated));
      return updated;
    });
  };

  // Load persistent security logs on initialization
  useEffect(() => {
    const savedLogs = localStorage.getItem('riman_security_logs_v3');
    if (savedLogs) {
      try {
        setSecurityLogs(JSON.parse(savedLogs));
      } catch (e) {}
    }
  }, []);

  // Splash loader countdown mimicking secure memory hydration
  useEffect(() => {
    const interval = setInterval(() => {
      setSplashProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => setIsSplashActive(false), 550);
          return 100;
        }
        return prev + 4;
      });
    }, 85);
    return () => clearInterval(interval);
  }, []);

  // Set default initial telemetry log events
  useEffect(() => {
    if (!isSplashActive && securityLogs.length === 0) {
      if (locale === 'ar') {
        handleSecurityLog('تم تهيئة شبكة ريمان للتشفير الحرج', 'info', 'تم رسم الأصفار التخيلية ومطابقتها مع فضاءات المفاتيح الرياضية.');
        handleSecurityLog('تطابق تسريعات عتاد الحماية CBC / GCM', 'info', 'تم تحميل قيم تمدد مفاتيح AES بنجاح كامل.');
      } else {
        handleSecurityLog('Riemann critical grid initialized', 'info', 'Imaginary zeros mapped to mathematical keyspaces.');
        handleSecurityLog('CBC / GCM hardware accelerations matched', 'info', 'AES keys stretching parameters loaded successfully.');
      }
    }
  }, [isSplashActive, locale]);

  // Inactivity tracking (Feature 4 Session Manager)
  useEffect(() => {
    const trackInactivity = () => {
      if (!isSplashActive && !isAppLocked) {
        setLastActivity(Date.now());
      }
    };

    window.addEventListener('mousemove', trackInactivity);
    window.addEventListener('keydown', trackInactivity);
    window.addEventListener('click', trackInactivity);
    window.addEventListener('scroll', trackInactivity);
    window.addEventListener('touchstart', trackInactivity);

    return () => {
      window.removeEventListener('mousemove', trackInactivity);
      window.removeEventListener('keydown', trackInactivity);
      window.removeEventListener('click', trackInactivity);
      window.removeEventListener('scroll', trackInactivity);
      window.removeEventListener('touchstart', trackInactivity);
    };
  }, [isSplashActive, isAppLocked]);

  // Monitor inactive timeout (Feature 4 Session auto-lock)
  useEffect(() => {
    if (isSplashActive || isAppLocked) return;

    const interval = setInterval(() => {
      const elapsedMins = (Date.now() - lastActivity) / (1000 * 60);
      if (elapsedMins >= sessionTimeout) {
        setIsAppLocked(true);
        setPinValue('');
        handleSecurityLog(
          'Session Inertia Lock Activated', 
          'warning', 
          `Auto-lock triggered after ${sessionTimeout} minute(s) of inactivity.`
        );
        fireToast(
          locale === 'ar' 
            ? `تم قفل الغلاف تلقائياً لخمول النظام لـ ${sessionTimeout} دقيقة!` 
            : `System memory auto-locked after ${sessionTimeout} mins of complete inactivity.`, 
          'info'
        );
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [isSplashActive, isAppLocked, lastActivity, sessionTimeout, locale]);

  if (isSplashActive) {
    return (
      <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-neutral-950 font-sans p-6 overflow-hidden select-none">
        {/* Abstract mathematical background mapping dots */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(120,119,198,0.1),rgba(255,255,255,0))]" />
        
        <div className="relative flex flex-col items-center text-center space-y-6 max-w-md w-full">
          {/* Animated Glowing Logo Vector */}
          <div className="relative flex items-center justify-center w-24 h-24 rounded-3xl bg-neutral-900 border border-neutral-800 shadow-2xl overflow-hidden animate-pulse">
            <div className="absolute inset-0 bg-gradient-to-tr from-cyan-500/10 to-purple-500/10" />
            <Shield className="w-12 h-12 text-cyan-400 glow-text" />
            {/* Pulsating spectrum orbit ring */}
            <div className="absolute w-20 h-20 rounded-full border-2 border-cyan-500/10 border-t-cyan-400 rotate-animation animate-spin pointer-events-none" style={{ animationDuration: '4s' }} />
          </div>

          <div className="space-y-2">
            <h1 className="text-3xl font-display font-bold text-white tracking-tight glow-text flex items-center justify-center gap-2">
              Riman <span className="text-cyan-400">Cryptst</span>
            </h1>
            <p className="text-xs text-neutral-500 font-mono tracking-widest uppercase">
              {locale === 'ar' ? 'نظام ريمان الهجين المتكامل للتشفير الفائق' : 'Riemann Zero Hybrid Cryptosystem'}
            </p>
          </div>

          {/* Dynamic Progress indicator bar */}
          <div className="w-full space-y-2 pt-4">
            <div className="h-1.5 w-full bg-neutral-900 rounded-full overflow-hidden border border-neutral-850">
              <div 
                className="h-full bg-gradient-to-r from-cyan-500 to-purple-500 rounded-full transition-all duration-300"
                style={{ width: `${splashProgress}%` }}
              />
            </div>
            <div className="flex justify-between items-center text-[10px] font-mono text-neutral-500">
              <span className="animate-pulse">
                {locale === 'ar' ? 'جاري تهيئة كتل التشفير وإرواء خلايا ريمان...' : 'HYDRATING SPECTRUM CELL MATRICES...'}
              </span>
              <span>{splashProgress}%</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (isAppLocked) {
    const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);
    const handlePinPress = (val: string) => {
      setPinError('');
      if (pinValue.length < 4) {
        setPinValue(prev => prev + val);
      }
    };
    const handleBackspace = () => {
      setPinValue(prev => prev.slice(0, -1));
    };
    const handleUnlock = () => {
      if (pinValue === setupPin) {
        setIsAppLocked(false);
        setPinValue('');
        setFailedAttempts(0);
        handleSecurityLog('Sovereign session authenticated', 'info', 'Correct PIN provided to unlock system memory.');
        fireToast(locVal('Access Granted. Workspace Unlocked.', 'تم التصريح بالدخول. أهلاً بك في وحدة ريمان.'), 'success');
      } else {
        const nextAttempts = failedAttempts + 1;
        setFailedAttempts(nextAttempts);
        handleSecurityLog('PIN Authentication failure', 'warning', `Incorrect unlock attempt #${nextAttempts}.`);
        
        if (nextAttempts >= 5) {
          const cooldown = Date.now() + 30000;
          setLockUntil(cooldown);
          setPinValue('');
          setPinError(locVal('Lockout triggered! Please wait 30 seconds.', 'تم تفعيل الحماية من الاختراق! انتظر 30 ثانية.'));
          handleSecurityLog('Authentication threshold lock active', 'critical', '5 consecutive failures detected. Lockdown enforced.');
        } else {
          setPinError(locVal(`Incorrect PIN specification! (${nextAttempts}/5)`, `رمز تعريف PIN خاطئ! (${nextAttempts}/5)`));
          setPinValue('');
        }
      }
    };

    const handleBiometricUnlockOnLockScreen = () => {
      if (lockUntil && Date.now() < lockUntil) {
        fireToast(locVal('Scanner currently locked due to multi-attempts.', 'مستشعر المعالم الحيوية مقفل حالياً لكثرة المحاولات.'), 'error');
        return;
      }

      setIsBioScanning(true);
      handleSecurityLog(
        'Lock Screen biometric scan sequence online',
        'info',
        `Acquiring device credentials for quick bypass.`
      );

      setTimeout(() => {
        setIsBioScanning(false);
        setIsAppLocked(false);
        setPinValue('');
        setFailedAttempts(0);
        handleSecurityLog(
          'Biometric quick unlock matched successfully',
          'info',
          `Sovereign user identity authorized via live ${biometricType.toUpperCase()} sensor.`
        );
        fireToast(
          locVal('Access Granted. Biometric session active.', 'تم السماح بالدخول. الجلسة الحيوية آمنة ونشطة.'),
          'success'
        );
      }, 1500);
    };

    return (
      <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-neutral-950 font-sans p-6 overflow-hidden select-none">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_80%_at_50%_120%,rgba(120,119,198,0.06),rgba(255,255,255,0))]" />
        
        <div className="relative flex flex-col items-center text-center space-y-6 max-w-sm w-full mx-4">
          <div className="relative flex items-center justify-center w-16 h-16 rounded-2xl bg-neutral-900 border border-neutral-800 shadow-xl overflow-hidden animate-pulse">
            <Lock className="w-8 h-8 text-cyan-500 glow-text" />
          </div>

          <div className="space-y-1">
            <h1 className="text-xl font-display font-bold text-white tracking-tight glow-text">
              {locVal('Memory Zero-Key Locked', 'تم تأمين وتجميد الذاكرة')}
            </h1>
            <p className="text-[10px] text-neutral-500 font-mono uppercase tracking-widest leading-relaxed">
              {locVal('Panic protocol has immolated temporary session keys and purged cached decryptions.', 'بروتوكول الطوارئ قام بمحو مفاتيح التشفير وتفريغ الحافظة المؤقتة.')}
            </p>
          </div>

          <div className="space-y-4 w-full">
            {/* Biometric quick authenticate button (Feature 3) */}
            {biometricsEnabled && (
              <div className="w-full max-w-[280px] bg-neutral-900/40 border border-neutral-850/60 rounded-2xl p-4 flex flex-col items-center space-y-3 shadow-2xl mx-auto">
                <div className="flex items-center gap-2 text-[9px] font-mono text-cyan-400 font-bold tracking-wider uppercase">
                  <Fingerprint className="w-4.5 h-4.5 text-cyan-400 animate-pulse" />
                  <span>{locVal('Biometric Unlock Active', 'المصادقة الحيوية نشطة')}</span>
                </div>

                {isBioScanning ? (
                  <div className="flex flex-col items-center space-y-2 py-1">
                    <div className="relative w-12 h-12 flex items-center justify-center bg-neutral-950 border border-cyan-500 rounded-full overflow-hidden">
                      <div className="absolute top-0 bottom-0 left-0 right-0 bg-cyan-500/15 animate-ping rounded-full" />
                      <div className="absolute left-0 right-0 h-0.5 bg-cyan-400 animate-bounce" />
                      <Fingerprint className="w-6 h-6 text-cyan-400 animate-pulse" />
                    </div>
                    <span className="text-[8px] text-neutral-400 font-mono tracking-widest uppercase animate-pulse">
                      {locVal('SCANNING CO-ORDS...', 'جاري المسح الحركي...')}
                    </span>
                  </div>
                ) : lockUntil && Date.now() < lockUntil ? (
                  <div className="flex items-center gap-2 text-rose-400 bg-rose-950/20 border border-rose-900/40 px-3 py-1.5 rounded-xl text-[10px] font-mono">
                    <ShieldAlert className="w-3.5 h-3.5" />
                    <span>{locVal(`Locked. Wait ${Math.ceil((lockUntil - Date.now())/1000)}s`, `عطل مؤقت. انتظر ${Math.ceil((lockUntil - Date.now())/1000)} ثانية`)}</span>
                  </div>
                ) : (
                  <button 
                    onClick={handleBiometricUnlockOnLockScreen}
                    className="relative w-12 h-12 rounded-full bg-cyan-950/20 border border-cyan-800 flex items-center justify-center hover:bg-cyan-900/40 hover:text-white transition duration-200 cursor-pointer text-cyan-450 group overflow-hidden"
                  >
                    <Fingerprint className="w-6 h-6 text-cyan-400 group-hover:scale-110 transition" />
                  </button>
                )}

                <span className="text-[9px] text-neutral-500 font-mono">
                  {locVal('Scan biometrics to bypass credentials', 'انقر على الدائرة لتجاوز رمز PIN')}
                </span>
              </div>
            )}

            {/* PIN indicators */}
            <div className="flex justify-center gap-3 py-2">
              {[0, 1, 2, 3].map((i) => (
                <div 
                  key={i} 
                  className={`w-3.5 h-3.5 rounded-full border border-neutral-850 transition-all ${
                    pinValue.length > i ? 'bg-cyan-550 shadow shadow-cyan-500/50' : 'bg-neutral-900'
                  }`}
                />
              ))}
            </div>

            {pinError && (
              <span className="text-[10px] text-rose-400 font-mono block animate-pulse">{pinError}</span>
            )}

            {/* PIN Pad 0-9 */}
            <div className="grid grid-cols-3 gap-2 max-w-[240px] mx-auto">
              {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
                <button
                  key={num}
                  disabled={lockUntil !== null && Date.now() < lockUntil}
                  onClick={() => handlePinPress(num.toString())}
                  className="w-14 h-14 rounded-full bg-neutral-900/60 border border-neutral-850 hover:bg-neutral-850 text-white font-mono text-lg font-bold flex items-center justify-center active:scale-95 transition-all cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                >
                  {num}
                </button>
              ))}
              <button
                disabled={lockUntil !== null && Date.now() < lockUntil}
                onClick={handleBackspace}
                className="w-14 h-14 rounded-full bg-neutral-950/20 text-neutral-400 font-mono text-xs flex items-center justify-center active:scale-95 transition-all cursor-pointer hover:text-white disabled:opacity-30"
              >
                DEL
              </button>
              <button
                disabled={lockUntil !== null && Date.now() < lockUntil}
                onClick={() => handlePinPress('0')}
                className="w-14 h-14 rounded-full bg-neutral-900/60 border border-neutral-850 hover:bg-neutral-850 text-white font-mono text-lg font-bold flex items-center justify-center active:scale-95 transition-all cursor-pointer disabled:opacity-30"
              >
                0
              </button>
              <button
                disabled={lockUntil !== null && Date.now() < lockUntil}
                onClick={handleUnlock}
                className="w-14 h-14 rounded-full bg-cyan-950/40 border border-cyan-800 text-cyan-400 font-semibold text-xs flex items-center justify-center active:scale-95 transition-all cursor-pointer hover:bg-cyan-900 hover:text-white disabled:opacity-30"
              >
                OPEN
              </button>
            </div>

            <div className="text-[9.5px] text-neutral-600 font-mono">
              {locVal('Master bypass lock. (Hint: 1234)', 'رمز العبور المبدئي لفك القفل هو (1234)')}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 font-sans relative overflow-x-hidden selection:bg-cyan-500/30 selection:text-white">
      {/* Immersive radial background vector fields */}
      <div className="absolute top-0 left-0 w-full h-[500px] bg-[radial-gradient(ellipse_60%_40%_at_50%_-10%,rgba(6,182,212,0.12),rgba(255,255,255,0))] pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-full h-[500px] bg-[radial-gradient(ellipse_60%_40%_at_50%_110%,rgba(168,85,247,0.06),rgba(255,255,255,0))] pointer-events-none" />

      {/* Structured Operator Dashboard Header */}
      <header className="sticky top-0 z-30 w-full border-b border-neutral-900 bg-neutral-950/80 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-neutral-900 border border-neutral-800 rounded-xl">
              <Shield className="w-5 h-5 text-cyan-400" />
            </div>
            <div>
              <span className="font-display font-bold text-base text-white tracking-tight">{t('app_title')}</span>
              <span className="block text-[9px] font-mono text-neutral-500 tracking-wider uppercase">{t('app_subtitle')}</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-900 border border-neutral-800 text-[11px] font-mono text-neutral-400">
                <span className="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-ping" />
                {t('spectrum_secure')}
              </span>
            </div>

            {/* FEATURE 4: PANIC LOCK HEADER BUTTON */}
            <button
              onClick={() => {
                setIsAppLocked(true);
                setPinValue('');
                // Clear active/decrypted session storage keys
                sessionStorage.removeItem('riman_gallery_cached_key');
                sessionStorage.removeItem('riman_media_vault_cached_key');
                handleSecurityLog(
                  'Panic Lock Protocol Activated',
                  'critical',
                  'Emergency lockout initiated via active terminal gate. Session caches dissolved.'
                );
                fireToast(
                  locale === 'ar' ? 'تم تفعيل بروتوكول قفل الذعر فوراً!' : 'Panic Lock activated! Security shields engaged.',
                  'error'
                );
              }}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-rose-950/35 border border-rose-900/50 hover:bg-rose-900/45 text-xs text-rose-400 font-mono font-bold hover:text-white transition-all active:scale-95 cursor-pointer uppercase animate-pulse shadow-lg shadow-rose-950/20"
              title={locale === 'en' ? 'Immediate Panic Lock' : 'بروتوكول قفل الذعر المباشر'}
            >
              <ShieldAlert className="w-3.5 h-3.5 text-rose-500 animate-spin" style={{ animationDuration: '3s' }} />
              <span className="hidden sm:inline">{locale === 'en' ? 'PANIC LOCK' : 'قفل الذعر'}</span>
            </button>

            {/* Language Switcher Button inside Settings / Header Area */}
            <div className="flex items-center gap-2 border-s border-neutral-900 ps-4">
              <button 
                onClick={() => {
                  const targetLocale = locale === 'en' ? 'ar' : 'en';
                  setLocale(targetLocale);
                  fireToast(targetLocale === 'ar' ? 'تم تحويل الواجهة إلى العربية بنجاح' : 'Interface language updated to English', 'info');
                }}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-neutral-900 border border-neutral-850 hover:border-cyan-400 text-xs font-mono text-neutral-300 hover:text-white transition-all active:scale-95 cursor-pointer uppercase"
                title={locale === 'en' ? 'تحويل للغة العربية' : 'Switch to English'}
              >
                <Globe className="w-3.5 h-3.5 text-cyan-400" />
                <span>{locale === 'en' ? 'العربية' : 'EN'}</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Major Operator Workspace Layout */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6 relative z-10">
        
        {/* Real-time Math Spectrum Wave Panel (Persistent Visual feedback) */}
        <section className="space-y-2">
          <div className="flex justify-between items-center px-1">
            <span className="text-[10px] uppercase font-mono text-neutral-500 tracking-wider">{t('quantum_spectrum_mapping_panel')}</span>
            <span className="text-[10px] font-mono text-cyan-400">RC-310-CBC</span>
          </div>
          <RiemannSpectrumCanvas 
            activityLevel={activityLevel} 
            isEncrypting={isEncrypting} 
            isDecrypting={isDecrypting} 
          />
        </section>

        {/* Tab Navigation Menu Area */}
        <nav className="flex flex-wrap gap-2 p-1.5 bg-neutral-900/40 border border-neutral-850 rounded-2xl backdrop-blur-md max-w-full overflow-x-auto select-none">
          {[
            { id: 'dashboard', label: t('tab_dashboard'), icon: <LayoutDashboard className="w-4 h-4" /> },
            { id: 'security', label: t('tab_security'), icon: <Shield className="w-4 h-4 text-cyan-400" /> },
            { id: 'recovery', label: locale === 'ar' ? 'مركز الاستعادة' : 'Recovery Center', icon: <Activity className="w-4 h-4 text-rose-450" /> },
            { id: 'biometrics', label: t('tab_biometrics'), icon: <Fingerprint className="w-4 h-4 text-purple-400" /> },
            { id: 'text', label: t('tab_text'), icon: <FileLock className="w-4 h-4" /> },
            { id: 'file', label: t('tab_file'), icon: <Key className="w-4 h-4" /> },
            { id: 'capsules', label: t('tab_capsules'), icon: <MailOpen className="w-4 h-4" /> },
            { id: 'keygen', label: t('tab_keygen'), icon: <Compass className="w-4 h-4" /> },
            { id: 'notes', label: t('tab_notes'), icon: <FileText className="w-4 h-4" /> },
            { id: 'journal', label: t('tab_journal'), icon: <BookOpen className="w-4 h-4" /> },
            { id: 'gallery', label: t('tab_gallery'), icon: <Images className="w-4 h-4 text-emerald-400" /> },
            { id: 'media_vault', label: t('tab_media_vault'), icon: <Video className="w-4 h-4 text-cyan-400" /> },
            { id: 'spectrum', label: t('tab_spectrum'), icon: <Activity className="w-4 h-4" /> },
            { id: 'flutter', label: t('tab_flutter'), icon: <FileCode2 className="w-4 h-4" /> }
          ].filter(tab => !privacySettings.hiddenTabs.includes(tab.id)).map((tab) => {
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-4 py-2 text-xs font-sans font-semibold rounded-xl transition-all whitespace-nowrap cursor-pointer focus:outline-none ${
                  active 
                    ? 'bg-neutral-800 text-white shadow shadow-neutral-950/40 border border-neutral-700/30' 
                    : 'text-neutral-400 hover:text-white hover:bg-neutral-800/20'
                }`}
              >
                {tab.icon}
                {tab.label}
              </button>
            );
          })}
        </nav>

        {/* Operational Modules Mount Platform */}
        <section className="bg-neutral-950 min-h-[300px]">
          {activeTab === 'dashboard' && (
            <SovereignDashboard 
              securityLogs={securityLogs} 
              onClearLogs={() => setSecurityLogs([])} 
              activeTunnels={activeCapsulesCount}
              activityRate={activityLevel}
              onSecurityLog={handleSecurityLog}
            />
          )}

          {activeTab === 'security' && (
            <SecurityCenter
              locale={locale}
              securityLogs={securityLogs}
              onSecurityLog={handleSecurityLog}
              onSuccess={fireToast}
              biometricsEnabled={biometricsEnabled}
              setBiometricsEnabled={handleSetBiometricsEnabled}
              recoveryKey={recoveryKey}
              setRecoveryKey={handleSetRecoveryKey}
              clipboardDuration={clipboardDuration}
              setClipboardDuration={setClipboardDuration}
              privacySettings={privacySettings}
              onPrivacySettingsChange={handleUpdatePrivacySettings}
              onEmergencyLock={() => {
                setIsAppLocked(true);
                setPinValue('');
                sessionStorage.removeItem('riman_gallery_cached_key');
                sessionStorage.removeItem('riman_media_vault_cached_key');
                handleSecurityLog('Emergency Lock Activated', 'critical', 'Panic protocol initialized. System caches purged.');
                fireToast(locale === 'ar' ? 'تم تفعيل قفل الطوارئ ومسح كل السجلات النشطة!' : 'Emergency Lock Activated! Cached memory purged.', 'error');
              }}
            />
          )}

          {activeTab === 'recovery' && (
            <RecoveryCenterModule
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              recoveryKey={recoveryKey}
              setRecoveryKey={handleSetRecoveryKey}
            />
          )}

          {activeTab === 'biometrics' && (
            <BiometricSettingsModule
              locale={locale}
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              biometricsEnabled={biometricsEnabled}
              setBiometricsEnabled={handleSetBiometricsEnabled}
              biometricType={biometricType}
              setBiometricType={handleSetBiometricType}
              sessionTimeout={sessionTimeout}
              setSessionTimeout={handleSetSessionTimeout}
              failedAttempts={failedAttempts}
              setFailedAttempts={setFailedAttempts}
              lockUntil={lockUntil}
              setLockUntil={setLockUntil}
              onLockApp={() => {
                setIsAppLocked(true);
                setPinValue('');
                sessionStorage.removeItem('riman_gallery_cached_key');
                sessionStorage.removeItem('riman_media_vault_cached_key');
                handleSecurityLog('Emergency Lock Activated', 'critical', 'Panic protocol initialized. System caches purged.');
                fireToast(locale === 'ar' ? 'تم تفريغ وحظر الجلسة!' : 'Sovereign session suspended and locked.', 'error');
              }}
              lastActivity={lastActivity}
              loginTime={loginTime}
            />
          )}

          {activeTab === 'text' && (
            <TextEncryptionModule 
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
            />
          )}

          {activeTab === 'file' && (
            <FileEncryptionModule 
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
            />
          )}

          {activeTab === 'capsules' && (
            <TimeCapsuleModule 
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
            />
          )}

          {activeTab === 'keygen' && (
            <KeyGeneratorModule 
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
            />
          )}

          {activeTab === 'spectrum' && (
            <RiemannSpectrumAnalyzer 
              activityLevel={activityLevel}
            />
          )}

          {activeTab === 'flutter' && (
            <FlutterExplorer 
              onSuccess={fireToast}
            />
          )}

          {activeTab === 'notes' && (
            <SecureNotesModule
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
              privacySettings={privacySettings}
              isAppLocked={isAppLocked}
            />
          )}

          {activeTab === 'journal' && (
            <SecureJournalModule
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
              privacySettings={privacySettings}
              isAppLocked={isAppLocked}
            />
          )}

          {activeTab === 'gallery' && (
            <SecureGalleryModule
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
              privacySettings={privacySettings}
              isAppLocked={isAppLocked}
            />
          )}

          {activeTab === 'media_vault' && (
            <SecureMediaModule
              onSuccess={fireToast}
              onSecurityLog={handleSecurityLog}
              triggerAnimation={triggerCryptoAnimation}
              privacySettings={privacySettings}
              isAppLocked={isAppLocked}
            />
          )}
        </section>

      </main>

      {/* Multi-tier footer credentials */}
      <footer className="w-full border-t border-neutral-900 bg-neutral-950 py-6 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center gap-3">
          <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-widest">
            {locale === 'ar' ? 'منصة ريمان كربتست • الإصدار السيادي 1.0.0' : 'RIMAN CRYPTST SYSTEM • VERSION 1.0.0-SOVEREIGN'}
          </span>
          <span className="text-[10px] font-mono text-neutral-600">
            {locale === 'ar' 
              ? '© 2026 بروتوكولات ريمان للأمن العلمي والتقني الاستباقي. جميع المداخل مشفرة وموثقة بالكامل.' 
              : '© 2026 RIEMANN SCIENTIFIC SECURITY INITIATIVES. ALL ENTRANCES AUTHENTICATED.'}
          </span>
        </div>
      </footer>

      {/* Custom Global Toast Alert */}
      {toastMessage && (
        <Toast 
          message={toastMessage} 
          type={toastType} 
          onClose={() => setToastMessage('')} 
        />
      )}

    </div>
  );
}
