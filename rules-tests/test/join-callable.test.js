import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set, update } from 'firebase/database';
import { QUEUE, setupEnv } from './helpers.js';

const [FUNCTIONS_HOST, FUNCTIONS_PORT] = (process.env.FUNCTIONS_EMULATOR_HOST ?? 'localhost:5001').split(':');

describe('callable joinQueue (emulador)', () => {
  let env;
  let apps = [];
  const adminDb = async (fn) => {
    let result;
    await env.withSecurityRulesDisabled(async (ctx) => {
      result = await fn(ctx.database());
    });
    return result;
  };

  async function newClient(name) {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `${name}-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    const cred = await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = httpsCallable(functions, 'joinQueue');
    return { uid: cred.user.uid, join: async (data) => (await call(data)).data };
  }

  async function rejects(promise, code) {
    await assert.rejects(promise, (err) => {
      assert.equal(err.code, `functions/${code}`);
      return true;
    });
  }

  async function waitFor(check, timeoutMs = 15000) {
    const start = Date.now();
    for (;;) {
      const value = await check();
      if (value) return value;
      if (Date.now() - start > timeoutMs) throw new Error('timeout');
      await new Promise((r) => setTimeout(r, 300));
    }
  }

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearDatabase();
    await adminDb((db) =>
      set(ref(db), {
        owners: { [QUEUE]: { ownerUid: 'owner' } },
        queues: {
          [QUEUE]: { meta: { name: 'Balcão', status: 'open', serving: 0, updatedAt: 0 } },
          closed: { meta: { name: 'Fechada', status: 'closed', serving: 0, updatedAt: 0 } },
        },
      }),
    );
  });

  after(async () => {
    await Promise.all(apps.map((a) => deleteApp(a)));
  });

  it('entra na fila e o trigger cria o nó public sem PII', async () => {
    const c = await newClient('a');
    const res = await c.join({ queueId: QUEUE, name: ' Ana ', phone: '(11) 91234-5678' });
    assert.equal(res.existing, false);
    assert.equal(res.ticket, 1);
    const entry = await waitFor(() =>
      adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/entries/${res.entryId}`))).val()),
    );
    assert.equal(entry.name, 'Ana');
    assert.equal(entry.uid, c.uid);
    assert.equal(entry.status, 'waiting');
    const pub = await waitFor(() =>
      adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/public/${res.entryId}`))).val()),
    );
    assert.deepEqual(pub, { ticket: 1, status: 'waiting' });
  });

  it('segundo join do mesmo uid devolve a mesma entry', async () => {
    const c = await newClient('b');
    const first = await c.join({ queueId: QUEUE, name: 'Bia', phone: '' });
    const second = await c.join({ queueId: QUEUE, name: 'Bia', phone: '' });
    assert.equal(second.existing, true);
    assert.equal(second.entryId, first.entryId);
    assert.equal(second.ticket, first.ticket);
  });

  it('rejeita telefone já presente na fila', async () => {
    const a = await newClient('c');
    const b = await newClient('d');
    await a.join({ queueId: QUEUE, name: 'Caio', phone: '(11) 3333-4444' });
    await rejects(b.join({ queueId: QUEUE, name: 'Duda', phone: '(11) 3333-4444' }), 'already-exists');
  });

  it('rejeita telefone e nome inválidos', async () => {
    const c = await newClient('e');
    await rejects(c.join({ queueId: QUEUE, name: 'Eva', phone: '11912345678' }), 'invalid-argument');
    await rejects(c.join({ queueId: QUEUE, name: '   ', phone: '' }), 'invalid-argument');
    await rejects(c.join({ queueId: QUEUE, name: 'a'.repeat(61), phone: '' }), 'invalid-argument');
  });

  it('rejeita fila fechada e inexistente', async () => {
    const c = await newClient('f');
    await rejects(c.join({ queueId: 'closed', name: 'Fábio', phone: '' }), 'failed-precondition');
    await rejects(c.join({ queueId: 'nope', name: 'Fábio', phone: '' }), 'not-found');
  });

  it('bloqueia o 4o join em 10 minutos', async () => {
    const c = await newClient('g');
    for (let i = 0; i < 3; i += 1) {
      const res = await c.join({ queueId: QUEUE, name: 'Gui', phone: '' });
      assert.equal(res.existing, false);
      await adminDb((db) => update(ref(db, `queues/${QUEUE}/entries/${res.entryId}`), { status: 'left' }));
    }
    await rejects(c.join({ queueId: QUEUE, name: 'Gui', phone: '' }), 'resource-exhausted');
  });
});
