const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { WATCHER_TTL_MS, openedFromClosed, activeWatchers } = require('../src/openwatch');
const { buildOpenMessage } = require('../src/webpush');

describe('openedFromClosed', () => {
  it('dispara só ao abrir vindo de closed ou paused', () => {
    assert.equal(openedFromClosed('closed', 'open'), true);
    assert.equal(openedFromClosed('paused', 'open'), true);
    assert.equal(openedFromClosed('open', 'open'), false);
    assert.equal(openedFromClosed(null, 'open'), false);
    assert.equal(openedFromClosed('open', 'closed'), false);
    assert.equal(openedFromClosed('closed', 'paused'), false);
  });
});

describe('activeWatchers', () => {
  const now = 1_000_000_000;

  it('ignora expirados, sem token e sem createdAt', () => {
    const out = activeWatchers(
      {
        a: { fcmToken: 't1', lang: 'en', createdAt: now - 1000 },
        b: { fcmToken: 't2', lang: 'pt', createdAt: now - WATCHER_TTL_MS - 1 },
        c: { fcmToken: '', createdAt: now },
        d: { createdAt: now },
        e: { fcmToken: 't5' },
        f: null,
      },
      now,
    );
    assert.deepEqual(out, [{ uid: 'a', token: 't1', lang: 'en' }]);
  });

  it('respeita o limite e tokens enormes', () => {
    const many = {};
    for (let i = 0; i < 10; i++) many[`u${i}`] = { fcmToken: `t${i}`, createdAt: now };
    assert.equal(activeWatchers(many, now, WATCHER_TTL_MS, 3).length, 3);
    assert.equal(
      activeWatchers({ a: { fcmToken: 'x'.repeat(4097), createdAt: now } }, now).length,
      0,
    );
  });

  it('aceita entrada vazia', () => {
    assert.deepEqual(activeWatchers(null, now), []);
  });
});

describe('buildOpenMessage', () => {
  it('monta em pt/en/es com tag e link', () => {
    for (const [lang, title] of [
      ['pt', 'A fila abriu'],
      ['en', 'The queue is open'],
      ['es', 'La fila abrió'],
    ]) {
      const m = buildOpenMessage({ token: 'tk', queueName: 'Balcão', queueId: 'q1', lang });
      assert.equal(m.notification.title, title);
      assert.match(m.notification.body, /Balcão/);
      assert.equal(m.data.type, 'open');
      assert.equal(m.webpush.notification.tag, 'q1');
      assert.match(m.webpush.fcmOptions.link, /q1$/);
    }
  });

  it('idioma desconhecido cai no padrão e nome vazio vira Qio', () => {
    const m = buildOpenMessage({ token: 'tk', queueName: ' ', queueId: 'q1', lang: 'xx' });
    assert.match(m.notification.body, /Qio/);
  });
});
