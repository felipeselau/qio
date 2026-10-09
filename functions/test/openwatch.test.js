const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  WATCHER_LIMIT,
  WATCHER_TTL_MS,
  openedFromClosed,
  activeWatchers,
  processQueueOpened,
} = require('../src/openwatch');
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

describe('processQueueOpened', () => {
  const now = 1_000_000_000_000;

  function fakeDeps(initial, { send } = {}) {
    const store = { ...initial };
    const calls = { send: [], update: [] };
    const pick = (pred, limit) =>
      Object.fromEntries(
        Object.entries(store)
          .filter(([, w]) => pred(w.createdAt))
          .slice(0, limit),
      );
    const deps = {
      fetchActive: async (limit, min) => pick((c) => c >= min, limit),
      fetchExpired: async (limit, min) => pick((c) => c < min, limit),
      update: async (patch) => {
        calls.update.push(patch);
        for (const [k, v] of Object.entries(patch)) {
          if (v === null) delete store[k];
          else store[k] = v;
        }
      },
      queueName: async () => 'Balcão',
      send:
        send ??
        (async (messages) => {
          calls.send.push(messages);
          return messages.map(() => ({ success: true }));
        }),
    };
    return { deps, store, calls };
  }

  const w = (i, over = {}) => [`u${i}`, { fcmToken: `t${i}`, lang: 'pt', createdAt: now - 1000, ...over }];

  it('envia, remove os capturados e apaga vencidos', async () => {
    const { deps, store, calls } = fakeDeps(
      Object.fromEntries([w(1), w(2, { lang: 'en' }), w(3, { createdAt: now - WATCHER_TTL_MS - 5 })]),
    );
    const res = await processQueueOpened({ queueId: 'q1', now, deps });
    assert.equal(res.sent, 2);
    assert.equal(calls.send.flat().length, 2);
    assert.deepEqual(store, {});
  });

  it('é idempotente: segunda execução não reenvia', async () => {
    const { deps, calls } = fakeDeps(Object.fromEntries([w(1), w(2)]));
    await processQueueOpened({ queueId: 'q1', now, deps });
    await processQueueOpened({ queueId: 'q1', now, deps });
    assert.equal(calls.send.flat().length, 2);
  });

  it('remove antes de enviar', async () => {
    const order = [];
    const { deps } = fakeDeps(Object.fromEntries([w(1)]), {
      send: async (m) => {
        order.push('send');
        return m.map(() => ({ success: true }));
      },
    });
    const update = deps.update;
    deps.update = async (p) => {
      order.push('update');
      return update(p);
    };
    await processQueueOpened({ queueId: 'q1', now, deps });
    assert.equal(order[0], 'update');
    assert.ok(order.indexOf('send') > 0);
  });

  it('token inválido some; falha transitória restaura o pedido', async () => {
    const { deps, store } = fakeDeps(Object.fromEntries([w(1), w(2), w(3)]), {
      send: async () => [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/internal-error' } },
      ],
    });
    const res = await processQueueOpened({ queueId: 'q1', now, deps });
    assert.equal(res.sent, 1);
    assert.deepEqual(Object.keys(store), ['u3']);
  });

  it('send que lança restaura o lote sem propagar', async () => {
    const { deps, store } = fakeDeps(Object.fromEntries([w(1), w(2)]), {
      send: async () => {
        throw new Error('boom');
      },
    });
    await processQueueOpened({ queueId: 'q1', now, deps });
    assert.deepEqual(Object.keys(store).sort(), ['u1', 'u2']);
  });

  it('lote maior que 500 é paginado até esvaziar', async () => {
    const n = WATCHER_LIMIT * 2 + 7;
    const { deps, store, calls } = fakeDeps(
      Object.fromEntries(Array.from({ length: n }, (_, i) => w(i))),
    );
    const res = await processQueueOpened({ queueId: 'q1', now, deps });
    assert.equal(res.sent, n);
    assert.equal(calls.send.flat().length, n);
    assert.ok(calls.send.every((c) => c.length <= WATCHER_LIMIT));
    assert.deepEqual(store, {});
  });

  it('vencidos além de 500 também são apagados', async () => {
    const old = createdAt => ({ fcmToken: 't', lang: 'pt', createdAt });
    const initial = {};
    for (let i = 0; i < WATCHER_LIMIT + 3; i++) initial[`x${i}`] = old(now - WATCHER_TTL_MS - 10 - i);
    const { deps, store, calls } = fakeDeps(initial);
    await processQueueOpened({ queueId: 'q1', now, deps });
    assert.deepEqual(store, {});
    assert.equal(calls.send.length, 0);
  });

  it('falha no fetch inicial propaga sem remover nada', async () => {
    const { deps, calls } = fakeDeps(Object.fromEntries([w(1)]));
    deps.fetchActive = async () => {
      throw new Error('rtdb down');
    };
    await assert.rejects(processQueueOpened({ queueId: 'q1', now, deps }), /rtdb down/);
    assert.equal(calls.update.length, 0);
    assert.equal(calls.send.length, 0);
  });
});
