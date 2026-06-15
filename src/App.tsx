import React, { useState, useEffect } from 'react';
import { 
  Shield, Cpu, Activity, Database, Key, LayoutDashboard, FileLock, MailOpen, Compass, FileCode2, Globe
} from 'lucide-react';
import { SovereignDashboard } from './components/SovereignDashboard';
import { TextEncryptionModule } from './components/TextEncryptionModule';
import { FileEncryptionModule } from './components/FileEncryptionModule';
import { TimeCapsuleModule } from './components/TimeCapsuleModule';
import { KeyGeneratorModule } from './components/KeyGeneratorModule';
import { RiemannSpectrumAnalyzer } from './components/RiemannSpectrumAnalyzer';
import { FlutterExplorer } from './components/FlutterExplorer';
import { RiemannSpectrumCanvas } from './components/RiemannSpectrumCanvas';
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
    setSecurityLogs(prev => [newLog, ...prev].slice(0, 50));
  };

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
            { id: 'text', label: t('tab_text'), icon: <FileLock className="w-4 h-4" /> },
            { id: 'file', label: t('tab_file'), icon: <Key className="w-4 h-4" /> },
            { id: 'capsules', label: t('tab_capsules'), icon: <MailOpen className="w-4 h-4" /> },
            { id: 'keygen', label: t('tab_keygen'), icon: <Compass className="w-4 h-4" /> },
            { id: 'spectrum', label: t('tab_spectrum'), icon: <Activity className="w-4 h-4" /> },
            { id: 'flutter', label: t('tab_flutter'), icon: <FileCode2 className="w-4 h-4" /> }
          ].map((tab) => {
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
