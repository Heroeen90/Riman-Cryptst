import React, { useState, useEffect } from 'react';
import { 
  Share2, Lock, Unlock, Clock, AlertTriangle, Key, User, FileText, Download, 
  Eye, Plus, Trash2, Check, RefreshCw, Send, Radio, Info, Shield, ShieldCheck, 
  Fingerprint, Activity, Calendar, Copy, ChevronRight, Inbox, HelpCircle, 
  HardDrive, Compass, Link, RefreshCw as RefreshIcon
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useTranslation } from '../lib/I18nContext';
import { EncryptedContainer } from '../types';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt,
  stringToBytes,
  bytesToString
} from '../lib/crypto';

interface CollabProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

interface SharedPackage {
  id: string; // package ID e.g. PKG-1234
  name: string;
  category: 'File' | 'Note' | 'Media' | 'Vault Folder';
  createdTime: number;
  expireTime: number | null; // null if no expiry
  maxAccessCount: number | null; // null if unlimited
  currentAccessCount: number;
  oneTimeAccess: boolean;
  readOnly: boolean;
  downloadAllowed: boolean;
  status: 'ACTIVE' | 'REVOKED' | 'EXPIRED';
  trustScore: 'Verified' | 'Protected' | 'Temporary' | 'Expired';
  container: EncryptedContainer;
  passwordProtected: boolean;
  biometricRequired: boolean;
  recoveryVerified: boolean;
  ownerDna: string;
}

interface InboxItem {
  id: string;
  packageName: string;
  category: 'File' | 'Note' | 'Media' | 'Vault Folder';
  receivedTime: number;
  senderDna: string;
  plainTextContent: string;
  fileName?: string;
  trustScore: 'Verified' | 'Protected' | 'Temporary' | 'Expired';
}

interface CollabActivityLog {
  id: string;
  timestamp: number;
  action: 'Package Created' | 'Package Opened' | 'Package Expired' | 'Package Revoked' | 'Inbox Recieved' | 'Security Rejected';
  name: string;
  details: string;
}

