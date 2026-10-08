const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { orderOf, publicTicketFor, shouldRenotify } = require('../src/ticket');

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
    assert.deepEqual(pub, { ticket: 4, status: 'waiting', order: 20, slotId: 's1' });
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

  it('não notifica sem mudança ou fora de called', () => {
    assert.equal(shouldRenotify({ status: 'called', recalledAt: 1 }, { status: 'called', recalledAt: 1 }), false);
    assert.equal(shouldRenotify({ status: 'waiting' }, { status: 'waiting' }), false);
    assert.equal(shouldRenotify({ status: 'called' }, null), false);
  });
});
