const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { historyFromLeftEntry } = require('../src/history');

describe('historyFromLeftEntry', () => {
  const now = 1_700_000_000_000;

  it('monta o documento com result left', () => {
    const doc = historyFromLeftEntry(
      { ticket: 7, name: 'Ana', phone: '(11) 91234-5678', uid: 'u', status: 'left', joinedAt: now - 60000 },
      now,
    );
    assert.equal(doc.ticket, 7);
    assert.equal(doc.name, 'Ana');
    assert.equal(doc.phone, '(11) 91234-5678');
    assert.equal(doc.result, 'left');
    assert.equal(doc.calledBy, null);
    assert.equal(doc.operatorId, null);
    assert.equal(doc.calledAt, null);
    assert.ok(doc.joinedAt instanceof Timestamp);
    assert.equal(doc.joinedAt.toMillis(), now - 60000);
    assert.equal(doc.finishedAt.toMillis(), now);
  });

  it('converte calledAt em Timestamp', () => {
    const doc = historyFromLeftEntry({ ticket: 1, name: 'Bia', joinedAt: now - 2000, calledAt: now - 1000 }, now);
    assert.equal(doc.calledAt.toMillis(), now - 1000);
  });

  it('não vaza uid nem fcmToken e usa só as chaves do histórico', () => {
    const doc = historyFromLeftEntry({ ticket: 1, name: 'Caio', uid: 'u', fcmToken: 't', joinedAt: now }, now);
    assert.deepEqual(Object.keys(doc).sort(), [
      'calledAt',
      'calledBy',
      'finishedAt',
      'joinedAt',
      'name',
      'operatorId',
      'phone',
      'result',
      'ticket',
    ]);
  });

  it('tolera campos ausentes', () => {
    const doc = historyFromLeftEntry({}, now);
    assert.equal(doc.ticket, 0);
    assert.equal(doc.name, '');
    assert.equal(doc.phone, '');
    assert.equal(doc.joinedAt.toMillis(), now);
  });

  it('grava phone null quando a fila anonimiza', () => {
    const entry = { ticket: 1, name: 'Ana', phone: '(11) 91234-5678', status: 'left', joinedAt: now - 1000 };
    assert.equal(historyFromLeftEntry(entry, now, { anonymizePhone: true }).phone, null);
    assert.equal(historyFromLeftEntry(entry, now, { anonymizePhone: false }).phone, '(11) 91234-5678');
    assert.equal(historyFromLeftEntry(entry, now).phone, '(11) 91234-5678');
  });
});