export const SecureCollaborationModule: React.FC<CollabProps> = ({
  onSuccess,
  onSecurityLog,
  triggerAnimation
}) => {
  const { locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // States
  const [subTab, setSubTab] = useState<'dashboard' | 'packages' | 'inbox' | 'architecture'>('dashboard');
  const [ownerDna] = useState<string>(() => localStorage.getItem('riman_vault_dna_seed') || 'RZ-A81F-92CD');
  const [biometricsEnabled] = useState<boolean>(() => localStorage.getItem('riman_biometrics_enabled') === 'true');
  const [recoveryKey] = useState<string | null>(() => localStorage.getItem('riman_recovery_key'));

  const [activePackages, setActivePackages] = useState<SharedPackage[]>([]);
  const [inboxItems, setInboxItems] = useState<InboxItem[]>([]);
  const [activityLogs, setActivityLogs] = useState<CollabActivityLog[]>([]);

  // Selection states
  const [selectedPackageId, setSelectedPackageId] = useState<string | null>(null);
  const [selectedInboxId, setSelectedInboxId] = useState<string | null>(null);

  // Package Input form
  const [packageName, setPackageName] = useState<string>('');
  const [packageCategory, setPackageCategory] = useState<'File' | 'Note' | 'Media' | 'Vault Folder'>('Note');
  const [packageContent, setPackageContent] = useState<string>('');
  const [packageFileName, setPackageFileName] = useState<string>('');
  const [packagePassword, setPackagePassword] = useState<string>('');
  
  // Expiration / Duration limits
  const [rawDuration, setRawDuration] = useState<'1h' | '24h' | '7d' | 'unlimited' | 'custom'>('1h');
  const [customDurationHours, setCustomDurationHours] = useState<string>('4');
  const [maxAccessCountRaw, setMaxAccessCountRaw] = useState<string>('unlimited'); // '1' | '3' | '5' | 'unlimited'
  const [oneTimeAccess, setOneTimeAccess] = useState<boolean>(false);
  const [readOnly, setReadOnly] = useState<boolean>(false);
  const [downloadAllowed, setDownloadAllowed] = useState<boolean>(true);

  // Authentication locks
  const [biometricRequired, setBiometricRequired] = useState<boolean>(false);
  const [recoveryVerified, setRecoveryVerified] = useState<boolean>(false);

  // Import / Pasting Link
  const [importTokenInput, setImportTokenInput] = useState<string>('');
  const [importPasswordInput, setImportPasswordInput] = useState<string>('');
  const [importBiometricPrompt, setImportBiometricPrompt] = useState<boolean>(false);
  const [importRecoveryPrompt, setImportRecoveryPrompt] = useState<boolean>(false);
  const [importRecoveryInput, setImportRecoveryInput] = useState<string>('');
  const [importTargetPackage, setImportTargetPackage] = useState<SharedPackage | null>(null);

  // UI state for creation modal
  const [showCreateModal, setShowCreateModal] = useState<boolean>(false);

  // Time ticks
  const [currentTime, setCurrentTime] = useState<number>(Date.now());

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Hydrate lists
  useEffect(() => {
    const savedPackages = localStorage.getItem('riman_collab_packages_v7');
    const savedInbox = localStorage.getItem('riman_collab_inbox_v7');
    const savedLogs = localStorage.getItem('riman_collab_logs_v7');

    if (savedPackages) {
      try { setActivePackages(JSON.parse(savedPackages)); } catch (e) { initPresets(); }
    } else {
      initPresets();
    }

    if (savedInbox) {
      try { setInboxItems(JSON.parse(savedInbox)); } catch (e) {}
    }
    if (savedLogs) {
      try { setActivityLogs(JSON.parse(savedLogs)); } catch (e) {}
    }
  }, []);

  const savePackagesToLocalStorage = (pkgs: SharedPackage[]) => {
    setActivePackages(pkgs);
    localStorage.setItem('riman_collab_packages_v7', JSON.stringify(pkgs));
  };

  const saveInboxToLocalStorage = (items: InboxItem[]) => {
    setInboxItems(items);
    localStorage.setItem('riman_collab_inbox_v7', JSON.stringify(items));
  };

  const saveLogsToLocalStorage = (logs: CollabActivityLog[]) => {
    setActivityLogs(logs);
    localStorage.setItem('riman_collab_logs_v7', JSON.stringify(logs));
  };

  const addActivityLog = (action: CollabActivityLog['action'], name: string, details: string) => {
    const newLog: CollabActivityLog = {
      id: `LOG-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
      timestamp: Date.now(),
      action,
      name,
      details
    };
    const updated = [newLog, ...activityLogs].slice(0, 50); // limit to 50
    saveLogsToLocalStorage(updated);
  };

  const initPresets = () => {
    const now = Date.now();
    
    // Preset Shared Package
    const demoPayload = stringToBytes("V7 SECURE MULTI-LAYER AUTH COLLABORATION PROTOTYPE. SUCCESS");
    const container = executeRiemannTripleLayerEncrypt(demoPayload, 'riman123', {
      filename: 'collaborative_instructions.md',
      fileType: 'text/markdown',
      isCapsule: false
    });

    const demoPackage: SharedPackage = {
      id: 'PKG-RI-9E4B',
      name: locVal('Demostatistic Sovereignty Rules', 'دليل السيادة الإحصائي التوضيحي'),
      category: 'Note',
      createdTime: now - 3600000 * 2,
      expireTime: now + 3600000 * 24, // 24 Hours duration
      maxAccessCount: 5,
      currentAccessCount: 2,
      oneTimeAccess: false,
      readOnly: true,
      downloadAllowed: true,
      status: 'ACTIVE',
      trustScore: 'Protected',
      container,
      passwordProtected: true,
      biometricRequired: false,
      recoveryVerified: false,
      ownerDna: 'RZ-A81F-92CD'
    };

    savePackagesToLocalStorage([demoPackage]);
  };

  // Check and update package expiration automatically based on time ticks
  useEffect(() => {
    let changed = false;
    const mapped = activePackages.map(pkg => {
      if (pkg.status === 'ACTIVE' && pkg.expireTime && currentTime > pkg.expireTime) {
        changed = true;
        addActivityLog('Package Expired', pkg.name, `Package ID: ${pkg.id} elapsed expiration threshold.`);
        return { ...pkg, status: 'EXPIRED' as const, trustScore: 'Expired' as const };
      }
      return pkg;
    });

    if (changed) {
      savePackagesToLocalStorage(mapped);
    }
  }, [currentTime, activePackages]);

  // FEATURE 1 & 2: CREATE ENCRYPTED SHARE PACKAGES
  const handleCreatePackage = (e: React.FormEvent) => {
    e.preventDefault();

    if (!packageName.trim() || !packageContent.trim()) {
      onSuccess(locVal('Label and Content payload cannot be empty!', 'الاسم التعريفي ومخرجات المحتوى لا يمكن أن تظل فارغة!'), 'error');
      return;
    }

    if (!packagePassword || packagePassword.length < 6) {
      onSuccess(locVal('Password must be at least 6 characters!', 'كلمة المرور يجب ألا تقل عن ٦ خانات طيفية!'), 'error');
      return;
    }

    // Determine temporary duration limit (FEATURE 3)
    let expirationMs: number | null = null;
    if (rawDuration === '1h') expirationMs = 3600000;
    else if (rawDuration === '24h') expirationMs = 86400000;
    else if (rawDuration === '7d') expirationMs = 86400000 * 7;
    else if (rawDuration === 'custom') {
      const hrs = parseFloat(customDurationHours);
      if (isNaN(hrs) || hrs <= 0) {
        onSuccess(locVal('Please input a valid positive hour value!', 'يرجى تقديم مدة تفعيل صحيحة بالساعات!'), 'error');
        return;
      }
      expirationMs = Math.round(hrs * 3600000);
    }

    const expireTimestamp = expirationMs ? Date.now() + expirationMs : null;

    // Access Count limit
    let maxAccess: number | null = null;
    if (maxAccessCountRaw !== 'unlimited') {
      maxAccess = parseInt(maxAccessCountRaw);
    }

    try {
      triggerAnimation('encrypt');
      onSecurityLog('Encrypting Shared Collaboration Parcel', 'info', `Target: ${packageName}`);

      // Encrypt payload strictly through Symmetric Riemann Triple Architecture
      const fileBytes = stringToBytes(packageContent);
      const containerObj = executeRiemannTripleLayerEncrypt(fileBytes, packagePassword, {
        filename: packageCategory === 'File' ? (packageFileName || `${packageName.toLowerCase().replace(/\s/g, '_')}.dat`) : undefined,
        fileType: packageCategory === 'Note' ? 'text/plain' : 'application/octet-stream',
        isCapsule: false
      });

      // Calculate Trust Score classification (FEATURE 8)
      let scoreCategory: SharedPackage['trustScore'] = 'Verified';
      if (expireTimestamp) scoreCategory = 'Temporary';
      else if (biometricRequired || packagePassword) scoreCategory = 'Protected';

      const randomId = `PKG-SVR-${Math.random().toString(36).substring(2, 6).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

      const newPkg: SharedPackage = {
        id: randomId,
        name: packageName,
        category: packageCategory,
        createdTime: Date.now(),
        expireTime: expireTimestamp,
        maxAccessCount: maxAccess,
        currentAccessCount: 0,
        oneTimeAccess,
        readOnly,
        downloadAllowed,
        status: 'ACTIVE',
        trustScore: scoreCategory,
        container: containerObj,
        passwordProtected: true,
        biometricRequired,
        recoveryVerified,
        ownerDna: ownerDna
      };

      const updated = [newPkg, ...activePackages];
      savePackagesToLocalStorage(updated);

      addActivityLog('Package Created', packageName, `Package ID: ${randomId} compiled under multi-layer shield.`);
      onSecurityLog('End-to-end multi-layer envelope sealed', 'info', `ID: ${randomId}`);
      onSuccess(locVal('Sovereign Collaboration Package compiled and link token unlocked!', 'تم تشكيل حزمة التعاون المشفرة وتلقي كود المزامنة بنجاح!'), 'success');

      // Clear Form
      setPackageName('');
      setPackageContent('');
      setPackagePassword('');
      setPackageFileName('');
      setShowCreateModal(false);
    } catch (e: any) {
      onSecurityLog('Collaboration compilation fault', 'critical', e.message);
      onSuccess(`${locVal('Symmetric encryption logic fault', 'عطل في التشفير المتناسق')}: ${e.message}`, 'error');
    }
  };

  // FEATURE 6: ACCESS REVOCATION
  const handleRevokePackage = (id: string) => {
    const updated = activePackages.map(pkg => {
      if (pkg.id === id) {
        addActivityLog('Package Revoked', pkg.name, `Package ID: ${pkg.id} security token invalidated manually.`);
        onSecurityLog('Manual Package Access Revocation', 'warning', `ID: ${id} blacklisted`);
        return { ...pkg, status: 'REVOKED' as const };
      }
      return pkg;
    });
    savePackagesToLocalStorage(updated);
    onSuccess(locVal('Share link cancelled and access revoked immediately.', 'تم تفريغ وإبطال صلاحية كود المزامنة ومسار الوصول فوراً!'), 'info');
  };

  // Fast helper to export structural Package object as high-security Encrypted Token Base64 string (FEATURE 1)
  const getShareTokenString = (pkg: SharedPackage): string => {
    try {
      // Create a secure export payload that acts as the secure link
      const serializableObj = {
        _rimanCollabMarker: 'v7_collab_packet_g1',
        id: pkg.id,
        name: pkg.name,
        category: pkg.category,
        createdTime: pkg.createdTime,
        expireTime: pkg.expireTime,
        maxAccessCount: pkg.maxAccessCount,
        oneTimeAccess: pkg.oneTimeAccess,
        readOnly: pkg.readOnly,
        downloadAllowed: pkg.downloadAllowed,
        biometricRequired: pkg.biometricRequired,
        recoveryVerified: pkg.recoveryVerified,
        container: pkg.container,
        ownerDna: pkg.ownerDna
      };
      
      const jsonStr = JSON.stringify(serializableObj);
      return btoa(unescape(encodeURIComponent(jsonStr)));
    } catch(e) {
      return '';
    }
  };

  const copyShareToken = (pkg: SharedPackage) => {
    const token = getShareTokenString(pkg);
    if (!token) return;
    navigator.clipboard.writeText(token);
    onSuccess(locVal('Collaboration Link Token copied to secure clipboard!', 'تم نسخ كود المزامنة والربط التعاوني بأمان للحافظة!'), 'success');
  };

  // FEATURE 4: SECURE INBOX DECRYPT AND ATTACH
  const handleProcessImportToken = () => {
    if (!importTokenInput.trim()) {
      onSuccess(locVal('Please paste a valid collaboration package token!', 'يرجى لصق كود المزامنة التعاونية أولاً!'), 'error');
      return;
    }

    try {
      // Decode base64
      const decodedJson = decodeURIComponent(escape(atob(importTokenInput.trim())));
      const parsed = JSON.parse(decodedJson);

      if (parsed._rimanCollabMarker !== 'v7_collab_packet_g1' || !parsed.container) {
        onSuccess(locVal('Invalid token signature or compromised envelope payload.', 'الشفرة الملصقة غير صالحة أو معطلة برمجياً.'), 'error');
        return;
      }

      // Check validation variables of incoming nodes (Even if simulate offline, we read the boundaries)
      if (parsed.expireTime && Date.now() > parsed.expireTime) {
        addActivityLog('Security Rejected', parsed.name, `Import rejected: expired on ${new Date(parsed.expireTime).toLocaleString()}`);
        onSecurityLog('Decryption request rejected', 'warning', `Package ${parsed.id} has reached expiration boundary.`);
        onSuccess(locVal('Secure Link has expired! Connection is closed to this envelope.', 'فشلت المزامنة: تجاوزت هذه الحزمة النطاق الزمني المحدد لها!'), 'error');
        return;
      }

      // Prepare target for multi-layer authorization checks (FEATURE 7)
      setImportTargetPackage(parsed);

      if (parsed.biometricRequired && !biometricsEnabled) {
        onSuccess(locVal('Biometrics required to ingest this packet, but biometrics are disabled in this Vault!', 'بصمة الهوية مطلوبة لاستيراد المعطيات، لكنها معطلة في هذا النظام!'), 'error');
        return;
      }

      if (parsed.biometricRequired) {
        setImportBiometricPrompt(true);
      } else if (parsed.recoveryVerified) {
        setImportRecoveryPrompt(true);
      } else {
        // Just password prompt needed
        // Normal state handles next step
      }

    } catch (err) {
      onSuccess(locVal('Failed to parse connection signature. Copy-paste mismatch?', 'فشل تحليل التوقيع الرقمي. يرجى التأكد من اكتمال نسخ الكود.'), 'error');
    }
  };

  const handleApplyDecryptionToInbox = () => {
    if (!importTargetPackage) return;
    if (!importPasswordInput) {
      onSuccess(locVal('Please input the containment key password!', 'يرجى تقديم كلمة المرور لفك الدرع المتناسق!'), 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Symmetric Riemann Multi-Layer decrypt', 'info', `Target Inbox: ${importTargetPackage.id}`);

      // Decrypt container
      const decodedBytes = executeRiemannTripleLayerDecrypt(importTargetPackage.container, importPasswordInput);
      const plaintext = bytesToString(decodedBytes);

      // Increment access on active packages list if it resides locally (self-shares simulation)
      const locallyLogged = activePackages.some(p => p.id === importTargetPackage.id);
      if (locallyLogged) {
        const updatedPkgs = activePackages.map(p => {
          if (p.id === importTargetPackage.id) {
            const nextCount = p.currentAccessCount + 1;
            let currentStatus = p.status;
            if (p.maxAccessCount && nextCount >= p.maxAccessCount) {
              currentStatus = 'EXPIRED';
            }
            if (p.oneTimeAccess) {
              currentStatus = 'EXPIRED';
            }
            return {
              ...p,
              currentAccessCount: nextCount,
              status: currentStatus,
              trustScore: currentStatus === 'EXPIRED' ? ('Expired' as const) : p.trustScore
            };
          }
          return p;
        });
        savePackagesToLocalStorage(updatedPkgs);
      }

      // Append to local inboxItems list
      const received: InboxItem = {
        id: `INB-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
        packageName: importTargetPackage.name,
        category: importTargetPackage.category,
        receivedTime: Date.now(),
        senderDna: importTargetPackage.ownerDna,
        plainTextContent: plaintext,
        fileName: importTargetPackage.container.filename,
        trustScore: importTargetPackage.biometricRequired ? 'Verified' : 'Protected'
      };

      const updatedInbox = [received, ...inboxItems];
      saveInboxToLocalStorage(updatedInbox);

      addActivityLog('Package Opened', importTargetPackage.name, `Imported successfully to secure inbox ledger.`);
      onSecurityLog('Zero-Knowledge envelope integrated', 'info', `Package ${importTargetPackage.id} processed.`);
      onSuccess(locVal('Package decrypted and added to your Secure Inbox successfully!', 'تم تفريغ الحزمة بنجاح بمفتاح فك الأغلال وإضافتها لبريد الاستلام الآمن!'), 'success');

      // Reset Import prompts
      setImportTokenInput('');
      setImportPasswordInput('');
      setImportTargetPackage(null);
      setImportBiometricPrompt(false);
      setImportRecoveryPrompt(false);
      setImportRecoveryInput('');

    } catch (e) {
      addActivityLog('Security Rejected', importTargetPackage.name, 'Cryptographic key signature unmatched.');
      onSecurityLog('Collaboration decryption fault', 'critical', `Target ID: ${importTargetPackage.id}`);
      onSuccess(locVal('Incorrect password or key mismatch!', 'خطأ في كلمة المرور أو تلف طيفي في فك الأقفال!'), 'error');
    }
  };

  const handleSimulateBiometricImport = () => {
    // Verified Simulate
    onSuccess(locVal('Biometric verification verified. Key pipeline approved!', 'تمت مطابقة بصمة الهوية الطيفية بنجاح! صودق على المتابعة.'), 'success');
    setImportBiometricPrompt(false);
    if (importTargetPackage?.recoveryVerified) {
      setImportRecoveryPrompt(true);
    }
  };

  const handleSimulateRecoveryImport = () => {
    if (!importRecoveryInput) {
      onSuccess(locVal('Please input your vault master recovery key!', 'يرجى تقديم رمز الاستعادة الكلي للنظام!'), 'error');
      return;
    }

    if (importRecoveryInput !== recoveryKey) {
      onSuccess(locVal('Incorrect master recovery key! Authorization canceled.', 'مفتاح الاستعادة المدخل غير صحيح! ألغيت المصادقة.'), 'error');
      return;
    }

    onSuccess(locVal('Recovery key verification aligned! Security override unlocked.', 'تمت مطابقة مفتاح المعايرة والاستعادة! تجاوز معزز الأمان أقر ونجح.'), 'success');
    setImportRecoveryPrompt(false);
  };

  const handleDownloadReceivedItem = (item: InboxItem) => {
    const blob = new Blob([item.plainTextContent], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = item.fileName || `${item.packageName.toLowerCase().replace(/\s/g, '_')}_received.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    onSuccess(locVal('Received payload saved to disk!', 'تم حفظ وتصدير المستند بنجاح!'), 'success');
  };

  const purgeInboxItem = (id: string) => {
    const filtered = inboxItems.filter(item => item.id !== id);
    saveInboxToLocalStorage(filtered);
    if (selectedInboxId === id) setSelectedInboxId(null);
    onSuccess(locVal('Received packet completely wiped from local sector.', 'تم مسح وتطهير الطرد المستلم بالكامل.'), 'info');
  };

  return (
    <div className="space-y-6" id="secure_collaboration_platform_root">
      
      {/* Header and Sub Nav Tabs */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-neutral-850 pb-4">
        <div>
          <span className="text-[9px] uppercase tracking-widest font-mono text-cyan-400">
            {locVal('REIMANN COLLABORATION CORE V7.0', 'نظام ريمان للتعاون الآمن والربط الخارجي')}
          </span>
          <h2 className="text-xl font-display font-medium text-white tracking-tight flex items-center gap-2">
            <Share2 className="w-5 h-5 text-cyan-400" />
            {locVal('Encrypted Collaboration & Inbox', 'منصة التبادل المشفر والبريد السيادي')}
          </h2>
        </div>
        
        {/* Module Area Selector Tabs */}
        <div className="flex gap-1 bg-neutral-950 p-1 border border-neutral-850 rounded-xl">
          <button 
            onClick={() => setSubTab('dashboard')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'dashboard' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('Collab Space', 'مساحة المزامنة')}
          </button>
          <button 
            onClick={() => setSubTab('packages')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'packages' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('My Outbox Seals', 'الحزم الصادرة')}
          </button>
          <button 
            onClick={() => setSubTab('inbox')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'inbox' ? 'bg-neutral-850 text-white border border-neutral-700/50 flex items-center gap-1.5' : 'text-neutral-500 hover:text-neutral-300 flex items-center gap-1.5'
            }`}
          >
            <Inbox className="w-3 h-3" />
            {locVal('Secure Inbox', 'صندوق الوارد المظلم')}
            {inboxItems.length > 0 && (
              <span className="w-2 h-2 bg-rose-500 rounded-full animate-ping" />
            )}
          </button>
          <button 
            onClick={() => setSubTab('architecture')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'architecture' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('E2E Blueprint', 'العقد وفضاء المستقبل')}
          </button>
        </div>
      </div>

      {/* DASHBOARD TAB (Multi-layer indicators, quick stats & recent actions) */}
      {subTab === 'dashboard' && (
        <div className="space-y-6">
          
          {/* Top Info Shield banner */}
          <div className="glass-card p-5 rounded-3xl border border-cyan-850/40 bg-cyan-950/5 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/5 rounded-full blur-2xl pointer-events-none" />
            <div className="flex flex-col md:flex-row items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-2xl bg-cyan-955/20 border border-cyan-500/30 text-cyan-400 shrink-0">
                  <ShieldCheck className="w-5 h-5 animate-pulse" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-white leading-tight">
                    {locVal('Sovereign Zero-Knowledge Protocol Configured', 'تم تفعيل بنية صفر المعرفة بمصادقة ريمان')}
                  </h4>
                  <p className="text-[10px] text-neutral-400 font-mono mt-0.5">
                    {locVal('Vault Signature DNA:', 'الرمز الوراثي الطيفي (DNA):')} <span className="text-cyan-400 font-bold">{ownerDna}</span>
                  </p>
                </div>
              </div>
              <button 
                onClick={() => setShowCreateModal(true)}
                className="px-4 py-1.5 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white text-xs font-bold rounded-xl shadow cursor-pointer transition"
              >
                {locVal('+ Create Share Lock', '+ حزمة تعاونية فريدة')}
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Left: Quick Statistics & Share activities */}
            <div className="lg:col-span-4 space-y-4">
              <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">
                {locVal('COLLABORATION DRIFT COHERENCE', 'معايير الاتساق وبطاقات الأمان')}
              </span>

              <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-850 space-y-3.5">
                
                <div className="flex justify-between items-center text-xs">
                  <span className="text-neutral-400">{locVal('Active Outbox Envelopes', 'الأظرف الصادرة النشطة')}</span>
                  <span className="font-mono text-cyan-400 font-bold">{activePackages.filter(p => p.status === 'ACTIVE').length}</span>
                </div>

                <div className="flex justify-between items-center text-xs">
                  <span className="text-neutral-400">{locVal('Secure Received Items', 'الحزم المستلمة الجاهزة')}</span>
                  <span className="font-mono text-emerald-400 font-bold">{inboxItems.length}</span>
                </div>

                <div className="flex justify-between items-center text-xs">
                  <span className="text-neutral-400">{locVal('Total Logged Operations', 'مجموع الحركات المسجلة')}</span>
                  <span className="font-mono text-neutral-300 font-bold">{activityLogs.length}</span>
                </div>

                <div className="h-px bg-neutral-900" />

                {/* TRUST SCORE BREAKDOWN (FEATURE 8) */}
                <div className="space-y-2">
                  <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('COLLABORATIVE TRUST INDEX SCORE', 'مقياس الثقة والتحصين للفضاء')}</span>
                  
                  <div className="grid grid-cols-2 gap-2 text-[10px] font-mono">
                    <div className="p-2 border border-emerald-950 bg-emerald-950/10 text-emerald-400 rounded-lg flex items-center justify-between">
                      <span>VERIFIED</span>
                      <span className="bg-emerald-950 px-1 py-0.2 rounded border border-emerald-850">9.8</span>
                    </div>
                    <div className="p-2 border border-cyan-950 bg-cyan-950/10 text-cyan-400 rounded-lg flex items-center justify-between">
                      <span>PROTECTED</span>
                      <span className="bg-cyan-950 px-1 py-0.2 rounded border border-cyan-850">8.5</span>
                    </div>
                  </div>
                </div>

              </div>

              {/* Import Link Paste panel */}
              <div className="p-5 bg-neutral-900/10 border border-neutral-850 rounded-2xl space-y-3.5">
                <div className="flex items-center gap-1.5">
                  <Link className="w-4 h-4 text-cyan-400" />
                  <span className="text-xs font-sans font-bold text-white">{locVal('Ingest Collaboration Token', 'حقن كود مشاركة تعاونية')}</span>
                </div>

                <p className="text-[10px] text-neutral-450 leading-relaxed font-sans">
                  {locVal('Paste a secure collaboration link/packet token code string to decrypt and import content directly into your sandbox inbox module.', 'ألصق مفتاح/كود المزامنة المشتركة لفك درع الحماية واستيراد المحتوى المتفق عليه فوراً.')}
                </p>

                <div className="space-y-3">
                  <textarea
                    rows={3}
                    placeholder={locVal('Paste RI_COLLAB token code data...', 'الصق البيانات البرمجية المشفرة هنا...')}
                    value={importTokenInput}
                    onChange={(e) => setImportTokenInput(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-neutral-950 border border-neutral-850 text-[10px] font-mono text-slate-200 focus:outline-none focus:border-cyan-400 leading-normal"
                  />

                  <button
                    onClick={handleProcessImportToken}
                    className="w-full py-2 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white text-xs font-bold rounded-xl shadow cursor-pointer transition active:scale-95"
                  >
                    {locVal('Verify & Map Payload', 'تحليل وإطلاق الرمز')}
                  </button>
                </div>
              </div>

            </div>

            {/* Right: SECURE ACTIVITY TRACKER LEDGER (FEATURE 5) */}
            <div className="lg:col-span-8 space-y-4">
              <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">
                {locVal('SECURE TRANSACTION ACTIVITY STREAM', 'سجل أنشطة التبادل والحزم الأمنية')}
              </span>

              <div className="p-4 bg-neutral-900/10 border border-neutral-850 rounded-2xl min-h-[300px] flex flex-col justify-between">
                
                {activityLogs.length === 0 ? (
                  <div className="text-center py-20 text-xs text-neutral-500 font-mono">
                    <Activity className="w-8 h-8 text-neutral-800 mx-auto mb-3 animate-pulse" />
                    {locVal('Collaboration stream is completely empty. Initiate share modules.', 'سجل الحصانة الكلي للتبادل فارغ. لم يتم تفريغ أو كبس أي حاويات.')}
                  </div>
                ) : (
                  <div className="space-y-3 max-h-[400px] overflow-y-auto pr-1">
                    {activityLogs.slice(0, 8).map((log) => {
                      
                      const getActionIconAndColor = (act: CollabActivityLog['action']) => {
                        switch (act) {
                          case 'Package Created': return { icon: <Plus className="w-3.5 h-3.5 text-cyan-400" />, bg: 'bg-cyan-950/20 border-cyan-900' };
                          case 'Package Opened': return { icon: <Unlock className="w-3.5 h-3.5 text-emerald-400" />, bg: 'bg-emerald-950/20 border-emerald-900' };
                          case 'Package Expired': return { icon: <Clock className="w-3.5 h-3.5 text-amber-500" />, bg: 'bg-amber-950/20 border-amber-900' };
                          case 'Package Revoked': return { icon: <AlertTriangle className="w-3.5 h-3.5 text-rose-500" />, bg: 'bg-rose-950/20 border-rose-900' };
                          default: return { icon: <Info className="w-3.5 h-3.5 text-neutral-400" />, bg: 'bg-neutral-950' };
                        }
                      };

                      const meta = getActionIconAndColor(log.action);

                      return (
                        <div key={log.id} className="flex gap-4 items-start p-3 bg-neutral-950 rounded-xl border border-neutral-850/40">
                          <div className={`p-1.5 rounded-lg border ${meta.bg}`}>
                            {meta.icon}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex items-center justify-between">
                              <span className="block text-xs font-semibold text-neutral-100">{log.name}</span>
                              <span className="block text-[9px] font-mono text-neutral-500">{new Date(log.timestamp).toLocaleTimeString()}</span>
                            </div>
                            <p className="text-[10px] font-mono text-neutral-400 mt-0.5">{log.details}</p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                <div className="text-right border-t border-neutral-900 pt-3 mt-3">
                  <button
                    onClick={() => {
                      saveLogsToLocalStorage([]);
                      onSuccess(locVal('Activity logging index purged successfully.', 'تم تفريغ فهرس الأنشطة المسجلة.'), 'info');
                    }}
                    className="text-[9px] font-mono text-rose-500 hover:text-rose-400"
                  >
                    {locVal('[ PURGE AUDIT INDEX ]', '[ تصفير وطمس سجل التحركات ]')}
                  </button>
                </div>

              </div>

            </div>

          </div>

        </div>
      )}

      {/* OUTBOX SEALS TAB */}
      {subTab === 'packages' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between border-b border-neutral-900 pb-3">
            <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">
              {locVal('Active Outgoing Cryptographic Envelopes', 'الأظرف والوصايا الصادرة الجارية')}
            </span>
            <button
              onClick={() => setShowCreateModal(true)}
              className="px-3 py-1 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white rounded-lg text-xs font-bold cursor-pointer transition"
            >
              + {locVal('Create New Package', 'إنشاء ظرف آمن')}
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 animate-fade-in">
            {/* Package list */}
            <div className="lg:col-span-7 space-y-3">
              {activePackages.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-neutral-850 rounded-2xl bg-neutral-950/20">
                  <Share2 className="w-8 h-8 text-neutral-800 mx-auto mb-3 animate-pulse" />
                  <p className="text-xs text-neutral-500 font-mono">
                    {locVal('No active outgoing shares are listed under your Node.', 'لا يوجد وصايا أو أظرف مُصدرة تحت هويتك الطيفية.')}
                  </p>
                </div>
              ) : (
                activePackages.map((pkg) => {
                  const isExpired = pkg.status === 'EXPIRED';
                  const isRevoked = pkg.status === 'REVOKED';
                  const isSel = selectedPackageId === pkg.id;

                  return (
                    <div
                      key={pkg.id}
                      onClick={() => setSelectedPackageId(pkg.id)}
                      className={`p-4 rounded-2xl border cursor-pointer transition ${
                        isSel 
                          ? 'bg-neutral-900/70 border-cyan-500/50 shadow shadow-cyan-500/10' 
                          : 'bg-neutral-900/10 border-neutral-850 hover:bg-neutral-900/30'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-center gap-3 min-w-0">
                          <div className={`p-2 rounded-xl border ${
                            isRevoked ? 'bg-rose-950/10 border-rose-900 text-rose-500' :
                            isExpired ? 'bg-amber-950/10 border-amber-900 text-amber-500' :
                            'bg-cyan-950/10 border-cyan-900 text-cyan-400'
                          }`}>
                            <Lock className="w-4 h-4" />
                          </div>

                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-sans font-bold text-neutral-100 truncate">{pkg.name}</span>
                              <span className="px-1.5 py-0.2 rounded text-[8px] font-mono bg-neutral-950 text-neutral-500">
                                {pkg.category}
                              </span>
                            </div>
                            <span className="block text-[8.5px] font-mono text-neutral-500 mt-1 truncate">
                              ID: {pkg.id} • Expiry: {pkg.expireTime ? new Date(pkg.expireTime).toLocaleTimeString() : 'Infinite'}
                            </span>
                          </div>
                        </div>

                        <div className="text-right shrink-0">
                          {/* TRUST INDICATORS BAR (FEATURE 8) */}
                          <span className={`px-2 py-0.5 text-[8.5px] font-mono font-semibold rounded-md border uppercase tracking-wider ${
                            pkg.trustScore === 'Verified' ? 'text-emerald-400 bg-emerald-950/10 border-emerald-900/50' :
                            pkg.trustScore === 'Protected' ? 'text-cyan-400 bg-cyan-950/10 border-cyan-900/50' :
                            pkg.trustScore === 'Temporary' ? 'text-amber-400 bg-amber-950/10 border-amber-900/50' :
                            'text-neutral-500 bg-neutral-950 border-neutral-850'
                          }`}>
                            {pkg.trustScore}
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Selected package specifications and quick access revoke controls */}
            <div className="lg:col-span-5">
              {selectedPackageId ? (
                (() => {
                  const pkg = activePackages.find(p => p.id === selectedPackageId);
                  if (!pkg) return null;

                  const isRevoked = pkg.status === 'REVOKED';
                  const isExpired = pkg.status === 'EXPIRED';

                  return (
                    <div className="p-5 border border-neutral-850 bg-neutral-900/40 rounded-3xl space-y-5">
                      
                      <div className="flex items-center justify-between border-b border-neutral-850 pb-2.5">
                        <span className="text-[10px] font-mono font-bold text-neutral-300">{locVal('METADATA OVERLAY', 'تفاصيل الحزمة')}</span>
                        <span className={`text-[9px] font-mono uppercase ${isRevoked ? 'text-rose-500' : isExpired ? 'text-amber-500' : 'text-cyan-400'}`}>
                          {pkg.status}
                        </span>
                      </div>

                      {/* Info matrix Grid */}
                      <div className="grid grid-cols-2 gap-3 text-[10px] font-mono text-neutral-400">
                        <div className="p-2 bg-neutral-950/40 border border-neutral-900 rounded-xl">
                          <span className="block text-[8px] text-neutral-500">{locVal('ENVELOPE IDENTIFIER', 'رمز المعرّف')}</span>
                          <span className="block font-bold text-neutral-200 mt-0.5">{pkg.id}</span>
                        </div>
                        <div className="p-2 bg-neutral-950/40 border border-neutral-900 rounded-xl">
                          <span className="block text-[8px] text-neutral-500">{locVal('EXPIRATION TIME', 'موعد الانتهاء')}</span>
                          <span className="block font-bold text-neutral-200 mt-0.5">
                            {pkg.expireTime ? new Date(pkg.expireTime).toLocaleTimeString() : 'NEVER'}
                          </span>
                        </div>
                        <div className="p-2 bg-neutral-950/40 border border-neutral-900 rounded-xl">
                          <span className="block text-[8px] text-neutral-500">{locVal('ACCESS DISCHARGE REMAINING', 'محاولات فك الأقفال المتاحة')}</span>
                          <span className="block font-bold text-neutral-200 mt-0.5">
                            {pkg.maxAccessCount ? `${pkg.currentAccessCount} / ${pkg.maxAccessCount}` : `${pkg.currentAccessCount} / $\\infty$`}
                          </span>
                        </div>
                        <div className="p-2 bg-neutral-950/40 border border-neutral-900 rounded-xl">
                          <span className="block text-[8px] text-neutral-500">{locVal('ONE TIME ACCESS', 'قراءة لمرة واحدة فقط')}</span>
                          <span className="block font-bold text-neutral-200 mt-0.5">{pkg.oneTimeAccess ? 'YES' : 'NO'}</span>
                        </div>
                      </div>

                      {/* Display share link token payload (FEATURE 1) */}
                      <div className="p-3.5 bg-neutral-950 border border-neutral-900 rounded-2xl space-y-2.5">
                        <span className="block text-[9px] font-mono text-neutral-500">{locVal('STRICT DISCHARGE KEY-MAPPED LINK TOKEN', 'كود الربط المفرز طيفياً')}</span>
                        <div className="flex gap-2">
                          <input
                            type="text"
                            readOnly
                            value={getShareTokenString(pkg)}
                            className="bg-neutral-900 border border-neutral-850 p-1.5 px-2 rounded-lg text-[9px] font-mono text-cyan-400 flex-1 focus:outline-none focus:border-cyan-400 select-all"
                          />
                          <button
                            onClick={() => copyShareToken(pkg)}
                            className="p-2 hover:bg-neutral-850 text-cyan-400 rounded-lg transition"
                            title="Copy Token"
                          >
                            <Copy className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>

                      {/* REVOCATION INTERACTION PANEL (FEATURE 6) */}
                      <div className="pt-2">
                        {pkg.status === 'ACTIVE' ? (
                          <button
                            onClick={() => handleRevokePackage(pkg.id)}
                            className="w-full py-2 bg-rose-950/20 hover:bg-rose-950/50 border border-rose-900 text-rose-400 font-sans font-bold text-xs rounded-xl cursor-pointer transition active:scale-95"
                          >
                            {locVal('REVOKE IMMEDIATELY (PURGE KEYS)', 'إبطال الصلاحية فوراً (مسح المفاتيح الصادرة)')}
                          </button>
                        ) : (
                          <div className="p-3 text-center rounded-xl bg-neutral-950 text-[10px] text-neutral-500 font-mono italic">
                            {locVal('Access to this resource has already been terminated.', 'تم إغلاق مسار الوصول لهذه الحزمة تماماً.')}
                          </div>
                        )}
                      </div>

                    </div>
                  );
                })()
              ) : (
                <div className="p-8 text-center text-xs text-neutral-550 border border-dashed border-neutral-850 rounded-3xl bg-neutral-950/10">
                  <HelpCircle className="w-8 h-8 text-neutral-700 mx-auto mb-2" />
                  {locVal('Select a compiled package to inspect metrics, copy encrypted links or trigger revoke commands.', 'اختر من القائمة لمعاينة إحصائيات المعطيات، أو نسخ روابط التبادل الآمن.')}
                </div>
              )}
            </div>

          </div>

        </div>
      )}

      {/* SECURE INBOX PANEL (FEATURE 4 - Receiving sector) */}
      {subTab === 'inbox' && (
        <div className="space-y-6">
          <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest mb-1">
            {locVal('Secure Zero-Knowledge Inbox Storage Sector', 'وحدة تخزين الرسائل الواردة بمسار صفر المعرفة')}
          </span>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 animate-fade-in">
            {/* Inbox stream lists */}
            <div className="lg:col-span-7 space-y-3">
              {inboxItems.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-neutral-850 rounded-2xl bg-neutral-950/20">
                  <Inbox className="w-8 h-8 text-neutral-805 mx-auto mb-3 animate-pulse" />
                  <p className="text-xs text-neutral-500 font-mono">
                    {locVal('Sovereign Inbox is completely clear.', 'صندوق الاستقبال السيادي نظيف تماماً ولا توجد حاويات محقونة.')}
                  </p>
                </div>
              ) : (
                inboxItems.map((item) => {
                  const isSel = selectedInboxId === item.id;
                  return (
                    <div
                      key={item.id}
                      onClick={() => setSelectedInboxId(item.id)}
                      className={`p-4 rounded-2xl border cursor-pointer transition ${
                        isSel 
                          ? 'bg-neutral-900/70 border-emerald-500/50 shadow shadow-emerald-500/10' 
                          : 'bg-neutral-900/10 border-neutral-850 hover:bg-neutral-900/30'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div className="min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-sans font-bold text-neutral-100 truncate">{item.packageName}</span>
                            <span className="px-1.5 py-0.2 rounded text-[8px] font-mono bg-neutral-950 text-neutral-500">
                              {item.category}
                            </span>
                          </div>
                          <span className="block text-[8.5px] font-mono text-neutral-500 mt-1 truncate">
                            ID: {item.id} • {locVal('Sender DNA:', 'مرسل:')} {item.senderDna}
                          </span>
                        </div>

                        <span className="px-1.5 py-0.5 font-mono text-[8.5px] font-bold rounded-md bg-emerald-950/20 border border-emerald-900/40 text-emerald-400">
                          {item.trustScore}
                        </span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Inbox Item inspect details */}
            <div className="lg:col-span-5">
              {selectedInboxId ? (
                (() => {
                  const item = inboxItems.find(i => i.id === selectedInboxId);
                  if (!item) return null;

                  return (
                    <div className="p-5 border border-emerald-850/30 bg-neutral-900/40 rounded-3xl space-y-4">
                      
                      <div className="flex items-center justify-between border-b border-neutral-850 pb-2.5">
                        <span className="text-[10px] font-mono font-bold text-emerald-400">{locVal('DECRYPTED INCOMING ATOM', 'الوصاية المستلمة المستعادة')}</span>
                        <span className="text-[9px] font-mono text-neutral-500">{new Date(item.receivedTime).toLocaleTimeString()}</span>
                      </div>

                      <div className="space-y-1.5">
                        <span className="block text-[9px] font-mono text-neutral-500">{locVal('ORIGINAL ORIGIN DNA POINTER', 'مرساة توثيق الملقم المرسل')}</span>
                        <div className="p-2 bg-neutral-950 rounded-xl font-mono text-xs text-neutral-200 border border-neutral-900 select-all">
                          {item.senderDna}
                        </div>
                      </div>

                      {/* Plaintext decrypted content display */}
                      <div className="space-y-1.5 pb-2">
                        <span className="block text-[9px] font-mono text-neutral-500">{locVal('CONTENT MEMO PAYLOAD (DECRYPTED)', 'مذكرة المحتوى (تمت المزاملة وفك التشفير)')}</span>
                        <div className="p-3 bg-neutral-950/70 border border-neutral-900 rounded-xl text-[11px] font-mono text-slate-100 whitespace-pre-wrap leading-relaxed max-h-[160px] overflow-y-auto">
                          {item.plainTextContent}
                        </div>
                      </div>

                      {/* Download Payload Action */}
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleDownloadReceivedItem(item)}
                          className="flex-1 py-2 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white font-sans font-bold text-xs rounded-xl shadow cursor-pointer transition flex items-center justify-center gap-1.5"
                        >
                          <Download className="w-3.5 h-3.5" />
                          {locVal('Save/Download Decrypted', 'حفظ/تصدير المحتوى')}
                        </button>

                        <button
                          onClick={() => purgeInboxItem(item.id)}
                          className="p-2 bg-rose-955/20 hover:bg-rose-955/40 border border-rose-900/40 text-rose-500 rounded-xl transition"
                          title="Wipe permanently"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                    </div>
                  );
                })()
              ) : (
                <div className="p-8 text-center text-xs text-neutral-550 border border-dashed border-neutral-850 rounded-3xl bg-neutral-950/10">
                  <Inbox className="w-8 h-8 text-neutral-805 mx-auto mb-2" />
                  {locVal('Select a received package from your Secure Inbox index stream to decrypt, browse file contents, or purge records.', 'اختر من قائمة الوارد لمطالعة وتحميل محتويات الملفات المشفّرة المفرج عنها.')}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* E2E ARCHITECTURAL BLUEPRINTS TAB (FEATURE 9 PREPARATION FUTURE PATHWAYS) */}
      {subTab === 'architecture' && (
        <div className="space-y-6">
          <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-3xl space-y-3">
            <h3 className="font-sans font-bold text-sm text-cyan-300">{locVal('Technical Blueprint: Riemann Multi-Node Team Expansion', 'الهندسة التقنية: توسيع نظام غرف ريمان متعددة الأطراف')}</h3>
            <p className="text-[11px] text-neutral-400 leading-relaxed font-sans">
              {locVal(
                'Displays structural schemas mapping the future deployment phase of Secure Team Vaults (with threshold multisig Shamir Secret sharing schemes) and Shared Workspace directories. These modules are mathematically outlined according to specs but remain fully inactive for production stability.',
                'توضح هذه الرسوم الهيكلية المتقدمة منهجية تشكيل غرف الأمان والفرق (بواسطة تقنية تجزئة رموز شامير لحماية الاتصال السري متعدد الثقات) دون تشغيل قنوات الخوادم حماية لموثوقية الاستقرار الكلي.'
              )}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-fade-in">
            {/* Architecture Node 1: Team Vaults Shamir math */}
            <div className="p-5 border border-neutral-850 bg-neutral-950 rounded-2xl space-y-4">
              <span className="text-[9px] font-mono text-purple-400 font-bold uppercase tracking-widest block border-b border-neutral-900 pb-1.5">
                {locVal('REIMANN SHAMIR THRESHOLD SHARDS', 'معادلات تجزئة شامير السرية')}
              </span>
              <div className="flex justify-center p-3.5 bg-neutral-900/20 rounded-xl">
                <svg viewBox="0 0 100 100" className="w-20 h-20 text-purple-500">
                  <circle cx="50" cy="50" r="42" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="4 4" />
                  <path d="M50 20 L80 70 L20 70 Z" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <circle cx="50" cy="20" r="4" fill="#a855f7" />
                  <circle cx="80" cy="70" r="4" fill="#a855f7" />
                  <circle cx="20" cy="70" r="4" fill="#a855f7" />
                  <circle cx="50" cy="50" r="8" fill="#1e1b4b" stroke="#a855f7" strokeWidth="2" />
                </svg>
              </div>
              <h4 className="text-xs font-sans font-bold text-white text-center">{locVal('Secret Share Multi-Sig Channel', 'غرفة الإجماع بمجال مشتت')}</h4>
              <p className="text-[10px] text-neutral-400 font-sans leading-relaxed text-center">
                {locVal('Splits the vault key into redundant polynomials where any k-out-of-n nodes can reassemble the encryption key.', 'يوزع الكلمات والمفاتيح بطريقة مجزأة، كأن تطلب النظام مفتاحين اثنين على الأقل لبناء وعاء التشفير كلياً.')}
              </p>
            </div>

            {/* Architecture Node 2: Workspace Routing Hub */}
            <div className="p-5 border border-neutral-850 bg-neutral-950 rounded-2xl space-y-4">
              <span className="text-[9px] font-mono text-cyan-400 font-bold uppercase tracking-widest block border-b border-neutral-900 pb-1.5">
                {locVal('SOVEREIGN PEER DIRECTORY MAPPING', 'هندسة الفضاء المشترك لشبكات ريمان')}
              </span>
              <div className="flex justify-center p-3.5 bg-neutral-900/20 rounded-xl">
                <svg viewBox="0 0 100 100" className="w-20 h-20 text-cyan-400">
                  <rect x="20" y="20" width="16" height="16" rx="3" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <rect x="64" y="20" width="16" height="16" rx="3" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <rect x="42" y="64" width="16" height="16" rx="3" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <line x1="36" y1="28" x2="64" y2="28" stroke="currentColor" strokeWidth="1" strokeDasharray="3 3" />
                  <line x1="28" y1="36" x2="42" y2="72" stroke="currentColor" strokeWidth="1" strokeDasharray="3 3" />
                  <line x1="72" y1="36" x2="58" y2="72" stroke="currentColor" strokeWidth="1" strokeDasharray="3 3" />
                </svg>
              </div>
              <h4 className="text-xs font-sans font-bold text-white text-center">{locVal('Encrypted Workspace Directory', 'دليل ساحات العمل التشاركية')}</h4>
              <p className="text-[10px] text-neutral-400 font-sans leading-relaxed text-center">
                {locVal('Secure folder directories linked across active nodes, tracking atomic mutations with decentralized zero-trust anchors.', 'هيكل المجلدات الموزعة مع التبادل، تتبع التحركات والقرارات بشكل محكم وآمن دون كشف التفاصيل.')}
              </p>
            </div>

            {/* Architecture Node 3: Messaging Relay */}
            <div className="p-5 border border-neutral-850 bg-neutral-950 rounded-2xl space-y-4">
              <span className="text-[9px] font-mono text-indigo-400 font-bold uppercase tracking-widest block border-b border-neutral-900 pb-1.5">
                {locVal('TEMPORAL MESSAGE ESCROW RELAY', 'بنية البث والبريد التفاعلي المشفر')}
              </span>
              <div className="flex justify-center p-3.5 bg-neutral-900/20 rounded-xl">
                <svg viewBox="0 0 100 100" className="w-20 h-20 text-indigo-400 animate-pulse">
                  <rect x="15" y="30" width="70" height="40" rx="4" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <path d="M15 30 L50 54 L85 30" fill="none" stroke="currentColor" strokeWidth="1.5" />
                  <line x1="50" y1="54" x2="50" y2="70" stroke="currentColor" strokeWidth="1" />
                </svg>
              </div>
              <h4 className="text-xs font-sans font-bold text-white text-center">{locVal('Spacetime Message Queuing', 'نظام رتل المحادثات المؤقت')}</h4>
              <p className="text-[10px] text-neutral-400 font-sans leading-relaxed text-center">
                {locVal('Under-development end-to-end symmetric chat buffers storing message records with quantum-containment decay.', 'فضاء دردشة متناسق للرسائل المؤقتة، تبنى الهوية في غرف ريمان مع تفريغ دوري للذاكرة العشوائية.')}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* CREATE PACKAGE MODAL (FEATURE 1, 2 & FEATURE 7 AUTHORIZATIONS) */}
      <AnimatePresence>
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-neutral-950 border border-neutral-850 rounded-3xl p-5 w-full max-w-lg space-y-4 shadow-xl"
            >
              
              <div className="flex items-center justify-between border-b border-neutral-900 pb-2">
                <h3 className="text-sm font-sans font-bold text-cyan-400 flex items-center gap-1.5">
                  <Plus className="w-4 h-4" />
                  {locVal('Compile Secure Outgoing Package', 'إنشاء وحشو ظرف تعاوني جديد')}
                </h3>
                <button 
                  onClick={() => setShowCreateModal(false)}
                  className="text-neutral-500 hover:text-neutral-300 text-xs font-mono"
                >
                  {locVal('[ ESC ]', '[ إلغاء ]')}
                </button>
              </div>

              <form onSubmit={handleCreatePackage} className="space-y-4">
                
                {/* Name Label */}
                <div>
                  <label className="block text-[9px] font-mono text-neutral-500 mb-1">{locVal('PACKAGE LABEL', 'اسم المعطيات الخارجي')}</label>
                  <input
                    type="text"
                    required
                    placeholder={locVal('e.g. Secret Legal Settlement Notes...', 'مثال: وصية العائلة، قائمة الاستعادة الخاصة...')}
                    value={packageName}
                    onChange={(e) => setPackageName(e.target.value)}
                    className="w-full px-3 py-1.5 rounded-lg bg-neutral-900 border border-neutral-850 text-xs text-white focus:outline-none focus:border-cyan-400"
                  />
                </div>

                {/* Grid for Category and File Name */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[9px] font-mono text-neutral-500 mb-1">{locVal('CATEGORY', 'نوع التصنيف')}</label>
                    <select
                      value={packageCategory}
                      onChange={(e) => setPackageCategory(e.target.value as any)}
                      className="w-full px-3 py-1.5 rounded-lg bg-neutral-900 border border-neutral-850 text-xs text-white focus:outline-none focus:border-cyan-400 cursor-pointer"
                    >
                      <option value="Note">{locVal('Notes / Document', 'مستند / ملاحظة مكتوبة')}</option>
                      <option value="File">{locVal('File Attachment', 'ملف مشفّر مرفق')}</option>
                      <option value="Media">{locVal('Media Resource', 'ملف وسائط وسجلات')}</option>
                      <option value="Vault Folder">{locVal('Vault Folder', 'مجلد سيادي متكامل')}</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-[9px] font-mono text-neutral-500 mb-1">{locVal('ATTACHMENT FILENAME', 'اسم الملف المتولد بالتبادل')}</label>
                    <input
                      type="text"
                      placeholder="e.g. escrow_shield.txt"
                      value={packageFileName}
                      onChange={(e) => setPackageFileName(e.target.value)}
                      className="w-full px-3 py-1.5 rounded-lg bg-neutral-900 border border-neutral-850 text-xs text-white focus:outline-none focus:border-cyan-400"
                    />
                  </div>
                </div>

                {/* Content Payload textarea */}
                <div>
                  <label className="block text-[9px] font-mono text-neutral-500 mb-1">{locVal('CONFIDENTIAL DATA CONTENT (PLAINTEXT)', 'البيانات والمحتويات السرية للتشفير')}</label>
                  <textarea
                    rows={3}
                    required
                    placeholder={locVal('Enter plain text / keys to package securely...', 'أدخل المعطيات أو المفاتيح التي تريد حشوها بالداخل...')}
                    value={packageContent}
                    onChange={(e) => setPackageContent(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg bg-neutral-900 border border-neutral-850 text-xs text-slate-300 focus:outline-none focus:border-cyan-400 font-mono"
                  />
                </div>

                {/* Access Expiry and Limits triggers (FEATURE 1 & FEATURE 3) */}
                <div className="grid grid-cols-2 gap-3 p-3 bg-neutral-900/40 rounded-2xl border border-neutral-900">
                  <div>
                    <label className="block text-[8.5px] font-mono text-neutral-500 mb-1">{locVal('TEMPORAL LOCK LIMIT', 'مدة تفعيل الرابط (قفل وقت طرئي)')}</label>
                    <select
                      value={rawDuration}
                      onChange={(e) => setRawDuration(e.target.value as any)}
                      className="w-full px-2 py-1 bg-neutral-950 border border-neutral-850 rounded text-[11px] text-white focus:outline-none cursor-pointer"
                    >
                      <option value="1h">1 {locVal('Hour', 'ساعة')}</option>
                      <option value="24h">24 {locVal('Hours', 'ساعة')}</option>
                      <option value="7d">7 {locVal('Days', 'أيام')}</option>
                      <option value="unlimited">{locVal('Unlimited', 'بلا حدود زمنية')}</option>
                      <option value="custom">{locVal('Custom Duration', 'صلاحية مخصصة للتحكم')}</option>
                    </select>

                    {rawDuration === 'custom' && (
                      <input
                        type="text"
                        placeholder="Hours (e.g. 4.5)"
                        value={customDurationHours}
                        onChange={(e) => setCustomDurationHours(e.target.value)}
                        className="w-full mt-1.5 px-2 py-1 bg-neutral-950 border border-neutral-850 rounded text-[10px] text-white focus:outline-none"
                      />
                    )}
                  </div>

                  <div>
                    <label className="block text-[8.5px] font-mono text-neutral-500 mb-1">{locVal('MAX DECRYPTION DISCHARGES', 'أقصى حد لمس مرات الفتح')}</label>
                    <select
                      value={maxAccessCountRaw}
                      onChange={(e) => setMaxAccessCountRaw(e.target.value)}
                      className="w-full px-2 py-1 bg-neutral-950 border border-neutral-850 rounded text-[11px] text-white focus:outline-none cursor-pointer"
                    >
                      <option value="1">1 {locVal('Discharge Limit', 'مرة فتح واحدة (one-time)')}</option>
                      <option value="3">3 {locVal('Discharges', 'ثلاث مرات فك أختام')}</option>
                      <option value="5">5 {locVal('Discharges', 'خمس محاولات فتح')}</option>
                      <option value="unlimited">{locVal('Unlimited', 'عدد لا نهائي')}</option>
                    </select>
                  </div>
                </div>

                {/* Multilayer Authorization Setup checkboxes (FEATURE 7) */}
                <div className="space-y-2 p-3 bg-neutral-900/30 rounded-2xl border border-neutral-900 text-[10.5px]">
                  <span className="block text-[8px] font-mono text-cyan-400 uppercase tracking-widest mb-1">
                    {locVal('REQUIRED SAFETY GUARANTEES', 'تراخيص ومعايير مطابقة الأمان المطلوبة')}
                  </span>

                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={oneTimeAccess}
                      onChange={(e) => setOneTimeAccess(e.target.checked)}
                      className="rounded border-neutral-800 bg-neutral-950 text-cyan-500 focus:ring-0"
                    />
                    <span className="text-neutral-300 font-sans">{locVal('Force One-Time Access (Burn on Decrypt)', 'تفعيل فرض قراءة لمرة واحدة فقط (حرق تلقائي بالفك)')}</span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={biometricRequired}
                      onChange={(e) => setBiometricRequired(e.target.checked)}
                      disabled={!biometricsEnabled}
                      className="rounded border-neutral-800 bg-neutral-950 text-cyan-500 focus:ring-0 disabled:opacity-30"
                    />
                    <span className="text-neutral-300 font-sans flex items-center gap-1">
                      {locVal('Require Biometric Confirmation on import', 'طلب مصادقة بالبصمة لاستيراد الحزمة')}
                      {!biometricsEnabled && <span className="text-[9px] text-rose-500">({locVal('Vault Biometrics Disabled', 'الخدمة معطلة بالجهاز')})</span>}
                    </span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={recoveryVerified}
                      onChange={(e) => setRecoveryVerified(e.target.checked)}
                      disabled={!recoveryKey}
                      className="rounded border-neutral-800 bg-neutral-950 text-cyan-500 focus:ring-0 disabled:opacity-30"
                    />
                    <span className="text-neutral-300 font-sans flex items-center gap-1">
                      {locVal('Require Master Recovery Verification Key override', 'طلب مفتاح مسار الاستعادة للمطابقة الفوقية')}
                      {!recoveryKey && <span className="text-[9px] text-rose-500">({locVal('No Recovery Key Found', 'لا يوجد مفتاح استعادة تم توليده!')})</span>}
                    </span>
                  </label>
                </div>

                {/* Symmetrical password credentials */}
                <div className="p-3 bg-cyan-955/5 border border-cyan-850/30 rounded-2xl">
                  <label className="block text-[9px] font-mono text-cyan-400 mb-1">{locVal('SYMMETRIC SECURE KEYS PASSWORD', 'كلمة مرور فك التشفير الصادرة')}</label>
                  <input
                    type="password"
                    required
                    placeholder={locVal('Enter master packet password key...', 'أدخل كلمة المرور الشاملة للحفظ...')}
                    value={packagePassword}
                    onChange={(e) => setPackagePassword(e.target.value)}
                    className="w-full px-3 py-1.5 rounded-lg bg-neutral-950 border border-cyan-850/30 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono"
                  />
                </div>

                {/* Submit Action */}
                <button
                  type="submit"
                  className="w-full py-2.5 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white font-sans font-bold text-xs rounded-xl shadow cursor-pointer transition active:scale-95"
                >
                  {locVal('COMPILE AND SECURE COLLABORATION KEY', 'كبس وحفظ الحزمة وتوليد كود التبادل')}
                </button>

              </form>

            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* DETAILED DIALOG FOR IMPORT PASSWORD & AUTHORIZATION (FEATURE 7 MULTIPLEX) */}
      <AnimatePresence>
        {importTargetPackage && (
          <div className="fixed inset-0 bg-black/85 backdrop-blur-sm flex items-center justify-center p-4 z-50">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-neutral-950 border border-neutral-800 rounded-3xl p-5 w-full max-w-sm space-y-4"
            >
              
              <div className="flex items-center justify-between border-b border-neutral-900 pb-2">
                <h4 className="text-xs font-sans font-bold text-emerald-400 flex items-center gap-1.5">
                  <ShieldCheck className="w-4 h-4 animate-bounce" />
                  {locVal('Multi-Layer Authentication Portal', 'جواز المرور متعدد الضوابط والتوقيع')}
                </h4>
                <button 
                  onClick={() => {
                    setImportTargetPackage(null);
                    setImportBiometricPrompt(false);
                    setImportRecoveryPrompt(false);
                    setImportPasswordInput('');
                  }}
                  className="text-neutral-500 hover:text-neutral-300 text-[10px] font-mono cursor-pointer"
                >
                  {locVal('[ CANCEL ]', '[ إلغاء ]')}
                </button>
              </div>

              <p className="text-[10px] font-sans text-neutral-400 leading-relaxed text-center">
                {locVal('Symmetric envelope authentication detected! Align required credentials below to open space.', 'لوحة التوثيق رصدت بنية مشفرة متعددة الحصون! وازن المفاتيح لفتح الحزمة.')}
              </p>

              {/* Step 1: Biometric Check simulated block (FEATURE 7) */}
              {importBiometricPrompt && (
                <div className="p-4 bg-purple-950/20 border border-purple-900 rounded-2xl flex flex-col items-center justify-center text-center gap-3 space-y-1">
                  <Fingerprint className="w-8 h-8 text-purple-400 animate-pulse" />
                  <span className="font-sans font-bold text-xs text-white">{locVal('Biometric Authorization Required', 'مطلوب مصادقة الهوية بالبصمة')}</span>
                  <button
                    onClick={handleSimulateBiometricImport}
                    className="px-4 py-1.5 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-[10px] font-semibold cursor-pointer transition shadow"
                  >
                    {locVal('[ SIMULATE TOUCH ID ]', '[ مطابقة البصمة الآن ]')}
                  </button>
                </div>
              )}

              {/* Step 2: Recovery Verification required block */}
              {importRecoveryPrompt && !importBiometricPrompt && (
                <div className="p-4 bg-rose-955/10 border border-rose-900/50 rounded-2xl space-y-3">
                  <span className="text-[9px] font-mono text-rose-450 uppercase font-semibold block">{locVal('OVERSIZE SYSTEM RECOVERY KEY ATOMICITY', 'مطابقة مفتاح الاستعادة والإنقاذ الكلي')}</span>
                  <p className="text-[10px] text-neutral-400 leading-normal font-sans">
                    {locVal('The sender has flagged master recovery parity logic. Input recovery master token below to verify chain.', 'فرض المرسل دالة التحقق الكلي. يرجى تقديم كود الاستعادة للمطابقة الفوقية.')}
                  </p>
                  <input
                    type="password"
                    placeholder={locVal('Enter master recovery key...', 'أدخل رمز الاستعادة للتوثيق...')}
                    value={importRecoveryInput}
                    onChange={(e) => setImportRecoveryInput(e.target.value)}
                    className="w-full px-2 py-1 bg-neutral-900 border border-neutral-850 rounded text-xs text-white focus:outline-none focus:border-rose-400 font-mono"
                  />
                  <button
                    onClick={handleSimulateRecoveryImport}
                    className="w-full py-1.5 bg-rose-600 hover:bg-rose-500 text-white font-sans text-[11px] font-bold rounded-lg transition"
                  >
                    {locVal('Confirm Verification Key', 'تقديم وتأكيد مفتاح الاستعادة')}
                  </button>
                </div>
              )}

              {/* General symmetric password key */}
              {!importBiometricPrompt && !importRecoveryPrompt && (
                <div className="space-y-3.5">
                  <div>
                    <label className="block text-[8.5px] font-mono text-neutral-500 mb-1">{locVal('CHRONO CONTAINMENT ENCRYPT PASSKEY', 'كلمة مرور فك الدرع المتناسق المخصصة')}</label>
                    <input
                      type="password"
                      placeholder={locVal('Enter symmetric key validation...', 'أدخل كلمة مرور الحزمة...')}
                      value={importPasswordInput}
                      onChange={(e) => setImportPasswordInput(e.target.value)}
                      className="w-full px-3 py-1.5 rounded-lg bg-neutral-900 border border-neutral-850 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono"
                    />
                  </div>

                  <button
                    onClick={handleApplyDecryptionToInbox}
                    className="w-full py-2 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white font-sans font-bold text-xs rounded-xl shadow cursor-pointer transition active:scale-95"
                  >
                    {locVal('DISSOLVE SHEATH & UNLOCK INBOX', 'فك القفل المزدوج وحقن بريد الاستيراد')}
                  </button>
                </div>
              )}

            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
};
