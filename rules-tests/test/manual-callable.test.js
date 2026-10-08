import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set } from 'firebase/database';
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

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `manual-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, `http://localhost:${AUTH_PORT}`, { disableWarnings: true });
    const cred = await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = httpsCallable(functions, 'addManualEntry');
    return { uid: cred.user.uid, add: async (data) => (await call(data)).data };
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
});
