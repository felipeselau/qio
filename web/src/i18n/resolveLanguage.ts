export const LANGUAGES = ['pt', 'en', 'es'] as const;
export type Language = (typeof LANGUAGES)[number];

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
