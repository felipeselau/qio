import { describe, expect, it } from 'vitest';
import {
  isQueueFull,
  positionInQueue,
  safeBrandColor,
  safeLogoUrl,
  type PublicTicket,
} from '../queueLogic';

const t = (ticket: number, status = 'waiting', order?: number): PublicTicket => ({
  ticket,
  status,
  ...(order === undefined ? {} : { order }),
});

describe('positionInQueue', () => {
  it('is 1 when nobody is ahead', () => {
    expect(positionInQueue({}, { ticket: 5, joinedAt: 100 })).toBe(1);
  });

  it('counts waiting tickets with smaller ticket when order is missing', () => {
    const pub = { a: t(1), b: t(2), c: t(4) };
    expect(positionInQueue(pub, { ticket: 3, joinedAt: 100 })).toBe(3);
  });

  it('ignores called entries and itself', () => {
    const pub = { a: t(1, 'called'), b: t(3), c: t(4) };
    expect(positionInQueue(pub, { ticket: 3, joinedAt: 100 })).toBe(1);
  });

  it('uses order over ticket when present', () => {
    const pub = { a: t(1, 'waiting', 500), b: t(5, 'waiting', 50) };
    expect(positionInQueue(pub, { ticket: 3, order: 100, joinedAt: 10 })).toBe(2);
  });

  it('falls back to joinedAt when mine has no order', () => {
    const pub = { a: t(9, 'waiting', 40), b: t(8, 'waiting', 200) };
    expect(positionInQueue(pub, { ticket: 3, order: null, joinedAt: 100 })).toBe(2);
  });

  it('breaks order ties by ticket', () => {
    const pub = { a: t(2, 'waiting', 100), b: t(4, 'waiting', 100) };
    expect(positionInQueue(pub, { ticket: 3, order: 100, joinedAt: 1 })).toBe(2);
  });

  it('compares by ticket for entries without order even if mine has order', () => {
    const pub = { a: t(1), b: t(7) };
    expect(positionInQueue(pub, { ticket: 3, order: 100, joinedAt: 1 })).toBe(2);
  });
});

describe('isQueueFull', () => {
  it('never full when maxWaiting is 0', () => {
    expect(isQueueFull(0, 999)).toBe(false);
  });
  it('full at and above the limit', () => {
    expect(isQueueFull(3, 2)).toBe(false);
    expect(isQueueFull(3, 3)).toBe(true);
    expect(isQueueFull(3, 4)).toBe(true);
  });
});

describe('safeBrandColor', () => {
  it('accepts palette colors case-insensitively and normalizes to upper', () => {
    expect(safeBrandColor('#2563eb')).toBe('#2563EB');
    expect(safeBrandColor('#334155')).toBe('#334155');
  });
  it('rejects other values', () => {
    expect(safeBrandColor('#123456')).toBeNull();
    expect(safeBrandColor('red')).toBeNull();
    expect(safeBrandColor(null)).toBeNull();
    expect(safeBrandColor(123)).toBeNull();
    expect(safeBrandColor(undefined)).toBeNull();
  });
});

describe('safeLogoUrl', () => {
  const ok = 'https://firebasestorage.googleapis.com/v0/b/x/o/logo.jpg';
  it('accepts firebase storage https urls', () => {
    expect(safeLogoUrl(ok)).toBe(ok);
  });
  it('rejects other hosts, schemes and non-strings', () => {
    expect(safeLogoUrl('http://firebasestorage.googleapis.com/x')).toBeNull();
    expect(safeLogoUrl('https://evil.com/https://firebasestorage.googleapis.com/')).toBeNull();
    expect(safeLogoUrl('javascript:alert(1)')).toBeNull();
    expect(safeLogoUrl(42)).toBeNull();
    expect(safeLogoUrl(null)).toBeNull();
  });
  it('rejects urls longer than 600 chars', () => {
    expect(safeLogoUrl(ok + 'a'.repeat(600))).toBeNull();
  });
});
