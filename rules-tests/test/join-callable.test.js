import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set, update } from 'firebase/database';
import { doc, getDoc, setDoc } from 'firebase/firestore';
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
    const feedbackCall = httpsCallable(functions, 'submitFeedback');
    return {
      uid: cred.user.uid,
      join: async (data) => (await call(data)).data,
      feedback: async (data) => (await feedbackCall(data)).data,
    };
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

  async function leaveAndWait(c, entryId) {
    await update(ref(env.authenticatedContext(c.uid).database(), `queues/${QUEUE}/entries/${entryId}`), {
      status: 'left',
    });
    await waitFor(() =>
      adminDb(async (db) => !(await get(ref(db, `queues/${QUEUE}/entries/${entryId}`))).exists()),
    );
  }

  const history = async (entryId) => {
    let data = null;
    await env.withSecurityRulesDisabled(async (ctx) => {
      const snap = await getDoc(doc(ctx.firestore(), 'queues', QUEUE, 'history', entryId));
      data = snap.exists() ? snap.data() : null;
    });
    return data;
  };

  it('cliente marca left: entry e public somem do RTDB e history result left é criado', async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'queues', QUEUE), { ownerId: 'owner', name: 'Balcão', status: 'open' });
    });
    const c = await newClient('h');
    const res = await c.join({ queueId: QUEUE, name: 'Hugo', phone: '(11) 91234-5678' });
    await waitFor(() =>
      adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/public/${res.entryId}`))).exists()),
    );
    await leaveAndWait(c, res.entryId);
    const pubGone = await waitFor(() =>
      adminDb(async (db) => !(await get(ref(db, `queues/${QUEUE}/public/${res.entryId}`))).exists()),
    );
    assert.equal(pubGone, true);
    const hist = await waitFor(() => history(res.entryId));
    assert.equal(hist.result, 'left');
    assert.equal(hist.ticket, res.ticket);
    assert.equal(hist.name, 'Hugo');
    assert.equal(hist.phone, '(11) 91234-5678');
    assert.equal(hist.calledAt, null);
    assert.equal(hist.calledBy, null);
    assert.equal(hist.operatorId, null);
    assert.ok(hist.joinedAt.toMillis() > 0);
    assert.ok(hist.finishedAt.toMillis() >= hist.joinedAt.toMillis());
  });

  it('left sem doc da fila no Firestore remove a entry e não cria history', async () => {
    await env.clearFirestore();
    const c = await newClient('i');
    const res = await c.join({ queueId: QUEUE, name: 'Iris', phone: '' });
    await waitFor(() =>
      adminDb(async (db) => (await get(ref(db, `queues/${QUEUE}/public/${res.entryId}`))).exists()),
    );
    await leaveAndWait(c, res.entryId);
    assert.equal(await history(res.entryId), null);
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


describe('callable joinQueue com limite (emulador)', () => {
  let env;
  let apps = [];
  const adminDb = async (fn) => {
    let result;
    await env.withSecurityRulesDisabled(async (ctx) => {
      result = await fn(ctx.database());
    });
    return result;
  };

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `cap-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = httpsCallable(functions, 'joinQueue');
    return async (data) => (await call(data)).data;
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
    await adminDb((db) =>
      set(ref(db), {
        owners: { [QUEUE]: { ownerUid: 'owner' } },
        queues: {
          [QUEUE]: { meta: { name: 'Balcão', status: 'open', serving: 0, updatedAt: 0, maxWaiting: 2 } },
        },
      }),
    );
  });

  it('recusa com queue-full quando a fila atinge o limite', async () => {
    const a = await newClient();
    const b = await newClient();
    const c = await newClient();
    await a({ queueId: QUEUE, name: 'Ana', phone: '' });
    await b({ queueId: QUEUE, name: 'Bia', phone: '' });
    await assert.rejects(c({ queueId: QUEUE, name: 'Caio', phone: '' }), (err) => {
      assert.equal(err.code, 'functions/resource-exhausted');
      assert.equal(err.details?.reason, 'queue-full');
      return true;
    });
  });

  it('quem já está na fila continua recebendo a própria entrada', async () => {
    const a = await newClient();
    const b = await newClient();
    await a({ queueId: QUEUE, name: 'Ana', phone: '' });
    await b({ queueId: QUEUE, name: 'Bia', phone: '' });
    const again = await a({ queueId: QUEUE, name: 'Ana', phone: '' });
    assert.equal(again.existing, true);
  });

  it('libera vaga quando alguém sai', async () => {
    const a = await newClient();
    const b = await newClient();
    const c = await newClient();
    const first = await a({ queueId: QUEUE, name: 'Ana', phone: '' });
    await b({ queueId: QUEUE, name: 'Bia', phone: '' });
    await adminDb((db) => update(ref(db, `queues/${QUEUE}/entries/${first.entryId}`), { status: 'served' }));
    const res = await c({ queueId: QUEUE, name: 'Caio', phone: '' });
    assert.equal(res.existing, false);
  });

  it('sem limite configurado não recusa', async () => {
    await adminDb((db) => set(ref(db, `queues/${QUEUE}/meta/maxWaiting`), 0));
    const clients = await Promise.all([newClient(), newClient(), newClient()]);
    for (const [i, c] of clients.entries()) {
      await c({ queueId: QUEUE, name: `P${i}`, phone: '' });
    }
  });
});


