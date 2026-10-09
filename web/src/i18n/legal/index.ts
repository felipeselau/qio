import type { Language } from '../resolveLanguage';
import type { LegalBundle } from './types';

export type { LegalBundle, LegalDoc, LegalSection } from './types';

export async function loadLegal(lang: Language): Promise<LegalBundle> {
  switch (lang) {
    case 'en':
      return (await import('./en')).default;
    case 'es':
      return (await import('./es')).default;
    default:
      return (await import('./pt')).default;
  }
}
