const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  createMirrorQueueHandler,
  createMirrorOperatorHandler,
} = require('../src/handlers/mirror');

const snap = (data) => ({ exists: data !== null && data !== undefined, data: () => data });
const event = (before, after, params = { queueId: 'q1' }) => ({
  params,
  data: { before: snap(before), after: snap(after) },
});
const doc = (extra = {}) => ({
  ownerId: 'u1',
  name: 'Balcão',
  status: 'open',
  avgServiceMin: 10,
  maxWaiting: 0,
  ...extra,
});

function queueWorld({ current, meta = null, owner = null } = {}) {
  const w = { current, meta, owner, calls: [], warns: [], errors: [] };
  w.deps = {
    readQueueDoc: async () => w.current,
    readOwner: async () => w.owner,
    setOwner: async (id, patch) => {
      w.calls.push(['setOwner', patch]);
      w.owner = patch;
    },
    readMeta: async () => w.meta,
    updateMeta: async (id, patch) => {
      w.calls.push(['updateMeta', patch]);
      const next = { ...w.meta, ...patch };
      for (const k of Object.keys(next)) if (next[k] === null) delete next[k];
      w.meta = next;
    },
    createMeta: async (id, meta) => {
      w.calls.push(['createMeta', meta]);
      w.meta = meta;
    },
    now: () => 4242,
    warn: (m) => w.warns.push(m),
    onError: (m, err) => w.errors.push(err),
  };
  return w;
}

const metaOf = (extra = {}) => ({
  nextTicket: 5,
  serving: 4,
  updatedAt: 1,
  name: 'Balcão',
  status: 'open',
  avgServiceMin: 10,
  maxWaiting: 0,
  ...extra,
});

