import { describe, expect, it } from 'vitest';
import { resolveLanguage } from '../resolveLanguage';

describe('resolveLanguage', () => {
  it('prefers a valid stored language', () => {
    expect(resolveLanguage('es', ['en-US'])).toBe('es');
    expect(resolveLanguage('pt', ['en'])).toBe('pt');
  });
  it('ignores an unsupported stored language', () => {
    expect(resolveLanguage('fr', ['en-US'])).toBe('en');
  });
  it('uses the first supported navigator language, base only, case-insensitive', () => {
    expect(resolveLanguage(null, ['fr-FR', 'ES-mx', 'en'])).toBe('es');
    expect(resolveLanguage(null, ['pt-BR'])).toBe('pt');
    expect(resolveLanguage(null, ['en-GB'])).toBe('en');
  });
  it('falls back to pt', () => {
    expect(resolveLanguage(null, [])).toBe('pt');
    expect(resolveLanguage(null, ['de', 'ja'])).toBe('pt');
    expect(resolveLanguage('', ['zh'])).toBe('pt');
  });
});
