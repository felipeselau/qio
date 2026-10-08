const { onValueWritten, onValueCreated } = require('firebase-functions/v2/database');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const {
  rateLimitFromEnv,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
} = require('./src/join');
const { historyFromLeftEntry } = require('./src/history');
const { isQueueFull } = require('./src/capacity');
const { publicTicketFor, shouldRenotify } = require('./src/ticket');
const { planScheduleChange } = require('./src/schedule');
const {
  buildNewEntryMessage,
  recipientUids,
  wantsNewEntryPush,
  isStaleTokenError,
  groupTokensByLang,
  normalizeLang,
} = require('./src/push');
const {
  buildCalledMessage,
  buildNextMessage,
  pickNextWaiting,
  advancedFromWaiting,
} = require('./src/webpush');
const {
  normalizeRating,
  normalizeComment,
  isValidId,
  buildFeedbackDoc,
} = require('./src/feedback');
const { MAX_SAMPLES, estimateServiceMin } = require('./src/estimate');
const {
  evaluateAlerts,
  stateAfter,
  startOfDaySaoPaulo,
  lastActivityOf,
  mapLimit,
  buildAlertPush,
  wantsAlertPush,
} = require('./src/alerts');
const { logError, logAppCheck } = require('./src/log');
const { guarded } = require('./src/guard');
const { isEnforced } = require('./src/appcheck');

initializeApp();

const ALERT_CONCURRENCY = 5;

const RATE_LIMIT = rateLimitFromEnv(process.env);

exports.onEntryCalled = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const after = event.data.after.val();
    const before = event.data.before.val();

    if (!shouldRenotify(before, after)) {
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

    const message = buildCalledMessage({
      token,
      ticket: after.ticket,
      queueName,
      queueId,
      lang: after.lang,
    });

    try {
      await getMessaging().send(message);
      return { ok: true };
    } catch (err) {
      logError('onEntryCalled failed', err, { queueId });
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
    invoker: 'public',
    enforceAppCheck: isEnforced('joinQueue'),
  },
  guarded('joinQueue', async (request) => {
    logAppCheck('joinQueue', request);
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
    const lang = normalizeLang(data.lang);

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

    const maxWaiting = metaSnap.child('maxWaiting').val();
    if (maxWaiting) {
      const waitingSnap = await entriesRef
        .orderByChild('status')
        .equalTo('waiting')
        .once('value');
      if (isQueueFull(maxWaiting, waitingSnap.numChildren())) {
        throw new HttpsError('resource-exhausted', 'Fila lotada no momento.', {
          reason: 'queue-full',
        });
      }
    }

    const now = Date.now();
    let limited = false;
    await db.ref(`rateLimits/${queueId}/${uid}`).transaction((current) => {
      const recent = pruneTimestamps(current, now, RATE_LIMIT.windowMs);
      if (isRateLimited(recent, now, RATE_LIMIT)) {
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
      lang,
      status: 'waiting',
      joinedAt: Date.now(),
    });

    return { entryId: newRef.key, ticket, existing: false };
  }),
);

exports.submitFeedback = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: isEnforced('submitFeedback'),
  },
  guarded('submitFeedback', async (request) => {
    logAppCheck('submitFeedback', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para avaliar.');
    }
    const data = request.data ?? {};
    if (!isValidId(data.queueId) || !isValidId(data.entryId)) {
      throw new HttpsError('invalid-argument', 'Atendimento inválido.');
    }
    const rating = normalizeRating(data.rating);
    if (rating === null) {
      throw new HttpsError('invalid-argument', 'A nota deve ser de 1 a 5.');
    }
    const comment = normalizeComment(data.comment);
    if (comment === null) {
      throw new HttpsError('invalid-argument', 'Comentário muito longo.');
    }

    const firestore = getFirestore();
    const historySnap = await firestore
      .doc(`queues/${data.queueId}/history/${data.entryId}`)
      .get();
    if (!historySnap.exists || historySnap.get('result') !== 'served') {
      throw new HttpsError('failed-precondition', 'Atendimento não encontrado.');
    }

    try {
      await firestore
        .doc(`queues/${data.queueId}/feedback/${data.entryId}`)
        .create(buildFeedbackDoc({ rating, comment, uid }, Date.now()));
    } catch (err) {
      if (err?.code !== 6) throw err;
      return { ok: true, existing: true };
    }
    return { ok: true, existing: false };
  }),
);

exports.syncPublicTicket = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const after = event.data.after.val();
    const { queueId, entryId } = event.params;
    const db = getDatabase();
    const publicRef = db.ref(`queues/${queueId}/public/${entryId}`);
    try {
      if (after && after.status === 'left') {
        try {
          await archiveLeftEntry(queueId, entryId, after);
          await db.ref(`queues/${queueId}/entries/${entryId}`).remove();
        } finally {
          await publicRef.remove();
        }
      } else if (after && ACTIVE_STATUSES.includes(after.status)) {
        await publicRef.set(publicTicketFor(after));
      } else {
        await publicRef.remove();
      }
    } catch (err) {
      logError('syncPublicTicket failed', err, { queueId, entryId });
      throw err;
    }
    return null;
  },
);

