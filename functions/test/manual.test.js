const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { parseManualInput, isQueueStaff, buildManualEntry } = require('../src/manual');

describe('parseManualInput', () => {
  it('aceita nome e telefone vazio', () => {
    assert.deepEqual(parseManualInput({ queueId: 'q1', name: ' Ana ' }), {
      queueId: 'q1',
      name: 'Ana',
      phone: '',
      slotId: undefined,
    });
  });

  it('aceita telefone com máscara e slotId', () => {
    const r = parseManualInput({ queueId: 'q1', name: 'Ana', phone: '(11) 91234-5678', slotId: 's1' });
    assert.equal(r.phone, '(11) 91234-5678');
    assert.equal(r.slotId, 's1');
  });

  it('rejeita fila inválida', () => {
    assert.equal(parseManualInput({ name: 'Ana' }).error, 'invalid-queue');
    assert.equal(parseManualInput({ queueId: 'a/b', name: 'Ana' }).error, 'invalid-queue');
    assert.equal(parseManualInput(null).error, 'invalid-queue');
  });

  it('rejeita nome vazio ou longo', () => {
    assert.equal(parseManualInput({ queueId: 'q1', name: '  ' }).error, 'invalid-name');
    assert.equal(parseManualInput({ queueId: 'q1', name: 'x'.repeat(61) }).error, 'invalid-name');
  });

  it('rejeita telefone fora da máscara', () => {
    assert.equal(parseManualInput({ queueId: 'q1', name: 'Ana', phone: '123' }).error, 'invalid-phone');
    assert.equal(parseManualInput({ queueId: 'q1', name: 'Ana', phone: 5 }).error, 'invalid-phone');
  });
});

describe('isQueueStaff', () => {
  it('dono e operador aprovado passam', () => {
    assert.equal(isQueueStaff('o', 'o', {}), true);
    assert.equal(isQueueStaff('p', 'o', { p: true }), true);
  });

  it('estranho, operador falso e uid vazio não passam', () => {
    assert.equal(isQueueStaff('x', 'o', { p: true }), false);
    assert.equal(isQueueStaff('p', 'o', { p: false }), false);
    assert.equal(isQueueStaff('', '', null), false);
    assert.equal(isQueueStaff(undefined, undefined, undefined), false);
  });
});

describe('buildManualEntry', () => {
  it('marca manual, sem uid nem fcmToken', () => {
    const e = buildManualEntry({ ticket: 3, name: 'Ana', phone: '', now: 10 });
    assert.deepEqual(e, { ticket: 3, name: 'Ana', phone: '', manual: true, status: 'waiting', joinedAt: 10 });
    assert.equal('uid' in e, false);
    assert.equal('fcmToken' in e, false);
  });

  it('inclui campos de slot', () => {
    const e = buildManualEntry({
      ticket: 1,
      name: 'A',
      phone: '',
      now: 5,
      slotFields: { slotId: 's', slotStart: 9, order: 9 },
    });
    assert.equal(e.slotId, 's');
    assert.equal(e.order, 9);
  });
});

const {
  MANUAL_RATE_LIMIT,
  MAX_ACTIVE_ENTRIES,
  manualRateKey,
  nextManualRateState,
  isActiveCeilingReached,
  resolveActiveCeiling,
} = require('../src/manual');
const { publicTicketFor, shouldRenotify } = require('../src/ticket');
const { pickNextWaiting, advancedFromWaiting } = require('../src/webpush');

describe('rate limit manual', () => {
  it('chave própria por uid', () => {
    assert.equal(manualRateKey('abc'), 'manual-abc');
  });

  it('bloqueia a 31a chamada na janela', () => {
    let stamps = [];
    for (let i = 0; i < MANUAL_RATE_LIMIT.max; i += 1) {
      const s = nextManualRateState(stamps, 1000 + i);
      assert.equal(s.limited, false);
      stamps = s.timestamps;
    }
    const blocked = nextManualRateState(stamps, 2000);
    assert.equal(blocked.limited, true);
    assert.equal(blocked.timestamps.length, MANUAL_RATE_LIMIT.max);
  });

  it('libera depois da janela', () => {
    const stamps = Array.from({ length: 30 }, (_, i) => 1000 + i);
    const s = nextManualRateState(stamps, 1000 + MANUAL_RATE_LIMIT.windowMs + 100);
    assert.equal(s.limited, false);
  });
});

describe('teto de entries ativas', () => {
  it('só vale sem maxWaiting', () => {
    assert.equal(isActiveCeilingReached(0, MAX_ACTIVE_ENTRIES), true);
    assert.equal(isActiveCeilingReached(undefined, MAX_ACTIVE_ENTRIES - 1), false);
    assert.equal(isActiveCeilingReached(50, 5000), false);
  });

  it('override só vale no emulator e só para baixo', () => {
    const emu = { FUNCTIONS_EMULATOR: 'true' };
    assert.equal(resolveActiveCeiling({}), MAX_ACTIVE_ENTRIES);
    assert.equal(resolveActiveCeiling({ MANUAL_MAX_ACTIVE_ENTRIES: '40' }), MAX_ACTIVE_ENTRIES);
    assert.equal(resolveActiveCeiling({ ...emu, MANUAL_MAX_ACTIVE_ENTRIES: '40' }), 40);
    assert.equal(resolveActiveCeiling({ ...emu, MANUAL_MAX_ACTIVE_ENTRIES: '5000' }), MAX_ACTIVE_ENTRIES);
    assert.equal(resolveActiveCeiling({ ...emu, MANUAL_MAX_ACTIVE_ENTRIES: '0' }), MAX_ACTIVE_ENTRIES);
    assert.equal(resolveActiveCeiling({ ...emu, MANUAL_MAX_ACTIVE_ENTRIES: 'x' }), MAX_ACTIVE_ENTRIES);
    assert.equal(resolveActiveCeiling(emu), MAX_ACTIVE_ENTRIES);
  });
});

describe('entry manual nas funções puras', () => {
  const manual = { ticket: 4, name: 'Ana', phone: '', manual: true, status: 'waiting', joinedAt: 10 };

  it('publicTicketFor não depende de uid', () => {
    assert.deepEqual(publicTicketFor(manual), { ticket: 4, status: 'waiting', order: 10 });
  });

  it('shouldRenotify funciona sem fcmToken', () => {
    assert.equal(shouldRenotify(manual, { ...manual, status: 'called' }), true);
  });

  it('pickNextWaiting e advancedFromWaiting toleram entry sem uid/fcmToken', () => {
    const next = pickNextWaiting({ m1: manual });
    assert.equal(next.id, 'm1');
    assert.equal(next.fcmToken, undefined);
    assert.equal(typeof advancedFromWaiting(manual, { ...manual, status: 'called' }), 'boolean');
  });
});
