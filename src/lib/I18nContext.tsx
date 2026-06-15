import React, { createContext, useContext, useState, useEffect } from 'react';
import { Locale, TranslationDict, translations } from './translations';

interface I18nContextProps {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: keyof TranslationDict, vars?: Record<string, string | number>) => string;
  dir: 'ltr' | 'rtl';
}

const I18nContext = createContext<I18nContextProps | undefined>(undefined);

export const I18nProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [locale, setLocaleState] = useState<Locale>(() => {
    // 1. Check local storage persistence
    const savedLocale = localStorage.getItem('riman_locale') as Locale | null;
    if (savedLocale === 'en' || savedLocale === 'ar') {
      return savedLocale;
    }

    // 2. Language Detection: Detect device/browser language automatically
    const browserLanguages = navigator.languages || [navigator.language || 'en'];
    const isArabic = browserLanguages.some(lang => lang.toLowerCase().startsWith('ar'));
    
    return isArabic ? 'ar' : 'en';
  });

  const setLocale = (newLocale: Locale) => {
    setLocaleState(newLocale);
    localStorage.setItem('riman_locale', newLocale);
  };

  useEffect(() => {
    // Update HTML document attributes for complete RTL/LTR structural flips
    const dir = locale === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.dir = dir;
    document.documentElement.lang = locale;
  }, [locale]);

  const t = (key: keyof TranslationDict, vars?: Record<string, string | number>): string => {
    const dict = translations[locale] || translations.en;
    let text = dict[key];
    
    if (!text) {
      // Fallback to English key if not found
      text = translations.en[key] || String(key);
    }

    if (vars) {
      Object.entries(vars).forEach(([k, v]) => {
        text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
      });
    }

    return text;
  };

  const dir = locale === 'ar' ? 'rtl' : 'ltr';

  return (
    <I18nContext.Provider value={{ locale, setLocale, t, dir }}>
      {children}
    </I18nContext.Provider>
  );
};

export const useTranslation = () => {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error('useTranslation must be used inside an I18nProvider');
  }
  return context;
};
