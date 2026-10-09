import assert from 'node:assert/strict';
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  get,
  onValue,
  ref,
  remove,
  runTransaction,
  serverTimestamp,
  set,
  update,
} from 'firebase/database';
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

    it('dono grava limite, mensagem e retorno válidos', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/maxWaiting')), 30));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/statusMessage')), 'Volto em 10 min'));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/resumeAt')), 1790000000000));
    });

    it('dono não reabre a fila enquanto meta/deleting for true', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await update(ref(ctx.database(), path('meta')), { status: 'closed', deleting: true });
      });
      await assertFails(set(ref(rtdb(OWNER), path('meta/status')), 'open'));
      await assertFails(update(ref(rtdb(OWNER), path('meta')), { status: 'open' }));
      await assertFails(set(ref(rtdb(OWNER), path('meta/deleting')), null));
      await assertSucceeds(set(ref(rtdb(OPERATOR), path('meta/serving')), 4));
    });

    it('dono grava opensAt numérico; os demais não', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/opensAt')), 1790000000000));
      await assertFails(set(ref(rtdb(OWNER), path('meta/opensAt')), 'amanhã'));
      for (const uid of [OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/opensAt')), 1));
      }
    });

    it('dono grava cor e logo válidos; rejeita valores fora do padrão', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/brandColor')), '#2563EB'));
      await assertSucceeds(
        set(ref(rtdb(OWNER), path('meta/logoUrl')), 'https://firebasestorage.googleapis.com/v0/b/x/o/queue-logos%2Fq1%2Flogo.png?alt=media'),
      );
      for (const bad of ['azul', '#12', '#GGGGGG', 'rgb(1,2,3)']) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/brandColor')), bad));
      }
      for (const bad of ['http://x.test/a.png', 'https://evil.example/pixel.png', 'javascript:alert(1)']) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/logoUrl')), bad));
      }
    });

    it('operador, cliente e estranho não gravam cor nem logo', async () => {
      for (const uid of [OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/brandColor')), '#2563EB'));
      }
    });

    it('dono grava modo e slots válidos', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/mode')), 'schedule'));
      await assertSucceeds(
        set(ref(rtdb(OWNER), path('meta/slots')), {
          s1: { start: '09:00', capacity: 2 },
          s2: { start: '23:59', capacity: 50 },
        }),
      );
    });

    it('rejeita modo, horário, capacidade e campos inválidos nos slots', async () => {
      await assertFails(set(ref(rtdb(OWNER), path('meta/mode')), 'agenda'));
      await assertFails(set(ref(rtdb(OWNER), path('meta/mode')), 1));
      for (const bad of [
        { start: '24:00', capacity: 1 },
        { start: '9:00', capacity: 1 },
        { start: '09:60', capacity: 1 },
        { start: '09:00', capacity: 0 },
        { start: '09:00', capacity: 51 },
        { start: '09:00', capacity: 1.5 },
        { start: '09:00' },
        { start: '09:00', capacity: 1, extra: 1 },
      ]) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/slots')), { s1: bad }));
      }
      await assertFails(set(ref(rtdb(OWNER), path('meta/slots')), { 'a b': { start: '09:00', capacity: 1 } }));
    });

    it('operador, cliente e estranho não gravam modo nem slots', async () => {
      for (const uid of [OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/mode')), 'schedule'));
        await assertFails(set(ref(rtdb(uid), path('meta/slots')), { s1: { start: '09:00', capacity: 1 } }));
      }
    });

    it('rejeita limite negativo, fracionário ou acima de 1000', async () => {
      for (const v of [-1, 2.5, 1001, 'x']) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/maxWaiting')), v));
      }
    });

    it('rejeita mensagem longa demais ou que não seja texto', async () => {
      await assertFails(set(ref(rtdb(OWNER), path('meta/statusMessage')), 'a'.repeat(121)));
      await assertFails(set(ref(rtdb(OWNER), path('meta/statusMessage')), 5));
    });

    it('dono grava nome, descrição e tempo médio válidos', async () => {
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/name')), 'x'.repeat(60)));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/description')), 'a'.repeat(300)));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/avgServiceMin')), 240));
    });

    it('rejeita nome, descrição e tempo médio inválidos', async () => {
      for (const v of ['', 'x'.repeat(61), 5]) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/name')), v));
      }
      for (const v of ['a'.repeat(301), 5]) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/description')), v));
      }
      for (const v of [0, 241, 2.5, '10']) {
        await assertFails(set(ref(rtdb(OWNER), path('meta/avgServiceMin')), v));
      }
    });

    it('valor legado inalterado passa e valor novo inválido não', async () => {
      const long = 'x'.repeat(80);
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/name')), long);
        await set(ref(ctx.database(), path('meta/description')), 'd'.repeat(400));
        await set(ref(ctx.database(), path('meta/avgServiceMin')), 500);
      });
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/name')), long));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/description')), 'd'.repeat(400)));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/avgServiceMin')), 500));
      await assertFails(set(ref(rtdb(OWNER), path('meta/name')), 'y'.repeat(81)));
      await assertFails(set(ref(rtdb(OWNER), path('meta/avgServiceMin')), 501));
      await assertSucceeds(set(ref(rtdb(OWNER), path('meta/name')), 'curto'));
    });

    it('operador, cliente e estranho não gravam nome nem tempo médio', async () => {
      for (const uid of [OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/name')), 'Hack'));
        await assertFails(set(ref(rtdb(uid), path('meta/avgServiceMin')), 5));
      }
    });

    it('operador, cliente e estranho não gravam limite nem mensagem', async () => {
      for (const uid of [OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/maxWaiting')), 5));
        await assertFails(set(ref(rtdb(uid), path('meta/statusMessage')), 'oi'));
      }
    });

    it('qualquer autenticado lê a mensagem de status', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/statusMessage')), 'Intervalo');
      });
      const snap = await assertSucceeds(get(ref(rtdb('client1'), path('meta/statusMessage'))));
      if (snap.val() !== 'Intervalo') throw new Error('mensagem não lida');
    });

    it('operador não escreve meta/status', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path('meta/status')), 'closed'));
    });

    it('cliente não escreve meta/avgServiceMinAuto', async () => {
      await assertFails(set(ref(rtdb('client1'), path('meta/avgServiceMinAuto')), 1));
    });

    it('operador não escreve meta/avgServiceMinAuto', async () => {
      await assertFails(set(ref(rtdb(OPERATOR), path('meta/avgServiceMinAuto')), 1));
    });

    it('dono, operador e cliente não escrevem meta/waitingCount', async () => {
      for (const uid of [OWNER, OPERATOR, 'client1', STRANGER]) {
        await assertFails(set(ref(rtdb(uid), path('meta/waitingCount')), 0));
        await assertFails(update(ref(rtdb(uid), path('meta')), { waitingCount: 9 }));
      }
    });

    it('meta/waitingCount é legível por autenticado e o dono segue escrevendo o resto do meta', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/waitingCount')), 2);
      });
      const snap = await get(ref(rtdb('client1'), path('meta/waitingCount')));
      assert.equal(snap.val(), 2);
      const ownerSnap = await get(ref(rtdb(OWNER), path('meta/waitingCount')));
      assert.equal(ownerSnap.val(), 2);
      await assertSucceeds(update(ref(rtdb(OWNER), path('meta')), { maxWaiting: 5 }));
    });

    it('dono pode remover meta/waitingCount, mas não escrever valor', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/waitingCount')), 2);
      });
      await assertFails(set(ref(rtdb(OWNER), path('meta/waitingCount')), 3));
      await assertSucceeds(remove(ref(rtdb(OWNER), path('meta/waitingCount'))));
      const snap = await get(ref(rtdb(OWNER), path('meta/waitingCount')));
      assert.equal(snap.exists(), false);
    });

    it('set completo do meta pelo dono funciona e apaga waitingCount', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/waitingCount')), 2);
      });
      await assertSucceeds(
        set(ref(rtdb(OWNER), path('meta')), { name: 'Balcão', status: 'open', serving: 3, updatedAt: 1 }),
      );
      const snap = await get(ref(rtdb(OWNER), path('meta')));
      assert.equal(snap.val().waitingCount, undefined);
      assert.equal(snap.val().name, 'Balcão');
    });

    it('set completo do meta que inclua waitingCount é negado', async () => {
      await assertFails(
        set(ref(rtdb(OWNER), path('meta')), { name: 'Balcão', status: 'open', serving: 3, updatedAt: 1, waitingCount: 4 }),
      );
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
    it('operador e dono gravam order, recalls, skips e recalledAt', async () => {
      for (const uid of [OPERATOR, OWNER]) {
        await assertSucceeds(
          update(ref(rtdb(uid), path('entries/e1')), {
            order: 1790000000000,
            skips: 1,
            recalls: 2,
            recalledAt: 1790000000500,
          }),
        );
      }
    });

    it('rejeita recalls/skips negativos ou fracionários e order não numérico', async () => {
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { recalls: -1 }));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { skips: 1.5 }));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { order: 'x' }));
    });

    it('cliente não altera a própria posição nem os contadores', async () => {
      for (const patch of [{ order: 1 }, { skips: 0 }, { recalls: 0 }, { recalledAt: 5 }]) {
        await assertFails(update(ref(rtdb('client1'), path('entries/e1')), patch));
      }
    });

    it('cliente ainda pode sair da fila (status left)', async () => {
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { status: 'left' }));
    });

    it('campo desconhecido continua rejeitado', async () => {
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { vip: true }));
    });

    it('operador chama entry criada pela joinQueue (com lang): transação grava a entry inteira', async () => {
      const full = {
        uid: 'client1',
        ticket: 4,
        status: 'called',
        name: 'Ana',
        phone: '(11) 91234-5678',
        joinedAt: 0,
        calledAt: 1790000000000,
        operatorId: OPERATOR,
        lang: 'en',
        nextNotifiedAt: 1790000000500,
      };
      await assertSucceeds(set(ref(rtdb(OPERATOR), path('entries/e1')), full));
    });

    it('cliente não altera lang nem nextNotifiedAt da própria entry', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await update(ref(ctx.database(), path('entries/e1')), { lang: 'pt', nextNotifiedAt: 5 });
      });
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { lang: 'en' }));
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { nextNotifiedAt: 9 }));
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { status: 'left' }));
    });

    it('cliente não altera slotId nem slotStart da própria entry', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await update(ref(ctx.database(), path('entries/e1')), { slotId: 's1', slotStart: 1790000000000 });
      });
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { slotId: 's2' }));
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { slotStart: 1 }));
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { status: 'left' }));
    });

    it('slotId e slotStart inválidos são rejeitados', async () => {
      await assertSucceeds(update(ref(rtdb(OPERATOR), path('entries/e1')), { slotId: 's1', slotStart: 5 }));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { slotId: 'a/b' }));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { slotId: 7 }));
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { slotStart: 'x' }));
    });

    it('entry manual sem uid: dono e operador gravam, cliente não', async () => {
      const manual = { ticket: 5, status: 'waiting', name: 'Balcão Bia', phone: '', joinedAt: 1, manual: true };
      await assertSucceeds(set(ref(rtdb(OWNER), path('entries/m1')), manual));
      await assertSucceeds(set(ref(rtdb(OPERATOR), path('entries/m2')), manual));
      await assertFails(set(ref(rtdb(STRANGER), path('entries/m3')), manual));
      await assertFails(set(ref(rtdb('client1'), path('entries/m4')), manual));
    });

    it('entry sem uid e sem manual é rejeitada', async () => {
      await assertFails(
        set(ref(rtdb(OWNER), path('entries/m5')), { ticket: 5, status: 'waiting', name: 'X', phone: '', joinedAt: 1 }),
      );
    });

    it('manual só aceita booleano', async () => {
      await assertFails(
        set(ref(rtdb(OWNER), path('entries/m6')), { ticket: 5, status: 'waiting', name: 'X', manual: 'sim' }),
      );
    });

    it('operador chama e finaliza entry manual', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('entries/m1')), {
          ticket: 5, status: 'waiting', name: 'Bia', phone: '', joinedAt: 1, manual: true,
        });
      });
      await assertSucceeds(update(ref(rtdb(OPERATOR), path('entries/m1')), { status: 'called', operatorId: OPERATOR }));
      await assertSucceeds(update(ref(rtdb(OPERATOR), path('entries/m1')), { status: 'served' }));
      await assertSucceeds(remove(ref(rtdb(OPERATOR), path('entries/m1'))));
    });

    it('cliente não marca a própria entry como manual nem remove a marca', async () => {
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { manual: true }));
      await env.withSecurityRulesDisabled(async (ctx) => {
        await update(ref(ctx.database(), path('entries/e1')), { manual: true });
      });
      await assertFails(update(ref(rtdb('client1'), path('entries/e1')), { manual: false }));
      await assertSucceeds(update(ref(rtdb('client1'), path('entries/e1')), { status: 'left' }));
    });

    it('cliente não lê entry manual', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('entries/m1')), {
          ticket: 5, status: 'waiting', name: 'Bia', phone: '', joinedAt: 1, manual: true,
        });
      });
      await assertFails(get(ref(rtdb('client1'), path('entries/m1'))));
    });

    it('lang inválido é rejeitado', async () => {
      await assertFails(update(ref(rtdb(OPERATOR), path('entries/e1')), { lang: 'klingon' }));
    });

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

    it('dono remove public mas não cria', async () => {
      await assertSucceeds(remove(ref(rtdb(OWNER), path('public/e1'))));
      await assertSucceeds(remove(ref(rtdb(OWNER), path('public'))));
    });

    it('operador e estranho não removem public', async () => {
      await assertFails(remove(ref(rtdb(OPERATOR), path('public/e1'))));
      await assertFails(remove(ref(rtdb(STRANGER), path('public'))));
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

  describe('openWatchers', () => {
    const watcher = (over = {}) => ({
      fcmToken: 'tok',
      lang: 'pt',
      createdAt: serverTimestamp(),
      ...over,
    });
    const wpath = (uid) => path(`openWatchers/${uid}`);

    it('cliente cria o próprio pedido', async () => {
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher()));
    });

    it('cliente não cria pedido de outro uid', async () => {
      await assertFails(set(ref(rtdb('c1'), wpath('c2')), watcher()));
    });

    it('sem auth não cria', async () => {
      const unauth = env.unauthenticatedContext().database();
      await assertFails(set(ref(unauth, wpath('c1')), watcher()));
    });

    it('valida fcmToken, lang e createdAt', async () => {
      const db = rtdb('c1');
      await assertFails(set(ref(db, wpath('c1')), watcher({ fcmToken: '' })));
      await assertFails(set(ref(db, wpath('c1')), watcher({ fcmToken: 'x'.repeat(4097) })));
      await assertFails(set(ref(db, wpath('c1')), watcher({ fcmToken: 5 })));
      await assertFails(set(ref(db, wpath('c1')), watcher({ lang: 'fr' })));
      await assertFails(set(ref(db, wpath('c1')), watcher({ createdAt: 1 })));
      await assertFails(set(ref(db, wpath('c1')), watcher({ phone: '1' })));
      await assertFails(set(ref(db, wpath('c1')), { fcmToken: 'tok', lang: 'pt' }));
      await assertSucceeds(set(ref(db, wpath('c1')), watcher({ fcmToken: 'x'.repeat(4096) })));
    });

    it('não cria em fila inexistente ou em exclusão', async () => {
      await assertFails(set(ref(rtdb('c1'), 'queues/nope/openWatchers/c1'), watcher()));
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/deleting')), true);
      });
      await assertFails(set(ref(rtdb('c1'), wpath('c1')), watcher()));
    });

    it('cliente renova o próprio pedido', async () => {
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher()));
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher({ fcmToken: 'novo' })));
      const snap = await get(ref(rtdb('c1'), wpath('c1')));
      assert.equal(snap.val().fcmToken, 'novo');
    });

    it('dono e operador não escrevem pedido alheio', async () => {
      await assertFails(set(ref(rtdb(OWNER), wpath('c1')), watcher()));
      await assertFails(set(ref(rtdb(OPERATOR), wpath('c1')), watcher()));
    });

    it('createdAt falso (passado ou futuro) é negado', async () => {
      await assertFails(set(ref(rtdb('c1'), wpath('c1')), watcher({ createdAt: Date.now() })));
      await assertFails(
        set(ref(rtdb('c1'), wpath('c1')), watcher({ createdAt: Date.now() + 86_400_000 })),
      );
    });

    it('fila em exclusão ainda deixa o cliente apagar o pedido', async () => {
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher()));
      await env.withSecurityRulesDisabled(async (ctx) => {
        await set(ref(ctx.database(), path('meta/deleting')), true);
      });
      await assertSucceeds(remove(ref(rtdb('c1'), wpath('c1'))));
    });

    it('cliente lê e apaga só o próprio pedido', async () => {
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher()));
      await assertSucceeds(get(ref(rtdb('c1'), wpath('c1'))));
      await assertFails(get(ref(rtdb('c2'), wpath('c1'))));
      await assertFails(remove(ref(rtdb('c2'), wpath('c1'))));
      await assertSucceeds(remove(ref(rtdb('c1'), wpath('c1'))));
    });

    it('cliente e operador não listam; dono lista', async () => {
      await assertSucceeds(set(ref(rtdb('c1'), wpath('c1')), watcher()));
      await assertFails(get(ref(rtdb('c1'), path('openWatchers'))));
      await assertFails(get(ref(rtdb(OPERATOR), path('openWatchers'))));
      await assertSucceeds(get(ref(rtdb(OWNER), path('openWatchers'))));
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

    it('operador e dono sobrescrevem calledAt com o timestamp do servidor', async () => {
      for (const uid of [OPERATOR, OWNER]) {
        await env.withSecurityRulesDisabled(async (ctx) => {
          await update(ref(ctx.database(), entryPath('e1')), {
            status: 'called',
            operatorId: OPERATOR,
            calledAt: 1,
          });
        });
        await assertSucceeds(set(ref(rtdb(uid), entryPath('e1/calledAt')), serverTimestamp()));
        await env.withSecurityRulesDisabled(async (ctx) => {
          const snap = await get(ref(ctx.database(), entryPath('e1/calledAt')));
          assert.equal(typeof snap.val(), 'number');
          assert.ok(Math.abs(snap.val() - Date.now()) < 60000);
          assert.notEqual(snap.val(), 1);
        });
      }
    });

    it('cliente não altera calledAt, nem com o timestamp do servidor', async () => {
      await assertFails(set(ref(rtdb('client1'), entryPath('e1/calledAt')), serverTimestamp()));
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

  describe('transação de finalização', () => {
    const entryPath = (id) => path(`entries/${id}`);
    const finish = (result, uid) => (current) => {
      if (current === null) return null;
      if (current.status !== 'called' && current.status !== result) return undefined;
      return { ...current, status: result, operatorId: uid };
    };

    beforeEach(async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await update(ref(ctx.database(), entryPath('e1')), { status: 'called', operatorId: OPERATOR });
      });
    });

    for (const [label, uid] of [['dono', OWNER], ['operador', OPERATOR]]) {
      it(`${label} finaliza com cache frio (handler recebe null e é refeito)`, async () => {
        const r = ref(rtdb(uid), entryPath('e1'));
        const res = await assertSucceeds(runTransaction(r, finish('served', uid)));
        assert.equal(res.committed, true);
        assert.equal(res.snapshot.val().status, 'served');
        assert.equal(res.snapshot.val().operatorId, uid);
      });

      it(`${label} finaliza com listener ativo`, async () => {
        const r = ref(rtdb(uid), entryPath('e1'));
        const off = onValue(r, () => {});
        await get(r);
        const res = await assertSucceeds(runTransaction(r, finish('no_show', uid)));
        off();
        assert.equal(res.committed, true);
        assert.equal(res.snapshot.val().status, 'no_show');
      });
    }

    it('status de destino já gravado é idempotente', async () => {
      const r = ref(rtdb(OPERATOR), entryPath('e1'));
      await assertSucceeds(runTransaction(r, finish('served', OPERATOR)));
      const res = await assertSucceeds(runTransaction(r, finish('served', OPERATOR)));
      assert.equal(res.snapshot.val().status, 'served');
    });

    it('resultado diferente do já gravado aborta sem alterar', async () => {
      const r = ref(rtdb(OPERATOR), entryPath('e1'));
      await assertSucceeds(runTransaction(r, finish('served', OPERATOR)));
      const res = await assertSucceeds(runTransaction(r, finish('no_show', OPERATOR)));
      assert.equal(res.committed, false);
      assert.equal(res.snapshot.val().status, 'served');
    });

    it('entry inexistente termina com snapshot nulo', async () => {
      const r = ref(rtdb(OPERATOR), entryPath('nope'));
      const res = await runTransaction(r, finish('served', OPERATOR));
      assert.equal(res.snapshot.val(), null);
    });

    it('estranho não finaliza', async () => {
      const r = ref(rtdb(STRANGER), entryPath('e1'));
      await assertFails(runTransaction(r, finish('served', STRANGER)));
    });

    it('campo desconhecido é negado', async () => {
      const r = ref(rtdb(OPERATOR), entryPath('e1'));
      await assertFails(
        runTransaction(r, (current) => (current === null ? null : { ...current, status: 'served', hack: 1 })),
      );
    });
  });
});
