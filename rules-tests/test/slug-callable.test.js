import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { doc, setDoc } from 'firebase/firestore';
import { setupEnv } from './helpers.js';

const [FUNCTIONS_HOST, FUNCTIONS_PORT] = (process.env.FUNCTIONS_EMULATOR_HOST ?? 'localhost:5001').split(':');

describe('callable resolveSlug (emulador)', () => {
  let env;
  const apps = [];

  async function newClient() {
    const app = initializeApp({ projectId: 'demo-qio', apiKey: 'fake-key' }, `slug-${apps.length}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    await signInAnonymously(auth);
    const functions = getFunctions(app);
    connectFunctionsEmulator(functions, FUNCTIONS_HOST, Number(FUNCTIONS_PORT));
    return async (slug) => (await httpsCallable(functions, 'resolveSlug')({ slug })).data;
  }

  async function rejects(promise, code) {
    await assert.rejects(promise, (err) => {
      assert.equal(err.code, `functions/${code}`);
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
    await env.clearFirestore();
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'queueSlugs', 'padaria'), { queueId: 'qpad', ownerId: 'o1' }),
    );
  });

  it('resolve o slug para o queueId', async () => {
    const resolve = await newClient();
    assert.deepEqual(await resolve('padaria'), { queueId: 'qpad' });
  });

  it('normaliza maiúsculas e espaços', async () => {
    const resolve = await newClient();
    assert.deepEqual(await resolve('  Padaria '), { queueId: 'qpad' });
  });

  it('slug inexistente responde not-found', async () => {
    const resolve = await newClient();
    await rejects(resolve('nao-existe'), 'not-found');
  });

  it('slug inválido ou reservado responde not-found sem consultar', async () => {
    const resolve = await newClient();
    for (const bad of ['', 'ab', 'admin', '../x', 'a/b', null, 42]) {
      await rejects(resolve(bad), 'not-found');
    }
  });
});
