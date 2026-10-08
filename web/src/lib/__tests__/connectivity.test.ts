import { describe, expect, it } from 'vitest';
import { isEffectivelyOnline } from '../connectivity';

describe('isEffectivelyOnline', () => {
  it('is offline whenever the browser is offline', () => {
    expect(isEffectivelyOnline(false, true, true)).toBe(false);
    expect(isEffectivelyOnline(false, null, false)).toBe(false);
  });
  it('is offline when rtdb dropped after having connected', () => {
    expect(isEffectivelyOnline(true, false, true)).toBe(false);
  });
  it('ignores rtdb disconnected before first connection', () => {
    expect(isEffectivelyOnline(true, false, false)).toBe(true);
  });
  it('is online when rtdb is connected or unknown', () => {
    expect(isEffectivelyOnline(true, true, true)).toBe(true);
    expect(isEffectivelyOnline(true, null, false)).toBe(true);
  });
});
