const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { HttpsError } = require('firebase-functions/v2/https');
const { guarded, safeQueueId } = require('../src/guard');

function run(err, data) {
  const calls = [];
  const fn = guarded(
    'joinQueue',
    async () => {
      throw err;
    },
    (event, e, ctx) => calls.push({ event, e, ctx }),
  );
  return fn({ data }).then(
    () => assert.fail('deveria lançar'),
    (thrown) => {
      assert.equal(thrown, err);
      return calls;
    },
  );
}

describe('guarded', () => {
  it('não loga erros do cliente', async () => {
    for (const code of ['invalid-argument', 'not-found', 'already-exists', 'resource-exhausted']) {
      assert.equal((await run(new HttpsError(code, 'x'), {})).length, 0);
    }
  });

  it('loga HttpsError internal e erros inesperados', async () => {
    assert.equal((await run(new HttpsError('internal', 'x'), {})).length, 1);
    assert.equal((await run(new Error('boom'), {})).length, 1);
  });

  it('valida e corta o queueId', async () => {
    const [a] = await run(new Error('x'), { queueId: 'a'.repeat(200) });
    assert.equal(a.ctx.queueId.length, 64);
    const [b] = await run(new Error('x'), { queueId: { evil: 1 } });
    assert.equal(b.ctx.queueId, undefined);
  });

  it('devolve o resultado normal', async () => {
    const fn = guarded('e', async () => 7, () => {});
    assert.equal(await fn({}), 7);
  });
});

describe('safeQueueId', () => {
  it('aceita só string', () => {
    assert.equal(safeQueueId(5), undefined);
    assert.equal(safeQueueId('q'), 'q');
  });
});
