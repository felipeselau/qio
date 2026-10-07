const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  buildCalledMessage,
  buildNextMessage,
  pickNextWaiting,
  advancedFromWaiting,
} = require('../src/webpush');

describe('buildCalledMessage', () => {
  it('localiza e aponta para a página da fila', () => {
    const m = buildCalledMessage({ token: 't', ticket: 7, queueName: 'Balcão', queueId: 'q1', lang: 'en' });
    assert.equal(m.token, 't');
    assert.equal(m.notification.title, "It's your turn!");
    assert.match(m.notification.body, /Ticket #7/);
    assert.equal(m.webpush.fcmOptions.link, 'https://qio.web.app/q/q1');
    assert.deepEqual(m.data, { type: 'called', queueId: 'q1' });
  });

  it('cai em pt e usa nome de reserva', () => {
    const m = buildCalledMessage({ token: 't', ticket: 1, queueName: '  ', queueId: 'q', lang: 'xx' });
    assert.equal(m.notification.title, 'É a sua vez!');
    assert.match(m.notification.body, /\(Qio\)/);
  });
});

describe('buildNextMessage', () => {
  it('avisa que é o próximo, em cada idioma', () => {
    for (const [lang, title] of [['pt', 'Você é o próximo'], ['en', "You're next"], ['es', 'Eres el siguiente']]) {
      const m = buildNextMessage({ token: 't', queueName: 'Fila', queueId: 'q', lang });
      assert.equal(m.notification.title, title);
      assert.equal(m.data.type, 'next');
    }
  });
});

describe('pickNextWaiting', () => {
  it('escolhe o primeiro por ordem, depois por senha', () => {
    const next = pickNextWaiting({
      a: { status: 'waiting', ticket: 3, joinedAt: 30 },
      b: { status: 'waiting', ticket: 2, joinedAt: 20 },
      c: { status: 'called', ticket: 1, joinedAt: 10 },
      d: { status: 'waiting', ticket: 4, joinedAt: 5, order: 99 },
    });
    assert.equal(next.id, 'b');
  });

  it('desempata pela senha e devolve null sem ninguém esperando', () => {
    assert.equal(
      pickNextWaiting({ a: { status: 'waiting', ticket: 5, joinedAt: 1 }, b: { status: 'waiting', ticket: 4, joinedAt: 1 } }).id,
      'b',
    );
    assert.equal(pickNextWaiting({ a: { status: 'called' } }), null);
    assert.equal(pickNextWaiting(null), null);
  });
});

describe('advancedFromWaiting', () => {
  it('detecta saída da espera (chamado, removido, desistiu)', () => {
    assert.equal(advancedFromWaiting({ status: 'waiting' }, { status: 'called' }), true);
    assert.equal(advancedFromWaiting({ status: 'waiting' }, null), true);
    assert.equal(advancedFromWaiting({ status: 'waiting' }, { status: 'left' }), true);
  });

  it('ignora o resto', () => {
    assert.equal(advancedFromWaiting({ status: 'waiting' }, { status: 'waiting' }), false);
    assert.equal(advancedFromWaiting({ status: 'called' }, null), false);
    assert.equal(advancedFromWaiting(null, { status: 'waiting' }), false);
  });
});
