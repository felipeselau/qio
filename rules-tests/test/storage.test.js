import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { doc, setDoc } from 'firebase/firestore';
import { OPERATOR, OWNER, QUEUE, STRANGER, setupEnv } from './helpers.js';

const png = (size = 1024) => new Uint8Array(size).fill(7);
const meta = { contentType: 'image/png' };
const path = (file = 'logo.png') => `queue-logos/${QUEUE}/${file}`;

describe('Storage rules (logos das filas)', () => {
  let env;
  const storage = (uid) => env.authenticatedContext(uid).storage();

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await env.clearStorage();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'queues', QUEUE), { ownerId: OWNER, name: 'Balcão' });
      await setDoc(doc(ctx.firestore(), 'queues', QUEUE, 'operators', OPERATOR), { uid: OPERATOR });
    });
  });

  it('dono envia o logo', async () => {
    await assertSucceeds(uploadBytes(ref(storage(OWNER), path()), png(), meta));
  });

  it('dono aceita jpg e webp', async () => {
    await assertSucceeds(uploadBytes(ref(storage(OWNER), path('logo.jpg')), png(), { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(storage(OWNER), path('logo.webp')), png(), { contentType: 'image/webp' }));
  });

  it('operador e estranho não enviam', async () => {
    await assertFails(uploadBytes(ref(storage(OPERATOR), path()), png(), meta));
    await assertFails(uploadBytes(ref(storage(STRANGER), path()), png(), meta));
  });

  it('visitante sem login não envia', async () => {
    await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), path()), png(), meta));
  });

  it('recusa arquivo grande demais', async () => {
    await assertFails(uploadBytes(ref(storage(OWNER), path()), png(300 * 1024), meta));
  });

  it('recusa tipo que não é imagem permitida', async () => {
    await assertFails(uploadBytes(ref(storage(OWNER), path()), png(), { contentType: 'text/html' }));
    await assertFails(uploadBytes(ref(storage(OWNER), path()), png(), { contentType: 'image/svg+xml' }));
  });

  it('recusa nome de arquivo fora do padrão', async () => {
    await assertFails(uploadBytes(ref(storage(OWNER), path('evil.png')), png(), meta));
  });

  it('o dono de outra fila não escreve nesta', async () => {
    await assertFails(uploadBytes(ref(storage('outroDono'), path()), png(), meta));
  });

  it('qualquer um lê o logo, inclusive sem login', async () => {
    await uploadBytes(ref(storage(OWNER), path()), png(), meta);
    await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), path())));
  });

  it('só o dono remove', async () => {
    await uploadBytes(ref(storage(OWNER), path()), png(), meta);
    await assertFails(deleteObject(ref(storage(STRANGER), path())));
    await assertFails(deleteObject(ref(storage(OPERATOR), path())));
    await assertSucceeds(deleteObject(ref(storage(OWNER), path())));
  });
});
