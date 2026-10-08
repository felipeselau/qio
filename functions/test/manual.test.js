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
