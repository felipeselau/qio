import { describe, expect, it } from 'vitest';
import { contactHref, privacyContact } from '../privacy';

describe('privacyContact', () => {
  it('returns null when missing or blank', () => {
    expect(privacyContact(undefined)).toBeNull();
    expect(privacyContact('')).toBeNull();
    expect(privacyContact('   ')).toBeNull();
  });

  it('trims the configured value', () => {
    expect(privacyContact('  dono@loja.com ')).toBe('dono@loja.com');
  });
});

describe('contactHref', () => {
  it('returns null without contact', () => {
    expect(contactHref(null)).toBeNull();
  });

  it('builds mailto for emails', () => {
    expect(contactHref('dono@loja.com')).toBe('mailto:dono@loja.com');
  });

  it('accepts https urls only', () => {
    expect(contactHref('https://loja.com/contato')).toBe('https://loja.com/contato');
    expect(contactHref('http://loja.com')).toBeNull();
    expect(contactHref('javascript:alert(1)')).toBeNull();
  });

  it('returns null for free text', () => {
    expect(contactHref('balcão da loja')).toBeNull();
  });
});
