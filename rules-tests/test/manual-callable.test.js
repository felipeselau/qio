import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set, update } from 'firebase/database';
import { QUEUE, setupEnv } from './helpers.js';

const [FUNCTIONS_HOST, FUNCTIONS_PORT] = (process.env.FUNCTIONS_EMULATOR_HOST ?? 'localhost:5001').split(':');
const AUTH_PORT = Number(process.env.AUTH_EMULATOR_PORT ?? 9099);

describe('callable addManualEntry (emulador)', () => {
  let env;
  let apps = [];
  const adminDb = async (fn) => {
    let result;
    await env.withSecurityRulesDisabled(async (ctx) => {
      result = await fn(ctx.database());
    });
    return result;
  };

  async function waitFor(check, timeoutMs = 15000) {
    const start = Date.now();
    for (;;) {
      const value = await check();
      if (value) return value;
      if (Date.now() - start > timeoutMs) throw new Error('timeout');
      await new Promise((r) => setTimeout(r, 300));
    }
  }

  async function newClient({ signedIn = true } = {}) {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `manual-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, `http://localhost:${AUTH_PORT}`, { disableWarnings: true });
    const cred = signedIn ? await signInAnonymously(auth) : null;
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = httpsCallable(functions, 'addManualEntry');
    const joinCall = httpsCallable(functions, 'joinQueue');
    return {
      uid: cred?.user.uid,
      add: async (data) => (await call(data)).data,
      join: async (data) => (await joinCall(data)).data,
    };
  }

  async function seed(owner, operator, metaPatch = {}) {
    await adminDb((db) =>
      set(ref(db), {
        owners: { [QUEUE]: { ownerUid: owner.uid }, closed: { ownerUid: owner.uid } },
        queues: {
          [QUEUE]: {
            meta: { name: 'Balcão', status: 'open', serving: 0, updatedAt: 0, ...metaPatch },
            operatorUids: { [operator.uid]: true },
          },
          closed: { meta: { name: 'Fechada', status: 'closed', serving: 0, updatedAt: 0 } },
        },
      }),
    );
  }

  const readEntry = (id) =>
    adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/entries/${id}`))).val());

  async function rejects(promise, code, reason) {
    await assert.rejects(promise, (err) => {
      assert.equal(err.code, `functions/${code}`);
      if (reason) assert.equal(err.details?.reason, reason);
      return true;
    });
  }

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await Promise.all(apps.map((a) => deleteApp(a)));
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearDatabase();
    await env.clearFirestore();
  });

  it('dono adiciona: entry manual sem uid e public espelhado', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    const res = await owner.add({ queueId: QUEUE, name: ' Dona Maria ', phone: '(11) 91234-5678' });
    assert.equal(res.ticket, 1);
    const entry = await readEntry(res.entryId);
    assert.equal(entry.manual, true);
    assert.equal(entry.name, 'Dona Maria');
    assert.equal(entry.status, 'waiting');
    assert.equal('uid' in entry, false);
    assert.equal('fcmToken' in entry, false);
    const pub = await waitFor(() =>
      adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/public/${res.entryId}`))).val()),
    );
    assert.deepEqual(Object.keys(pub).sort(), ['order', 'status', 'ticket']);
  });

  it('operador aprovado adiciona e o ticket é sequencial', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    const a = await operator.add({ queueId: QUEUE, name: 'Ana' });
    const b = await owner.add({ queueId: QUEUE, name: 'Bia', phone: '' });
    assert.equal(a.ticket, 1);
    assert.equal(b.ticket, 2);
  });

  it('estranho e operador removido são negados', async () => {
    const owner = await newClient();
    const operator = await newClient();
    const stranger = await newClient();
    await seed(owner, operator);
    await rejects(stranger.add({ queueId: QUEUE, name: 'Ana' }), 'permission-denied');
    await adminDb((db) => set(ref(db, `queues/${QUEUE}/operatorUids/${operator.uid}`), null));
    await rejects(operator.add({ queueId: QUEUE, name: 'Ana' }), 'permission-denied');
  });

  it('fila fechada é negada para quem tem permissão', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    await rejects(owner.add({ queueId: 'closed', name: 'Ana' }), 'failed-precondition');
  });

  it('rejeita nome e telefone inválidos', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    await rejects(owner.add({ queueId: QUEUE, name: '   ' }), 'invalid-argument');
    await rejects(owner.add({ queueId: QUEUE, name: 'a'.repeat(61) }), 'invalid-argument');
    await rejects(owner.add({ queueId: QUEUE, name: 'Ana', phone: '11912345678' }), 'invalid-argument');
  });

  it('respeita o limite da fila', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator, { maxWaiting: 2 });
    await owner.add({ queueId: QUEUE, name: 'Ana' });
    await owner.add({ queueId: QUEUE, name: 'Bia' });
    await rejects(owner.add({ queueId: QUEUE, name: 'Caio' }), 'resource-exhausted', 'queue-full');
  });

  it('em fila por horário exige slot válido e respeita a capacidade', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator, {
      mode: 'schedule',
      slots: { late: { start: '23:59', capacity: 1 } },
    });
    await rejects(owner.add({ queueId: QUEUE, name: 'Ana' }), 'invalid-argument', 'slot-required');
    await rejects(owner.add({ queueId: QUEUE, name: 'Ana', slotId: 'nope' }), 'invalid-argument', 'slot-invalid');
    const res = await owner.add({ queueId: QUEUE, name: 'Ana', slotId: 'late' });
    const entry = await readEntry(res.entryId);
    assert.equal(entry.slotId, 'late');
    assert.equal(entry.manual, true);
    await rejects(owner.add({ queueId: QUEUE, name: 'Bia', slotId: 'late' }), 'resource-exhausted', 'slot-full');
  });

  it('sem login retorna unauthenticated', async () => {
    const anon = await newClient({ signedIn: false });
    await rejects(anon.add({ queueId: QUEUE, name: 'Ana' }), 'unauthenticated');
  });

  it('queueId malicioso é invalid-argument e não escreve nada', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    for (const queueId of ['a/b', '..', '.', 'a.b', 'a#b', 'a$b', 'a[b', '']) {
      await rejects(owner.add({ queueId, name: 'Ana' }), 'invalid-argument');
    }
    const tickets = await adminDb(async (db) => (await get(ref(db, 'tickets'))).val());
    assert.equal(tickets, null);
    const rate = await adminDb(async (db) => (await get(ref(db, 'rateLimits'))).val());
    assert.equal(rate, null);
  });

  it('cliente da web que entrou pela fila recebe permission-denied', async () => {
    const owner = await newClient();
    const operator = await newClient();
    const web = await newClient();
    await seed(owner, operator);
    await web.join({ queueId: QUEUE, name: 'Web', phone: '' });
    await rejects(web.add({ queueId: QUEUE, name: 'Ana' }), 'permission-denied');
  });

  it('recusa telefone já ativo, inclusive de cliente que entrou pela web', async () => {
    const owner = await newClient();
    const operator = await newClient();
    const web = await newClient();
    await seed(owner, operator);
    await web.join({ queueId: QUEUE, name: 'Web', phone: '(11) 3333-4444' });
    await rejects(owner.add({ queueId: QUEUE, name: 'Ana', phone: '(11) 3333-4444' }), 'already-exists');
    await owner.add({ queueId: QUEUE, name: 'Bia', phone: '(11) 95555-6666' });
    await rejects(operator.add({ queueId: QUEUE, name: 'Bia 2', phone: '(11) 95555-6666' }), 'already-exists');
  });

  it('telefone liberado quando a entry deixa de estar ativa', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    const first = await owner.add({ queueId: QUEUE, name: 'Ana', phone: '(11) 3333-4444' });
    await adminDb((db) => update(ref(db, `queues/${QUEUE}/entries/${first.entryId}`), { status: 'served' }));
    const again = await owner.add({ queueId: QUEUE, name: 'Ana', phone: '(11) 3333-4444' });
    assert.ok(again.entryId);
  });

  it('a 31a adição em 10 minutos retorna rate-limited', async () => {
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    for (let i = 0; i < 30; i += 1) {
      await owner.add({ queueId: QUEUE, name: `P${i}` });
    }
    await rejects(owner.add({ queueId: QUEUE, name: 'Extra' }), 'resource-exhausted', 'rate-limited');
    const op = await operator.add({ queueId: QUEUE, name: 'Outro operador' });
    assert.equal(op.ticket, 31);
  });

  it('teto absoluto de entries ativas sem maxWaiting', async () => {
    const ceiling = Number(process.env.MANUAL_MAX_ACTIVE_ENTRIES);
    assert.ok(
      Number.isInteger(ceiling) && ceiling >= 2 && ceiling < 1000,
      'defina MANUAL_MAX_ACTIVE_ENTRIES (ex.: 40) para o emulator de functions',
    );
    const owner = await newClient();
    const operator = await newClient();
    await seed(owner, operator);
    const entries = {};
    for (let i = 0; i < ceiling - 1; i += 1) {
      entries[`e${i}`] = { ticket: i + 1, name: `P${i}`, phone: '', manual: true, status: 'waiting', joinedAt: 1 };
    }
    await adminDb((db) => update(ref(db, `queues/${QUEUE}/entries`), entries));
    const last = await owner.add({ queueId: QUEUE, name: 'Última vaga' });
    assert.equal(last.existing, undefined);
    await rejects(owner.add({ queueId: QUEUE, name: 'Extra' }), 'resource-exhausted', 'queue-full');
  });
});
