import React, { useState, useEffect } from 'react';
import { 
  Clock, Lock, Unlock, Compass, AlertTriangle 
} from 'lucide-react';
import { useTranslation } from '../lib/I18nContext';
import { EncryptedContainer } from '../types';

interface CapsuleProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

interface ActiveCapsule {
  id: string;
  name: string;
  dateCreated: number;
  unlockTime: number;
  container: EncryptedContainer;
}

export const TimeCapsuleModule: React.FC<CapsuleProps> = ({ 
  onSuccess, 
  onSecurityLog, 
  triggerAnimation 
}) => {
  const { t, locale } = useTranslation();

  const [activeCapsules, setActiveCapsules] = useState<ActiveCapsule[]>([]);
  const [dummyPassword, setDummyPassword] = useState<string>('');
  const [selectedCapsuleId, setSelectedCapsuleId] = useState<string | null>(null);
  const [currentTime, setCurrentTime] = useState<number>(Date.now());

  // Set real-time ticker
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  // Hydrate premium presets
  useEffect(() => {
    const now = Date.now();
    const preset1: EncryptedContainer = {
      version: '1.0.0-Riemann_Cryptst',
      timestamp: now - 3600000,
      layer1Schema: 'Riemann XOR Field',
      layer2Schema: 'AES-256-GCM',
      layer3Schema: 'AES-256-CBC',
      saltGcm: 'e4a3b7d19c02ffed',
      saltCbc: '3a98bcdef0123f45',
      ivGcm: 'b9a87d654321fcde',
      ivCbc: '12345678abcdef01',
      riemannOffset: 14,
      payload: 'U292ZXJlaWduIHF1YW50dW0=',
      filename: 'financial_ledger_2026.pdf',
      fileSize: 4521020,
      isCapsule: true,
      unlockTimestamp: now + 1200000 // 20 minutes from now
    };

    const preset2: EncryptedContainer = {
      version: '1.0.0-Riemann_Cryptst',
      timestamp: now - 7200000,
      layer1Schema: 'Riemann XOR Field',
      layer2Schema: 'AES-256-GCM',
      layer3Schema: 'AES-256-CBC',
      saltGcm: 'fa56da781c90bcde',
      saltCbc: '9a7bc012def3456a',
      ivGcm: 'c87db98f21e0ab12',
      ivCbc: '876543210bcdef4c',
      riemannOffset: 42,
      payload: 'U2VjcmV0IEFwa2V5cw==',
      filename: 'android_production_keystore.jks',
      fileSize: 12402,
      isCapsule: true,
      unlockTimestamp: now - 60000 // Already unlocked (1 minute ago)
    };

    setActiveCapsules([
      { id: 'CAP-01', name: 'financial_ledger_2026.pdf', dateCreated: now - 3600000, unlockTime: now + 1200000, container: preset1 },
      { id: 'CAP-02', name: 'android_production_keystore.jks', dateCreated: now - 7200000, unlockTime: now - 60000, container: preset2 }
    ]);
  }, []);

  const getCountdownString = (unlockTimestamp: number) => {
    const diff = unlockTimestamp - currentTime;
    if (diff <= 0) return t('ready_decryption');
    
    const d = Math.floor(diff / (1000 * 60 * 60 * 24));
    const h = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const s = Math.floor((diff % (1000 * 60)) / 1000);
    
    const daysStr = d > 0 ? `${d}${t('day_short')} ` : '';
    return `${daysStr}${h.toString().padStart(2, '0')}${t('hour_short')} ${m.toString().padStart(2, '0')}${t('minute_short')} ${s.toString().padStart(2, '0')}${t('second_short')}`;
  };

  const handleDecapsulate = () => {
    if (!selectedCapsuleId) return;
    const capsule = activeCapsules.find(c => c.id === selectedCapsuleId);
    if (!capsule) return;

    if (currentTime < capsule.unlockTime) {
      onSuccess(locale === 'ar' ? 'درع الاحتواء نشط. فك التشفير مغلق زمنياً بالكامل.' : 'Quantum containment shield active. Decryption is mathematically locked.', 'error');
      return;
    }

    if (!dummyPassword) {
      onSuccess(locale === 'ar' ? 'كلمة المرور مطلوبة لإذابة درع الحماية الزمني.' : 'Key password required to dissolve the shield.', 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Decapsulator tunnel matching keys', 'info', `Target: ${capsule.name}`);
      
      if (capsule.id === 'CAP-02' && dummyPassword === 'riman123') {
        const fileContent = 'SOVEREIGN SECURE DUMMY KEY DATA CONFIGURATION BLOCKS';
        const blob = new Blob([fileContent], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = capsule.name;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        onSuccess(locale === 'ar' ? 'تمت إذابة قفل الكبسولة الزمنية بنجاح!' : 'Chrono Capsule Decapsulated successfully!', 'success');
      } else {
        throw new Error(locale === 'ar' ? 'عدم تطابق توقيع المفتاح المتماثل.' : 'Symmetric key signature mismatch - math matrix failed to align.');
      }
    } catch (err: any) {
      onSecurityLog('Capsule key signature rejection', 'critical', err.message);
      onSuccess(`${locale === 'ar' ? 'بروتوكول التحقق رُفض' : 'Math match failed'}: ${err.message}`, 'error');
    }
  };

  return (
    <div className="space-y-6">
      
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <span className="text-[10px] uppercase tracking-widest font-mono text-pink-400">{t('time_lock_containment')}</span>
          <h2 className="text-xl font-display font-medium text-white tracking-tight">{t('vortex_title')}</h2>
        </div>
        <div className="flex gap-2">
          <span className="flex items-center gap-1.5 px-2.5 py-1 rounded bg-slate-900 border border-slate-800 text-[11px] font-mono text-neutral-400">
            <Compass className="w-4 h-4 text-pink-400" />
            {t('chrono_buffer_active')}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Active Capsules List */}
        <div className="lg:col-span-2 space-y-4">
          <h3 className="text-xs font-mono text-neutral-500 uppercase tracking-wider">{t('active_quantum_seals')}</h3>
          
          <div className="space-y-3">
            {activeCapsules.map((capsule) => {
              const remains = capsule.unlockTime - currentTime;
              const isLocked = remains > 0;
              const isSelected = selectedCapsuleId === capsule.id;

              return (
                <div 
                  key={capsule.id}
                  onClick={() => setSelectedCapsuleId(capsule.id)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all ${
                    isSelected 
                      ? 'bg-neutral-900/60 border-pink-500/50 shadow shadow-pink-500/10' 
                      : 'bg-neutral-900/10 border-neutral-850 hover:bg-neutral-900/30'
                  }`}
                >
                  <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
                    <div className="flex items-center gap-3">
                      <div className={`p-2.5 rounded-lg border ${isLocked ? 'bg-pink-950/20 border-pink-500/30 text-pink-400' : 'bg-emerald-950/20 border-emerald-500/30 text-emerald-400'}`}>
                        {isLocked ? <Lock className="w-4 h-4" /> : <Unlock className="w-4 h-4" />}
                      </div>
                      <div>
                        <span className="font-sans font-semibold text-sm text-neutral-100">{capsule.name}</span>
                        <div className="flex items-center gap-2 mt-0.5 text-[10px] font-mono text-neutral-500">
                          <span>{t('created_at')}: {new Date(capsule.dateCreated).toLocaleString()}</span>
                          <span>•</span>
                          <span>{t('size_label')}: {(capsule.container.fileSize || 0) / 1000} KB</span>
                        </div>
                      </div>
                    </div>

                    <div className="text-start sm:text-end">
                      <span className="block text-[9px] font-mono text-neutral-500">{t('chrono_lock_counter')}</span>
                      <span className={`font-mono text-xs font-bold ${isLocked ? 'text-pink-400 animate-pulse' : 'text-emerald-400'}`}>
                        {getCountdownString(capsule.unlockTime)}
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Portal Controller card */}
        <div className="glass-card p-6 rounded-2xl flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Compass className="w-5 h-5 text-pink-400" />
              <h3 className="font-display font-medium text-white">{t('dissolve_seal_title')}</h3>
            </div>
            
            <p className="text-xs text-neutral-400 leading-relaxed">
              {t('dissolve_seal_desc')}
            </p>

            {selectedCapsuleId ? (
              <div className="space-y-3 pt-2">
                <div className="p-3 rounded-xl bg-neutral-950/40 border border-neutral-900">
                  <span className="block text-[9px] font-mono text-neutral-500">{t('selected_archive')}</span>
                  <span className="text-sm font-sans font-semibold text-neutral-200">
                    {activeCapsules.find(c => c.id === selectedCapsuleId)?.name}
                  </span>
                </div>

                <div>
                  <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('capsule_pass_key')}</label>
                  <input 
                    type="password"
                    placeholder={t('enter_decryption_password_placeholder')}
                    value={dummyPassword}
                    onChange={(e) => setDummyPassword(e.target.value)}
                    className="w-full px-3 py-1.5 rounded-lg bg-neutral-900/60 border border-neutral-800 text-xs text-white focus:outline-none focus:border-pink-500"
                  />
                  <span className="text-[9px] text-neutral-600 block mt-1">{t('demo_password_hint')}</span>
                </div>
              </div>
            ) : (
              <div className="p-8 text-center text-xs text-neutral-500 font-mono border border-neutral-850 rounded-xl bg-neutral-950/20">
                {t('select_active_capsule')}
              </div>
            )}
          </div>

          <button
            disabled={!selectedCapsuleId}
            onClick={handleDecapsulate}
            className={`w-full py-2.5 rounded-xl font-sans font-bold text-sm tracking-tight transition-all duration-300 mt-4 ${
              selectedCapsuleId 
                ? 'bg-gradient-to-r from-pink-600 to-rose-600 hover:from-pink-500 hover:to-rose-500 text-white shadow shadow-pink-950/20 active:scale-95 cursor-pointer' 
                : 'bg-neutral-900 border border-neutral-800 text-neutral-600 cursor-not-allowed'
            }`}
          >
            {t('dissolve_confinement_btn')}
          </button>
        </div>

      </div>

      {/* Cyber Technical Info Banner */}
      <div className="p-4 bg-neutral-900/30 border border-neutral-800/60 rounded-2xl flex gap-3 items-start">
        <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0 mt-0.5 animate-pulse" />
        <div className="space-y-1">
          <span className="font-display font-medium text-xs text-neutral-200 block">{t('proof_matrix_title')}</span>
          <p className="text-[11px] text-neutral-400 leading-relaxed">
            {t('proof_matrix_desc')}
          </p>
        </div>
      </div>

    </div>
  );
};
