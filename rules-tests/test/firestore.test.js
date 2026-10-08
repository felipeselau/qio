import { after, before, beforeEach, describe, it } from 'node:test';
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
  setDoc,
  updateDoc,
  where,
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
  });

  describe('modo agendado e slots', () => {
    const queueRef = () => doc(db(OWNER), 'queues', QUEUE);
    const slot = (n, start = '09:00', capacity = 2) => ({ id: `s${n}`, start, capacity });

    it('dono grava modo e slots válidos', async () => {
      await assertSucceeds(updateDoc(queueRef(), { mode: 'schedule', slots: [slot(1), slot(2, '10:30', 50)] }));
      await assertSucceeds(updateDoc(queueRef(), { mode: 'queue', slots: [] }));
    });

    it('aceita exatamente 24 slots e nega 25', async () => {
      const slots = Array.from({ length: 24 }, (_, i) => slot(i, `${String(i).padStart(2, '0')}:00`));
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
});
