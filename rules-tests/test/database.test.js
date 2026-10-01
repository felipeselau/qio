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
              e1: { uid: 'client1', ticket: 4, status: 'waiting', name: 'Ana', phone: '(11) 91234-5678', joinedAt: 0 },
            },
            public: { e1: { ticket: 4, status: 'waiting' } },
            operatorUids: { [OPERATOR]: true, other: true },
          },
        },
        tickets: { [QUEUE]: 4 },
        rateLimits: { [QUEUE]: { client1: [1] } },
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

    it('cliente não cria entry diretamente', async () => {
      await assertFails(
        set(ref(rtdb(STRANGER), path('entries/e2')), { uid: STRANGER, ticket: 5, status: 'waiting', name: 'Bia' }),
      );
    });

    it('anônimo não lista entries', async () => {
      await assertFails(get(ref(rtdb(STRANGER), path('entries'))));
    });

    it('cliente lê a própria entry', async () => {
      await assertSucceeds(get(ref(rtdb('client1'), path('entries/e1'))));
    });

    it('cliente não lê entry de outro', async () => {
      await assertFails(get(ref(rtdb(STRANGER), path('entries/e1'))));
    });

    it('dono lista entries', async () => {
      await assertSucceeds(get(ref(rtdb(OWNER), path('entries'))));
    });

    it('operador lista entries', async () => {
      await assertSucceeds(get(ref(rtdb(OPERATOR), path('entries'))));
    });

    it('cliente marca a própria entry como left', async () => {
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { status: 'left' }));
    });

    it('cliente não volta a própria entry para called', async () => {
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { status: 'called' }));
    });

    it('cliente grava fcmToken', async () => {
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { fcmToken: 'tok' }));
    });

    it('cliente não muda o próprio ticket, nome ou telefone', async () => {
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { ticket: 1 }));
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { name: 'Outro' }));
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { phone: '(11) 3333-4444' }));
    });
  });

  describe('public, tickets e rateLimits', () => {
    it('cliente lê public', async () => {
      await assertSucceeds(get(ref(rtdb(STRANGER), path('public'))));
    });

    it('cliente não escreve em public', async () => {
      await assertFails(set(ref(rtdb('client1'), path('public/e9')), { ticket: 1, status: 'waiting' }));
      await assertFails(remove(ref(rtdb('client1'), path('public/e1'))));
    });

    it('dono não escreve em public', async () => {
      await assertFails(set(ref(rtdb(OWNER), path('public/e9')), { ticket: 1, status: 'waiting' }));
    });

    it('cliente não escreve tickets', async () => {
      await assertFails(set(ref(rtdb(STRANGER), `tickets/${QUEUE}`), 99));
    });

    it('cliente não lê tickets', async () => {
      await assertFails(get(ref(rtdb(STRANGER), `tickets/${QUEUE}`)));
    });

    it('dono remove tickets', async () => {
      await assertSucceeds(remove(ref(rtdb(OWNER), `tickets/${QUEUE}`)));
    });

    it('ninguém lê ou escreve rateLimits', async () => {
      for (const uid of [OWNER, OPERATOR, 'client1', STRANGER]) {
        await assertFails(get(ref(rtdb(uid), `rateLimits/${QUEUE}/client1`)));
        await assertFails(set(ref(rtdb(uid), `rateLimits/${QUEUE}/client1`), []));
      }
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

  describe('validação de entries', () => {
    const entryPath = (id) => path(`entries/${id}`);
    const valid = (extra = {}) => ({
      uid: STRANGER,
      ticket: 5,
      name: 'Bia',
      phone: '(11) 91234-5678',
      status: 'waiting',
      joinedAt: 1,
      calledAt: null,
      ...extra,
    });
    const create = (extra) => set(ref(rtdb(OWNER), entryPath('e2')), valid(extra));

    it('aceita entry válida com telefone celular', async () => {
      await assertSucceeds(create());
    });

    it('aceita telefone fixo', async () => {
      await assertSucceeds(create({ phone: '(11) 3333-4444' }));
    });

    it('aceita telefone vazio', async () => {
      await assertSucceeds(create({ phone: '' }));
    });

    it('rejeita telefone fora do formato', async () => {
      await assertFails(create({ phone: '11912345678' }));
      await assertFails(create({ phone: '<script>' }));
    });

    it('rejeita nome vazio', async () => {
      await assertFails(create({ name: '' }));
    });

    it('rejeita nome com mais de 60 caracteres', async () => {
      await assertFails(create({ name: 'a'.repeat(61) }));
      await assertSucceeds(create({ name: 'a'.repeat(60) }));
    });

    it('rejeita status inválido', async () => {
      await assertFails(create({ status: 'vip' }));
    });

    it('rejeita ticket não numérico', async () => {
      await assertFails(create({ ticket: '5' }));
    });

    it('rejeita campo desconhecido', async () => {
      await assertFails(create({ admin: true }));
    });

    it('rejeita troca de uid', async () => {
      await assertFails(
        update(ref(rtdb(OPERATOR), entryPath('e1')), { uid: OPERATOR }),
      );
    });

    it('dono atualiza status de entry antiga com telefone fora do padrão', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), entryPath('old')), {
          uid: 'client1',
          ticket: 1,
          name: 'x'.repeat(80),
          phone: '123',
          status: 'waiting',
          joinedAt: 0,
        });
      });
      await assertSucceeds(
        update(ref(rtdb(OWNER), entryPath('old')), { status: 'called', operatorId: OWNER }),
      );
    });

    it('operador faz o equivalente à transação de _claimEntry', async () => {
      await assertSucceeds(
        set(ref(rtdb(OPERATOR), entryPath('e1')), {
          uid: 'client1',
          ticket: 4,
          status: 'called',
          name: 'Ana',
          joinedAt: 0,
          calledAt: Date.now(),
          operatorId: OPERATOR,
        }),
      );
    });

    it('cliente marca left', async () => {
      await assertSucceeds(update(ref(rtdb('client1'), entryPath('e1')), { status: 'left' }));
    });

    it('cliente grava fcmToken', async () => {
      await assertSucceeds(update(ref(rtdb('client1'), entryPath('e1')), { fcmToken: 'tok' }));
    });

    it('dono remove entry', async () => {
      await assertSucceeds(remove(ref(rtdb(OWNER), entryPath('e1'))));
    });
  });
});
