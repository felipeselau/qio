import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set } from 'firebase/database';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { setupEnv } from './helpers.js';

const [FUNCTIONS_HOST, FUNCTIONS_PORT] = (process.env.FUNCTIONS_EMULATOR_HOST ?? 'localhost:5001').split(':');
const AUTH_PORT = process.env.AUTH_EMULATOR_PORT ?? '9099';

describe('callables de direitos do titular (emulador)', () => {
  let env;
  let apps = [];
  const MASKED = '(11) 99999-9999';
  const DIGITS = '11999999999';

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `dsr-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, `http://localhost:${AUTH_PORT}`, { disableWarnings: true });
    const cred = await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    const call = async (name, data) => (await httpsCallable(functions, name)(data)).data;
    return {
      uid: cred.user.uid,
      find: (data) => call('findCustomerData', data),
      exportData: (data) => call('exportCustomerData', data),
      erase: (data) => call('eraseCustomerData', data),
    };
  }

  async function rejects(promise, code) {
    await assert.rejects(promise, (err) => {
      assert.equal(err.code, `functions/${code}`);
      return true;
    });
  }

  const inCtx = (fn) =>
    new Promise((resolve, reject) =>
      env.withSecurityRulesDisabled(async (ctx) => {
        try {
          resolve(await fn(ctx));
        } catch (err) {
          reject(err);
        }
      }),
    );

  const hist = (queueId, id) =>
    inCtx(async (ctx) => {
      const snap = await getDoc(doc(ctx.firestore(), 'queues', queueId, 'history', id));
      return snap.exists() ? snap.data() : null;
    });

  const feedback = (queueId, id) =>
    inCtx(async (ctx) => {
      const snap = await getDoc(doc(ctx.firestore(), 'queues', queueId, 'feedback', id));
      return snap.exists() ? snap.data() : null;
    });

  const rtdb = (path) => inCtx(async (ctx) => (await get(ref(ctx.database(), path))).val());

  const logs = (uid) =>
    inCtx(async (ctx) => {
      const snap = await getDocs(collection(ctx.firestore(), 'owners', uid, 'dataRequests'));
      return snap.docs.map((d) => d.data());
    });

  async function seed(ownerA, ownerB) {
    await inCtx(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'queues', 'qa1'), { ownerId: ownerA, name: 'Balcão' });
      await setDoc(doc(fs, 'queues', 'qa2'), { ownerId: ownerA, name: 'Caixa' });
      await setDoc(doc(fs, 'queues', 'qb1'), { ownerId: ownerB, name: 'Alheia' });
      const h = (name, phone) => ({ ticket: 1, name, phone, result: 'served', joinedAt: 1, finishedAt: 2 });
      await setDoc(doc(fs, 'queues', 'qa1', 'history', 'h1'), h('Ana', MASKED));
      await setDoc(doc(fs, 'queues', 'qa1', 'history', 'h2'), h('Bia', '(11) 88888-8888'));
      await setDoc(doc(fs, 'queues', 'qa2', 'history', 'h3'), h('Ana', DIGITS));
      await setDoc(doc(fs, 'queues', 'qb1', 'history', 'h4'), h('Ana', MASKED));
      await setDoc(doc(fs, 'queues', 'qa1', 'feedback', 'h1'), { rating: 5, comment: 'top', uid: 'c1' });
      await setDoc(doc(fs, 'queues', 'qb1', 'feedback', 'h4'), { rating: 3, comment: 'ok', uid: 'c2' });
      const db = ctx.database();
      await set(ref(db, 'queues/qa1/entries/e1'), { ticket: 5, name: 'Ana', phone: MASKED, uid: 'c1', status: 'waiting' });
      await set(ref(db, 'queues/qa1/public/e1'), { ticket: 5, status: 'waiting' });
      await set(ref(db, 'queues/qa1/entries/e2'), { ticket: 6, name: 'Bia', phone: '(11) 88888-8888', uid: 'c3', status: 'waiting' });
      await set(ref(db, 'queues/qb1/entries/e3'), { ticket: 1, name: 'Ana', phone: MASKED, uid: 'c4', status: 'waiting' });
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
    await env.clearFirestore();
    await env.clearDatabase();
  });

  it('find lista contagens só das filas do dono, nas duas formas de telefone', async () => {
    const owner = await newClient();
    await seed(owner.uid, 'outro-dono');
    const res = await owner.find({ phone: '(11) 99999-9999' });
    assert.deepEqual(
      res.queues.map((q) => [q.queueId, q.history, q.feedback, q.entries]),
      [
        ['qa1', 1, 1, 1],
        ['qa2', 1, 0, 0],
      ],
    );
    assert.deepEqual(res.totals, { history: 2, feedback: 1, entries: 1 });
    assert.ok(!JSON.stringify(res).includes('Ana'));
    const written = await logs(owner.uid);
    assert.equal(written.length, 1);
    assert.equal(written[0].action, 'find');
    assert.ok(!JSON.stringify(written).includes(DIGITS));
  });

  it('exporta registros do titular com avaliação', async () => {
    const owner = await newClient();
    await seed(owner.uid, 'outro-dono');
    const res = await owner.exportData({ phone: DIGITS });
    assert.equal(res.records.length, 3);
    const withRating = res.records.find((r) => r.rating === 5);
    assert.equal(withRating.comment, 'top');
    assert.ok(res.csv.includes('Ana'));
  });

  it('erase delete apaga só o telefone nas filas do dono e preserva fila alheia', async () => {
    const owner = await newClient();
    await seed(owner.uid, 'outro-dono');
    const res = await owner.erase({ phone: MASKED, mode: 'delete' });
    assert.equal(res.complete, true);
    assert.deepEqual(res.totals, { history: 2, feedback: 1, entries: 1 });
    assert.equal(await hist('qa1', 'h1'), null);
    assert.equal(await hist('qa2', 'h3'), null);
    assert.notEqual(await hist('qa1', 'h2'), null);
    assert.notEqual(await hist('qb1', 'h4'), null);
    assert.equal(await feedback('qa1', 'h1'), null);
    assert.notEqual(await feedback('qb1', 'h4'), null);
    assert.equal(await rtdb('queues/qa1/entries/e1'), null);
    assert.equal(await rtdb('queues/qa1/public/e1'), null);
    assert.notEqual(await rtdb('queues/qa1/entries/e2'), null);
    assert.notEqual(await rtdb('queues/qb1/entries/e3'), null);
    const written = await logs(owner.uid);
    assert.equal(written.length, 1);
    assert.equal(written[0].mode, 'delete');
    assert.ok(!JSON.stringify(written).includes('Ana'));
  });

  it('erase anonymize troca nome/telefone e limpa o comentário', async () => {
    const owner = await newClient();
    await seed(owner.uid, 'outro-dono');
    await owner.erase({ phone: DIGITS, mode: 'anonymize' });
    const h1 = await hist('qa1', 'h1');
    assert.equal(h1.name, 'Anônimo');
    assert.equal(h1.phone, null);
    const fb = await feedback('qa1', 'h1');
    assert.equal(fb.comment, '');
    assert.equal(fb.rating, 5);
    assert.equal((await hist('qb1', 'h4')).name, 'Ana');
    const again = await owner.find({ phone: DIGITS });
    assert.deepEqual(again.totals, { history: 0, feedback: 0, entries: 0 });
  });

  it('outro dono não alcança dados que não são dele', async () => {
    const owner = await newClient();
    const stranger = await newClient();
    await seed(owner.uid, 'outro-dono');
    const res = await stranger.erase({ phone: MASKED, mode: 'delete' });
    assert.deepEqual(res.totals, { history: 0, feedback: 0, entries: 0 });
    assert.notEqual(await hist('qa1', 'h1'), null);
    assert.notEqual(await hist('qb1', 'h4'), null);
  });

  it('valida telefone, modo e autenticação', async () => {
    const owner = await newClient();
    for (const bad of ['', '123', 'abc', null, 5, '119999999999']) {
      await rejects(owner.find({ phone: bad }), 'invalid-argument');
      await rejects(owner.erase({ phone: bad, mode: 'delete' }), 'invalid-argument');
    }
    await rejects(owner.erase({ phone: DIGITS, mode: 'tudo' }), 'invalid-argument');
    await rejects(owner.erase({ phone: DIGITS }), 'invalid-argument');
  });

  it('limita a 20 consultas por hora por uid', async () => {
    const owner = await newClient();
    for (let i = 0; i < 20; i += 1) {
      await owner.find({ phone: DIGITS });
    }
    await rejects(owner.find({ phone: DIGITS }), 'resource-exhausted');
    const other = await newClient();
    await other.find({ phone: DIGITS });
  });

  it('recusa chamada sem autenticação', async () => {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `dsr-anon-${apps.length}`);
    apps.push(app);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    await rejects(httpsCallable(functions, 'findCustomerData')({ phone: DIGITS }), 'unauthenticated');
    await rejects(httpsCallable(functions, 'eraseCustomerData')({ phone: DIGITS, mode: 'delete' }), 'unauthenticated');
  });

  it('exige login recente (auth_time antigo) e não toca nos dados', async () => {
    const owner = await newClient();
    await seed(owner.uid, 'outro-dono');
    const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
    const old = Math.floor(Date.now() / 1000) - 3600;
    const token = [
      b64({ alg: 'none', typ: 'JWT' }),
      b64({
        iss: 'https://securetoken.google.com/demo-qio',
        aud: 'demo-qio',
        auth_time: old,
        iat: old,
        exp: old + 7200,
        user_id: owner.uid,
        sub: owner.uid,
        firebase: { sign_in_provider: 'password', identities: {} },
      }),
      '',
    ].join('.');
    const call = async (name, data) => {
      const res = await fetch(`http://${FUNCTIONS_HOST}:${FUNCTIONS_PORT}/demo-qio/us-central1/${name}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ data }),
      });
      return res.json();
    };
    const res = await call('eraseCustomerData', { phone: DIGITS, mode: 'delete' });
    assert.equal(res.error?.status, 'FAILED_PRECONDITION');
    assert.equal(res.error?.details?.reason, 'recent-login');
    const find = await call('findCustomerData', { phone: DIGITS });
    assert.equal(find.error?.details?.reason, 'recent-login');
    assert.notEqual(await hist('qa1', 'h1'), null);
  });
});
