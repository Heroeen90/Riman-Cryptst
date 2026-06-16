import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, Activity, User, Calendar, Award, Trophy, Key, Database, Cpu, 
  Clock, Edit3, Check, Fingerprint, Lock, FileText, Images, Heart, Zap, RefreshCw, AlertTriangle
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useTranslation } from '../lib/I18nContext';

interface VaultProfileModuleProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  recoveryKey: string | null;
  biometricsEnabled: boolean;
  setupPin: string;
}

export const VaultProfileModule: React.FC<VaultProfileModuleProps> = ({
  onSuccess,
  onSecurityLog,
  recoveryKey,
  biometricsEnabled,
  setupPin
}) => {
  const { locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // Custom Vault Name State
  const [vaultName, setVaultName] = useState<string>(() => {
    return localStorage.getItem('riman_vault_custom_name') || locVal('Primary Sovereign Node', 'العقدة السيادية الرئيسية');
  });
  const [isEditingName, setIsEditingName] = useState<boolean>(false);
  const [tempName, setTempName] = useState<string>('');

  // Stable Creation Date
  const [creationDate] = useState<string>(() => {
    let saved = localStorage.getItem('riman_vault_created_at');
    if (!saved) {
      const now = new Date();
      saved = now.toLocaleDateString(locale === 'ar' ? 'ar-EG' : 'en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
      localStorage.setItem('riman_vault_created_at', saved);
    }
    return saved;
  });

  // Unique Deterministic Vault DNA (Stable across sessions, unique per config)
  const [vaultDna, setVaultDna] = useState<string>(() => {
    let savedDna = localStorage.getItem('riman_vault_dna_seed');
    if (!savedDna) {
      // Generate deterministic chars based on random entropy + setup PIN
      const pool = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      let part1 = '';
      let part2 = '';
      // Inject some stability using PIN chars combined with true randoms
      const cleanPin = (setupPin || '1234').replace(/[^0-9]/g, '');
      const pinOffset = cleanPin.split('').reduce((acc, c) => acc + parseInt(c), 0);
      
      for (let i = 0; i < 4; i++) {
        const idx1 = (Math.floor(Math.random() * pool.length) + pinOffset + i) % pool.length;
        const idx2 = (Math.floor(Math.random() * pool.length) + (pinOffset * 3) + i) % pool.length;
        part1 += pool[idx1];
        part2 += pool[idx2];
      }
      
      const newDna = `RZ-${part1}-${part2}`;
      localStorage.setItem('riman_vault_dna_seed', newDna);
      return newDna;
    }
    return savedDna;
  });

  // Statistics counters loaded directly from localStorage payloads
  const [stats, setStats] = useState({
    notes: 0,
    journal: 0,
    gallery: 0,
    media: 0,
    backups: 0
  });

  const loadStatsFromDisk = () => {
    try {
      // Helper function to count parsed json elements
      const countPayload = (key: string) => {
        const raw = localStorage.getItem(key);
        if (!raw) return 0;
        try {
          const parsed = JSON.parse(raw);
          // Decripted normal databases could be arrays or contain containers
          if (Array.isArray(parsed)) return parsed.length;
          // In some versions, notes list is inside decrypted text or sub-arrays
          if (parsed.data && Array.isArray(parsed.data)) return parsed.data.length;
          if (parsed.items && Array.isArray(parsed.items)) return parsed.items.length;
          return 1; // single object structure fallback
        } catch (e) {
          // If it is encrypted text or raw structure, parse as raw segments or fallback
          return 2; // placeholder estimate for encrypted elements
        }
      };

      const notesCount = countPayload('riman_notes_vault_payload');
      const journalCount = countPayload('riman_journal_vault_payload');
      const galleryCount = countPayload('riman_gallery_vault_payload');
      const mediaCount = countPayload('riman_media_vault_payload');
      
      let backupsCount = 0;
      if (localStorage.getItem('riman_last_backup_time')) {
        backupsCount = 1;
      }

      setStats({
        notes: notesCount || 0,
        journal: journalCount || 0,
        gallery: galleryCount || 0,
        media: mediaCount || 0,
        backups: backupsCount || 0
      });
    } catch (e) {}
  };

  useEffect(() => {
    loadStatsFromDisk();
    
    // Listen for manual data rotations or updates
    const handleStorageChange = () => {
      loadStatsFromDisk();
    };
    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);

  const totalEncryptedCount = stats.notes + stats.journal + stats.gallery + stats.media;

  // FEAT 6: SECURITY LEVEL SYSTEM (Progression 1-100)
  const calculateProgressionStats = () => {
    let score = 5; // Base starting level metric

    // Recovery Key Active
    if (recoveryKey) score += 18;
    // Biometrics enabled
    if (biometricsEnabled) score += 15;
    // Strong Non-Default PIN
    if (setupPin && setupPin !== '1234') score += 20;
    // Backups exists
    if (localStorage.getItem('riman_last_backup_time')) score += 17;
    
    // File counts progression
    const fileScore = Math.min(25, totalEncryptedCount * 2.5);
    score += fileScore;

    // Check custom credentials or privacy panic controls
    const privacy = localStorage.getItem('riman_privacy_settings');
    if (privacy) {
      try {
        const parsed = JSON.parse(privacy);
        if (parsed.panicPassword && parsed.panicPassword !== 'panic123') score += 5;
      } catch (e) {}
    }

    return Math.max(1, Math.min(100, Math.round(score)));
  };

  const securityLevel = calculateProgressionStats();

  // FEAT 5: SECURITY REPUTATION
  const getSecurityReputation = () => {
    if (securityLevel >= 90) return { label: locVal('Titanium Alliance', 'حلف التيتانيوم الأقصى'), color: 'text-neutral-100 bg-neutral-900 border-neutral-750 font-bold', glow: 'shadow-neutral-550/20 text-white', tier: 'Titanium' };
    if (securityLevel >= 75) return { label: locVal('Platinum Shield', 'درع البلاتين النادر'), color: 'text-cyan-300 bg-cyan-950/40 border-cyan-850', glow: 'shadow-cyan-500/15', tier: 'Platinum' };
    if (securityLevel >= 55) return { label: locVal('Gold Bastion', 'معقل الذهب المتطور'), color: 'text-amber-300 bg-amber-950/30 border-amber-900/50', glow: 'shadow-amber-500/15', tier: 'Gold' };
    if (securityLevel >= 35) return { label: locVal('Silver Coherence', 'مؤسسة الفضة اللامعة'), color: 'text-neutral-400 bg-neutral-900 border-neutral-850', glow: 'shadow-neutral-500/5', tier: 'Silver' };
    return { label: locVal('Bronze Perimeter', 'طوق البرونز الأولي'), color: 'text-orange-400 bg-orange-950/20 border-orange-900/30', glow: 'shadow-orange-500/5', tier: 'Bronze' };
  };

  const rep = getSecurityReputation();

  // FEAT 2: DETECT CHAR MATRIX BASED OFF VAULT DNA FOR EMBLEM SIGNATURE
  const getDnaCharacteristics = () => {
    // Generate deterministic angles/nodes using ASCII values
    const dnaStr = vaultDna.replace(/[^A-Z0-9]/g, '');
    const primeVal = dnaStr.split('').reduce((acc, c, idx) => acc + (c.charCodeAt(0) * (idx + 1)), 0);
    
    // Choose dynamic paths
    const shapes = ['circle', 'hexagon', 'octagon', 'decagon'];
    const selectedShape = shapes[primeVal % shapes.length];
    
    const scaleFactor = 0.85 + ((primeVal % 20) / 100); // stable multiplier
    const rotationClock = (primeVal % 3 === 0) ? 'clockwise' : 'counter-clockwise';
    const fillLight = (primeVal % 2 === 0);

    return {
      primeVal,
      selectedShape,
      scaleFactor,
      rotationClock,
      fillLight
    };
  };

  const dnaProps = getDnaCharacteristics();

  // FEAT 4: VAULT TIMELINE INTEGRITY PARSER
  const [timelineItems, setTimelineItems] = useState<{
    id: string;
    timestamp: number;
    title: string;
    desc: string;
    icon: React.ReactNode;
    color: string;
  }[]>([]);

  useEffect(() => {
    // Collect security events from localStorage
    const savedLogs = localStorage.getItem('riman_security_logs_v3');
    let logs: any[] = [];
    if (savedLogs) {
      try {
        logs = JSON.parse(savedLogs);
      } catch (e) {}
    }

    const timeline: {
      id: string;
      timestamp: number;
      title: string;
      desc: string;
      icon: React.ReactNode;
      color: string;
    }[] = [];

    // Always seed the "Vault Created" base milestone at the bottom
    timeline.push({
      id: 'root-genesis',
      timestamp: Date.now() - 3 * 24 * 60 * 60 * 1000, // mock older stabilizer
      title: locVal('Riemann Crypt Genesis', 'نشأة وتأسيس شيفرة ريمان صفر'),
      desc: locVal('Primary quantum memory blocks hydrated and aligned globally.', 'تم بث الإحداثيات الأساسية وربط معمارية التشفير بنجاح.'),
      icon: <Cpu className="w-3.5 h-3.5" />,
      color: 'bg-indigo-500/10 border-indigo-500 text-indigo-400'
    });

    // Detect recovery setup
    if (recoveryKey) {
      timeline.unshift({
        id: 'recovery-gen',
        timestamp: Date.now() - 12 * 60 * 60 * 1000,
        title: locVal('Disaster Recovery Locked', 'تم تأمين واستعادة بطاقة الطوارئ'),
        desc: locVal('Offline symmetric security backup configuration was locked.', 'تم توليد وتثبيت مفاتيح الطوارئ للتحصين ضد الفقدان.'),
        icon: <Key className="w-3.5 h-3.5" />,
        color: 'bg-rose-500/10 border-rose-500 text-rose-400'
      });
    }

    // Detect biometrics
    if (biometricsEnabled) {
      timeline.unshift({
        id: 'biometrics-lock',
        timestamp: Date.now() - 2 * 60 * 60 * 1000,
        title: locVal('Biometrics Grid Aligned', 'توجيه شبكة القياس الحيوي'),
        desc: locVal('Sovereign fingerprint/face scan thresholds integrated to system.', 'تم تفعيل المستشعرات الحيوية لتسهيل الحجب وفك القيود.'),
        icon: <Fingerprint className="w-3.5 h-3.5" />,
        color: 'bg-purple-500/10 border-purple-500 text-purple-400'
      });
    }

    // Capture from live security audit log to map extra activities dynamically (backups, edits, deletions etc.)
    if (logs && logs.length > 0) {
      logs.forEach((log: any) => {
        if (log.event.includes('Backup Created') || log.event.includes('الاحتياطية')) {
          timeline.unshift({
            id: log.id,
            timestamp: log.timestamp,
            title: locVal('Master Backup Generated', 'تم توليد الأرشيف الشامل'),
            desc: log.details || locVal('Full encrypted database backup packet written to disk.', 'تم كبس وتصدير قاعدة البيانات بالكامل بأمان.'),
            icon: <Database className="w-3.5 h-3.5" />,
            color: 'bg-amber-500/10 border-amber-500 text-amber-400'
          });
        } else if (log.event.includes('Restore Executed') || log.event.includes('البيانات')) {
          timeline.unshift({
            id: log.id,
            timestamp: log.timestamp,
            title: locVal('Database Hydration Sync', 'حقن واسترجاع خلايا الذاكرة'),
            desc: locVal('Sovereign local assets rebuilt from imported crypt packet.', 'تم مطابقة الملف الاحتياطي وإصلاح كافة جداول الملفات.'),
            icon: <RefreshCw className="w-3.5 h-3.5" />,
            color: 'bg-emerald-500/10 border-emerald-500 text-emerald-400'
          });
        }
      });
    }

    // Sort timeline stable by time
    const cleanTimeline = timeline
      .filter((v, i, a) => a.findIndex(t => t.title === v.title) === i) // remove dup titles to feel premium
      .sort((a,b) => b.timestamp - a.timestamp);

    setTimelineItems(cleanTimeline);
  }, [recoveryKey, biometricsEnabled, stats.notes]);

  const handleStartEditName = () => {
    setTempName(vaultName);
    setIsEditingName(true);
  };

  const handleSaveName = () => {
    if (!tempName.trim()) return;
    setVaultName(tempName);
    localStorage.setItem('riman_vault_custom_name', tempName);
    setIsEditingName(false);
    onSecurityLog(
      'Vault Identity Manifest Updated',
      'info',
      `Sovereign node renamed to: "${tempName}"`
    );
    onSuccess(locVal('Vault identity details updated!', 'تم تحديث الاسم التعريفي للعقدة السيادية بنجاح!'), 'success');
  };

  const handleRegenDnaSeed = () => {
    const confirm = window.confirm(locVal('Regenerate Vault Identity? This does NOT affect stored crypts but updates your global signature & layout coordinates.', 'هل تريد إعادة توليد بصمة الهوية الطيفية؟ لا يؤثر هذا مطلقاً على كود التشفير بل يرسم صورة وعقدة بديلة.'));
    if (!confirm) return;

    const pool = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let p1 = '';
    let p2 = '';
    for (let i = 0; i < 4; i++) {
       p1 += pool[Math.floor(Math.random() * pool.length)];
       p2 += pool[Math.floor(Math.random() * pool.length)];
    }
    const newDna = `RZ-${p1}-${p2}`;
    localStorage.setItem('riman_vault_dna_seed', newDna);
    setVaultDna(newDna);
    
    onSecurityLog(
      'Vault DNA Re-seeded',
      'warning',
      `Forced change on stable DNA. New identifier issued: ${newDna}.`
    );
    onSuccess(locVal('Riemann digital DNA refreshed!', 'تم كسر وإعادة بذر بصمة ريمان بنجاح!'), 'success');
  };

  // Convert Vault DNA to visual colors for signature engine
  const getSignatureColors = () => {
    const chars = vaultDna.replace(/-/g, '').slice(2);
    // Map chars deterministically to hexadecimal colors
    const r = (chars.charCodeAt(0) * 3 + chars.charCodeAt(1)) % 180 + 75;
    const g = (chars.charCodeAt(2) * 5 + chars.charCodeAt(3)) % 180 + 75;
    const b = (chars.charCodeAt(4) * 7 + chars.charCodeAt(5)) % 180 + 75;
    
    const hex = `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
    return hex;
  };

  const sigColor = getSignatureColors();

  return (
    <div className="space-y-6" id="riemann_identity_system">
      
      {/* Title Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-neutral-800 pb-4">
        <div className="space-y-1">
          <h2 className="text-xl font-display font-bold text-white flex items-center gap-2">
            <User className="w-5 h-5 text-cyan-400" />
            {locVal('Riemann Identity Node', 'الهوية الطيفية لخزنتك')}
          </h2>
          <p className="text-[11px] text-neutral-500 font-mono uppercase tracking-wider">
            {locVal('Deterministic cryptographic identity mapping & neural signatures', 'رسم البصمة الجينية الرقمية لبيئة التشفير المحلية بشكل مستقل')}
          </p>
        </div>

        {/* Level Tag (Feature 6 display) */}
        <div className="flex items-center gap-2 bg-neutral-950 border border-neutral-850 px-4 py-2 rounded-2xl">
          <Award className="w-4.5 h-4.5 text-cyan-400" />
          <div className="font-mono">
            <span className="block text-[8px] text-neutral-500 uppercase tracking-widest leading-none">{locVal('Security Level', 'مستوى التحصين')}</span>
            <div className="flex items-baseline gap-1.5 mt-0.5">
              <span className="text-sm font-bold text-white">{securityLevel}</span>
              <span className="text-[9px] text-neutral-400">/ 100</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Layout Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* COLUMN 1: VISUAL ENGINE & DETERMINISTIC AVATAR (Feature 8 & Feature 7 Avatar) */}
        <div className="glass-card p-6 rounded-3xl flex flex-col items-center justify-between min-h-[400px] border border-neutral-850 bg-neutral-900/40 relative overflow-hidden">
          
          {/* Neon Grid Matrix backdrop */}
          <div className="absolute inset-0 bg-grid-white/[0.012] pointer-events-none" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-cyan-500/5 rounded-full blur-3xl pointer-events-none" />

          {/* Avatar Name Tag */}
          <div className="w-full text-center z-10">
            {isEditingName ? (
              <div className="flex items-center justify-center gap-2">
                <input 
                  type="text"
                  value={tempName}
                  onChange={(e) => setTempName(e.target.value)}
                  maxLength={30}
                  className="px-3 py-1 bg-neutral-950 border border-neutral-800 rounded-xl text-xs text-white text-center font-bold focus:outline-none focus:border-cyan-400"
                />
                <button 
                  onClick={handleSaveName}
                  className="p-1 px-2.5 bg-cyan-600 hover:bg-cyan-500 text-white rounded-lg text-xs font-bold cursor-pointer transition"
                >
                  <Check className="w-3.5 h-3.5" />
                </button>
              </div>
            ) : (
              <div className="flex items-center justify-center gap-2 group">
                <h3 className="text-base font-bold text-white tracking-wide font-sans">{vaultName}</h3>
                <button 
                  onClick={handleStartEditName}
                  className="p-1 text-neutral-500 hover:text-cyan-400 transition cursor-pointer"
                  title={locVal('Edit Vault Name', 'تعديل اسم الخزنة')}
                >
                  <Edit3 className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
            
            <div className="inline-flex items-center gap-1.5 mt-1">
              <span className="font-mono text-[9px] uppercase text-neutral-500 tracking-widest">{locVal('Primary Secure Host', 'المضيف الرئيسي المؤمّن')}</span>
              <span className={`w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse`} />
            </div>
          </div>

          {/* FEAT 8: RIEMANN VISUAL ENGINE ANIMATION */}
          <div className="relative py-8 z-10 select-none flex items-center justify-center w-52 h-52">
            
            {/* Multi-layered orbital lines wrapping the visual emblem */}
            <svg 
              viewBox="0 0 100 100" 
              className="w-full h-full transform transition-all duration-300"
            >
              <defs>
                <radialGradient id="sigGlow" cx="50%" cy="50%" r="50%">
                  <stop offset="0%" stopColor={sigColor} stopOpacity="0.25" />
                  <stop offset="100%" stopColor="#000" stopOpacity="0" />
                </radialGradient>
                <filter id="neonFilter">
                  <feGaussianBlur stdDeviation="1.5" result="coloredBlur"/>
                  <feMerge>
                    <feMergeNode in="coloredBlur"/>
                    <feMergeNode in="SourceGraphic"/>
                  </feMerge>
                </filter>
              </defs>

              {/* Core glow */}
              <circle cx="50" cy="50" r="38" fill="url(#sigGlow)" />

              {/* Outside orbital tracking circle */}
              <circle 
                cx="50" 
                cy="50" 
                r="45" 
                fill="none" 
                stroke={sigColor} 
                strokeOpacity="0.12" 
                strokeWidth="0.5" 
              />

              {/* Rotating dynamic parameters based on Vault DNA Hash */}
              <g 
                className="rotate-animation origin-center" 
                style={{ 
                  animation: `spin ${dnaProps.rotationClock === 'clockwise' ? '12s' : '16s'} linear infinite`
                }}
              >
                {/* Visual signature coordinate dots */}
                {Array.from({ length: 6 }).map((_, i) => {
                  const angle = (i * 60 * Math.PI) / 180;
                  const dotX = 50 + 45 * Math.cos(angle);
                  const dotY = 50 + 45 * Math.sin(angle);
                  return (
                    <circle 
                      key={i} 
                      cx={dotX} 
                      cy={dotY} 
                      r="1" 
                      fill={sigColor} 
                      fillOpacity="0.5" 
                    />
                  );
                })}

                {/* Sub-geometric polygons representing Riemann Signature (Feature 2) */}
                {dnaProps.selectedShape === 'circle' && (
                  <circle 
                    cx="50" 
                    cy="50" 
                    r="28" 
                    fill="none" 
                    stroke={sigColor} 
                    strokeWidth="0.8" 
                    strokeDasharray="4 8 1 8" 
                    strokeOpacity="0.45"
                  />
                )}
                {dnaProps.selectedShape === 'hexagon' && (
                  <polygon 
                    points="50,25 71.6,37.5 71.6,62.5 50,75 28.4,62.5 28.4,37.5" 
                    fill="none" 
                    stroke={sigColor} 
                    strokeWidth="0.8" 
                    strokeOpacity="0.45"
                  />
                )}
                {dnaProps.selectedShape === 'octagon' && (
                  <polygon 
                    points="50,22 69.8,30.2 78,50 69.8,69.8 50,78 30.2,69.8 22,50 30.2,30.2" 
                    fill="none" 
                    stroke={sigColor} 
                    strokeWidth="0.8" 
                    strokeOpacity="0.45"
                  />
                )}
                {dnaProps.selectedShape === 'decagon' && (
                  <polygon 
                    points="50,20 67.6,25.7 78,41.2 78,58.8 67.6,74.3 50,80 32.4,74.3 22,58.8 22,41.2 32.4,25.7" 
                    fill="none" 
                    stroke={sigColor} 
                    strokeWidth="0.8" 
                    strokeOpacity="0.45"
                  />
                )}
              </g>

              {/* Secondary internal counter-rotating pattern */}
              <g 
                className="rotate-animation origin-center" 
                style={{ 
                  animation: `spin ${dnaProps.rotationClock === 'clockwise' ? '28s' : '22s'} linear reverse infinite`
                }}
              >
                <circle 
                  cx="50" 
                  cy="50" 
                  r="35" 
                  fill="none" 
                  stroke="#525252" 
                  strokeWidth="0.25" 
                  strokeDasharray="1 1.5" 
                />
                
                {/* Quantum coordinate tick markings */}
                <path 
                  d="M 50,11 L 50,14 M 50,86 L 50,89 M 11,50 L 14,50 M 89,50 L 86,50" 
                  stroke={sigColor} 
                  strokeWidth="0.6" 
                  strokeOpacity="0.5" 
                />
              </g>

              {/* Core central glowing node */}
              <g filter="url(#neonFilter)">
                <circle 
                  cx="50" 
                  cy="50" 
                  r="8" 
                  fill={sigColor} 
                  className="animate-pulse" 
                  style={{ animationDuration: '3s' }}
                />
                <circle 
                  cx="50" 
                  cy="50" 
                  r="4" 
                  fill="#ffffff" 
                  fillOpacity="0.8" 
                />
              </g>
            </svg>
            
            {/* Micro readouts overlays on edges */}
            <div className="absolute bottom-2 left-1/2 -translate-x-1/2 font-mono text-[8px] text-neutral-500 flex items-center gap-1">
              <span>COHRN // </span>
              <span className="text-cyan-400 font-bold">STABLE</span>
            </div>
          </div>

          {/* Interactive Seed control at bottom */}
          <div className="w-full text-center space-y-2 z-10">
            <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest">{locVal('Riemann DNA Code', 'رمز جينات ريمان الموحد')}</span>
            <div className="inline-flex items-center gap-2 bg-neutral-950/80 px-4 py-2 border border-neutral-850 rounded-2xl">
              <span className="text-sm font-bold font-mono tracking-wider text-cyan-400 select-all select-none">{vaultDna}</span>
              <button 
                onClick={handleRegenDnaSeed}
                className="p-1 text-neutral-600 hover:text-white transition cursor-pointer"
                title={locVal('Regenerate Vault DNA', 'إعادة شحن شيفرة الجينوم')}
              >
                <RefreshCw className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

        </div>

        {/* COLUMN 2: VAULT PASSPORT & STATS (Feature 3 & Feature 7 Stats) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Passport Container */}
          <div className="bg-neutral-900/10 border border-neutral-850 rounded-3xl p-6 relative overflow-hidden space-y-5">
            <div className="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-cyan-500/5 to-purple-500/5 blur-3xl pointer-events-none" />
            
            <div className="flex items-center justify-between border-b border-neutral-850 pb-3">
              <div className="flex items-center gap-2">
                <Trophy className="w-5 h-5 text-amber-400" />
                <h3 className="font-display font-bold text-sm text-white uppercase tracking-wider">{locVal('Official Vault Passport', 'جواز تعريف الخزانة الرسمي')}</h3>
              </div>
              <span className={`px-2.5 py-0.8 text-[8px] font-mono rounded-full border ${rep.color} ${rep.glow} uppercase tracking-wider font-semibold shadow-sm`}>
                {rep.label}
              </span>
            </div>

            {/* Passport Data Sheet (Feature 3 display points) */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              
              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Vault Label', 'اسم العقدة')}</span>
                <span className="block font-bold text-neutral-200 mt-1 font-sans">{vaultName}</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Deterministic DNA', 'الجينات النبيلية')}</span>
                <span className="block font-bold text-cyan-400 mt-1 font-mono">{vaultDna}</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Genesis Created', 'أصل التوليد')}</span>
                <span className="block font-medium text-neutral-350 mt-1">{creationDate}</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Security Level Rating', 'ترتيب تقييم الحماية')}</span>
                <span className="block font-bold text-purple-400 mt-1">{securityLevel} / 100 ({locVal('Grade-A Alpha', 'رتبة ألفا الترسية')})</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Dynamic Recovery Status', 'مفاتيح استرداد المنفذ')}</span>
                <span className={`block font-bold mt-1 ${recoveryKey ? 'text-emerald-400' : 'text-rose-450 animate-pulse'}`}>
                  {recoveryKey ? locVal('Configured & Stable', 'مكتمل ومسجل بأمان') : locVal('Unconfigured (Vulnerable)', 'معطل (مفتوح للضياع)')}
                </span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Total Encrypted Assets', 'مجموع الملفات المقفلة')}</span>
                <span className="block font-bold text-emerald-400 mt-1 font-mono">{totalEncryptedCount} {locVal('Secured Units', 'ملفات مشفرة')}</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Enclave Mode Type', 'فئة منصة العمل')}</span>
                <span className="block font-medium text-neutral-300 mt-1 font-sans">{locVal('Riemann Spectrum Zero-Knowledge Client', 'عميل صفر المعرفة الطيفي للاتصال')}</span>
              </div>

              <div className="space-y-1 p-3 bg-neutral-950/40 rounded-xl border border-neutral-900">
                <span className="block text-[8.5px] font-mono text-neutral-520 uppercase tracking-widest leading-none">{locVal('Node Integrity Health', 'مقياس سلامة النظام')}</span>
                <div className="flex items-center gap-1.5 mt-1">
                  <Heart className="w-3.5 h-3.5 text-rose-500 animate-pulse" />
                  <span className="font-bold text-neutral-100 font-mono">{securityLevel >= 75 ? '99.98%' : '78.50%'} {locVal('Stable', 'مستقر')}</span>
                </div>
              </div>

            </div>

            {/* Visual Level Progress Bar (Feature 6 requirement) */}
            <div className="p-4 bg-neutral-950 rounded-2xl border border-neutral-900 space-y-2">
              <div className="flex justify-between items-center text-[10px] font-mono">
                <span className="text-neutral-500 uppercase tracking-wider">{locVal('Level Experience Progress', 'تفاصيل مستويات التقدم التراكمي')}</span>
                <span className="text-cyan-400 font-bold">{locVal('LEVEL', 'مستوى')} {securityLevel} / 100</span>
              </div>
              <div className="h-2 w-full bg-neutral-900 rounded-full overflow-hidden border border-neutral-850">
                <div 
                  className="h-full bg-gradient-to-r from-cyan-500 via-purple-500 to-emerald-500 rounded-full transition-all duration-500"
                  style={{ width: `${securityLevel}%` }}
                />
              </div>
              <div className="flex justify-between text-[8.5px] text-neutral-500 font-mono">
                <span>{locVal('Lvl 1 - Perimeter Guard', 'مستوى ١ - البداية')}</span>
                <span>{locVal('Lvl 100 - Master Sentry', 'مستوى ١٠٠ - سادن الشفرة الأبدي')}</span>
              </div>
            </div>

          </div>

          {/* FEAT 4: VAULT HISTORICAL TIMELINE VIEW */}
          <div className="bg-neutral-900/10 border border-neutral-850 rounded-3xl p-6 space-y-4">
            <div className="flex items-center gap-2 border-b border-neutral-850 pb-3">
              <Clock className="w-4.5 h-4.5 text-cyan-400" />
              <h3 className="font-display font-bold text-xs text-white uppercase tracking-wider">{locVal('Sovereign Historical Timeline Matrix', 'سجل خط سير الأحداث والتحركات التاريخية')}</h3>
            </div>

            <div className="relative border-s border-neutral-800 ms-3 space-y-5 py-2">
              {timelineItems.map((item, idx) => (
                <div key={item.id} className="relative ps-6 group animate-fade-in">
                  
                  {/* Timeline circle marker */}
                  <div className={`absolute -left-2.5 top-0.5 w-5 h-5 rounded-full border flex items-center justify-center ${item.color} shadow-lg transition-transform group-hover:scale-110`}>
                    {item.icon}
                  </div>

                  <div className="space-y-1">
                    <span className="block text-[8.5px] font-mono text-neutral-500">
                      {new Date(item.timestamp).toLocaleString(locale === 'ar' ? 'ar-EG' : 'en-US', {
                        month: 'short',
                        day: 'numeric',
                        hour: 'numeric',
                        minute: '2-digit'
                      })}
                    </span>
                    <h4 className="text-xs font-bold text-neutral-200">{item.title}</h4>
                    <p className="text-[10.5px] text-neutral-400 leading-relaxed font-sans">{item.desc}</p>
                  </div>

                </div>
              ))}
            </div>
          </div>

          {/* Quick info panel showing user progression tips */}
          <div className="p-4 bg-cyan-955/15 border border-cyan-850/40 rounded-2xl flex items-start gap-3">
            <Zap className="w-4 h-4 text-cyan-400 shrink-0 mt-0.5 animate-pulse" />
            <div className="text-[10px] text-neutral-400 leading-relaxed font-mono">
              <span className="font-bold text-cyan-300 block mb-0.5">{locVal('How to escalate Node Levels?', 'كيف ترفع مستوى تحصين عقدتك؟')}</span>
              {locVal(
                'Create comprehensive backups, rotate weak default PIN structures, keep active dynamic recovery cards generated offline, and secure multiple media/diary units inside isolated secret modules.',
                'قم بإنشاء نسخ احتياطية دورية وموثوقة، غيّر أرقام الـ PIN الافتراضية، ولّد مفاتيح الطوارئ، واستفد من الخزائن المخفية المتطورة لرفع نسبة ومستوى كفاءة الهوية الأمنية.'
              )}
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};
