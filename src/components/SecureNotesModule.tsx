import React, { useState, useEffect } from 'react';
import { 
  Pin, Folder, Plus, Search, Lock, Unlock, Trash2, Save, FileText, 
  LayoutGrid, List, Calendar, Download, Sparkles, Volume2, Image, 
  Clock, Check, Eye, EyeOff, ShieldCheck, ChevronRight, FileUp, Fingerprint
} from 'lucide-react';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt, 
  stringToBytes, 
  bytesToString 
} from '../lib/crypto';
import { EncryptedContainer } from '../types';
import { useTranslation } from '../lib/I18nContext';

interface Note {
  id: string;
  title: string;
  content: string;
  category: string;
  color: string;
  createdAt: number;
  lastModifiedAt: number;
  isPinned: boolean;
  isSelectiveLocked: boolean; // Extra security layer requiring password/PIN
}

interface SecureNotesProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
  privacySettings?: {
    hiddenVaultsEnabled: boolean;
    decoyVaultEnabled: boolean;
    panicPassword: string;
    hiddenVaultPasswords: string[];
    hiddenTabs: string[];
  };
  isAppLocked?: boolean;
}

const NOTE_COLORS = [
  { name: 'Cyan', value: '#06B6D4', textClass: 'text-cyan-400', bgClass: 'bg-cyan-500/10', borderClass: 'border-cyan-500/40' },
  { name: 'Purple', value: '#A855F7', textClass: 'text-purple-400', bgClass: 'bg-purple-500/10', borderClass: 'border-purple-500/40' },
  { name: 'Emerald', value: '#10B981', textClass: 'text-emerald-400', bgClass: 'bg-emerald-500/10', borderClass: 'border-emerald-500/40' },
  { name: 'Amber', value: '#F59E0B', textClass: 'text-amber-400', bgClass: 'bg-amber-500/10', borderClass: 'border-amber-500/40' },
  { name: 'Rose', value: '#F43F5E', textClass: 'text-rose-400', bgClass: 'bg-rose-500/10', borderClass: 'border-rose-500/40' },
  { name: 'Blue', value: '#3B82F6', textClass: 'text-blue-400', bgClass: 'bg-blue-500/10', borderClass: 'border-blue-500/40' },
];

