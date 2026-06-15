import React, { useEffect, useRef } from 'react';
import { RIEMANN_ZEROS } from '../lib/crypto';

interface RiemannCanvasProps {
  activityLevel: number; // 0 to 100
  isEncrypting: boolean;
  isDecrypting: boolean;
}

export const RiemannSpectrumCanvas: React.FC<RiemannCanvasProps> = ({ 
  activityLevel, 
  isEncrypting, 
  isDecrypting 
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationFrameId: number;
    let width = canvas.width = canvas.parentElement?.clientWidth || 600;
    let height = canvas.height = canvas.parentElement?.clientHeight || 200;

    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        width = canvas.width = entry.contentRect.width;
        height = canvas.height = entry.contentRect.height || 200;
      }
    });

    if (canvas.parentElement) {
      resizeObserver.observe(canvas.parentElement);
    }

    let time = 0;
    const particles: Array<{ x: number; y: number; speed: number; size: number; alpha: number; zetaIdx: number }> = [];

    // Initialize quantum wave particles matching Riemann Zero wave seeds
    for (let i = 0; i < 40; i++) {
      particles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        speed: (0.2 + Math.random() * 0.8),
        size: 1 + Math.random() * 2,
        alpha: 0.1 + Math.random() * 0.4,
        zetaIdx: i % RIEMANN_ZEROS.length
      });
    }

    const render = () => {
      ctx.clearRect(0, 0, width, height);
      time += 0.015 + (activityLevel / 2000);

      // 1. Draw Critical Line (Re(s) = 1/2) in complex plane space
      const criticalLineX = width * 0.45;
      
      // Outer glow for critical line
      ctx.beginPath();
      ctx.strokeStyle = 'rgba(6, 182, 212, 0.1)';
      ctx.lineWidth = 14;
      ctx.moveTo(criticalLineX, 0);
      ctx.lineTo(criticalLineX, height);
      ctx.stroke();

      ctx.beginPath();
      ctx.strokeStyle = 'rgba(6, 182, 212, 0.4)';
      ctx.lineWidth = 1;
      ctx.setLineDash([5, 5]);
      ctx.moveTo(criticalLineX, 0);
      ctx.lineTo(criticalLineX, height);
      ctx.stroke();
      ctx.setLineDash([]);

      // Label critical line
      ctx.fillStyle = 'rgba(6, 182, 212, 0.3)';
      ctx.font = '9px monospace';
      ctx.fillText('Critical Line s = 1/2 + iγ', criticalLineX + 8, 15);

      // 2. Compute and render Dirichlet Wave Harmonics
      ctx.lineWidth = 1.5;
      const waveCount = isEncrypting || isDecrypting ? 8 : 4;
      
      for (let w = 0; w < waveCount; w++) {
        // Zero phase derive from genuine Riemann Zero values
        const zeroValue = RIEMANN_ZEROS[w % RIEMANN_ZEROS.length];
        
        ctx.beginPath();
        const colorRatio = w / waveCount;
        
        if (isEncrypting) {
          // Intense energetic stream for encryption transformation
          ctx.strokeStyle = `rgba(168, 85, 247, ${0.15 + (1 - colorRatio) * 0.35})`; // Quantum Purple neon
        } else if (isDecrypting) {
          // Reconstitution cyan streams
          ctx.strokeStyle = `rgba(6, 182, 212, ${0.15 + (1 - colorRatio) * 0.35})`; // Electric Blue / Neon Cyan
        } else {
          // Steady-state mathematical ocean waves
          ctx.strokeStyle = `rgba(99, 102, 241, ${0.1 + (1 - colorRatio) * 0.15})`; // Deep Slate Indigo
        }

        for (let x = 0; x < width; x++) {
          // Harmonic wave mechanics reflecting Riemann Zeta zeroes and primes logs
          const waveFreq = (zeroValue / 500) * (w + 1);
          const damping = Math.sin((x / width) * Math.PI); // Pin ocean wave at boundaries
          const sineCalc = Math.sin(x * waveFreq - time * (w + 1.2) + zeroValue);
          const cosineCalc = Math.cos(x * (waveFreq * 0.77) + time * 0.5);
          
          let y = (height / 2) + (sineCalc * 35 + cosineCalc * 15) * damping;
          
          if (isEncrypting || isDecrypting) {
            // Distort wave field dynamic vectors
            const pulse = Math.sin(time * 5 + x * 0.05);
            y += pulse * 12;
          }

          if (x === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }
        ctx.stroke();
      }

      // 3. Render Mathematical Zeta Zero Coordinates
      particles.forEach((p, idx) => {
        const gamma = RIEMANN_ZEROS[p.zetaIdx];
        
        // Complex oscillations math projection
        p.x += p.speed * (1 + activityLevel / 15);
        if (p.x > width) {
          p.x = 0;
          p.y = Math.random() * height;
        }

        // Oscillate height based on Riemann math formulation
        const orbitalY = (height / 2) + Math.sin(time + gamma) * (height * 0.25);
        p.y = p.y * 0.95 + orbitalY * 0.05;

        ctx.beginPath();
        if (isEncrypting) {
          ctx.fillStyle = `rgba(236, 72, 153, ${p.alpha * 1.5})`; // Neon Pink energy spikes
        } else if (isDecrypting) {
          ctx.fillStyle = `rgba(64, 224, 208, ${p.alpha * 1.5})`; // Turquoise quantum flare
        } else {
          ctx.fillStyle = `rgba(0, 191, 255, ${p.alpha})`; // Deep blue / cyans
        }
        
        ctx.arc(p.x, p.y, p.size * (isEncrypting || isDecrypting ? 1.8 : 1), 0, Math.PI * 2);
        ctx.fill();

        // Connect nearby points with delicate neural grid strands
        particles.forEach((p2, idx2) => {
          if (idx !== idx2 && idx < idx2 + 3) {
            const dx = p.x - p2.x;
            const dy = p.y - p2.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 60) {
              ctx.beginPath();
              ctx.strokeStyle = `rgba(6, 182, 212, ${0.05 * (1 - dist / 60)})`;
              ctx.lineWidth = 0.5;
              ctx.moveTo(p.x, p.y);
              ctx.lineTo(p2.x, p2.y);
              ctx.stroke();
            }
          }
        });
      });

      // 4. Overlap digital scanlines and binary streams during high activity
      if (isEncrypting || isDecrypting) {
        ctx.fillStyle = `rgba(6, 182, 212, ${0.03 + Math.random() * 0.03})`;
        for (let i = 0; i < height; i += 4) {
          ctx.fillRect(0, i, width, 1);
        }
      }

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animationFrameId);
      resizeObserver.disconnect();
    };
  }, [activityLevel, isEncrypting, isDecrypting]);

  return (
    <div className="relative w-full h-full min-h-[180px] bg-neutral-950/60 rounded-xl border border-neutral-800/50 overflow-hidden backdrop-blur-md shadow-inner">
      {/* Precision coordinate grid indicator overlay */}
      <div className="absolute top-2 left-3 font-mono text-[9px] text-neutral-500 flex gap-4 pointer-events-none select-none z-10 uppercase">
        <span>FIELD SPEC: RC-310</span>
        <span>Re(s) = 0.5</span>
        <span className="text-cyan-400 font-bold animate-pulse">
          {isEncrypting ? '● ENCRYPTING LAYER 1-2-3' : isDecrypting ? '● DECRYPTING STATE' : '● IDLE SPECTRUM'}
        </span>
      </div>
      <canvas ref={canvasRef} className="absolute inset-0 w-full h-full" />
    </div>
  );
};
