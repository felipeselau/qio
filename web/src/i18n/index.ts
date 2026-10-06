import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import pt from './locales/pt.json';
import en from './locales/en.json';
import es from './locales/es.json';

export const LANGUAGES = ['pt', 'en', 'es'] as const;
export type Language = (typeof LANGUAGES)[number];

export const LANGUAGE_LABELS: Record<Language, string> = {
  pt: 'Português',
  en: 'English',
  es: 'Español',
};

const KEY = 'qio:lang';

export function resolveLanguage(
  stored: string | null,
  navigatorLanguages: readonly string[],
): Language {
  if (stored && (LANGUAGES as readonly string[]).includes(stored)) return stored as Language;
  for (const raw of navigatorLanguages) {
    const base = raw.toLowerCase().split('-')[0];
    if ((LANGUAGES as readonly string[]).includes(base)) return base as Language;
  }
  return 'pt';
}

function storedLanguage(): string | null {
  try {
    return localStorage.getItem(KEY);
  } catch {
    return null;
  }
}

export function setLanguage(lang: Language) {
  try {
    localStorage.setItem(KEY, lang);
  } catch {
    // ignore
  }
  void i18n.changeLanguage(lang);
}

const initial = resolveLanguage(
  storedLanguage(),
  navigator.languages?.length ? navigator.languages : [navigator.language],
);

void i18n.use(initReactI18next).init({
  resources: { pt: { translation: pt }, en: { translation: en }, es: { translation: es } },
  lng: initial,
  fallbackLng: 'pt',
  interpolation: { escapeValue: false },
});

i18n.on('languageChanged', (lng) => {
  document.documentElement.lang = lng === 'pt' ? 'pt-BR' : lng;
});
document.documentElement.lang = initial === 'pt' ? 'pt-BR' : initial;

export default i18n;
