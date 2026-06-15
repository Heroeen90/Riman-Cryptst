import React, { useState } from 'react';
import { 
  Lock, Unlock, Copy, Key, ChevronDown, ChevronUp, FileText, Database, ShieldAlert, BadgeCheck 
} from 'lucide-react';
import { 
  executeRiemannTripleLayerEncrypt, 
  executeRiemannTripleLayerDecrypt, 
  stringToBytes, 
  bytesToString 
} from '../lib/crypto';
import { EncryptedContainer } from '../types';
import { useTranslation } from '../lib/I18nContext';

interface TextEncProps {
  onSuccess: (msg: string, type: 'success' | 'error' | 'info') => void;
  onSecurityLog: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
  triggerAnimation: (mode: 'encrypt' | 'decrypt') => void;
}

export const TextEncryptionModule: React.FC<TextEncProps> = ({ 
  onSuccess, 
  onSecurityLog, 
  triggerAnimation 
}) => {
  const { t, locale } = useTranslation();

  // Input parameters
  const [plaintext, setPlaintext] = useState<string>('');
  const [secretPassword, setSecretPassword] = useState<string>('');
  const [encryptedJson, setEncryptedJson] = useState<string>('');
  
  // Decryption parameters
  const [decryptInput, setDecryptInput] = useState<string>('');
  const [decryptPassword, setDecryptPassword] = useState<string>('');
  const [decryptedText, setDecryptedText] = useState<string>('');

  // UI status elements
  const [showMetadata, setShowMetadata] = useState<boolean>(false);
  const [parsedContainer, setParsedContainer] = useState<EncryptedContainer | null>(null);

  const handleTripleLayerEncrypt = () => {
    if (!plaintext) {
      onSuccess(locale === 'ar' ? 'حقل النص المدخل فارغ' : 'Plaintext input field is empty', 'error');
      return;
    }
    if (!secretPassword || secretPassword.length < 6) {
      onSuccess(locale === 'ar' ? 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل لاشتقاق المفتاح' : 'Password must be at least 6 characters for mathematical key space derivation', 'error');
      return;
    }

    try {
      triggerAnimation('encrypt');
      onSecurityLog('Riemann transform initialized', 'info', 'Step 1: Starting critical line zeros position derivation.');
      
      const payloadBytes = stringToBytes(plaintext);
      
      // Execute pipeline
      const container = executeRiemannTripleLayerEncrypt(payloadBytes, secretPassword, {
        fileType: 'text/plain',
        filename: 'riman_secret.txt'
      });
      
      const containerJsonStr = JSON.stringify(container, null, 2);
      setEncryptedJson(containerJsonStr);
      setParsedContainer(container);
      
      onSecurityLog('Triple layer complete', 'info', `Layer 1: Riemann XOR, Layer 2: GCM (${container.saltGcm}), Layer 3: CBC (${container.saltCbc})`);
      onSuccess(locale === 'ar' ? 'تم تأمين النص بنجاح داخل حاوية ريمان السيادية' : 'Text successfully secured into sovereign containment wrapper', 'success');
    } catch (err: any) {
      onSecurityLog('Encryption failure state triggered', 'critical', err.message || 'Unknown matrix error');
      onSuccess(`${locale === 'ar' ? 'فشل التشفير' : 'Encryption failure'}: ${err.message}`, 'error');
    }
  };

  const handleTripleLayerDecrypt = () => {
    if (!decryptInput) {
      onSuccess(locale === 'ar' ? 'رمز الحاوية المدخل فارغ' : 'Containment token string is empty', 'error');
      return;
    }
    if (!decryptPassword) {
      onSuccess(locale === 'ar' ? 'يرجى إدخال كلمة المرور لفك التشفير' : 'Enter secret password to derive decryption matrices', 'error');
      return;
    }

    try {
      triggerAnimation('decrypt');
      onSecurityLog('Decryption sequence active', 'info', 'Step 1: Parsing Riemann Container schemas.');
      
      let container: EncryptedContainer;
      try {
        container = JSON.parse(decryptInput);
      } catch (e) {
        throw new Error(locale === 'ar' ? 'ليست حاوية JSON صالحة لنظام ريمان كربتست.' : 'Not a valid Riman Cryptst dynamic schema JSON block.');
      }

      // Execute reverse pipeline
      const decryptedBytes = executeRiemannTripleLayerDecrypt(container, decryptPassword);
      const outputText = bytesToString(decryptedBytes);
      
      setDecryptedText(outputText);
      onSecurityLog('Decryption verified successfully', 'info', 'Verified Layer-2 HMAC and GCM tag. Reconstituted original plaintext.');
      onSuccess(locale === 'ar' ? 'تم فك التشفير واستعادة النص الأصلي بنجاح' : 'Original text verified and decrypted successfully', 'success');
    } catch (err: any) {
      onSecurityLog('Integrity check fault detected', 'critical', err.message || 'Signature mismatch');
      onSuccess(`${locale === 'ar' ? 'فشل فك التشفير' : 'Decryption failure'}: ${err.message}`, 'error');
    }
  };

  const copyToClipboard = (text: string, label: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    onSuccess(locale === 'ar' ? `تم نسخ ${label} إلى الحافظة` : `${label} copied to clipboard`, 'info');
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      {/* Encryption Module Panel */}
      <div className="glass-card p-6 rounded-2xl flex flex-col justify-between space-y-4">
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Lock className="w-5 h-5 text-purple-400" />
            <h3 className="font-display font-semibold text-white tracking-tight">{t('triple_pipeline_shield')}</h3>
          </div>
          <p className="text-xs text-neutral-400">
            {t('text_shield_desc')}
          </p>

          <div className="space-y-3 pt-2">
            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('secret_key_password')}</label>
              <div className="relative">
                <Key className="absolute left-3 top-2.5 w-4 h-4 text-neutral-500" />
                <input 
                  type="password"
                  placeholder={t('enter_encryption_password')}
                  value={secretPassword}
                  onChange={(e) => setSecretPassword(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-xl bg-neutral-900/60 border border-neutral-800/60 font-sans text-sm text-white focus:outline-none focus:border-purple-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('plaintext_stream_label')}</label>
              <textarea 
                rows={5}
                placeholder={t('plaintext_stream_placeholder')}
                value={plaintext}
                onChange={(e) => setPlaintext(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-neutral-900/60 border border-neutral-800/60 font-sans text-sm text-white focus:outline-none focus:border-purple-500 resize-none"
              />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <button 
            onClick={handleTripleLayerEncrypt}
            className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white text-sm font-sans font-bold tracking-tight shadow-md shadow-purple-950/20 active:scale-95 transition-all cursor-pointer"
          >
            {t('execute_triple_pipeline')}
          </button>

          {encryptedJson && (
            <div className="space-y-3 animate-fade-in">
              <div className="flex justify-between items-center text-[10px] font-mono text-neutral-500">
                <span>{t('riemann_container_schema')}</span>
                <div className="flex gap-2">
                  <button 
                    onClick={() => setShowMetadata(!showMetadata)}
                    className="flex items-center gap-1 hover:text-white transition focus:outline-none cursor-pointer"
                  >
                    {showMetadata ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                    {t('info')}
                  </button>
                  <button 
                    onClick={() => copyToClipboard(encryptedJson, locale === 'ar' ? 'حاوية JSON الآمنة' : 'Secured Container JSON')}
                    className="flex items-center gap-1 hover:text-white transition focus:outline-none cursor-pointer"
                  >
                    <Copy className="w-3.5 h-3.5" />
                    {t('copy_container')}
                  </button>
                </div>
              </div>

              {showMetadata && parsedContainer && (
                <div className="p-3 rounded-xl bg-neutral-950/60 border border-neutral-900 text-[10px] font-mono text-neutral-400 space-y-1 animate-slide-in">
                  <div className="flex justify-between"><span>{t('schema_layer_1')}:</span> <span className="text-cyan-400">{parsedContainer.layer1Schema}</span></div>
                  <div className="flex justify-between"><span>{t('schema_layer_2')}:</span> <span className="text-purple-400">{parsedContainer.layer2Schema}</span></div>
                  <div className="flex justify-between"><span>{t('schema_layer_3')}:</span> <span className="text-indigo-400">{parsedContainer.layer3Schema}</span></div>
                  <div className="flex justify-between"><span>{t('det_zeta_offset')}:</span> <span className="text-neutral-200">{parsedContainer.riemannOffset}</span></div>
                  <div className="flex justify-between"><span>{t('gcm_salt_key')}:</span> <span className="text-neutral-300 truncate max-w-[150px]">{parsedContainer.saltGcm}</span></div>
                  <div className="flex justify-between"><span>{t('cbc_iv_bytes')}:</span> <span className="text-neutral-300 truncate max-w-[150px]">{parsedContainer.ivCbc}</span></div>
                </div>
              )}

              <div className="relative">
                <textarea 
                  readOnly
                  rows={4}
                  value={encryptedJson}
                  className="w-full p-3 rounded-xl bg-neutral-900/50 border border-neutral-850 font-mono text-[10px] text-purple-300/80 resize-none focus:outline-none"
                />
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Decryption Module Panel */}
      <div className="glass-card p-6 rounded-2xl flex flex-col justify-between space-y-4">
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Unlock className="w-5 h-5 text-cyan-400" />
            <h3 className="font-display font-semibold text-white tracking-tight">{t('dec_reconstitution')}</h3>
          </div>
          <p className="text-xs text-neutral-400">
            {t('dec_desc')}
          </p>

          <div className="space-y-3 pt-2">
            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('key_chrono_match')}</label>
              <div className="relative">
                <Key className="absolute left-3 top-2.5 w-4 h-4 text-neutral-500" />
                <input 
                  type="password"
                  placeholder={t('enter_pass_phrase')}
                  value={decryptPassword}
                  onChange={(e) => setDecryptPassword(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-xl bg-neutral-900/60 border border-neutral-800/60 font-sans text-sm text-white focus:outline-none focus:border-cyan-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-[10px] text-neutral-500 font-mono mb-1">{t('container_metadata')}</label>
              <textarea 
                rows={5}
                placeholder={t('paste_json_envelope')}
                value={decryptInput}
                onChange={(e) => setDecryptInput(e.target.value)}
                className="w-full px-4 py-3 rounded-xl bg-neutral-900/60 border border-neutral-800/60 font-mono text-[11px] text-neutral-400 focus:outline-none focus:border-cyan-500 resize-none"
              />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <button 
            onClick={handleTripleLayerDecrypt}
            className="w-full py-3 rounded-xl bg-gradient-to-r from-cyan-600 to-teal-600 hover:from-cyan-500 hover:to-teal-500 text-white text-sm font-sans font-bold tracking-tight shadow-md shadow-cyan-950/20 active:scale-95 transition-all cursor-pointer"
          >
            {t('execute_decipher')}
          </button>

          {decryptedText && (
            <div className="space-y-2 animate-fade-in">
              <div className="flex justify-between items-center text-[10px] font-mono text-neutral-500">
                <span>{t('reconstituted_plain')}</span>
                <button 
                  onClick={() => copyToClipboard(decryptedText, locale === 'ar' ? 'النص الأصلي المسترجع' : 'Original Decrypted Plaintext')}
                  className="flex items-center gap-1 hover:text-white transition focus:outline-none cursor-pointer"
                >
                  <Copy className="w-3.5 h-3.5" />
                  {t('copy_original')}
                </button>
              </div>

              <div className="p-4 rounded-xl bg-neutral-900/40 border border-neutral-800 text-sm text-neutral-200 min-h-[80px] break-all font-sans whitespace-pre-wrap">
                {decryptedText}
              </div>
            </div>
          )}
        </div>
      </div>

    </div>
  );
};
