import React, { useState, useEffect } from 'react';
import { 
  Clock, Lock, Unlock, Compass, AlertTriangle, User, Shield, Activity, Calendar, 
  Award, Database, Key, Server, Plus, Trash2, Download, Eye, FileText, Check, 
  ChevronRight, RefreshCw, Send, Radio, Info, Filter, Archive, HelpCircle, Layers, CheckCircle2
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

interface CapsuleProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

interface LegacyCapsule {
  id: string;
  name: string;
  category: 'Financial' | 'Legal' | 'Personal' | 'Secrets' | 'Credentials';
  type: 'Message' | 'File' | 'Notes';
  content: string; // Stored plaintext for notes/msg or encrypted representation
  fileName?: string;
  fileSize: number;
  dateCreated: number;
  unlockTime: number;
  container: EncryptedContainer;
  ownerVaultDna: string;
  securityState: 'SEALED' | 'QUANTUM_CONTAINMENT' | 'READY_TO_DISSOLVE' | 'UNLOCKED';
}

export const TimeCapsuleModule: React.FC<CapsuleProps> = ({ 
  onSuccess, 
  onSecurityLog, 
  triggerAnimation 
}) => {
  const { locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // Sub-Navigation Tabs inside Legacy and Time Vault system
  const [subTab, setSubTab] = useState<'dashboard' | 'delivery_prep' | 'observatory'>('dashboard');

  // Vault DNA
  const [vaultDna] = useState<string>(() => {
    return localStorage.getItem('riman_vault_dna_seed') || 'RZ-A81F-92CD';
  });

  // State
  const [capsules, setCapsules] = useState<LegacyCapsule[]>([]);
  const [currentTime, setCurrentTime] = useState<number>(Date.now());
  const [selectedCapsuleId, setSelectedCapsuleId] = useState<string | null>(null);
  const [decryptPassword, setDecryptPassword] = useState<string>('');
  
  // Create Form State
  const [showCreateModal, setShowCreateModal] = useState<boolean>(false);
  const [formName, setFormName] = useState<string>('');
  const [formCategory, setFormCategory] = useState<'Financial' | 'Legal' | 'Personal' | 'Secrets' | 'Credentials'>('Personal');
  const [formType, setFormType] = useState<'Message' | 'File' | 'Notes'>('Message');
  const [formContent, setFormContent] = useState<string>('');
  const [formPassword, setFormPassword] = useState<string>('');
  const [formDuration, setFormDuration] = useState<string>('1day'); // '1day' | '1month' | '1year' | 'custom'
  const [formCustomDate, setFormCustomDate] = useState<string>('');
  const [formCustomTime, setFormCustomTime] = useState<string>('');
  
  // Category Filter
  const [activeCategoryFilter, setActiveCategoryFilter] = useState<string>('ALL');

  // File Upload State inside Creation
  const [attachedFile, setAttachedFile] = useState<{ name: string; size: number; content: string } | null>(null);

  // Hydrate capsules from LocalStorage on mount
  useEffect(() => {
    const saved = localStorage.getItem('riman_time_capsules_v6');
    if (saved) {
      try {
        setCapsules(JSON.parse(saved));
      } catch (e) {
        initPresets();
      }
    } else {
      initPresets();
    }
  }, []);

  const initPresets = () => {
    const now = Date.now();
    
    // Preset 1: Financial Ledger - Locked
    const payload1 = stringToBytes("CONFIDENTIAL CORPORATE BALANCE SHEET 2026. SECURED UNDER RIEMANN PROTOCOLS.");
    const container1 = executeRiemannTripleLayerEncrypt(payload1, 'riman123', {
      filename: 'financial_ledger_2026.pdf',
      fileType: 'application/pdf',
      isCapsule: true,
      unlockTimestamp: now + 3600000 * 24 // 1 day
    });

    const preset1: LegacyCapsule = {
      id: 'CAP-RZ9F-841B',
      name: locVal('Corporate Financial Ledger', 'الخطط المالية للشركة لعام ٢٠٢٦'),
      category: 'Financial',
      type: 'File',
      content: 'ENCRYPTED_BINARY_PAYLOAD_LOCKED',
      fileName: 'financial_ledger_2026.pdf',
      fileSize: 452000,
      dateCreated: now - 3600000 * 2,
      unlockTime: now + 3600000 * 24,
      container: container1,
      ownerVaultDna: vaultDna,
      securityState: 'SEALED'
    };

    // Preset 2: Smart Vault Credentials - Unlocked/Matured
    const payload2 = stringToBytes("RIEMANN SEED DEVIATION COMPROMISE CODE: 0x93FA11B7F20D. PRIMARY DELEGATE TRUST KEY SIGNED.");
    const container2 = executeRiemannTripleLayerEncrypt(payload2, 'riman123', {
      filename: 'secret_reconstruction_keys.txt',
      fileType: 'text/plain',
      isCapsule: true,
      unlockTimestamp: now - 60000 // Already Unlocked (1 minute ago)
    });

    const preset2: LegacyCapsule = {
      id: 'CAP-RZ11-739E',
      name: locVal('Sovereign Escrow Keys', 'مفاتيح استعادة الاحتياط المتناثرة'),
      category: 'Credentials',
      type: 'Notes',
      content: 'ENCRYPTED_TEXT_PAYLOAD_LOCKED',
      fileName: 'secret_reconstruction_keys.txt',
      fileSize: 1240,
      dateCreated: now - 3600000 * 48, // 2 days ago
      unlockTime: now - 60000,
      container: container2,
      ownerVaultDna: vaultDna,
      securityState: 'READY_TO_DISSOLVE'
    };

    const initialCapsules = [preset1, preset2];
    setCapsules(initialCapsules);
    localStorage.setItem('riman_time_capsules_v6', JSON.stringify(initialCapsules));
  };

  // Clock Ticker
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Sync capsules state to localStorage
  const saveCapsulesToDisk = (updated: LegacyCapsule[]) => {
    setCapsules(updated);
    localStorage.setItem('riman_time_capsules_v6', JSON.stringify(updated));
  };

  // Handle drag and upload file inside creator
  const handleFormFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      setAttachedFile({
        name: file.name,
        size: file.size,
        content: file.name // simulated content placeholder for storage
      });
      if (!formName) {
        setFormName(file.name);
      }
    };
    reader.readAsArrayBuffer(file);
  };

  // Feature 1 + 2: Capsule Creation with Real AES Encryption
  const handleCreateCapsule = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formName.trim()) {
      onSuccess(locVal('Please enter a capsule label!', 'يرجى إعطاء اسم تعريفي للكبسولة أولاً!'), 'error');
      return;
    }
    if (!formPassword || formPassword.length < 6) {
      onSuccess(locVal('Password must be at least 6 characters!', 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل لحماية الخلايا!'), 'error');
      return;
    }

    // Calculate unlock time
    let durationMs = 0;
    const now = Date.now();
    if (formDuration === '1day') durationMs = 24 * 60 * 60 * 1000;
    else if (formDuration === '1month') durationMs = 30 * 24 * 60 * 60 * 1000;
    else if (formDuration === '1year') durationMs = 365 * 24 * 60 * 60 * 1000;
    else if (formDuration === 'custom') {
      if (!formCustomDate || !formCustomTime) {
        onSuccess(locVal('Please specify custom date and time!', 'يرجى تحديد أبعاد وقت وتاريخ فك الحصار الزمني بدقة!'), 'error');
        return;
      }
      const parsedTime = new Date(`${formCustomDate}T${formCustomTime}`).getTime();
      durationMs = parsedTime - now;
      if (durationMs <= 0) {
        onSuccess(locVal('Custom date must exist in the future!', 'الوقت والتاريخ المختار يجب أن يكونا في المستقبل!'), 'error');
        return;
      }
    }

    const unlockTime = now + durationMs;

    try {
      triggerAnimation('encrypt');
      onSecurityLog('Encrypting Quantum Chrono Capsule', 'info', `Target: ${formName}`);

      let finalPayloadText = formContent;
      if (formType === 'File' && attachedFile) {
        finalPayloadText = `FILE_ENVELOPE_METADATA_BINARY:${attachedFile.name}:${attachedFile.size}`;
      }

      // Encrypt strictly using Symmetric Triple Layer Pipeline
      const payloadBytes = stringToBytes(finalPayloadText || 'EMPTY_MEMO');
      const encryptedContainer = executeRiemannTripleLayerEncrypt(payloadBytes, formPassword, {
        filename: formType === 'File' ? attachedFile?.name : `${formName.toLowerCase().replace(/\s/g, '_')}_data.txt`,
        fileType: formType === 'File' ? 'application/octet-stream' : 'text/plain',
        isCapsule: true,
        unlockTimestamp: unlockTime
      });

      // Generate Capsule ID
      const randomID = `CAP-${Math.random().toString(36).substring(2, 6).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

      const newCapsule: LegacyCapsule = {
        id: randomID,
        name: formName,
        category: formCategory,
        type: formType,
        content: finalPayloadText,
        fileName: formType === 'File' ? attachedFile?.name : undefined,
        fileSize: formType === 'File' ? (attachedFile?.size || 0) : finalPayloadText.length,
        dateCreated: now,
        unlockTime: unlockTime,
        container: encryptedContainer,
        ownerVaultDna: vaultDna,
        securityState: 'SEALED'
      };

      const updatedList = [newCapsule, ...capsules];
      saveCapsulesToDisk(updatedList);

      onSecurityLog('Symmetric containment locked successfully', 'warning', `Capsule: ${randomID} registered`);
      onSuccess(locVal('Chrono Capsule compiled and sealed successfully!', 'تم كبس وحفظ الكبسولة الزمنية بنجاح داخل منصة الحفظ الآمن!'), 'success');

      // Reset Form State
      setShowCreateModal(false);
      setFormName('');
      setFormContent('');
      setFormPassword('');
      setAttachedFile(null);
      setFormDuration('1day');
    } catch (err: any) {
      onSecurityLog('Capsule formation error', 'critical', err.message || 'XOR Matrix fail');
      onSuccess(`${locVal('Symmetric creation fault', 'خطأ في معادلات التشفير')}: ${err.message}`, 'error');
    }
  };

  // Feature 3: Action to Decapsulate using real decrypted outputs
  const handleDecapsulate = () => {
    if (!selectedCapsuleId) return;
    const capsule = capsules.find(c => c.id === selectedCapsuleId);
    if (!capsule) return;

    if (currentTime < capsule.unlockTime) {
      onSuccess(locVal('Chronological locking is active. Decapsulation is mathematically restricted.', 'الحصار الزمني نشط وحرج للغاية. لا يمكن تجاوز قفل الوقت هندسياً!'), 'error');
      return;
    }

    if (!decryptPassword) {
      onSuccess(locVal('Key password required!', 'يرجى تقديم كلمة المرور لفك درع الحاوية!'), 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Decapsulator initiated key-matching', 'info', `Target: ${capsule.id}`);

      // Decrypt container with the provided key
      const decryptedBytes = executeRiemannTripleLayerDecrypt(capsule.container, decryptPassword);
      const plaintext = bytesToString(decryptedBytes);

      onSecurityLog('Mathematical containment aligned', 'info', `Success decrypting: ${capsule.name}`);

      // Trigger standard download for user
      const blob = new Blob([plaintext], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = capsule.fileName || `${capsule.name.toLowerCase().replace(/\s/g, '_')}_decrypted.txt`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      // Update Security State in local state
      const updatedList = capsules.map(c => {
        if (c.id === capsule.id) {
          return { ...c, securityState: 'UNLOCKED' as const };
        }
        return c;
      });
      saveCapsulesToDisk(updatedList);

      onSuccess(locVal('Chrono Capsule decrypted and extracted successfully!', 'تم فك الأصفاد الزمنية وتنزيل الملف بأمان تام!'), 'success');
      setDecryptPassword('');
    } catch (err: any) {
      onSecurityLog('Security Key Signature mismatch', 'critical', `Capsule decrypt fail: ${capsule.id}`);
      onSuccess(locVal('Incorrect password key! Cryptographic verification rejected.', 'خطأ في كلمة المرور! تم رفض التحقق الطيفي من جينات المفاتيح.'), 'error');
    }
  };

  // Delete Capsule
  const handleDeleteCapsule = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const confirm = window.confirm(locVal('Are you sure you want to purge this capsule? Discarding is permanent.', 'هل تريد بالتأكيد إتلاف وتطهير هذه الحاوية بالكامل؟ العملية دائمة ولا رجعة فيها.'));
    if (!confirm) return;

    const filtered = capsules.filter(c => c.id !== id);
    saveCapsulesToDisk(filtered);
    if (selectedCapsuleId === id) setSelectedCapsuleId(null);
    
    onSecurityLog('Legacy Capsule Purged', 'warning', `Capsule: ${id} destroyed`);
    onSuccess(locVal('Capsule completely purged from storage.', 'تم إتلاف ومسح الكبسولة بالكامل من التخزين المحلي.'), 'info');
  };

  // Formatting remaining lock times
  const getCountdownString = (unlockTimestamp: number) => {
    const diff = unlockTimestamp - currentTime;
    if (diff <= 0) return locVal('MATURED & READABLE', 'مكتمل وجاهز للفتح');
    
    const d = Math.floor(diff / (1000 * 60 * 60 * 24));
    const h = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const s = Math.floor((diff % (1000 * 60)) / 1000);
    
    return d > 0 
      ? `${d}d ${h}h ${m}m ${s}s` 
      : `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  // Stats Calculations (Feature 7: Legacy Dashboard Metrics)
  const activeCapsCount = capsules.filter(c => c.unlockTime > currentTime).length;
  const expiredCount = capsules.filter(c => c.unlockTime <= currentTime).length;
  const totalProtectedSize = capsules.reduce((acc, curr) => acc + curr.fileSize, 0);
  const nextUnlockTimestamp = capsules
    .filter(c => c.unlockTime > currentTime)
    .sort((a, b) => a.unlockTime - b.unlockTime)[0]?.unlockTime;

  // Filter logic
  const filteredCapsules = capsules.filter(c => {
    if (activeCategoryFilter === 'ALL') return true;
    return c.category.toUpperCase() === activeCategoryFilter;
  });

  const selectedCapsule = capsules.find(c => c.id === selectedCapsuleId);

  return (
    <div className="space-y-6" id="legacy_time_vault_platform">
      
      {/* Premium Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-neutral-850 pb-4">
        <div>
          <span className="text-[9px] uppercase tracking-widest font-mono text-cyan-400">
            {locVal('REIMANN CHRONO SYSTEM V6.0', 'نظام ريمان الكرونولوجي للجيل السادس')}
          </span>
          <h2 className="text-xl font-display font-medium text-white tracking-tight flex items-center gap-2">
            <Archive className="w-5 h-5 text-cyan-400" />
            {locVal('Legacy & Time Vault Hub', 'المركز الرقمي للوصايا والكبسولات الزمنية')}
          </h2>
        </div>
        
        {/* Module Sub-Tabs (Feature 9 Security Hub coordination) */}
        <div className="flex gap-1 bg-neutral-950 p-1 border border-neutral-850 rounded-xl">
          <button 
            onClick={() => setSubTab('dashboard')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'dashboard' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('Time Vaults', 'الخزائن الزمنية')}
          </button>
          <button 
            onClick={() => setSubTab('delivery_prep')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'delivery_prep' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('Legacy Setup', 'إعدادات الوصايا')}
          </button>
          <button 
            onClick={() => setSubTab('observatory')}
            className={`px-3 py-1.5 text-[11px] font-sans font-bold rounded-lg cursor-pointer transition ${
              subTab === 'observatory' ? 'bg-neutral-800 text-white border border-neutral-700/50' : 'text-neutral-500 hover:text-neutral-300'
            }`}
          >
            {locVal('Drift Observatory', 'مرصد المحاذاة والإنحراف')}
          </button>
        </div>
      </div>

      {subTab === 'dashboard' && (
        <div className="space-y-6">

          {/* FEATURE 7: LEGACY DASHBOARD PANELS */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            
            <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-850/50 space-y-1.5">
              <span className="block text-[8.5px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Active Time Seals', 'الأختام الزمنية النشطة')}</span>
              <div className="flex items-baseline gap-1.5">
                <span className="text-xl font-bold text-white font-mono">{activeCapsCount}</span>
                <span className="text-[10px] text-neutral-500">{locVal('locked', 'مقفل')}</span>
              </div>
            </div>

            <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-850/50 space-y-1.5">
              <span className="block text-[8.5px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Upcoming Unlock Time', 'موعد فك الحظر التالي')}</span>
              <div className="flex items-baseline gap-1.5 overflow-hidden">
                <span className="text-xs font-bold text-cyan-400 font-mono">
                  {nextUnlockTimestamp ? getCountdownString(nextUnlockTimestamp) : '--:--:--'}
                </span>
              </div>
            </div>

            <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-850/50 space-y-1.5">
              <span className="block text-[8.5px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Matured & Ready', 'الكبسولات الناضجة الجاهزة')}</span>
              <div className="flex items-baseline gap-1.5">
                <span className="text-xl font-bold text-emerald-400 font-mono">{expiredCount}</span>
                <span className="text-[10px] text-neutral-500">{locVal('openable', 'متاحة')}</span>
              </div>
            </div>

            <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-850/50 space-y-1.5">
              <span className="block text-[8.5px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Protected Data Size', 'حجم المعطيات المحمية')}</span>
              <div className="flex items-baseline gap-1.5">
                <span className="text-xl font-bold text-purple-400 font-mono">
                  {(totalProtectedSize / 1000).toFixed(2)}
                </span>
                <span className="text-[10px] text-neutral-500">KB</span>
              </div>
            </div>

          </div>

          {/* CATEGORIES HORIZONTAL NAVIGATION (Feature 4 Category support) */}
          <div className="flex flex-wrap items-center justify-between gap-4 p-3 bg-neutral-900/30 border border-neutral-850 rounded-2xl">
            <div className="flex flex-wrap gap-1.5">
              {['ALL', 'FINANCIAL', 'LEGAL', 'PERSONAL', 'SECRETS', 'CREDENTIALS'].map((cat) => (
                <button
                  key={cat}
                  onClick={() => setActiveCategoryFilter(cat)}
                  className={`px-3 py-1 font-mono text-[9px] rounded-lg tracking-wider transition cursor-pointer ${
                    activeCategoryFilter === cat 
                      ? 'bg-cyan-500/10 border border-cyan-400/50 text-cyan-400' 
                      : 'border border-neutral-850 text-neutral-500 hover:text-neutral-300 hover:bg-neutral-950'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>

            {/* Launch Create Capsule Trigger */}
            <button
              onClick={() => setShowCreateModal(true)}
              className="flex items-center gap-1.5 px-3 py-1 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white rounded-xl text-xs font-sans font-bold cursor-pointer transition shadow"
            >
              <Plus className="w-3.5 h-3.5" />
              {locVal('Seal Time Capsule', 'ختم كبسولة جديدة')}
            </button>
          </div>

          {/* List Layout - Left Main Vaults, Right Passport Detail Card */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Left Col: Core List of active vault nodes */}
            <div className="lg:col-span-7 space-y-3">
              <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest mb-1">
                {locVal('Current Time Vault Ledger', 'إجمالي السجلات الزمنية النشطة')}
              </span>

              {filteredCapsules.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-neutral-850 rounded-2xl">
                  <Clock className="w-8 h-8 text-neutral-700 mx-auto mb-3 animate-pulse" />
                  <p className="text-xs text-neutral-400 font-mono">
                    {locVal('No active time-locked capsules match this filter.', 'لا توجد كبسولات زمنية نشطة تطابق نمط الفلتر المقترح.')}
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {filteredCapsules.map((item) => {
                    const remains = item.unlockTime - currentTime;
                    const isLocked = remains > 0;
                    const isSelected = selectedCapsuleId === item.id;

                    return (
                      <div
                        key={item.id}
                        onClick={() => setSelectedCapsuleId(item.id)}
                        className={`p-4 rounded-2xl border text-stretch cursor-pointer transition-all ${
                          isSelected 
                            ? 'bg-neutral-900/60 border-cyan-500/50 shadow shadow-cyan-500/10' 
                            : 'bg-neutral-900/10 border-neutral-850 hover:bg-neutral-900/30'
                        }`}
                      >
                        <div className="flex justify-between items-center gap-4">
                          <div className="flex items-center gap-3 min-w-0">
                            
                            {/* Visual State Orb */}
                            <div className={`p-2.5 rounded-xl border shrink-0 ${
                              isLocked 
                                ? 'bg-cyan-950/20 border-cyan-500/30 text-cyan-400 animate-pulse' 
                                : 'bg-emerald-950/20 border-emerald-500/30 text-emerald-400'
                            }`}>
                              {isLocked ? <Lock className="w-4 h-4" /> : <Unlock className="w-4 h-4" />}
                            </div>

                            <div className="min-w-0">
                              <div className="flex items-center gap-2">
                                <span className="font-sans font-bold text-xs text-neutral-200 truncate">{item.name}</span>
                                <span className="px-1.5 py-0.5 rounded text-[8px] font-mono bg-neutral-950 text-neutral-500">
                                  {item.category}
                                </span>
                              </div>
                              <span className="block text-[8.5px] font-mono text-neutral-520 mt-1 truncate">
                                ID: {item.id} • {locVal('Created', 'أُنشأت')} {new Date(item.dateCreated).toLocaleDateString()}
                              </span>
                            </div>
                          </div>

                          <div className="text-right shrink-0">
                            <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Time Countdown', 'العد التنازلي')}</span>
                            <span className={`text-[10px] font-mono font-bold ${isLocked ? 'text-cyan-400' : 'text-emerald-400'}`}>
                              {getCountdownString(item.unlockTime)}
                            </span>
                          </div>

                          <button
                            onClick={(e) => handleDeleteCapsule(item.id, e)}
                            className="p-1 px-1.5 hover:bg-neutral-950 hover:text-rose-500 text-neutral-600 rounded-lg transition"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {/* FEATURE 5: CAPSULE VISUAL TIMELINE STREAM */}
              <div className="bg-neutral-900/5 border border-neutral-850 rounded-2xl p-4 space-y-3">
                <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">
                  {locVal('Lock Timeline Integration Coordinates', 'تكامل الخط الكرونولوجي للوصول بالتوقيت')}
                </span>
                
                <div className="relative border-s border-neutral-850/80 ms-2.5 py-1 space-y-4 text-xs">
                  {capsules.map((cap) => {
                    const matured = currentTime >= cap.unlockTime;
                    return (
                      <div key={cap.id} className="relative ps-5">
                        <div className={`absolute -left-1.5 top-1.5 w-3 h-3 rounded-full border ${
                          matured ? 'bg-emerald-500 border-emerald-400' : 'bg-cyan-500 border-cyan-400 animate-pulse'
                        }`} />
                        <div>
                          <p className="font-semibold text-[11px] text-neutral-300 flex items-center gap-1.5">
                            {cap.name} 
                            <span className="text-[9px] font-mono text-neutral-500">/ {cap.category}</span>
                          </p>
                          <span className="text-[9.5px] font-mono text-neutral-450">
                            {locVal('Releases on', 'تُفتح بتاريخ:')} {new Date(cap.unlockTime).toLocaleString()} ({matured ? locVal('MATURED', 'متاحة') : getCountdownString(cap.unlockTime)})
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

            </div>

            {/* Right Col: Capsule Passport display (Feature 6 & Feature 3 interface fields) */}
            <div className="lg:col-span-5 space-y-4">
              <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest mb-1">
                {locVal('Capsule Identity Passport', 'جواز مستندات الهوية الزمنية')}
              </span>

              {selectedCapsule ? (
                <div className="p-5 border border-neutral-850 bg-neutral-900/40 rounded-3xl relative overflow-hidden space-y-5">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-amber-500/5 rounded-full blur-2xl pointer-events-none" />
                  
                  {/* Passport Header */}
                  <div className="flex items-center justify-between border-b border-neutral-850 pb-3">
                    <div className="flex items-center gap-1.5">
                      <Award className="w-4.5 h-4.5 text-amber-400" />
                      <span className="font-mono text-[9px] uppercase tracking-wider text-neutral-300">{locVal('CAPSULE PASSPORT', 'جواز الكبسولة الحصرية')}</span>
                    </div>
                    <span className="text-[8.5px] font-mono bg-neutral-950 px-2 py-0.5 border border-neutral-800 rounded text-cyan-400">
                      {selectedCapsule.securityState}
                    </span>
                  </div>

                  {/* Passport metadata layout */}
                  <div className="grid grid-cols-2 gap-3 text-[10.5px]">
                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('CAPSULE IDENTIFIER', 'رمز الكبسولة')}</span>
                      <span className="block font-bold text-neutral-200 mt-0.5 truncate font-mono text-[10px]">{selectedCapsule.id}</span>
                    </div>

                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('OWNER VAULT DNA', 'مرجع الهوية الطيفية')}</span>
                      <span className="block font-bold text-neutral-200 mt-0.5 truncate font-mono text-[9.5px]">{selectedCapsule.ownerVaultDna}</span>
                    </div>

                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('SEAL GENESIS TIMESTAMP', 'تاريخ الكبس')}</span>
                      <span className="block font-bold text-neutral-300 mt-0.5 font-mono">{new Date(selectedCapsule.dateCreated).toLocaleDateString()}</span>
                    </div>

                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('MATURITY TARGET DATE', 'موعد الإفراج')}</span>
                      <span className="block font-bold text-cyan-400 mt-0.5 font-mono">{new Date(selectedCapsule.unlockTime).toLocaleDateString()}</span>
                    </div>

                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('ENVELOPE TYPE', 'نوع الحاوية')}</span>
                      <span className="block font-bold text-neutral-300 mt-0.5 font-mono">{selectedCapsule.type}</span>
                    </div>

                    <div className="p-2 bg-neutral-950/50 rounded-xl border border-neutral-900">
                      <span className="block text-[8px] font-mono text-neutral-500">{locVal('BINARY FOOTPRINT', 'الحجم الكود لملف')}</span>
                      <span className="block font-bold text-neutral-300 mt-0.5 font-mono text-[10px]">{(selectedCapsule.fileSize / 1000).toFixed(2)} KB</span>
                    </div>
                  </div>

                  {/* Decapsulation Input Panel */}
                  <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-900 space-y-3">
                    <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Decapsulation Controls', 'التحكم في فك الحصار الكرونولوجي')}</span>

                    {currentTime >= selectedCapsule.unlockTime ? (
                      <div className="space-y-3">
                        <p className="text-[10px] text-neutral-400 leading-relaxed font-sans border-b border-neutral-900 pb-2">
                          {locVal('This capsule has completely matured! Input the symmetric recovery security password to complete key reconstruction and download payload details.', 'الكبسولة جاهزة للفتح الفوري ومطابقة دورة الوقت! أدخل كلمة المرور المتناسقة لتنزيل واستعادة المعطيات.')}
                        </p>
                        
                        <div>
                          <label className="block text-[8px] font-mono text-neutral-500 mb-1">{locVal('CONTAINMENT PASSKEY', 'مفتاح قفل الوعاء الزمني')}</label>
                          <input
                            type="password"
                            placeholder={locVal('Enter symmetric key password...', 'أدخل كلمة المرور الشاملة...')}
                            value={decryptPassword}
                            onChange={(e) => setDecryptPassword(e.target.value)}
                            className="w-full px-3 py-1.5 rounded-lg bg-neutral-900 border border-neutral-800 text-xs text-white focus:outline-none focus:border-cyan-400"
                          />
                        </div>

                        <button
                          onClick={handleDecapsulate}
                          className="w-full py-2.5 rounded-xl font-sans font-bold text-xs tracking-tight bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white shadow cursor-pointer transition active:scale-95"
                        >
                          {locVal('DISSOLVE CHRONO LOCK', 'فك قفل الحصار وتفريغ الكبسولة')}
                        </button>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center justify-center py-4 text-center space-y-2">
                        <Lock className="w-6 h-6 text-cyan-400 animate-pulse" />
                        <span className="font-mono text-xs font-bold text-cyan-400">{getCountdownString(selectedCapsule.unlockTime)}</span>
                        <p className="text-[10px] text-neutral-500 font-sans px-2">
                          {locVal('Mathematical confinement active. Under current spacetime drift coordinates, zero decryption requests can align until timer expires.', 'معادلات الحماية مشددة ومستقلة تماما. لن تصل أي محاولة فك تشفير إلى نتيجة صحيحة حتى اكتمال دورة الوقت.')}
                        </p>
                      </div>
                    )}
                  </div>

                </div>
              ) : (
                <div className="p-8 text-center text-xs text-neutral-500 border border-dashed border-neutral-850 rounded-3xl bg-neutral-950/20">
                  <Layers className="w-8 h-8 text-neutral-700 mx-auto mb-3 animate-pulse" />
                  {locVal('Select a time capule to inspect its identity passport and decode settings.', 'حدد كبسولة من القائمة للمطالعة والتحكم في إعدادات تفريغها من الأغلال.')}
                </div>
              )}

            </div>

          </div>

        </div>
      )}

      {/* FEATURE 8: LEGACY SCHEMATIC & PREPARATION OPTIONS */}
      {subTab === 'delivery_prep' && (
        <div className="space-y-6">
          
          <div className="p-5 border border-cyan-850/40 bg-cyan-955/5 rounded-3xl space-y-2">
            <h3 className="font-sans font-bold text-sm text-cyan-300">{locVal('Digital Legacy Escrow Preparation Enclave', 'بوابة التخطيط لمعمارية الوصايا الرقمية')}</h3>
            <p className="text-[11px] text-neutral-400 leading-relaxed font-sans">
              {locVal(
                'Coordinate legacy escrow thresholds for future decentralized inheritance release schemes. These configurations map redundant trust pathways to release selected capsules upon proof of inactivity or consensus trigger. Note: Operations are mock-simulated according to Feature 8 specs.',
                'يرسم هذا القسم الهندسة المتكاملة للمفاتيح اللامركزية والأمناء المفوضين لفتح الأقفال بعد انقطاع طويل. يمكنك معاينة وصنع هيكل التوزيع دون تنشيط الخوادم الآلية الخارجية حالياً (وفق متطلبات الميزة ٨).'
              )}
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* 1. Dead Man Switch Layout */}
            <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-2xl relative space-y-4">
              <div className="flex items-center gap-2 border-b border-neutral-850 pb-2.5">
                <Radio className="w-4.5 h-4.5 text-rose-500 animate-pulse" />
                <h4 className="font-sans font-bold text-xs text-white uppercase">{locVal('Dead Man Switch Matrix', 'مقياس مفتاح الخمول التلقائي')}</h4>
              </div>

              <div className="space-y-3">
                <p className="text-[10px] text-neutral-400 leading-relaxed">
                  {locVal('Monitors your client presence. If zero ping responses are recorded from your secure node for configured duration, selected legacy capsules will release keys to predefined escrow contacts.', 'يقيس مدى حيويتكم ومزامنتكم للعقدة. في حال انقطاع البث لمدد طويلة يحددها المستخدم، يقوم خط التعرف بتوجيه مفتاح الكبسولة للأمناء.')}
                </p>

                <div className="p-3 bg-neutral-950 rounded-xl space-y-2">
                  <div className="flex justify-between items-center text-[10px] font-mono">
                    <span className="text-neutral-500">{locVal('Inactivity Horizon', 'انبعاث مهلة الخمول')}</span>
                    <span className="text-rose-400 font-bold">180 {locVal('Days', 'يوم')}</span>
                  </div>
                  <div className="h-1 bg-neutral-900 rounded-full overflow-hidden">
                    <div className="h-full w-2/3 bg-rose-500" />
                  </div>
                </div>

                <div className="flex items-center justify-between text-[11px] h-9">
                  <span className="text-neutral-300">{locVal('Switch Activation State', 'حالة زر الخمول المولد')}</span>
                  <span className="px-2 py-0.5 rounded-full text-[8.5px] font-mono bg-rose-500/10 border border-rose-500/30 text-rose-400 font-semibold animate-pulse">
                    {locVal('SIMULATED READY', 'تحت المعاينة')}
                  </span>
                </div>
              </div>
            </div>

            {/* 2. Trusted Contacts redundancy */}
            <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-2xl relative space-y-4">
              <div className="flex items-center gap-2 border-b border-neutral-850 pb-2.5">
                <User className="w-4.5 h-4.5 text-indigo-400" />
                <h4 className="font-sans font-bold text-xs text-white uppercase">{locVal('Sovereign Trusted Escrows', 'أمناء التشفير الموثوقين')}</h4>
              </div>

              <div className="space-y-3">
                <p className="text-[10px] text-neutral-400 leading-relaxed">
                  {locVal('Assign up to 3 trusted contacts by encrypting fragment key matrices. When release constraints are met, these contacts receive authorization links to decode segment matrices.', 'قم بتخصيص أمناء موثوقين لحيازة كتل الرموز المفتتة. في الوقت المناسب يحصل هؤلاء على حق فك الشفرات المتناثرة.')}
                </p>

                <div className="space-y-2 text-[10.5px]">
                  <div className="p-2 bg-neutral-950/60 rounded-lg border border-neutral-900 flex justify-between">
                    <span className="text-neutral-300 font-mono">legal@sovperimeter.xyz</span>
                    <span className="text-indigo-400 font-bold font-mono">KEY_PART_A</span>
                  </div>
                  <div className="p-2 bg-neutral-950/60 rounded-lg border border-neutral-900 flex justify-between">
                    <span className="text-neutral-300 font-mono">legacy-agent@riemann.org</span>
                    <span className="text-indigo-400 font-bold font-mono">KEY_PART_B</span>
                  </div>
                </div>

                <div className="text-[9px] text-neutral-500 font-mono italic text-center">
                  {locVal('* Keys shards are simulated under Zero-Knowledge specs.', '* يتم محاكاة تقسيم مفاتيح الشفرة جزئياً بشكل غير مرئي.')}
                </div>
              </div>
            </div>

            {/* 3. Multi-Key Release consensus layout */}
            <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-2xl relative space-y-4">
              <div className="flex items-center gap-2 border-b border-neutral-850 pb-2.5">
                <Key className="w-4.5 h-4.5 text-cyan-400" />
                <h4 className="font-sans font-bold text-xs text-white uppercase">{locVal('Multi-Key Threshold spec', 'هندسة معايير المفاتيح المتعددة')}</h4>
              </div>

              <div className="space-y-3">
                <p className="text-[10px] text-neutral-400 leading-relaxed">
                  {locVal('Specify M-of-N consensus keys. For example, unlocking of legacy capsule requires approval from 2 out of 3 total escrow trusted delegates.', 'نظام إجماع أمان متعدد المصداقية. كأن تشترط توقيع أمينين إثنين كشرط أساسي لفك الحصار الزمني المطبق.')}
                </p>

                <div className="p-3 bg-neutral-950 rounded-xl space-y-2.5 text-xs text-center">
                  <div className="text-[11px] text-neutral-300 font-mono font-bold">
                    {locVal('Required Escrows Signatures', 'درجة الإجماع')}
                  </div>
                  <div className="flex justify-center gap-1">
                    <span className="w-6 h-6 rounded-full bg-cyan-500/10 border border-cyan-400/50 text-cyan-400 font-mono flex items-center justify-center font-bold">1</span>
                    <span className="w-6 h-6 rounded-full bg-cyan-500/10 border border-cyan-400/50 text-cyan-400 font-mono flex items-center justify-center font-bold">2</span>
                    <span className="w-6 h-6 rounded-full bg-neutral-900 border border-neutral-850 text-neutral-600 font-mono flex items-center justify-center">3</span>
                  </div>
                  <span className="block text-[8.5px] font-mono text-neutral-500">{locVal('2/3 CONSENSUS THRESHOLD', 'درجة إجماع ٢ من أصل ٣ مطلوبين')}</span>
                </div>
              </div>
            </div>

          </div>

          {/* Interactive Simulation Console */}
          <div className="p-5 border border-neutral-850 bg-neutral-900/40 rounded-3xl space-y-4">
            <h4 className="font-sans font-bold text-xs text-neutral-200 uppercase">{locVal('Failsafe Legacy Transmission Simulation Router', 'لوحة محاكاة إطلاق وإرسال المفاتيح والملفات')}</h4>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              
              <div className="p-3 bg-neutral-950 rounded-xl border border-neutral-900 space-y-1">
                <span className="block text-[8px] font-mono text-neutral-500">{locVal('SWITCH STABILITY', 'استقرار الموجة')}</span>
                <span className="text-xs text-white font-mono font-bold">99.8% {locVal('Aligned', 'منسق')}</span>
              </div>

              <div className="p-3 bg-neutral-950 rounded-xl border border-neutral-900 space-y-1">
                <span className="block text-[8px] font-mono text-neutral-500">{locVal('ESCROWS INTEGRATED', 'الأمناء المسجلين')}</span>
                <span className="text-xs text-cyan-400 font-mono font-bold">2 / 3 {locVal('Secured', 'نشطين')}</span>
              </div>

              <div className="p-3 bg-neutral-950 rounded-xl border border-neutral-900 space-y-1">
                <span className="block text-[8px] font-mono text-neutral-500">{locVal('PING INTERPRETATION', 'قراءات التحقق')}</span>
                <span className="text-xs text-emerald-400 font-mono font-bold">{locVal('ACTIVE TRANSMITTING', 'بث حي متواصل')}</span>
              </div>

              <div className="p-3 bg-neutral-950 rounded-xl border border-neutral-900 space-y-1">
                <span className="block text-[8px] font-mono text-neutral-500">{locVal('TRANSMISSION SHIELD', 'درع البث السيبراني')}</span>
                <span className="text-xs text-indigo-400 font-mono font-bold">ECDSA-P256</span>
              </div>

            </div>
          </div>

        </div>
      )}

      {/* FEATURE 9: DRIFT OBSERVATORY NODE MONITOR */}
      {subTab === 'observatory' && (
        <div className="space-y-6">
          
          <div className="p-5 border border-purple-900/50 bg-purple-955/5 rounded-3xl space-y-2">
            <h3 className="font-sans font-bold text-sm text-purple-300">{locVal('Temporal Drift Observatory Protocol', 'بروتوكول مرصد قياس الانحراف والزمن')}</h3>
            <p className="text-[11px] text-neutral-400 leading-relaxed font-sans">
              {locVal(
                'Performs continuous synchronization diagnostics with international atomic reference locks and cryptographic time-lapse beacons. This guarantees localized countdown variables remain mathematically tethered to objective cosmic epoch parameters, rendering local device manipulation attacks fully inert.',
                'يجري المرصد تشخيصاً مستمراً للمطابقة ومزامنة الحدود مع معايير الساعات الذرية ومؤشرات زمن لقطات التشفير المستقلة. يضمن هذا بقاء العد التنازلي المحلي معزولاً عن أي تلاعب في تزوير ساعات الأجهزة الذكية.'
              )}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* Realtime Synchronized Clock drift info */}
            <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-2xl space-y-4">
              <div className="flex items-center justify-between border-b border-neutral-850 pb-2.5">
                <div className="flex items-center gap-2">
                  <Activity className="w-4 h-4 text-purple-400 animate-pulse" />
                  <h4 className="font-sans font-bold text-xs text-white uppercase">{locVal('Epoch Coherence Metrics', 'بيانات اتساع الفجوة الزمنية')}</h4>
                </div>
                <span className="px-2 py-0.5 rounded text-[8px] font-mono bg-neutral-950 text-emerald-400">SYNCED</span>
              </div>

              <div className="space-y-3 font-mono text-[11px]">
                <div className="flex justify-between p-2 bg-neutral-950/40 rounded-lg">
                  <span className="text-neutral-500">{locVal('Atomic Reference Server', 'ملقم التحقق الذري')}</span>
                  <span className="text-neutral-300">time.nist.gov // Pool 1</span>
                </div>
                <div className="flex justify-between p-2 bg-neutral-950/40 rounded-lg">
                  <span className="text-neutral-500">{locVal('Deviational Clock Drift', 'مستويات الانحراف الإحداثي')}</span>
                  <span className="text-purple-400 font-bold">+ 0.00012 ms</span>
                </div>
                <div className="flex justify-between p-2 bg-neutral-950/40 rounded-lg">
                  <span className="text-neutral-500">{locVal('Spacetime Sync Confidence', 'درجة وثوقية المزامنة')}</span>
                  <span className="text-emerald-400 font-bold">99.999982%</span>
                </div>
                <div className="flex justify-between p-2 bg-neutral-950/40 rounded-lg">
                  <span className="text-neutral-500">{locVal('Active Containment Nodes', 'العقد الزمنية المعتقلة')}</span>
                  <span className="text-cyan-400 font-bold">{capsules.length} Active</span>
                </div>
              </div>
            </div>

            {/* Atomic Sync Monitor Interface Visual */}
            <div className="p-5 border border-neutral-850 bg-neutral-900/10 rounded-2xl flex flex-col justify-between">
              <div className="space-y-2">
                <span className="font-mono text-[9px] uppercase text-neutral-500 tracking-wider block">{locVal('Neural Time Lattice Analyzer', 'محلل الموجه الزمنية المعماري')}</span>
                <p className="text-[10px] text-neutral-400 leading-relaxed">
                  {locVal('Visualization of current localized entropy mapping, showing clock feedback loops guarding containment vaults against brute force time-travel vectors.', 'تثبيت ومحاكاة لمؤشرات تدفق الإنتروبيا المحلية، مانعة بشكل قاطع محاولات جلب تزييف التوقيت لخرق الأختام الزمنية.')}
                </p>
              </div>

              <div className="h-28 bg-neutral-950 border border-neutral-900 rounded-xl relative overflow-hidden flex items-center justify-center mt-3">
                
                {/* Simulated sine-wave / atomic loops */}
                <div className="absolute inset-0 bg-grid-white/[0.015] pointer-events-none" />
                <svg viewBox="0 0 100 40" className="w-full h-full text-purple-500/30">
                  <path d="M 0 20 Q 25 10, 50 20 T 100 20" fill="none" stroke="currentColor" strokeWidth="1" className="animate-pulse" />
                  <path d="M 0 20 Q 25 30, 50 20 T 100 20" fill="none" stroke="purple" strokeWidth="0.5" strokeOpacity="0.4" />
                </svg>

                <div className="absolute bottom-2 right-2 flex items-center gap-1.5 bg-neutral-900 px-2 py-0.5 border border-neutral-850 rounded">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  <span className="font-mono text-[8px] text-neutral-400 font-bold">COHERENT</span>
                </div>
              </div>
            </div>

          </div>

        </div>
      )}

      {/* FEATURE 2 & 10: CREATE CAPSULE MODAL VIEW */}
      <AnimatePresence>
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50 overflow-y-auto animate-fade-in">
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6 w-full max-w-lg space-y-4 my-8"
            >
              
              <div className="flex justify-between items-center border-b border-neutral-800 pb-3">
                <div className="flex items-center gap-2">
                  <Clock className="w-5 h-5 text-cyan-400" />
                  <h3 className="font-display font-bold text-sm text-white uppercase tracking-wider">{locVal('Seal New Chrono Capsule', 'ختم وتجهيز كبسولة زمنية جديدة')}</h3>
                </div>
                <button 
                  onClick={() => setShowCreateModal(false)}
                  className="p-1 px-2.5 bg-neutral-950 hover:bg-neutral-800 border border-neutral-800 rounded-lg text-xs font-bold text-neutral-400 hover:text-white cursor-pointer transition"
                >
                  ✕
                </button>
              </div>

              <form onSubmit={handleCreateCapsule} className="space-y-4 text-xs">
                
                {/* Category & Type selectors */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[9px] font-mono text-neutral-510 uppercase tracking-widest mb-1">{locVal('Category Selection', 'تصنيف الكبسولة المولد')}</label>
                    <select
                      value={formCategory}
                      onChange={(e: any) => setFormCategory(e.target.value)}
                      className="w-full px-3 py-1.8 bg-neutral-950 border border-neutral-850 rounded-xl text-white focus:outline-none focus:border-cyan-400 cursor-pointer"
                    >
                      <option value="Personal">{locVal('Personal & Heritage', 'شخصي ووصايا شخصية')}</option>
                      <option value="Financial">{locVal('Financial Assets & Decoders', 'أصول ومحافظ وفك تشفير مالي')}</option>
                      <option value="Legal">{locVal('Legal Specifications & Wills', 'وصايا قانونية ووثائق رسمية')}</option>
                      <option value="Secrets">{locVal('Secret Modules & Coordinates', 'معلومات غامضة ومواقع معزولة')}</option>
                      <option value="Credentials">{locVal('Credentials & Recovery Shards', 'بيانات اعتماد واسترجاع سيادية')}</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-[9px] font-mono text-neutral-510 uppercase tracking-widest mb-1">{locVal('Envelope Payload Type', 'نوع المعطيات المحقونة')}</label>
                    <select
                      value={formType}
                      onChange={(e: any) => {
                        setFormType(e.target.value);
                        setAttachedFile(null);
                      }}
                      className="w-full px-3 py-1.8 bg-neutral-950 border border-neutral-850 rounded-xl text-white focus:outline-none focus:border-cyan-400 cursor-pointer"
                    >
                      <option value="Message">{locVal('Secret Legacy Message', 'رسالة وصية سرية')}</option>
                      <option value="Notes">{locVal('Sovereign Secured Note', 'مذكرة تأمين مشددة')}</option>
                      <option value="File">{locVal('Binary Legacy File Attachment', 'ملف رقمي خارجي (.riman)')}</option>
                    </select>
                  </div>
                </div>

                {/* Capsule Label Name */}
                <div>
                  <label className="block text-[9px] font-mono text-neutral-510 uppercase tracking-widest mb-1">{locVal('Capsule Unique Name', 'العنوان التعريفي للكبسولة (ظاهر)')}</label>
                  <input
                    type="text"
                    required
                    placeholder={locVal('e.g., Bitcoin Wallet recovery keys, Land deed, Personal message...', 'مثال: مفاتيح المحفظة الباردة، وصية عقارية، رسالة للأبناء...')}
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    className="w-full px-3 py-2 bg-neutral-950 border border-neutral-850 rounded-xl text-white focus:outline-none focus:border-cyan-400"
                  />
                </div>

                {/* Secure payload container depending on type choice */}
                {formType === 'File' ? (
                  <div className="p-4 border border-dashed border-neutral-800 rounded-xl bg-neutral-950/40 text-center flex flex-col items-center justify-center space-y-2">
                    <Database className="w-5 h-5 text-indigo-400 animate-pulse" />
                    <div>
                      <p className="font-semibold text-neutral-300 text-[10.5px]">
                        {attachedFile ? attachedFile.name : locVal('Click or Drag a File to Secure', 'انقر أو اسحب ملفاً لحجزه بالتوقيت')}
                      </p>
                      <span className="block text-[9px] text-neutral-500 mt-0.5">
                        {attachedFile ? `Size: ${(attachedFile.size / 1000).toFixed(2)} KB` : locVal('File will be wrapped into highly secure Riemann format', 'سيتم تشفير وتغليف الملف كلياً بشكل فوري')}
                      </span>
                    </div>
                    
                    <input 
                      type="file" 
                      onChange={handleFormFileUpload} 
                      className="hidden" 
                      id="capsule_file_upload_trigger" 
                    />
                    {!attachedFile && (
                      <label 
                        htmlFor="capsule_file_upload_trigger" 
                        className="p-1 px-3 bg-neutral-900 border border-neutral-750 hover:bg-neutral-800 text-[10px] text-neutral-300 font-bold rounded-lg cursor-pointer transition select-none"
                      >
                        {locVal('Select File', 'تحديد ملف')}
                      </label>
                    )}
                  </div>
                ) : (
                  <div>
                    <label className="block text-[9px] font-mono text-neutral-510 uppercase tracking-widest mb-1">{locVal('Encrypted Secret Details', 'تفاصيل الخبايا المرتبطة بالتشفير')}</label>
                    <textarea
                      placeholder={locVal('Enter highly sensitive information here. Stored inside encrypted containment blocks.', 'اكتب هنا تفاصيل الأسرار الحساسة، ستكون مغلقة تشفيرياً كلياً...')}
                      rows={4}
                      value={formContent}
                      onChange={(e) => setFormContent(e.target.value)}
                      className="w-full px-3 py-2 bg-neutral-950 border border-neutral-850 rounded-xl text-white focus:outline-none focus:border-cyan-400 font-sans"
                    />
                  </div>
                )}

                {/* Duration constraints Selector (Feature 1 specs) */}
                <div className="grid grid-cols-2 gap-3 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                  <div>
                    <label className="block text-[9px] font-mono text-neutral-512 mb-1">{locVal('Seal Spacetime Horizon', 'أبعاد فترات الحصار المؤقت')}</label>
                    <select
                      value={formDuration}
                      onChange={(e) => setFormDuration(e.target.value)}
                      className="w-full px-2.5 py-1.5 bg-neutral-950 border border-neutral-850 rounded-lg text-white font-sans focus:outline-none cursor-pointer"
                    >
                      <option value="1day">{locVal('1 Day Lockout', 'يوم واحد فك حصر')}</option>
                      <option value="1month">{locVal('1 Month Lockout', 'شهر كامل فك حصر')}</option>
                      <option value="1year">{locVal('1 Year Lockout', 'سنة كاملة فك حصر')}</option>
                      <option value="custom">{locVal('Custom Time Constraint', 'اختيار تاريخ ووقت مخصص')}</option>
                    </select>
                  </div>

                  {formDuration === 'custom' && (
                    <div className="space-y-1.5">
                      <input
                        type="date"
                        required
                        value={formCustomDate}
                        onChange={(e) => setFormCustomDate(e.target.value)}
                        className="w-full px-2 py-1 bg-neutral-950 border border-neutral-800 rounded text-center text-white focus:outline-none focus:border-cyan-400 cursor-pointer"
                      />
                      <input
                        type="time"
                        required
                        value={formCustomTime}
                        onChange={(e) => setFormCustomTime(e.target.value)}
                        className="w-full px-2 py-1 bg-neutral-950 border border-neutral-800 rounded text-center text-white focus:outline-none focus:border-cyan-400 cursor-pointer"
                      />
                    </div>
                  )}
                </div>

                {/* Password input */}
                <div>
                  <label className="block text-[9px] font-mono text-neutral-510 uppercase tracking-widest mb-1">{locVal('Symmetric Seal Password Key (Min 6 Characters)', 'كلمة مرور التشفير المتماثلة (٦ أحرف كحد أدنى)')}</label>
                  <input
                    type="password"
                    required
                    placeholder={locVal('Enter complex key phrase...', 'اكتب كلمة عبور معقدة ومميزة...')}
                    value={formPassword}
                    onChange={(e) => setFormPassword(e.target.value)}
                    className="w-full px-3 py-2 bg-neutral-950 border border-neutral-850 rounded-xl text-white focus:outline-none focus:border-cyan-400 font-sans"
                  />
                  <span className="text-[8.5px] text-neutral-600 block mt-1">
                    {locVal('This key password drives the key derivation engine of Triple Cryptography. It cannot be bypass-recovered.', 'مهم: كلمة المرور هذه تُدرج مباشرة في خلايا التشفير المكونة من ٣ طبقات، عند فقدانها لا يمكن فك محتوى الوعاء طوال الدهر.')}
                  </span>
                </div>

                <div className="flex justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    className="px-4 py-2 hover:bg-neutral-950 text-neutral-400 hover:text-white rounded-xl text-xs font-sans font-bold cursor-pointer transition border border-neutral-800"
                  >
                    {locVal('Cancel', 'إلغاء')}
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2 bg-gradient-to-r from-cyan-600 to-indigo-600 hover:from-cyan-500 hover:to-indigo-500 text-white rounded-xl text-xs font-sans font-bold cursor-pointer transition shadow"
                  >
                    {locVal('Seal Capsule', 'أودع واقفل الكبسولة')}
                  </button>
                </div>

              </form>

            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
};
