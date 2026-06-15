import React, { useState, useRef } from 'react';
import { 
  File, Upload, Download, Key, ShieldCheck, Clock, AlertTriangle 
} from 'lucide-react';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt,
} from '../lib/crypto';
import { EncryptedContainer } from '../types';
import { useTranslation } from '../lib/I18nContext';

interface FileEncProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

export const FileEncryptionModule: React.FC<FileEncProps> = ({ 
  onSuccess, 
  onSecurityLog, 
  triggerAnimation 
}) => {
  const { t, locale } = useTranslation();

  // Input parameters
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [encryptPassword, setEncryptPassword] = useState<string>('');
  
  // Capsule Time locks
  const [isTimeCapsule, setIsTimeCapsule] = useState<boolean>(false);
  const [lockDate, setLockDate] = useState<string>('');
  const [lockTime, setLockTime] = useState<string>('');

  // Results
  const [encryptedFileContainer, setEncryptedFileContainer] = useState<EncryptedContainer | null>(null);

  // Decrypt File assets
  const [decryptContainerFile, setDecryptContainerFile] = useState<EncryptedContainer | null>(null);
  const [decryptContainerName, setDecryptContainerName] = useState<string>('');
  const [decryptPassword, setDecryptPassword] = useState<string>('');

  const fileInputRef = useRef<HTMLInputElement>(null);
  const decryptInputRef = useRef<HTMLInputElement>(null);

  const handleFileDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const file = e.dataTransfer.files?.[0];
    if (file) {
      setSelectedFile(file);
      onSuccess(locale === 'ar' ? `تم تحميل ${file.name} لحسابات الطيف` : `Loaded ${file.name} for spectrum calculation`, 'info');
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      onSuccess(locale === 'ar' ? `تم تحميل ${file.name} لحسابات الطيف` : `Loaded ${file.name} for spectrum calculation`, 'info');
    }
  };

  const executeFileEncrypt = () => {
    if (!selectedFile) {
      onSuccess(locale === 'ar' ? 'يرجى تحميل أو سحب الملف المراد حمايته أولاً.' : 'Please upload or drag a target file first.', 'error');
      return;
    }
    if (!encryptPassword || encryptPassword.length < 6) {
      onSuccess(locale === 'ar' ? 'يجب أن تتكون كلمة المرور المتناظرة من 6 أحرف على الأقل.' : 'Symmetric password must be at least 6 characters.', 'error');
      return;
    }

    let unlockTimestamp: number | undefined = undefined;
    if (isTimeCapsule) {
      if (!lockDate || !lockTime) {
        onSuccess(locale === 'ar' ? 'يرجى تحديد تفاصيل التاريخ والوقت المجدول لختم الكبسولة.' : 'Please specify future date and time constraints to seal the capsule.', 'error');
        return;
      }
      const combinedDateTime = new Date(`${lockDate}T${lockTime}`);
      unlockTimestamp = combinedDateTime.getTime();
      if (unlockTimestamp <= Date.now()) {
        onSuccess(locale === 'ar' ? 'يجب أن يكون تاريخ القفل بالكامل في المستقبل.' : 'Seal date constraints must exist strictly in the future.', 'error');
        return;
      }
    }

    triggerAnimation('encrypt');
    onSecurityLog('File extraction routine started', 'info', `Target: ${selectedFile.name} (${selectedFile.size} Bytes)`);

    const reader = new FileReader();
    reader.onload = () => {
      try {
        const rawArrayBuffer = reader.result as ArrayBuffer;
        const fileBytes = new Uint8Array(rawArrayBuffer);
        
        const container = executeRiemannTripleLayerEncrypt(fileBytes, encryptPassword, {
          filename: selectedFile.name,
          fileType: selectedFile.type,
          isCapsule: isTimeCapsule,
          unlockTimestamp: unlockTimestamp
        });

        setEncryptedFileContainer(container);
        
        // Post notification and download direct trigger
        onSecurityLog(
          isTimeCapsule ? 'Time capsule capsule locking verified' : 'File container shielding completed',
          isTimeCapsule ? 'warning' : 'info',
          `Wrapped ${selectedFile.name} successfully.`
        );
        onSuccess(
          isTimeCapsule 
            ? (locale === 'ar' ? 'تم قفل الكبسولة الزمنية في فضاء ريمان كربتست' : 'Capsule sealed under Riemann lock') 
            : (locale === 'ar' ? 'تم تأمين الملف وتغليفه بنجاح داخل حاوية ريمان' : 'File secured successfully into containment wrapper'),
          'success'
        );
      } catch (err: any) {
        onSecurityLog('Symmetric wrap fault triggered', 'critical', err.message || 'General file stream error');
        onSuccess(`${locale === 'ar' ? 'خطأ في تجميع الملف' : 'File compilation error'}: ${err.message}`, 'error');
      }
    };
    reader.readAsArrayBuffer(selectedFile);
  };

  const triggerDownloadEncrypted = () => {
    if (!encryptedFileContainer) return;
    const jsonStr = JSON.stringify(encryptedFileContainer, null, 2);
    const blob = new Blob([jsonStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${encryptedFileContainer.filename || 'quantum_secure'}.riman`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    onSuccess(locale === 'ar' ? 'تم تحميل ملف حاوية ريمان (.riman)' : 'Encrypted Riman (.riman) container downloaded', 'success');
  };

  const handleDecryptFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setDecryptContainerName(file.name);
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const parsed = JSON.parse(reader.result as string) as EncryptedContainer;
        if (!parsed.payload || !parsed.saltGcm || !parsed.saltCbc) {
          throw new Error(locale === 'ar' ? 'بيانات التشفير مفقودة. هذا ليس ملف ريمان صالح.' : 'Missing core cryptographic fields. File is not a valid Riman Container.');
        }
        setDecryptContainerFile(parsed);
        onSuccess(locale === 'ar' ? 'تم بناء خرائط ملف .riman الآمن' : 'Secured .riman metadata mapped', 'info');
      } catch (err: any) {
        onSuccess(`${locale === 'ar' ? 'هيكلة غير صالحة' : 'Invalid file schema'}: ${err.message}`, 'error');
      }
    };
    reader.readAsText(file);
  };

  const executeFileDecrypt = () => {
    if (!decryptContainerFile) {
      onSuccess(locale === 'ar' ? 'يرجى رفع ملف ريمان (.riman) الآمن أولاً.' : 'Please upload an encrypted Riman (.riman) file first.', 'error');
      return;
    }
    if (!decryptPassword) {
      onSuccess(locale === 'ar' ? 'يرجى إدخال كلمة سر فك التشفير.' : 'Please enter your decrypt password.', 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Encrypted block structure reading initiated', 'info', `Target container filename: ${decryptContainerFile.filename}`);

      const plaintextBytes = executeRiemannTripleLayerDecrypt(decryptContainerFile, decryptPassword);
      
      // Reconstitute file binary trigger download
      const originalFileBlob = new Blob([plaintextBytes], { type: decryptContainerFile.fileType || 'application/octet-stream' });
      const url = URL.createObjectURL(originalFileBlob);
      const a = document.createElement('a');
      a.href = url;
      a.download = decryptContainerFile.filename || 'reconstituted_file';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);

      onSecurityLog('Decryption sequence authenticated', 'info', `Verified GCM integrity check block. Stream parsed.`);
      onSuccess(locale === 'ar' ? 'تم فك تشفير وتنزيل الملف الأصلي بنجاح' : 'Decrypted and downloaded original file successfully', 'success');
    } catch (err: any) {
      onSecurityLog('Decryption phase mismatch triggered', 'critical', err.message || 'Authorization rejected');
      onSuccess(`${locale === 'ar' ? 'ترفض فك التشفير' : 'Decryption rejected'}: ${err.message}`, 'error');
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      {/* File Encryptor Card */}
      <div className="glass-card p-6 rounded-2xl flex flex-col justify-between space-y-4">
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <Upload className="w-5 h-5 text-purple-400" />
            <h3 className="font-display font-semibold text-white tracking-tight">{t('file_locker_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400 font-sans">
            {t('file_locker_desc')}
          </p>

          {/* Dropzone area */}
          <div 
            onDragOver={(e) => e.preventDefault()}
            onDrop={handleFileDrop}
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-neutral-805 hover:border-purple-500/50 rounded-xl p-6 text-center cursor-pointer transition bg-neutral-900/10 flex flex-col items-center justify-center space-y-2 min-h-[140px]"
          >
            <File className="w-8 h-8 text-neutral-500" />
            <div>
              <span className="text-xs text-neutral-300 font-medium">
                {selectedFile ? selectedFile.name : t('select_drag_file')}
              </span>
              {selectedFile && (
                <span className="block text-[10px] text-neutral-500 font-mono mt-0.5">
                  {(selectedFile.size / 1024).toFixed(2)} KB
                </span>
              )}
            </div>
            <span className="text-[10px] text-purple-400 font-mono tracking-wider uppercase">
              {selectedFile ? t('change_file') : t('browse_files')}
            </span>
            <input 
              ref={fileInputRef}
              type="file" 
              onChange={handleFileSelect}
              className="hidden" 
            />
          </div>

          <div className="space-y-3 pt-2">
            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('protection_password')}</label>
              <div className="relative">
                <Key className="absolute left-3 top-2.5 w-4 h-4 text-neutral-500" />
                <input 
                  type="password"
                  placeholder="••••••••••••"
                  value={encryptPassword}
                  onChange={(e) => setEncryptPassword(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-xl bg-neutral-900/60 border border-neutral-800/60 text-sm text-white focus:outline-none focus:border-purple-500"
                />
              </div>
            </div>

            {/* Time Capsule Toggle Section */}
            <div className="p-3.5 bg-neutral-950/40 rounded-xl border border-neutral-900 space-y-3">
              <label className="flex items-center justify-between cursor-pointer">
                <span className="text-xs font-sans text-neutral-300 flex items-center gap-1.5 font-semibold">
                  <Clock className="w-4 h-4 text-pink-400" />
                  {t('seal_chrono_capsule')}
                </span>
                <input 
                  type="checkbox"
                  checked={isTimeCapsule}
                  onChange={(e) => setIsTimeCapsule(e.target.checked)}
                  className="rounded bg-neutral-900 accent-pink-500 border-neutral-800 w-4 h-4 cursor-pointer"
                />
              </label>
              
              {isTimeCapsule && (
                <div className="grid grid-cols-2 gap-3 pt-2 animate-slide-in">
                  <div>
                    <label className="block text-[9px] text-neutral-500 font-mono uppercase mb-0.5">{t('unlock_date')}</label>
                    <input 
                      type="date"
                      value={lockDate}
                      onChange={(e) => setLockDate(e.target.value)}
                      className="w-full px-2.5 py-1 text-xs rounded-lg bg-neutral-900 border border-neutral-850 font-mono text-white focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-[9px] text-neutral-500 font-mono uppercase mb-0.5">{t('unlock_time_utc')}</label>
                    <input 
                      type="time"
                      value={lockTime}
                      onChange={(e) => setLockTime(e.target.value)}
                      className="w-full px-2.5 py-1 text-xs rounded-lg bg-neutral-900 border border-neutral-850 font-mono text-white focus:outline-none"
                    />
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="space-y-3">
          <button 
            onClick={executeFileEncrypt}
            className="w-full py-2.5 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white text-sm font-sans font-bold tracking-tight shadow-md transition active:scale-95 cursor-pointer"
          >
            {isTimeCapsule ? t('seal_time_capsule_btn') : t('encrypt_secure_btn')}
          </button>

          {encryptedFileContainer && (
            <button 
              onClick={triggerDownloadEncrypted}
              className="w-full py-2.5 rounded-xl border border-emerald-500/30 bg-emerald-950/20 hover:bg-emerald-950/40 text-emerald-400 text-sm font-sans font-semibold tracking-tight transition flex items-center justify-center gap-2 animate-fade-in cursor-pointer"
            >
              <Download className="w-4 h-4" />
              {t('download_secured_btn')}
            </button>
          )}
        </div>
      </div>

      {/* File Decryptor Card */}
      <div className="glass-card p-6 rounded-2xl flex flex-col justify-between space-y-4">
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-cyan-400" />
            <h3 className="font-display font-semibold text-white tracking-tight">{t('dec_portal_title')}</h3>
          </div>
          <p className="text-xs text-neutral-400">
            {t('dec_portal_desc')}
          </p>

          <div 
            onClick={() => decryptInputRef.current?.click()}
            className="border-2 border-dashed border-neutral-805 hover:border-cyan-500/50 rounded-xl p-6 text-center cursor-pointer transition bg-neutral-900/10 flex flex-col items-center justify-center space-y-2 min-h-[140px]"
          >
            <ShieldCheck className="w-8 h-8 text-neutral-500 animate-pulse" />
            <div>
              <span className="text-xs text-neutral-300 font-medium">
                {decryptContainerName ? decryptContainerName : t('upload_riman_placeholder')}
              </span>
            </div>
            <span className="text-[10px] text-cyan-400 font-mono tracking-wider uppercase">
              {decryptContainerName ? t('change_container') : t('select_riman_archive')}
            </span>
            <input 
              ref={decryptInputRef}
              type="file" 
              accept=".riman"
              onChange={handleDecryptFileUpload}
              className="hidden" 
            />
          </div>

          <div className="space-y-3 pt-2">
            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('capsule_match_password')}</label>
              <div className="relative">
                <Key className="absolute left-3 top-2.5 w-4 h-4 text-neutral-500" />
                <input 
                  type="password"
                  placeholder={t('master_decrypt_placeholder')}
                  value={decryptPassword}
                  onChange={(e) => setDecryptPassword(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-xl bg-neutral-900/60 border border-neutral-800/60 text-sm text-white focus:outline-none focus:border-cyan-500"
                />
              </div>
            </div>

            {decryptContainerFile && decryptContainerFile.isCapsule && decryptContainerFile.unlockTimestamp && (
              <div className="p-3 bg-pink-950/15 border border-pink-500/20 rounded-xl flex items-start gap-2.5 text-xs text-pink-300">
                <AlertTriangle className="w-4.5 h-4.5 text-pink-400 shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold block">{t('time_lock_restriction')}</span>
                  <span className="text-[10px] text-pink-400 font-mono">
                    {t('time_lock_remaining_utc', { time: new Date(decryptContainerFile.unlockTimestamp).toLocaleString() })}
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>

        <button 
          onClick={executeFileDecrypt}
          className="w-full py-2.5 rounded-xl bg-gradient-to-r from-cyan-600 to-teal-600 hover:from-cyan-500 hover:to-teal-500 text-white text-sm font-sans font-bold tracking-tight shadow-md transition active:scale-95 cursor-pointer"
        >
          {t('auth_reconstitute_btn')}
        </button>
      </div>

    </div>
  );
};
