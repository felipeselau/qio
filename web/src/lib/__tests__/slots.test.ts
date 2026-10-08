import { describe, expect, it } from 'vitest';
import {
  MAX_SLOTS,
  SLOT_GRACE_MS,
  formatSlotTime,
  isSlotFull,
  isSlotPast,
  parseSlots,
  slotStartMs,
  slotTaken,
} from '../slots';

const sp = (iso: string) => Date.parse(`${iso}-03:00`);

describe('parseSlots', () => {
  it('returns [] for non-objects', () => {
    expect(parseSlots(null)).toEqual([]);
    expect(parseSlots('x')).toEqual([]);
    expect(parseSlots(undefined)).toEqual([]);
  });

  it('sorts by start time', () => {
    const out = parseSlots({
      b: { start: '14:00', capacity: 2 },
      a: { start: '09:30', capacity: 1 },
      c: { start: '09:00', capacity: 5 },
    });
    expect(out.map((s) => s.id)).toEqual(['c', 'a', 'b']);
  });

  it('drops invalid start and capacity', () => {
    const out = parseSlots({
      a: { start: '24:00', capacity: 1 },
      b: { start: '9:00', capacity: 1 },
      c: { start: '10:00', capacity: 0 },
      d: { start: '10:00', capacity: 51 },
      e: { start: '10:00', capacity: 1.5 },
      f: { start: '10:00', capacity: '2' },
      g: null,
      ok: { start: '23:59', capacity: 50 },
    });
    expect(out).toEqual([{ id: 'ok', start: '23:59', capacity: 50 }]);
  });

  it('caps at MAX_SLOTS', () => {
    const raw: Record<string, unknown> = {};
    for (let i = 0; i < 30; i++) {
      const h = String(i % 24).padStart(2, '0');
      raw[`s${i}`] = { start: `${h}:${i < 24 ? '00' : '30'}`, capacity: 1 };
    }
    expect(parseSlots(raw)).toHaveLength(MAX_SLOTS);
  });
});

describe('slotStartMs', () => {
  it('resolves the start on the Sao Paulo day of now', () => {
    expect(slotStartMs('09:30', sp('2026-03-10T15:00:00'))).toBe(sp('2026-03-10T09:30:00'));
  });

  it('stays on the same Sao Paulo day just before local midnight', () => {
    expect(slotStartMs('08:00', sp('2026-03-10T23:59:00'))).toBe(sp('2026-03-10T08:00:00'));
  });

  it('rolls to the next Sao Paulo day right after local midnight', () => {
    expect(slotStartMs('08:00', sp('2026-03-11T00:01:00'))).toBe(sp('2026-03-11T08:00:00'));
  });

  it('uses the Sao Paulo day even when the UTC date differs', () => {
    const now = Date.parse('2026-03-11T02:30:00Z');
    expect(slotStartMs('20:00', now)).toBe(sp('2026-03-10T20:00:00'));
  });

  it('treats invalid time as 00:00', () => {
    expect(slotStartMs('nope', sp('2026-03-10T15:00:00'))).toBe(sp('2026-03-10T00:00:00'));
  });
});

describe('isSlotPast', () => {
  const now = sp('2026-03-10T10:00:00');
  it('is not past before start or within grace', () => {
    expect(isSlotPast('10:30', now)).toBe(false);
    expect(isSlotPast('10:00', now)).toBe(false);
    expect(isSlotPast('09:45', now)).toBe(false);
  });
  it('is past after the grace window', () => {
    expect(isSlotPast('09:44', now)).toBe(true);
    expect(SLOT_GRACE_MS).toBe(15 * 60 * 1000);
  });
  it('resets after midnight', () => {
    expect(isSlotPast('23:00', sp('2026-03-11T00:05:00'))).toBe(false);
  });
});

describe('slotTaken and isSlotFull', () => {
  const slot = { id: 's1', start: '10:00', capacity: 2 };
  const pub = {
    a: { status: 'waiting', slotId: 's1' },
    b: { status: 'called', slotId: 's1' },
    c: { status: 'served', slotId: 's1' },
    d: { status: 'waiting', slotId: 's2' },
    e: { status: 'waiting' },
  };
  it('counts only waiting/called entries of the slot', () => {
    expect(slotTaken(pub, slot)).toBe(2);
  });
  it('flags full at capacity', () => {
    expect(isSlotFull(1, slot)).toBe(false);
    expect(isSlotFull(2, slot)).toBe(true);
    expect(isSlotFull(3, slot)).toBe(true);
  });
});

describe('formatSlotTime', () => {
  it('renders in Sao Paulo time regardless of host zone', () => {
    expect(formatSlotTime(Date.parse('2026-03-10T12:30:00Z'), 'pt-BR')).toBe('09:30');
  });
  it('renders just after midnight', () => {
    expect(formatSlotTime(sp('2026-03-10T00:05:00'), 'en')).toMatch(/^(24|00):05$/);
  });
});