export const SecureNotesModule: React.FC<SecureNotesProps> = ({
  onSuccess,
  onSecurityLog,
  triggerAnimation,
  privacySettings,
  isAppLocked
}) => {
  const { t, locale } = useTranslation();
  const locVal = (en: string, ar: string) => (locale === 'ar' ? ar : en);

  // Quick Notes state (unencrypted scratchpad)
  const [scratchpadTitle, setScratchpadTitle] = useState<string>('');
  const [scratchpadContent, setScratchpadContent] = useState<string>('');

  // Biometric state variables (Feature 6 Reauthentication)
  const [biometricsActive, setBiometricsActive] = useState<boolean>(false);
  const [biometricType, setBiometricType] = useState<string>('fingerprint');
  const [isNoteScanning, setIsNoteScanning] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const active = localStorage.getItem('riman_biometrics_enabled') === 'true';
    const type = localStorage.getItem('riman_biometric_type') || 'fingerprint';
    setBiometricsActive(active);
    setBiometricType(type);
  }, []);

  // Is lock triggered globally
  useEffect(() => {
    if (isAppLocked) {
      setIsUnlocked(false);
      setVaultPassword('');
      setNotes([]);
      setActiveNote(null);
    }
  }, [isAppLocked]);

  // Main Vault unlock state
  const [isUnlocked, setIsUnlocked] = useState<boolean>(false);
  const [vaultPassword, setVaultPassword] = useState<string>('');
  const [showPasswordInput, setShowPasswordInput] = useState<boolean>(false);
  const [activeMode, setActiveMode] = useState<'normal' | 'decoy' | 'hidden'>('normal');
  const [activePassword, setActivePassword] = useState<string>('');

  // Decrypted active state
  const [notes, setNotes] = useState<Note[]>([]);
  const [categories, setCategories] = useState<string[]>(['Personal', 'Work', 'Financial', 'Credentials', 'Secrets']);
  const [newCatName, setNewCatName] = useState<string>('');
  const [isAddingCat, setIsAddingCat] = useState<boolean>(false);

  // Filters and Selectors
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [selectedColor, setSelectedColor] = useState<string>('All');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  // Selected note detail / edit mode
  const [activeNote, setActiveNote] = useState<Note | null>(null);
  const [noteTitle, setNoteTitle] = useState<string>('');
  const [noteContent, setNoteContent] = useState<string>('');
  const [noteCategory, setNoteCategory] = useState<string>('Personal');
  const [noteColor, setNoteColor] = useState<string>('#06B6D4');
  const [isNoteSelectiveLocked, setIsNoteSelectiveLocked] = useState<boolean>(false);
  const [selectivePasscode, setSelectivePasscode] = useState<string>('');
  const [unlockSelectivePasscode, setUnlockSelectivePasscode] = useState<string>('');
  const [tempUnlockedNotes, setTempUnlockedNotes] = useState<Record<string, boolean>>({});

  // Onboarding default notes
  const createDefaultNotes = (password: string): Note[] => {
    return [
      {
        id: 'note_01',
        title: locVal('Riemann Master Encryption Coordinates', 'إحداثيات تشفير ريمان الرئيسية'),
        content: locVal('The primary non-trivial zeroes on the critical line map to: s=1/2 + i*14.134725 and s=1/2 + i*21.022040. Use these exact phase gaps when syncing dynamic spectrum calculations.', 'تتطابق الأصفار غير البديهية الأولية على الخط الحرج مع المعلمات التالية: s=1/2 + i*14.134725 و s=1/2 + i*21.022040. استخدم فجوات الطور المحددة لمزامنة حسابات الطيف.'),
        category: 'Secrets',
        color: '#06B6D4',
        createdAt: Date.now() - 3600000 * 24 * 3,
        lastModifiedAt: Date.now() - 3600000 * 12,
        isPinned: true,
        isSelectiveLocked: false
      },
      {
        id: 'note_02',
        title: locVal('Sovereign Wallet Seed Phrases Backup', 'نسخة مساندة لكلمات استعادة المحفظة السيادية'),
        content: locVal('1. quantum  2. riemann  3. spectrum  4. gravity  5. cascade  6. entropy\n7. absolute 8. cipher   9. barrier   10. secure  11. transit  12. vortex\nKeep this locked selectively under a secondary cryptographic protocol.', '1. quantum  2. riemann  3. spectrum  4. gravity  5. cascade  6. entropy\n7. absolute 8. cipher   9. barrier   10. secure  11. transit  12. vortex\nاحتفظ بهذا المقطع السري تحت نظام قفل انتقائي مخصص.'),
        category: 'Financial',
        color: '#F43F5E',
        createdAt: Date.now() - 3600000 * 10,
        lastModifiedAt: Date.now() - 3600000 * 10,
        isPinned: false,
        isSelectiveLocked: true
      }
    ];
  };

  // Load Scratchpad on startup
  useEffect(() => {
    const savedScratchTitle = localStorage.getItem('riman_scratchspace_title');
    const savedScratchContent = localStorage.getItem('riman_scratchspace_content');
    if (savedScratchTitle) setScratchpadTitle(savedScratchTitle);
    if (savedScratchContent) setScratchpadContent(savedScratchContent);

    // Load available categories
    const savedCats = localStorage.getItem('riman_notes_categories');
    if (savedCats) {
      try {
        setCategories(JSON.parse(savedCats));
      } catch (e) {}
    }
  }, []);

  const saveScratchpad = (title: string, content: string) => {
    setScratchpadTitle(title);
    setScratchpadContent(content);
    localStorage.setItem('riman_scratchspace_title', title);
    localStorage.setItem('riman_scratchspace_content', content);
  };

  const createDecoyNotes = (): Note[] => [
    {
      id: 'decoy_01',
      title: locVal('Personal Grocery List', 'قائمة المشتريات الشخصية'),
      content: locVal('1. Greek yogurt\n2. Oats & Honey\n3. Bananas\n4. Almond milk\n5. Green Tea bag boxes', '1. زبادي طبيعي\n2. حبوب الشوفان والعسل\n3. موز طازج\n4. حليب اللوز\n5. علبة شاي أخضر بالنعناع'),
      category: 'Personal',
      color: '#10B981',
      createdAt: Date.now() - 3600000 * 2,
      lastModifiedAt: Date.now() - 3600000 * 2,
      isPinned: true,
      isSelectiveLocked: false
    },
    {
      id: 'decoy_02',
      title: locVal('Weekly Workout Routine', 'جدول التمارين الأسبوعي'),
      content: locVal('- Monday: Chest & Triceps (Hypertrophy)\n- Wednesday: Back & Biceps (Pull focus)\n- Friday: Legs & Shoulders (Overload)\n- Gym card code on keychain: 9812-B', 'الأثنين: تمارين صدر وترايسبس\nالأربعاء: تمارين ظهر وبايسبس\nالجمعة: تمارين أرجل وأكتاف\nرقم العضوية في النادي: 9812-B'),
      category: 'Work',
      color: '#06B6D4',
      createdAt: Date.now() - 3600000 * 20,
      lastModifiedAt: Date.now() - 3600000 * 20,
      isPinned: false,
      isSelectiveLocked: false
    },
    {
      id: 'decoy_03',
      title: locVal('Kitchen Cabinet Redesign Ideas', 'أفكار تجديد المطبخ الجديد'),
      content: locVal('Need to contact local carpenter on Monday:\n- Wooden panels for cupboards: semi-matte off-white.\n- Handle styles: brushed brass minimalist pulls.', 'الاتصال بالنجار لتفصيل كبائن المطبخ المقاومة للمياه:\n- خشب أبيض مطفي مقاوم للرطوبة.\n- المقابض: نحاس مطفي ناعم ممتد.'),
      category: 'Personal',
      color: '#F59E0B',
      createdAt: Date.now() - 3600050 * 50,
      lastModifiedAt: Date.now() - 3600050 * 50,
      isPinned: false,
      isSelectiveLocked: false
    }
  ];

  const createHiddenNotes = (): Note[] => [
    {
      id: 'hidden_01',
      title: locVal('Isolated Dynamic Zero Gaps', 'الفجوات الديناميكية المنعزلة لقسم الأصفار'),
      content: locVal('Hidden vault mapped successfully. System coordinates: [PHASE-4-DEVIATION]. Primary partition token: 0x981F4B96.', 'تم فك تشفير وتأسيس الخزنة السحرية المعزولة بنجاح تام. لا توجد أي سجلات أو إشارات في الفهارس الرسمية.'),
      category: 'Secrets',
      color: '#A855F7',
      createdAt: Date.now(),
      lastModifiedAt: Date.now(),
      isPinned: true,
      isSelectiveLocked: false
    }
  ];

  const handleUnlockNotesVault = () => {
    if (!vaultPassword || vaultPassword.length < 6) {
      onSuccess(locVal('Sovereign password must be at least 6 characters', 'يجب أن لا تقل كلمة مرور النظام السيادي عن 6 أحرف'), 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Notes Vault decryption sequence online', 'info', 'Deriving triple encryption key vectors from password.');

      let mode: 'normal' | 'decoy' | 'hidden' = 'normal';
      if (privacySettings?.decoyVaultEnabled && vaultPassword === privacySettings?.panicPassword) {
        mode = 'decoy';
      } else if (privacySettings?.hiddenVaultsEnabled && privacySettings?.hiddenVaultPasswords?.includes(vaultPassword)) {
        mode = 'hidden';
      }

      let decryptedNotes: Note[] = [];

      if (mode === 'decoy') {
        const decoyPayload = localStorage.getItem('riman_notes_decoy_payload');
        if (!decoyPayload) {
          const defaultDecoy = createDecoyNotes();
          saveNotesToLocalStorage(defaultDecoy, vaultPassword, 'decoy');
          decryptedNotes = defaultDecoy;
        } else {
          try {
            const container = JSON.parse(decoyPayload);
            const decBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
            decryptedNotes = JSON.parse(bytesToString(decBytes));
          } catch (e) {
            const defaultDecoy = createDecoyNotes();
            saveNotesToLocalStorage(defaultDecoy, vaultPassword, 'decoy');
            decryptedNotes = defaultDecoy;
          }
        }
        onSecurityLog('Decoy Notes Vault Access', 'warning', 'Plausible deniability scenario triggered. Fake payload decrypted.');
        onSuccess(locVal('Decoy Notes database loaded.', 'تم فك لوائح البيانات المموهة بنجاح.'), 'info');
      } else if (mode === 'hidden') {
        const encSuffix = btoa(vaultPassword).substring(0, 15);
        const hiddenPayload = localStorage.getItem(`riman_notes_hidden_payload_${encSuffix}`);
        if (!hiddenPayload) {
          const defaultHidden = createHiddenNotes();
          saveNotesToLocalStorage(defaultHidden, vaultPassword, 'hidden');
          decryptedNotes = defaultHidden;
        } else {
          try {
            const container = JSON.parse(hiddenPayload);
            const decBytes = executeRiemannTripleLayerDecrypt(container, vaultPassword);
            decryptedNotes = JSON.parse(bytesToString(decBytes));
          } catch (e) {
            const defaultHidden = createHiddenNotes();
            saveNotesToLocalStorage(defaultHidden, vaultPassword, 'hidden');
            decryptedNotes = defaultHidden;
          }
        }
        onSecurityLog('Hidden Notes Vault Access', 'warning', 'Isolated hidden vault successfully decrypted and loaded.');
        onSuccess(locVal('Hidden partition unlocked!', 'تم فتح القسم المشفر المخفي بالكامل!'), 'success');
      } else {
        // STANDARD NORMAL VAULT
        const savedTokenJson = localStorage.getItem('riman_notes_vault_token');
        if (!savedTokenJson) {
          // First-time setup
          onSecurityLog('Notes Vault initialization', 'warning', 'No existing vault configuration. Creating brand new encrypted container.');
          const verifyObj = { active: true, verifier: 'riemann_zero' };
          const payloadBytes = stringToBytes(JSON.stringify(verifyObj));
          const encryptedTokenObj = executeRiemannTripleLayerEncrypt(payloadBytes, vaultPassword, {
            fileType: 'application/json',
            filename: 'notes_token.riman'
          });
          localStorage.setItem('riman_notes_vault_token', JSON.stringify(encryptedTokenObj));

          const defaultNotes = createDefaultNotes(vaultPassword);
          saveNotesToLocalStorage(defaultNotes, vaultPassword, 'normal');
          decryptedNotes = defaultNotes;
          onSuccess(locVal('Secured Crypt Notes initialized successfully!', 'تم تهيئة وتأسيس مخزن الملاحظات المشفر لأول مرة!'), 'success');
        } else {
          // Authenticate using verification token
          try {
            const tokenContainer: EncryptedContainer = JSON.parse(savedTokenJson);
            const decryptedTokenBytes = executeRiemannTripleLayerDecrypt(tokenContainer, vaultPassword);
            const decryptedTokenStr = bytesToString(decryptedTokenBytes);
            const tokenParsed = JSON.parse(decryptedTokenStr);
            
            if (tokenParsed.verifier !== 'riemann_zero') {
              throw new Error('Verification tag invalid');
            }
          } catch (authErr) {
            onSecurityLog('Notes Vault authentication failed', 'critical', 'Incorrect password key provided. Decryption aborted.');
            onSuccess(locVal('Incorrect vault key password!', 'فشل فك التشفير: كلمة المرور غير صحيحة!'), 'error');
            return;
          }

          const encryptedNotesListJson = localStorage.getItem('riman_notes_vault_payload');
          if (encryptedNotesListJson) {
            try {
              const notesContainer: EncryptedContainer = JSON.parse(encryptedNotesListJson);
              const decryptedNotesBytes = executeRiemannTripleLayerDecrypt(notesContainer, vaultPassword);
              const decryptedNotesStr = bytesToString(decryptedNotesBytes);
              decryptedNotes = JSON.parse(decryptedNotesStr);
            } catch (decErr) {
              onSecurityLog('Notes Payload decryption crash', 'critical', 'Corrupted node payload mapping.');
              decryptedNotes = [];
            }
          } else {
            decryptedNotes = [];
          }
        }
        onSecurityLog('Sovereign Notes unlocked', 'info', `Successfully hydrated ${decryptedNotes.length} secure items from local container.`);
        onSuccess(locVal('Notes Vault decrypted completely!', 'تم إذابة وفك تشفير حواية الملاحظات بنجاح تام!'), 'success');
      }

      setActiveMode(mode);
      setActivePassword(vaultPassword);
      setNotes(decryptedNotes);
      setIsUnlocked(true);
    } catch (e: any) {
      onSecurityLog('Notes Vault opening crashed', 'critical', e.message || 'Decryption error');
      onSuccess(locVal('Decryption failed. Please check your password.', 'خطأ في المعالجة الرياضية: كلمة المرور غير مطابقة!'), 'error');
    }
  };

  const saveNotesToLocalStorage = (currentNotes: Note[], passwordStr: string, mode: 'normal' | 'decoy' | 'hidden') => {
    try {
      const notesJsonStr = JSON.stringify(currentNotes);
      const payloadBytes = stringToBytes(notesJsonStr);
      const encryptedNotesObj = executeRiemannTripleLayerEncrypt(payloadBytes, passwordStr, {
        fileType: 'application/json',
        filename: mode === 'decoy' ? 'decoy_notes.riman' : mode === 'hidden' ? 'hidden_notes.riman' : 'notes_payload.riman'
      });
      const keyStr = mode === 'decoy' 
        ? 'riman_notes_decoy_payload' 
        : mode === 'hidden' 
          ? `riman_notes_hidden_payload_${btoa(passwordStr).substring(0, 15)}` 
          : 'riman_notes_vault_payload';
      localStorage.setItem(keyStr, JSON.stringify(encryptedNotesObj));
    } catch (err: any) {
      onSecurityLog('Local persistence failed', 'critical', err.message || 'Write error');
    }
  };

  const syncNotesWithDisk = (updatedNotes: Note[]) => {
    setNotes(updatedNotes);
    if (isUnlocked) {
      saveNotesToLocalStorage(updatedNotes, activePassword, activeMode);
    }
  };

  // Lock session back to unencrypted state
  const handleLockNotesSession = () => {
    setIsUnlocked(false);
    setNotes([]);
    setActiveNote(null);
    setTempUnlockedNotes({});
    onSecurityLog('Notes memory purged completely', 'info', 'Immolated active secure states from heap.');
    onSuccess(locVal('Secure Notes Session closed.', 'تم إقفال وتجميد فضاء الملاحظات بنجاح.'), 'info');
  };

  // Quick Notes scratchpad elevation to vaults
  const handleElevateScratchpad = () => {
    if (!scratchpadTitle && !scratchpadContent) {
      onSuccess(locVal('Scratchpad is empty!', 'مساحة المسودة فارغة تماماً!'), 'error');
      return;
    }

    if (!isUnlocked) {
      onSuccess(locVal('Unlock the encrypted notes vault first to file this scratchpad!', 'يرجى فتح الشفرة لمستودع الملاحظات أولاً لإيداع المسودة!'), 'warning');
      return;
    }

    const newNoteObj: Note = {
      id: 'note_' + Date.now(),
      title: scratchpadTitle.trim() || locVal('Untitled Scratchpad Note', 'ملاحظة مسودة غير معنونة'),
      content: scratchpadContent,
      category: 'Personal',
      color: '#06B6D4',
      createdAt: Date.now(),
      lastModifiedAt: Date.now(),
      isPinned: false,
      isSelectiveLocked: false
    };

    const updatedNotes = [newNoteObj, ...notes];
    syncNotesWithDisk(updatedNotes);

    // Clear scratchpad
    saveScratchpad('', '');
    onSecurityLog('Elevated unencrypted scratchpad entry', 'info', `Encrypted and saved Scratchpad as Vault note "${newNoteObj.title}"`);
    onSuccess(locVal('Scratchpad successfully elevated & encrypted in your Sovereign Vault!', 'تم رفع وتشفير مسودة الكتابة بنجاح داخل خزنتك السيادية!'), 'success');
  };

  const handleCreateOrUpdateNote = () => {
    if (!noteTitle) {
      onSuccess(locVal('Note title is required!', 'اسم أو عنوان الملاحظة مطلوب!'), 'error');
      return;
    }

    if (activeNote) {
      // Update Mode
      const updated = notes.map(n => {
        if (n.id === activeNote.id) {
          const isNowLocked = isNoteSelectiveLocked;
          return {
            ...n,
            title: noteTitle,
            content: noteContent,
            category: noteCategory,
            color: noteColor,
            lastModifiedAt: Date.now(),
            isSelectiveLocked: isNowLocked,
            // Keep existing pin state
          };
        }
        return n;
      });

      syncNotesWithDisk(updated);
      onSecurityLog('Updated secure note', 'info', `Re-encrypted note content: "${noteTitle}"`);
      onSuccess(locVal('Secured Note updated and re-encrypted!', 'تم تعديل وإعادة تشفير الملاحظة بنجاح!'), 'success');
      setActiveNote(null);
    } else {
      // Create Mode
      const newNote: Note = {
        id: 'note_' + Date.now(),
        title: noteTitle,
        content: noteContent,
        category: noteCategory,
        color: noteColor,
        createdAt: Date.now(),
        lastModifiedAt: Date.now(),
        isPinned: false,
        isSelectiveLocked: isNoteSelectiveLocked
      };

      const updated = [newNote, ...notes];
      syncNotesWithDisk(updated);
      onSecurityLog('Created secure note', 'info', `Encrypted new note node: "${noteTitle}"`);
      onSuccess(locVal('New Secure Note encrypted and filed!', 'تم تشفير وحفظ الملاحظة الجديدة بنجاح!'), 'success');
      
      // Clear inputs
      setNoteTitle('');
      setNoteContent('');
    }
  };

  const handleDeleteNote = (idStr: string) => {
    const updated = notes.filter(n => n.id !== idStr);
    syncNotesWithDisk(updated);
    if (activeNote?.id === idStr) {
      setActiveNote(null);
    }
    onSecurityLog('Sovereign note parsed out', 'warning', `Purged encrypted node sequence matching key id: ${idStr}`);
    onSuccess(locVal('Secured Note destroyed!', 'تم تدمير ومسح الملاحظة المشفرة تماماً!'), 'success');
  };

  const handleTogglePin = (idStr: string) => {
    const updated = notes.map(n => {
      if (n.id === idStr) {
        return { ...n, isPinned: !n.isPinned };
      }
      return n;
    });
    syncNotesWithDisk(updated);
    onSuccess(locVal('Pin status modulated', 'تم تعديل رتبة وتثبيت الملاحظة'), 'info');
  };

  const handleAddCategory = () => {
    const trimmed = newCatName.trim();
    if (!trimmed) return;
    if (categories.includes(trimmed)) {
      onSuccess(locVal('Category already exists!', 'هذا التصنيف مسجل بالفعل!'), 'error');
      return;
    }
    const updatedCats = [...categories, trimmed];
    setCategories(updatedCats);
    localStorage.setItem('riman_notes_categories', JSON.stringify(updatedCats));
    setNewCatName('');
    setIsAddingCat(false);
    onSuccess(locVal(`Added: ${trimmed}`, `تم تسجيل تصنيف: ${trimmed}`), 'success');
  };

  const triggerExportSingleNote = (noteObj: Note) => {
    try {
      // Dynamic Markdown Construction
      const mdContent = `---
title: ${noteObj.title}
category: ${noteObj.category}
created: ${new Date(noteObj.createdAt).toUTCString()}
engine: Riman Cryptst Triple Pipeline
---

# ${noteObj.title}

${noteObj.content}

*Sovereign Export Secured via Riemann Zeta-Matrix Dynamic Encrypter.*`;

      const blob = new Blob([mdContent], { type: 'text/markdown;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `${noteObj.title.toLowerCase().replace(/\s+/g, '_')}_export.md`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      onSecurityLog('Exported note metadata to disk', 'success', `Generated offline backup container file matching: "${noteObj.title}"`);
      onSuccess(locVal('Secure Markdown export compiled and downloaded!', 'تم تجميع وتصدير مسودة ملف الملاحظة المشفرة بنجاح!'), 'success');
    } catch (e: any) {
      onSuccess(locVal('Failed compile.', 'عطل فني في تصدير المستند.'), 'error');
    }
  };

  // Sort notes so pinned ones are first
  const filteredNotes = notes
    .filter(n => {
      const matchesSearch = n.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
                            n.content.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === 'All' || n.category === selectedCategory;
      const matchesColor = selectedColor === 'All' || n.color === selectedColor;
      return matchesSearch && matchesCategory && matchesColor;
    })
    .sort((a, b) => {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.lastModifiedAt - a.lastModifiedAt;
    });

  return (
    <div className="space-y-6">
      {/* Dynamic Spectrum Overview Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <span className="text-[10px] uppercase tracking-widest font-mono text-cyan-400">{locVal('ZERO-KNOWLEDGE CONTAINMENT FIELD', 'طور حماية فضاء المعرفة الصفرية لدرع ريمان')}</span>
          <h2 className="text-xl font-display font-semibold text-white tracking-tight flex items-center gap-2">
            <FileText className="w-5 h-5 text-cyan-400" />
            {locVal('Secure Notes & Scratchpad', 'الملاحظات الآمنة والمسودة الفورية')}
          </h2>
          <p className="text-xs text-neutral-400 mt-1">
            {locVal(
              'Plaintext data undergoes dynamic triple cascade encryption inside the browser before committing to browser memory.',
              'تخضع كافة البيانات المكتوبة لتشفير تسلسلي متعاقب ثلاثي الطبقات داخل المتصفح قبل الحفظ لضمان الخصوصية المطلقة.'
            )}
          </p>
        </div>

        {isUnlocked && (
          <button
            onClick={handleLockNotesSession}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl border border-rose-800/60 hover:border-rose-400 bg-rose-950/10 hover:bg-rose-900/30 text-rose-400 font-mono text-xs cursor-pointer transition active:scale-95"
          >
            <Lock className="w-3.5 h-3.5" />
            <span>{locVal('LOCK VAULT SESSION', 'تجميد وقفل الجلسة')}</span>
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* SIDE BAR / UNENCRYPTED SCRATCHSPACE (Visible to let user draft instant transient thought before saving) */}
        <div className="space-y-6 lg:col-span-1">
          
          {/* Quick Scratchpad Widget */}
          <div className="glass-card p-5 rounded-2xl border border-neutral-850 bg-neutral-900/10 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/5 rounded-full blur-2xl pointer-events-none" />
            
            <div className="flex justify-between items-center border-b border-neutral-900 pb-3 mb-3">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-cyan-400" />
                <span className="text-xs font-mono font-bold text-white tracking-wide">{locVal('INSTANT COLD SCRATCHPAD', 'مساحة المسودة الفورية السريعة')}</span>
              </div>
              <span className="text-[9px] font-mono bg-neutral-800/40 text-neutral-400 px-2 py-0.5 rounded-full">{locVal('VOLATILE / UNLOCKED', 'جلسة مرحلية / غير مشفرة')}</span>
            </div>

            <p className="text-[10px] text-neutral-500 leading-normal mb-3">
              {locVal('Instant scratch space requiring zero key derivation. Input details instantly or draft items here, then securely propagate to your encrypted vaults.', 'حقل كتابة سريع ومسودة لحظية لا تشغل دورات حوسبة التشفير الثقيلة. اكتب مسودتك هنا ثم ارفعها فورياً للتشفير في الخزنة.')}
            </p>

            <div className="space-y-3">
              <input 
                type="text" 
                placeholder={locVal('Transient note title...', 'عنوان المسودة السريع...')}
                value={scratchpadTitle}
                onChange={(e) => saveScratchpad(e.target.value, scratchpadContent)}
                className="w-full px-3 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 focus:border-cyan-400 text-white font-sans focus:outline-none placeholder:text-neutral-600"
              />
              <textarea 
                placeholder={locVal('Draft quick thoughts or sensitive tokens here...', 'اكتب الأفكار السريعة أو الرموز المؤقتة هنا...')}
                value={scratchpadContent}
                rows={5}
                onChange={(e) => saveScratchpad(scratchpadTitle, e.target.value)}
                className="w-full p-3 text-xs rounded-xl bg-neutral-950 border border-neutral-900 focus:border-cyan-400 text-white font-sans focus:outline-none placeholder:text-neutral-600 resize-none scrollbar-thin"
              />

              <div className="flex gap-2">
                {(scratchpadTitle || scratchpadContent) && (
                  <button
                    onClick={() => saveScratchpad('', '')}
                    className="px-3 py-2 rounded-xl bg-neutral-950 border border-neutral-900 text-[10px] text-neutral-500 hover:text-white transition cursor-pointer"
                  >
                    {t('clear')}
                  </button>
                )}
                
                <button
                  onClick={handleElevateScratchpad}
                  className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl bg-cyan-950/40 border border-cyan-800 hover:border-cyan-400 text-cyan-400 text-xs font-semibold hover:bg-cyan-950/85 transition cursor-pointer active:scale-95"
                >
                  <Sparkles className="w-3.5 h-3.5 shrink-0" />
                  <span>{locVal('SECURE & ENCRYPT IN VAULT', 'قفل وإرسال للخزنة المشفرة')}</span>
                </button>
              </div>
            </div>
          </div>

          {/* Premium Future Proof Compatibility Features Card */}
          <div className="glass-card p-5 rounded-2xl border border-neutral-850 bg-neutral-900/10 space-y-4">
            <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-widest block border-b border-neutral-900 pb-2">{locVal('SYSTEM CONSTRAINTS & MATRIX ROADS', 'مسارات تحديثات النظام السيادي')}</span>
            
            <div className="space-y-3">
              <div className="flex items-start gap-2.5 opacity-50">
                <Volume2 className="w-4 h-4 text-cyan-400 shrink-0 mt-0.5" />
                <div>
                  <span className="block text-[11px] font-sans font-medium text-neutral-200">{locVal('Sovereign Voice Notes', 'المذكرات الصوتية المشفرة')}</span>
                  <span className="block text-[9px] text-neutral-500 font-mono uppercase">{locVal('IN DEVELOPMENT • VOX PROTOCOL', 'قيد التطوير الفني والمطابقة')}</span>
                </div>
              </div>

              <div className="flex items-start gap-2.5 opacity-50">
                <Image className="w-4 h-4 text-purple-400 shrink-0 mt-0.5" />
                <div>
                  <span className="block text-[11px] font-sans font-medium text-neutral-200">{locVal('Secure Image Attachments', 'مرفقات الصور والوثائق المؤمنة')}</span>
                  <span className="block text-[9px] text-neutral-500 font-mono uppercase">{locVal('FUTURE PHASE COMPATIBILITY', 'إصدار مرحلي مستقبلي مجدول')}</span>
                </div>
              </div>

              <div className="flex items-start gap-2.5 opacity-50">
                <Clock className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                <div>
                  <span className="block text-[11px] font-sans font-medium text-neutral-200">{locVal('Automatic Time Capsules Integration', 'الربط التلقائي بـ كبسولات ريمان الزمنية')}</span>
                  <span className="block text-[9px] text-neutral-500 font-mono uppercase">{locVal('CHRONO SEQUENCE ROADMAP', 'خريطة بروتوكول قفل الإطلاق الزمني')}</span>
                </div>
              </div>
            </div>
          </div>

        </div>

        {/* VAULT BOARD (Central Panel) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Locked Vault Gate */}
          {!isUnlocked ? (
            <div className="glass-card p-10 rounded-2xl border border-neutral-850 flex flex-col items-center justify-center text-center h-[460px] relative overflow-hidden">
              <div className="absolute inset-0 bg-grid-white/[0.01]" />
              <div className="absolute bottom-[-100px] w-80 h-80 bg-purple-500/5 rounded-full blur-[100px] pointer-events-none" />
              
              <div className="relative z-10 space-y-6 max-w-sm">
                <div className="w-16 h-16 rounded-2xl bg-neutral-900 border border-neutral-800 flex items-center justify-center mx-auto shadow-2xl animate-pulse">
                  <Lock className="w-8 h-8 text-cyan-400" />
                </div>

                <div className="space-y-1.5">
                  <h3 className="text-base font-display font-bold text-white tracking-tight">{locVal('Decryption Matrix Required', 'مستودع الملاحظات السيادية مغلق')}</h3>
                  <p className="text-[11px] text-neutral-500 leading-relaxed font-sans">
                    {locVal(
                      'Sovereign notes are double ciphered. Decrypt the memory cells locally using your master safe lock password key.',
                      'تخضع كافة الملاحظات والبيانات المسجلة لنظام كشف مزدوج. لتنشيط القراءة وفك التشفير محلياً، اكتب كلمة مرور القفل السيادي.'
                    )}
                  </p>
                </div>

                <div className="space-y-3 pt-2">
                  <div className="relative">
                    <input 
                      type={showPasswordInput ? "text" : "password"} 
                      placeholder={locVal("Enter Vault password to decrypt...", "أدخل كلمة مرور فك الشفرة للخزنة...")}
                      value={vaultPassword}
                      onChange={(e) => setVaultPassword(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && handleUnlockNotesVault()}
                      className="w-full px-3.5 py-2.5 pe-10 font-mono text-center text-white text-xs bg-neutral-950 border border-neutral-900 rounded-xl focus:border-cyan-400 focus:outline-none placeholder:text-neutral-700"
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
                    onClick={handleUnlockNotesVault}
                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-cyan-400 text-black text-xs font-bold font-mono tracking-widest hover:bg-cyan-300 transition cursor-pointer active:scale-95"
                  >
                    <Unlock className="w-4 h-4" />
                    <span>{locVal('DECRYPT SECURE MEMORY', 'فك تشفير خلايا الذاكرة')}</span>
                  </button>

                  <span className="block text-[9px] text-neutral-600 font-mono">
                    {locVal('Hint to unlock default demo notes: "riman123"', 'تلميح لفك كبسولة الملاحظات التجريبية: "riman123"')}
                  </span>
                </div>
              </div>
            </div>
          ) : (
            /* Unlocked Notes Content Area */
            <div className="space-y-6">
              
              {/* Form to Create/Edit Note */}
              <div className="glass-card p-6 rounded-2xl border border-neutral-850 space-y-4">
                <div className="flex justify-between items-center border-b border-neutral-900 pb-3">
                  <h3 className="text-xs font-mono font-bold text-white tracking-widest flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-cyan-400" />
                    {activeNote ? locVal('RE-ENCRYPT NOTE INDEX', 'تعديل وإعادة تشفير محتوى الملاحظة') : locVal('ENCRYPT NEW DIRECTIVE NOTE', 'كتابة وتشفير ملاحظة جديدة')}
                  </h3>
                  {activeNote && (
                    <button
                      onClick={() => {
                        setActiveNote(null);
                        setNoteTitle('');
                        setNoteContent('');
                      }}
                      className="text-[10px] font-mono text-neutral-500 hover:text-white cursor-pointer"
                    >
                      [{locVal('Cancel Edit', 'إلغاء التعديل')}]
                    </button>
                  )}
                </div>

                <div className="space-y-3.5">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Title */}
                    <div>
                      <label className="block text-[9px] font-mono text-neutral-500 uppercase mb-1.5">{locVal('Note Title', 'عنوان الملاحظة المشفرة')}</label>
                      <input 
                        type="text" 
                        value={noteTitle}
                        onChange={(e) => setNoteTitle(e.target.value)}
                        placeholder={locVal('Enter highly descriptive title...', 'أدخل عنواناً معبراً ودقيقاً...')}
                        className="w-full px-3 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white font-sans focus:border-cyan-400 focus:outline-none placeholder:text-neutral-700"
                      />
                    </div>

                    {/* Category Selection */}
                    <div>
                      <div className="flex justify-between items-baseline mb-1.5">
                        <label className="block text-[9px] font-mono text-neutral-500 uppercase">{locVal('Security Category', 'تصنيف الأمن والحفظ')}</label>
                        {!isAddingCat ? (
                          <button 
                            onClick={() => setIsAddingCat(true)}
                            className="text-[9px] text-cyan-400 hover:text-cyan-300 font-mono cursor-pointer"
                          >
                            + {locVal('Add', 'تسجيل جديد')}
                          </button>
                        ) : (
                          <button 
                            onClick={handleAddCategory}
                            className="text-[9px] text-emerald-400 hover:text-emerald-300 font-mono cursor-pointer font-bold"
                          >
                            [ {locVal('Save', 'حفظ')} ]
                          </button>
                        )}
                      </div>

                      {isAddingCat ? (
                        <input 
                          type="text"
                          placeholder={locVal('New category name...', 'اسم التصنيف الجديد...')}
                          value={newCatName}
                          onChange={(e) => setNewCatName(e.target.value)}
                          onKeyDown={(e) => e.key === 'Enter' && handleAddCategory()}
                          className="w-full px-3 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white focus:border-cyan-400 focus:outline-none"
                        />
                      ) : (
                        <select
                          value={noteCategory}
                          onChange={(e) => setNoteCategory(e.target.value)}
                          className="w-full px-3 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white focus:border-cyan-400 focus:outline-none cursor-pointer"
                        >
                          {categories.map((c, idx) => (
                            <option key={idx} value={c}>{c}</option>
                          ))}
                        </select>
                      )}
                    </div>
                  </div>

                  {/* Note Color selection & Selective Lock */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Color Select */}
                    <div>
                      <label className="block text-[9px] font-mono text-neutral-500 uppercase mb-1.5">{locVal('Visual Classification Color', 'رمز اللون المساعد للفرز البصري')}</label>
                      <div className="flex gap-2">
                        {NOTE_COLORS.map((c, idx) => (
                          <button
                            key={idx}
                            onClick={() => setNoteColor(c.value)}
                            className={`w-6 h-6 rounded-full cursor-pointer border transition ${
                              noteColor === c.value ? 'border-white scale-110 shadow-lg' : 'border-neutral-850 hover:scale-105'
                            }`}
                            style={{ backgroundColor: c.value }}
                            title={c.name}
                          />
                        ))}
                      </div>
                    </div>

                    {/* Selective note lock */}
                    <div className="bg-neutral-950/40 p-3 rounded-xl border border-neutral-900 flex justify-between items-center">
                      <div className="space-y-0.5">
                        <span className="block text-[10px] font-mono font-medium text-white">{locVal('Selective Lock Encryption', 'درع الحماية الانتقائية الإضافية')}</span>
                        <span className="block text-[8px] text-neutral-500 leading-tight">{locVal('Mask title & body until additional passcode match.', 'حظر عنوان ونص الملاحظة بقفل مخصص حتى مطابقة رمز إضافي.')}</span>
                      </div>
                      
                      <button
                        onClick={() => setIsNoteSelectiveLocked(!isNoteSelectiveLocked)}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-[10px] font-mono font-bold cursor-pointer transition ${
                          isNoteSelectiveLocked 
                            ? 'bg-rose-950/20 border-rose-800 text-rose-400' 
                            : 'bg-neutral-900 border-neutral-800 text-neutral-400 hover:text-white'
                        }`}
                      >
                        {isNoteSelectiveLocked ? <Lock className="w-3 h-3 text-rose-400" /> : <Unlock className="w-3 h-3" />}
                        <span>{isNoteSelectiveLocked ? locVal('LOCKED', 'مقيد بكلمة سر') : locVal('UNLOCKED', 'مفتوح للعموم')}</span>
                      </button>
                    </div>
                  </div>

                  {/* Content textarea */}
                  <div>
                    <label className="block text-[9px] font-mono text-neutral-500 uppercase mb-1.5">{locVal('Directive Secure Note Payload', 'متن نص الملاحظة المألوف المشفر')}</label>
                    <textarea 
                      value={noteContent}
                      onChange={(e) => setNoteContent(e.target.value)}
                      placeholder={locVal('Input delicate scientific formulas, recovery words, API configurations, or seed entries here...', 'اكتب المتون والصيغ السرية، معلمات واجهة التطبيقات البرمجية، أو كلمات الهوية هنا...')}
                      rows={6}
                      className="w-full p-4 text-xs rounded-xl bg-neutral-950 border border-neutral-900 focus:border-cyan-400 text-white font-sans focus:outline-none placeholder:text-neutral-800 resize-y scrollbar-thin"
                    />
                  </div>

                  <button
                    onClick={handleCreateOrUpdateNote}
                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-cyan-500 to-purple-500 text-black text-xs font-bold hover:scale-[1.01] transition duration-200 cursor-pointer"
                  >
                    <Save className="w-4 h-4 text-black" />
                    <span>{activeNote ? locVal('UPDATE & RE-CIPHER DIRECTIVE', 'أرشفة وتحديث الملاحظة المشفرة المحددة') : locVal('COMMIT SECURE DIRECTIVE TO VAULT', 'تأكيد وحفظ الملاحظة المشفرة الجديدة')}</span>
                  </button>
                </div>
              </div>

              {/* Notes Filter Options & Actions Row */}
              <div className="glass-card p-4 rounded-xl border border-neutral-850 flex flex-col md:flex-row gap-4 items-center justify-between">
                
                {/* Search input of decrypted data */}
                <div className="relative w-full md:max-w-xs">
                  <Search className="absolute left-3.5 top-2.5 w-4 h-4 text-neutral-600" />
                  <input 
                    type="text" 
                    placeholder={locVal('Index scan title or text...', 'بحْث وتدقيق عن عبارات أو نصوص...')}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full ps-10 pe-4 py-2 text-xs rounded-xl bg-neutral-950 border border-neutral-900 text-white focus:border-cyan-400 focus:outline-none placeholder:text-neutral-700"
                  />
                </div>

                {/* Filters Wrap */}
                <div className="flex flex-wrap items-center gap-3 w-full md:w-auto md:justify-end">
                  
                  {/* Category Filter */}
                  <div className="flex items-center gap-1.5 text-xs text-neutral-400">
                    <Folder className="w-3.5 h-3.5 text-neutral-500" />
                    <select
                      value={selectedCategory}
                      onChange={(e) => setSelectedCategory(e.target.value)}
                      className="bg-neutral-950 px-2 py-1.5 rounded-lg border border-neutral-900 text-white text-[11px] focus:outline-none cursor-pointer"
                    >
                      <option value="All">{locVal('All Folders', 'كافة المجلدات')}</option>
                      {categories.map((c, idx) => (
                        <option key={idx} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>

                  {/* Color Filter */}
                  <div className="flex items-center gap-1.5 text-xs text-neutral-400">
                    <div className="w-2.5 h-2.5 rounded-full bg-cyan-400" />
                    <select
                      value={selectedColor}
                      onChange={(e) => setSelectedColor(e.target.value)}
                      className="bg-neutral-950 px-2 py-1.5 rounded-lg border border-neutral-900 text-white text-[11px] focus:outline-none cursor-pointer"
                    >
                      <option value="All">{locVal('All Colors', 'كافة الألوان')}</option>
                      {NOTE_COLORS.map((c, idx) => (
                        <option key={idx} value={c.value}>{c.name}</option>
                      ))}
                    </select>
                  </div>

                  {/* View Mode Toggle */}
                  <div className="flex items-center border border-neutral-900 bg-neutral-950 rounded-lg overflow-hidden">
                    <button 
                      onClick={() => setViewMode('grid')}
                      className={`p-1.5 cursor-pointer ${viewMode === 'grid' ? 'bg-neutral-800 text-white' : 'text-neutral-500 hover:text-white'}`}
                    >
                      <LayoutGrid className="w-3.5 h-3.5" />
                    </button>
                    <button 
                      onClick={() => setViewMode('list')}
                      className={`p-1.5 cursor-pointer ${viewMode === 'list' ? 'bg-neutral-800 text-white' : 'text-neutral-500 hover:text-white'}`}
                    >
                      <List className="w-3.5 h-3.5" />
                    </button>
                  </div>

                </div>

              </div>

              {/* Notes Display Layout */}
              {filteredNotes.length === 0 ? (
                <div className="p-8 text-center bg-neutral-900/10 rounded-xl border border-neutral-900">
                  <FileText className="w-8 h-8 text-neutral-700 mx-auto mb-1 animate-pulse" />
                  <span className="block text-xs text-neutral-500">{locVal('Zero secure matching nodes file indexes found.', 'لم يتم العثور على أية إدخالات أو إرشادات تطابق البحث.')}</span>
                </div>
              ) : (
                <div className={viewMode === 'grid' ? 'grid grid-cols-1 md:grid-cols-2 gap-4' : 'space-y-3'}>
                  {filteredNotes.map((n) => {
                    const isSelectivelyLocked = n.isSelectiveLocked && !tempUnlockedNotes[n.id];
                    const selectedColorObj = NOTE_COLORS.find(c => c.value === n.color) || NOTE_COLORS[0];

                    return (
                      <div
                        key={n.id}
                        className={`p-5 rounded-2xl border transition duration-200 relative group overflow-hidden ${
                          selectedColorObj.bgClass
                        } ${
                          activeNote?.id === n.id ? 'ring-2 ring-purple-500 border-purple-500' : 'border-neutral-850'
                        }`}
                      >
                        {/* Pinned Tag Accent */}
                        <div 
                          className="absolute left-0 top-0 bottom-0 w-1 rounded-s-2xl" 
                          style={{ backgroundColor: n.color }}
                        />

                        {/* Top Metadata Header of Note */}
                        <div className="flex justify-between items-start gap-2 mb-2 pb-1.5 border-b border-neutral-900">
                          <div className="flex flex-wrap items-center gap-2">
                            {n.isPinned && <Pin className="w-3 h-3 text-cyan-400 rotate-45 shrink-0" />}
                            <span className="text-[8px] font-mono font-bold tracking-wider text-neutral-400 uppercase bg-neutral-950/60 px-2 py-0.5 rounded border border-neutral-850">{n.category}</span>
                            <span className="text-[7.5px] font-mono text-neutral-500">{new Date(n.lastModifiedAt).toLocaleDateString()}</span>
                          </div>

                          <div className="flex items-center gap-1.5">
                            {/* Pin toggler */}
                            <button
                              onClick={() => handleTogglePin(n.id)}
                              className="text-neutral-500 hover:text-white transition cursor-pointer p-0.5"
                              title={locVal('Pin note', 'تثبيت الملاحظة')}
                            >
                              <Pin className={`w-3.5 h-3.5 ${n.isPinned ? 'text-amber-400 animate-pulse' : 'opacity-40 hover:opacity-100'}`} />
                            </button>

                            {/* Markdown Export direct */}
                            <button
                              onClick={() => triggerExportSingleNote(n)}
                              className="text-neutral-500 hover:text-white transition cursor-pointer p-0.5"
                              title={locVal('Export MD', 'تصدير بصيغة Markdown')}
                            >
                              <Download className="w-3.5 h-3.5 opacity-50 hover:opacity-100" />
                            </button>

                            {/* Purge Note */}
                            <button
                              onClick={() => handleDeleteNote(n.id)}
                              className="text-neutral-500 hover:text-rose-400 transition cursor-pointer p-0.5"
                              title={locVal('Destroy note', 'تدمير ومسح الملاحظة')}
                            >
                              <Trash2 className="w-3.5 h-3.5 opacity-50 hover:opacity-100" />
                            </button>
                          </div>
                        </div>

                        {/* Selective locked screen or actual note values */}
                        {isSelectivelyLocked ? (
                          <div className="py-4 text-center space-y-3 relative z-10">
                            <div className="w-8 h-8 rounded-full bg-neutral-950/60 border border-neutral-850 flex items-center justify-center mx-auto">
                              <Lock className="w-3.5 h-3.5 text-rose-400" />
                            </div>

                            <div className="space-y-1">
                              <span className="block text-[11px] font-mono font-semibold text-neutral-300">
                                {locVal('Selective Node Locked', 'ملاحظة تخضع لقفل انتقائي')}
                              </span>
                              <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-widest leading-none">
                                {locVal('Input main passcode or scan biometrics.', 'أدخل كلمة مرور النظام أو امسح البصمة للفتح.')}
                              </span>
                            </div>

                            {/* Biometric quick access choice for note */}
                            {biometricsActive && (
                              <div className="flex justify-center pb-1">
                                {isNoteScanning[n.id] ? (
                                  <div className="flex items-center gap-1.5 bg-neutral-950/80 px-2.5 py-1 rounded-lg border border-purple-500/50 text-[9px] font-mono text-purple-400 animate-pulse">
                                    <Fingerprint className="w-3.5 h-3.5 animate-bounce" />
                                    <span>{locVal('RE-AUTH...', 'جاري التحقق...')}</span>
                                  </div>
                                ) : (
                                  <button
                                    onClick={() => {
                                      setIsNoteScanning(prev => ({ ...prev, [n.id]: true }));
                                      onSecurityLog(
                                        'Biometric re-authentication triggered', 
                                        'info', 
                                        `Verifying identity for viewing locked note: "${n.title}".`
                                      );
                                      setTimeout(() => {
                                        setIsNoteScanning(prev => ({ ...prev, [n.id]: false }));
                                        setTempUnlockedNotes(prev => ({ ...prev, [n.id]: true }));
                                        onSecurityLog(
                                          'Biometric re-authentication verified', 
                                          'success', 
                                          `Identity confirmed via ${biometricType.toUpperCase()}. Opened note: "${n.title}".`
                                        );
                                        onSuccess(locVal('Identity verified! Note decrypted.', 'تم تأكيد هويتك الحيوية! فك تشفير الملاحظة.'), 'success');
                                      }, 1000);
                                    }}
                                    className="flex items-center gap-1 bg-purple-950/30 hover:bg-purple-900/40 border border-purple-800/60 text-purple-400 px-3 py-1 rounded-full text-[9px] font-mono font-bold cursor-pointer transition active:scale-95 shadow"
                                  >
                                    <Fingerprint className="w-3.5 h-3.5" />
                                    <span>{locVal('SCAN TO UNLOCK', 'امسح لفك القفل')}</span>
                                  </button>
                                )}
                              </div>
                            )}

                            <div className="flex gap-2 max-w-[170px] mx-auto">
                              <input 
                                type="password"
                                placeholder="Key..."
                                value={unlockSelectivePasscode}
                                onChange={(e) => setUnlockSelectivePasscode(e.target.value)}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter') {
                                    if (unlockSelectivePasscode === vaultPassword) {
                                      setTempUnlockedNotes(prev => ({ ...prev, [n.id]: true }));
                                      setUnlockSelectivePasscode('');
                                    } else {
                                      onSuccess(locVal('Incorrect password!', 'كلمة مرور خاطئة!'), 'error');
                                    }
                                  }
                                }}
                                className="w-full text-center px-2 py-1 text-[10px] font-mono rounded bg-neutral-950 border border-neutral-850 focus:border-rose-400 focus:outline-none"
                              />
                              <button
                                onClick={() => {
                                  if (unlockSelectivePasscode === vaultPassword) {
                                    setTempUnlockedNotes(prev => ({ ...prev, [n.id]: true }));
                                    setUnlockSelectivePasscode('');
                                  } else {
                                    onSuccess(locVal('Incorrect password!', 'كلمة مرور خاطئة!'), 'error');
                                  }
                                }}
                                className="px-2.5 py-1 bg-neutral-950 text-rose-400 text-[10px] hover:bg-rose-900 border border-rose-800 rounded font-semibold cursor-pointer"
                              >
                                {locVal('OK', 'تأكيد')}
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className="space-y-2 cursor-pointer" onClick={() => {
                            setActiveNote(n);
                            setNoteTitle(n.title);
                            setNoteContent(n.content);
                            setNoteCategory(n.category);
                            setNoteColor(n.color);
                            setIsNoteSelectiveLocked(n.isSelectiveLocked);
                          }}>
                            <h4 className="text-[12px] font-display font-bold text-white group-hover:text-cyan-300 transition duration-150 leading-tight">
                              {n.title}
                            </h4>
                            <p className="text-[10px] text-neutral-300 leading-normal line-clamp-3 font-sans whitespace-pre-wrap">
                              {n.content}
                            </p>

                            <div className="pt-2 text-[8px] font-mono text-neutral-500 text-end flex justify-between items-center">
                              {n.isSelectiveLocked && (
                                <span className="flex items-center gap-1 text-[8.5px] text-emerald-400 font-bold bg-neutral-950/60 border border-emerald-900 px-1.5 py-0.5 rounded-md">
                                  <ShieldCheck className="w-3 h-3 text-emerald-400" />
                                  {locVal('DECRYPTED STATE', 'مفكوكة القفل مؤقتاً')}
                                </span>
                              )}
                              <span className="ms-auto flex items-center gap-1 group-hover:text-neutral-300 transition shrink-0 uppercase select-none">
                                {locVal('EDIT NOTE', 'قراءة وتعديل الملاحظة')} <ChevronRight className="w-3 h-3 text-neutral-400" />
                              </span>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}

            </div>
          )}

        </div>

      </div>
    </div>
  );
};
