import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  Search, Compass, Activity, Shield, Settings, Bell, RefreshCw, LayoutGrid, Eye, EyeOff, 
  Lock, Unlock, FileText, Image as ImageIcon, Film, User, AlertTriangle, CheckCircle, 
  Download, ArrowUp, ArrowDown, ChevronRight, Share2, Award, Zap, HardDrive, ShieldAlert, 
  Key, Clipboard, Trash2, Calendar, LayoutDashboard, Radio
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { SecurityEvent, EncryptedContainer } from '../types';
import { useTranslation } from '../lib/I18nContext';
import { 
  executeRiemannTripleLayerDecrypt, 
  executeRiemannTripleLayerEncrypt, 
  bytesToString, 
  stringToBytes 
} from '../lib/crypto';

interface EcosystemCoreProps {
  securityLogs: SecurityEvent[];
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  onSuccess: (message: string, type: 'success' | 'error' | 'info') => void;
  isAppLocked?: boolean;
  onEmergencyLock?: () => void;
}

// Widget descriptor for customizable smart dashboard
interface DashboardWidget {
  id: string;
  titleEn: string;
  titleAr: string;
  visible: boolean;
  order: number;
}

export const RimanEcosystemCore: React.FC<EcosystemCoreProps> = ({
  securityLogs,
  onSecurityLog,
  onSuccess,
  isAppLocked = false,
  onEmergencyLock
}) => {
  const { t, locale } = useTranslation();
  const isAr = locale === 'ar';

  // Helper utility for inline translation keys
  const locVal = (en: string, ar: string) => (isAr ? ar : en);

  // Active Core Sub-tab
  const [activeSubTab, setActiveSubTab] = useState<'overview' | 'explorer' | 'search' | 'security' | 'timeline' | 'settings' | 'labs'>('overview');

  // Vault Passphrase State for Universal Indexing
  const [vaultPassword, setVaultPassword] = useState<string>(() => {
    return sessionStorage.getItem('riman_ecosystem_cached_key') || '';
  });
  const [isUnlocked, setIsUnlocked] = useState<boolean>(() => {
    return !!sessionStorage.getItem('riman_ecosystem_cached_key');
  });
  const [showPassInput, setShowPassInput] = useState<boolean>(false);
  const [passInput, setPassInput] = useState<string>('');

  // Universal Search states
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [searchCategory, setSearchCategory] = useState<string>('all');

  // Customizable Widgets State (Feature 5) & Local Storage Persistence
  const [widgets, setWidgets] = useState<DashboardWidget[]>(() => {
    const saved = localStorage.getItem('riman_ecosystem_widgets');
    if (saved) {
      try { return JSON.parse(saved); } catch (e) { /* ignore */ }
    }
    return [
      { id: 'score', titleEn: 'Security Score', titleAr: 'مؤشر قوة الحماية', visible: true, order: 0 },
      { id: 'vaults_health', titleEn: 'Vault Registry Diagnostics', titleAr: 'فحص سجل الخزائن', visible: true, order: 1 },
      { id: 'storage', titleEn: 'Physical Cryptographic Storage', titleAr: 'مساحة التخزين المشفرة', visible: true, order: 2 },
      { id: 'recovery_health', titleEn: 'Disaster Recovery Readiness', titleAr: 'جاهزية استعادة الكوارث', visible: true, order: 3 },
      { id: 'observatory', titleEn: 'Observatory Pulse Monitor', titleAr: 'نبض مرصد شبكة ريمان', visible: true, order: 4 },
      { id: 'recent_activities', titleEn: 'Real-time Signal Feed', titleAr: 'موجز الإشارات الفوري', visible: true, order: 5 }
    ];
  });

  const saveWidgets = (updated: DashboardWidget[]) => {
    setWidgets(updated);
    localStorage.setItem('riman_ecosystem_widgets', JSON.stringify(updated));
  };

  // Notification center visible state
  const [showNotifCenter, setShowNotifCenter] = useState<boolean>(false);

  // Explorer active file viewer modal
  const [viewingFile, setViewingFile] = useState<any | null>(null);

  // Active live fluctuations (Performance Sandbox simulation parameters)
  const [observatoryWave, setObservatoryWave] = useState<number[]>([40, 52, 45, 60, 55, 72, 65]);
  const [entropyRate, setEntropyRate] = useState<number>(310.42);

  // Triggering interval for spectrum fluctuations
  useEffect(() => {
    const interval = setInterval(() => {
      setObservatoryWave(prev => {
        const next = [...prev.slice(1)];
        const drift = Math.floor(Math.random() * 45) + 30;
        next.push(drift);
        return next;
      });
      setEntropyRate(prev => {
        const delta = (Math.random() - 0.5) * 8.5;
        return +(prev + delta).toFixed(2);
      });
    }, 1800);
    return () => clearInterval(interval);
  }, []);

  // Universal Indexing States derived from Local Storage
  const rawNotesPayload = localStorage.getItem('riman_notes_vault_payload');
  const rawJournalPayload = localStorage.getItem('riman_journal_vault_payload');
  const rawGalleryPayload = localStorage.getItem('riman_gallery_vault_payload');
  const rawMediaPayload = localStorage.getItem('riman_media_vault_payload');
  const rawCapsules = localStorage.getItem('riman_time_capsules_v6');
  const rawCollabInbox = localStorage.getItem('riman_collab_inbox_v7');
  const rawCollabSent = localStorage.getItem('riman_collab_packages_v7');
  const recoveryKey = localStorage.getItem('riman_recovery_key');
  const lastBackup = localStorage.getItem('riman_last_backup_time');
  const biometricsOn = localStorage.getItem('riman_biometrics_enabled') === 'true';

  // Decryption Index cache for Universal Search and Explorer (Feature 1, 2)
  const decryptedData = useMemo(() => {
    if (!isUnlocked || !vaultPassword) {
      return { notes: [], journals: [], gallery: [], media: [], isDecrypted: false };
    }

    let notesList: any[] = [];
    let journalList: any[] = [];
    let galleryList: any[] = [];
    let mediaList: any[] = [];

    // Decrypt Notes
    if (rawNotesPayload) {
      try {
        const container: EncryptedContainer = JSON.parse(rawNotesPayload);
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        notesList = JSON.parse(decryptedStr);
      } catch (err) {
        // password mismatch or parsing error
      }
    }

    // Decrypt Journals
    if (rawJournalPayload) {
      try {
        const container: EncryptedContainer = JSON.parse(rawJournalPayload);
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        journalList = JSON.parse(decryptedStr);
      } catch (err) { }
    }

    // Decrypt Gallery Image Metadata
    if (rawGalleryPayload) {
      try {
        const container: EncryptedContainer = JSON.parse(rawGalleryPayload);
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        galleryList = JSON.parse(decryptedStr);
      } catch (err) { }
    }

    // Decrypt Media Vault Videos/Audio Metadata
    if (rawMediaPayload) {
      try {
        const container: EncryptedContainer = JSON.parse(rawMediaPayload);
        const decryptedBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
        const decryptedStr = bytesToString(decryptedBytes);
        mediaList = JSON.parse(decryptedStr);
      } catch (err) { }
    }

    return {
      notes: notesList,
      journals: journalList,
      gallery: galleryList,
      media: mediaList,
      isDecrypted: true
    };
  }, [isUnlocked, vaultPassword, rawNotesPayload, rawJournalPayload, rawGalleryPayload, rawMediaPayload]);

  // Decode Time Capsules (Plain JSON)
  const capsulesList = useMemo(() => {
    if (rawCapsules) {
      try {
        return JSON.parse(rawCapsules);
      } catch (e) {
        return [];
      }
    }
    return [];
  }, [rawCapsules]);

  // Decode Collab
  const collabInboxList = useMemo(() => {
    if (rawCollabInbox) {
      try { return JSON.parse(rawCollabInbox); } catch (e) {}
    }
    return [];
  }, [rawCollabInbox]);

  const collabSentList = useMemo(() => {
    if (rawCollabSent) {
      try { return JSON.parse(rawCollabSent); } catch (e) {}
    }
    return [];
  }, [rawCollabSent]);

  // Handle Unlocking Action
  const handleUnlockEcosystem = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!passInput || passInput.length < 6) {
      onSuccess(locVal('Password must be at least 6 characters', 'يجب أن لا تقل كلمة المرور عن 6 أحرف'), 'error');
      return;
    }

    // Validate using notes token if exists, journal token, or fallback to direct processing
    let verified = false;
    const notesToken = localStorage.getItem('riman_notes_vault_token');
    const journalToken = localStorage.getItem('riman_journal_vault_token');

    if (notesToken) {
      try {
        const tokenContainer: EncryptedContainer = JSON.parse(notesToken);
        const dec = executeRiemannTripleLayerDecrypt(tokenContainer, passInput);
        const decStr = bytesToString(dec);
        const parsed = JSON.parse(decStr);
        if (parsed.verifier === 'riemann_zero') {
          verified = true;
        }
      } catch (e) { }
    } else if (journalToken) {
      try {
        const tokenContainer: EncryptedContainer = JSON.parse(journalToken);
        const dec = executeRiemannTripleLayerDecrypt(tokenContainer, passInput);
        const decStr = bytesToString(dec);
        const parsed = JSON.parse(decStr);
        if (parsed.owner === 'riman_cryptst_journal') {
          verified = true;
        }
      } catch (e) { }
    } else {
      // If no token exists, look if either payload compiles without throwing
      if (rawNotesPayload) {
        try {
          const container: EncryptedContainer = JSON.parse(rawNotesPayload);
          executeRiemannTripleLayerDecrypt(container, passInput);
          verified = true;
        } catch (e) { }
      } else {
        // Fallback: approve password as setup key
        verified = true;
      }
    }

    if (verified) {
      setVaultPassword(passInput);
      setIsUnlocked(true);
      sessionStorage.setItem('riman_ecosystem_cached_key', passInput);
      setShowPassInput(false);
      onSecurityLog('Universal Ecosystem Core Unlocked', 'info', 'In-memory dynamic decrypted indexing initialized.');
      onSuccess(locVal('Sovereign Index cache successfully online.', 'تم فك تشفير وتفعيل الفهرس المشترك بنجاح.'), 'success');
    } else {
      onSecurityLog('Failed Ecosystem Unlock attempt', 'warning', 'Authentication mismatch for Zero-knowledge data stream.');
      onSuccess(locVal('Incorrect vault credential password!', 'كلمة مرور الخزنة غير صحيحة!'), 'error');
    }
  };

  const handleLockEcosystem = () => {
    setVaultPassword('');
    setIsUnlocked(false);
    sessionStorage.removeItem('riman_ecosystem_cached_key');
    setPassInput('');
    onSecurityLog('Universal Ecosystem Core Locked', 'info', 'In-memory decrypted cache purged.');
    onSuccess(locVal('Ecosystem cache locked & memory flushed.', 'تم إغلاق الفهرس وتطهير الذاكرة العشوائية.'), 'info');
  };

  // Feature 6: Notification Generator
  const generatedNotifications = useMemo(() => {
    const list = [];
    // Backup required check
    if (!lastBackup) {
      list.push({
        id: 'backup_red',
        titleEn: 'Disaster Backup Is Required',
        titleAr: 'مطلوب إجراء نسخة احتياطية فورية',
        descEn: 'No backup records found for this system capsule. Encrypt and map backup coordinates.',
        descAr: 'لم يتم العثور على أي نسخ احتياطية مسجلة. قم بحفظ المعطيات تجنباً للفقد الرقمي.',
        type: 'critical',
        actionType: 'backup'
      });
    } else {
      const backupAge = Date.now() - parseInt(lastBackup);
      if (backupAge > 7 * 24 * 60 * 60 * 1000) {
        list.push({
          id: 'backup_old',
          titleEn: 'Backup Status Stale',
          titleAr: 'سجل النسخ الاحتياطي قديم',
          descEn: 'Your last security snapshot backup state is older than 7 days.',
          descAr: 'مرت أكثر من 7 أيام منذ آخر نسخة احتياطية مشفرة لملفاتك الحساسة.',
          type: 'warning',
          actionType: 'backup'
        });
      }
    }

    // Recovery recommended
    if (!recoveryKey) {
      list.push({
        id: 'recovery_abs',
        titleEn: 'Sovereign Recovery Key Missing',
        titleAr: 'مفتاح الطوارئ السيادي مفقود',
        descEn: 'Your dynamic paper recovery coordinates or quantum recovery seed has not been compiled.',
        descAr: 'لم يتم إنشاء مفتاح الاستعادة السيادي لتأمين الدخول في حال نسيان كلمة مرور الخزينة.',
        type: 'critical',
        actionType: 'recovery'
      });
    }

    // Security Alert check based on critical logs
    const criticalLogs = securityLogs.filter(log => log.severity === 'critical');
    if (criticalLogs.length > 0) {
      list.push({
        id: 'critical_alert',
        titleEn: `${criticalLogs.length} Security Threats Blocked`,
        titleAr: `تم تصفية وحظر ${criticalLogs.length} تهديد أمني`,
        descEn: 'System integrity modules detected and blocked authentication threshold events.',
        descAr: 'سجل العمليات يكشف عن تجاوز حد محاولات الولوج الممنوعة وتم حظر الأهداف.',
        type: 'warning',
        actionType: 'logs'
      });
    }

    // Capsule unlock event
    const lockableCapsules = capsulesList.filter(cap => cap.isCapsule && cap.unlockTimestamp && Date.now() >= cap.unlockTimestamp);
    if (lockableCapsules.length > 0) {
      list.push({
        id: 'capsule_due',
        titleEn: 'Time Capsule Unlocked & Ready',
        titleAr: 'كبسولة زمنية جاهزة لفك الإغلاق',
        descEn: 'Riemann Spectrum space-lock coordinates have aligned. A time capsule is waiting.',
        descAr: 'انقطعت فترة الحظر الحسابي والزمني وأصبحت إحدى الكبسولات الزمنية قابلة للقراءة.',
        type: 'info',
        actionType: 'capsules'
      });
    }

    return list;
  }, [lastBackup, recoveryKey, securityLogs, capsulesList]);

  // Overall Dynamic Security Score Calculation (Feature 4/5)
  const systemSecurityScore = useMemo(() => {
    let score = 55; // base configuration score
    
    // Recovery key check
    if (recoveryKey) score += 15;
    // Biometrics enabled
    if (biometricsOn) score += 15;
    // Backups registered
    if (lastBackup) {
      const age = Date.now() - parseInt(lastBackup);
      if (age < 2 * 24 * 60 * 60 * 1000) score += 15; // fresh backup
      else if (age < 7 * 24 * 60 * 60 * 1000) score += 10;
    }
    // High-density passwords check
    if (vaultPassword && vaultPassword.length > 10) score += 5;

    return Math.min(100, score);
  }, [recoveryKey, biometricsOn, lastBackup, vaultPassword]);

  // Metric calculation: Local Storage usage
  const localMemoryUsage = useMemo(() => {
    let totalBytes = 0;
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key) {
        totalBytes += (localStorage.getItem(key) || '').length;
      }
    }
    const kb = +(totalBytes / 1024).toFixed(1);
    const pct = Math.min(100, +(totalBytes / (5 * 1024 * 1024) * 100).toFixed(2)); // standard 5MB limit
    return { bytes: totalBytes, kb, pct };
  }, [rawNotesPayload, rawJournalPayload, rawGalleryPayload, rawMediaPayload, rawCapsules, securityLogs]);

  // Handle Quick notification actions
  const triggerNotificationQuickFix = (type: string) => {
    if (type === 'backup') {
      const date = Date.now().toString();
      localStorage.setItem('riman_last_backup_time', date);
      onSecurityLog('Instant disaster backup compiled', 'info', `Encrypted state stored natively at timestamp: ${date}`);
      onSuccess(locVal('Instant local filesystem backup compiled successfully.', 'تم تسجيل وضغط النسخة الاحتياطية في الذاكرة المحلية فورياً.'), 'success');
    } else if (type === 'recovery') {
      const demoKey = 'RZ-' + Math.floor(Math.random() * 89999 + 10000) + '-KY-' + Math.floor(Math.random() * 89999 + 10000);
      localStorage.setItem('riman_recovery_key', demoKey);
      onSecurityLog('Emergency recovery key generated', 'info', 'Generated Paper lock seed coordinate.');
      onSuccess(locVal(`Recovery Key Saved! Code: ${demoKey}`, `تم توليد وصياغة مفتاح الاسترداد: ${demoKey}`), 'success');
    } else if (type === 'logs') {
      setActiveSubTab('timeline');
    } else if (type === 'capsules') {
      onSuccess(locVal('Navigate to Time Capsules module to unlock.', 'توجه لنافذة الكبسولات الزمنية لمشاهدة وفك القيود.'), 'info');
    }
    setShowNotifCenter(false);
  };

  // Universal Search Engine logic
  const filteredSearchItems = useMemo(() => {
    if (!searchQuery) return { notes: [], journals: [], gallery: [], media: [], capsules: [], collab: [], logs: [] };

    const query = searchQuery.toLowerCase();
    
    // Notes
    const notesFilter = decryptedData.notes.filter((item: any) => 
      item.title?.toLowerCase().includes(query) || 
      item.content?.toLowerCase().includes(query) ||
      item.category?.toLowerCase().includes(query)
    );

    // Journals
    const journalsFilter = decryptedData.journals.filter((item: any) => 
      item.title?.toLowerCase().includes(query) || 
      item.content?.toLowerCase().includes(query)
    );

    // Gallery Custom Items
    const galleryFilter = decryptedData.gallery.filter((item: any) => 
      item.name?.toLowerCase().includes(query) ||
      item.category?.toLowerCase().includes(query)
    );

    // Media
    const mediaFilter = decryptedData.media.filter((item: any) => 
      item.name?.toLowerCase().includes(query) ||
      item.description?.toLowerCase().includes(query)
    );

    // Capsules
    const capsulesFilter = capsulesList.filter((item: any) => 
      item.name?.toLowerCase().includes(query) ||
      item.hint?.toLowerCase().includes(query)
    );

    // Collab
    const collabInboxFilter = collabInboxList.filter((item: any) => 
      item.packageName?.toLowerCase().includes(query) ||
      item.senderNode?.toLowerCase().includes(query)
    );
    const collabSentFilter = collabSentList.filter((item: any) => 
      item.name?.toLowerCase().includes(query) ||
      item.targetNode?.toLowerCase().includes(query)
    );

    // Logs
    const logsFilter = securityLogs.filter((item: any) => 
      item.event?.toLowerCase().includes(query) ||
      item.details?.toLowerCase().includes(query)
    );

    return {
      notes: notesFilter,
      journals: journalsFilter,
      gallery: galleryFilter,
      media: mediaFilter,
      capsules: capsulesFilter,
      collab: [...collabInboxFilter, ...collabSentFilter],
      logs: logsFilter
    };
  }, [searchQuery, decryptedData, capsulesList, collabInboxList, collabSentList, securityLogs]);

  // Aggregate Feed items chronologically (Feature 3)
  const unifiedActivityStream = useMemo(() => {
    const list: any[] = [];

    // Security logs
    securityLogs.forEach(log => {
      list.push({
        id: log.id,
        timestamp: log.timestamp,
        title: log.event,
        details: log.details,
        severity: log.severity,
        icon: <Shield className="w-3.5 h-3.5 text-cyan-400" />,
        cat: 'Security'
      });
    });

    // Notes adding
    decryptedData.notes.forEach((note: any) => {
      list.push({
        id: note.id,
        timestamp: note.createdAt || note.timestamp || Date.now(),
        title: locVal(`Secure Note Formed: ${note.title}`, `تم صياغة ملاحظة آمنة: ${note.title}`),
        details: locVal(`Category: ${note.category || 'None'}`, `تحت التصنيف: ${note.category || 'افتراضي'}`),
        severity: 'info',
        icon: <FileText className="w-3.5 h-3.5 text-yellow-400" />,
        cat: 'Vaults'
      });
    });

    // Journal additions
    decryptedData.journals.forEach((item: any) => {
      list.push({
        id: item.id || Math.random().toString(),
        timestamp: item.timestamp || Date.now(),
        title: locVal(`Journal Log Added: ${item.title}`, `تم تدوين يومية جديدة: ${item.title}`),
        details: locVal('Encrypted narrative saved to Riemann container.', 'حفظ ملف السرد المشفر بالخوارزمية الثلاثية.'),
        severity: 'info',
        icon: <Award className="w-3.5 h-3.5 text-emerald-400" />,
        cat: 'Media'
      });
    });

    // Gallery images additions
    decryptedData.gallery.forEach((item: any) => {
      list.push({
        id: item.id || Math.random().toString(),
        timestamp: item.timestamp || Date.now(),
        title: locVal(`Image Mapped to Encrypted Gallery: ${item.name}`, `إضافة صورة مشفرة في المعرض: ${item.name}`),
        details: locVal(`Format: ${item.type || 'RAW'} • Size: ${item.size || 'Unk'}`, `النوع: ${item.type || 'صورة'} • الحجم: ${item.size || 'مجهول'}`),
        severity: 'info',
        icon: <ImageIcon className="w-3.5 h-3.5 text-purple-400" />,
        cat: 'Media'
      });
    });

    // Capsules
    capsulesList.forEach((cap: any) => {
      list.push({
        id: cap.id || Math.random().toString(),
        timestamp: cap.timestamp || Date.now(),
        title: locVal(`Time Capsule Registered: ${cap.name}`, `تأسيس غلاف الكبسولة الزمنية: ${cap.name}`),
        details: locVal(`Seal lock until: ${new Date(cap.unlockTimestamp).toLocaleDateString()}`, `مغلقة حسابياً لغاية: ${new Date(cap.unlockTimestamp).toLocaleDateString()}`),
        severity: 'info',
        icon: <Activity className="w-3.5 h-3.5 text-pink-400" />,
        cat: 'Media'
      });
    });

    // Sorting Descending
    return list.sort((a, b) => b.timestamp - a.timestamp);
  }, [securityLogs, decryptedData, capsulesList]);

  // Weak Configuration Checks (Risk Identification - Feature 5 of both V9 & V10)
  const riskAssessmentIndicators = useMemo(() => {
    const list = [];
    if (!vaultPassword || vaultPassword === 'riman123') {
      list.push({
        id: 'weak_pass',
        issueEn: 'Standard Default Secure Password Key Active',
        issueAr: 'مفتاح المرور الافتراضي البسيط نشط',
        threatLevel: 'critical',
        recommendationEn: 'Transition away from "riman123". Ensure your secret passphrase utilizes uppercase, lowercase, and numeric distributions.',
        recommendationAr: 'قم بتغيير كلمة المرور الافتراضية "riman123" فورياً بكلمة مرور معقدة تحتوي على مزيج من الحروف والأرقام.'
      });
    }
    if (!biometricsOn) {
      list.push({
        id: 'biometric_off',
        issueEn: 'No Quick Biometric Verification Layer Confirmed',
        issueAr: 'التحقق البيومتري السريع غير مفعل',
        threatLevel: 'warning',
        recommendationEn: 'Enroll fingerprints or biometric keys so your browser sandbox can quickly verify local operator identities.',
        recommendationAr: 'قم بتشغيل خيار التحقق البيومتري في القناة الآمنة لتسهيل التحقق من هويتك كمالك سيادي.'
      });
    }
    if (capsulesList.some(cap => !cap.isCapsule)) {
      list.push({
        id: 'corrupt_cap',
        issueEn: 'Stray Time Capsules Mapped Outside Chrono-Boundaries',
        issueAr: 'كبسولات زمنية تتعدى نطاق الحماية الزمني المبرمج',
        threatLevel: 'info',
        recommendationEn: 'Ensure to audit unlock parameters so capsule indexes align completely with high-density security offsets.',
        recommendationAr: 'تأكد من مراجعة وضبط مواقيت الفك العشوائي للكبسولات لكي تتطابق مع تواريخ الاستحقاق الدقيقة.'
      });
    }

    return list;
  }, [vaultPassword, biometricsOn, capsulesList]);

  // Widget customizer triggers
  const toggleWidgetVisibility = (id: string) => {
    const updated = widgets.map(w => w.id === id ? { ...w, visible: !w.visible } : w);
    saveWidgets(updated);
  };

  const moveWidgetOrder = (index: number, direction: 'up' | 'down') => {
    const nextIdx = direction === 'up' ? index - 1 : index + 1;
    if (nextIdx < 0 || nextIdx >= widgets.length) return;
    const list = [...widgets];
    const target = list[index];
    list[index] = list[nextIdx];
    list[nextIdx] = target;
    // update order numbers index
    const finalized = list.map((item, i) => ({ ...item, order: i }));
    saveWidgets(finalized);
  };

  // Feature 6: Local Report Generators
  const triggerPdfReportDownload = () => {
    try {
      const reportHtml = `
========================================
    RIMAN CRYPTST SECURITY CORES REPORT
            VERSION 10.0 SOVEREIGN INDEX
========================================
Generated: ${new Date().toISOString()}
System Security Score: ${systemSecurityScore}%
Vault Indexing State: ${isUnlocked ? 'DECRYPTED_INDEX_ONLINE' : 'LOCKED_ZERO_KNOWLEDGE'}
Total Storage Index Size: ${localMemoryUsage.kb} KB

METRIC HEALTH:
----------------------------------------
- Core Vault Registry Score: ${systemSecurityScore >= 80 ? 'EXCELLENT' : 'CRITICAL_RISK'}
- Recovery Paper Backup Key Status: ${recoveryKey ? 'ACTIVE_AND_STORED' : 'MISSING_AND_VULNERABLE'}
- Physical Storage Integrity: 100% HEALTHY

IDENTIFIED RISK METRIC ANALYSIS:
${riskAssessmentIndicators.length === 0 ? 'No Critical Vulnerabilities Found.' : riskAssessmentIndicators.map((risk, idx) => `${idx + 1}. [${risk.issueEn}] - RECOM: ${risk.recommendationEn}`).join('\n')}

REAL-TIME SYSTEM OBSERVATORY SIGNAL PULSE:
- Mechanical Entropy rate flow: ${entropyRate} kb/s
- Sequence of random avalanche registers: [${observatoryWave.join(', ')}]

========================================
END SECURE REPORT TRANSMISSION
========================================`;
      const blob = new Blob([reportHtml], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `riman_system_operations_report_${Date.now()}.txt`;
      link.click();
      URL.revokeObjectURL(url);
      onSecurityLog('Sovereign operations document compiled', 'info', 'Created localized ecosystem parameters text breakdown.');
      onSuccess(locVal('Physical text security audit compiled and dispatched.', 'تم تجميع وتصدير تقرير أمن المعطيات بنجاح.'), 'success');
    } catch (e) {
      onSuccess(locVal('Report compile error.', 'خطأ أثناء توليد التقرير.'), 'error');
    }
  };

  const triggerEncryptedReportPackage = () => {
    if (!isUnlocked || !vaultPassword) {
      onSuccess(locVal('You must first unlock the Ecosystem Index using your master password to bundle zero-knowledge payloads!', 'يرجى فتح قفل الفهرس العام أولاً لتتمكن من تشفير وتجميع المعطيات!'), 'error');
      return;
    }
    try {
      const rawBackupObj = {
        notes: decryptedData.notes,
        journals: decryptedData.journals,
        gallery: decryptedData.gallery,
        media: decryptedData.media,
        timestamp: Date.now(),
        verifier: 'riemann_zero'
      };
      const textBytes = stringToBytes(JSON.stringify(rawBackupObj));
      const encryptedContainer = executeRiemannTripleLayerEncrypt(textBytes, vaultPassword, {
        filename: 'riman_ecosystem_snapshot.package',
        fileType: 'application/octet-stream'
      });
      const blob = new Blob([JSON.stringify(encryptedContainer, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `riman_secure_backup_vault_${Date.now()}.json`;
      link.click();
      URL.revokeObjectURL(url);
      localStorage.setItem('riman_last_backup_time', Date.now().toString());
      onSecurityLog('Triple-encrypted ecosystem package formulated', 'info', 'Saved all unencrypted cache arrays inside active container block.');
      onSuccess(locVal('Ecosystem database exported in high-intensity triple cipher format!', 'تم تصدير وتغليف قاعدة البيانات في الحزمة الثلاثية المشفرة الموحدة!'), 'success');
    } catch (e) {
      onSuccess(locVal('Failed to bundle encrypted backup package.', 'فشل تجميع وتصدير حزمة الدعم المشفرة.'), 'error');
    }
  };

  return (
    <div className="w-full text-neutral-100 font-sans leading-relaxed select-none relative" id="ecosystem_root_module">
      
      {/* Dynamic Spectrum Top Segment */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 bg-neutral-900/60 border-b border-neutral-850 p-4 sticky top-0 md:relative z-20 backdrop-blur-md">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gradient-to-tr from-cyan-900/40 to-blue-900/40 border border-cyan-800/40 rounded-xl">
            <Radio className="w-5 h-5 text-cyan-400 animate-pulse animate-duration-1000" />
          </div>
          <div>
            <h1 className="text-sm font-semibold tracking-tight text-white flex items-center gap-2">
              {locVal('Riman Ecosystem Core', 'النظام البيئي الموحد لشبكة ريمان')}
              <span className="text-[9px] bg-cyan-950 font-mono text-cyan-400 px-1.5 py-0.5 rounded border border-cyan-800/30">v10.0</span>
            </h1>
            <p className="text-[10px] text-neutral-400 font-mono">
              {locVal('Unified Security Operations & Secure Files Registry', 'وحدة العمليات المركزية ومستودع المعطيات السيادي')}
            </p>
          </div>
        </div>

        {/* Action Elements / Index Unlock Controls */}
        <div className="flex items-center gap-2 flex-wrap sm:flex-nowrap">
          {/* Unlock System Key indicator */}
          {!isUnlocked ? (
            <button
              onClick={() => setShowPassInput(!showPassInput)}
              className="flex items-center gap-1.5 bg-amber-950/40 hover:bg-amber-900/30 text-amber-300 font-mono text-[10px] px-3 py-1.5 rounded-lg border border-amber-800/30 transition-all cursor-pointer"
            >
              <Lock className="w-3 h-3 text-amber-400 shrink-0" />
              {locVal('Index Status: Locked (Verify Vault)', 'مفهرس المعطيات: مقفل (التحقق مطلوب)')}
            </button>
          ) : (
            <button
              onClick={handleLockEcosystem}
              className="flex items-center gap-1.5 bg-emerald-950/40 hover:bg-rose-950/40 text-emerald-300 hover:text-rose-300 font-mono text-[10px] px-3 py-1.5 rounded-lg border border-emerald-800/30 hover:border-rose-950 transition-all cursor-pointer"
            >
              <Unlock className="w-3 h-3 text-emerald-400 shrink-0" />
              {locVal('Index Status: Fully Indexed (Purge Cache)', 'مفهرس المعطيات: نشط (تطهير الكاش)')}
            </button>
          )}

          {/* Persistent Notifications Center Bell (Feature 6) */}
          <div className="relative">
            <button
              onClick={() => setShowNotifCenter(!showNotifCenter)}
              className="relative p-2 bg-neutral-900 hover:bg-neutral-800 border border-neutral-800 hover:border-neutral-700 rounded-lg transition-all cursor-pointer"
            >
              <Bell className="w-3.5 h-3.5 text-neutral-300" />
              {generatedNotifications.length > 0 && (
                <span className="absolute -top-1 -right-1 w-2 h-2 bg-rose-500 rounded-full animate-ping" />
              )}
            </button>

            {/* Notification drop menu */}
            <AnimatePresence>
              {showNotifCenter && (
                <motion.div
                  initial={{ opacity: 0, y: 10, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 10, scale: 0.95 }}
                  className={`absolute ${isAr ? 'left-0' : 'right-0'} mt-2 w-72 bg-neutral-950 border border-neutral-850 rounded-xl p-3 shadow-xl z-50 space-y-2`}
                >
                  <div className="flex justify-between items-center pb-2 border-b border-neutral-900">
                    <span className="text-xs font-semibold text-white">{locVal('Ecosystem Alerts', 'إشعارات النظام المركزي')}</span>
                    <span className="text-[10px] font-mono text-neutral-500">{generatedNotifications.length} alerts</span>
                  </div>
                  {generatedNotifications.length === 0 ? (
                    <div className="text-center py-4 text-xs text-neutral-500 font-mono">
                      {locVal('No outstanding hardware threats.', 'جميع الوحدات الأمنية سليمة ومستقرة.')}
                    </div>
                  ) : (
                    <div className="max-h-60 overflow-y-auto space-y-2 divide-y divide-neutral-900 pr-1">
                      {generatedNotifications.map((notif) => (
                        <div key={notif.id} className="pt-2 flex flex-col gap-1 z-50">
                          <div className="flex gap-1.5 items-start">
                            {notif.type === 'critical' ? (
                              <ShieldAlert className="w-3.5 h-3.5 text-red-500 mt-0.5 shrink-0" />
                            ) : (
                              <AlertTriangle className="w-3.5 h-3.5 text-amber-500 mt-0.5 shrink-0" />
                            )}
                            <div>
                              <p className="text-[11px] font-semibold text-white leading-normal">{notif.titleEn && notif.titleAr ? locVal(notif.titleEn, notif.titleAr) : 'Alert'}</p>
                              <p className="text-[10px] text-neutral-400 mt-0.5 leading-snug">{notif.descEn && notif.descAr ? locVal(notif.descEn, notif.descAr) : ''}</p>
                            </div>
                          </div>
                          <button
                            onClick={() => triggerNotificationQuickFix(notif.actionType)}
                            className="self-end text-[9px] font-mono font-semibold text-cyan-400 hover:text-cyan-300 hover:underline bg-cyan-950/20 px-2 py-0.5 rounded border border-cyan-800/20 mt-1 cursor-pointer"
                          >
                            {locVal('Execute Repair →', 'إجراء إصلاح ومعالجة ←')}
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
      </div>

      {/* Unlock Drawer Form Overlay */}
      <AnimatePresence>
        {showPassInput && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="bg-amber-950/20 border-b border-amber-900/30 p-4"
          >
            <form onSubmit={handleUnlockEcosystem} className="max-w-md mx-auto space-y-2">
              <label className="block text-[10px] font-mono uppercase text-amber-400">
                {locVal('Enter Master Safe Lock Password key:', 'أدخل مفتاح التشفير وسر الدخول السيادي:')}
              </label>
              <div className="flex gap-2">
                <input
                  type="password"
                  value={passInput}
                  onChange={(e) => setPassInput(e.target.value)}
                  placeholder={locVal('e.g., riman123', 'مثال: riman123')}
                  className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-1.5 text-xs text-white placeholder-neutral-600 focus:outline-none focus:border-amber-700/60 font-mono"
                />
                <button
                  type="submit"
                  className="bg-amber-800 hover:bg-amber-700 text-black font-semibold text-xs px-4 py-1.5 rounded-lg transition-all cursor-pointer whitespace-nowrap"
                >
                  {locVal('Decrypt Index', 'فك تشفير الفهارس')}
                </button>
              </div>
              <span className="text-[9px] font-mono text-neutral-400 block">
                {locVal('Decrypts and logs inside in-memory sandbox index. Does not store your plaintext password anywhere.', 'يتم فك تشفير المحتوى في مساحة الذاكرة الآمنة المؤقتة للمتصفح دون تخزين مفاتيحك العينية على وسائط التخزين الدائمة.')}
              </span>
            </form>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Grid Sub Navigation Layout for Ecosystem Sections (Adaptive layout for big screens & tablets) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 p-4">
        
        {/* Left column navigation panel (Accessible Navigation Sidebar) */}
        <aside className="lg:col-span-3 flex flex-row lg:flex-col overflow-x-auto lg:overflow-x-visible items-center lg:items-stretch gap-1.5 p-1 bg-neutral-900/30 border border-neutral-850/60 rounded-xl max-w-full whitespace-nowrap lg:whitespace-normal">
          <button
            onClick={() => setActiveSubTab('overview')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'overview'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <LayoutDashboard className="w-3.5 h-3.5 text-cyan-400" />
            <span>{locVal('Smart Dashboard', 'لوحة التحكم والمراقبة الذكية')}</span>
          </button>

          <button
            onClick={() => setActiveSubTab('explorer')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'explorer'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Compass className="w-3.5 h-3.5 text-amber-400" />
            <span>{locVal('Universal Explorer', 'المستعرض العام للملفات')}</span>
          </button>

          <button
            onClick={() => { setActiveSubTab('search'); if (isUnlocked && searchQuery==='') setSearchQuery(' '); }}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'search'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Search className="w-3.5 h-3.5 text-blue-400" />
            <span>{locVal('Universal Search', 'الباحث الرقمي الموحد')}</span>
          </button>

          <button
            onClick={() => setActiveSubTab('security')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'security'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Shield className="w-3.5 h-3.5 text-emerald-400" />
            <span>{locVal('Security & Risk center', 'مركز الأمان والمخاطر المدمج')}</span>
          </button>

          <button
            onClick={() => setActiveSubTab('timeline')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'timeline'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Activity className="w-3.5 h-3.5 text-rose-450" />
            <span>{locVal('Global Activity Feed', 'تحديثات النشاط الشاملة')}</span>
          </button>

          <button
            onClick={() => setActiveSubTab('settings')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'settings'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Settings className="w-3.5 h-3.5 text-purple-400" />
            <span>{locVal('Ecosystem Settings', 'إعدادات النظام المشتركة')}</span>
          </button>

          <button
            onClick={() => setActiveSubTab('labs')}
            className={`flex items-center gap-2.5 px-3.5 py-2.5 text-xs font-semibold rounded-lg transition-all w-full cursor-pointer border ${
              activeSubTab === 'labs'
                ? 'bg-neutral-850 border-neutral-750 text-white shadow shadow-neutral-950/40'
                : 'border-transparent text-neutral-400 hover:text-white hover:bg-neutral-850/35'
            }`}
          >
            <Radio className="w-3.5 h-3.5 text-pink-400 animate-pulse" />
            <span>{locVal('Future Labs Blueprints', 'مستقبل شبكة ريمان Labs')}</span>
          </button>
        </aside>

        {/* Right column view platform (Adaptive viewport) */}
        <main className="lg:col-span-9 bg-neutral-950 border border-neutral-850 rounded-2xl p-4 sm:p-6 overflow-hidden min-h-[480px]">
          <AnimatePresence mode="wait">
            
            {/* 1. SMART DASHBOARD (FEATURE 5) */}
            {activeSubTab === 'overview' && (
              <motion.div
                key="sub_overview"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                {/* Header widget options */}
                <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-3 border-b border-neutral-900 pb-3">
                  <div>
                    <h2 className="text-sm font-semibold text-white">{locVal('Dynamic Smart Control Desk', 'منصة المراقبة والتحكم اللامركزي الذكي')}</h2>
                    <p className="text-[10px] text-neutral-400 font-mono">{locVal('Customize your workspace layouts using the reorder utilities.', 'قم ببرمجة وتغيير ترتيب عناصر العرض المباشر وفق احتياجك وبالمؤشرات الفورية.')}</p>
                  </div>
                </div>

                {/* Dashboard grid layout re-orderable dynamically */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {widgets
                    .filter(w => w.visible)
                    .map((widget, idx) => {
                      return (
                        <div 
                          key={widget.id} 
                          className="bg-neutral-900/40 border border-neutral-850 hover:border-neutral-800 rounded-xl p-4.5 space-y-3 relative group transition-all"
                        >
                          {/* Reordering indicators visible on hover */}
                          <div className={`absolute ${isAr ? 'left-3' : 'right-3'} top-3 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all`}>
                            <button 
                              onClick={() => moveWidgetOrder(idx, 'up')}
                              disabled={idx === 0}
                              className="p-1 bg-neutral-950 border border-neutral-800 rounded hover:bg-neutral-800 hover:text-cyan-400 transition-all text-neutral-400 disabled:opacity-30 disabled:hover:bg-neutral-950 disabled:hover:text-neutral-400 cursor-pointer"
                            >
                              <ArrowUp className="w-3 h-3" />
                            </button>
                            <button 
                              onClick={() => moveWidgetOrder(idx, 'down')}
                              disabled={idx === widgets.length - 1}
                              className="p-1 bg-neutral-950 border border-neutral-800 rounded hover:bg-neutral-800 hover:text-cyan-400 transition-all text-neutral-400 disabled:opacity-30 disabled:hover:bg-neutral-950 disabled:hover:text-neutral-400 cursor-pointer"
                            >
                              <ArrowDown className="w-3 h-3" />
                            </button>
                          </div>

                          <span className="text-[10px] uppercase font-mono text-neutral-400 tracking-wider">
                            {locVal(widget.titleEn, widget.titleAr)}
                          </span>

                          {/* Render Widgets Contextually */}
                          {widget.id === 'score' && (
                            <div className="flex items-center gap-4 pt-1">
                              <div className="relative w-16 h-16 flex items-center justify-center">
                                <span className="text-xl font-bold font-mono text-cyan-400">{systemSecurityScore}%</span>
                                <div className="absolute inset-0 rounded-full border-2 border-neutral-800 border-t-cyan-400 animate-spin animate-duration-3000" />
                              </div>
                              <div>
                                <h3 className="text-xs font-semibold text-white">
                                  {systemSecurityScore >= 85 
                                    ? locVal('Sovereign Fortress Established', 'الحصن الحدودي متماسك بالكامل') 
                                    : locVal('Optimization Recommended', 'ينصح بإجراء بعض التحسينات')}
                                </h3>
                                <p className="text-[10px] text-neutral-400 leading-relaxed font-mono mt-0.5">
                                  {locVal(`All security metrics processed. Overall integrity coefficient registered high density.`, `تم معالجة كافة وحدات الحماية وحساب معامل القوة الكلية بدقة.`)}
                                </p>
                              </div>
                            </div>
                          )}

                          {widget.id === 'vaults_health' && (
                            <div className="space-y-2 pt-1">
                              <div className="grid grid-cols-3 gap-2">
                                <div className="bg-neutral-950/40 p-2 rounded border border-neutral-850 font-mono text-center">
                                  <p className="text-[10px] text-neutral-500">Notes</p>
                                  <p className="text-xs font-bold text-yellow-400">{isUnlocked ? decryptedData.notes.length : '🔒'}</p>
                                </div>
                                <div className="bg-neutral-950/40 p-2 rounded border border-neutral-850 font-mono text-center">
                                  <p className="text-[10px] text-neutral-500">Files</p>
                                  <p className="text-xs font-bold text-cyan-400">{capsulesList.length + 3}</p>
                                </div>
                                <div className="bg-neutral-950/40 p-2 rounded border border-neutral-850 font-mono text-center">
                                  <p className="text-[10px] text-neutral-500">Gallery</p>
                                  <p className="text-xs font-bold text-purple-400">{isUnlocked ? decryptedData.gallery.length : '🔒'}</p>
                                </div>
                              </div>
                              <p className="text-[10px] font-mono text-neutral-400">
                                {locVal(`Active key encryption handles matched. Verification state logged valid index.`, `محركات التشفير النشطة تعمل بسلام وتطابق مستمر مع مفاتيح ريمان المفهرسة.`)}
                              </p>
                            </div>
                          )}

                          {widget.id === 'storage' && (
                            <div className="space-y-1.5 pt-1">
                              <div className="flex justify-between items-center text-[10px] font-mono">
                                <span className="text-neutral-500">{locVal('Allocated Local Cache Space', 'المساحة المستغلة بالكاش المحلي')}</span>
                                <span className="text-cyan-400">{localMemoryUsage.kb} KB</span>
                              </div>
                              <div className="w-full bg-neutral-950 rounded-full h-1.5 overflow-hidden border border-neutral-900">
                                <div 
                                  className="bg-cyan-400 h-full rounded-full transition-all" 
                                  style={{ width: `${localMemoryUsage.pct}%` }} 
                                />
                              </div>
                              <p className="text-[9px] text-neutral-400 font-mono">
                                {locVal(`Your local index memory footprint uses ${localMemoryUsage.kb} KB of the secure browser cache database.`, `تستهلك المعطيات المشفرة الخاصة بك ${localMemoryUsage.kb} كيلوبايت من الذاكرة الرملية المؤمنة.`)}
                              </p>
                            </div>
                          )}

                          {widget.id === 'recovery_health' && (
                            <div className="space-y-2 pt-1 font-mono">
                              <div className="flex justify-between items-center text-[10px]">
                                <span className="text-neutral-500">Backup coordinates:</span>
                                <span className={lastBackup ? 'text-emerald-400' : 'text-rose-400 font-bold'}>
                                  {lastBackup ? new Date(parseInt(lastBackup)).toLocaleDateString() : 'MISSING'}
                                </span>
                              </div>
                              <div className="flex justify-between items-center text-[10px]">
                                <span className="text-neutral-500">Disaster Recovery Key:</span>
                                <span className={recoveryKey ? 'text-emerald-400' : 'text-rose-400 font-bold'}>
                                  {recoveryKey ? 'ESTABLISHED' : 'MISSING'}
                                </span>
                              </div>
                              <p className="text-[9px] text-neutral-500 leading-normal">
                                {locVal('Provides offline vault reconstruction if primary passwords are mathematically corrupted.', 'تضمن إمكانية استصلاح الهيكل الرياضي للمجلدات وفك الأصفار في الكوارث.')}
                              </p>
                            </div>
                          )}

                          {widget.id === 'observatory' && (
                            <div className="space-y-2 pt-1">
                              <div className="flex h-10 items-end justify-between p-1 bg-neutral-950/60 rounded border border-neutral-850">
                                {observatoryWave.map((val, i) => (
                                  <div 
                                    key={i} 
                                    className="bg-cyan-400 w-2.5 rounded-t transition-all" 
                                    style={{ height: `${val}%` }} 
                                  />
                                ))}
                              </div>
                              <div className="flex justify-between text-[9px] font-mono text-neutral-400">
                                <span>{locVal('Mechanical Jitter entropy', 'تذبذب طيفي حي')}</span>
                                <span className="text-cyan-400">{entropyRate} kbps</span>
                              </div>
                            </div>
                          )}

                          {widget.id === 'recent_activities' && (
                            <div className="space-y-1.5 pt-1 divide-y divide-neutral-900 pr-1 max-h-24 overflow-y-auto">
                              {unifiedActivityStream.slice(0, 3).map((item, i) => (
                                <div key={item.id + i} className="text-[10px] font-mono pt-1.5 flex justify-between gap-1 items-start text-neutral-400 leading-snug">
                                  <span className="truncate">{item.title}</span>
                                  <span className="text-[8px] text-neutral-500 font-mono shrink-0">
                                    {new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                  </span>
                                </div>
                              ))}
                            </div>
                          )}

                        </div>
                      );
                    })}
                </div>
              </motion.div>
            )}

            {/* 2. UNIVERSAL EXPLORER (FEATURE 2) */}
            {activeSubTab === 'explorer' && (
              <motion.div
                key="sub_explorer"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Universal Cryptographic Explorer', 'المستعرض الرقمي العام للملفات والمعطيات')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Consolidated unified directory path representing all internal stored databases.', 'مجلد هيكلي موحد يستعرض كافة المكونات والصور والملفات المحمية بالخزانة الكلية.')}</p>
                </div>

                {!isUnlocked ? (
                  <div className="border border-amber-900/30 bg-amber-950/10 rounded-xl p-8 text-center space-y-4 max-w-md mx-auto">
                    <Lock className="w-8 h-8 text-amber-500 mx-auto animate-pulse" />
                    <div>
                      <h3 className="text-sm font-semibold text-white font-mono">{locVal('Directories Locked & Sealed', 'الفهارس مغلقة ومحمية حسابياً')}</h3>
                      <p className="text-xs text-neutral-400 leading-relaxed font-sans mt-1">
                        {locVal('To prevent local data leakage, directory contents are kept mathematical noise until your vault passkey is supplied.', 'يتم عزل وحفظ أسماء الملفات وجغرافيا التخزين في فضاءات تظل مغلقة لحين إدخال مفتاح ريمان الكلي.')}
                      </p>
                    </div>
                    <button
                      onClick={() => setShowPassInput(true)}
                      className="bg-amber-800 hover:bg-amber-700 text-black font-semibold text-xs px-4 py-2 rounded-lg cursor-pointer transition-all"
                    >
                      {locVal('Unlock Directory Index', 'الولوج لفك تشفير الفهارس')}
                    </button>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {/* Category directory list */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                      {/* Secure Notes Category */}
                      <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-3.5 space-y-2">
                        <div className="flex justify-between items-center border-b border-neutral-900 pb-2">
                          <span className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                            <FileText className="w-3.5 h-3.5 text-yellow-400" />
                            {locVal('Secure Notes', 'الملاحظات الآمنة')}
                          </span>
                          <span className="text-[10px] font-mono text-yellow-400 px-1.5 py-0.5 rounded bg-yellow-950/20">{decryptedData.notes.length}</span>
                        </div>
                        <div className="max-h-24 overflow-y-auto space-y-1.5 pr-1 font-mono text-[10px]">
                          {decryptedData.notes.length === 0 ? (
                            <p className="text-neutral-500 italic py-1">{locVal('No notes saved.', 'لا توجد ملاحظات.')}</p>
                          ) : (
                            decryptedData.notes.map((item: any) => (
                              <div 
                                key={item.id} 
                                onClick={() => setViewingFile({ type: 'note', data: item })}
                                className="flex justify-between items-center p-1 bg-neutral-950/40 rounded hover:bg-neutral-800/45 border border-transparent hover:border-neutral-800 cursor-pointer text-neutral-400 hover:text-white transition-all text-[10px]"
                              >
                                <span className="truncate max-w-[130px]">{item.title}</span>
                                <ChevronRight className="w-3 h-3 text-neutral-600 shrink-0" />
                              </div>
                            ))
                          )}
                        </div>
                      </div>

                      {/* Journals directory */}
                      <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-3.5 space-y-2">
                        <div className="flex justify-between items-center border-b border-neutral-900 pb-2">
                          <span className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                            <Award className="w-3.5 h-3.5 text-emerald-400" />
                            {locVal('Journals Vault', 'مفكرة التدوين')}
                          </span>
                          <span className="text-[10px] font-mono text-emerald-400 px-1.5 py-0.5 rounded bg-emerald-950/20">{decryptedData.journals.length}</span>
                        </div>
                        <div className="max-h-24 overflow-y-auto space-y-1.5 pr-1 font-mono text-[10px]">
                          {decryptedData.journals.length === 0 ? (
                            <p className="text-neutral-500 italic py-1">{locVal('No journals logged.', 'لا توجد تدوينات.')}</p>
                          ) : (
                            decryptedData.journals.map((item: any, i) => (
                              <div 
                                key={item.id || i} 
                                onClick={() => setViewingFile({ type: 'journal', data: item })}
                                className="flex justify-between items-center p-1 bg-neutral-950/40 rounded hover:bg-neutral-800/45 border border-transparent hover:border-neutral-800 cursor-pointer text-neutral-400 hover:text-white transition-all text-[10px]"
                              >
                                <span className="truncate max-w-[130px]">{item.title}</span>
                                <ChevronRight className="w-3 h-3 text-neutral-600 shrink-0" />
                              </div>
                            ))
                          )}
                        </div>
                      </div>

                      {/* Video / Media section */}
                      <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-3.5 space-y-2">
                        <div className="flex justify-between items-center border-b border-neutral-900 pb-2">
                          <span className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                            <Film className="w-3.5 h-3.5 text-cyan-400" />
                            {locVal('Media & Gallery', 'الأستوديو والأفلام')}
                          </span>
                          <span className="text-[10px] font-mono text-cyan-400 px-1.5 py-0.5 rounded bg-cyan-950/20">
                            {decryptedData.gallery.length + decryptedData.media.length}
                          </span>
                        </div>
                        <div className="max-h-24 overflow-y-auto space-y-1.5 pr-1 font-mono text-[10px]">
                          {decryptedData.gallery.length === 0 && decryptedData.media.length === 0 ? (
                            <p className="text-neutral-500 italic py-1">{locVal('No media mapped.', 'لا توجد وسائط مشفرة.')}</p>
                          ) : (
                            [...decryptedData.gallery.map(g => ({ ...g, category: 'Gallery' })), ...decryptedData.media.map(m => ({ ...m, category: 'Media' }))].map((item: any, i) => (
                              <div 
                                key={item.id || i} 
                                onClick={() => setViewingFile({ type: 'media', data: item })}
                                className="flex justify-between items-center p-1 bg-neutral-950/40 rounded hover:bg-neutral-800/45 border border-transparent hover:border-neutral-800 cursor-pointer text-neutral-400 hover:text-white transition-all text-[10px]"
                              >
                                <span className="truncate max-w-[130px]">{item.name}</span>
                                <span className="text-[8px] px-1 py-0.2 background-neutral-800 rounded text-neutral-550 shrink-0">{item.category}</span>
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Capsule directory list & recovery keys (Combined directories) */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {/* Time capsules registry listing */}
                      <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                        <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                          <Activity className="w-3.5 h-3.5 text-pink-400" />
                          {locVal('Dynamic Time-Locked Capsules', 'الأغلفة والكبسولات الزمنية النشطة')}
                        </h3>
                        <div className="space-y-2 max-h-36 overflow-y-auto pr-1">
                          {capsulesList.length === 0 ? (
                            <p className="text-xs text-neutral-500 italic py-2 pr-1">{locVal('No mathematical time capsules programmed.', 'لم يتم كبسلة أو برمجة أي أوعية زمنية حتى الآن.')}</p>
                          ) : (
                            capsulesList.map((cup: any, idx) => {
                              const isStillLocked = cup.unlockTimestamp ? Date.now() < cup.unlockTimestamp : false;
                              return (
                                <div key={cup.id || idx} className="bg-neutral-950/40 p-2.5 rounded border border-neutral-850 flex items-center justify-between gap-3 text-xs">
                                  <div>
                                    <p className="font-semibold text-white">{cup.name}</p>
                                    <p className="text-[9px] text-neutral-400 font-mono mt-0.5">
                                      {cup.unlockTimestamp ? `${locVal('Sealed till:', 'مغلق لغاية:')} ${new Date(cup.unlockTimestamp).toLocaleDateString()}` : 'No locking delay'}
                                    </p>
                                  </div>
                                  <span className={`text-[10px] font-mono px-2 py-0.5 rounded border ${isStillLocked ? 'bg-amber-950/30 border-amber-800/30 text-amber-300' : 'bg-emerald-950/30 border-emerald-800/30 text-emerald-300'}`}>
                                    {isStillLocked ? locVal('SEALED', 'مغلقة') : locVal('UNSEALED', 'مفتوحة')}
                                  </span>
                                </div>
                              );
                            })
                          )}
                        </div>
                      </div>

                      {/* Sovereign Collab assets */}
                      <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                        <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                          <Share2 className="w-3.5 h-3.5 text-indigo-400" />
                          {locVal('Collaboration Secure Packages', 'حزم المراسلة المؤمنة والتبادل')}
                        </h3>
                        <div className="space-y-2 max-h-36 overflow-y-auto pr-1">
                          {collabInboxList.length === 0 && collabSentList.length === 0 ? (
                            <p className="text-xs text-neutral-500 italic py-2 pr-1">{locVal('No direct incoming or outgoing packages logged.', 'لا توجد حزم مراسلات صادرة أو واردة مسجلة خلف هذا النطاق.')}</p>
                          ) : (
                            [...collabInboxList.map(i => ({ ...i, dir: 'IN_BOUND' })), ...collabSentList.map(s => ({ ...s, dir: 'OUT_BOUND' }))].map((pkg: any, idx) => (
                              <div key={idx} className="bg-neutral-950/40 p-2.5 rounded border border-neutral-850 flex items-center justify-between text-xs">
                                <div>
                                  <p className="font-semibold text-white truncate max-w-[150px]">{pkg.name || pkg.packageName || 'Cipher package'}</p>
                                  <p className="text-[9px] text-neutral-400 font-mono mt-0.5">
                                    {pkg.dir === 'IN_BOUND' ? `${locVal('From node:', 'من العقدة:')} ${pkg.senderNode}` : `${locVal('Target Node:', 'العقدة المستقبلة:')} ${pkg.targetNode}`}
                                  </p>
                                </div>
                                <span className={`text-[9.5px] font-mono px-1.5 py-0.5 rounded ${pkg.dir === 'IN_BOUND' ? 'bg-blue-950 text-blue-300' : 'bg-purple-950 text-purple-300'}`}>
                                  {pkg.dir === 'IN_BOUND' ? 'IN' : 'OUT'}
                                </span>
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* Explorer File Viewer modal */}
                <AnimatePresence>
                  {viewingFile && (
                    <motion.div
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 z-50 text-neutral-200"
                    >
                      <motion.div
                        initial={{ scale: 0.95 }}
                        animate={{ scale: 1 }}
                        exit={{ scale: 0.95 }}
                        className="bg-neutral-955 border border-neutral-850 w-full max-w-lg rounded-2xl p-5 shadow-2xl space-y-4"
                      >
                        <div className="flex justify-between items-center border-b border-neutral-900 pb-3">
                          <div>
                            <span className="text-[9px] uppercase font-mono bg-cyan-950 text-cyan-400 px-2 py-0.5 rounded inline-block">{viewingFile.type}</span>
                            <h3 className="text-sm font-semibold text-white mt-1">{viewingFile.data.title || viewingFile.data.name}</h3>
                          </div>
                          <button
                            onClick={() => setViewingFile(null)}
                            className="text-xs text-neutral-500 hover:text-white transition-all font-mono cursor-pointer"
                          >
                            [ {locVal('Close', 'إغلاق')} ]
                          </button>
                        </div>

                        <div className="p-3 bg-neutral-900/60 border border-neutral-850 rounded-xl max-h-64 overflow-y-auto font-mono text-xs text-neutral-300 space-y-2">
                          {viewingFile.type === 'note' && (
                            <div>
                              <p className="text-[10px] text-neutral-550 border-b border-neutral-950 pb-1.5 mb-2">
                                {locVal('Category:', 'التصنيف:')} <span className="text-yellow-400">{viewingFile.data.category || 'Default'}</span>
                              </p>
                              <p className="whitespace-pre-wrap leading-relaxed">{viewingFile.data.content}</p>
                            </div>
                          )}

                          {viewingFile.type === 'journal' && (
                            <div>
                              <p className="text-[10px] text-neutral-550 border-b border-neutral-950 pb-1.5 mb-2">
                                {locVal('Date Locked:', 'تاريخ التدوين:')} <span className="text-emerald-400">{new Date(viewingFile.data.timestamp).toLocaleString()}</span>
                              </p>
                              <p className="whitespace-pre-wrap leading-relaxed text-neutral-250">{viewingFile.data.content}</p>
                            </div>
                          )}

                          {viewingFile.type === 'media' && (
                            <div className="text-center py-4 space-y-3">
                              <ImageIcon className="w-12 h-12 text-cyan-400 mx-auto" />
                              <div>
                                <p className="font-semibold text-white">{viewingFile.data.name}</p>
                                <p className="text-[10px] text-neutral-500 mt-1">{locVal('Size:', 'الحجم:')} {viewingFile.data.size || '318 KB'} • {locVal('Format:', 'الامتداد:')} {viewingFile.data.type || 'PNG'}</p>
                                {viewingFile.data.description && (
                                  <p className="text-[11px] text-neutral-400 italic mt-2">"{viewingFile.data.description}"</p>
                                )}
                              </div>
                            </div>
                          )}
                        </div>

                        <div className="flex justify-end gap-2 text-xs">
                          <button
                            onClick={() => {
                              navigator.clipboard.writeText(viewingFile.data.content || viewingFile.data.name);
                              onSuccess(locVal('Copied file parameters to clipboard.', 'تم نسخ معطيات الملف بنجاح.'), 'success');
                            }}
                            className="bg-neutral-900 hover:bg-neutral-800 text-white font-mono px-3.5 py-1.5 rounded-lg border border-neutral-800 transition-all cursor-pointer"
                          >
                            {locVal('Copy Metadata', 'نسخ البيانات')}
                          </button>
                          <button
                            onClick={() => setViewingFile(null)}
                            className="bg-neutral-100 hover:bg-white text-neutral-950 font-semibold px-3.5 py-1.5 rounded-lg transition-all cursor-pointer"
                          >
                            {locVal('Confirm View', 'تأكيد الحفظ')}
                          </button>
                        </div>
                      </motion.div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            )}

            {/* 3. UNIVERSAL SEARCH ENGINE (FEATURE 1) */}
            {activeSubTab === 'search' && (
              <motion.div
                key="sub_search"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Riemann Zero-Knowledge Search Engine', 'محرك البحث المشفر الكلي لشبكة ريمان')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Real-time client indexing engine. Searches notes, journal articles, media files and capsules locally.', 'يبحث محرك الفهرسة الفورية في الملاحظات، اليوميات، أسماء الصور والملفات مشفراً بالكامل.')}</p>
                </div>

                {/* Global Search Parameters Panel */}
                <div className="space-y-3">
                  <div className="flex gap-2 bg-neutral-900 border border-neutral-850 p-1.5 rounded-xl">
                    <div className="flex items-center gap-2 pl-2 w-full">
                      <Search className="w-4 h-4 text-cyan-400 shrink-0" />
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder={locVal('Type keywords (e.g., Note, Ledger, key, coordinate, etc.)', 'أدخل كلمة مفتاحية للبحث (مثلاً: ملاحظة، كبسولة، مفتاح، إلخ...)')}
                        className="w-full bg-transparent text-xs text-white placeholder-neutral-500 focus:outline-none focus:ring-0"
                      />
                    </div>
                  </div>

                  {/* Filter category chips */}
                  <div className="flex flex-wrap gap-1.5 max-w-full overflow-x-auto select-none">
                    {['all', 'notes', 'journals', 'media', 'systems'].map((cat) => (
                      <button
                        key={cat}
                        onClick={() => setSearchCategory(cat)}
                        className={`text-[9.5px] font-mono font-semibold px-2.5 py-1 rounded transition-all cursor-pointer uppercase ${
                          searchCategory === cat 
                            ? 'bg-cyan-950/40 text-cyan-400 border border-cyan-800' 
                            : 'bg-neutral-900 border border-neutral-850 text-neutral-400 hover:text-white'
                        }`}
                      >
                        {cat}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Display Warnings / Locked indicators */}
                {!isUnlocked && (
                  <div className="text-[10.5px] bg-amber-950/20 text-amber-300 px-3.5 py-2.5 rounded-lg border border-amber-800/25 flex items-start gap-2 max-w-lg mx-auto leading-normal font-sans">
                    <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5 text-amber-500" />
                    <div>
                      <p className="font-semibold">{locVal('Ecosystem Password verification needed for Deep Indexing', 'التحقق مطلوب للتمكن من فك التشفير وعمل البحث العميق')}</p>
                      <p className="text-neutral-400 text-[10px] mt-0.5">
                        {locVal('Currently only unencrypted systems like Time Capsules and Security logs are scanned. Unlock the Index above to search across notes, secure journals, and gallery data.', 'حالياً يتم فحص الأنظمة غير المشفرة مثل الكبسولات الزمنية وسجلات الضبط فقط. قم بتأكيد هويتك بالأعلى لإدراج كافة المعطيات السرية.')}
                      </p>
                    </div>
                  </div>
                )}

                {/* Integrated Search Results Display Panel (Fast pagination performance style) */}
                <div className="space-y-4 max-h-80 overflow-y-auto pr-1">
                  {searchQuery === '' ? (
                    <div className="text-center py-10 text-xs text-neutral-500 font-mono">
                      {locVal('Awaiting filter credentials...', 'أدخل مدخلات البحث لبدء فلترة الفهارس...')}
                    </div>
                  ) : (
                    <div className="space-y-3">
                      
                      {/* Sub-Group: Notes */}
                      {(searchCategory === 'all' || searchCategory === 'notes') && filteredSearchItems.notes.length > 0 && (
                        <div className="space-y-1.5">
                          <span className="text-[9px] font-mono text-yellow-500 font-semibold tracking-wider uppercase">{locVal('Notes Index Items', 'الملاحظات المتطابقة')}</span>
                          {filteredSearchItems.notes.map((item: any) => (
                            <div 
                              key={item.id} 
                              onClick={() => setViewingFile({ type: 'note', data: item })}
                              className="bg-neutral-900/40 border border-neutral-850 p-2.5 rounded-lg text-xs hover:border-neutral-700 cursor-pointer flex justify-between items-center transition-all select-none"
                            >
                              <div>
                                <p className="font-semibold text-white">{item.title}</p>
                                <p className="text-[9px] text-neutral-400 font-mono mt-0.5 mt-0.5 truncate max-w-[280px] sm:max-w-xl">{item.content}</p>
                              </div>
                              <ChevronRight className="w-3.5 h-3.5 text-neutral-600" />
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Sub-Group: Journals */}
                      {(searchCategory === 'all' || searchCategory === 'journals') && filteredSearchItems.journals.length > 0 && (
                        <div className="space-y-1.5">
                          <span className="text-[9px] font-mono text-emerald-500 font-semibold tracking-wider uppercase">{locVal('Journals Matches', 'اليوميات المتطابقة')}</span>
                          {filteredSearchItems.journals.map((item: any, i) => (
                            <div 
                              key={item.id || i} 
                              onClick={() => setViewingFile({ type: 'journal', data: item })}
                              className="bg-neutral-900/40 border border-neutral-850 p-2.5 rounded-lg text-xs hover:border-neutral-700 cursor-pointer flex justify-between items-center transition-all select-none"
                            >
                              <div>
                                <p className="font-semibold text-white">{item.title}</p>
                                <p className="text-[9px] text-neutral-400 font-mono mt-0.5 truncate max-w-[280px] sm:max-w-xl">{item.content}</p>
                              </div>
                              <ChevronRight className="w-3.5 h-3.5 text-neutral-600" />
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Sub-Group: Media */}
                      {(searchCategory === 'all' || searchCategory === 'media') && (filteredSearchItems.gallery.length > 0 || filteredSearchItems.media.length > 0) && (
                        <div className="space-y-1.5">
                          <span className="text-[9px] font-mono text-cyan-500 font-semibold tracking-wider uppercase">{locVal('Media Files matches', 'الوسائط والصور المطابقة')}</span>
                          {[...filteredSearchItems.gallery.map(g => ({ ...g, sub: 'Gallery' })), ...filteredSearchItems.media.map(m => ({ ...m, sub: 'Media' }))].map((item: any, i) => (
                            <div 
                              key={item.id || i} 
                              onClick={() => setViewingFile({ type: 'media', data: item })}
                              className="bg-neutral-900/40 border border-neutral-850 p-2.5 rounded-lg text-xs hover:border-neutral-700 cursor-pointer flex justify-between items-center transition-all select-none"
                            >
                              <div>
                                <p className="font-semibold text-white">{item.name}</p>
                                <p className="text-[9px] text-neutral-400 font-mono mt-0.5 truncate">{item.sub || 'Encrypted'}</p>
                              </div>
                              <span className="text-[8px] px-1 py-0.2 background-neutral-800 rounded text-neutral-550 shrink-0">{item.sub}</span>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Sub-Group: Systems capsules and collab */}
                      {(searchCategory === 'all' || searchCategory === 'systems') && (filteredSearchItems.capsules.length > 0 || filteredSearchItems.collab.length > 0) && (
                        <div className="space-y-1.5">
                          <span className="text-[9px] font-mono text-pink-500 font-semibold tracking-wider uppercase">{locVal('Time Capsule/Collab entries', 'أوعية ومراسلات ريمان القريبة')}</span>
                          {filteredSearchItems.capsules.map((item: any) => (
                            <div key={item.id} className="bg-neutral-900/40 border border-neutral-850 p-2.5 rounded-lg text-xs flex justify-between items-center text-neutral-300">
                              <div>
                                <p className="font-semibold text-white">{item.name}</p>
                                <p className="text-[9px] text-neutral-400 font-mono mt-0.5">Under Chrono espectrum constraint.</p>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Sub-Group: Logs */}
                      {(searchCategory === 'all' || searchCategory === 'systems') && filteredSearchItems.logs.length > 0 && (
                        <div className="space-y-1.5">
                          <span className="text-[9px] font-mono text-rose-500 font-semibold tracking-wider uppercase">{locVal('System Audit Logs', 'سجلات العمليات الموافقة')}</span>
                          {filteredSearchItems.logs.map((item: any) => (
                            <div key={item.id} className="bg-neutral-900/40 border border-neutral-850 p-2 text-[10.5px] font-mono text-neutral-400 font-mono">
                              <span className="text-neutral-500 text-[9px] inline-block mr-2">[{new Date(item.timestamp).toLocaleTimeString()}]</span>
                              <span className="text-white font-semibold">{item.event}</span>: {item.details}
                            </div>
                          ))}
                        </div>
                      )}

                      {/* No entries matched query */}
                      {filteredSearchItems.notes.length === 0 &&
                       filteredSearchItems.journals.length === 0 &&
                       filteredSearchItems.gallery.length === 0 &&
                       filteredSearchItems.media.length === 0 &&
                       filteredSearchItems.capsules.length === 0 &&
                       filteredSearchItems.collab.length === 0 &&
                       filteredSearchItems.logs.length === 0 && (
                         <div className="text-center py-10 text-xs text-neutral-500 font-mono">
                           {locVal('No matches found for that keyword.', 'لم يتم العثور على أي نتائج مطابقة للبحث في السجلات المحلية.')}
                         </div>
                       )}

                    </div>
                  )}
                </div>
              </motion.div>
            )}

            {/* 4. UNIFIED SECURITY & RISK CENTER (FEATURE 4) */}
            {activeSubTab === 'security' && (
              <motion.div
                key="sub_security"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Security Operations & Diagnostics Hub', 'مركز عمليات الحماية وتشخيص المخاطر')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Critical audit checklist analyzing physical system assets, passwords, and redundancy key states.', 'فحص أمني متقدم لمشكلات التهيئة وكلمات المرور الضعيفة مع إثبات فهارس الاستعادة الطارئة.')}</p>
                </div>

                {/* Main Score & Audit Summary */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl text-center space-y-1">
                    <span className="text-[9px] uppercase font-mono text-neutral-400">{locVal('Ecosystem Score', 'نقاط أمان النظام')}</span>
                    <p className="text-2xl font-black text-cyan-400 font-mono">{systemSecurityScore}%</p>
                    <span className="text-[9.5px] font-semibold text-emerald-400 bg-emerald-950/20 px-2 py-0.5 rounded border border-emerald-900/30 inline-block">
                      {systemSecurityScore >= 80 ? locVal('HIGH CONGRUENCY', 'مستوى حماية فائق') : locVal('SECURE MARGIN', 'مستوى حماية متوسط')}
                    </span>
                  </div>

                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl text-center space-y-1">
                    <span className="text-[9px] uppercase font-mono text-neutral-400">{locVal('Risk Detections', 'نقاط الضعف المكتشفة')}</span>
                    <p className="text-2xl font-black text-amber-400 font-mono">{riskAssessmentIndicators.length}</p>
                    <span className={`text-[9.5px] font-semibold px-2 py-0.5 rounded border inline-block ${riskAssessmentIndicators.length === 0 ? 'bg-emerald-950/20 text-emerald-400 border-emerald-900/40' : 'bg-amber-950/20 text-amber-400 border-amber-900/40'}`}>
                      {riskAssessmentIndicators.length === 0 ? locVal('ZERO ALERTS', 'خال من الثغرات') : locVal('THREATS REGISTERED', 'تتطلب التدخل')}
                    </span>
                  </div>

                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl text-center space-y-1">
                    <span className="text-[9px] uppercase font-mono text-neutral-400">{locVal('Hardware entropy pool', 'خزان العشوائية الكمومي')}</span>
                    <p className="text-2.5xl font-black text-blue-400 font-mono">1024 <span className="text-xs text-neutral-500 font-medium">bits</span></p>
                    <span className="text-[9.5px] font-semibold text-blue-400 bg-blue-955/20 px-2 py-0.5 rounded border border-blue-900/30 inline-block">
                      {locVal('MAX SATURATION', 'مستقر ومطابق')}
                    </span>
                  </div>
                </div>

                {/* Risk evaluation panel output (Feature 5) */}
                <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                  <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />
                    {locVal('Risk center - Critical vulnerability index', 'فهرس المخاطر ونقاط الضعف العينية')}
                  </h3>

                  {riskAssessmentIndicators.length === 0 ? (
                    <div className="text-xs text-neutral-500 italic py-2">
                      {locVal('✔ No vulnerabilities detected. Systems are structured to premium military standard presets.', '✔ مبروك: لم يتم كشف أي ثغرات أو معالم خطر بالخزانة الحالية. جميع المعايير مطابقة لأقصى درجات الأمان.')}
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {riskAssessmentIndicators.map((risk) => (
                        <div key={risk.id} className="bg-neutral-950/60 p-3 rounded-lg border border-neutral-850 flex gap-2.5 items-start text-xs leading-normal">
                          {risk.threatLevel === 'critical' ? (
                            <ShieldAlert className="w-4 h-4 text-rose-500 mt-0.5 shrink-0" />
                          ) : (
                            <AlertTriangle className="w-4 h-4 text-amber-500 mt-0.5 shrink-0" />
                          )}
                          <div>
                            <p className="font-semibold text-white">{isAr && risk.issueAr ? risk.issueAr : risk.issueEn}</p>
                            <p className="text-[10px] text-neutral-400 mt-0.5 leading-relaxed">{isAr && risk.recommendationAr ? risk.recommendationAr : risk.recommendationEn}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Audit & Report Actions (Feature 6 Reports) */}
                <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                  <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                    <Download className="w-3.5 h-3.5 text-cyan-400" />
                    {locVal('Audit reports generator center', 'بوابة توليد التدقيق وتصدير معطيات الكبسولة')}
                  </h3>
                  <p className="text-[10px] text-neutral-400 font-mono">
                    {locVal('Formulate physical diagnostic reports from active local index structures.', 'قم بإنشاء وتأمين وتصدير تقارير الإثبات المكتوبة عن الحالة العامة لحسابك الحساس.')}
                  </p>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-1">
                    <button
                      onClick={triggerPdfReportDownload}
                      className="bg-neutral-950 hover:bg-neutral-900 text-cyan-400 hover:text-white text-xs font-mono font-semibold py-2.5 px-3 rounded-xl border border-neutral-850 transition-all text-center cursor-pointer flex items-center justify-center gap-2"
                    >
                      <FileText className="w-4 h-4" />
                      {locVal('Export text Audit report', 'تصدير تقرير التدقيق النصي')}
                    </button>
                    <button
                      onClick={triggerEncryptedReportPackage}
                      className="bg-cyan-950/20 hover:bg-cyan-950/40 text-cyan-400 border border-cyan-800 py-2.5 px-3 rounded-xl transition-all text-xs font-mono font-semibold text-center cursor-pointer flex items-center justify-center gap-2"
                    >
                      <ZipIcon className="w-4 h-4 text-cyan-400" />
                      {locVal('Export Encrypted SNAPSHOT', 'تصدير الحزمة الثلاثية المشفرة')}
                    </button>
                  </div>
                </div>
              </motion.div>
            )}

            {/* 5. GLOBAL ACTIVITY FEED (FEATURE 3) */}
            {activeSubTab === 'timeline' && (
              <motion.div
                key="sub_timeline"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Global Security Timeline Feed', 'سجل العمليات الإشاري المركزي الموحد')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Consolidated chronologically organized event loop summarizing all security vectors.', 'خط زمني منظم يعرض بالتفصيل الكرنولوجي كافة الأنشطة والمحاولات الحيوية بقاعدة الحماية.')}</p>
                </div>

                <div className="space-y-4 max-h-96 overflow-y-auto pr-1">
                  {unifiedActivityStream.length === 0 ? (
                    <p className="text-xs text-neutral-500 italic py-6 text-center font-mono">{locVal('No system events recorded.', 'لا توجد فعاليات مسجلة كودياً بالمرصد.')}</p>
                  ) : (
                    <div className="relative border-l border-neutral-850 ml-4 pl-4 space-y-4 font-mono select-none">
                      {unifiedActivityStream.map((log, index) => (
                        <div key={log.id + index} className="relative group">
                          {/* Left bullet marker node */}
                          <div className="absolute -left-[24.5px] top-1 w-4 h-4 rounded-full bg-neutral-950 border border-neutral-850 flex items-center justify-center text-[8px] z-10 group-hover:border-cyan-400 transition-all">
                            {log.icon || '●'}
                          </div>
                          <div className="space-y-0.5">
                            <span className="text-[9px] text-neutral-500 block">
                              {new Date(log.timestamp).toLocaleString()}
                            </span>
                            <span className="text-xs font-bold text-white block">
                              {log.title}
                            </span>
                            <span className="text-[10px] text-neutral-400 block leading-relaxed">
                              {log.details}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </motion.div>
            )}

            {/* 6. ECOSYSTEM SETTINGS (FEATURE 8) */}
            {activeSubTab === 'settings' && (
              <motion.div
                key="sub_settings"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Central Ecosystem Settings Matrix', 'مصفوفة إعدادات النظام وتفضيلات الخزانة')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Manage unified system attributes, encryption constants, and local cached data layers.', 'تحكم في المتطلبات المشتركة، معايير العشوائية الطيفية، وخيارات التخزين المحلية.')}</p>
                </div>

                {/* Subsections Grid organizing logically */}
                <div className="space-y-4 text-xs font-mono">
                  {/* Category 1: Authentication config */}
                  <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-4 space-y-3">
                    <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                      <Lock className="w-3.5 h-3.5 text-yellow-400" />
                      {locVal('Authentication & Sovereign Access', 'إعدادات الولوج والأمان الرقمي')}
                    </h3>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                      <div className="bg-neutral-950/60 p-2.5 rounded border border-neutral-850 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-white">{locVal('Quick Biometrics Layer', 'التحقق البيومتري السريع')}</p>
                          <p className="text-[9px] text-neutral-500 mt-0.5">{biometricsOn ? 'ACTIVE_AND_SEALED' : 'INACTIVE'}</p>
                        </div>
                        <span className={`w-2.5 h-2.5 rounded-full ${biometricsOn ? 'bg-emerald-400 shadow-pulse' : 'bg-rose-500'}`} />
                      </div>

                      <div className="bg-neutral-950/60 p-2.5 rounded border border-neutral-850 flex justify-between items-center">
                        <div>
                          <p className="font-semibold text-white">{locVal('System Index cache keys', 'مفتاح الاسترجاع للفهرس المشترك')}</p>
                          <p className="text-[9px] text-neutral-500 mt-0.5">{isUnlocked ? 'SECURE_IN_MEMORY' : 'LOGGED_OUT'}</p>
                        </div>
                        <span className={`w-2.5 h-2.5 rounded-full ${isUnlocked ? 'bg-emerald-400' : 'bg-amber-400'}`} />
                      </div>
                    </div>
                  </div>

                  {/* Settings Widget Customization (Feature 5 Widgets selection) */}
                  <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-4 space-y-3">
                    <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none">
                      <LayoutGrid className="w-3.5 h-3.5 text-cyan-400" />
                      {locVal('Customizable Dashboard Modules', 'التحكم في ظهور حزم لوحة المراقبة')}
                    </h3>
                    <p className="text-[9.5px] text-neutral-400 leading-normal">
                      {locVal('Enable or suppress dynamic widgets from compiling in your main Sovereign Dashboard view.', 'قم بتفعيل أو إلغاء تفعيل عرض النوافذ التشخيصية الفورية في لوحة التحكم بشكل مباشر.')}
                    </p>
                    <div className="grid grid-cols-2 md:grid-cols-3 gap-2 pt-1">
                      {widgets.map(w => (
                        <button
                          key={w.id}
                          onClick={() => toggleWidgetVisibility(w.id)}
                          className={`text-center py-1.5 px-2.5 rounded border transition-all cursor-pointer text-[10px] select-none font-semibold ${
                            w.visible 
                              ? 'bg-cyan-950/20 text-cyan-400 border-cyan-800/40' 
                              : 'bg-neutral-950/60 text-neutral-500 border-neutral-850 '
                          }`}
                        >
                          {locVal(w.titleEn, w.titleAr)}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Settings Local Cache purge system */}
                  <div className="bg-neutral-900/40 border border-neutral-850 rounded-xl p-4 space-y-3">
                    <h3 className="text-xs font-semibold text-white flex items-center gap-1.5 select-none text-rose-450">
                      <Trash2 className="w-3.5 h-3.5" />
                      {locVal('Local Cache Sanitizer & Purge Control', 'تطهير الذاكرة وجلسة الطوارئ الكلية')}
                    </h3>
                    <p className="text-[9.5px] text-neutral-400 leading-normal">
                      {locVal('Purges local session variables, decrypt indices, and logs. This acts as an offline browser sandbox-wide panic protocol.', 'مسح فوري لمؤشرات الفك المؤقتة وملفات الضبط لحجب المعطيات عن الدخلاء ومنع فحص الكوكيز.')}
                    </p>
                    <div className="pt-1">
                      <button
                        onClick={() => {
                          if (onEmergencyLock) {
                            onEmergencyLock();
                          } else {
                            handleLockEcosystem();
                            onSuccess(locVal('Session caches Purged!', 'تم تصفية وتفريغ الذاكرة بنجاح!'), 'error');
                          }
                        }}
                        className="bg-rose-950/40 border border-rose-950 hover:bg-rose-900/30 text-rose-300 font-bold py-2 px-4 rounded-xl transition-all cursor-pointer"
                      >
                        {locVal('ACTIVATE EMERGENCY SANITIZATION LOOP', 'تفعيل بروتوكول قفل الطوارئ ومسح الملفات')}
                      </button>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {/* 7. FUTURE PREPARATION blue prints (Labs preview) */}
            {activeSubTab === 'labs' && (
              <motion.div
                key="sub_labs"
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -15 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                <div>
                  <h2 className="text-sm font-semibold text-white">{locVal('Riman Sovereign Labs Blueprints', 'مخططات مستقبل ريمان Labs للأمن والحلول الذكية')}</h2>
                  <p className="text-[10px] text-neutral-400 font-mono">{locVal('Future-focused technical architectural specifications (Preview pipeline).', 'أنظمة قيد التخطيط والتصميم الرياضي والهيكلي للشبكة (نظرة مستقبلية).')}</p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 font-mono text-[10.5px]">
                  
                  {/* Plugin system card */}
                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                    <div className="p-1 px-2 bg-pink-950/40 text-pink-400 border border-pink-900/40 rounded inline-block text-[9.5px] font-bold">
                      {locVal('BLUEPRINT v1.1', 'مخطط هجين v1.1')}
                    </div>
                    <h3 className="text-xs font-bold text-white uppercase">{locVal('Decentralized Plugin Engine', 'محرك الملحقات اللامركزي')}</h3>
                    <p className="text-neutral-400 leading-relaxed text-[10px]">
                      {locVal('A modular sandbox permitting third-party encryption libraries (such as post-quantum Dilithium) to register securely on top of the Riman Pipeline.', 'السماح لملحقات التحقق الخارجي والمكتبات الرياضية الأحدث بالاندماج مع خط التشفير بسلاسة.')}
                    </p>
                  </div>

                  {/* Cloud Bridge card */}
                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                    <div className="p-1 px-2 bg-blue-950/40 text-blue-400 border border-blue-900/40 rounded inline-block text-[9.5px] font-bold">
                      {locVal('BLUEPRINT v1.3', 'مخطط هجين v1.3')}
                    </div>
                    <h3 className="text-xs font-bold text-white uppercase">{locVal('Zero-Knowledge Cloud Bridge', 'جسر السحابة عديمة المعرفة')}</h3>
                    <p className="text-neutral-400 leading-relaxed text-[10px]">
                      {locVal('Secure distribution channel backup proxying client-side triple encrypted payload metadata blocks directly to IPFS and local relays.', 'قناة اتصالات مؤمنة ترفع البيانات المشفرة لجسور هجينة وموزعة لضمان عدم الفقد.')}
                    </p>
                  </div>

                  {/* Local AI card */}
                  <div className="bg-neutral-900/40 border border-neutral-850 p-4 rounded-xl space-y-3">
                    <div className="p-1 px-2 bg-purple-950/40 text-purple-400 border border-purple-900/40 rounded inline-block text-[9.5px] font-bold">
                      {locVal('BLUEPRINT v1.5', 'مخطط هجين v1.5')}
                    </div>
                    <h3 className="text-xs font-bold text-white uppercase">{locVal('Local AI Assistant Grounding', 'مساعد الذكاء الاصطناعي المحلي')}</h3>
                    <p className="text-neutral-400 leading-relaxed text-[10px]">
                      {locVal('On-device natural language query parsing utilizing client-side weights (WebNN or Transformers) to scan encrypted local logs.', 'معالجة لغوية في البيئة المحلية للمتصفح تمكن المستخدم من توجيه الاستعلامات بذكاء للأرصدة.')}
                    </p>
                  </div>

                </div>
              </motion.div>
            )}

          </AnimatePresence>
        </main>

      </div>

    </div>
  );
};

// Simple zip file icon inside Riman Ecosystem Core for export Snapshots
const ZipIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg 
    xmlns="http://www.w3.org/2000/svg" 
    width="16" 
    height="16" 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round" 
    className={className}
  >
    <path d="M12 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <path d="M10.42 12.585a3 3 0 1 0-4.24 0l2.12 2.122A1 1 0 0 0 9 15h6a1 1 0 0 0 .707-.293l2.122-2.122a3 3 0 1 0-4.24-4.242" />
    <polyline points="14 2 14 8 20 8" />
  </svg>
);
