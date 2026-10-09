const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { orderOf, publicTicketFor, shouldRenotify, countWaiting, waitingChanged } = require('../src/ticket');

describe('orderOf', () => {
  it('usa order quando existe, senão joinedAt', () => {
    assert.equal(orderOf({ order: 50, joinedAt: 10 }), 50);
    assert.equal(orderOf({ joinedAt: 10 }), 10);
    assert.equal(orderOf({}), 0);
    assert.equal(orderOf(null), 0);
  });
});

describe('publicTicketFor', () => {
  it('expõe só senha, status e ordem (sem PII)', () => {
    const pub = publicTicketFor({ ticket: 4, status: 'waiting', name: 'Ana', phone: 'x', uid: 'u', joinedAt: 9, order: 20 });
    assert.deepEqual(pub, { ticket: 4, status: 'waiting', order: 20 });
  });
});

describe('publicTicketFor com slot', () => {
  it('inclui slotId quando a entry tem horário', () => {
    const pub = publicTicketFor({ ticket: 4, status: 'waiting', name: 'Ana', joinedAt: 9, order: 20, slotId: 's1', slotStart: 20 });
    assert.deepEqual(pub, { ticket: 4, status: 'waiting', order: 20, slotId: 's1', slotStart: 20 });
  });

  it('order de mover para o fim não altera slotId nem slotStart', () => {
    const pub = publicTicketFor({ ticket: 4, status: 'waiting', joinedAt: 9, order: 999, slotId: 's1', slotStart: 20 });
    assert.equal(pub.slotId, 's1');
    assert.equal(pub.slotStart, 20);
    assert.equal(pub.order, 999);
  });

  it('ignora slotId inválido', () => {
    const pub = publicTicketFor({ ticket: 4, status: 'waiting', joinedAt: 9, slotId: 5 });
    assert.deepEqual(pub, { ticket: 4, status: 'waiting', order: 9 });
  });
});

describe('shouldRenotify', () => {
  it('notifica na primeira chamada', () => {
    assert.equal(shouldRenotify({ status: 'waiting' }, { status: 'called' }), true);
    assert.equal(shouldRenotify(null, { status: 'called' }), true);
  });

  it('notifica de novo quando recalledAt muda', () => {
    assert.equal(shouldRenotify({ status: 'called', recalledAt: 1 }, { status: 'called', recalledAt: 2 }), true);
    assert.equal(shouldRenotify({ status: 'called' }, { status: 'called', recalledAt: 5 }), true);
  });

  it('não notifica quando só o calledAt é corrigido pelo servidor', () => {
    assert.equal(
      shouldRenotify({ status: 'called', calledAt: 1000 }, { status: 'called', calledAt: 1500 }),
      false,
    );
  });

  it('não notifica sem mudança ou fora de called', () => {
    assert.equal(shouldRenotify({ status: 'called', recalledAt: 1 }, { status: 'called', recalledAt: 1 }), false);
    assert.equal(shouldRenotify({ status: 'waiting' }, { status: 'waiting' }), false);
    assert.equal(shouldRenotify({ status: 'called' }, null), false);
  });
});

describe('countWaiting', () => {
  it('conta só status waiting', () => {
    assert.equal(
      countWaiting({
        a: { ticket: 1, status: 'waiting' },
        b: { ticket: 2, status: 'called' },
        c: { ticket: 3, status: 'waiting' },
      }),
      2,
    );
  });

  it('é 0 para vazio, nulo ou inválido', () => {
    assert.equal(countWaiting(null), 0);
    assert.equal(countWaiting(undefined), 0);
    assert.equal(countWaiting({}), 0);
    assert.equal(countWaiting({ a: null }), 0);
    assert.equal(countWaiting('x'), 0);
  });

  it('é idempotente: reprocessar o mesmo estado dá o mesmo valor', () => {
    const pub = { a: { status: 'waiting' }, b: { status: 'waiting' } };
    assert.equal(countWaiting(pub), countWaiting(pub));
  });
});

describe('waitingChanged', () => {
  const w = { status: 'waiting' };
  const c = { status: 'called' };

  it('detecta entrada e saída de waiting', () => {
    assert.equal(waitingChanged(null, w), true);
    assert.equal(waitingChanged(w, c), true);
    assert.equal(waitingChanged(w, { status: 'left' }), true);
    assert.equal(waitingChanged(w, null), true);
    assert.equal(waitingChanged(c, w), true);
  });

  it('ignora mudanças que não alteram waiting', () => {
    assert.equal(waitingChanged(w, { status: 'waiting', fcmToken: 't' }), false);
    assert.equal(waitingChanged(c, { status: 'called', recalledAt: 1 }), false);
    assert.equal(waitingChanged(c, null), false);
    assert.equal(waitingChanged(null, c), false);
    assert.equal(waitingChanged(null, null), false);
  });
});
