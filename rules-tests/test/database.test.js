import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { get, ref, remove, set, update } from 'firebase/database';
import { OPERATOR, OWNER, QUEUE, STRANGER, setupEnv } from './helpers.js';

describe('RTDB rules', () => {
  let env;
  const rtdb = (uid) => env.authenticatedContext(uid).database();

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearDatabase();
    await env.withSecurityRulesDisabled(async (ctx) => {
      await set(ref(ctx.database()), {
        owners: { [QUEUE]: { ownerUid: OWNER } },
        queues: {
          [QUEUE]: {
            meta: { name: 'Balcão', status: 'open', serving: 3, updatedAt: 0 },
            entries: {
              e1: { uid: 'client1', ticket: 4, status: 'waiting', name: 'Ana', joinedAt: 0 },
            },
            operatorUids: { [OPERATOR]: true, other: true },
          },
        },
        tickets: { [QUEUE]: 4 },
      });
    });
  });

  const path = (p) => `queues/${QUEUE}/${p}`;

  describe('meta', () => {
    it('operador escreve meta/serving', async () => {
      await assertSucceeds(set(ref(rtdb(OPERATOR), path('meta/serving')), 4));
    });

    it('operador escreve meta/updatedAt', async () => {
      await assertSucceeds(set(ref(rtdb(OPERATOR), path('meta/updatedAt')), 1));
    });

    it('operador não escreve meta/status', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path('meta/status')), 'closed'));
    });

    it('operador não escreve meta/name', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path('meta/name')), 'Hack'));
    });

    it('operador não sobrescreve meta inteiro', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path('meta')), { serving: 9 }));
    });

    it('operador não mistura status num update de meta', async () => {
      await assertFails(update(ref(rtdb(OPERATOR), path('meta')), { serving: 5, status: 'paused' }));
    });

    it('estranho não escreve meta/serving', async () => {
      await assertFails(set(ref(rtdb(STRANGER), path('meta/serving')), 4));
    });

    it('dono escreve meta/status', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/status')), 'paused'));
    });
  });

  describe('entries', () => {
    it('operador chama a entry', async () => {
      await assertSucceeds(
        update(ref(rtdb(OPERATOR), path('entries/e1')), { status: 'called', operatorId: OPERATOR }),
      );
    });

    it('operador remove entry finalizada', async () => {
      await assertSucceeds(remove(ref(rtdb(OPERATOR), path('entries/e1'))));
    });

    it('estranho não altera entry de outro', async () => {
      await assertFails(update(ref(rtdb(STRANGER), path('entries/e1')), { status: 'called' }));
    });

    it('cliente cria a própria entry', async () => {
      await assertSucceeds(
        set(ref(rtdb(STRANGER), path('entries/e2')), { uid: STRANGER, ticket: 5, status: 'waiting' }),
      );
    });
  });

  describe('operatorUids', () => {
    it('operador lê o próprio espelho', async () => {
      await assertSucceeds(get(ref(rtdb(OPERATOR), path(`operatorUids/${OPERATOR}`))));
    });

    it('operador não lê o espelho de outro', async () => {
      await assertFails(get(ref(rtdb(OPERATOR), path('operatorUids/other'))));
    });

    it('operador não lê a lista inteira', async () => {
      await assertFails(get(ref(rtdb(OPERATOR), path('operatorUids'))));
    });

    it('operador não escreve no espelho', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path(`operatorUids/${STRANGER}`)), true));
    });

    it('estranho não se adiciona ao espelho', async () => {
      await assertFails(set(ref(rtdb(STRANGER), path(`operatorUids/${STRANGER}`)), true));
    });

    it('dono escreve e lê o espelho', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path(`operatorUids/${STRANGER}`)), true));
      await assertSucceeds(get(ref(rtdb(OWNER), path('operatorUids'))));
    });

    it('espelho só aceita booleano', async () => {
      await assertFails(set(ref(rtdb(OWNER), path(`operatorUids/${STRANGER}`)), 'yes'));
    });

    it('operador removido perde o acesso imediatamente', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await remove(ref(ctx.database(), path(`operatorUids/${OPERATOR}`)));
      });
      await assertFails(set(ref(rtdb(OPERATOR), path('meta/serving')), 4));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { status: 'called' }));
    });
  });

  describe('owners', () => {
    it('estranho não toma posse de fila existente', async () => {
      await assertFails(set(ref(rtdb(STRANGER), `owners/${QUEUE}`), { ownerUid: STRANGER }));
    });

    it('operador não toma posse da fila', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), `owners/${QUEUE}/ownerUid`), OPERATOR));
    });

    it('usuário cria posse de fila nova só para si', async () => {
      await assertSucceeds(set(ref(rtdb(STRANGER), 'owners/q2'), { ownerUid: STRANGER }));
      await assertFails(set(ref(rtdb(STRANGER), 'owners/q3'), { ownerUid: OWNER }));
    });
  });
});
