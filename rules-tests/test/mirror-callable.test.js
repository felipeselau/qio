import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { get, ref, set, update } from 'firebase/database';
import { doc, deleteDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { setupEnv } from './helpers.js';

describe('trigger mirrorQueueToRtdb / mirrorOperatorToRtdb (emulador)', () => {
  let env;
  let seq = 0;
  const newId = () => `mq${Date.now().toString(36)}${seq++}`;

  const rtdb = async (path) => {
    let value;
    await env.withSecurityRulesDisabled(async (ctx) => {
      value = (await get(ref(ctx.database(), path))).val();
    });
    return value;
  };
  const rtdbSet = (path, value) =>
    env.withSecurityRulesDisabled((ctx) => set(ref(ctx.database(), path), value));
  const rtdbUpdate = (path, value) =>
    env.withSecurityRulesDisabled((ctx) => update(ref(ctx.database(), path), value));
  const fs = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

  async function waitFor(check, timeoutMs = 20000) {
    const start = Date.now();
    for (;;) {
      const value = await check();
      if (value) return value;
      if (Date.now() - start > timeoutMs) throw new Error('timeout');
      await new Promise((r) => setTimeout(r, 300));
    }
  }

  async function barrier() {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id), { ownerId: 'barrier', name: 'barrier', status: 'open' }));
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
  }


  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  it('criar fila no Firestore gera owners e meta no RTDB', async () => {
    const id = newId();
    await fs((db) =>
      setDoc(doc(db, 'queues', id), {
        ownerId: 'owner1',
        name: '  Balcão  ',
        description: 'Atendimento',
        status: 'open',
        avgServiceMin: 12,
        maxWaiting: 5,
        brandColor: '#112233',
        createdAt: serverTimestamp(),
      }),
    );
    const meta = await waitFor(() => rtdb(`queues/${id}/meta`));
    assert.equal(meta.name, 'Balcão');
    assert.equal(meta.description, 'Atendimento');
    assert.equal(meta.avgServiceMin, 12);
    assert.equal(meta.maxWaiting, 5);
    assert.equal(meta.status, 'open');
    assert.equal(meta.brandColor, '#112233');
    assert.equal(meta.nextTicket, 0);
    assert.equal(meta.serving, 0);
    assert.equal(typeof meta.updatedAt, 'number');
    assert.deepEqual(await rtdb(`owners/${id}`), { ownerUid: 'owner1' });
  });

  it('editar nome, status e slots atualiza o meta e preserva campos Admin', async () => {
    const id = newId();
    await fs((db) =>
      setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open', avgServiceMin: 10 }),
    );
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await rtdbUpdate(`queues/${id}/meta`, {
      avgServiceMinAuto: 7.5,
      waitingCount: 4,
      serving: 9,
      updatedAt: 12345,
      opensAt: 777,
      nextNotifiedAt: 55,
    });

    await fs((db) =>
      updateDoc(doc(db, 'queues', id), {
        name: 'Novo nome',
        status: 'paused',
        statusMessage: 'Volto já',
        mode: 'schedule',
        slots: [{ id: 's1', start: '09:00', capacity: 2 }],
      }),
    );
    const meta = await waitFor(async () => {
      const m = await rtdb(`queues/${id}/meta`);
      return m?.name === 'Novo nome' ? m : null;
    });
    assert.equal(meta.status, 'paused');
    assert.equal(meta.statusMessage, 'Volto já');
    assert.equal(meta.mode, 'schedule');
    assert.deepEqual(meta.slots, { s1: { start: '09:00', capacity: 2 } });
    assert.equal(meta.avgServiceMinAuto, 7.5);
    assert.equal(meta.waitingCount, 4);
    assert.equal(meta.serving, 9);
    assert.equal(meta.updatedAt, 12345);
    assert.equal(meta.opensAt, 777);
    assert.equal(meta.nextNotifiedAt, 55);
  });

  it('só age nos campos que mudaram: update sem campo espelhado não repara nada', async () => {
    const id = newId();
    await fs((db) =>
      setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open', avgServiceMin: 10 }),
    );
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await rtdbUpdate(`queues/${id}/meta`, { name: 'Adulterado' });
    await fs((db) =>
      updateDoc(doc(db, 'queues', id), { posterTitle: 'x', alertState: { waitAt: 1 }, scheduleLastDesired: 'open' }),
    );
    await fs((db) => updateDoc(doc(db, 'queues', id), { maxWaiting: 7 }));
    await waitFor(async () => (await rtdb(`queues/${id}/meta/maxWaiting`)) === 7);
    assert.equal(await rtdb(`queues/${id}/meta/name`), 'Adulterado');
  });

  it('fila existente sem meta não recria meta num update', async () => {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open' }));
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await rtdbSet(`queues/${id}/meta`, null);
    await fs((db) => updateDoc(doc(db, 'queues', id), { name: 'B' }));
    await barrier();
    assert.equal(await rtdb(`queues/${id}/meta`), null);
  });

  it('repara meta divergente e owners ausente em fila existente', async () => {
    const id = newId();
    await rtdbSet(`queues/${id}/meta`, { name: 'Velho', status: 'open', serving: 3, nextTicket: 3, updatedAt: 1 });
    await fs((db) =>
      setDoc(doc(db, 'queues', id), { ownerId: 'owner2', name: 'Correto', status: 'closed', avgServiceMin: 15 }),
    );
    const meta = await waitFor(async () => {
      const m = await rtdb(`queues/${id}/meta`);
      return m?.name === 'Correto' ? m : null;
    });
    assert.equal(meta.status, 'closed');
    assert.equal(meta.avgServiceMin, 15);
    assert.equal(meta.serving, 3);
    assert.equal(meta.nextTicket, 3);
    assert.deepEqual(await rtdb(`owners/${id}`), { ownerUid: 'owner2' });
  });

  it('apagar o doc não recria meta nem owners', async () => {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open' }));
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await rtdbSet(`queues/${id}`, null);
    await rtdbSet(`owners/${id}`, null);
    await fs((db) => deleteDoc(doc(db, 'queues', id)));
    await barrier();
    assert.equal(await rtdb(`queues/${id}`), null);
    assert.equal(await rtdb(`owners/${id}`), null);
  });

  it('doc com deleting não recria meta apagado', async () => {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open' }));
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await rtdbSet(`queues/${id}/meta`, null);
    await rtdbSet(`owners/${id}`, null);
    await fs((db) => updateDoc(doc(db, 'queues', id), { deleting: true, status: 'closed' }));
    await barrier();
    assert.equal(await rtdb(`queues/${id}/meta`), null);
    assert.equal(await rtdb(`owners/${id}`), null);
  });

  it('operador criado/removido replica operatorUids', async () => {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id), { ownerId: 'owner1', name: 'A', status: 'open' }));
    await waitFor(() => rtdb(`queues/${id}/meta/name`));
    await fs((db) => setDoc(doc(db, 'queues', id, 'operators', 'op1'), { uid: 'op1' }));
    assert.equal(await waitFor(() => rtdb(`queues/${id}/operatorUids/op1`)), true);
    await fs((db) => deleteDoc(doc(db, 'queues', id, 'operators', 'op1')));
    await waitFor(async () => (await rtdb(`queues/${id}/operatorUids/op1`)) === null);
  });

  it('operador em fila inexistente não cria nó no RTDB', async () => {
    const id = newId();
    await fs((db) => setDoc(doc(db, 'queues', id, 'operators', 'op1'), { uid: 'op1' }));
    await barrier();
    assert.equal(await rtdb(`queues/${id}`), null);
  });
});