async function archiveLeftEntry(queueId, entryId, entry) {
  const firestore = getFirestore();
  const queueDoc = await firestore.doc(`queues/${queueId}`).get();
  if (!queueDoc.exists) return;
  try {
    await firestore
      .doc(`queues/${queueId}/history/${entryId}`)
      .create(historyFromLeftEntry(entry, Date.now()));
  } catch (err) {
    if (err?.code !== 6) throw err;
  }
}

exports.updateServiceEstimate = onDocumentCreated(
  {
    document: 'queues/{queueId}/history/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const { queueId } = event.params;
    try {
      const snap = await getFirestore()
        .collection(`queues/${queueId}/history`)
        .where('result', '==', 'served')
        .orderBy('finishedAt', 'desc')
        .limit(MAX_SAMPLES)
        .get();
      const estimate = estimateServiceMin(snap.docs.map((d) => d.data()));
      if (estimate === null) return null;

      const metaRef = getDatabase().ref(`queues/${queueId}/meta`);
      const metaSnap = await metaRef.once('value');
      if (!metaSnap.exists()) return null;
      await metaRef.child('avgServiceMinAuto').set(estimate);
      return { ok: true };
    } catch (err) {
      logError('updateServiceEstimate failed', err, { queueId });
      return null;
    }
  },
);

exports.applyQueueSchedules = onSchedule(
  { schedule: 'every 5 minutes', region: 'us-central1', timeZone: 'UTC' },
  async () => {
    const firestore = getFirestore();
    const db = getDatabase();
    const snap = await firestore
      .collection('queues')
      .where('schedule.enabled', '==', true)
      .get();
    const now = Date.now();
    for (const doc of snap.docs) {
      try {
        const data = doc.data();
        const metaRef = db.ref(`queues/${doc.id}/meta`);
        const meta = (await metaRef.once('value')).val();
        const plan = planScheduleChange(
          {
            schedule: data.schedule,
            lastDesired: data.scheduleLastDesired,
            status: meta?.status ?? data.status,
            currentOpensAt: meta?.opensAt ?? null,
          },
          now,
        );
        if (!plan) continue;
        if (plan.status) {
          await doc.ref.update({
            status: plan.status,
            statusMessage: FieldValue.delete(),
            resumeAt: FieldValue.delete(),
            scheduleLastDesired: plan.desired,
          });
        }
        if (meta) {
          const patch = { opensAt: plan.opensAt, updatedAt: now };
          if (plan.status) {
            patch.status = plan.status;
            patch.statusMessage = null;
            patch.resumeAt = null;
          }
          await metaRef.update(patch);
        }
      } catch (err) {
        logError('applyQueueSchedules failed', err, { queueId: doc.id });
      }
    }
  },
);

exports.onEntryJoined = onValueCreated(
  { ref: 'queues/{queueId}/entries/{entryId}', region: 'us-central1' },
  async (event) => {
    const entry = event.data.val();
    if (!entry || entry.status !== 'waiting') return null;
    const { queueId } = event.params;
    const db = getDatabase();
    const firestore = getFirestore();

    try {
      const [ownerSnap, opsSnap, nameSnap] = await Promise.all([
        db.ref(`owners/${queueId}/ownerUid`).once('value'),
        db.ref(`queues/${queueId}/operatorUids`).once('value'),
        db.ref(`queues/${queueId}/meta/name`).once('value'),
      ]);
      const ops = opsSnap.val() ?? {};
      const uids = recipientUids({
        ownerUid: ownerSnap.val(),
        operatorUids: Object.keys(ops).filter((k) => ops[k] === true),
      });

      const devices = [];
      for (const uid of uids) {
        const ownerDoc = await firestore.doc(`owners/${uid}`).get();
        if (!wantsNewEntryPush(ownerDoc.data())) continue;
        const snap = await firestore.collection(`owners/${uid}/devices`).get();
        snap.forEach((d) => devices.push({ ref: d.ref, ...d.data() }));
      }
      if (devices.length === 0) return null;

      const byLang = groupTokensByLang(devices);
      const refsByToken = new Map(devices.map((d) => [d.token, d.ref]));
      for (const [lang, tokens] of Object.entries(byLang)) {
        for (let i = 0; i < tokens.length; i += 500) {
          const chunk = tokens.slice(i, i + 500);
          const response = await getMessaging().sendEachForMulticast({
            tokens: chunk,
            ...buildNewEntryMessage({
              queueId,
              queueName: nameSnap.val(),
              entryName: entry.name,
              lang,
            }),
          });
          await Promise.all(
            response.responses.map((r, idx) =>
              !r.success && isStaleTokenError(r.error?.code)
                ? refsByToken.get(chunk[idx])?.delete()
                : null,
            ),
          );
        }
      }
    } catch (err) {
      logError('onEntryJoined failed', err, { queueId });
    }
    return null;
  },
);

