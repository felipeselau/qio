import { describe, expect, it } from 'vitest';
import {
  RESERVED_SLUGS,
  isValidSlug,
  normalizeSlug,
  parseSlug,
  queuePathFor,
  slugErrorKind,
} from '../slug';

const VALID = ['abc', 'cafe-do-ze', 'a1b', 'loja-2', 'a'.repeat(40), '123', 'a--b'];
const INVALID = [
  '',
  'ab',
  'a'.repeat(41),
  '-abc',
  'abc-',
  'ab_c',
  'café',
  'a b c',
  'abc/def',
  'ABC',
  'abc.def',
  'abc\n',
];
const RESERVED = [
  'admin',
  'api',
  'app',
  'q',
  'c',
  'w',
  'n',
  'privacidade',
  'termos',
  'assets',
  'fonts',
  'icons',
];

describe('isValidSlug', () => {
  it.each(VALID)('accepts %s', (slug) => {
    expect(isValidSlug(slug)).toBe(true);
  });

  it.each(INVALID)('rejects %j', (slug) => {
    expect(isValidSlug(slug)).toBe(false);
  });

  it.each(RESERVED)('rejects reserved %s', (slug) => {
    expect(isValidSlug(slug)).toBe(false);
  });

  it('rejects non strings', () => {
    expect(isValidSlug(null)).toBe(false);
    expect(isValidSlug(undefined)).toBe(false);
    expect(isValidSlug(42)).toBe(false);
  });

  it('keeps the reserved list in sync', () => {
    expect([...RESERVED_SLUGS].sort()).toEqual([...RESERVED].sort());
  });
});

describe('normalizeSlug and parseSlug', () => {
  it('trims and lowercases', () => {
    expect(normalizeSlug('  Cafe-Do-Ze ')).toBe('cafe-do-ze');
    expect(parseSlug('  Cafe-Do-Ze ')).toBe('cafe-do-ze');
  });

  it('returns null when invalid', () => {
    expect(parseSlug('-x-')).toBeNull();
    expect(parseSlug(undefined)).toBeNull();
    expect(parseSlug('admin')).toBeNull();
  });
});

describe('queuePathFor', () => {
  it('keeps the legacy /q/ route', () => {
    expect(queuePathFor('abc123')).toBe('/q/abc123');
  });
});

describe('slugErrorKind', () => {
  it('maps not-found to the missing queue page', () => {
    expect(slugErrorKind({ code: 'functions/not-found' })).toBe('notFound');
  });

  it('treats other failures as retryable', () => {
    expect(slugErrorKind({ code: 'functions/unavailable' })).toBe('retry');
    expect(slugErrorKind({ code: 'functions/resource-exhausted' })).toBe('retry');
    expect(slugErrorKind(null)).toBe('retry');
  });
});
