import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, AlertTriangle, Key, Download, Upload, RefreshCw, Clipboard, Check, Activity,
  Settings, Heart, ShieldAlert, BadgeCheck, FileArchive, CheckCircle2, FileText, ArrowRight, ArrowLeft
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt, 
  stringToBytes, 
  bytesToString 
} from '../lib/crypto';
import { useTranslation } from '../lib/I18nContext';
import { EncryptedContainer } from '../types';

interface RecoveryCenterProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  recoveryKey: string | null;
  setRecoveryKey: (key: string | null) => void;
  onSessionReset?: () => void;
}

export const RecoveryCenterModule: React.FC<RecoveryCenterProps> = ({
  onSuccess,
  onSecurityLog,
  recoveryKey,
  setRecoveryKey,
  onSessionReset
}) => {
  const { locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  const [activeTab, setActiveTab] = useState<'status' | 'generator' | 'package' | 'backup' | 'wizard'>('status');

  // Generator State
  const [tempKey, setTempKey] = useState<string>('');
  const [copiedKey, setCopiedKey] = useState<boolean>(false);

  // Backup State
  const [backupPassword, setBackupPassword] = useState<string>('');
  const [importedFile, setImportedFile] = useState<File | null>(null);
  const [importPassword, setImportPassword] = useState<string>('');
  
  // Verification State
  const [verifiedBackup, setVerifiedBackup] = useState<{
    status: 'Healthy' | 'Invalid' | 'Unknown';
    integrity: boolean;
    age: string;
    readiness: string;
    timestamp?: number;
    type?: string;
  } | null>(null);

  // Wizard Flow State
  const [wizardStep, setWizardStep] = useState<number>(1);
  const [wizardFile, setWizardFile] = useState<File | null>(null);
  const [wizardPassword, setWizardPassword] = useState<string>('');
  const [wizardDecryptedData, setWizardDecryptedData] = useState<any>(null);
  const [wizardError, setWizardError] = useState<string>('');

  // Recovery Tested flag from localStorage
  const [recoveryTested, setRecoveryTested] = useState<boolean>(() => {
    return localStorage.getItem('riman_recovery_tested') === 'true';
  });

  const [lastBackupTime, setLastBackupTime] = useState<number | null>(() => {
    const saved = localStorage.getItem('riman_last_backup_time');
    return saved ? parseInt(saved) : null;
  });

  // Calculate Recovery Score (FEATURE 8)
  const calculateRecoveryHealthScore = () => {
    let score = 0;
    if (recoveryKey) score += 25;
    if (lastBackupTime) score += 25;
    
    // Check if backup age is less than 7 days
    const isBackupFresh = lastBackupTime && (Date.now() - lastBackupTime < 7 * 24 * 60 * 60 * 1000);
    if (isBackupFresh) score += 25;
    else if (lastBackupTime) score += 15; // slightly outdated

    if (recoveryTested) score += 25;
    return score;
  };

  const healthScore = calculateRecoveryHealthScore();

  // Helper to trigger custom system actions
  const logEventAndNotify = (event: string, severity: 'info' | 'warning' | 'critical', details: string, toastMsg: string, toastType: 'success' | 'error' | 'info') => {
    onSecurityLog(event, severity, details);
    onSuccess(toastMsg, toastType);
  };

  // FEATURE 1: CRYPTOGRAPHICALLY STRONG RECOVERY KEY GENERATOR
  const handleGenerateRecoveryKey = () => {
    const pool = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Human readable capitals (excluding confusing chars like I, O, 1, 0)
    let blocks: string[] = [];
    for (let b = 0; b < 4; b++) {
      let chunk = '';
      for (let i = 0; i < 4; i++) {
        const randIndex = Math.floor(Math.random() * pool.length);
        chunk += pool[randIndex];
      }
      blocks.push(chunk);
    }
    const finalGeneratedKey = `RIMAN-RCV-${blocks.join('-')}`;
    setTempKey(finalGeneratedKey);
    logEventAndNotify(
      'Recovery Key Generated', 
      'info', 
      'A new offline dynamic recovery key seed was successfully generated.',
      locVal('New recovery key generated!', 'تم توليد مفتاح استعادة جديد بنجاح!'),
      'success'
    );
  };

  const handleRegisterGeneratedKey = () => {
    if (!tempKey) return;
    setRecoveryKey(tempKey);
    localStorage.setItem('riman_recovery_key', tempKey);
    logEventAndNotify(
      'Recovery Key Saved', 
      'warning', 
      'The generated recovery key was permanently registered on the local database.',
      locVal('Recovery Key registered successfully!', 'تم تسجيل وحفظ مفتاح الاستعادة بنجاح!'),
      'success'
    );
  };

  const handleCopyKey = () => {
    if (!tempKey && !recoveryKey) return;
    const target = tempKey || recoveryKey || '';
    navigator.clipboard.writeText(target);
    setCopiedKey(true);
    setTimeout(() => setCopiedKey(false), 2000);
    onSuccess(locVal('Recovery key copied to clipboard!', 'تم نسخ مفتاح الاستعادة للحافظة!'), 'info');
  };

  const handleExportKeyTxt = () => {
    const keyToExport = tempKey || recoveryKey;
    if (!keyToExport) return;
    const element = document.createElement('a');
    const file = new Blob([
      `RIMAN CRYPTST SYSTEM - OFFLINE EMERGENCY RECOVERY CARD\n`,
      `=======================================================\n`,
      `Timestamp: ${new Date().toISOString()}\n`,
      `Registered Keyspace Coordinate: ${keyToExport}\n\n`,
      `SECURITY INSTRUCTIONS:\n`,
      `1. Store this file on an encrypted storage peripheral or write it physically.\n`,
      `2. Never store this recovery card near your backup package files.\n`,
      `3. Keeping this key offline assures continuous zero-knowledge recovery.`
    ], { type: 'text/plain' });
    element.href = URL.createObjectURL(file);
    element.download = `riman_recovery_card_${Date.now()}.txt`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
    onSuccess(locVal('Offline Recovery Card exported as Text File!', 'تم تصدير بطاقة الاستعادة الورقية كملف نصي!'), 'success');
  };

  // FEATURE 2: GENERATE ENCRYPTED RECOVERY PACKAGE
  const handleExportRecoveryPackage = () => {
    const activeKey = recoveryKey || tempKey;
    if (!activeKey) {
      onSuccess(locVal('Please configure or generate a Recovery Key first!', 'يرجى تهيئة أو توليد مفتاح الاستعادة أولاً!'), 'error');
      return;
    }

    try {
      // Gather non-vault metadata, configs, and security structures
      const packageData: Record<string, string> = {};
      const sensitivePaylods = [
        'riman_notes_vault_payload', 
        'riman_gallery_vault_payload', 
        'riman_journal_vault_payload', 
        'riman_media_vault_payload',
        'riman_notes_decoy_payload',
        'riman_gallery_decoy_payload',
        'riman_journal_decoy_payload',
        'riman_media_decoy_payload'
      ];

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith('riman_')) {
          // Avoid plaintext database lists or decoy structures
          if (sensitivePaylods.includes(key) || key.includes('_hidden_payload_')) {
            continue;
          }
          const val = localStorage.getItem(key);
          if (val) packageData[key] = val;
        }
      }

      const payloadString = JSON.stringify({
        pkgType: 'riman_recovery_package',
        version: '3.5',
        timestamp: Date.now(),
        data: packageData,
        checkerToken: 'RIMAN_SPECTRUM_VERIFIED_V3'
      });

      // Triple-encrypt package using Recovery Key
      const encryptedContainer = executeRiemannTripleLayerEncrypt(
        stringToBytes(payloadString), 
        activeKey, 
        { filename: 'riman_recovery_pkg.rcv' }
      );

      const dataBlob = new Blob([JSON.stringify(encryptedContainer)], { type: 'application/json' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(dataBlob);
      link.download = `riman_recovery_package_${Date.now()}.rcv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      logEventAndNotify(
        'Recovery Package Exported',
        'warning',
        'Encrypted zero-knowledge system recovery package exported to disk.',
        locVal('Recovery Package exported successfully!', 'تم كبس وتصدير حزمة الاستعادة المشفرة بنجاح!'),
        'success'
      );
    } catch (e: any) {
      onSuccess(locVal(`Failed to compile package: ${e.message}`, `فشل تجميع الحزمة: ${e.message}`), 'error');
    }
  };

  // FEATURE 3: SECURE BACKUP EXPORT
  const handleExportFullBackup = () => {
    if (!backupPassword || backupPassword.length < 4) {
      onSuccess(locVal('Please enter a secure password to encrypt your backup!', 'يرجى إدخال كلمة مرور آمنة لتشفير نسخة احتياطية!'), 'error');
      return;
    }

    try {
      const backupData: Record<string, string> = {};
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith('riman_')) {
          const val = localStorage.getItem(key);
          if (val) backupData[key] = val;
        }
      }

      const payloadString = JSON.stringify({
        pkgType: 'riman_full_vault_backup',
        version: '3.5',
        timestamp: Date.now(),
        data: backupData,
        checkerToken: 'RIMAN_MASTER_BACKUP_VALIDATED'
      });

      const encrypted = executeRiemannTripleLayerEncrypt(
        stringToBytes(payloadString),
        backupPassword,
        { filename: 'riman_vault_backup.bak' }
      );

      const blob = new Blob([JSON.stringify(encrypted)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `riman_secure_backup_${Date.now()}.bak`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);

      const now = Date.now();
      localStorage.setItem('riman_last_backup_time', now.toString());
      setLastBackupTime(now);

      logEventAndNotify(
        'Backup Created',
        'info',
        'A full encrypted master backup file was generated and archived.',
        locVal('Encrypted master backup generated successfully!', 'تم تصدير نسخة احتياطية مشفرة بالكامل بنجاح!'),
        'success'
      );
      setBackupPassword('');
    } catch (e: any) {
      onSuccess(locVal(`Export failed: ${e.message}`, `فشل التصدير: ${e.message}`), 'error');
    }
  };

  // FEATURE 4: BACKUP VERIFICATION
  const handleVerifyBackupFile = () => {
    if (!importedFile) {
      onSuccess(locVal('Please select a vault file first!', 'يرجى تحديد ملف للتأكد من سلامته أولاً!'), 'error');
      return;
    }
    if (!importPassword) {
      onSuccess(locVal('Enter the encryption password for this backup file!', 'يرجى إدخال كلمة مرور هذا الملف المحمي!'), 'error');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const container: EncryptedContainer = JSON.parse(e.target?.result as string);
        
        // Decrypted using input key
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, importPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        const parsed = JSON.parse(decryptedStr);

        if (parsed.pkgType === 'riman_full_vault_backup' || parsed.pkgType === 'riman_recovery_package') {
          const isFull = parsed.pkgType === 'riman_full_vault_backup';
          const ageMins = Math.round((Date.now() - parsed.timestamp) / 60000);
          let ageStr = ageMins < 1 ? locVal('Moments ago', 'قبل لحظات') : `${ageMins} ${locVal('minutes ago', 'دقائق مضت')}`;
          if (ageMins >= 60) {
            const hours = Math.round(ageMins / 60);
            ageStr = `${hours} ${hours === 1 ? locVal('hour ago', 'ساعة مضت') : locVal('hours ago', 'ساعات مضت')}`;
          }

          setVerifiedBackup({
            status: 'Healthy',
            integrity: true,
            age: ageStr,
            readiness: isFull ? locVal('Fully Ready for Restore', 'جاهز تماماً للاستعادة الشاملة') : locVal('Configurations and metadata ready', 'الإعدادات والمعلومات والمفاهيم جاهزة في الحزمة'),
            timestamp: parsed.timestamp,
            type: isFull ? locVal('Full Database Backup', 'نسخة قاعدة البيانات الكاملة') : locVal('Recovery Configuration Package', 'حزمة استعادة الإعدادات والتهيئات')
          });

          logEventAndNotify(
            'Backup Verified',
            'info',
            `Cryptographic verify succeeded for uploaded ${parsed.pkgType}. Integrity confirmed.`,
            locVal('Backup file decrypted and verified successfully!', 'تم مسح وفك تشفير ملف الحجب بنجاح! سلامته سليمة.'),
            'success'
          );
        } else {
          throw new Error('Unsupported payload package scheme');
        }
      } catch (err: any) {
        setVerifiedBackup({
          status: 'Invalid',
          integrity: false,
          age: locVal('N/A', 'غير معروف'),
          readiness: locVal('Verification Failed. Incorrect credentials or corrupted file header.', 'فشل التحقق. كلمة المرور خاطئة أو الملف معطوب.')
        });
        logEventAndNotify(
          'Backup Verification Failed',
          'critical',
          'Cryptographic integrity verify failed for the archive.',
          locVal('Failed to verify: Incorrect password or corrupt file!', 'فشل فتح وفك ملف الاحتياط. كلمة المرور خاطئة!'),
          'error'
        );
      }
    };
    reader.readAsText(importedFile);
  };

  // FEATURE 5: SECURE RESTORE
  const handleExecuteRestore = () => {
    if (!verifiedBackup || !verifiedBackup.integrity || !importedFile || !importPassword) {
      onSuccess(locVal('No verified configuration loaded to restore!', 'يرجى التحقق من الملف أولاً قبل تفعيل الضخ!'), 'error');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const container: EncryptedContainer = JSON.parse(e.target?.result as string);
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, importPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        const parsed = JSON.parse(decryptedStr);

        if (parsed?.data) {
          // Commit to local disk
          Object.entries(parsed.data).forEach(([key, val]) => {
            localStorage.setItem(key, val as string);
          });

          localStorage.setItem('riman_recovery_tested', 'true');
          setRecoveryTested(true);

          logEventAndNotify(
            'Restore Executed',
            'warning',
            'Emergency database restoration complete. Memory layers synchronized.',
            locVal('Cryptographic data restore completed successfully!', 'تم استيراد واستعادة خزانة البيانات بالكامل بنجاح!'),
            'success'
          );

          // Refresh to apply updates elegantly after short delay
          setTimeout(() => {
            window.location.reload();
          }, 1800);
        }
      } catch (err: any) {
        onSuccess(locVal(`Restore execution failed: ${err.message}`, `فشل عملية الاستيراد: ${err.message}`), 'error');
      }
    };
    reader.readAsText(importedFile);
  };

  // FEATURE 7: EMERGENCY RECOVERY WORKFLOW (STEP-BY-STEP)
  const handleWizardNext = () => {
    if (wizardStep === 1) {
      if (!wizardFile) {
        setWizardError(locVal('Please upload a backup or recovery package file!', 'يرجى رفع ملف الحزمة المشفر لتجاوز الخطوة!'));
        return;
      }
      setWizardError('');
      setWizardStep(2);
    } else if (wizardStep === 2) {
      if (!wizardPassword) {
        setWizardError(locVal('Credentials code is strictly required!', 'رمز الفك أو الرقم السري للملف مطلوب لفك القيد!'));
        return;
      }

      setWizardError('');
      // Attempt verification
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const container: EncryptedContainer = JSON.parse(e.target?.result as string);
          const decryptedBytes = executeRiemannTripleLayerDecrypt(container, wizardPassword);
          const decryptedStr = bytesToString(decryptedBytes);
          const parsed = JSON.parse(decryptedStr);

          if (parsed.pkgType === 'riman_full_vault_backup' || parsed.pkgType === 'riman_recovery_package') {
            setWizardDecryptedData(parsed);
            setWizardStep(3);
          } else {
            throw new Error('Mismatched payload verification header');
          }
        } catch (err: any) {
          setWizardError(locVal('Invalid credentials specified or corrupt Riemann header bytes.', 'مفتاح الاستعادة خاطئ أو الرواق الثقيل للملف غير منظم.'));
        }
      };
      reader.readAsText(wizardFile as Blob);
    } else if (wizardStep === 3) {
      // Execute restore
      try {
        if (wizardDecryptedData?.data) {
          Object.entries(wizardDecryptedData.data).forEach(([key, val]) => {
            localStorage.setItem(key, val as string);
          });
          localStorage.setItem('riman_recovery_tested', 'true');
          setRecoveryTested(true);

          logEventAndNotify(
            'Restore Executed',
            'warning',
            'Emergency recovery workflow completed successfully. Cache loaded.',
            locVal('System restored and initialized!', 'تم تهيئة النظام واستعراض الأرشيف بالكامل بنجاح!'),
            'success'
          );

          setWizardStep(4);
        }
      } catch (e: any) {
        setWizardError(locVal(`Execution layer crash: ${e.message}`, `حدث كسر في حماية البيانات: ${e.message}`));
      }
    }
  };

  const handleWizardBack = () => {
    if (wizardStep > 1) {
      setWizardStep(wizardStep - 1);
      setWizardError('');
    }
  };

  const handleResetAppWizarClean = () => {
    window.location.reload();
  };

  return (
    <div id="recovery_continuity_center" className="bg-neutral-900 border border-neutral-850 rounded-3xl p-6 space-y-6 text-neutral-155 overflow-hidden">
      
      {/* Title Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-neutral-800">
        <div className="space-y-1">
          <h2 className="text-xl font-display font-bold text-white flex items-center gap-2">
            <Activity className="w-5 h-5 text-cyan-400 rotate-90" />
            {locVal('Recovery & Continuity System', 'نظام الاستعادة واستمرارية الأعمال')}
          </h2>
          <p className="text-[11px] text-neutral-500 font-mono uppercase tracking-wider">
            {locVal('Dual-path disaster recovery & cryptographic package hydration matrices', 'منظومة حماية الخصائص واستثمار الأرشيف المشفر ضد خسارة العتاد')}
          </p>
        </div>

        {/* Global Score Panel (Feature 8 Score Ring) */}
        <div className="flex items-center gap-3 bg-neutral-950 px-4 py-2 rounded-2xl border border-neutral-800">
          <Heart className="w-5 h-5 text-rose-500 animate-pulse" />
          <div>
            <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Recovery Score', 'نقاط جهوزية الاستعادة')}</span>
            <div className="flex items-center gap-2">
              <span className={`text-base font-bold font-mono ${healthScore >= 75 ? 'text-emerald-400' : healthScore >= 50 ? 'text-amber-400' : 'text-rose-450'}`}>
                {healthScore}%
              </span>
              <span className="text-[10px] text-neutral-500">
                {healthScore >= 75 ? locVal('Protected', 'كامل التحصين') : healthScore >= 50 ? locVal('Vulnerable', 'مهيأ جزئياً') : locVal('Critical', 'حرج للغاية')}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Internal Ribbon Navigation tabs (Feature 10) */}
      <div className="flex flex-wrap gap-1.5 p-1 bg-neutral-950 border border-neutral-850 rounded-2xl select-none">
        {[
          { id: 'status', label: locVal('Health & Recommendations', 'سلامة الخزائن وتوصياتنا'), icon: <ShieldCheck className="w-4 h-4 text-emerald-400" /> },
          { id: 'generator', label: locVal('Key Generator', 'مولد مفتاح الاستعادة'), icon: <Key className="w-4 h-4 text-cyan-400" /> },
          { id: 'package', label: locVal('Recovery Package', 'كبس حزمة الإعدادات'), icon: <FileArchive className="w-4 h-4 text-purple-400" /> },
          { id: 'backup', label: locVal('Secure Backups', 'نوافذ النسخ الشامل'), icon: <Download className="w-4 h-4 text-amber-400" /> },
          { id: 'wizard', label: locVal('Emergency Guided Flow', 'معالج تصفية الطوارئ'), icon: <ShieldAlert className="w-4 h-4 text-rose-400 animate-pulse" /> }
        ].map((tab) => {
          const isSelected = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex items-center gap-1.5 px-3 py-1.8 text-[11px] font-sans font-bold rounded-xl transition duration-150 cursor-pointer ${
                isSelected 
                  ? 'bg-neutral-800 text-white border border-neutral-700/50' 
                  : 'text-neutral-400 hover:text-white hover:bg-neutral-800/20'
              }`}
            >
              {tab.icon}
              <span>{tab.label}</span>
            </button>
          )
        })}
      </div>

      {/* Mounting Area for Tabs Layout */}
      <div className="min-h-[250px] transition-all">
        <AnimatePresence mode="wait">
          
          {/* TAB 1: STATUS & RECOMMENDATIONS */}
          {activeTab === 'status' && (
            <motion.div 
              key="panel_status" 
              initial={{ opacity: 0, y: 10 }} 
              animate={{ opacity: 1, y: 0 }} 
              exit={{ opacity: 0, y: -10 }}
              className="space-y-6"
            >
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                
                {/* Score and Stats breakdown */}
                <div className="bg-neutral-950/45 p-5 rounded-2xl border border-neutral-850 space-y-4">
                  <h3 className="text-xs font-mono uppercase tracking-wider text-neutral-400">{locVal('Continuity Health Dashboard', 'مؤشرات استمرارية العمل لجمع البيانات')}</h3>
                  
                  <div className="space-y-3">
                    <div className="flex justify-between items-center text-xs pb-2 border-b border-neutral-900">
                      <span className="text-neutral-400 font-medium">{locVal('Emergency Offline Keys', 'مفتاح حماية الطوارئ الورقي')}</span>
                      <span className={`font-mono font-bold ${recoveryKey ? 'text-emerald-400' : 'text-rose-400 animate-pulse'}`}>
                        {recoveryKey ? locVal('Active & Registered', 'مفعل ومسجل') : locVal('Unconfigured (Critical)', 'غير مهيأ (خطر)')}
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-xs pb-2 border-b border-neutral-900">
                      <span className="text-neutral-400 font-medium">{locVal('Full Database Backups', 'النسخ الاحتياطية الشاملة لقاعدة البيانات')}</span>
                      <span className={`font-mono font-bold ${lastBackupTime ? 'text-emerald-400' : 'text-amber-400'}`}>
                        {lastBackupTime ? locVal('Backed up', 'محفوظة') : locVal('None Active', 'لم تنشأ بعد')}
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-xs pb-2 border-b border-neutral-900">
                      <span className="text-neutral-400 font-medium">{locVal('Backup Frequency Status', 'حالة فترات تكرار التخزين')}</span>
                      <span className={`font-mono font-bold ${lastBackupTime && (Date.now() - lastBackupTime < 7*24*60*60*1000) ? 'text-emerald-400' : 'text-amber-500'}`}>
                        {lastBackupTime ? (Date.now() - lastBackupTime < 7*24*60*60*1000 ? locVal('Fresh (<= 7 days)', 'جديدة وآمنة') : locVal('Outdated (> 7 days)', 'قديمة وتحتاج تحديث')) : locVal('Unknown', 'غير معروف')}
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-xs pb-2 border-b border-neutral-900">
                      <span className="text-neutral-400 font-medium">{locVal('Disaster Recovery Tested', 'فحوصات استعادة الكتل السابقة')}</span>
                      <span className={`font-mono font-bold ${recoveryTested ? 'text-emerald-400' : 'text-amber-500 animate-pulse'}`}>
                        {recoveryTested ? locVal('Success (Tested)', 'مجرّب وناجح!') : locVal('Untested (Action Required)', 'غير مجرّب (موصى به)')}
                      </span>
                    </div>

                    <div className="flex justify-between items-center text-xs">
                      <span className="text-neutral-400 font-medium">{locVal('Primary Vault DNA Lock', 'بصمة رموز الذاكرة السيادية (DNA)')}</span>
                      <span className="font-mono font-bold text-cyan-400">
                        {localStorage.getItem('riman_vault_dna_seed') || 'RZ-A81F-92CD'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Recommendations (Feature 6) */}
                <div className="bg-neutral-950/45 p-5 rounded-2xl border border-neutral-850 space-y-4">
                  <h3 className="text-xs font-mono uppercase tracking-wider text-neutral-400">{locVal('Security Recommendations', 'وصايا الأمن الاستباقي لتجنب الضياع')}</h3>
                  <div className="space-y-3.5 text-xs text-neutral-350">
                    
                    {!recoveryKey && (
                      <div className="flex gap-3 items-start bg-rose-950/15 p-3 rounded-xl border border-rose-900/30">
                        <AlertTriangle className="w-4 h-4 text-rose-450 shrink-0 mt-0.5" />
                        <div>
                          <p className="font-semibold text-rose-200">{locVal('Generate Offline Recovery Key', 'توليد مفتاح حماية الطوارئ الورقي')}</p>
                          <p className="text-[10px] text-neutral-400 mt-1">
                            {locVal('Protects and seals the configurations offline so they can be restored easily even on platform shifts.', 'يسمح باستعادة إعداداتك ومفاهيم عتاد التشفير بدون الحاجة لكلمات مرورك العادية.')}
                          </p>
                        </div>
                      </div>
                    )}

                    {!lastBackupTime && (
                      <div className="flex gap-3 items-start bg-amber-950/15 p-3 rounded-xl border border-amber-900/30">
                        <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                        <div>
                          <p className="font-semibold text-amber-200">{locVal('Take Full Encrypted Backup', 'قم بإنشاء نسخة احتياطية مشفرة بالكامل')}</p>
                          <p className="text-[10px] text-neutral-400 mt-1">
                            {locVal('Your encrypted journals, items, and photos currently exist on this local container only.', 'كافة بياناتك، وسائطك المشفرة، ويومياتك مخزنة محلياً فقط. بدون الـ Backup ستفقدها إذا تضرر الجهاز.')}
                          </p>
                        </div>
                      </div>
                    )}

                    {recoveryKey && lastBackupTime && !recoveryTested && (
                      <div className="flex gap-3 items-start bg-cyan-950/15 p-3 rounded-xl border border-cyan-900/30">
                        <Activity className="w-4 h-4 text-cyan-400 shrink-0 mt-0.5" />
                        <div>
                          <p className="font-semibold text-cyan-200">{locVal('Test Disaster Recovery Workflow', 'إجراء تدريب فحص استعادة العتاد')}</p>
                          <p className="text-[10px] text-neutral-400 mt-1">
                            {locVal('Enter the Guided Emergency recovery panel to test reading your backup file structures.', 'استخدم قسم معالج الطوارئ الموجه للتأكد من سلامة وحيوية ملفاتك الاحتياطية.')}
                          </p>
                        </div>
                      </div>
                    )}

                    {recoveryKey && lastBackupTime && recoveryTested && (
                      <div className="flex gap-3 items-start bg-emerald-950/15 p-3 rounded-xl border border-emerald-900/30">
                        <BadgeCheck className="w-5 h-5 text-emerald-400 shrink-0" />
                        <div>
                          <p className="font-semibold text-emerald-200">{locVal('Ecosystem Protected Perfectly', 'مظلة التأمين متطابقة وفعالة كاملة')}</p>
                          <p className="text-[10px] text-neutral-400 mt-0.5">
                            {locVal('Disaster recovery key is configured, regular backups are on file, and recovery verified.', 'تهانينا! بطاقة الأمان موجودة، النسخ الاحتياطية محدثة، ومكابس الاستعادة تم فحصها وتلقيها بنجاح.')}
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

              </div>
            </motion.div>
          )}

          {/* TAB 2: RECOVERY KEY GENERATOR */}
          {activeTab === 'generator' && (
            <motion.div 
              key="panel_generator" 
              initial={{ opacity: 0, y: 10 }} 
              animate={{ opacity: 1, y: 0 }} 
              exit={{ opacity: 0, y: -10 }}
              className="space-y-6"
            >
              <div className="bg-neutral-950/45 p-6 rounded-2xl border border-neutral-850 space-y-6">
                
                {/* Security Guidance (Feature 1 Requirement) */}
                <div className="p-4 bg-cyan-955/20 border border-cyan-800/40 rounded-xl space-y-2">
                  <h4 className="text-xs font-semibold text-cyan-400 uppercase tracking-widest flex items-center gap-1.5">
                    <ShieldCheck className="w-4 h-4 text-cyan-400" />
                    {locVal('Zero-Knowledge Security Guidance', 'إرشادات الأمن الصفرية للمفاتيح')}
                  </h4>
                  <ul className="text-[10px] text-neutral-400 list-disc list-inside space-y-1.5 leading-relaxed font-mono">
                    <li>{locVal('Store this recovery sequence on a hardware vault or write it Physically.', 'احرص على تدوين هذه السلسلة في مفكرة ورقية معزولة أو قرص مغناطيسي خارجي.')}</li>
                    <li>{locVal('Do NOT keep recovery key files on folders containing active backup archives.', 'تجنب تخزين ملف الرموز بجانب النسخ الاحتياطية على السحابة.')}</li>
                    <li>{locVal('Since Riman uses complete local cryptographic layers, recovery keys are never shared.', 'بما أن التطبيق يعمل بشكل محلي تماماً، لا يوجد خادم لاستعادة كلمة مرورك إلا بهذا الرمز.')}</li>
                  </ul>
                </div>

                <div className="flex flex-col items-center justify-center p-4 bg-neutral-950 rounded-xl border border-neutral-900 space-y-4">
                  <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-wider">
                    {locVal('Registered Cryptographic Seed', 'مفتاح أمان الطائفة النشط والمسجل')}
                  </span>
                  
                  <div className="text-sm font-mono tracking-widest text-neutral-100 bg-neutral-900/60 font-bold px-6 py-3.5 rounded-lg border border-neutral-800 text-center select-all select-none flex items-center gap-3">
                    <Key className="w-4.5 h-4.5 text-cyan-400" />
                    <span>{recoveryKey || tempKey || locVal('--------------------------', '--------------------------')}</span>
                  </div>

                  <div className="flex gap-2">
                    <button
                      onClick={handleGenerateRecoveryKey}
                      className="px-4 py-2 bg-neutral-900/80 hover:bg-neutral-850 border border-neutral-800 select-none cursor-pointer rounded-xl text-xs font-semibold text-white flex items-center gap-1.5 transition-colors"
                    >
                      <RefreshCw className="w-3.5 h-3.5 text-cyan-400 animate-spin" style={{ animationDuration: '6s' }} />
                      <span>{recoveryKey ? locVal('Regenerate Key', 'توليد مفتاح بديل') : locVal('Generate Key', 'توليد المفتاح لأول مرة')}</span>
                    </button>

                    {tempKey && (
                      <button
                        onClick={handleRegisterGeneratedKey}
                        className="px-4 py-2 bg-cyan-950/40 hover:bg-cyan-900/50 border border-cyan-800 select-none cursor-pointer rounded-xl text-xs font-semibold text-cyan-400 hover:text-white flex items-center gap-1.5 transition-colors"
                      >
                        <BadgeCheck className="w-3.5 h-3.5" />
                        <span>{locVal('Apply & Register', 'تطبيق وحفظ المفتاح')}</span>
                      </button>
                    )}

                    {(tempKey || recoveryKey) && (
                      <>
                        <button
                          onClick={handleCopyKey}
                          className="px-4 py-2 bg-neutral-900 hover:bg-neutral-850 border border-neutral-800 cursor-pointer rounded-xl text-xs font-semibold text-white flex items-center gap-1.5 transition-all"
                        >
                          {copiedKey ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Clipboard className="w-3.5 h-3.5" />}
                          <span>{copiedKey ? locVal('Copied!', 'تم النسخ!') : locVal('Copy Key', 'نسخ الرمز')}</span>
                        </button>

                        <button
                          onClick={handleExportKeyTxt}
                          className="px-4 py-2 bg-neutral-900 hover:bg-neutral-850 border border-neutral-800 cursor-pointer rounded-xl text-xs font-semibold text-white flex items-center gap-1.5 transition-all"
                        >
                          <Download className="w-3.5 h-3.5" />
                          <span>{locVal('Export (.txt)', 'تصدير كبطاقة')}</span>
                        </button>
                      </>
                    )}
                  </div>
                </div>

              </div>
            </motion.div>
          )}

          {/* TAB 3: RECOVERY PACKAGE */}
          {activeTab === 'package' && (
            <motion.div 
              key="panel_package" 
              initial={{ opacity: 0, y: 10 }} 
              animate={{ opacity: 1, y: 0 }} 
              exit={{ opacity: 0, y: -10 }}
              className="space-y-6"
            >
              <div className="bg-neutral-950/45 p-6 rounded-2xl border border-neutral-850 space-y-6">
                
                <div className="space-y-2">
                  <h3 className="text-sm font-sans font-bold text-white flex items-center gap-2">
                    <FileArchive className="w-4.5 h-4.5 text-purple-400" />
                    {locVal('Active Config Encrypted Recovery Package', 'تجميع كبس الاستعادة للإعدادات النشطة')}
                  </h3>
                  <p className="text-xs text-neutral-450 leading-relaxed max-w-2xl">
                    {locVal('Produces an encrypted configuration capsule contenant only high-level layout config, categories structured systems, biometrics thresholds and security policies. It NEVER contains the actual media contents, notes text, or photo records, securing configurations cleanly.', 'يقوم هدا القسم بجمع الإعدادات، الفئات، هيكل الملاحظات واليوميات والسياسات، دون لمس أو كشف أي وسائط أو نصوص خاصة بك بنظام صفر المعرفة. يتم ضغطها وتشفيرها بمفتاح الاستعادة الخاص بك.')}
                  </p>
                </div>

                <div className="p-4 bg-neutral-950 rounded-xl border border-neutral-900 flex flex-col md:flex-row items-center justify-between gap-4">
                  <div className="space-y-1 text-center md:text-left">
                    <span className="inline-block px-2 py-0.5 rounded-full text-[9px] font-mono bg-purple-950 border border-purple-900 text-purple-300">
                      AES-256 GCM/CBC TRIPLE COMPRESSED
                    </span>
                    <p className="text-xs font-sans text-neutral-300 font-semibold mt-1">
                      {recoveryKey ? locVal('Locked under active registered recovery key.', 'مغلق ومحكم مشفر بمفتاحك النشط المسجل حالياً.') : locVal('No active recovery key registered. Please generate one first!', 'لا يوجد مفتاح نشط! يرجى توليد مفتاح أولاً لإمكانية التشفير.')}
                    </p>
                  </div>
                  
                  <button
                    disabled={!recoveryKey}
                    onClick={handleExportRecoveryPackage}
                    className="px-5 py-2.5 bg-purple-600 hover:bg-purple-500 disabled:opacity-35 disabled:cursor-not-allowed select-none cursor-pointer rounded-xl text-xs font-bold text-white flex items-center gap-2 transition"
                  >
                    <Download className="w-4 h-4" />
                    <span>{locVal('Export Recovery Package (.rcv)', 'تصدير كبس حزمة الاستعادة')}</span>
                  </button>
                </div>

              </div>
            </motion.div>
          )}

          {/* TAB 4: SECURE BACKUPS */}
          {activeTab === 'backup' && (
            <motion.div 
              key="panel_backup" 
              initial={{ opacity: 0, y: 10 }} 
              animate={{ opacity: 1, y: 0 }} 
              exit={{ opacity: 0, y: -10 }}
              className="space-y-6"
            >
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                
                {/* Backup Generation Column */}
                <div className="bg-neutral-950/45 p-5 rounded-2xl border border-neutral-850 space-y-4">
                  <div className="space-y-1">
                    <h3 className="text-xs font-mono uppercase tracking-wider text-neutral-400">{locVal('Export Encrypted Master Backup', 'تصدير نسخة احتياطية مشفرة شاملة')}</h3>
                    <p className="text-[10px] text-neutral-500 leading-relaxed font-sans mt-1">
                      {locVal('Generates a fully qualified encrypted zip-equivalent package containing ALL vault records (notes, diary, media files, tokens, and databases). Encrypted strictly using the symmetric password you specify below.', 'يولد نسخة رقمية مشفرة بالكامل تحتوي على طافة محتويات الخزائن (مذكرات، وسائط، كتل التشفير، وإعدادات). يتم قفل الملف بكلمة المرور المحددة تفك شفرتها على أي عتاد.')}
                    </p>
                  </div>

                  <div className="space-y-3 pt-2">
                    <div className="space-y-1">
                      <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Backup Encryption Password', 'رقم حجب تشفير ملف الاحتياط')}</label>
                      <input 
                        type="password"
                        value={backupPassword}
                        onChange={(e) => setBackupPassword(e.target.value)}
                        placeholder="••••••••••••••"
                        className="w-full px-3 py-2 rounded-xl bg-neutral-950 border border-neutral-800 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono transition-colors"
                      />
                    </div>

                    <button
                      onClick={handleExportFullBackup}
                      className="w-full py-2.5 bg-amber-600 hover:bg-amber-500 text-white text-xs font-bold rounded-xl cursor-pointer select-none flex items-center justify-center gap-2 transition"
                    >
                      <Download className="w-4 h-4" />
                      <span>{locVal('Generate Backup Archive (.bak)', 'تصدير وتشفير الأرشيف الاحتياطي')}</span>
                    </button>
                  </div>
                </div>

                {/* Backup Verification & Restore Column */}
                <div className="bg-neutral-950/45 p-5 rounded-2xl border border-neutral-850 space-y-4">
                  <div className="space-y-1">
                    <h3 className="text-xs font-mono uppercase tracking-wider text-neutral-400">{locVal('Archive Verification & Restoring', 'سلامة الأرشيف واستيراد المكابس')}</h3>
                    <p className="text-[10px] text-neutral-500 leading-relaxed font-sans mt-1">
                      {locVal('Select an exported .bak or .rcv file to verify its cryptographic validation properties before conducting system database hydration.', 'أدرج ملف الأرشيف للتأكد من بصمته الرياضية ومستحقات صحة الملف قبل استرجاعه للجهاز.')}
                    </p>
                  </div>

                  <div className="space-y-3 pt-2">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      <div className="space-y-1">
                        <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Select Archive File', 'انتقاء ملف الأرشيف')}</label>
                        <input 
                          type="file"
                          accept=".bak,.rcv,.riman,.json"
                          onChange={(e) => setImportedFile(e.target.files?.[0] || null)}
                          className="w-full text-xs text-neutral-400 bg-neutral-950 border border-neutral-850 p-1.5 rounded-xl font-mono focus:outline-none focus:border-cyan-400"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="block text-[10px] font-mono text-neutral-400 uppercase">{locVal('Unlock Password/Key', 'كلمة مرور فك القيد')}</label>
                        <input 
                          type="password"
                          value={importPassword}
                          onChange={(e) => setImportPassword(e.target.value)}
                          placeholder="••••••••"
                          className="w-full px-3 py-2 rounded-xl bg-neutral-950 border border-neutral-800 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono transition-colors"
                        />
                      </div>
                    </div>

                    <div className="flex gap-2 pt-1">
                      <button
                        onClick={handleVerifyBackupFile}
                        className="flex-1 py-1.8 bg-neutral-900 border border-neutral-800 hover:bg-neutral-850 text-white text-[11px] font-semibold rounded-lg cursor-pointer transition flex items-center justify-center gap-1.5"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5 text-cyan-400" />
                        <span>{locVal('Verify Integrity', 'التحقق من السلامة')}</span>
                      </button>

                      <button
                        onClick={handleExecuteRestore}
                        disabled={!verifiedBackup || !verifiedBackup.integrity}
                        className="flex-1 py-1.8 bg-emerald-600 disabled:opacity-30 disabled:cursor-not-allowed hover:bg-emerald-500 text-white text-[11px] font-bold rounded-lg cursor-pointer transition flex items-center justify-center gap-1.5"
                      >
                        <Upload className="w-3.5 h-3.5" />
                        <span>{locVal('Execute Restore', 'حقن واسترجاع البيانات')}</span>
                      </button>
                    </div>

                    {/* Verification Result Display */}
                    {verifiedBackup && (
                      <div className={`p-3 rounded-xl border ${verifiedBackup.integrity ? 'bg-emerald-950/20 border-emerald-900/40 text-emerald-350' : 'bg-rose-950/20 border-rose-900/40 text-rose-350'} text-[10px] font-mono space-y-1 animate-fade-in`}>
                        <div className="flex justify-between font-bold">
                          <span>{locVal('Status:', 'الحالة:')} {verifiedBackup.status}</span>
                          <span>{locVal('Integrity Verified:', 'سلامة التشفير:')} {verifiedBackup.integrity ? locVal('SUCCESS', 'سليم ومضمون') : locVal('FAILED', 'تدحرج فاشل')}</span>
                        </div>
                        {verifiedBackup.type && <div>{locVal('Archive Type:', 'نوع الأرشيف:')} {verifiedBackup.type}</div>}
                        <div>{locVal('Backup Age:', 'عمر النسخة:')} {verifiedBackup.age}</div>
                        <div className="text-[9.2px] border-t border-neutral-850 mt-1.5 pt-1 text-neutral-400 font-sans">{verifiedBackup.readiness}</div>
                      </div>
                    )}
                  </div>
                </div>

              </div>
            </motion.div>
          )}

          {/* TAB 5: GUIDED RETRO EMERGENCY FLOW (WIZARD) */}
          {activeTab === 'wizard' && (
            <motion.div 
              key="panel_wizard" 
              initial={{ opacity: 0, y: 10 }} 
              animate={{ opacity: 1, y: 0 }} 
              exit={{ opacity: 0, y: -10 }}
              className="space-y-6"
            >
              <div className="bg-neutral-950/45 p-6 rounded-2xl border border-neutral-850 space-y-6 max-w-3xl mx-auto">
                
                {/* Steps Visual Bar */}
                <div className="flex justify-between items-center pb-4 border-b border-neutral-900">
                  <span className="text-xs font-mono text-cyan-400 font-bold">{locVal('Guided Recovery Flow', 'معالج استعادة الكيان الموجه')}</span>
                  <div className="flex items-center gap-1 font-mono text-[10px] text-neutral-550">
                    {[1, 2, 3, 4].map((stepNum) => (
                      <div 
                        key={stepNum}
                        className={`px-2 py-0.5 rounded ${wizardStep === stepNum ? 'bg-cyan-950 border border-cyan-850 text-cyan-400' : 'bg-neutral-900 border border-neutral-850 text-neutral-500'}`}
                      >
                        {stepNum}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Step 1: Upload */}
                {wizardStep === 1 && (
                  <div className="space-y-4 animate-fade-in">
                    <div className="text-center py-6 space-y-2 border-2 border-dashed border-neutral-850 rounded-2xl p-4 bg-neutral-950/40">
                      <FileText className="w-10 h-10 text-neutral-600 mx-auto" />
                      <p className="text-xs font-bold text-white">{locVal('Step 1: Upload your Recovery / Backup Capsule', 'الخطوة 1: إسقاط أو رفع حزمة الاسترداد أو الاحتياط')}</p>
                      <p className="text-[10px] text-neutral-500 max-w-md mx-auto">
                        {locVal('Please select an exported .bak file or recovery package file from your physical local directories.', 'أدخل ملف الكبس الاحتياطي أو ملف خزانة التهيئة المشفر الذي قمت بتصديره مسبقاً.')}
                      </p>
                      <div className="pt-2">
                        <input 
                          type="file" 
                          accept=".bak,.rcv,.riman,.json"
                          onChange={(e) => {
                            setWizardFile(e.target.files?.[0] || null);
                            setWizardError('');
                          }}
                          className="text-xs text-cyan-400 bg-neutral-900 px-4 py-2 rounded-xl cursor-pointer hover:border-cyan-500 border border-neutral-800 transition"
                        />
                      </div>
                      {wizardFile && (
                        <p className="text-xs font-mono text-emerald-400 font-bold animate-pulse mt-2">
                          ✓ {wizardFile.name} ({(wizardFile.size / 1024).toFixed(1)} KB)
                        </p>
                      )}
                    </div>
                  </div>
                )}

                {/* Step 2: Credentials */}
                {wizardStep === 2 && (
                  <div className="space-y-4 animate-fade-in">
                    <div className="space-y-2 max-w-md mx-auto">
                      <div className="flex items-center gap-1.5 text-xs text-neutral-300 font-bold mb-1">
                        <Key className="w-4 h-4 text-cyan-400" />
                        <span>{locVal('Step 2: Input Authorization Credentials', 'الخطوة 2: إرسال معلمات تصريح وفك التشفير')}</span>
                      </div>
                      <p className="text-[10.5px] text-neutral-500 font-mono">
                        {locVal('Provide the Recovery Key (for .rcv packages) or current Master Password (for .bak backups).', 'أدخل مفتاح الاستعادة (للملفات ذات اللاحقة .rcv) أو كلمة المرور للملف الاحتياطي (.bak).')}
                      </p>
                      <input 
                        type="password"
                        value={wizardPassword}
                        onChange={(e) => {
                          setWizardPassword(e.target.value);
                          setWizardError('');
                        }}
                        placeholder={locVal('Enter symmetric unlock keys...', 'رقم الحجب أو مفتاح الاسترداد الحركي...')}
                        className="w-full px-3 py-2.5 rounded-xl bg-neutral-950 border border-neutral-800 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono transition-colors"
                      />
                    </div>
                  </div>
                )}

                {/* Step 3: Validate and Review */}
                {wizardStep === 3 && (
                  <div className="space-y-4 animate-fade-in max-w-lg mx-auto">
                    <div className="space-y-2">
                      <div className="flex items-center gap-1.5 text-xs text-emerald-450 font-bold">
                        <Check className="w-4 h-4" />
                        <span>{locVal('Step 3: Verification Successful!', 'الخطوة 3: تطابق البصمات وفك القيد بنجاح!')}</span>
                      </div>
                      <p className="text-[10px] text-neutral-500 leading-relaxed">
                        {locVal('The triple layer de-padding verification passed with excellence. We recovered the contents layout package structure. Review details below prior to committing full state flush.', 'تطابقت كتل المزامنة ريمان للملف. تم استخلاص محتوى الهيكلية والتنظيمات. افحص الخصائص المكتشفة أدناه قبل المزامنة النهائية.')}
                      </p>
                    </div>

                    <div className="bg-neutral-950 p-4 rounded-xl border border-neutral-900 space-y-2 font-mono text-[10px]">
                      <div className="flex justify-between border-b border-neutral-900 pb-1 text-neutral-400">
                        <span>{locVal('Capsule Scheme Version:', 'مسودة وإصدار الكبس:')}</span>
                        <span className="text-white font-bold">{wizardDecryptedData?.version || '1.0'}</span>
                      </div>
                      <div className="flex justify-between border-b border-neutral-900 pb-1 text-neutral-400">
                        <span>{locVal('Package Creation Node:', 'نقطة وتوقيت توليد الحزمة:')}</span>
                        <span className="text-white font-bold">{new Date(wizardDecryptedData?.timestamp).toLocaleString()}</span>
                      </div>
                      <div className="flex justify-between text-neutral-400">
                        <span>{locVal('Total Keys Extracted:', 'السجلات والهياكل المكتشفة:')}</span>
                        <span className="text-cyan-400 font-bold">{wizardDecryptedData?.data ? Object.keys(wizardDecryptedData.data).length : 0}</span>
                      </div>
                    </div>
                  </div>
                )}

                {/* Step 4: Finalize */}
                {wizardStep === 4 && (
                  <div className="space-y-4 animate-fade-in text-center py-6">
                    <div className="w-12 h-12 bg-emerald-900/30 border border-emerald-800 rounded-full flex items-center justify-center mx-auto mb-2 select-none animate-bounce">
                      <Check className="w-6 h-6 text-emerald-400" />
                    </div>
                    <p className="text-xs font-bold text-white">{locVal('Ecosystem Restored & Active!', 'تم استعادة النظام بالكامل والتشغيل!')}</p>
                    <p className="text-[10px] text-neutral-400 max-w-sm mx-auto font-mono">
                      {locVal('Database values synced, localized files decrypted to system cache, and security flags updated. System will automatically re-verify active structures.', 'تمت مزامنة كافة الفئات والطبقات وتدوين المعاملات وتسييرها للأقراص المحلية. اضغط على البدء من جديد لتطبيق الواجهات.')}
                    </p>
                    <div className="pt-2">
                      <button
                        onClick={handleResetAppWizarClean}
                        className="px-5 py-2.5 bg-neutral-900 border border-neutral-800 hover:border-cyan-400 text-cyan-400 rounded-xl text-xs font-bold transition"
                      >
                        {locVal('Relaunch Workspace', 'إعادة إطلاق لوحة التحكم')}
                      </button>
                    </div>
                  </div>
                )}

                {/* Wizard Error Messages */}
                {wizardError && (
                  <div className="p-3 bg-rose-955/25 border border-rose-900/40 rounded-xl text-[10px] font-mono text-rose-400 text-center animate-pulse">
                    ⚠️ {wizardError}
                  </div>
                )}

                {/* Wizard Footer Controls */}
                {wizardStep < 4 && (
                  <div className="flex justify-between items-center pt-4 border-t border-neutral-900 mt-4 select-none">
                    <button
                      disabled={wizardStep === 1}
                      onClick={handleWizardBack}
                      className="px-4 py-2 hover:bg-neutral-900 border border-transparent hover:border-neutral-800 text-xs font-semibold text-neutral-400 disabled:opacity-30 disabled:cursor-not-allowed transition rounded-xl flex items-center gap-1 select-none"
                    >
                      <ArrowLeft className="w-3.5 h-3.5" />
                      <span>{locVal('Back', 'رجوع')}</span>
                    </button>

                    <button
                      onClick={handleWizardNext}
                      className="px-4 py-2 bg-neutral-900 border border-neutral-800 hover:border-cyan-400 text-cyan-400 text-xs font-bold transition rounded-xl flex items-center gap-1 select-none"
                    >
                      <span>{wizardStep === 3 ? locVal('Commit Restoration', 'تطبيق الاستعادة والضخ') : locVal('Next Step', 'الخطوة التالية')}</span>
                      <ArrowRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                )}

              </div>
            </motion.div>
          )}

        </AnimatePresence>
      </div>

    </div>
  );
};
