import React, { useState, useEffect } from 'react';
import { useTranslation } from '../lib/I18nContext';

interface AnalyzerProps {
  activityLevel: number;
}

export const RiemannSpectrumAnalyzer: React.FC<AnalyzerProps> = ({ activityLevel }) => {
  const { t, locale } = useTranslation();

  const [zeros, setZeros] = useState<{ id: number; re: number; im: number; offset: number }[]>([]);
  const [activeOffset, setActiveOffset] = useState<number>(0);

  // Generate imaginary non-trivial zeta zeros on critical line Re(s) = 1/2
  useEffect(() => {
    const list = [
      { id: 1, re: 0.5, im: 14.134725, offset: 1.2 },
      { id: 2, re: 0.5, im: 21.022040, offset: 2.4 },
      { id: 3, re: 0.5, im: 25.010858, offset: 1.8 },
      { id: 4, re: 0.5, im: 30.424876, offset: 3.1 },
      { id: 5, re: 0.5, im: 32.935062, offset: 0.9 },
      { id: 6, re: 0.5, im: 37.586178, offset: 4.2 },
      { id: 7, re: 0.5, im: 40.918719, offset: 2.1 },
      { id: 8, re: 0.5, im: 43.327073, offset: 1.5 },
      { id: 9, re: 0.5, im: 48.005151, offset: 3.5 },
      { id: 10, re: 0.5, im: 49.773832, offset: 0.6 }
    ];
    setZeros(list);
  }, []);

  // Fluctuating metric offset parameter simulation
  useEffect(() => {
    const timer = setInterval(() => {
      setActiveOffset(+(Math.random() * 0.05).toFixed(6));
    }, 800);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="space-y-6">
      
      <div>
        <span className="text-[10px] uppercase tracking-widest font-mono text-purple-400">{t('zeta_critical_zeros')}</span>
        <h2 className="text-xl font-display font-semibold text-white tracking-tight">{t('math_spectrum_title')}</h2>
        <p className="text-xs text-neutral-400 max-w-2xl mt-1">
          {t('math_spectrum_desc')}
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Riemann Non-Trivial Zero List */}
        <div className="lg:col-span-2 glass-card rounded-2xl overflow-hidden border border-neutral-850">
          <div className="px-6 py-4 border-b border-neutral-900 bg-neutral-900/10 flex justify-between items-center">
            <span className="text-xs font-mono font-semibold text-white">{t('zeta_zeros')}</span>
            <span className="text-[10px] font-mono text-purple-400">{t('zeros_computed', { count: zeros.length })}</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-start text-xs border-collapse">
              <thead>
                <tr className="border-b border-neutral-900 text-neutral-500 font-mono text-[10px] uppercase">
                  <th className="px-6 py-3 text-start font-medium">INDEX</th>
                  <th className="px-6 py-3 text-start font-medium">{t('re_coordinate')}</th>
                  <th className="px-6 py-3 text-start font-medium">{t('im_coordinate')}</th>
                  <th className="px-6 py-3 text-start font-medium">RIEMANN ZERO MATRIX VARIANCE</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-950 font-mono text-neutral-300">
                {zeros.map((z) => (
                  <tr key={z.id} className="hover:bg-neutral-900/20 transition">
                    <td className="px-6 py-3.5 text-neutral-500 font-bold"># {z.id.toString().padStart(2, '0')}</td>
                    <td className="px-6 py-3.5 text-cyan-400">{z.re.toFixed(1)}</td>
                    <td className="px-6 py-3.5 text-purple-400">{z.im.toFixed(6)}</td>
                    <td className="px-6 py-3.5">
                      <div className="flex items-center gap-3">
                        <span className="text-[11px] text-white">{(z.offset + activeOffset).toFixed(6)}</span>
                        <div className="flex-1 max-w-[120px] h-1 bg-neutral-900 rounded-full overflow-hidden">
                          <div 
                            className="h-full bg-gradient-to-r from-cyan-400 to-purple-400 transition-all duration-300"
                            style={{ width: `${Math.min(100, (z.offset + activeOffset) * 18)}%` }}
                          />
                        </div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Coherence Stats card */}
        <div className="glass-card p-6 rounded-2xl flex flex-col justify-between">
          <div className="space-y-4">
            <span className="text-[10px] uppercase tracking-widest font-mono text-neutral-500 block">Zeta Critical Coordinate Specs</span>
            <h3 className="text-lg font-display font-medium text-white tracking-tight">{t('riemann_derivation_title')}</h3>
            
            <p className="text-xs text-neutral-400 leading-relaxed font-sans mt-2">
              {t('zeta_zeros_desc')}
            </p>

            <div className="space-y-3 pt-3">
              <div className="p-3 rounded-xl bg-neutral-950/40 border border-neutral-900">
                <span className="block text-[9px] font-mono text-neutral-500">ZETA COMPLEX PLANE FORMULA</span>
                <span className="text-xs font-mono font-semibold text-purple-400 block mt-1">ζ(s) = ∑ (1 / n^s)</span>
              </div>

              <div className="p-3 rounded-xl bg-neutral-950/40 border border-neutral-900">
                <span className="block text-[9px] font-mono text-neutral-500">CRITICAL METRIC ALIGNMENT</span>
                <span className="text-xs font-mono font-semibold text-cyan-400 block mt-1">Re(s) = 0.50000000000...</span>
              </div>
            </div>
          </div>

          <div className="pt-6">
            <div className="flex justify-between items-center text-[10px] font-mono text-neutral-500 mb-1.5">
              <span>ZETA COMPONENT SYNCHRONIZATION</span>
              <span className="text-purple-400 font-bold">100% SECURE</span>
            </div>
            <div className="h-1.5 w-full bg-neutral-900 rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-cyan-500 to-purple-500 w-full" />
            </div>
          </div>
        </div>

      </div>

    </div>
  );
};
