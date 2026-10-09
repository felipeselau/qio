const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  planWaitingCount,
  writeWaitingCount,
  refreshWaitingCount,
  mapLimit,
  reconcileWaitingCounts,
  applyEntryChange,
} = require('../src/waiting');

function clone(v) {
  return v === undefined ? undefined : JSON.parse(JSON.stringify(v));
}

function fakeDb(initial = {}, hooks = {}) {
  const root = clone(initial);
  const log = [];
  const parts = (path) => path.split('/').filter(Boolean);
  const read = (path) => {
    let node = root;
    for (const p of parts(path)) {
      if (node === null || typeof node !== 'object' || !(p in node)) return null;
      node = node[p];
    }
    return clone(node);
  };
  const write = (path, value) => {
    const ps = parts(path);
    let node = root;
    for (const p of ps.slice(0, -1)) {
      if (node[p] === null || typeof node[p] !== 'object') node[p] = {};
      node = node[p];
    }
    const last = ps[ps.length - 1];
    if (value === null || value === undefined) delete node[last];
    else node[last] = clone(value);
  };
  return {
    log,
    read,
    ref: (path) => ({
      once: async () => {
        log.push(['read', path]);
        if (hooks.onRead) hooks.onRead(path, { write });
        return { val: () => read(path) };
      },
      set: async (value) => {
        log.push(['set', path]);
        write(path, value);
      },
      remove: async () => {
        log.push(['remove', path]);
        write(path, null);
      },
      transaction: async (fn) => {
        const result = fn(read(path));
        if (result === undefined) {
          log.push(['abort', path]);
          return { committed: false };
        }
        log.push(['commit', path]);
        write(path, result);
        return { committed: true };
      },
    }),
  };
}

const meta = (extra = {}) => ({ name: 'Balcão', status: 'open', ...extra });
const pub = (...statuses) =>
  Object.fromEntries(statuses.map((status, i) => [`e${i}`, { ticket: i, status }]));

describe('planWaitingCount', () => {
  it('ignora meta ausente, sem name ou deleting', () => {
    assert.equal(planWaitingCount(null, {}).action, 'missing');
    assert.equal(planWaitingCount({ status: 'open' }, {}).action, 'missing');
    assert.equal(planWaitingCount(meta({ deleting: true }), pub('waiting')).action, 'deleting');
  });

  it('pula quando já está correto e escreve quando diverge', () => {
    assert.deepEqual(planWaitingCount(meta({ waitingCount: 1 }), pub('waiting', 'called')), {
      action: 'same',
      count: 1,
    });
    assert.deepEqual(planWaitingCount(meta({ waitingCount: 5 }), pub('waiting')), {
      action: 'write',
      count: 1,
    });
    assert.deepEqual(planWaitingCount(meta(), null), { action: 'write', count: 0 });
  });
});

describe('writeWaitingCount', () => {
  it('fila apagada não recria o meta', async () => {
    const db = fakeDb({});
    assert.equal(await writeWaitingCount(db, 'q', 3), 'missing');
    assert.equal(db.read('queues/q/meta'), null);
  });

  it('meta sem name não é alterado', async () => {
    const db = fakeDb({ queues: { q: { meta: { status: 'open' } } } });
    assert.equal(await writeWaitingCount(db, 'q', 3), 'missing');
    assert.deepEqual(db.read('queues/q/meta'), { status: 'open' });
  });

  it('deleting não altera', async () => {
    const db = fakeDb({ queues: { q: { meta: meta({ deleting: true }) } } });
    assert.equal(await writeWaitingCount(db, 'q', 3), 'deleting');
    assert.equal(db.read('queues/q/meta/waitingCount'), null);
  });

  it('grava o campo preservando o resto do meta', async () => {
    const db = fakeDb({ queues: { q: { meta: meta({ serving: 2 }) } } });
    assert.equal(await writeWaitingCount(db, 'q', 3), 'written');
    assert.deepEqual(db.read('queues/q/meta'), meta({ serving: 2, waitingCount: 3 }));
    assert.equal(await writeWaitingCount(db, 'q', 3), 'same');
  });
});

describe('refreshWaitingCount', () => {
  it('relê public e regrava se mudou durante a escrita', async () => {
    let reads = 0;
    const db = fakeDb(
      { queues: { q: { meta: meta(), public: pub('waiting') } } },
      {
        onRead: (path, { write }) => {
          if (path !== 'queues/q/public') return;
          reads += 1;
          if (reads === 1) write('queues/q/public/x', { ticket: 9, status: 'waiting' });
        },
      },
    );
    await refreshWaitingCount(db, 'q');
    assert.equal(reads, 2);
    assert.equal(db.read('queues/q/meta/waitingCount'), 2);
  });

  it('para após uma releitura estável', async () => {
    const db = fakeDb({ queues: { q: { meta: meta(), public: pub('waiting') } } });
    assert.equal(await refreshWaitingCount(db, 'q'), 'stable');
    assert.equal(db.log.filter((l) => l[0] === 'commit').length, 1);
  });

  it('no máximo duas escritas', async () => {
    let n = 0;
    const db = fakeDb(
      { queues: { q: { meta: meta(), public: {} } } },
      {
        onRead: (path, { write }) => {
          if (path === 'queues/q/public') {
            n += 1;
            write(`queues/q/public/k${n}`, { status: 'waiting' });
          }
        },
      },
    );
    await refreshWaitingCount(db, 'q');
    assert.equal(db.log.filter((l) => l[0] === 'commit').length, 2);
  });

  it('fila apagada: não recria meta', async () => {
    const db = fakeDb({ queues: { q: { public: pub('waiting') } } });
    assert.equal(await refreshWaitingCount(db, 'q'), 'missing');
    assert.equal(db.read('queues/q/meta'), null);
  });
});