describe('callable submitFeedback (emulador)', () => {
  let env;
  let apps = [];

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `fb-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = httpsCallable(functions, 'submitFeedback');
    return async (data) => (await call(data)).data;
  }

  async function rejects(promise, code) {
    await assert.rejects(promise, (err) => {
      assert.equal(err.code, `functions/${code}`);
      return true;
    });
  }

  const readFeedback = (id) =>
    new Promise((resolve) =>
      env.withSecurityRulesDisabled(async (ctx) => {
        const snap = await getDoc(doc(ctx.firestore(), 'queues', QUEUE, 'feedback', id));
        resolve(snap.exists() ? snap.data() : null);
      }),
    );

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await Promise.all(apps.map((a) => deleteApp(a)));
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'queues', QUEUE), { ownerId: 'owner', name: 'Balcão', status: 'open' });
      await setDoc(doc(fs, 'queues', QUEUE, 'history', 'served1'), { ticket: 1, name: 'Ana', result: 'served' });
      await setDoc(doc(fs, 'queues', QUEUE, 'history', 'noshow1'), { ticket: 2, name: 'Bia', result: 'no_show' });
    });
  });

  it('grava a avaliação de um atendimento concluído', async () => {
    const send = await newClient();
    const res = await send({ queueId: QUEUE, entryId: 'served1', rating: 4, comment: ' ótimo ' });
    assert.equal(res.existing, false);
    const saved = await readFeedback('served1');
    assert.equal(saved.rating, 4);
    assert.equal(saved.comment, 'ótimo');
  });

  it('segunda avaliação não sobrescreve a primeira', async () => {
    const send = await newClient();
    await send({ queueId: QUEUE, entryId: 'served1', rating: 5 });
    const res = await send({ queueId: QUEUE, entryId: 'served1', rating: 1 });
    assert.equal(res.existing, true);
    assert.equal((await readFeedback('served1')).rating, 5);
  });

  it('recusa nota fora de 1-5', async () => {
    const send = await newClient();
    await rejects(send({ queueId: QUEUE, entryId: 'served1', rating: 6 }), 'invalid-argument');
    await rejects(send({ queueId: QUEUE, entryId: 'served1', rating: 0 }), 'invalid-argument');
  });

  it('recusa comentário longo demais', async () => {
    const send = await newClient();
    await rejects(
      send({ queueId: QUEUE, entryId: 'served1', rating: 3, comment: 'a'.repeat(301) }),
      'invalid-argument',
    );
  });

  it('recusa atendimento inexistente ou não concluído', async () => {
    const send = await newClient();
    await rejects(send({ queueId: QUEUE, entryId: 'nope', rating: 3 }), 'failed-precondition');
    await rejects(send({ queueId: QUEUE, entryId: 'noshow1', rating: 3 }), 'failed-precondition');
  });
});