describe('mirrorQueueToRtdb handler', () => {
  it('create do doc cria owners e meta com updatedAt', async () => {
    const w = queueWorld({ current: doc() });
    await createMirrorQueueHandler(w.deps)(event(null, doc()));
    assert.deepEqual(w.calls[0], ['setOwner', { ownerUid: 'u1' }]);
    assert.equal(w.calls[1][0], 'createMeta');
    assert.equal(w.calls[1][1].updatedAt, 4242);
    assert.equal(w.calls[1][1].nextTicket, 0);
  });

  it('update parcial só de alertState/scheduleLastDesired não lê nem escreve nada', async () => {
    const w = queueWorld({ current: doc(), meta: metaOf({ name: 'Adulterado' }) });
    let reads = 0;
    w.deps.readQueueDoc = async () => {
      reads += 1;
      return w.current;
    };
    const after = doc({ alertState: { waitAt: 9 }, scheduleLastDesired: 'open', lastTicketResetDay: 'd' });
    await createMirrorQueueHandler(w.deps)(event(doc(), after));
    assert.equal(reads, 0);
    assert.deepEqual(w.calls, []);
  });

  it('patch idempotente sobre tudo: repara também campo que não mudou no evento', async () => {
    const w = queueWorld({
      current: doc({ name: 'Novo' }),
      meta: metaOf({ status: 'closed' }),
      owner: { ownerUid: 'u1' },
    });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ name: 'Novo' })));
    assert.deepEqual(w.calls, [['updateMeta', { name: 'Novo', status: 'open', updatedAt: 4242 }]]);
  });

  it('só nome muda: sem updatedAt', async () => {
    const w = queueWorld({ current: doc({ name: 'Novo' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ name: 'Novo' })));
    assert.deepEqual(w.calls, [['updateMeta', { name: 'Novo' }]]);
  });

  it('status muda: carimba updatedAt', async () => {
    const w = queueWorld({ current: doc({ status: 'paused' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ status: 'paused' })));
    assert.deepEqual(w.calls, [['updateMeta', { status: 'paused', updatedAt: 4242 }]]);
  });

  it('pausado com mensagem para aberto sem mensagem limpa statusMessage e resumeAt', async () => {
    const before = doc({ status: 'paused', statusMessage: 'volto já', resumeAt: 1000 });
    const w = queueWorld({
      current: doc(),
      meta: metaOf({ status: 'paused', statusMessage: 'volto já', resumeAt: 1000 }),
      owner: { ownerUid: 'u1' },
    });
    await createMirrorQueueHandler(w.deps)(event(before, doc()));
    assert.deepEqual(w.calls, [
      ['updateMeta', { status: 'open', statusMessage: null, resumeAt: null, updatedAt: 4242 }],
    ]);
    assert.equal('statusMessage' in w.meta, false);
    assert.equal('resumeAt' in w.meta, false);
  });

  it('evento fora de ordem: usa o doc atual, não o after do evento', async () => {
    const w = queueWorld({
      current: doc({ name: 'Segundo' }),
      meta: metaOf({ name: 'Segundo' }),
      owner: { ownerUid: 'u1' },
    });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ name: 'Primeiro' })));
    assert.deepEqual(w.calls, []);
    assert.equal(w.meta.name, 'Segundo');
  });

  it('evento stale depois de deleting: doc atual deleting não escreve', async () => {
    const w = queueWorld({ current: doc({ deleting: true }), meta: null });
    await createMirrorQueueHandler(w.deps)(event(null, doc()));
    assert.deepEqual(w.calls, []);
  });

  it('evento stale depois de doc apagado não escreve', async () => {
    const w = queueWorld({ current: null });
    await createMirrorQueueHandler(w.deps)(event(null, doc()));
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ name: 'x' })));
    assert.deepEqual(w.calls, []);
  });

  it('delete do doc e after deleting são ignorados', async () => {
    const w = queueWorld({ current: doc() });
    await createMirrorQueueHandler(w.deps)(event(doc(), null));
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ deleting: true })));
    assert.deepEqual(w.calls, []);
  });

  it('fila existente sem meta: só loga, nunca recria nem zera serving', async () => {
    const w = queueWorld({ current: doc({ name: 'Novo' }), meta: null, owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ name: 'Novo' })));
    assert.deepEqual(w.calls, []);
    assert.equal(w.warns.length, 1);
  });

  it('status só entra quando mudou; valor desconhecido é ignorado', async () => {
    const w = queueWorld({ current: doc({ status: 'closed', name: 'N' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w.deps)(event(doc({ status: 'closed' }), doc({ status: 'closed', name: 'N' })));
    assert.deepEqual(w.calls, [['updateMeta', { name: 'N', status: 'closed', updatedAt: 4242 }]]);

    const w2 = queueWorld({ current: doc({ status: 'weird' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w2.deps)(event(doc(), doc({ status: 'weird' })));
    assert.deepEqual(w2.calls, []);
  });

  it('segunda execução com o mesmo evento é idempotente', async () => {
    const w = queueWorld({ current: doc({ name: 'Novo' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    const handler = createMirrorQueueHandler(w.deps);
    await handler(event(doc(), doc({ name: 'Novo' })));
    await handler(event(doc(), doc({ name: 'Novo' })));
    assert.equal(w.calls.length, 1);
  });

  it('mudança de ownerId atualiza owners sem tocar meta', async () => {
    const w = queueWorld({ current: doc({ ownerId: 'u2' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    await createMirrorQueueHandler(w.deps)(event(doc(), doc({ ownerId: 'u2' })));
    assert.deepEqual(w.calls, [['setOwner', { ownerUid: 'u2' }]]);
  });

  it('erro de dependência é logado e relançado (retry do trigger)', async () => {
    const w = queueWorld({ current: doc() });
    w.deps.readQueueDoc = async () => {
      throw new Error('boom');
    };
    await assert.rejects(createMirrorQueueHandler(w.deps)(event(null, doc())), /boom/);
    assert.equal(w.errors.length, 1);
  });

  it('falha do RTDB no update relança e a reexecução converge', async () => {
    const w = queueWorld({ current: doc({ name: 'Novo' }), meta: metaOf(), owner: { ownerUid: 'u1' } });
    const update = w.deps.updateMeta;
    w.deps.updateMeta = async () => {
      throw new Error('rtdb down');
    };
    const ev = event(doc(), doc({ name: 'Novo' }));
    await assert.rejects(createMirrorQueueHandler(w.deps)(ev), /rtdb down/);
    w.deps.updateMeta = update;
    await createMirrorQueueHandler(w.deps)(ev);
    assert.equal(w.meta.name, 'Novo');
  });
});

describe('mirrorOperatorToRtdb handler', () => {
  let w;
  const params = { queueId: 'q1', uid: 'op1' };
  beforeEach(() => {
    w = { opDoc: true, queue: { ownerId: 'u1' }, mirror: false, calls: [], errors: [] };
    w.deps = {
      readQueueDoc: async () => w.queue,
      operatorExists: async () => w.opDoc,
      readOperator: async () => w.mirror,
      setOperator: async () => {
        w.calls.push('set');
        w.mirror = true;
      },
      removeOperator: async () => {
        w.calls.push('remove');
        w.mirror = false;
      },
      onError: (m, err) => w.errors.push(err),
    };
  });

  it('add quando o operador existe e a fila existe', async () => {
    await createMirrorOperatorHandler(w.deps)({ params });
    assert.deepEqual(w.calls, ['set']);
  });

  it('já espelhado não escreve de novo', async () => {
    w.mirror = true;
    await createMirrorOperatorHandler(w.deps)({ params });
    assert.deepEqual(w.calls, []);
  });

  it('evento de add atrasado após remove não re-adiciona', async () => {
    w.opDoc = false;
    await createMirrorOperatorHandler(w.deps)({ params, data: { after: snap({}) } });
    assert.deepEqual(w.calls, ['remove']);
  });

  it('evento de remove atrasado após novo add não remove', async () => {
    await createMirrorOperatorHandler(w.deps)({ params, data: { before: snap({}), after: snap(null) } });
    assert.deepEqual(w.calls, ['set']);
  });

  it('fila inexistente ou deleting não recebe operador', async () => {
    w.queue = null;
    await createMirrorOperatorHandler(w.deps)({ params });
    w.queue = { deleting: true };
    await createMirrorOperatorHandler(w.deps)({ params });
    assert.deepEqual(w.calls, []);
  });

  it('uid inválido é ignorado', async () => {
    await createMirrorOperatorHandler(w.deps)({ params: { queueId: 'q1', uid: 'a/b' } });
    assert.deepEqual(w.calls, []);
  });

  it('falha do RTDB é logada e relançada', async () => {
    w.deps.setOperator = async () => {
      throw new Error('rtdb down');
    };
    await assert.rejects(createMirrorOperatorHandler(w.deps)({ params }), /rtdb down/);
    assert.equal(w.errors.length, 1);
  });
});
