const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  SLOT_GRACE_MS,
  normalizeMode,
  normalizeCapacity,
  parseSlots,
  slotStartMs,
  isSlotBookable,
  countSlotEntries,
  isSlotFull,
} = require('../src/slots');

const NOON_SP = Date.UTC(2026, 9, 7, 15, 0, 0);

describe('normalizeMode', () => {
  it('só schedule vira schedule', () => {
    assert.equal(normalizeMode('schedule'), 'schedule');
    for (const v of ['queue', undefined, null, 'x', 1]) {
      assert.equal(normalizeMode(v), 'queue');
    }
  });
});

describe('normalizeCapacity', () => {
  it('aceita inteiros de 1 a 50', () => {
    assert.equal(normalizeCapacity(1), 1);
    assert.equal(normalizeCapacity(50), 50);
    for (const v of [0, 51, 2.5, '3', null, undefined, NaN]) {
      assert.equal(normalizeCapacity(v), null);
    }
  });
});

describe('parseSlots', () => {
  it('ordena por horário e descarta inválidos', () => {
    const slots = parseSlots({
      b: { start: '10:30', capacity: 2 },
      a: { start: '09:00', capacity: 1 },
      bad1: { start: '24:00', capacity: 1 },
      bad2: { start: '9:00', capacity: 1 },
      bad3: { start: '11:00', capacity: 0 },
      bad4: null,
    });
    assert.deepEqual(slots, [
      { id: 'a', start: '09:00', capacity: 1 },
      { id: 'b', start: '10:30', capacity: 2 },
    ]);
  });

  it('retorna vazio sem dados', () => {
    assert.deepEqual(parseSlots(null), []);
    assert.deepEqual(parseSlots(undefined), []);
  });
});

describe('slotStartMs', () => {
  it('calcula o horário de hoje em America/Sao_Paulo', () => {
    assert.equal(slotStartMs(NOON_SP, '12:00'), NOON_SP);
    assert.equal(slotStartMs(NOON_SP, '09:30'), NOON_SP - 150 * 60 * 1000);
  });

  it('usa o dia de São Paulo perto da meia-noite UTC', () => {
    const lateSp = Date.UTC(2026, 9, 8, 1, 0, 0);
    assert.equal(slotStartMs(lateSp, '22:00'), Date.UTC(2026, 9, 8, 1, 0, 0));
  });

  it('formato inválido retorna null', () => {
    assert.equal(slotStartMs(NOON_SP, '25:00'), null);
    assert.equal(slotStartMs(NOON_SP, 'x'), null);
  });
});

describe('isSlotBookable', () => {
  it('aceita futuro e tolerância após o início', () => {
    const start = NOON_SP;
    assert.equal(isSlotBookable(start - 1000, start), true);
    assert.equal(isSlotBookable(start + SLOT_GRACE_MS, start), true);
    assert.equal(isSlotBookable(start + SLOT_GRACE_MS + 1, start), false);
    assert.equal(isSlotBookable(start, null), false);
  });
});

describe('countSlotEntries / isSlotFull', () => {
  const entries = {
    e1: { status: 'waiting', slotId: 's1', slotStart: 100 },
    e2: { status: 'called', slotId: 's1', slotStart: 100 },
    e3: { status: 'served', slotId: 's1', slotStart: 100 },
    e4: { status: 'waiting', slotId: 's2', slotStart: 100 },
    e5: { status: 'waiting', slotId: 's1', slotStart: 50 },
    e6: null,
  };

  it('conta só ativas do mesmo slot e dia', () => {
    assert.equal(countSlotEntries(entries, 's1', 100), 2);
    assert.equal(countSlotEntries(null, 's1', 100), 0);
  });

  it('lota quando alcança a capacidade', () => {
    assert.equal(isSlotFull(3, 2), false);
    assert.equal(isSlotFull(3, 3), true);
    assert.equal(isSlotFull(undefined, 0), true);
  });
});
