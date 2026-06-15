import React from 'react';
import { Shield, Sparkles, Binary, CheckCircle } from 'lucide-react';

interface ToastProps {
  message: string;
  type: 'success' | 'error' | 'info';
  onClose: () => void;
}

export const Toast: React.FC<ToastProps> = ({ message, type, onClose }) => {
  React.useEffect(() => {
    const timer = setTimeout(onClose, 4000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const bgStyles = {
    success: 'bg-emerald-950/90 border-emerald-500 text-emerald-300 shadow-emerald-500/10',
    error: 'bg-rose-950/90 border-rose-500 text-rose-300 shadow-rose-500/10',
    info: 'bg-cyan-950/90 border-cyan-500 text-cyan-300 shadow-cyan-500/10'
  };

  const icons = {
    success: <CheckCircle className="w-5 h-5 text-emerald-400" />,
    error: <Shield className="w-5 h-5 text-rose-400" />,
    info: <Binary className="w-5 h-5 text-cyan-400" />
  };

  return (
    <div className={`fixed bottom-6 right-6 rtl:right-auto rtl:left-6 z-50 flex items-center gap-3 px-5 py-4 rounded-xl border backdrop-blur-md shadow-lg transition-all duration-300 animate-slide-in ${bgStyles[type]}`}>
      {icons[type]}
      <span className="font-sans text-sm font-medium tracking-tight whitespace-pre-wrap">{message}</span>
      <button 
        onClick={onClose} 
        className="ms-3 text-xs opacity-60 hover:opacity-100 transition-opacity focus:outline-none cursor-pointer"
      >
        ✕
      </button>
    </div>
  );
};
