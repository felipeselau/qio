import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { get, ref, set } from 'firebase/database';
import { collection, doc, getDoc, getDocs, setDoc, writeBatch } from 'firebase/firestore';
import { getBytes, ref as storageRef, uploadBytes } from 'firebase/storage';
import { setupEnv } from './helpers.js';

const [FUNCTIONS_HOST, FUNCTIONS_PORT] = (process.env.FUNCTIONS_EMULATOR_HOST ?? 'localhost:5001').split(':');

describe('callables deleteQueue e deleteAccount (emulador)', () => {
  let env;
  let apps = [];
  const Q = 'qdel';
  const Q2 = 'qdel2';

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `del-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    const cred = await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    return {
      uid: cred.user.uid,
      deleteQueue: async (queueId) => (await httpsCallable(functions, 'deleteQueue')({ queueId })).data,
      deleteAccount: async () => (await httpsCallable(functions, 'deleteAccount')({})).data,
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

  const fsExists = (path) => inCtx(async (ctx) => (await getDoc(doc(ctx.firestore(), path))).exists());

  const rtdbExists = (path) => inCtx(async (ctx) => (await get(ref(ctx.database(), path))).exists());

  const countHistory = (queueId) =>
    inCtx(async (ctx) => (await getDocs(collection(ctx.firestore(), 'queues', queueId, 'history'))).size);

  const logoExists = (queueId) =>
    inCtx(async (ctx) => {
      try {
        await getBytes(storageRef(ctx.storage('gs://demo-qio.appspot.com'), `queue-logos/${queueId}/logo.jpg`));
        return true;
      } catch (_) {
        return false;
      }
    });

  async function seedQueue(queueId, ownerId, historyCount) {
    await inCtx(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'queues', queueId), {
        ownerId,
        name: 'Balcão',
        status: 'open',
        operatorInviteCode: `INV${queueId}`,
      });
      await setDoc(doc(fs, 'operatorInvites', `INV${queueId}`), { ownerId, queueId });
      await setDoc(doc(fs, 'queues', queueId, 'operators', 'op1'), { uid: 'op1' });
      await setDoc(doc(fs, 'queues', queueId, 'feedback', 'f1'), { rating: 5 });
      for (let start = 0; start < historyCount; start += 400) {
        const batch = writeBatch(fs);
        for (let i = start; i < Math.min(start + 400, historyCount); i += 1) {
          batch.set(doc(fs, 'queues', queueId, 'history', `h${i}`), { ticket: i, result: 'served' });
        }
        await batch.commit();
      }
      const db = ctx.database();
      await set(ref(db, `queues/${queueId}`), {
        meta: { name: 'Balcão', status: 'open', serving: 0, updatedAt: 0 },
        entries: { e1: { ticket: 1, name: 'Ana', phone: '', uid: 'c1', status: 'waiting' } },
        public: { e1: { ticket: 1, status: 'waiting' } },
        operatorUids: { op1: true },
      });
      await set(ref(db, `owners/${queueId}`), { ownerUid: ownerId });
      await set(ref(db, `tickets/${queueId}`), 1);
      await set(ref(db, `rateLimits/${queueId}/c1`), [1]);
      await uploadBytes(storageRef(ctx.storage('gs://demo-qio.appspot.com'), `queue-logos/${queueId}/logo.jpg`), new Uint8Array([1, 2, 3]), {
        contentType: 'image/jpeg',
      });
    });
  }

  async function expectQueueGone(queueId) {
    assert.equal(await fsExists(`queues/${queueId}`), false);
    assert.equal(await countHistory(queueId), 0);
    assert.equal(await fsExists(`queues/${queueId}/feedback/f1`), false);
    assert.equal(await fsExists(`queues/${queueId}/operators/op1`), false);
    assert.equal(await fsExists(`operatorInvites/INV${queueId}`), false);
    assert.equal(await rtdbExists(`queues/${queueId}`), false);
    assert.equal(await rtdbExists(`owners/${queueId}`), false);
    assert.equal(await rtdbExists(`tickets/${queueId}`), false);
    assert.equal(await rtdbExists(`rateLimits/${queueId}`), false);
    assert.equal(await logoExists(queueId), false);
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
    await env.clearStorage();
  });

  it('apaga fila com mais de 500 docs de history sem deixar órfãos', async () => {
    const owner = await newClient();
    await seedQueue(Q, owner.uid, 650);
    assert.equal(await countHistory(Q), 650);
    assert.equal(await logoExists(Q), true);
    const res = await owner.deleteQueue(Q);
    assert.equal(res.ok, true);
    await expectQueueGone(Q);
  });

  it('é idempotente: repetir a chamada depois de apagada não falha', async () => {
    const owner = await newClient();
    await seedQueue(Q, owner.uid, 3);
    await owner.deleteQueue(Q);
    const res = await owner.deleteQueue(Q);
    assert.equal(res.alreadyGone, true);
  });

  it('recusa quem não é dono e não apaga nada', async () => {
    const owner = await newClient();
    const stranger = await newClient();
    await seedQueue(Q, owner.uid, 3);
    await rejects(stranger.deleteQueue(Q), 'permission-denied');
    assert.equal(await fsExists(`queues/${Q}`), true);
    assert.equal(await rtdbExists(`queues/${Q}/meta`), true);
  });

  it('recusa id inválido', async () => {
    const owner = await newClient();
    await rejects(owner.deleteQueue('a/b'), 'invalid-argument');
    await rejects(owner.deleteQueue(''), 'invalid-argument');
  });

  it('deleteAccount apaga filas, dados do dono e vínculos de operador em filas alheias', async () => {
    const owner = await newClient();
    await seedQueue(Q, owner.uid, 5);
    await seedQueue(Q2, 'outro-dono', 2);
    await inCtx(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'owners', owner.uid), { name: 'Dono' });
      await setDoc(doc(fs, 'owners', owner.uid, 'devices', 'tok'), { token: 'tok' });
      await setDoc(doc(fs, 'owners', owner.uid, 'groups', 'g1'), { name: 'Grupo' });
      await setDoc(doc(fs, 'queues', Q2, 'operators', owner.uid), { uid: owner.uid });
      await setDoc(doc(fs, 'queues', Q2, 'operatorRequests', owner.uid), { uid: owner.uid, status: 'approved' });
      await set(ref(ctx.database(), `queues/${Q2}/operatorUids/${owner.uid}`), true);
    });
    const res = await owner.deleteAccount();
    assert.equal(res.ok, true);
    await expectQueueGone(Q);
    assert.equal(await fsExists(`owners/${owner.uid}`), false);
    assert.equal(await fsExists(`owners/${owner.uid}/devices/tok`), false);
    assert.equal(await fsExists(`owners/${owner.uid}/groups/g1`), false);
    assert.equal(await fsExists(`queues/${Q2}/operators/${owner.uid}`), false);
    assert.equal(await fsExists(`queues/${Q2}/operatorRequests/${owner.uid}`), false);
    assert.equal(await rtdbExists(`queues/${Q2}/operatorUids/${owner.uid}`), false);
    assert.equal(await fsExists(`queues/${Q2}`), true);
    assert.equal(await rtdbExists(`queues/${Q2}/meta`), true);
    assert.equal(await fsExists(`queues/${Q2}/operators/op1`), true);
  });
});
