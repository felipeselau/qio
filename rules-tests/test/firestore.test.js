import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { OPERATOR, OWNER, QUEUE, STRANGER, setupEnv } from './helpers.js';

const hoursFromNow = (h) => Timestamp.fromMillis(Date.now() + h * 3600 * 1000);

const historyEntry = (operatorId) => ({
  ticket: 1,
  name: 'Ana',
  phone: null,
  result: 'served',
  joinedAt: Timestamp.now(),
  calledAt: Timestamp.now(),
  calledBy: operatorId,
  operatorId,
  finishedAt: Timestamp.now(),
});

describe('Firestore rules', () => {
  let env;
  const db = (uid) => env.authenticatedContext(uid).firestore();
  const anonDb = (uid) =>
    env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
  const passwordDb = (uid) =>
    env.authenticatedContext(uid, { firebase: { sign_in_provider: 'password' } }).firestore();
  const noProviderDb = (uid) =>
    env.authenticatedContext(uid, { firebase: undefined }).firestore();
  const googleDb = (uid) =>
    env.authenticatedContext(uid, { firebase: { sign_in_provider: 'google.com' } }).firestore();

  before(async () => {
    env = await setupEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'queues', QUEUE), { ownerId: OWNER, name: 'Balcão', status: 'open' });
      await setDoc(doc(fs, 'queues', QUEUE, 'operators', OPERATOR), { uid: OPERATOR, queueId: QUEUE });
      await setDoc(doc(fs, 'queues', QUEUE, 'history', 'h1'), historyEntry(OWNER));
      await setDoc(doc(fs, 'queues', QUEUE, 'feedback', 'h1'), { rating: 5, comment: '', uid: 'client', createdAt: 1 });
      await setDoc(doc(fs, 'operatorInvites', 'VALID1'), { queueId: QUEUE, ownerId: OWNER, expiresAt: hoursFromNow(24) });
      await setDoc(doc(fs, 'operatorInvites', 'EXPIR1'), { queueId: QUEUE, ownerId: OWNER, expiresAt: hoursFromNow(-1) });
      await setDoc(doc(fs, 'operatorInvites', 'OTHER1'), { queueId: 'q2', ownerId: OWNER, expiresAt: hoursFromNow(24) });
      await setDoc(doc(fs, 'queues', QUEUE, 'operatorRequests', 'pendingUser'), {
        uid: 'pendingUser',
        queueId: QUEUE,
        code: 'VALID1',
        status: 'pending',
      });
      await setDoc(doc(fs, 'queues', QUEUE, 'operatorRequests', 'rejectedUser'), {
        uid: 'rejectedUser',
        queueId: QUEUE,
        code: 'VALID1',
        status: 'rejected',
      });
    });
  });

  describe('feedback', () => {
    it('dono lê a lista de avaliações', async () => {
      await assertSucceeds(getDocs(collection(db(OWNER), 'queues', QUEUE, 'feedback')));
      await assertSucceeds(getDoc(doc(db(OWNER), 'queues', QUEUE, 'feedback', 'h1')));
    });

    it('operador e estranho não leem', async () => {
      await assertFails(getDoc(doc(db(OPERATOR), 'queues', QUEUE, 'feedback', 'h1')));
      await assertFails(getDocs(collection(db(STRANGER), 'queues', QUEUE, 'feedback')));
    });

    it('nenhum cliente escreve, nem o dono', async () => {
      const data = { rating: 5, comment: '', uid: STRANGER, createdAt: 1 };
      await assertFails(setDoc(doc(db(STRANGER), 'queues', QUEUE, 'feedback', 'h9'), data));
      await assertFails(setDoc(doc(db(OWNER), 'queues', QUEUE, 'feedback', 'h9'), data));
      await assertFails(updateDoc(doc(db(OWNER), 'queues', QUEUE, 'feedback', 'h1'), { rating: 1 }));
    });

    it('dono apaga avaliações (deleteQueue)', async () => {
      await assertSucceeds(deleteDoc(doc(db(OWNER), 'queues', QUEUE, 'feedback', 'h1')));
    });

    it('estranho não apaga', async () => {
      await assertFails(deleteDoc(doc(db(STRANGER), 'queues', QUEUE, 'feedback', 'h1')));
    });
  });

  describe('devices de push', () => {
    const device = { token: 'abc', platform: 'android', lang: 'pt', updatedAt: 1 };

    it('o próprio usuário registra, lê e apaga o aparelho', async () => {
      const ref = doc(db(OWNER), 'owners', OWNER, 'devices', 'd1');
      await assertSucceeds(setDoc(ref, device));
      await assertSucceeds(getDoc(ref));
      await assertSucceeds(deleteDoc(ref));
    });

    it('outro usuário não lê nem escreve nos aparelhos alheios', async () => {
      const ref = doc(db(STRANGER), 'owners', OWNER, 'devices', 'd1');
      await assertFails(setDoc(ref, device));
      await assertFails(getDoc(ref));
      await assertFails(deleteDoc(ref));
    });

    it('rejeita token vazio, grande demais, sem token ou com campo extra', async () => {
      const ref = doc(db(OWNER), 'owners', OWNER, 'devices', 'd2');
      await assertFails(setDoc(ref, { ...device, token: '' }));
      await assertFails(setDoc(ref, { ...device, token: 'x'.repeat(4097) }));
      await assertFails(setDoc(ref, { platform: 'android' }));
      await assertFails(setDoc(ref, { ...device, admin: true }));
      await assertFails(setDoc(ref, { ...device, token: 5 }));
    });
  });

  describe('grupos de filas', () => {
    const group = { name: 'Loja Centro', createdAt: 1 };
    const ref = (uid, id = 'g1') => doc(db(uid), 'owners', OWNER, 'groups', id);

    beforeEach(async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'owners', OWNER, 'groups', 'g1'), group);
      });
    });

    it('dono cria, lê, renomeia e apaga', async () => {
      await assertSucceeds(setDoc(ref(OWNER, 'g2'), group));
      await assertSucceeds(getDoc(ref(OWNER)));
      await assertSucceeds(getDocs(collection(db(OWNER), 'owners', OWNER, 'groups')));
      await assertSucceeds(updateDoc(ref(OWNER), { name: 'Loja Norte' }));
      await assertSucceeds(deleteDoc(ref(OWNER)));
    });

    it('outro uid e operador não leem nem escrevem', async () => {
      for (const uid of [STRANGER, OPERATOR]) {
        await assertFails(getDoc(ref(uid)));
        await assertFails(getDocs(collection(db(uid), 'owners', OWNER, 'groups')));
        await assertFails(setDoc(ref(uid, 'g3'), group));
        await assertFails(updateDoc(ref(uid), { name: 'X' }));
        await assertFails(deleteDoc(ref(uid)));
      }
    });

    it('rejeita nome vazio, grande demais, não string, ausente ou chave extra', async () => {
      await assertFails(setDoc(ref(OWNER, 'g4'), { ...group, name: '' }));
      await assertFails(setDoc(ref(OWNER, 'g4'), { ...group, name: 'x'.repeat(41) }));
      await assertFails(setDoc(ref(OWNER, 'g4'), { ...group, name: 5 }));
      await assertFails(setDoc(ref(OWNER, 'g4'), { createdAt: 1 }));
      await assertFails(setDoc(ref(OWNER, 'g4'), { ...group, queueIds: [] }));
      await assertFails(updateDoc(ref(OWNER), { name: '' }));
      await assertSucceeds(setDoc(ref(OWNER, 'g5'), { ...group, name: 'x'.repeat(40) }));
    });

    it('somente o dono define groupId na fila', async () => {
      await assertSucceeds(updateDoc(doc(db(OWNER), 'queues', QUEUE), { groupId: 'g1' }));
      await assertFails(updateDoc(doc(db(OPERATOR), 'queues', QUEUE), { groupId: 'g1' }));
      await assertFails(updateDoc(doc(db(STRANGER), 'queues', QUEUE), { groupId: 'g1' }));
    });

    it('create de fila com groupId válido passa e inválido é negado', async () => {
      const base = { ownerId: OWNER, name: 'Nova', status: 'open' };
      const q = (id) => doc(db(OWNER), 'queues', id);
      await assertSucceeds(setDoc(q('n1'), { ...base, groupId: 'g1' }));
      await assertSucceeds(setDoc(q('n2'), base));
      await assertFails(setDoc(q('n3'), { ...base, groupId: 5 }));
      await assertFails(setDoc(q('n4'), { ...base, groupId: '' }));
      await assertFails(setDoc(q('n5'), { ...base, groupId: 'x'.repeat(41) }));
      await assertFails(setDoc(doc(db(STRANGER), 'queues', 'n6'), { ...base, groupId: 'g1' }));
    });

    it('groupId inválido na fila é negado', async () => {
      await assertFails(updateDoc(doc(db(OWNER), 'queues', QUEUE), { groupId: 5 }));
      await assertFails(updateDoc(doc(db(OWNER), 'queues', QUEUE), { groupId: 'x'.repeat(41) }));
    });
  });

  describe('conta do dono', () => {
    it('usuário lê o próprio owners/{uid}', async () => {
      await assertSucceeds(getDoc(doc(db(OWNER), 'owners', OWNER)));
    });

    it('usuário não lê owners de outro', async () => {
      await assertFails(getDoc(doc(db(STRANGER), 'owners', OWNER)));
    });

    it('dono conta as próprias filas', async () => {
      await assertSucceeds(
        getCountFromServer(query(collection(db(OWNER), 'queues'), where('ownerId', '==', OWNER))),
      );
    });
  });

  describe('fila', () => {
    it('operador lê a fila', async () => {
      await assertSucceeds(getDoc(doc(db(OPERATOR), 'queues', QUEUE)));
    });

    it('estranho não lê a fila', async () => {
      await assertFails(getDoc(doc(db(STRANGER), 'queues', QUEUE)));
    });

    it('operador não altera status da fila', async () => {
      await assertFails(updateDoc(doc(db(OPERATOR), 'queues', QUEUE), { status: 'paused' }));
    });

    it('operador não altera o convite da fila', async () => {
      await assertFails(updateDoc(doc(db(OPERATOR), 'queues', QUEUE), { operatorInviteCode: 'HACK01' }));
    });

    it('operador não exclui a fila', async () => {
      await assertFails(deleteDoc(doc(db(OPERATOR), 'queues', QUEUE)));
    });

    it('dono altera status da fila', async () => {
      await assertSucceeds(updateDoc(doc(db(OWNER), 'queues', QUEUE), { status: 'paused' }));
    });

    it('dono edita nome, descrição e tempo médio válidos', async () => {
      const ref = doc(db(OWNER), 'queues', QUEUE);
      await assertSucceeds(updateDoc(ref, { name: 'Novo nome', description: 'a'.repeat(300), avgServiceMin: 240 }));
      await assertSucceeds(updateDoc(ref, { name: 'x'.repeat(60), description: null, avgServiceMin: 1 }));
    });

    it('nega nome, descrição e tempo médio inválidos', async () => {
      const ref = doc(db(OWNER), 'queues', QUEUE);
      for (const bad of [{ name: '' }, { name: 'x'.repeat(61) }, { name: 5 }]) {
        await assertFails(updateDoc(ref, bad));
      }
      for (const bad of [{ description: 'a'.repeat(301) }, { description: 5 }]) {
        await assertFails(updateDoc(ref, bad));
      }
      for (const bad of [{ avgServiceMin: 0 }, { avgServiceMin: 241 }, { avgServiceMin: 2.5 }, { avgServiceMin: '10' }]) {
        await assertFails(updateDoc(ref, bad));
      }
    });

    it('dado legado fora do limite não bloqueia outras atualizações', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'queues', 'legacy'), { ownerId: OWNER, name: 'x'.repeat(80), status: 'open' });
      });
      await assertSucceeds(updateDoc(doc(db(OWNER), 'queues', 'legacy'), { status: 'paused' }));
    });

    it('valida cada campo só quando ele muda', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'queues', 'legacy2'), { ownerId: OWNER, name: 'x'.repeat(80), status: 'open' });
      });
      const ref = doc(db(OWNER), 'queues', 'legacy2');
      await assertSucceeds(updateDoc(ref, { description: 'nova' }));
      await assertSucceeds(updateDoc(ref, { avgServiceMin: 20 }));
      await assertSucceeds(updateDoc(ref, { description: 'outra', avgServiceMin: 30 }));
      await assertFails(updateDoc(ref, { name: 'y'.repeat(61) }));
      await assertSucceeds(updateDoc(ref, { name: 'curto' }));
    });

    it('operador e estranho não editam nome', async () => {
      await assertFails(updateDoc(doc(db(OPERATOR), 'queues', QUEUE), { name: 'Hack' }));
      await assertFails(updateDoc(doc(db(STRANGER), 'queues', QUEUE), { name: 'Hack' }));
    });

    it('create valida nome, descrição e tempo médio', async () => {
      const base = { ownerId: OWNER, name: 'Nova', status: 'open' };
      const q = (id) => doc(db(OWNER), 'queues', id);
      await assertSucceeds(setDoc(q('i1'), { ...base, description: null, avgServiceMin: 10 }));
      await assertFails(setDoc(q('i2'), { ...base, name: '' }));
      await assertFails(setDoc(q('i3'), { ...base, name: 'x'.repeat(61) }));
      await assertFails(setDoc(q('i4'), { ...base, description: 'a'.repeat(301) }));
      await assertFails(setDoc(q('i5'), { ...base, avgServiceMin: 0 }));
    });
  });

  describe('retenção e anonimização', () => {
    const ref = () => doc(db(OWNER), 'queues', QUEUE);

    it('dono grava retentionDays 30–730 e anonymizePhone booleano', async () => {
      await assertSucceeds(updateDoc(ref(), { retentionDays: 30 }));
      await assertSucceeds(updateDoc(ref(), { retentionDays: 730 }));
      await assertSucceeds(updateDoc(ref(), { retentionDays: 180, anonymizePhone: true }));
      await assertSucceeds(updateDoc(ref(), { anonymizePhone: false }));
    });

    it('nega retentionDays e anonymizePhone inválidos', async () => {
      for (const bad of [
        { retentionDays: 29 },
        { retentionDays: 731 },
        { retentionDays: 0 },
        { retentionDays: 90.5 },
        { retentionDays: '90' },
        { retentionDays: null },
      ]) {
        await assertFails(updateDoc(ref(), bad));
      }
      for (const bad of [{ anonymizePhone: 'true' }, { anonymizePhone: 1 }, { anonymizePhone: null }]) {
        await assertFails(updateDoc(ref(), bad));
      }
    });

    it('atualiza anonymizePhone e retentionDays em fila com 24 slots', async () => {
      const slots = Array.from({ length: 20 }, (_, i) => ({
        id: `s${i}`,
        start: `${String(i).padStart(2, '0')}:00`,
        capacity: 2,
      }));
      await assertSucceeds(updateDoc(ref(), { mode: 'schedule', slots }));
      await assertSucceeds(updateDoc(ref(), { anonymizePhone: true }));
      await assertSucceeds(updateDoc(ref(), { retentionDays: 365 }));
      await assertSucceeds(updateDoc(ref(), { status: 'paused' }));
    });

    it('valor legado inalterado não bloqueia outras atualizações', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'queues', 'legacy3'), {
          ownerId: OWNER,
          name: 'x',
          status: 'open',
          retentionDays: 5,
        });
      });
      await assertSucceeds(updateDoc(doc(db(OWNER), 'queues', 'legacy3'), { status: 'paused' }));
    });

    it('create valida os campos', async () => {
      const base = { ownerId: OWNER, name: 'Nova', status: 'open' };
      const q = (id) => doc(db(OWNER), 'queues', id);
      await assertSucceeds(setDoc(q('p1'), { ...base, retentionDays: 90, anonymizePhone: true }));
      await assertFails(setDoc(q('p2'), { ...base, retentionDays: 10 }));
      await assertFails(setDoc(q('p3'), { ...base, anonymizePhone: 'x' }));
    });

    it('operador e estranho não gravam', async () => {
      for (const uid of [OPERATOR, STRANGER]) {
        await assertFails(updateDoc(doc(db(uid), 'queues', QUEUE), { anonymizePhone: true }));
        await assertFails(updateDoc(doc(db(uid), 'queues', QUEUE), { retentionDays: 60 }));
      }
    });
  });

  describe('pior caso, ownerId, deleting e alertState', () => {
    const ref = () => doc(db(OWNER), 'queues', QUEUE);
    const slots24 = Array.from({ length: 20 }, (_, i) => ({
      id: `s${i}`,
      start: `${String(i).padStart(2, '0')}:00`,
      capacity: 50,
    }));
    const alerts = { enabled: true, maxWaitMin: 240, maxNoShowPct: 100, idleMin: 240, cooldownMin: 1440 };

    it('create com 24 slots, alerts, groupId e privacidade passa', async () => {
      await assertSucceeds(
        setDoc(doc(db(OWNER), 'queues', 'big1'), {
          ownerId: OWNER,
          name: 'x'.repeat(60),
          description: 'd'.repeat(300),
          avgServiceMin: 240,
          status: 'open',
          mode: 'schedule',
          slots: slots24,
          alerts,
          groupId: 'g'.repeat(40),
          retentionDays: 730,
          anonymizePhone: true,
          expiry: { enabled: true, hours: 48, clearOnClose: true, resetTicketDaily: true },
        }),
      );
    });

    it('create com 25 slots ou slot inválido é negado', async () => {
      const base = { ownerId: OWNER, name: 'x', status: 'open', mode: 'schedule' };
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'big2'), { ...base, slots: [...slots24, slots24[0]] }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'big3'), { ...base, slots: [slots24[0], { ...slots24[1], capacity: 51 }] }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'big4'), { ...base, slots: [{ ...slots24[0], start: '24:00' }] }));
    });

    it('update com 24 slots e todos os campos validados passa', async () => {
      await assertSucceeds(
        updateDoc(ref(), {
          mode: 'schedule',
          slots: slots24,
          name: 'Novo',
          description: 'outra',
          avgServiceMin: 12,
          alerts,
          retentionDays: 365,
          anonymizePhone: true,
          expiry: { enabled: true, hours: 24, clearOnClose: true, resetTicketDaily: false },
        }),
      );
    });

    it('expiry: exige map (detalhes validados na function)', async () => {
      await assertSucceeds(updateDoc(ref(), { expiry: { enabled: false } }));
      for (const bad of ['x', 1, true, null]) {
        await assertFails(updateDoc(ref(), { expiry: bad }));
      }
    });

    it('expiry válido em fila com 20 slots e todos os campos', async () => {
      await assertSucceeds(updateDoc(ref(), { mode: 'schedule', slots: slots24 }));
      await assertSucceeds(updateDoc(ref(), { expiry: { enabled: true, hours: 12 } }));
    });

    it('create exige expiry map', async () => {
      const base = { ownerId: OWNER, name: 'x', status: 'open' };
      await assertSucceeds(setDoc(doc(db(OWNER), 'queues', 'ex1'), { ...base, expiry: { enabled: true } }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'ex2'), { ...base, expiry: 'x' }));
    });

    it('update nega slot inválido em qualquer posição', async () => {
      for (const i of [0, 11, 19]) {
        const slots = slots24.map((x, j) => (j === i ? { ...x, capacity: 0 } : x));
        await assertFails(updateDoc(ref(), { slots }));
      }
    });

    it('slots e alerts legados inalterados não bloqueiam outras atualizações', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'queues', 'old'), {
          ownerId: OWNER,
          name: 'x',
          status: 'open',
          slots: [{ id: 'a', start: '99:99', capacity: 0 }],
          alerts: { enabled: 'sim' },
        });
      });
      const old = doc(db(OWNER), 'queues', 'old');
      await assertSucceeds(updateDoc(old, { status: 'paused' }));
      await assertFails(updateDoc(old, { alerts: { enabled: 'nao' } }));
    });

    it('dono não transfere a fila e estranho não altera nada', async () => {
      await assertFails(updateDoc(ref(), { ownerId: STRANGER }));
      await assertFails(updateDoc(doc(db(STRANGER), 'queues', QUEUE), { status: 'paused' }));
      await assertFails(updateDoc(doc(db(STRANGER), 'queues', QUEUE), { ownerId: STRANGER }));
    });

    it('cliente não escreve deleting nem alertState', async () => {
      await assertFails(updateDoc(ref(), { deleting: true }));
      await assertFails(updateDoc(ref(), { alertState: { x: 1 } }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'd1'), { ownerId: OWNER, name: 'x', deleting: true }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'd2'), { ownerId: OWNER, name: 'x', alertState: {} }));
    });

    it('campos desconhecidos continuam permitidos', async () => {
      await assertSucceeds(updateDoc(ref(), { slug: 'padaria' }));
    });
  });

  describe('modo agendado e slots', () => {
    const queueRef = () => doc(db(OWNER), 'queues', QUEUE);
    const slot = (n, start = '09:00', capacity = 2) => ({ id: `s${n}`, start, capacity });

    it('dono grava modo e slots válidos', async () => {
      await assertSucceeds(updateDoc(queueRef(), { mode: 'schedule', slots: [slot(1), slot(2, '10:30', 50)] }));
      await assertSucceeds(updateDoc(queueRef(), { mode: 'queue', slots: [] }));
    });

    it('aceita exatamente 24 slots e nega 25', async () => {
      const slots = Array.from({ length: 20 }, (_, i) => slot(i, `${String(i).padStart(2, '0')}:00`));
      await assertSucceeds(updateDoc(queueRef(), { mode: 'schedule', slots }));
      await assertFails(updateDoc(queueRef(), { mode: 'schedule', slots: [...slots, slot(24, '23:30')] }));
    });

    it('nega modo, horário, capacidade e campos inválidos', async () => {
      await assertFails(updateDoc(queueRef(), { mode: 'agenda' }));
      await assertFails(updateDoc(queueRef(), { mode: 1 }));
      for (const bad of [
        slot(1, '24:00'),
        slot(1, '9:00'),
        slot(1, '09:00', 0),
        slot(1, '09:00', 51),
        slot(1, '09:00', 1.5),
        slot(1, '09:00', '2'),
        { id: 's1', start: '09:00' },
        { id: 's1', capacity: 2 },
        'x',
      ]) {
        await assertFails(updateDoc(queueRef(), { mode: 'schedule', slots: [slot(0), bad] }));
      }
      await assertFails(updateDoc(queueRef(), { slots: 'x' }));
    });

    it('create da fila valida modo e slots', async () => {
      const base = { ownerId: OWNER, name: 'Nova', status: 'open' };
      await assertSucceeds(setDoc(doc(db(OWNER), 'queues', 'n1'), { ...base, mode: 'schedule', slots: [slot(1)] }));
      await assertFails(setDoc(doc(db(OWNER), 'queues', 'n2'), { ...base, mode: 'schedule', slots: [slot(1, '99:99')] }));
    });

    it('operador e estranho não gravam modo nem slots', async () => {
      for (const uid of [OPERATOR, STRANGER]) {
        await assertFails(updateDoc(doc(db(uid), 'queues', QUEUE), { mode: 'schedule', slots: [slot(1)] }));
      }
    });
  });

  describe('alertas', () => {
    const queueRef = () => doc(db(OWNER), 'queues', QUEUE);
    const valid = { enabled: true, maxWaitMin: 30, maxNoShowPct: 40, idleMin: 15, cooldownMin: 30 };

    it('dono grava configuração válida', async () => {
      await assertSucceeds(updateDoc(queueRef(), { alerts: valid }));
    });

    it('dono aceita limites nulos', async () => {
      await assertSucceeds(
        updateDoc(queueRef(), { alerts: { enabled: false, maxWaitMin: null, maxNoShowPct: null, idleMin: null } }),
      );
    });

    it('não-dono não grava', async () => {
      await assertFails(updateDoc(doc(db(STRANGER), 'queues', QUEUE), { alerts: valid }));
      await assertFails(updateDoc(doc(db(OPERATOR), 'queues', QUEUE), { alerts: valid }));
    });

    it('nega limites fora do intervalo', async () => {
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, maxWaitMin: 241 } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, maxWaitMin: 0 } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, maxNoShowPct: 101 } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, idleMin: 4 } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, cooldownMin: 1 } }));
    });

    it('nega tipos inválidos e campos extras', async () => {
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, maxWaitMin: '30' } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, enabled: 'yes' } }));
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, extra: 1 } }));
    });

    it('nega double no limite', async () => {
      await assertFails(updateDoc(queueRef(), { alerts: { ...valid, maxWaitMin: 30.5 } }));
    });

    it('create da fila valida alerts e nega alertState', async () => {
      const ref = doc(db(OWNER), 'queues', 'novaFila');
      const base = { ownerId: OWNER, name: 'Nova', status: 'open' };
      await assertSucceeds(setDoc(ref, { ...base, alerts: valid }));
      const ref2 = doc(db(OWNER), 'queues', 'novaFila2');
      await assertFails(setDoc(ref2, { ...base, alerts: { ...valid, maxWaitMin: 30.5 } }));
      await assertFails(setDoc(ref2, { ...base, alertState: { waitAt: 123 } }));
    });

    it('dono grava notifyAlerts em owners/{uid}', async () => {
      await assertSucceeds(setDoc(doc(db(OWNER), 'owners', OWNER), { notifyAlerts: false }, { merge: true }));
      await assertFails(setDoc(doc(db(STRANGER), 'owners', OWNER), { notifyAlerts: false }, { merge: true }));
    });

    it('dono não escreve alertState', async () => {
      await assertFails(updateDoc(queueRef(), { alertState: { waitAt: 1 } }));
    });
  });

  describe('histórico', () => {
    it('operador cria registro com o próprio operatorId', async () => {
      await assertSucceeds(setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h2'), historyEntry(OPERATOR)));
    });

    it('operador não cria registro em nome de outro', async () => {
      await assertFails(setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h2'), historyEntry(OWNER)));
    });

    it('operador não cria registro com resultado inválido', async () => {
      await assertFails(
        setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h2'), { ...historyEntry(OPERATOR), result: 'left' }),
      );
    });

    it('operador não cria registro com campos extras', async () => {
      await assertFails(
        setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h2'), { ...historyEntry(OPERATOR), extra: true }),
      );
    });

    it('operador não cria registro incompleto', async () => {
      await assertFails(
        setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h2'), { operatorId: OPERATOR, result: 'served' }),
      );
    });

    it('operador não sobrescreve registro existente', async () => {
      await assertFails(setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h1'), historyEntry(OPERATOR)));
    });

    it('operador cria registro com recalls e skips', async () => {
      await assertSucceeds(
        setDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h3'), { ...historyEntry(OPERATOR), recalls: 2, skips: 1 }),
      );
    });

    it('operador não lê o histórico', async () => {
      await assertFails(getDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'h1')));
      await assertFails(getDocs(collection(db(OPERATOR), 'queues', QUEUE, 'history')));
    });

    it('estranho não cria registro', async () => {
      await assertFails(setDoc(doc(db(STRANGER), 'queues', QUEUE, 'history', 'h2'), historyEntry(STRANGER)));
    });

    it('dono lê registro com result left', async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'queues', QUEUE, 'history', 'left1'), {
          ...historyEntry(null),
          result: 'left',
          calledAt: null,
          calledBy: null,
        });
      });
      await assertSucceeds(getDoc(doc(db(OWNER), 'queues', QUEUE, 'history', 'left1')));
      await assertFails(getDoc(doc(db(OPERATOR), 'queues', QUEUE, 'history', 'left1')));
    });

    it('dono lê o histórico', async () => {
      await assertSucceeds(getDocs(collection(db(OWNER), 'queues', QUEUE, 'history')));
    });

    it('dono lê history ordenado por finishedAt', async () => {
      await assertSucceeds(
        getDocs(
          query(collection(db(OWNER), 'queues', QUEUE, 'history'), orderBy('finishedAt', 'desc'), limit(200)),
        ),
      );
    });

    it('operador não lê history ordenado por finishedAt', async () => {
      await assertFails(
        getDocs(
          query(collection(db(OPERATOR), 'queues', QUEUE, 'history'), orderBy('finishedAt', 'desc'), limit(200)),
        ),
      );
    });
  });

  describe('convites', () => {
    it('usuário logado lê convite pelo código', async () => {
      await assertSucceeds(getDoc(doc(db(STRANGER), 'operatorInvites', 'VALID1')));
    });

    it('usuário com provedor lê convite', async () => {
      await assertSucceeds(getDoc(doc(googleDb(STRANGER), 'operatorInvites', 'VALID1')));
    });

    it('usuário anônimo não lê convite', async () => {
      await assertFails(getDoc(doc(anonDb(STRANGER), 'operatorInvites', 'VALID1')));
    });

    it('usuário com provedor password lê convite', async () => {
      await assertSucceeds(getDoc(doc(passwordDb(STRANGER), 'operatorInvites', 'VALID1')));
    });

    it('token sem a claim firebase não lê convite', async () => {
      await assertFails(getDoc(doc(noProviderDb(STRANGER), 'operatorInvites', 'VALID1')));
    });

    it('anônimo não lista convites', async () => {
      await assertFails(getDocs(collection(anonDb(STRANGER), 'operatorInvites')));
    });

    it('estranho não cria convite para a fila de outro', async () => {
      await assertFails(
        setDoc(doc(db(STRANGER), 'operatorInvites', 'NEW001'), { queueId: QUEUE, ownerId: STRANGER, expiresAt: null }),
      );
    });

    it('operador não cria convite', async () => {
      await assertFails(
        setDoc(doc(db(OPERATOR), 'operatorInvites', 'NEW001'), { queueId: QUEUE, ownerId: OPERATOR, expiresAt: null }),
      );
    });

    it('dono cria convite', async () => {
      await assertSucceeds(
        setDoc(doc(db(OWNER), 'operatorInvites', 'NEW001'), { queueId: QUEUE, ownerId: OWNER, expiresAt: hoursFromNow(24) }),
      );
    });

    it('estranho não revoga convite', async () => {
      await assertFails(deleteDoc(doc(db(STRANGER), 'operatorInvites', 'VALID1')));
    });
  });

  describe('pedidos de operador', () => {
    const request = (uid, code, status = 'pending') => ({ uid, queueId: QUEUE, code, status });
    const requestDoc = (uid, as = uid) => doc(db(as), 'queues', QUEUE, 'operatorRequests', uid);

    it('pedido com convite válido é criado', async () => {
      await assertSucceeds(setDoc(requestDoc(STRANGER), request(STRANGER, 'VALID1')));
    });

    it('pedido de usuário com provedor é criado', async () => {
      await assertSucceeds(setDoc(doc(googleDb(STRANGER), 'queues', QUEUE, 'operatorRequests', STRANGER), request(STRANGER, 'VALID1')));
    });

    it('pedido de usuário anônimo falha', async () => {
      await assertFails(setDoc(doc(anonDb(STRANGER), 'queues', QUEUE, 'operatorRequests', STRANGER), request(STRANGER, 'VALID1')));
    });

    it('pedido de usuário password é criado', async () => {
      await assertSucceeds(setDoc(doc(passwordDb(STRANGER), 'queues', QUEUE, 'operatorRequests', STRANGER), request(STRANGER, 'VALID1')));
    });

    it('pedido sem a claim firebase falha', async () => {
      await assertFails(setDoc(doc(noProviderDb(STRANGER), 'queues', QUEUE, 'operatorRequests', STRANGER), request(STRANGER, 'VALID1')));
    });

    it('anônimo não refaz pedido já recusado', async () => {
      await assertFails(
        updateDoc(doc(anonDb('rejectedUser'), 'queues', QUEUE, 'operatorRequests', 'rejectedUser'), { status: 'pending' }),
      );
    });

    it('usuário com provedor refaz o próprio pedido recusado', async () => {
      await assertSucceeds(
        updateDoc(doc(googleDb('rejectedUser'), 'queues', QUEUE, 'operatorRequests', 'rejectedUser'), { status: 'pending' }),
      );
    });

    it('pedido com convite expirado falha', async () => {
      await assertFails(setDoc(requestDoc(STRANGER), request(STRANGER, 'EXPIR1')));
    });

    it('pedido com convite de outra fila falha', async () => {
      await assertFails(setDoc(requestDoc(STRANGER), request(STRANGER, 'OTHER1')));
    });

    it('pedido com código inexistente falha', async () => {
      await assertFails(setDoc(requestDoc(STRANGER), request(STRANGER, 'NOPE00')));
    });

    it('pedido já aprovado na criação falha', async () => {
      await assertFails(setDoc(requestDoc(STRANGER), request(STRANGER, 'VALID1', 'approved')));
    });

    it('pedido em nome de outro usuário falha', async () => {
      await assertFails(setDoc(requestDoc('victim', STRANGER), request('victim', 'VALID1')));
    });

    it('solicitante não aprova o próprio pedido', async () => {
      await assertFails(updateDoc(requestDoc('pendingUser'), { status: 'approved' }));
    });

    it('operador não aprova pedido de outro', async () => {
      await assertFails(updateDoc(requestDoc('pendingUser', OPERATOR), { status: 'approved' }));
    });

    it('dono aprova', async () => {
      await assertSucceeds(updateDoc(requestDoc('pendingUser', OWNER), { status: 'approved' }));
    });

    it('dono recusa', async () => {
      await assertSucceeds(updateDoc(requestDoc('pendingUser', OWNER), { status: 'rejected' }));
    });

    it('dono marca como removido', async () => {
      await assertSucceeds(updateDoc(requestDoc('pendingUser', OWNER), { status: 'removed' }));
    });

    it('dono não altera outros campos do pedido', async () => {
      await assertFails(updateDoc(requestDoc('pendingUser', OWNER), { status: 'approved', uid: OWNER }));
    });

    it('só o dono lista os pedidos da fila', async () => {
      await assertSucceeds(getDocs(collection(db(OWNER), 'queues', QUEUE, 'operatorRequests')));
      await assertFails(getDocs(collection(db(OPERATOR), 'queues', QUEUE, 'operatorRequests')));
    });
  });

  describe('operadores', () => {
    it('operador não se adiciona sozinho', async () => {
      await assertFails(setDoc(doc(db(STRANGER), 'queues', QUEUE, 'operators', STRANGER), { uid: STRANGER }));
    });

    it('operador não remove outro operador', async () => {
      await assertFails(deleteDoc(doc(db(STRANGER), 'queues', QUEUE, 'operators', OPERATOR)));
    });

    it('dono remove operador', async () => {
      await assertSucceeds(deleteDoc(doc(db(OWNER), 'queues', QUEUE, 'operators', OPERATOR)));
    });

    it('operador lê o próprio vínculo', async () => {
      await assertSucceeds(getDoc(doc(db(OPERATOR), 'queues', QUEUE, 'operators', OPERATOR)));
    });

    it('usuário lê o próprio vínculo mesmo se não existir', async () => {
      await assertSucceeds(getDoc(doc(db(STRANGER), 'queues', QUEUE, 'operators', STRANGER)));
    });

    it('estranho não lê vínculo de outro', async () => {
      await assertFails(getDoc(doc(db(STRANGER), 'queues', QUEUE, 'operators', OPERATOR)));
    });
  });

  describe('collectionGroup', () => {
    it('operador consulta só os próprios vínculos', async () => {
      await assertSucceeds(
        getDocs(query(collectionGroup(db(OPERATOR), 'operators'), where('uid', '==', OPERATOR))),
      );
    });

    it('consulta de vínculos de outro usuário falha', async () => {
      await assertFails(
        getDocs(query(collectionGroup(db(STRANGER), 'operators'), where('uid', '==', OPERATOR))),
      );
    });

    it('consulta sem filtro falha', async () => {
      await assertFails(getDocs(collectionGroup(db(STRANGER), 'operators')));
      await assertFails(getDocs(collectionGroup(db(STRANGER), 'operatorRequests')));
    });

    it('usuário consulta só os próprios pedidos', async () => {
      await assertSucceeds(
        getDocs(query(collectionGroup(db('pendingUser'), 'operatorRequests'), where('uid', '==', 'pendingUser'))),
      );
    });
  });

  describe('queueSlugs', () => {
    const slugDoc = (overrides = {}) => ({
      queueId: QUEUE,
      ownerId: OWNER,
      createdAt: serverTimestamp(),
      ...overrides,
    });
    const seedSlug = (slug, data = { queueId: QUEUE, ownerId: OWNER, createdAt: Timestamp.now() }) =>
      env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'queueSlugs', slug), data));

    it('dono cria slug válido para a própria fila', async () => {
      await assertSucceeds(setDoc(doc(db(OWNER), 'queueSlugs', 'minha-loja'), slugDoc()));
    });

    it('aceita limites de tamanho 3 e 40', async () => {
      await assertSucceeds(setDoc(doc(db(OWNER), 'queueSlugs', 'abc'), slugDoc()));
      await assertSucceeds(setDoc(doc(db(OWNER), 'queueSlugs', 'a'.repeat(40)), slugDoc()));
    });

    it('recusa formato inválido', async () => {
      for (const bad of ['ab', 'a'.repeat(41), '-abc', 'abc-', 'ab_c', 'ABC', 'a b', 'café', 'a.b']) {
        await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', bad), slugDoc()));
      }
    });

    it('recusa slugs reservados', async () => {
      for (const word of ['admin', 'api', 'app', 'privacidade', 'termos', 'assets', 'fonts', 'icons']) {
        await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', word), slugDoc()));
      }
    });

    it('colisão: slug existente não pode ser recriado nem por outro dono nem pelo mesmo', async () => {
      await seedSlug('padaria');
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'padaria'), slugDoc()));
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), 'queues', 'q2'), { ownerId: STRANGER, name: 'Outra', status: 'open' }),
      );
      await assertFails(
        setDoc(doc(db(STRANGER), 'queueSlugs', 'padaria'), slugDoc({ queueId: 'q2', ownerId: STRANGER })),
      );
      await env.withSecurityRulesDisabled(async (ctx) => {
        const snap = await getDoc(doc(ctx.firestore(), 'queueSlugs', 'padaria'));
        assert.equal(snap.get('ownerId'), OWNER);
      });
    });

    it('não cria slug para fila de outro dono', async () => {
      await assertFails(setDoc(doc(db(STRANGER), 'queueSlugs', 'roubado'), slugDoc({ ownerId: STRANGER })));
    });

    it('não cria com ownerId de outro', async () => {
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'falso'), slugDoc({ ownerId: STRANGER })));
    });

    it('operador não cria slug', async () => {
      await assertFails(setDoc(doc(db(OPERATOR), 'queueSlugs', 'operador'), slugDoc({ ownerId: OPERATOR })));
    });

    it('não autenticado não cria', async () => {
      const anon = env.unauthenticatedContext().firestore();
      await assertFails(setDoc(doc(anon, 'queueSlugs', 'sem-login'), slugDoc()));
    });

    it('recusa campos extras, faltando campo ou createdAt arbitrário', async () => {
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'extra'), slugDoc({ x: 1 })));
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'sem-data'), { queueId: QUEUE, ownerId: OWNER }));
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'data-falsa'), slugDoc({ createdAt: Timestamp.fromMillis(1) })));
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'fila-num'), slugDoc({ queueId: 5 })));
    });

    it('slug de fila inexistente é recusado', async () => {
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'fantasma'), slugDoc({ queueId: 'nao-existe' })));
    });

    it('update é sempre recusado', async () => {
      await seedSlug('padaria');
      await assertFails(updateDoc(doc(db(OWNER), 'queueSlugs', 'padaria'), { queueId: 'q2' }));
    });

    it('listagem é recusada para todos', async () => {
      await seedSlug('padaria');
      await assertFails(getDocs(collection(db(OWNER), 'queueSlugs')));
      await assertFails(getDocs(query(collection(db(OWNER), 'queueSlugs'), where('ownerId', '==', OWNER))));
      await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'queueSlugs')));
    });

    it('get só para o dono do slug', async () => {
      await seedSlug('padaria');
      await assertSucceeds(getDoc(doc(db(OWNER), 'queueSlugs', 'padaria')));
      await assertFails(getDoc(doc(db(STRANGER), 'queueSlugs', 'padaria')));
    });

    it('ninguém apaga o slug (só tombstone)', async () => {
      await seedSlug('padaria');
      await assertFails(deleteDoc(doc(db(STRANGER), 'queueSlugs', 'padaria')));
      await assertFails(deleteDoc(doc(db(OWNER), 'queueSlugs', 'padaria')));
    });

    it('anônimo não cria slug nem para a própria fila', async () => {
      await assertFails(setDoc(doc(anonDb(OWNER), 'queueSlugs', 'anonimo'), slugDoc()));
    });

    it('queueId com caracteres inválidos é recusado', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), 'queues', 'a.b'), { ownerId: OWNER, name: 'X', status: 'open' }),
      );
      await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'ponto'), slugDoc({ queueId: 'a.b' })));
    });

    describe('tombstone', () => {
      const daysAgo = (d) => Timestamp.fromMillis(Date.now() - d * 86400 * 1000);
      const tomb = (ownerId, daysOld) => ({
        queueId: 'q-velha',
        ownerId,
        createdAt: daysAgo(daysOld + 5),
        released: true,
        releasedAt: daysAgo(daysOld),
      });

      beforeEach(async () => {
        await env.withSecurityRulesDisabled((ctx) =>
          setDoc(doc(ctx.firestore(), 'queues', 'q2'), { ownerId: STRANGER, name: 'Outra', status: 'open' }),
        );
      });

      it('dono libera o próprio slug (tombstone)', async () => {
        await seedSlug('padaria');
        const ref = doc(db(OWNER), 'queueSlugs', 'padaria');
        await assertSucceeds(updateDoc(ref, { released: true, releasedAt: serverTimestamp() }));
        await env.withSecurityRulesDisabled(async (ctx) => {
          const snap = await getDoc(doc(ctx.firestore(), 'queueSlugs', 'padaria'));
          assert.equal(snap.get('released'), true);
          assert.equal(snap.get('queueId'), QUEUE);
        });
      });

      it('estranho não libera slug alheio', async () => {
        await seedSlug('padaria');
        await assertFails(
          updateDoc(doc(db(STRANGER), 'queueSlugs', 'padaria'), { released: true, releasedAt: serverTimestamp() }),
        );
      });

      it('liberar não aceita releasedAt arbitrário nem outros campos', async () => {
        await seedSlug('padaria');
        const ref = doc(db(OWNER), 'queueSlugs', 'padaria');
        await assertFails(updateDoc(ref, { released: true, releasedAt: Timestamp.fromMillis(1) }));
        await assertFails(updateDoc(ref, { released: true, releasedAt: serverTimestamp(), queueId: 'q2' }));
        await assertFails(updateDoc(ref, { released: true, releasedAt: serverTimestamp(), extra: 1 }));
      });

      it('outro dono NÃO toma o slug dentro de 30 dias', async () => {
        await seedSlug('velho', tomb(OWNER, 1));
        await assertFails(
          setDoc(doc(db(STRANGER), 'queueSlugs', 'velho'), slugDoc({ queueId: 'q2', ownerId: STRANGER })),
        );
        await seedSlug('quase', tomb(OWNER, 29));
        await assertFails(
          setDoc(doc(db(STRANGER), 'queueSlugs', 'quase'), slugDoc({ queueId: 'q2', ownerId: STRANGER })),
        );
      });

      it('mesmo dono retoma dentro dos 30 dias', async () => {
        await seedSlug('velho', tomb(OWNER, 1));
        await assertSucceeds(setDoc(doc(db(OWNER), 'queueSlugs', 'velho'), slugDoc()));
        await env.withSecurityRulesDisabled(async (ctx) => {
          const snap = await getDoc(doc(ctx.firestore(), 'queueSlugs', 'velho'));
          assert.equal(snap.get('released'), undefined);
          assert.equal(snap.get('queueId'), QUEUE);
        });
      });

      it('após 30 dias outro dono toma o slug', async () => {
        await seedSlug('velho', tomb(OWNER, 31));
        await assertSucceeds(
          setDoc(doc(db(STRANGER), 'queueSlugs', 'velho'), slugDoc({ queueId: 'q2', ownerId: STRANGER })),
        );
      });

      it('retomar tombstone exige as validações de criação', async () => {
        await seedSlug('velho', tomb(OWNER, 31));
        await assertFails(
          setDoc(doc(anonDb(STRANGER), 'queueSlugs', 'velho'), slugDoc({ queueId: 'q2', ownerId: STRANGER })),
        );
        await assertFails(setDoc(doc(db(STRANGER), 'queueSlugs', 'velho'), slugDoc({ ownerId: STRANGER })));
      });

      it('slug ativo não pode ser retomado nem pelo dono', async () => {
        await seedSlug('ativo');
        await assertFails(setDoc(doc(db(OWNER), 'queueSlugs', 'ativo'), slugDoc()));
      });

      it('tombstone é legível por qualquer logado; ativo só pelo dono', async () => {
        await seedSlug('velho', tomb(OWNER, 1));
        await seedSlug('ativo');
        await assertSucceeds(getDoc(doc(db(STRANGER), 'queueSlugs', 'velho')));
        await assertFails(getDoc(doc(db(STRANGER), 'queueSlugs', 'ativo')));
        await assertSucceeds(getDoc(doc(db(STRANGER), 'queueSlugs', 'inexistente')));
      });

      it('troca em batch deixa tombstone do antigo e grava o novo', async () => {
        await seedSlug('antigo');
        await env.withSecurityRulesDisabled((ctx) =>
          updateDoc(doc(ctx.firestore(), 'queues', QUEUE), { slug: 'antigo' }),
        );
        const fs = db(OWNER);
        const batch = writeBatch(fs);
        batch.set(doc(fs, 'queueSlugs', 'novo-nome'), slugDoc());
        batch.update(doc(fs, 'queueSlugs', 'antigo'), { released: true, releasedAt: serverTimestamp() });
        batch.update(doc(fs, 'queues', QUEUE), { slug: 'novo-nome' });
        await assertSucceeds(batch.commit());
        await env.withSecurityRulesDisabled(async (ctx) => {
          const old = await getDoc(doc(ctx.firestore(), 'queueSlugs', 'antigo'));
          assert.equal(old.get('released'), true);
          const next = await getDoc(doc(ctx.firestore(), 'queueSlugs', 'novo-nome'));
          assert.equal(next.get('queueId'), QUEUE);
        });
      });
    });

    it('batch com slug em uso falha inteiro e não altera a fila', async () => {
      await seedSlug('ocupado', { queueId: 'q2', ownerId: STRANGER, createdAt: Timestamp.now() });
      const fs = db(OWNER);
      const batch = writeBatch(fs);
      batch.set(doc(fs, 'queueSlugs', 'ocupado'), slugDoc());
      batch.update(doc(fs, 'queues', QUEUE), { slug: 'ocupado' });
      await assertFails(batch.commit());
      await env.withSecurityRulesDisabled(async (ctx) => {
        const queue = await getDoc(doc(ctx.firestore(), 'queues', QUEUE));
        assert.equal(queue.get('slug'), undefined);
      });
    });

    it('pior caso: 20 slots + slug + posterTitle no mesmo update e batch com slug', async () => {
      const slots = Array.from({ length: 20 }, (_, i) => ({
        id: `s${i}`,
        start: `${String(i).padStart(2, '0')}:00`,
        capacity: 50,
      }));
      const fs = db(OWNER);
      await assertSucceeds(
        updateDoc(doc(fs, 'queues', QUEUE), { mode: 'schedule', slots, slug: 'com-slots', posterTitle: 'Olá' }),
      );
      const batch = writeBatch(fs);
      batch.set(doc(fs, 'queueSlugs', 'novo-slug'), slugDoc());
      batch.update(doc(fs, 'queues', QUEUE), { slug: 'novo-slug', slots });
      await assertSucceeds(batch.commit());
    });

    it('dono grava slug e posterTitle na fila sem validação extra', async () => {
      await assertSucceeds(
        updateDoc(doc(db(OWNER), 'queues', QUEUE), { slug: 'minha-loja', posterTitle: 'Entre na fila' }),
      );
    });
  });
});
