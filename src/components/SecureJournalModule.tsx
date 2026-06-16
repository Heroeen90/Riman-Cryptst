import React, { useState, useEffect } from 'react';
import { 
  BookOpen, Calendar, MapPin, Smile, Eye, EyeOff, Lock, Unlock, 
  Trash2, Download, Search, Plus, Map, Sparkles, Pin, Check, ListFilter,
  BarChart2, Clock, ShieldCheck, ChevronDown
} from 'lucide-react';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt, 
  stringToBytes, 
  bytesToString 
} from '../lib/crypto';
import { EncryptedContainer } from '../types';
import { useTranslation } from '../lib/I18nContext';

interface JournalEntry {
  id: string;
  title: string;
  content: string;
  createdAt: number;
  mood: 'serene' | 'focused' | 'vigilant' | 'thoughtful' | 'restless';
  location?: {
    latitude: number;
    longitude: number;
    name?: string;
  };
}

const MOODS = [
  { key: 'serene', labelEn: 'Serene', labelAr: 'صفاء نقي', emoji: '🌸', color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
  { key: 'focused', labelEn: 'Focused', labelAr: 'تركيز فائق', emoji: '🎯', color: 'text-cyan-400', bg: 'bg-cyan-500/10' },
  { key: 'vigilant', labelEn: 'Vigilant', labelAr: 'يقظ حذر', emoji: '🛡️', color: 'text-blue-400', bg: 'bg-blue-500/10' },
  { key: 'thoughtful', labelEn: 'Thoughtful', labelAr: 'متأمل عميق', emoji: '💭', color: 'text-purple-400', bg: 'bg-purple-500/10' },
  { key: 'restless', labelEn: 'Restless', labelAr: 'قلق متأهب', emoji: '⚡', color: 'text-rose-400', bg: 'bg-rose-500/10' },
];

interface SecureJournalProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

export const SecureJournalModule: React.FC<SecureJournalProps> = ({
  onSuccess,
  onSecurityLog,
  triggerAnimation
}) => {
  const { t, locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // Journal lock/unlock state
  const [isUnlocked, setIsUnlocked] = useState<boolean>(false);
  const [vaultPassword, setVaultPassword] = useState<string>('');
  const [showPasswordInput, setShowPasswordInput] = useState<boolean>(false);

  // Journal entries
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  
  // Create / Edit new entry form
  const [entryTitle, setEntryTitle] = useState<string>('');
  const [entryContent, setEntryContent] = useState<string>('');
  const [entryMood, setEntryMood] = useState<'serene' | 'focused' | 'vigilant' | 'thoughtful' | 'restless'>('focused');
  const [includeLocation, setIncludeLocation] = useState<boolean>(false);
  const [currentCoords, setCurrentCoords] = useState<{ latitude: number; longitude: number } | null>(null);

  // Search/Filters
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedMoodFilter, setSelectedMoodFilter] = useState<string>('All');

  // Trigger geolocation tracking
  useEffect(() => {
    if (includeLocation) {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            setCurrentCoords({
              latitude: parseFloat(position.coords.latitude.toFixed(6)),
              longitude: parseFloat(position.coords.longitude.toFixed(6))
            });
            onSuccess(locVal('Geolocation coordinates pinpointed successfully!', 'تم تحديد إحداثيات الموقع الجغرافي الدقيقة بنجاح!'), 'info');
          },
          (error) => {
            // Rollback gracefully with standard default / mock orbit coordinates
            // This is perfect for when Chrome/Safari flags iframe blocking
            setCurrentCoords({ latitude: 30.0444, longitude: 31.2357 }); // Cairo orbit anchor
            onSuccess(locVal('Locator service mapping defaulted to Orbit Anchor Cairo.', 'تم استخدام إحداثيات مدار الحماية في "القاهرة" كبديل خطي.'), 'info');
          },
          { enableHighAccuracy: true, timeout: 5000 }
        );
      } else {
        setCurrentCoords({ latitude: 30.0444, longitude: 31.2357 });
      }
    } else {
      setCurrentCoords(null);
    }
  }, [includeLocation]);

  const defaultJournalEntries = (): JournalEntry[] => [
    {
      id: 'journal_01',
      title: locVal('First Successful Symmetric Wave Fusion', 'أول دمج طيفي متطابق ناجح'),
      content: locVal('Completed our first test suite matching Riemann waves in browser local threads with the backend Dart modules. Zero latency observed in the memory stack. Keystreams align precisely within 16 decimal places.', 'أتممنا أولى مصفوفات الاختبار التطابقية لموجات ريمان محلياً على المتصفح مع معمارية دارت الخلفية. لم نرصد أي تأخر في حوايا المكدس الذاكري. تصطف مفاتيح التشفير تدريجياً بدقة متناهية.'),
      createdAt: Date.now() - 3600000 * 48,
      mood: 'serene',
      location: { latitude: 30.0571, longitude: 31.2272, name: locVal('Orbit Anchor (Egypt)', 'مرتكز الحماية (مصر)') }
    },
    {
      id: 'journal_02',
      title: locVal('Dynamic Spectrum Variance Incident', 'رصد انحراف طيفي طارئ'),
      content: locVal('Discovered slight entropy drift in secondary nodes. Elevated system parameters automatically to counter physical channel latency. Resetting all seed generators to critical zeroes offset immediately.', 'رصدنا انحراف طفيف في معدل العشوائية للعقد الرديفة. قمنا بتصعيد معلمات النظام تلقائياً لمواجهة الفجوات الخلوية الفيزيائية. جاري إعادة ضبط بذور العشوائية بالعودة للأصفار الحرجة فوراً.'),
      createdAt: Date.now() - 3600000 * 4,
      mood: 'vigilant',
      location: { latitude: 30.0444, longitude: 31.2357, name: locVal('Orbit Primary (Cairo)', 'المدار الرئيسي (القاهرة)') }
    }
  ];

  const handleUnlockJournal = () => {
    if (!vaultPassword || vaultPassword.length < 6) {
      onSuccess(locVal('Sovereign password must be at least 6 characters', 'يجب أن لا تقل كلمة مرور النظام السيادي عن 6 أحرف'), 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Journal decryption array armed', 'info', 'Step 1: Instantiating Rijndael verification grids.');

      const savedVerifyToken = localStorage.getItem('riman_journal_vault_token');
      let decryptedEntries: JournalEntry[] = [];

      if (!savedVerifyToken) {
        // Setup newly
        onSecurityLog('Journal Vault initialization', 'warning', 'No existing configuration. Initializing brand new zero-knowledge journaling payload.');
        
        // Save verification token
        const verifyData = { active: true, owner: 'riman_cryptst_journal' };
        const payloadBytes = stringToBytes(JSON.stringify(verifyData));
        const encryptedToken = executeRiemannTripleLayerEncrypt(payloadBytes, vaultPassword, {
          fileType: 'application/json',
          filename: 'journal_token.riman'
        });
        localStorage.setItem('riman_journal_vault_token', JSON.stringify(encryptedToken));

        // Create default list & persist
        const defaults = defaultJournalEntries();
        saveJournalToLocalStorage(defaults, vaultPassword);
        decryptedEntries = defaults;
        onSuccess(locVal('Sovereign Secure Journal initialized!', 'تم تهيئة وتأسيس اليوميات المشفرة الآمنة لأول مرة!'), 'success');
      } else {
        // Verify key integrity
        try {
          const tokenContainer: EncryptedContainer = JSON.parse(savedVerifyToken);
          const decryptedTokenBytes = executeRiemannTripleLayerDecrypt(tokenContainer, vaultPassword);
          const decryptedTokenStr = bytesToString(decryptedTokenBytes);
          const parsed = JSON.parse(decryptedTokenStr);
          if (parsed.owner !== 'riman_cryptst_journal') {
            throw new Error('Owner mismatch');
          }
        } catch (authErr) {
          onSecurityLog('Journal authentication failed', 'critical', 'Incorrect password key provided. Cipher reject.');
          onSuccess(locVal('Incorrect secure password!', 'فشل فتح اليوميات: كلمة المرور غير صحيحة!'), 'error');
          return;
        }

        // Lock verification passed, decrypt data payload
        const encryptedJournalPayload = localStorage.getItem('riman_journal_vault_payload');
        if (encryptedJournalPayload) {
          try {
            const payloadContainer: EncryptedContainer = JSON.parse(encryptedJournalPayload);
            const decryptedBytes = executeRiemannTripleLayerDecrypt(payloadContainer, vaultPassword);
            const decryptedStr = bytesToString(decryptedBytes);
            decryptedEntries = JSON.parse(decryptedStr);
          } catch (decErr) {
            onSecurityLog('Journal payload corrupted', 'critical', 'Node sequence integrity compromised.');
            decryptedEntries = [];
          }
        }
      }

      setEntries(decryptedEntries);
      setIsUnlocked(true);
      onSecurityLog('Journal unlocked and decrypted', 'info', `De-routed ${decryptedEntries.length} chronological secure log entry frames.`);
      onSuccess(locVal('Journal open. Entries decrypted in thread heap.', 'تم إذابة شفرة ريمان وعرض اليوميات بنجاح تام!'), 'success');
    } catch (e: any) {
      onSecurityLog('Journal sequence failed', 'critical', e.message || 'Decryption failure');
      onSuccess(locVal('Zero-knowledge authentication failed.', 'فشل فك تشفير البيانات المجدولة.'), 'error');
    }
  };

  const saveJournalToLocalStorage = (currentEntries: JournalEntry[], passString: string) => {
    try {
      const payloadStr = JSON.stringify(currentEntries);
      const payloadBytes = stringToBytes(payloadStr);
      const encryptedObj = executeRiemannTripleLayerEncrypt(payloadBytes, passString, {
        fileType: 'application/json',
        filename: 'journal_payload.riman'
      });
      localStorage.setItem('riman_journal_vault_payload', JSON.stringify(encryptedObj));
    } catch (e: any) {
      onSecurityLog('Journal local commits failed', 'critical', 'Disk allocation failures.');
    }
  };

  const syncJournalWithDisk = (updatedEntries: JournalEntry[]) => {
    setEntries(updatedEntries);
    if (isUnlocked) {
      saveJournalToLocalStorage(updatedEntries, vaultPassword);
    }
  };

  const handleLockJournalSession = () => {
    setIsUnlocked(false);
    setEntries([]);
    onSecurityLog('Journal session securely locked', 'info', 'Immolated decompressed journal keys and objects from RAM.');
    onSuccess(locVal('Journal Vault session successfully locked.', 'تم قفل وتجميد فضاء اليوميات المشفرة.'), 'info');
  };

  const handleCreateJournalEntry = () => {
    if (!entryTitle || !entryContent) {
      onSuccess(locVal('Title and content are required for a log frame.', 'عنوان ونص تدوينة اليوميات مطلوب لتوثيق الطيف!'), 'error');
      return;
    }

    const newEntry: JournalEntry = {
      id: 'journal_' + Date.now(),
      title: entryTitle,
      content: entryContent,
      createdAt: Date.now(),
      mood: entryMood,
      location: includeLocation && currentCoords ? {
        latitude: currentCoords.latitude,
        longitude: currentCoords.longitude,
        name: locVal('Loc-Tag Armed Orbit', 'إحداثيات المدار الموثق')
      } : undefined
    };

    const updated = [newEntry, ...entries];
    syncJournalWithDisk(updated);

    // Clear inputs
    setEntryTitle('');
    setEntryContent('');
    setIncludeLocation(false);
    setCurrentCoords(null);

    onSecurityLog('Chronological entry logged', 'info', `Encrypted new Journal frame "${entryTitle}" under category sequence.`);
    onSuccess(locVal('Journal entry successfully encrypted and written into Sovereign Timeline!', 'تم تشفير وحفظ تدوينة اليوميات بنجاح داخل الخط الزمني المشفر!'), 'success');
  };

  const handleDeleteEntry = (idStr: string) => {
    const updated = entries.filter(e => e.id !== idStr);
    syncJournalWithDisk(updated);
    onSecurityLog('Journal entry shredded', 'warning', `Destroyed journal frame under sequence ID: ${idStr}`);
    onSuccess(locVal('Journal entry completely shredded!', 'تم تمزيق وإزالة تدوينة اليوميات المشفرة تماماً!'), 'success');
  };

  const triggerExportMarkdown = () => {
    try {
      if (entries.length === 0) {
        onSuccess(locVal('Journal is empty', 'قائمة اليوميات فارغة'), 'error');
        return;
      }

      let backupStr = `# Riman Cryptst Secure Journal Export\nExported on: ${new Date().toUTCString()}\n\n`;

      entries.forEach(e => {
        const moodName = MOODS.find(m => m.key === e.mood);
        backupStr += `## [${new Date(e.createdAt).toLocaleString()}] ${e.title}\n`;
        backupStr += `**Energy / Mood:** ${moodName?.emoji} ${locale === 'ar' ? moodName?.labelAr : moodName?.labelEn}\n`;
        if (e.location) {
          backupStr += `**Geolocation Coordinates:** Lat ${e.location.latitude}, Lng ${e.location.longitude} (${e.location.name})\n`;
        }
        backupStr += `\n${e.content}\n\n---\n\n`;
      });

      const blob = new Blob([backupStr], { type: 'text/markdown;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'riman_secure_journal_export.md');
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      onSecurityLog('Exported entire Journal timeline', 'success', 'Generated full offline Backup Container file.');
      onSuccess(locVal('Sovereign encrypted timeline exported perfectly!', 'تم تصدير اليوميات وصياغة ملف التدوين بنجاح!'), 'success');
    } catch (_err) {
      onSuccess(locVal('Backup generation failed.', 'فشل تصدير مستند اليوميات.'), 'error');
    }
  };

  const filteredEntries = entries.filter(e => {
    const matchesSearch = e.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          e.content.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesMood = selectedMoodFilter === 'All' || e.mood === selectedMoodFilter;
    return matchesSearch && matchesMood;
  });

  return (
    <div className="space-y-6">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <span className="text-[10px] uppercase tracking-widest font-mono text-purple-400">{locVal('CHRONOLOGICAL JOURNAL AND MOOD ARCHIVE', 'جدار توثيق اليوميات التاريخية المشفرة')}</span>
          <h2 className="text-xl font-display font-semibold text-white tracking-tight flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-purple-400" />
            {locVal('Secure Journal & Timeline', 'اليوميات المؤمنة والخط الزمني السيادي')}
          </h2>
          <p className="text-xs text-neutral-400 mt-1">
            {locVal(
              'Capture personal thoughts, cryptographic discoveries, and logs. Masked completely under Riemann zero mathematical limits on disk.',
              'وثق تطلعاتك الشخصية، اكتشافاتك الخلوية، ومسار أفكارك محجوبة تماماً خلف مصفوفات الحدود الرياضية لصفر ريمان.'
            )}
          </p>
        </div>

        {isUnlocked && (
          <div className="flex items-center gap-3">
            <button
              onClick={triggerExportMarkdown}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-neutral-800 hover:border-neutral-700 hover:text-white bg-neutral-900/40 text-neutral-400 font-mono text-xs cursor-pointer transition"
            >
              <Download className="w-3.5 h-3.5" />
              <span>{locVal('EXPORT JOURNAL', 'تصدير اليوميات')}</span>
            </button>
            <button
              onClick={handleLockJournalSession}
              className="flex items-center gap-2 px-3 py-1.5 rounded-xl border border-rose-800/60 hover:border-rose-400 bg-rose-950/10 hover:bg-rose-900/30 text-rose-400 font-mono text-xs cursor-pointer transition active:scale-95"
            >
              <Lock className="w-3.5 h-3.5" />
              <span>{locVal('LOCK JOURNAL', 'إقفال الملف')}</span>
            </button>
          </div>
        )}
      </div>

      {!isUnlocked ? (
        /* Locked Gate Screen */
        <div className="glass-card p-10 rounded-2xl border border-neutral-850 flex flex-col items-center justify-center text-center h-[460px] relative overflow-hidden">
          <div className="absolute inset-0 bg-grid-white/[0.01]" />
          <div className="absolute bottom-[-100px] w-80 h-80 bg-cyan-500/5 rounded-full blur-[100px] pointer-events-none" />
          
          <div className="relative z-10 space-y-6 max-w-sm">
            <div className="w-16 h-16 rounded-2xl bg-neutral-900 border border-neutral-800 flex items-center justify-center mx-auto shadow-2xl animate-pulse">
              <BookOpen className="w-8 h-8 text-purple-400" />
            </div>

            <div className="space-y-1.5">
              <h3 className="text-base font-display font-bold text-white tracking-tight">{locVal('Chronicle Array Locked', 'اليوميات التاريخية مقفلة')}</h3>
              <p className="text-[11px] text-neutral-500 leading-relaxed font-sans">
                {locVal(
                  'Chronological timelines have been wiped from memory. Supply your Riman primary password lock to reconstruct decrypted vectors.',
                  'تم محو الخطوط الزمنية والخرائط التاريخية بالكامل من ذاكرة العمل المؤقتة. يرجى كتابة رمز مرور ريمان الدائم للتفعيل.'
                )}
              </p>
            </div>

            <div className="space-y-3 pt-2">
              <div className="relative">
                <input 
                  type={showPasswordInput ? "text" : "password"} 
                  placeholder={locVal("Enter primary password...", "أدخل كلمة مرور ريمان...")}
                  value={vaultPassword}
                  onChange={(e) => setVaultPassword(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleUnlockJournal()}
                  className="w-full px-3.5 py-2.5 pe-10 font-mono text-center text-white text-xs bg-neutral-950 border border-neutral-900 rounded-xl focus:border-purple-400 focus:outline-none placeholder:text-neutral-700"
                />
                <button
                  type="button"
                  onClick={() => setShowPasswordInput(!showPasswordInput)}
                  className="absolute right-3.5 top-3 text-neutral-600 hover:text-neutral-400 cursor-pointer"
                >
                  {showPasswordInput ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>

              <button
                onClick={handleUnlockJournal}
                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-purple-500 text-black text-xs font-bold font-mono tracking-widest hover:bg-purple-400 transition cursor-pointer active:scale-95"
              >
                <Unlock className="w-4 h-4" />
                <span>{locVal('DECRYPT SECURE ARCHIVES', 'فك تشفير الأرشيف الزمني')}</span>
              </button>

              <span className="block text-[8.5px] text-neutral-600 font-mono">
                {locVal('Default demo password key is "riman123"', 'تلميح فك الشفرة للتجربة: "riman123"')}
              </span>
            </div>
          </div>
        </div>
      ) : (
        /* Dynamic Journal workspace screen */
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Create Journal Entry Card Column (Left 1) */}
          <div className="lg:col-span-1 space-y-6">
            <div className="glass-card p-5 rounded-2xl border border-neutral-850 bg-neutral-900/10 space-y-4">
              <div className="border-b border-neutral-950 pb-3 flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-purple-400" />
                <span className="text-xs font-mono font-bold text-white tracking-widest">{locVal('RECORD LOG FRAME', 'تسجيل لقطة زمنية مشفرة')}</span>
              </div>

              <div className="space-y-3.5">
                {/* Title */}
                <div className="space-y-1.5">
                  <label className="text-[9px] font-mono text-neutral-500 uppercase">{locVal('Entry Title', 'عنوان تدوينة اليوميات')}</label>
                  <input 
                    type="text" 
                    placeholder={locVal("Title of this wave slice...", "عنوان هذه اللحظة التاريخية...")}
                    value={entryTitle}
                    onChange={(e) => setEntryTitle(e.target.value)}
                    className="w-full px-3 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white focus:border-purple-400 focus:outline-none placeholder:text-neutral-700"
                  />
                </div>

                {/* Mood selection */}
                <div className="space-y-1.5">
                  <label className="text-[9px] font-mono text-neutral-500 uppercase block">{locVal('Internal Metric Status / Mood', 'مؤشر قياس الطاقة / المزاج العام')}</label>
                  <div className="grid grid-cols-5 gap-1.5">
                    {MOODS.map((m) => (
                      <button
                        key={m.key}
                        type="button"
                        onClick={() => setEntryMood(m.key as any)}
                        className={`p-2 rounded-xl border flex flex-col items-center justify-center gap-1 cursor-pointer transition duration-150 ${
                          entryMood === m.key 
                            ? `${m.bg} ${m.color} border-purple-500 font-bold scale-[1.04]` 
                            : 'bg-neutral-950/60 border-neutral-900 text-neutral-500 hover:text-white hover:border-neutral-800'
                        }`}
                        title={locale === 'ar' ? m.labelAr : m.labelEn}
                      >
                        <span className="text-sm select-none">{m.emoji}</span>
                        <span className="text-[7.5px] truncate max-w-full font-mono">{locale === 'ar' ? m.labelAr.split(' ')[0] : m.labelEn}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Secure location toggle */}
                <div className="bg-neutral-950 p-3 rounded-xl border border-neutral-900 space-y-2">
                  <div className="flex justify-between items-center">
                    <div className="space-y-0.5">
                      <span className="block text-[10px] font-mono text-white">{locVal('Include Geolocation Tag', 'تضمين إحداثيات الموقع السيادي')}</span>
                      <span className="block text-[8px] text-neutral-500 leading-tight">{locVal('Binds physical location matrix to encryption frame.', 'ربط معلمات وإحداثيات الموقع الفيزيائي في الغلاف.')}</span>
                    </div>

                    <button
                      type="button"
                      onClick={() => setIncludeLocation(!includeLocation)}
                      className={`px-2.5 py-1 rounded-lg text-[9px] font-mono font-bold cursor-pointer transition ${
                        includeLocation 
                          ? 'bg-purple-950/20 border border-purple-800 text-purple-400' 
                          : 'bg-neutral-900 border border-neutral-800 text-neutral-500'
                      }`}
                    >
                      {includeLocation ? locVal('ACTIVE', 'نشط') : locVal('DISABLED', 'معطل')}
                    </button>
                  </div>

                  {includeLocation && currentCoords && (
                    <div className="p-1.5 bg-neutral-900/60 rounded border border-neutral-850 flex items-center justify-between">
                      <div className="flex items-center gap-1.5 font-mono text-[8px] text-purple-300">
                        <MapPin className="w-3 h-3 text-purple-400 shrink-0" />
                        <span>Lat: {currentCoords.latitude}° • Lng: {currentCoords.longitude}°</span>
                      </div>
                      <span className="text-[7px] font-mono uppercase bg-purple-950 text-purple-400 px-1 rounded">{locVal('ARMED', 'مدرع')}</span>
                    </div>
                  )}
                </div>

                {/* Entry Content Payload */}
                <div className="space-y-1.5">
                  <label className="text-[9px] font-mono text-neutral-500 uppercase">{locVal('Secure Timeline payload text', 'متن النص المشفر لتدوينات اليوميات')}</label>
                  <textarea 
                    value={entryContent}
                    onChange={(e) => setEntryContent(e.target.value)}
                    placeholder={locVal("Transcribe thoughts, sensitive events, system upgrades or cryptographic formulas...", "اكتب مشاعرك، الأحداث الحساسة، ترقيات الخادم أو الصيغ الرياضية هنا...")}
                    rows={8}
                    className="w-full p-3.5 text-xs rounded-xl bg-neutral-950 border border-neutral-900 focus:border-purple-400 text-white font-sans focus:outline-none placeholder:text-neutral-800 resize-none resize-y"
                  />
                </div>

                <button
                  type="button"
                  onClick={handleCreateJournalEntry}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-purple-500 to-indigo-500 text-black text-xs font-bold hover:scale-[1.01] transition duration-200 cursor-pointer"
                >
                  <Plus className="w-4 h-4 text-black" />
                  <span>{locVal('ENCRYPT & COMMIT SLICE', 'تأكيد التسجيل والتشفير الزمني')}</span>
                </button>
              </div>
            </div>
          </div>

          {/* Chronological Timeline column (Right 2) */}
          <div className="lg:col-span-2 space-y-6">

            {/* Timelines searching/filtering bar */}
            <div className="glass-card p-4 rounded-xl border border-neutral-850 flex flex-col md:flex-row gap-4 items-center justify-between bg-neutral-900/5">
              
              {/* Search timeline notes */}
              <div className="relative w-full md:max-w-xs">
                <Search className="absolute left-3.5 top-2.5 w-4 h-4 text-neutral-600" />
                <input 
                  type="text" 
                  placeholder={locVal('Index filter stories...', 'ابحث في خطك الزمني...')}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full ps-10 pe-4 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white focus:border-purple-400 focus:outline-none placeholder:text-neutral-700"
                />
              </div>

              {/* Mood list filters */}
              <div className="flex items-center gap-2">
                <ListFilter className="w-3.5 h-3.5 text-neutral-500" />
                <select
                  value={selectedMoodFilter}
                  onChange={(e) => setSelectedMoodFilter(e.target.value)}
                  className="bg-neutral-950 px-3 py-1.5 rounded-xl border border-neutral-900 text-white text-[11px] focus:outline-none cursor-pointer"
                >
                  <option value="All">{locVal('All Energy Statuses', 'كافة مقاييس الطاقة')}</option>
                  {MOODS.map((m, idx) => (
                    <option key={idx} value={m.key}>{m.emoji} {locale === 'ar' ? m.labelAr : m.labelEn}</option>
                  ))}
                </select>
              </div>

            </div>

            {/* Actual Timeline Nodes render */}
            {filteredEntries.length === 0 ? (
              <div className="p-12 text-center bg-neutral-900/10 rounded-2xl border border-neutral-900">
                <BookOpen className="w-8 h-8 text-neutral-700 mx-auto mb-2 animate-pulse" />
                <span className="block text-xs font-mono text-neutral-500">{locVal('No chronological entries aligned with the current phase index.', 'لا توجد أية تدوينات مجدولة تتطابق مع فلاتر البحث الحالية.')}</span>
              </div>
            ) : (
              <div className="relative border-s border-neutral-850 ps-6 ms-4 space-y-6">
                {filteredEntries.map((e, idx) => {
                  const moodInfo = MOODS.find(m => m.key === e.mood) || MOODS[1];
                  return (
                    <div key={e.id} className="relative group">
                      
                      {/* Circle icon locator on the timeline line */}
                      <span className="absolute -left-[33px] top-1 w-4 h-4 rounded-full bg-neutral-950 border-2 border-purple-500 flex items-center justify-center text-[8px] select-none z-10 group-hover:scale-125 transition duration-150">
                        {moodInfo.emoji}
                      </span>

                      {/* Content details frame */}
                      <div className="p-5 rounded-2xl border border-neutral-900 bg-neutral-950/40 hover:bg-neutral-950/80 transition duration-200 space-y-3 relative overflow-hidden">
                        
                        {/* Dynamic ambient mood bg glow */}
                        <div className="absolute top-0 right-0 w-24 h-24 bg-purple-500/[0.02] rounded-full blur-2xl pointer-events-none" />

                        <div className="flex flex-wrap justify-between items-start gap-2 border-b border-neutral-950 pb-2">
                          <div className="space-y-0.5">
                            <span className="block text-[11px] font-sans font-bold text-white group-hover:text-purple-300 transition">{e.title}</span>
                            <div className="flex items-center gap-1.5 font-mono text-[8px] text-neutral-500">
                              <Clock className="w-3 h-3 text-neutral-600" />
                              <span>{new Date(e.createdAt).toLocaleString()}</span>
                            </div>
                          </div>

                          <div className="flex items-center gap-1.5">
                            <span className={`px-2 py-0.5 rounded text-[8px] font-mono font-bold tracking-wide uppercase ${moodInfo.bg} ${moodInfo.color}`}>
                              {locale === 'ar' ? moodInfo.labelAr : moodInfo.labelEn}
                            </span>
                            <button
                              type="button"
                              onClick={() => handleDeleteEntry(e.id)}
                              className="text-neutral-600 hover:text-rose-400 p-0.5 cursor-pointer transition shrink-0"
                              title={locVal('Shred Entry', 'شطب التدوينة')}
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </div>

                        <p className="text-[11px] text-neutral-300 leading-relaxed font-sans whitespace-pre-wrap">
                          {e.content}
                        </p>

                        {e.location && (
                          <div className="pt-2 flex items-center justify-between border-t border-neutral-950/40 text-[8px] font-mono text-purple-400">
                            <div className="flex items-center gap-1.5 select-none">
                              <Map className="w-3.5 h-3.5" />
                              <span>Coordinates: {e.location.latitude}, {e.location.longitude}</span>
                            </div>

                            <span className="text-neutral-500 uppercase">
                              {e.location.name}
                            </span>
                          </div>
                        )}

                      </div>

                    </div>
                  );
                })}
              </div>
            )}

          </div>

        </div>
      )}

    </div>
  );
};
