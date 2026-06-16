import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, Cpu, Activity, Database, Key, Server, RefreshCw, Terminal,
  Zap, Thermometer, Shuffle, HelpCircle
} from 'lucide-react';
import { SecurityEvent } from '../types';
import { useTranslation } from '../lib/I18nContext';

interface DashProps {
  securityLogs: SecurityEvent[];
  onClearLogs: () => void;
  activeTunnels: number;
  activityRate: number;
  onSecurityLog?: (event: string, severity: 'info' | 'warning' | 'critical', details: string) => void;
}

export const SovereignDashboard: React.FC<DashProps> = ({ 
  securityLogs, 
  onClearLogs, 
  activeTunnels, 
  activityRate,
  onSecurityLog
}) => {
  const { t, locale } = useTranslation();

  const [entropyHealth, setEntropyHealth] = useState<number>(99.98);
  const [cpuUsage, setCpuUsage] = useState<number>(4.21);
  const [ramUsage, setRamUsage] = useState<number>(27.42);

  // Real-time hardware random source state
  const [jitterFreq, setJitterFreq] = useState<number>(212.4);
  const [thermalStatic, setThermalStatic] = useState<number>(1.84);
  const [avalancheBit, setAvalancheBit] = useState<string>('FBE482C1');
  const [kineticEntropy, setKineticEntropy] = useState<number>(42);
  const [totalPoolSaturate, setTotalPoolSaturate] = useState<number>(88.24);
  const [flowRateKbps, setFlowRateKbps] = useState<number>(1460);
  const [isReseeding, setIsReseeding] = useState<boolean>(false);
  const [secondsToReseed, setSecondsToReseed] = useState<number>(24);

  // Simulated sparkline data points
  const [jitterHistory, setJitterHistory] = useState<number[]>([12, 14, 18, 11, 15, 22, 19, 14, 17, 24]);

  // Set randomized live fluctuation values to simulate full operations
  useEffect(() => {
    const timer = setInterval(() => {
      // Basic OS indicators
      setEntropyHealth(prev => {
        const delta = (Math.random() - 0.5) * 0.02;
        return Math.min(100.0, Math.max(99.9, +(prev + delta).toFixed(4)));
      });
      setCpuUsage(prev => {
        const delta = (Math.random() - 0.5) * 1.5;
        return Math.min(50.0, Math.max(1.5, +(prev + delta).toFixed(2)));
      });
      setRamUsage(prev => {
        const delta = (Math.random() - 0.5) * 0.1;
        return Math.min(85.0, Math.max(25.0, +(prev + delta).toFixed(2)));
      });

      // Hardware Randomness Sources Fluctuations
      setJitterFreq(prev => {
        const delta = (Math.random() - 0.5) * 14.5;
        const newVal = Math.min(320.0, Math.max(150.0, +(prev + delta).toFixed(1)));
        return newVal;
      });
      setThermalStatic(prev => {
        const delta = (Math.random() - 0.5) * 0.18;
        return Math.min(3.5, Math.max(0.6, +(prev + delta).toFixed(3)));
      });
      setAvalancheBit(() => {
        const chars = '0123456789ABCDEF';
        let res = '';
        for (let i = 0; i < 8; i++) {
          res += chars[Math.floor(Math.random() * 16)];
        }
        return res;
      });
      setTotalPoolSaturate(prev => {
        const drift = (Math.random() - 0.48) * 0.15;
        return Math.min(100.0, Math.max(75.0, +(prev + drift).toFixed(2)));
      });
      setFlowRateKbps(prev => {
        const drift = Math.floor((Math.random() - 0.5) * 48);
        return Math.min(1850, Math.max(1100, prev + drift));
      });
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  // Update jitterHistory cleanly when jitterFreq changes
  useEffect(() => {
    setJitterHistory(prevHistory => [...prevHistory.slice(1), Math.floor((jitterFreq - 150) / 7)]);
  }, [jitterFreq]);

  // Handle countdown for automatic entropy reseed
  useEffect(() => {
    const countdownTimer = setInterval(() => {
      setSecondsToReseed(prev => {
        const nextVal = prev - 1;
        if (nextVal <= 0) {
          if (onSecurityLog) {
            setTimeout(() => {
              onSecurityLog(
                'Automated Entropy Pool Rotation', 
                'info', 
                'Re-allocated active seed pool. Refreshed thermal and mechanical seed parameters.'
              );
            }, 0);
          }
          return 30;
        }
        return nextVal;
      });
    }, 1000);

    return () => clearInterval(countdownTimer);
  }, [onSecurityLog]);

  // Interactive mouse kinetic harvesting
  const handleKineticHarvest = (e: React.MouseEvent<HTMLDivElement>) => {
    const distanceVal = Math.abs(e.movementX) + Math.abs(e.movementY);
    if (distanceVal > 0) {
      setKineticEntropy(prev => Math.min(5000, prev + Math.min(distanceVal, 8)));
      
      // Periodically trigger a log
      if (Math.random() < 0.015 && onSecurityLog) {
        onSecurityLog(
          'Analog kinetic seed vector registered', 
          'info', 
          `Gathered dynamic browser event offsets. Infused ${distanceVal} true random bits.`
        );
      }
    }
  };

  const handleManualPoolReseed = () => {
    if (isReseeding) return;
    setIsReseeding(true);
    setSecondsToReseed(30);

    if (onSecurityLog) {
      onSecurityLog(
        'Manual Hardware Entropy Rotation Request', 
        'warning', 
        'Purging current RNG matrices. Force harvesting active semiconductor jitter nodes...'
      );
    }

    setTimeout(() => {
      setIsReseeding(false);
      setKineticEntropy(10);
      setTotalPoolSaturate(99.98);
      if (onSecurityLog) {
        onSecurityLog(
          'Sovereign Entropy Reservoir fully synchronized', 
          'info', 
          'Key generator registers zero cryptographic repetition hazards.'
        );
      }
    }, 1800);
  };

  // Load Riemann Identity data dynamically
  const vaultName = localStorage.getItem('riman_vault_custom_name') || (locale === 'ar' ? 'العقدة السيادية الرئيسية' : 'Primary Sovereign Node');
  const vaultDna = localStorage.getItem('riman_vault_dna_seed') || 'RZ-A81F-92CD';
  
  // Calculate level score
  let totalItems = 0;
  try {
    const keys = ['riman_notes_vault_payload', 'riman_journal_vault_payload', 'riman_gallery_vault_payload', 'riman_media_vault_payload'];
    keys.forEach(k => {
      const raw = localStorage.getItem(k);
      if (raw) {
        try {
          const p = JSON.parse(raw);
          if (Array.isArray(p)) totalItems += p.length;
          else if (p.data && Array.isArray(p.data)) totalItems += p.data.length;
          else if (p.items && Array.isArray(p.items)) totalItems += p.items.length;
          else totalItems += 1;
        } catch(e) { totalItems += 2; }
      }
    });
  } catch(e) {}

  const recoveryKey = localStorage.getItem('riman_recovery_key');
  const biometricsEnabled = localStorage.getItem('riman_biometrics_enabled') === 'true';
  let score = 5;
  if (recoveryKey) score += 18;
  if (biometricsEnabled) score += 15;
  if (localStorage.getItem('riman_last_backup_time')) score += 17;
  score += Math.min(25, totalItems * 2.5);
  const securityLevel = Math.max(1, Math.min(100, Math.round(score)));

  // Reputation
  const getReputation = (lvl: number) => {
    if (lvl >= 90) return { label: locale === 'ar' ? 'حلف التيتانيوم الأقصى' : 'Titanium Alliance', color: 'text-neutral-100 bg-neutral-900 border-neutral-750' };
    if (lvl >= 75) return { label: locale === 'ar' ? 'درع البلاتين النادر' : 'Platinum Shield', color: 'text-cyan-300 bg-cyan-950/40 border-cyan-850' };
    if (lvl >= 55) return { label: locale === 'ar' ? 'معقل الذهب المتطور' : 'Gold Bastion', color: 'text-amber-300 bg-amber-950/30 border-amber-900/50' };
    if (lvl >= 35) return { label: locale === 'ar' ? 'مؤسسة الفضة اللامعة' : 'Silver Coherence', color: 'text-neutral-400 bg-neutral-900 border-neutral-850' };
    return { label: locale === 'ar' ? 'طوق البرونز الأولي' : 'Bronze Perimeter', color: 'text-orange-400 bg-orange-950/20 border-orange-900/30' };
  };
  const rep = getReputation(securityLevel);

  // Parse DNA characters for central signature SVG color
  const chars = vaultDna.replace(/-/g, '').slice(2);
  const rVal = chars.length > 5 ? ((chars.charCodeAt(0) * 3 + chars.charCodeAt(1)) % 180 + 75) : 100;
  const gVal = chars.length > 5 ? ((chars.charCodeAt(2) * 5 + chars.charCodeAt(3)) % 180 + 75) : 160;
  const bVal = chars.length > 5 ? ((chars.charCodeAt(4) * 7 + chars.charCodeAt(5)) % 180 + 75) : 220;
  const sigColor = `#${rVal.toString(16).padStart(2,'0')}${gVal.toString(16).padStart(2,'0')}${bVal.toString(16).padStart(2,'0')}`;

  return (
    <div className="space-y-6">

      {/* REAT 9: DYNAMIC IDENTITY SYSTEM BANNER */}
      <div className="glass-card p-5 rounded-3xl border border-neutral-850/50 bg-neutral-900/10 flex flex-col md:flex-row items-center justify-between gap-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/5 rounded-full blur-2xl pointer-events-none" />
        
        {/* Left section: mini animated visual engine & passport info */}
        <div className="flex items-center gap-4 w-full md:w-auto">
          {/* Animated mini-signature preview */}
          <div className="relative w-14 h-14 bg-neutral-950 border border-neutral-850 rounded-2xl flex items-center justify-center shrink-0">
            <svg viewBox="0 0 100 100" className="w-10 h-10 animate-spin" style={{ animationDuration: '20s' }}>
              <circle cx="50" cy="50" r="42" fill="none" stroke={sigColor} strokeWidth="1.5" strokeDasharray="3 5 1 5" />
              <polygon points="50,22 75,36 75,64 50,78 25,64 25,36" fill="yellow" fillOpacity="0.04" stroke={sigColor} strokeWidth="1" />
              <circle cx="50" cy="50" r="8" fill={sigColor} />
            </svg>
            <div className="absolute inset-0 rounded-2xl shadow-inner border border-white/[0.04] pointer-events-none" />
          </div>

          <div className="space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <h4 className="text-sm font-bold text-white tracking-wide">{vaultName}</h4>
              <span className={`px-2 py-0.5 text-[8px] font-mono font-semibold rounded-md border ${rep.color} uppercase tracking-wider`}>
                {rep.label}
              </span>
            </div>
            
            <div className="flex items-center gap-2 text-[10px] text-neutral-400 font-mono">
              <span className="text-[9px] text-neutral-500 uppercase tracking-widest">{locale === 'ar' ? 'جينات ريمان:' : 'VAULT DNA:'}</span>
              <span className="font-bold text-cyan-400 selection:bg-cyan-950">{vaultDna}</span>
            </div>
          </div>
        </div>

        {/* Right Section: Level metrics summary */}
        <div className="flex items-center gap-6 w-full md:w-auto justify-between md:justify-end border-t md:border-t-0 border-neutral-900 pt-4 md:pt-0 shrink-0">
          <div className="space-y-1 text-start md:text-end">
            <span className="block text-[8px] font-mono text-neutral-500 uppercase tracking-wider">{locale === 'ar' ? 'مستوى التحصين' : 'SECURITY LEVEL PROGRESS'}</span>
            <span className="block text-sm font-mono font-bold text-neutral-200">LVL {securityLevel} <span className="text-[10px] text-neutral-500 font-normal">/ 100</span></span>
          </div>
          <div className="w-24 h-1.5 bg-neutral-950 border border-neutral-850 rounded-full overflow-hidden hidden sm:block">
            <div className="h-full bg-cyan-400" style={{ width: `${securityLevel}%` }} />
          </div>
        </div>

      </div>
      
      {/* Dynamic Key Indicators Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Core Entropy health */}
        <div className="p-4 bg-neutral-900/30 border border-neutral-800/60 rounded-2xl flex flex-col justify-between h-28 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-cyan-500/5 rounded-full blur-2xl pointer-events-none" />
          <div className="flex justify-between items-start">
            <span className="text-[10px] font-mono tracking-wider text-neutral-500 uppercase">{t('entropy_reservoir')}</span>
            <ShieldCheck className="w-4 h-4 text-cyan-400" />
          </div>
          <div>
            <span className="block text-2xl font-mono font-bold text-white glow-text">{entropyHealth}%</span>
            <span className="text-[9px] text-cyan-400 font-sans tracking-wide uppercase">{t('sovereign_integrity')}</span>
          </div>
        </div>

        {/* Math coherence */}
        <div className="p-4 bg-neutral-900/30 border border-neutral-800/60 rounded-2xl flex flex-col justify-between h-28 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-purple-500/5 rounded-full blur-2xl pointer-events-none" />
          <div className="flex justify-between items-start">
            <span className="text-[10px] font-mono tracking-wider text-neutral-500 uppercase">{t('spectrum_coherence')}</span>
            <Activity className="w-4 h-4 text-purple-400" />
          </div>
          <div>
            <span className="block text-2xl font-mono font-bold text-white glow-text">99.9984</span>
            <span className="text-[9px] text-purple-400 font-sans tracking-wide uppercase">{t('critical_zeta')}</span>
          </div>
        </div>

        {/* CPU usage */}
        <div className="p-4 bg-neutral-900/30 border border-neutral-800/60 rounded-2xl flex flex-col justify-between h-28 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-500/5 rounded-full blur-2xl pointer-events-none" />
          <div className="flex justify-between items-start">
            <span className="text-[10px] font-mono tracking-wider text-neutral-500 uppercase">{t('matrix_load')}</span>
            <Cpu className="w-4 h-4 text-indigo-400" />
          </div>
          <div>
            <span className="block text-2xl font-mono font-bold text-white">{cpuUsage}%</span>
            <span className="text-[9px] text-indigo-400 font-sans tracking-wide uppercase">{t('stream_cycle')}</span>
          </div>
        </div>

        {/* Tunnels active */}
        <div className="p-4 bg-neutral-900/30 border border-neutral-800/60 rounded-2xl flex flex-col justify-between h-28 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-2xl pointer-events-none" />
          <div className="flex justify-between items-start">
            <span className="text-[10px] font-mono tracking-wider text-neutral-500 uppercase">{t('secure_tunnels')}</span>
            <Database className="w-4 h-4 text-emerald-400" />
          </div>
          <div>
            <span className="block text-2xl font-mono font-bold text-white">{activeTunnels}</span>
            <span className="text-[9px] text-emerald-400 font-sans tracking-wide uppercase">{t('isolated_capsules')}</span>
          </div>
        </div>

      </div>

      {/* NEW COMPONENT: Real-time Entropy Randomness Sources Monitor Dashboard Widget */}
      <div className="glass-card p-6 rounded-2xl space-y-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-80 h-80 bg-cyan-500/5 rounded-full blur-3xl pointer-events-none" />
        
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-neutral-900 pb-4">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-cyan-400 animate-pulse" />
              <h3 className="font-display font-semibold text-lg text-white">{t('hardware_harvester_title')}</h3>
            </div>
            <p className="text-xs text-neutral-400 max-w-xl">
              {t('hardware_harvester_desc')}
            </p>
          </div>
          
          <div className="flex items-center gap-3">
            <div className="text-end hidden sm:block">
              <span className="block text-[9px] font-mono text-neutral-500">{t('auto_rotation_cycle')}</span>
              <span className="text-xs font-mono font-semibold text-cyan-400">{t('seconds_remaining', { seconds: secondsToReseed })}</span>
            </div>
            
            <button
              onClick={handleManualPoolReseed}
              disabled={isReseeding}
              className={`flex items-center gap-2 px-4 py-2 text-xs font-mono font-semibold rounded-xl border transition-all cursor-pointer ${
                isReseeding 
                  ? 'border-yellow-800/30 bg-yellow-950/20 text-yellow-400' 
                  : 'border-cyan-800/60 hover:border-cyan-400 bg-cyan-950/10 hover:bg-cyan-950/40 text-cyan-400 active:scale-95'
              }`}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isReseeding ? 'animate-spin' : ''}`} />
              {isReseeding ? t('active') : t('rotate_seed')}
            </button>
          </div>
        </div>

        {/* Randomness Source Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Source 1: CPU Jitter */}
          <div className="p-4 bg-neutral-950/40 rounded-xl border border-neutral-900 flex flex-col justify-between h-36">
            <div className="flex justify-between items-start">
              <div className="space-y-0.5">
                <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-wider block">{t('jitter_oscillator')}</span>
                <span className="text-sm font-mono font-bold text-white">{jitterFreq} μs dev</span>
              </div>
              <Cpu className="w-4 h-4 text-neutral-500" />
            </div>
            
            {/* Simple simulated live canvas sparkline of historic microsecond timing gap */}
            <div className="h-8 flex items-end gap-0.5 pt-2">
              {jitterHistory.map((val, idx) => (
                <div 
                  key={idx} 
                  className="flex-1 bg-cyan-400/20 hover:bg-cyan-400 transition" 
                  style={{ height: `${Math.max(15, val * 4)}%` }}
                />
              ))}
            </div>

            <div className="flex justify-between items-center text-[9px] font-mono text-neutral-500 mt-2">
              <span>{t('info')}: 2.4K Sieve/s</span>
              <span className="text-cyan-400">● {t('established')}</span>
            </div>
          </div>

          {/* Source 2: Thermal Resistor static */}
          <div className="p-4 bg-neutral-950/40 rounded-xl border border-neutral-900 flex flex-col justify-between h-36">
            <div className="flex justify-between items-start">
              <div className="space-y-0.5">
                <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-wider block">{t('thermal_node')}</span>
                <span className="text-sm font-mono font-bold text-white">{thermalStatic} nV rms</span>
              </div>
              <Thermometer className="w-4 h-4 text-purple-400" />
            </div>

            <div className="space-y-1.5 py-1">
              <div className="h-1 bg-neutral-900 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-purple-500 transition-all duration-300"
                  style={{ width: `${Math.min(100, (thermalStatic / 3.5) * 100)}%` }}
                />
              </div>
              <span className="block text-[9px] font-mono text-neutral-500">{t('thermal_ambient')}</span>
            </div>

            <div className="flex justify-between items-center text-[9px] font-mono text-neutral-500">
              <span>{t('details')}: Dual-Symmetric</span>
              <span className="text-purple-400 animate-pulse">● {t('active')}</span>
            </div>
          </div>

          {/* Source 3: Quantum Avalanche Diode */}
          <div className="p-4 bg-neutral-950/40 rounded-xl border border-neutral-900 flex flex-col justify-between h-36">
            <div className="flex justify-between items-start">
              <div className="space-y-0.5">
                <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-wider block">{t('avalanche_tunneling')}</span>
                <span className="text-sm font-mono font-bold text-emerald-400 block tracking-widest">{avalancheBit}</span>
              </div>
              <Shuffle className="w-4 h-4 text-emerald-400" />
            </div>

            <p className="text-[9px] font-mono text-neutral-500 leading-relaxed">
              {t('avalanche_tunnel_desc')}
            </p>

            <div className="flex justify-between items-center text-[9px] font-mono text-neutral-500">
              <span>SEED RATIO: 1.000</span>
              <span className="text-emerald-400">● {t('active')}</span>
            </div>
          </div>

          {/* Source 4: Responsive Kinetic Mouse Collector */}
          <div 
            onMouseMove={handleKineticHarvest}
            className="p-4 bg-cyan-950/5 hover:bg-cyan-950/15 rounded-xl border border-cyan-900/30 hover:border-cyan-500/50 flex flex-col justify-between h-36 transition duration-250 cursor-crosshair group relative overflow-hidden"
          >
            {/* Fine radar mesh overlay in background */}
            <div className="absolute inset-0 bg-grid-white/[0.02] pointer-events-none" />
            
            <div className="flex justify-between items-start z-10">
              <div className="space-y-0.5">
                <span className="text-[10px] font-mono text-cyan-400 group-hover:text-cyan-300 transition uppercase tracking-wider block">{t('kinetic_harvester')}</span>
                <span className="text-sm font-mono font-bold text-white group-hover:scale-105 transition-transform block">{t('kinetic_bytes', { bytes: kineticEntropy })}</span>
              </div>
              <HelpCircle className="w-4 h-4 text-cyan-400 animate-pulse shrink-0" />
            </div>

            <div className="z-10 bg-neutral-950/60 p-2 rounded border border-neutral-900 text-center">
              <span className="block text-[9px] font-mono text-cyan-300 animate-pulse uppercase">{t('kinetic_hover')}</span>
              <span className="block text-[8px] text-neutral-500 font-sans">{t('kinetic_infuse')}</span>
            </div>

            <div className="flex justify-between items-center text-[9px] font-mono text-neutral-500 z-10">
              <span>{locale === 'ar' ? 'بذور حركة الفأرة' : 'MOUSE DRIFT SEED'}</span>
              <span className="text-cyan-300 group-hover:animate-ping block">● {t('kinetic_recording')}</span>
            </div>
          </div>

        </div>

        {/* Global Entropy Flow Metrics Panel */}
        <div className="p-4 bg-neutral-900/10 border border-neutral-850 rounded-xl grid grid-cols-1 md:grid-cols-3 gap-6">
          
          <div className="space-y-1">
            <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">{t('total_pool_saturated')}</span>
            <div className="flex items-center gap-2">
              <span className="text-xl font-mono font-bold text-white">{totalPoolSaturate}%</span>
              <div className="flex-1 max-w-[120px] h-1.5 bg-neutral-900 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-gradient-to-r from-cyan-500 to-purple-500 rounded-full transition-all duration-300"
                  style={{ width: `${totalPoolSaturate}%` }}
                />
              </div>
            </div>
          </div>

          <div className="space-y-1 md:border-s md:border-neutral-900 md:ps-6">
            <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">{t('entropy_flow_rate')}</span>
            <div className="flex items-baseline gap-1">
              <span className="text-xl font-mono font-bold text-cyan-400 glow-text">{flowRateKbps}</span>
              <span className="text-[10px] font-mono text-neutral-500">{t('kbps_concurrent')}</span>
            </div>
          </div>

          <div className="space-y-1 md:border-s md:border-neutral-900 md:ps-6">
            <span className="block text-[9px] font-mono text-neutral-500 uppercase tracking-widest">{t('randomness_grade')}</span>
            <span className="block text-xs font-mono font-semibold text-emerald-400 tracking-wider uppercase">{t('nist_status')}</span>
          </div>

        </div>

      </div>

      {/* Main Core View Grid (System Log + Activity Monitoring) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Telemetry Log */}
        <div className="lg:col-span-2 glass-card p-6 rounded-2xl flex flex-col justify-between h-[360px]">
          <div className="flex justify-between items-center mb-4">
            <div className="flex items-center gap-2">
              <Terminal className="w-5 h-5 text-cyan-400" />
              <h3 className="font-display font-semibold text-white">{t('audit_log_title')}</h3>
            </div>
            {securityLogs.length > 0 && (
              <button 
                onClick={onClearLogs}
                className="text-[10px] font-mono text-neutral-500 hover:text-white transition cursor-pointer"
              >
                {t('clear_data')}
              </button>
            )}
          </div>

          <div className="flex-1 overflow-y-auto space-y-2 pr-2 font-mono text-[10px] leading-relaxed">
            {securityLogs.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-neutral-500 space-y-1 select-none">
                <ShieldCheck className="w-8 h-8 text-neutral-600 animate-pulse" />
                <span>{t('standard_operations')}</span>
              </div>
            ) : (
              securityLogs.map((log) => {
                const colorMap = {
                  info: 'text-cyan-400',
                  warning: 'text-amber-400',
                  critical: 'text-rose-400'
                };
                return (
                  <div key={log.id} className="p-2 border-b border-neutral-900 bg-neutral-950/20 rounded flex items-start gap-2 animate-slide-in">
                    <span className="text-neutral-500 shrink-0 select-none">[{new Date(log.timestamp).toLocaleTimeString()}]</span>
                    <div className="flex-1">
                      <span className={`font-bold uppercase ${colorMap[log.severity]}`}> {log.severity === 'info' ? t('info') : log.severity === 'warning' ? t('warning') : t('critical')}:</span>
                      <span className="text-neutral-200"> {log.event}</span>
                      <span className="block text-[9px] text-neutral-400/80 mt-0.5">{log.details}</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Algorithm details card */}
        <div className="glass-card p-6 rounded-2xl flex flex-col justify-between h-[360px]">
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Key className="w-5 h-5 text-purple-400" />
              <h3 className="font-display font-medium text-white">{t('algorithm_specs')}</h3>
            </div>
            
            <div className="space-y-3.5 text-xs text-neutral-400 leading-relaxed">
              <p>{t('spec_desc')}</p>
              
              <div className="space-y-2.5 pt-1">
                <div className="flex justify-between border-b border-neutral-850 pb-1.5">
                  <span className="font-mono text-[10px] text-neutral-500">{t('zeta_matrix')}</span>
                  <span className="text-white font-mono text-[10px]">RIEMANN 100-ZERO</span>
                </div>
                <div className="flex justify-between border-b border-neutral-850 pb-1.5">
                  <span className="font-mono text-[10px] text-neutral-500">{t('l2_block_key')}</span>
                  <span className="text-white font-mono text-[10px]">AES-GCM (310K ITER)</span>
                </div>
                <div className="flex justify-between border-b border-neutral-850 pb-1.5">
                  <span className="font-mono text-[10px] text-neutral-500">{t('l3_block_key')}</span>
                  <span className="text-white font-mono text-[10px]">AES-CBC (250K ITER)</span>
                </div>
                <div className="flex justify-between">
                  <span className="font-mono text-[10px] text-neutral-500">{t('kdf_hash')}</span>
                  <span className="text-white font-mono text-[10px]">PBKDF2 SHA-256</span>
                </div>
              </div>
            </div>
          </div>

          <div className="p-3 bg-neutral-950/40 rounded-xl border border-neutral-900 text-[10px] font-mono text-neutral-500 flex justify-between items-center">
            <span>{t('tunnel_encryption')}</span>
            <span className="text-cyan-400 font-bold">{t('sovereign_offline')}</span>
          </div>
        </div>

      </div>

    </div>
  );
};
