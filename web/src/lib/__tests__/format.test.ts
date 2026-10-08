import { describe, expect, it } from 'vitest';
import {
  effectiveAvgMin,
  elapsedSince,
  formatElapsed,
  formatPhone,
  isValidPhone,
  waitRange,
} from '../format';

describe('formatPhone', () => {
  it('formats progressively', () => {
    expect(formatPhone('')).toBe('');
    expect(formatPhone('1')).toBe('1');
    expect(formatPhone('119')).toBe('(11) 9');
    expect(formatPhone('1199999')).toBe('(11) 9999-9');
    expect(formatPhone('11999999999')).toBe('(11) 99999-9999');
    expect(formatPhone('1133334444')).toBe('(11) 3333-4444');
  });
  it('strips non-digits and truncates to 11 digits', () => {
    expect(formatPhone('(11) 99999-9999 99')).toBe('(11) 99999-9999');
  });
});

describe('isValidPhone', () => {
  it('accepts both formats', () => {
    expect(isValidPhone('(11) 9999-9999')).toBe(true);
    expect(isValidPhone('(11) 99999-9999')).toBe(true);
  });
  it('rejects malformed', () => {
    expect(isValidPhone('11999999999')).toBe(false);
    expect(isValidPhone('(11) 999-9999')).toBe(false);
    expect(isValidPhone('')).toBe(false);
  });
});

describe('elapsedSince', () => {
  it('floors to whole seconds', () => {
    expect(elapsedSince(1000, 3999)).toBe(2);
  });
  it('never goes negative', () => {
    expect(elapsedSince(5000, 1000)).toBe(0);
  });
});

describe('formatElapsed', () => {
  it('formats m:ss', () => {
    expect(formatElapsed(0)).toBe('0:00');
    expect(formatElapsed(5)).toBe('0:05');
    expect(formatElapsed(65)).toBe('1:05');
    expect(formatElapsed(600)).toBe('10:00');
    expect(formatElapsed(3725)).toBe('62:05');
  });
  it('clamps negatives and floors fractions', () => {
    expect(formatElapsed(-4)).toBe('0:00');
    expect(formatElapsed(59.9)).toBe('0:59');
  });
});

describe('effectiveAvgMin', () => {
  it('prefers auto, then manual, then 10', () => {
    expect(effectiveAvgMin(4.5, 7)).toBe(4.5);
    expect(effectiveAvgMin(null, 7)).toBe(7);
    expect(effectiveAvgMin(undefined, undefined)).toBe(10);
  });
  it('ignores non-positive and non-finite values', () => {
    expect(effectiveAvgMin(0, 7)).toBe(7);
    expect(effectiveAvgMin(-1, 0)).toBe(10);
    expect(effectiveAvgMin(NaN, Infinity)).toBe(10);
  });
});

describe('waitRange', () => {
  it('computes a 0.7x to 1.4x range', () => {
    expect(waitRange(2, 10)).toEqual({ min: 14, max: 28 });
  });
  it('keeps min at least 1 and max above min', () => {
    expect(waitRange(1, 1)).toEqual({ min: 1, max: 2 });
  });
  it('returns null for invalid input', () => {
    expect(waitRange(0, 10)).toBeNull();
    expect(waitRange(1, 0)).toBeNull();
    expect(waitRange(NaN, 10)).toBeNull();
    expect(waitRange(1, Infinity)).toBeNull();
  });
});
