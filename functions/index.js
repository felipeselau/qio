const { onValueWritten } = require('firebase-functions/v2/database');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');
const {
  DEFAULT_RATE_LIMIT,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
} = require('./lib/join');

initializeApp();

exports.onEntryCalled = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const after = event.data.after.val();
    const before = event.data.before.val();

    const wasCalled = before?.status === 'called';
    const isCalled = after?.status === 'called';
    if (wasCalled || !isCalled) {
      return null;
    }

    const token = after.fcmToken;
    if (!token) {
      return null;
    }

    const queueId = event.params.queueId;
    let queueName = 'Fila';
    try {
      const metaSnap = await getDatabase()
        .ref(`queues/${queueId}/meta/name`)
        .once('value');
      if (metaSnap.exists()) {
        queueName = metaSnap.val();
      }
    } catch {
      // fallback name
    }

    const ticket = after.ticket ?? '';

    const message = {
      token,
      notification: {
        title: 'É a sua vez!',
        body: `Senha #${ticket} — dirija-se ao atendimento (${queueName})`,
      },
      webpush: {
        fcmOptions: {
          link: `https://qio.web.app/q/${queueId}`,
        },
      },
    };

    try {
      await getMessaging().send(message);
      return { ok: true };
    } catch (err) {
      console.error('FCM send failed', err);
      return null;
    }
  },
);

const ACTIVE_STATUSES = ['waiting', 'called'];

function findActive(snap) {
  const found = [];
  snap.forEach((child) => {
    const val = child.val();
    if (val && ACTIVE_STATUSES.includes(val.status)) {
      found.push({ entryId: child.key, ...val });
    }
  });
  return found;
}

exports.joinQueue = onCall(
  {
    region: 'us-central1',
    enforceAppCheck: process.env.ENFORCE_APP_CHECK === 'true',
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para entrar na fila.');
    }

    const data = request.data ?? {};
    const queueId = typeof data.queueId === 'string' ? data.queueId.trim() : '';
    if (!queueId || queueId.includes('/') || /[.#$\[\]]/.test(queueId)) {
      throw new HttpsError('invalid-argument', 'Fila inválida.');
    }
    const name = normalizeName(data.name);
    if (!name) {
      throw new HttpsError(
        'invalid-argument',
        'Informe um nome com até 60 caracteres.',
      );
    }
    const phone = data.phone === undefined || data.phone === null ? '' : data.phone;
    if (typeof phone !== 'string' || !isValidPhone(phone.trim())) {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use o formato (00) 00000-0000.',
      );
    }
    const cleanPhone = phone.trim();

    const db = getDatabase();
    const metaSnap = await db.ref(`queues/${queueId}/meta`).once('value');
    if (!metaSnap.exists()) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    if (metaSnap.child('status').val() !== 'open') {
      throw new HttpsError('failed-precondition', 'Fila fechada ou pausada.');
    }

    const entriesRef = db.ref(`queues/${queueId}/entries`);

    const mine = findActive(
      await entriesRef.orderByChild('uid').equalTo(uid).once('value'),
    );
    if (mine.length > 0) {
      const existing = mine.sort((a, b) => (a.joinedAt ?? 0) - (b.joinedAt ?? 0))[0];
      return { entryId: existing.entryId, ticket: existing.ticket, existing: true };
    }

    if (cleanPhone) {
      const samePhone = findActive(
        await entriesRef.orderByChild('phone').equalTo(cleanPhone).once('value'),
      );
      if (samePhone.length > 0) {
        throw new HttpsError('already-exists', 'Este telefone já está na fila.');
      }
    }

    const now = Date.now();
    let limited = false;
    await db.ref(`rateLimits/${queueId}/${uid}`).transaction((current) => {
      const recent = pruneTimestamps(current, now, DEFAULT_RATE_LIMIT.windowMs);
      if (isRateLimited(recent, now, DEFAULT_RATE_LIMIT)) {
        limited = true;
        return recent;
      }
      limited = false;
      return [...recent, now];
    });
    if (limited) {
      throw new HttpsError(
        'resource-exhausted',
        'Muitas tentativas. Aguarde alguns minutos.',
      );
    }

    const ticketResult = await db
      .ref(`tickets/${queueId}`)
      .transaction((current) => (current ?? 0) + 1);
    const ticket = ticketResult.snapshot.val();

    const newRef = entriesRef.push();
    await newRef.set({
      ticket,
      name,
      phone: cleanPhone,
      uid,
      status: 'waiting',
      joinedAt: Date.now(),
    });

    return { entryId: newRef.key, ticket, existing: false };
  },
);

exports.syncPublicTicket = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const after = event.data.after.val();
    const { queueId, entryId } = event.params;
    const publicRef = getDatabase().ref(`queues/${queueId}/public/${entryId}`);
    if (after && ACTIVE_STATUSES.includes(after.status)) {
      await publicRef.set({ ticket: after.ticket, status: after.status });
    } else {
      await publicRef.remove();
    }
    return null;
  },
);