describe('mapLimit / reconcileWaitingCounts', () => {
  it('respeita a concorrência e preserva a ordem', async () => {
    let running = 0;
    let peak = 0;
    const out = await mapLimit([1, 2, 3, 4, 5, 6], 2, async (n) => {
      running += 1;
      peak = Math.max(peak, running);
      await new Promise((r) => setImmediate(r));
      running -= 1;
      return n * 2;
    });
    assert.deepEqual(out, [2, 4, 6, 8, 10, 12]);
    assert.equal(peak, 2);
  });

  it('corrige divergência, pula deleting e isola erro por fila', async () => {
    const db = fakeDb({
      queues: {
        a: { meta: meta({ waitingCount: 7 }), public: pub('waiting', 'waiting') },
        b: { meta: meta({ deleting: true, waitingCount: 4 }), public: pub('waiting') },
        c: { meta: meta({ waitingCount: 1 }), public: pub('waiting') },
      },
    });
    const errors = [];
    const results = await reconcileWaitingCounts(db, ['a', 'b', 'c', 'gone'], {
      onError: (err, id) => errors.push(id),
    });
    assert.equal(db.read('queues/a/meta/waitingCount'), 2);
    assert.equal(db.read('queues/b/meta/waitingCount'), 4);
    assert.equal(db.read('queues/c/meta/waitingCount'), 1);
    assert.equal(db.read('queues/gone/meta'), null);
    assert.deepEqual(errors, []);
    assert.equal(results.length, 4);
  });

  it('erro em uma fila não interrompe as outras', async () => {
    const db = fakeDb({ queues: { b: { meta: meta(), public: pub('waiting') } } });
    const realRef = db.ref;
    db.ref = (path) => {
      if (path.startsWith('queues/a/')) throw new Error('boom');
      return realRef(path);
    };
    const errors = [];
    const results = await reconcileWaitingCounts(db, ['a', 'b'], { onError: (e, id) => errors.push(id) });
    assert.deepEqual(errors, ['a']);
    assert.deepEqual(results, ['error', 'stable']);
    assert.equal(db.read('queues/b/meta/waitingCount'), 1);
  });
});

describe('applyEntryChange', () => {
  const noopLog = () => {};

  it('waiting grava public e depois recontagem', async () => {
    const db = fakeDb({ queues: { q: { meta: meta() } } });
    const after = { ticket: 1, status: 'waiting', joinedAt: 5 };
    await applyEntryChange(
      db,
      { queueId: 'q', entryId: 'e1', before: null, after },
      { archiveLeftEntry: async () => {}, logError: noopLog },
    );
    assert.equal(db.read('queues/q/public/e1/status'), 'waiting');
    assert.equal(db.read('queues/q/meta/waitingCount'), 1);
    const setIdx = db.log.findIndex((l) => l[0] === 'set');
    const commitIdx = db.log.findIndex((l) => l[0] === 'commit');
    assert.ok(setIdx >= 0 && setIdx < commitIdx);
  });

  it('left com falha no arquivamento ainda remove public e recontagem, e relança', async () => {
    const db = fakeDb({
      queues: {
        q: {
          meta: meta({ waitingCount: 1 }),
          public: pub('waiting'),
          entries: { e0: { status: 'left' } },
        },
      },
    });
    const logged = [];
    await assert.rejects(
      applyEntryChange(
        db,
        {
          queueId: 'q',
          entryId: 'e0',
          before: { status: 'waiting' },
          after: { status: 'left', ticket: 0 },
        },
        {
          archiveLeftEntry: async () => {
            throw new Error('archive down');
          },
          logError: (msg) => logged.push(msg),
        },
      ),
      /archive down/,
    );
    assert.equal(db.read('queues/q/public/e0'), null);
    assert.equal(db.read('queues/q/meta/waitingCount'), 0);
    const removeIdx = db.log.findIndex((l) => l[0] === 'remove' && l[1] === 'queues/q/public/e0');
    const commitIdx = db.log.findIndex((l) => l[0] === 'commit');
    assert.ok(removeIdx >= 0 && removeIdx < commitIdx);
    assert.deepEqual(logged, ['syncPublicTicket failed']);
  });

  it('mudança sem alterar waiting não recontagem', async () => {
    const db = fakeDb({ queues: { q: { meta: meta(), public: pub('called') } } });
    await applyEntryChange(
      db,
      {
        queueId: 'q',
        entryId: 'e0',
        before: { status: 'called' },
        after: { status: 'called', recalledAt: 3, ticket: 0 },
      },
      { archiveLeftEntry: async () => {}, logError: noopLog },
    );
    assert.equal(db.log.filter((l) => l[0] === 'commit' || l[0] === 'abort').length, 0);
  });
});
