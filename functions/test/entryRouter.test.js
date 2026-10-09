const test = require('node:test');
const assert = require('node:assert/strict');
const { planEntryWrite, routeEntryWrite } = require('../src/entryRouter');
const { shouldRenotify } = require('../src/ticket');
const { advancedFromWaiting } = require('../src/webpush');

const waiting = { status: 'waiting', ticket: 1, name: 'Ana' };
const called = { status: 'called', ticket: 1, name: 'Ana' };
const served = { status: 'served', ticket: 1, name: 'Ana' };
const left = { status: 'left', ticket: 1, name: 'Ana' };

test('create dispara sync e joined', () => {
  assert.deepEqual(planEntryWrite(null, waiting), {
    sync: true,
    joined: true,
    called: false,
    advanced: false,
  });
});

test('create ja em called dispara joined e called', () => {
  const plan = planEntryWrite(undefined, called);
  assert.equal(plan.joined, true);
  assert.equal(plan.called, true);
});

test('waiting -> called dispara called e advanced, nao joined', () => {
  assert.deepEqual(planEntryWrite(waiting, called), {
    sync: true,
    joined: false,
    called: true,
    advanced: true,
  });
});

test('recall dispara so called', () => {
  const plan = planEntryWrite(
    { ...called, recalledAt: 1 },
    { ...called, recalledAt: 2 },
  );
  assert.deepEqual(plan, { sync: true, joined: false, called: true, advanced: false });
});

test('remocao de waiting dispara advanced', () => {
  assert.equal(planEntryWrite(waiting, null).advanced, true);
  assert.equal(planEntryWrite(waiting, left).advanced, true);
});

test('update neutro dispara so sync', () => {
  assert.deepEqual(planEntryWrite(waiting, { ...waiting, fcmToken: 't' }), {
    sync: true,
    joined: false,
    called: false,
    advanced: false,
  });
  assert.deepEqual(planEntryWrite(called, served), {
    sync: true,
    joined: false,
    called: false,
    advanced: false,
  });
});

test('equivalencia com os predicados originais em todas as transicoes', () => {
  const states = [null, undefined, waiting, called, { ...called, recalledAt: 5 }, served, left];
  for (const before of states) {
    for (const after of states) {
      const plan = planEntryWrite(before, after);
      assert.equal(plan.called, shouldRenotify(before, after));
      assert.equal(plan.advanced, advancedFromWaiting(before, after));
      assert.equal(plan.joined, (before ?? null) === null && !!after);
    }
  }
});

test('routeEntryWrite chama so os handlers do plano, com o contexto', async () => {
  const calls = [];
  const handlers = Object.fromEntries(
    ['sync', 'joined', 'called', 'advanced'].map((step) => [
      step,
      async (ctx) => {
        calls.push([step, ctx.queueId, ctx.entryId]);
      },
    ]),
  );
  const result = await routeEntryWrite(
    { queueId: 'q', entryId: 'e', before: waiting, after: called },
    handlers,
  );
  assert.equal(result, null);
  assert.deepEqual(calls.map((c) => c[0]).sort(), ['advanced', 'called', 'sync']);
  assert.ok(calls.every((c) => c[1] === 'q' && c[2] === 'e'));
});

test('falha de um handler nao impede os outros e e repropagada', async () => {
  const ran = [];
  const handlers = {
    sync: async () => {
      throw new Error('boom');
    },
    joined: async () => {
      ran.push('joined');
    },
  };
  await assert.rejects(
    routeEntryWrite({ queueId: 'q', entryId: 'e', before: null, after: waiting }, handlers),
    /boom/,
  );
  assert.deepEqual(ran, ['joined']);
});

test('handler que lanca de forma sincrona tambem e isolado', async () => {
  const ran = [];
  const handlers = {
    sync: () => {
      throw new Error('sync-boom');
    },
    joined: async () => {
      ran.push('joined');
    },
  };
  await assert.rejects(
    routeEntryWrite({ queueId: 'q', entryId: 'e', before: null, after: waiting }, handlers),
    /sync-boom/,
  );
  assert.deepEqual(ran, ['joined']);
});
