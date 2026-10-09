const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  DEFAULT_RETENTION_DAYS,
  retentionDaysFor,
  cutoffMs,
  isOlderThan,
  purgeOlderThan,
  purgeQueueRetention,
  purgeAllRetention,
} = require('../src/retention');

const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_800_000_000_000;
const toTs = (ms) => ({ ms });

function fakeCollection(items) {
  return {
    items,
    where(field, op, ts) {
      const self = this;
      return {
        orderBy() {
          return {
            limit(n) {
              return {
                async get() {
                  const docs = self.items
                    .filter((d) => d.data[field] < ts.ms)
                    .sort((a, b) => a.data[field] - b.data[field])
                    .slice(0, n)
                    .map((d) => ({ id: d.id, ref: d }));
                  return { empty: docs.length === 0, size: docs.length, docs };
                },
              };
            },
          };
        },
      };
    },
  };
}

function fakeFirestore(collections) {
  const sizes = [];
  return {
    sizes,
    batch() {
      const refs = [];
      return {
        delete: (ref) => refs.push(ref),
        async commit() {
          sizes.push(refs.length);
          for (const ref of refs) {
            for (const col of collections) {
              const i = col.items.indexOf(ref);
              if (i >= 0) col.items.splice(i, 1);
            }
          }
        },
      };
    },
  };
}

function items(prefix, field, n, ms) {
  return Array.from({ length: n }, (_, i) => ({ id: `${prefix}${i}`, data: { [field]: ms + i } }));
}

function fakeQueue(id, data, history, feedback) {
  return {
    id,
    data: () => data,
    ref: { collection: (name) => (name === 'history' ? history : feedback) },
  };
}

describe('retentionDaysFor / cutoffMs', () => {
  it('usa 180 por padrão e para valores inválidos', () => {
    for (const v of [undefined, null, 0, 29, 731, 1.5, '90', NaN]) {
      assert.equal(retentionDaysFor(v), DEFAULT_RETENTION_DAYS);
    }
  });

  it('aceita 30 a 730', () => {
    assert.equal(retentionDaysFor(30), 30);
    assert.equal(retentionDaysFor(730), 730);
  });

  it('calcula o corte', () => {
    assert.equal(cutoffMs(NOW, undefined), NOW - 180 * DAY);
    assert.equal(cutoffMs(NOW, 30), NOW - 30 * DAY);
  });

  it('isOlderThan é estrito', () => {
    assert.equal(isOlderThan(10, 11), true);
    assert.equal(isOlderThan(11, 11), false);
    assert.equal(isOlderThan(null, 11), false);
  });
});

describe('purgeOlderThan', () => {
  it('apaga em lotes de no máximo 450 e mantém os recentes', async () => {
    const cutoff = NOW - 180 * DAY;
    const old = items('o', 'finishedAt', 1000, cutoff - 5000);
    const recent = items('r', 'finishedAt', 10, cutoff + 1000);
    const col = fakeCollection([...old, ...recent]);
    const fs = fakeFirestore([col]);
    const n = await purgeOlderThan(fs, col, 'finishedAt', toTs(cutoff));
    assert.equal(n, 1000);
    assert.deepEqual(fs.sizes, [450, 450, 100]);
    assert.equal(col.items.length, 10);
    assert.ok(col.items.every((d) => d.id.startsWith('r')));
  });

  it('é idempotente', async () => {
    const cutoff = NOW - 180 * DAY;
    const col = fakeCollection(items('o', 'finishedAt', 3, cutoff - 100));
    const fs = fakeFirestore([col]);
    assert.equal(await purgeOlderThan(fs, col, 'finishedAt', toTs(cutoff)), 3);
    assert.equal(await purgeOlderThan(fs, col, 'finishedAt', toTs(cutoff)), 0);
  });

  it('respeita maxBatches', async () => {
    const col = fakeCollection(items('o', 'finishedAt', 10, 0));
    const fs = fakeFirestore([col]);
    const n = await purgeOlderThan(fs, col, 'finishedAt', toTs(NOW), { limit: 2, maxBatches: 3 });
    assert.equal(n, 6);
    assert.equal(col.items.length, 4);
  });
});

describe('purgeQueueRetention', () => {
  it('apaga history e feedback antigos com o prazo da fila', async () => {
    const cutoff30 = NOW - 30 * DAY;
    const history = fakeCollection([
      { id: 'a', data: { finishedAt: cutoff30 - 1 } },
      { id: 'b', data: { finishedAt: cutoff30 + 1 } },
    ]);
    const feedback = fakeCollection([
      { id: 'a', data: { createdAt: cutoff30 - 1 } },
      { id: 'b', data: { createdAt: cutoff30 + 1 } },
    ]);
    const fs = fakeFirestore([history, feedback]);
    const q = fakeQueue('q1', { retentionDays: 30 }, history, feedback);
    const res = await purgeQueueRetention(fs, q, NOW, toTs);
    assert.deepEqual(res, { history: 1, feedback: 1, skipped: false });
    assert.deepEqual(history.items.map((d) => d.id), ['b']);
    assert.deepEqual(feedback.items.map((d) => d.id), ['b']);
  });

  it('usa 180 dias sem retentionDays e preserva 179 dias', async () => {
    const history = fakeCollection([
      { id: 'old', data: { finishedAt: NOW - 181 * DAY } },
      { id: 'new', data: { finishedAt: NOW - 179 * DAY } },
    ]);
    const feedback = fakeCollection([]);
    const fs = fakeFirestore([history, feedback]);
    await purgeQueueRetention(fs, fakeQueue('q', {}, history, feedback), NOW, toTs);
    assert.deepEqual(history.items.map((d) => d.id), ['new']);
  });

  it('ignora filas em exclusão', async () => {
    const history = fakeCollection([{ id: 'old', data: { finishedAt: 0 } }]);
    const feedback = fakeCollection([]);
    const fs = fakeFirestore([history, feedback]);
    const res = await purgeQueueRetention(
      fs,
      fakeQueue('q', { deleting: true }, history, feedback),
      NOW,
      toTs,
    );
    assert.equal(res.skipped, true);
    assert.equal(history.items.length, 1);
  });
});

describe('purgeAllRetention', () => {
  it('soma contagens e segue após falha em uma fila', async () => {
    const h1 = fakeCollection([{ id: 'x', data: { finishedAt: 0 } }]);
    const f1 = fakeCollection([]);
    const h3 = fakeCollection([{ id: 'y', data: { finishedAt: 0 } }]);
    const f3 = fakeCollection([{ id: 'y', data: { createdAt: 0 } }]);
    const fs = fakeFirestore([h1, f1, h3, f3]);
    const broken = {
      id: 'bad',
      data: () => ({}),
      ref: {
        collection: () => {
          throw new Error('boom');
        },
      },
    };
    const errors = [];
    const totals = await purgeAllRetention(
      fs,
      [
        fakeQueue('q1', {}, h1, f1),
        broken,
        fakeQueue('q3', {}, h3, f3),
        fakeQueue('q4', { deleting: true }, h3, f3),
      ],
      NOW,
      toTs,
      { onError: (err, ctx) => errors.push(ctx.queueId) },
    );
    assert.deepEqual(totals, { queues: 2, history: 2, feedback: 1, failed: 1 });
    assert.deepEqual(errors, ['bad']);
  });
});