exports.onQueueAdvanced = onValueWritten(
  { ref: 'queues/{queueId}/entries/{entryId}', region: 'us-central1' },
  async (event) => {
    const before = event.data.before.val();
    const after = event.data.after.val();
    if (!advancedFromWaiting(before, after)) return null;
    const { queueId } = event.params;
    const db = getDatabase();
    try {
      const snap = await db
        .ref(`queues/${queueId}/entries`)
        .orderByChild('status')
        .equalTo('waiting')
        .once('value');
      const next = pickNextWaiting(snap.val());
      if (!next || !next.fcmToken || next.nextNotifiedAt) return null;
      const nameSnap = await db.ref(`queues/${queueId}/meta/name`).once('value');
      await db
        .ref(`queues/${queueId}/entries/${next.id}/nextNotifiedAt`)
        .set(Date.now());
      await getMessaging().send(
        buildNextMessage({
          token: next.fcmToken,
          queueName: nameSnap.val(),
          queueId,
          lang: next.lang,
        }),
      );
    } catch (err) {
      logError('onQueueAdvanced failed', err, { queueId });
    }
    return null;
  },
);

async function loadAlertDevices(firestore, ownerUid) {
  const ownerDoc = await firestore.doc(`owners/${ownerUid}`).get();
  if (!wantsAlertPush(ownerDoc.data())) return [];
  const snap = await firestore.collection(`owners/${ownerUid}/devices`).get();
  return snap.docs.map((d) => ({ ref: d.ref, ...d.data() }));
}

async function sendQueueAlerts({ devices, queueId, queueName, fired }) {
  const byLang = groupTokensByLang(devices);
  const refsByToken = new Map(devices.map((d) => [d.token, d.ref]));
  for (const alert of fired) {
    for (const [lang, tokens] of Object.entries(byLang)) {
      for (let i = 0; i < tokens.length; i += 500) {
        const chunk = tokens.slice(i, i + 500);
        const response = await getMessaging().sendEachForMulticast({
          tokens: chunk,
          ...buildAlertPush({ queueId, queueName, rule: alert.rule, vars: alert, lang }),
        });
        await Promise.all(
          response.responses.map((r, idx) =>
            !r.success && isStaleTokenError(r.error?.code)
              ? refsByToken.get(chunk[idx])?.delete()
              : null,
          ),
        );
      }
    }
  }
}

async function evaluateOneQueueAlerts({ firestore, db, doc, now, dayStart }) {
  const data = doc.data();
  if (typeof data.ownerId !== 'string' || !data.ownerId) return;
  const [metaSnap, publicSnap] = await Promise.all([
    db.ref(`queues/${doc.id}/meta`).once('value'),
    db.ref(`queues/${doc.id}/public`).once('value'),
  ]);
  const meta = metaSnap.val();
  const status = meta?.status ?? data.status;
  if (status !== 'open') return;

  const devices = (await loadAlertDevices(firestore, data.ownerId)).filter(
    (d) => typeof d.token === 'string' && d.token.length > 0,
  );
  if (devices.length === 0) return;

  const waitingOrders = Object.values(publicSnap.val() ?? {})
    .filter((p) => p?.status === 'waiting')
    .map((p) => p.order);
  const history = firestore.collection(`queues/${doc.id}/history`);
  const [served, noShow] = await Promise.all(
    ['served', 'no_show'].map((result) =>
      history.where('result', '==', result).where('finishedAt', '>=', dayStart).count().get(),
    ),
  );

  const input = {
    now,
    status,
    waiting: waitingOrders.length,
    avgServiceMin: meta?.avgServiceMinAuto ?? meta?.avgServiceMin ?? null,
    noShowToday: noShow.data().count,
    servedToday: served.data().count,
    lastActivityAt: lastActivityOf({ updatedAt: meta?.updatedAt, waitingOrders }),
  };

  const fired = await firestore.runTransaction(async (tx) => {
    const fresh = (await tx.get(doc.ref)).data();
    const state = fresh?.alertState ?? {};
    const result = evaluateAlerts({ ...input, config: fresh?.alerts, state });
    if (result.length > 0) {
      tx.update(doc.ref, { alertState: stateAfter(state, result, now) });
    }
    return result;
  });
  if (fired.length === 0) return;

  await sendQueueAlerts({
    devices,
    queueId: doc.id,
    queueName: meta?.name ?? data.name,
    fired,
  });
}

exports.evaluateQueueAlerts = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'us-central1',
    timeZone: 'UTC',
    timeoutSeconds: 300,
  },
  async () => {
    const firestore = getFirestore();
    const db = getDatabase();
    const snap = await firestore.collection('queues').where('alerts.enabled', '==', true).get();
    const now = Date.now();
    const dayStart = Timestamp.fromMillis(startOfDaySaoPaulo(now));
    await mapLimit(snap.docs, ALERT_CONCURRENCY, async (doc) => {
      try {
        await evaluateOneQueueAlerts({ firestore, db, doc, now, dayStart });
      } catch (err) {
        logError('evaluateQueueAlerts failed', err, { queueId: doc.id });
      }
    });
  },
);
