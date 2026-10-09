const { onValueWritten, onValueCreated } = require('firebase-functions/v2/database');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp, getApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore, FieldValue, FieldPath, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const {
  rateLimitFromEnv,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
} = require('./src/join');
const { historyFromLeftEntry } = require('./src/history');
const { isQueueFull } = require('./src/capacity');
const {
  normalizeMode,
  parseSlots,
  slotStartMs,
  isSlotBookable,
  countSlotEntries,
  slotsFromDoc,
  isSlotFull,
} = require('./src/slots');
const { shouldRenotify } =require('./src/ticket');
const { applyEntryChange, reconcileWaitingCounts } = require('./src/waiting');
const { planScheduleChange } = require('./src/schedule');
const { purgeAllRetention } = require('./src/retention');
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
const {
  parseManualInput,
  isQueueStaff,
  buildManualEntry,
  manualRateKey,
  nextManualRateState,
  isActiveCeilingReached,
} = require('./src/manual');
const logger = require('firebase-functions/logger');
const { logError, logAppCheck } = require('./src/log');
const { guarded } = require('./src/guard');
const { isEnforced } = require('./src/appcheck');
const {
  isSafeId,
  assertRecentLogin,
  deleteLogoFiles,
  deleteOwnedQueue,
  deleteAccountData,
} = require('./src/delete');
const {
  DSR_RATE_LIMIT,
  normalizePhone,
  normalizeMode: normalizeDsrMode,
  dsrRateKey,
  nextDsrRateState,
  chunk: dsrChunk,
  ANONYMOUS_NAME,
  findCustomerData,
  exportCustomerData,
  eraseCustomerData,
} = require('./src/dsr');
const {
  parseSlug,
  SLUG_RATE_USER,
  SLUG_RATE_IP,
  nextSlugRate,
  hashIp,
  isReleasedSlug,
} = require('./src/slug');

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

async function resolveSlot({ entriesRef, slots, slotId, now }) {
  if (typeof slotId !== 'string' || !slotId) {
    throw new HttpsError('invalid-argument', 'Escolha um horário.', {
      reason: 'slot-required',
    });
  }
  const slot = slots.find((s) => s.id === slotId);
  if (!slot) {
    throw new HttpsError('invalid-argument', 'Horário inválido.', {
      reason: 'slot-invalid',
    });
  }
  const slotStart = slotStartMs(now, slot.start);
  if (!isSlotBookable(now, slotStart)) {
    throw new HttpsError('failed-precondition', 'Horário já passou.', {
      reason: 'slot-passed',
    });
  }
  const snap = await entriesRef.orderByChild('slotId').equalTo(slotId).once('value');
  if (isSlotFull(slot.capacity, countSlotEntries(snap.val(), slotId))) {
    throw new HttpsError('resource-exhausted', 'Horário lotado.', {
      reason: 'slot-full',
    });
  }
  return { slotId, slotStart, order: slotStart };
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
    if (metaSnap.child('deleting').val() === true) {
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

    let mode = normalizeMode(metaSnap.child('mode').val());
    let rawSlots = metaSnap.child('slots').val();
    if (!metaSnap.child('mode').exists()) {
      const queueDoc = await getFirestore().doc(`queues/${queueId}`).get();
      if (queueDoc.exists && normalizeMode(queueDoc.get('mode')) === 'schedule') {
        mode = 'schedule';
        rawSlots = slotsFromDoc(queueDoc.get('slots'));
      }
    }
    let slotFields = null;
    if (mode === 'schedule') {
      slotFields = await resolveSlot({
        entriesRef,
        slots: parseSlots(rawSlots),
        slotId: data.slotId,
        now: Date.now(),
      });
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
      ...(slotFields ?? {}),
    });

    return { entryId: newRef.key, ticket, existing: false };
  }),
);

exports.addManualEntry = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: false,
  },
  guarded('addManualEntry', async (request) => {
    logAppCheck('addManualEntry', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para adicionar pessoas.');
    }

    const parsed = parseManualInput(request.data);
    if (parsed.error === 'invalid-queue') {
      throw new HttpsError('invalid-argument', 'Fila inválida.');
    }
    if (parsed.error === 'invalid-name') {
      throw new HttpsError('invalid-argument', 'Informe um nome com até 60 caracteres.');
    }
    if (parsed.error === 'invalid-phone') {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use o formato (00) 00000-0000.',
      );
    }
    const { queueId, name, phone, slotId } = parsed;

    const db = getDatabase();
    const [ownerSnap, opsSnap] = await Promise.all([
      db.ref(`owners/${queueId}/ownerUid`).once('value'),
      db.ref(`queues/${queueId}/operatorUids`).once('value'),
    ]);
    if (!isQueueStaff(uid, ownerSnap.val(), opsSnap.val())) {
      throw new HttpsError('permission-denied', 'Sem permissão para esta fila.');
    }

    const metaSnap = await db.ref(`queues/${queueId}/meta`).once('value');
    if (!metaSnap.exists()) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    if (metaSnap.child('status').val() !== 'open') {
      throw new HttpsError('failed-precondition', 'Fila fechada ou pausada.');
    }

    const entriesRef = db.ref(`queues/${queueId}/entries`);

    if (phone) {
      const samePhone = findActive(
        await entriesRef.orderByChild('phone').equalTo(phone).once('value'),
      );
      if (samePhone.length > 0) {
        throw new HttpsError('already-exists', 'Este telefone já está na fila.');
      }
    }

    let mode = normalizeMode(metaSnap.child('mode').val());
    let rawSlots = metaSnap.child('slots').val();
    if (!metaSnap.child('mode').exists()) {
      const queueDoc = await getFirestore().doc(`queues/${queueId}`).get();
      if (queueDoc.exists && normalizeMode(queueDoc.get('mode')) === 'schedule') {
        mode = 'schedule';
        rawSlots = slotsFromDoc(queueDoc.get('slots'));
      }
    }
    let slotFields = null;
    if (mode === 'schedule') {
      slotFields = await resolveSlot({
        entriesRef,
        slots: parseSlots(rawSlots),
        slotId,
        now: Date.now(),
      });
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

    if (!maxWaiting) {
      const [waitingSnap, calledSnap] = await Promise.all([
        entriesRef.orderByChild('status').equalTo('waiting').once('value'),
        entriesRef.orderByChild('status').equalTo('called').once('value'),
      ]);
      if (
        isActiveCeilingReached(
          maxWaiting,
          waitingSnap.numChildren() + calledSnap.numChildren(),
        )
      ) {
        throw new HttpsError('resource-exhausted', 'Fila lotada no momento.', {
          reason: 'queue-full',
        });
      }
    }

    const rateNow = Date.now();
    let limited = false;
    await db.ref(`rateLimits/${queueId}/${manualRateKey(uid)}`).transaction((current) => {
      const state = nextManualRateState(current, rateNow);
      limited = state.limited;
      return state.timestamps;
    });
    if (limited) {
      throw new HttpsError(
        'resource-exhausted',
        'Muitas adições. Aguarde alguns minutos.',
        { reason: 'rate-limited' },
      );
    }

    const ticketResult = await db
      .ref(`tickets/${queueId}`)
      .transaction((current) => (current ?? 0) + 1);
    const ticket = ticketResult.snapshot.val();

    const newRef = entriesRef.push();
    await newRef.set(
      buildManualEntry({ ticket, name, phone, now: Date.now(), slotFields }),
    );

    return { entryId: newRef.key, ticket };
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

function logDelete(event, ctx) {
  logger.info(event, { event, ...ctx });
}

const DEFAULT_STORAGE_BUCKET = 'qio-app.firebasestorage.app';

function logoBucket() {
  const name =
    process.env.STORAGE_BUCKET ||
    getApp().options.storageBucket ||
    DEFAULT_STORAGE_BUCKET;
  const bucket = getStorage().bucket(name);
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) return bucket;
  return {
    exists: async () => [true],
    deleteFiles: (opts) => bucket.deleteFiles(opts),
  };
}

function isNotFound(err) {
  return err?.code === 404 || err?.code === 5 || err?.code === 'auth/user-not-found';
}

function deleteDeps() {
  const firestore = getFirestore();
  const db = getDatabase();
  return {
    getQueue: async (queueId) => {
      const snap = await firestore.doc(`queues/${queueId}`).get();
      return snap.exists ? snap.data() : null;
    },
    markDeleting: async (queueId) => {
      await firestore.doc(`queues/${queueId}`).set(
        { deleting: true, status: 'closed' },
        { merge: true },
      );
      const metaSnap = await db.ref(`queues/${queueId}/meta`).get();
      if (metaSnap.exists()) {
        await db.ref(`queues/${queueId}/meta`).update({ status: 'closed', deleting: true });
      }
    },
    removeRtdb: (path) => db.ref(path).remove(),
    deleteSubcollections: async (queueId) => {
      const collections = await firestore.doc(`queues/${queueId}`).listCollections();
      for (const col of collections) {
        await firestore.recursiveDelete(col);
      }
    },
    listInvites: async (queueId) => {
      const snap = await firestore
        .collection('operatorInvites')
        .where('queueId', '==', queueId)
        .get();
      return snap.docs.map((d) => ({
        code: d.id,
        queueId: d.get('queueId'),
        ownerId: d.get('ownerId'),
      }));
    },
    listSlugs: async (queueId) => {
      const snap = await firestore
        .collection('queueSlugs')
        .where('queueId', '==', queueId)
        .get();
      return snap.docs.map((d) => ({
        slug: d.id,
        queueId: d.get('queueId'),
        ownerId: d.get('ownerId'),
        released: d.get('released') === true,
      }));
    },
    releaseSlug: (slug) =>
      firestore
        .doc(`queueSlugs/${slug}`)
        .update({ released: true, releasedAt: FieldValue.serverTimestamp() }),
    deleteInvite: (code) => firestore.doc(`operatorInvites/${code}`).delete(),
    deleteLogos: async (queueId) => {
      await deleteLogoFiles(logoBucket(), queueId, (event, ctx) =>
        logError(event, new Error('storage bucket not found'), ctx),
      );
    },
    deleteQueueDoc: (queueId) => firestore.recursiveDelete(firestore.doc(`queues/${queueId}`)),
    listOwnedQueueIds: async (uid) => {
      const snap = await firestore.collection('queues').where('ownerId', '==', uid).get();
      return snap.docs.map((d) => d.id);
    },
    listOperatorLinks: async (uid) => {
      const links = [];
      for (const kind of ['operators', 'operatorRequests']) {
        const snap = await firestore.collectionGroup(kind).where('uid', '==', uid).get();
        for (const doc of snap.docs) {
          const queueId = doc.ref.parent.parent?.id;
          if (queueId) links.push({ kind, queueId, path: doc.ref.path });
        }
      }
      return links;
    },
    removeOperatorLink: async (link, uid) => {
      await firestore.doc(link.path).delete();
      await db.ref(`queues/${link.queueId}/operatorUids/${uid}`).remove();
    },
    deleteOwnerData: async (uid) => {
      await firestore.recursiveDelete(firestore.doc(`owners/${uid}`));
      await db.ref(`rateLimits/_dsr/${uid}`).remove();
    },
    deleteAuthUser: async (uid) => {
      try {
        await getAuth().deleteUser(uid);
      } catch (err) {
        if (!isNotFound(err)) throw err;
      }
    },
  };
}

async function slugRateLimit(path, options, now) {
  let limited = false;
  await getDatabase()
    .ref(path)
    .transaction((current) => {
      const state = nextSlugRate(current, now, options);
      limited = state.limited;
      return state.timestamps;
    });
  return limited;
}

exports.resolveSlug = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: isEnforced('resolveSlug'),
  },
  guarded('resolveSlug', async (request) => {
    logAppCheck('resolveSlug', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para abrir o link.');
    }
    const slug = parseSlug(request.data?.slug);
    if (!slug) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    const now = Date.now();
    const ipHash = hashIp(request.rawRequest?.ip);
    const limited =
      (await slugRateLimit(`rateLimits/slug/${uid}`, SLUG_RATE_USER, now)) ||
      (ipHash !== null && (await slugRateLimit(`rateLimits/slugIp/${ipHash}`, SLUG_RATE_IP, now)));
    if (limited) {
      throw new HttpsError('resource-exhausted', 'Muitas tentativas. Aguarde um instante.');
    }
    const snap = await getFirestore().doc(`queueSlugs/${slug}`).get();
    const queueId = snap.exists && !isReleasedSlug(snap.data()) ? snap.get('queueId') : null;
    if (!isSafeId(queueId)) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    return { queueId };
  }),
);

exports.deleteQueue = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    timeoutSeconds: 540,
    memory: '512MiB',
    enforceAppCheck: isEnforced('deleteQueue'),
  },
  guarded('deleteQueue', async (request) => {
    logAppCheck('deleteQueue', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para excluir a fila.');
    }
    const queueId = request.data?.queueId;
    if (!isSafeId(queueId)) {
      throw new HttpsError('invalid-argument', 'Fila inválida.');
    }
    const result = await deleteOwnedQueue(queueId, uid, deleteDeps(), logDelete);
    if (result.forbidden) {
      throw new HttpsError('permission-denied', 'Só o dono pode excluir a fila.');
    }
    return { ok: true, alreadyGone: result.alreadyGone };
  }),
);

exports.deleteAccount = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    timeoutSeconds: 540,
    memory: '512MiB',
    enforceAppCheck: isEnforced('deleteAccount'),
  },
  guarded('deleteAccount', async (request) => {
    logAppCheck('deleteAccount', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para excluir a conta.');
    }
    assertRecentLogin(
      request.auth?.token?.auth_time,
      Math.floor(Date.now() / 1000),
      300,
      (message, details) => new HttpsError('failed-precondition', message, details),
    );
    const result = await deleteAccountData(uid, deleteDeps(), logDelete);
    if (!result.complete) {
      throw new HttpsError('aborted', 'Exclusão parcial. Tente novamente.', {
        reason: 'partial',
        failures: result.failures,
      });
    }
    return { ok: true, queuesDeleted: result.queuesDeleted };
  }),
);

function dsrDeps() {
  const firestore = getFirestore();
  const db = getDatabase();
  const queueRef = (queueId) => firestore.doc(`queues/${queueId}`);
  const batched = async (queueId, ids, collectionName, apply) => {
    for (const part of dsrChunk(ids)) {
      const batch = firestore.batch();
      for (const id of part) {
        apply(batch, queueRef(queueId).collection(collectionName).doc(id));
      }
      await batch.commit();
    }
  };
  return {
    listOwnedQueues: async (uid) => {
      const snap = await firestore.collection('queues').where('ownerId', '==', uid).get();
      return snap.docs
        .filter((d) => d.get('deleting') !== true)
        .map((d) => ({ id: d.id, name: d.get('name') }));
    },
    pageHistory: async (queueId, forms, afterId, limit) => {
      let query = queueRef(queueId)
        .collection('history')
        .where('phone', 'in', forms)
        .orderBy(FieldPath.documentId())
        .limit(limit);
      if (afterId) query = query.startAfter(afterId);
      const snap = await query.get();
      return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
    },
    getFeedback: async (queueId, ids) => {
      if (ids.length === 0) return [];
      const refs = ids.map((id) => queueRef(queueId).collection('feedback').doc(id));
      const snaps = await firestore.getAll(...refs);
      return snaps.filter((d) => d.exists).map((d) => ({ id: d.id, data: d.data() }));
    },
    findEntries: async (queueId, forms) => {
      const found = new Map();
      for (const form of forms) {
        const snap = await db
          .ref(`queues/${queueId}/entries`)
          .orderByChild('phone')
          .equalTo(form)
          .once('value');
        snap.forEach((child) => {
          found.set(child.key, { id: child.key, data: child.val() });
        });
      }
      return [...found.values()];
    },
    deleteHistory: (queueId, ids) =>
      batched(queueId, ids, 'history', (batch, ref) => batch.delete(ref)),
    anonymizeHistory: (queueId, ids) =>
      batched(queueId, ids, 'history', (batch, ref) =>
        batch.update(ref, { name: ANONYMOUS_NAME, phone: null }),
      ),
    deleteFeedback: (queueId, ids) =>
      batched(queueId, ids, 'feedback', (batch, ref) => batch.delete(ref)),
    clearFeedbackComments: (queueId, ids) =>
      batched(queueId, ids, 'feedback', (batch, ref) => batch.update(ref, { comment: '' })),
    removeEntries: async (queueId, ids) => {
      const updates = {};
      for (const id of ids) {
        updates[`entries/${id}`] = null;
        updates[`public/${id}`] = null;
      }
      await db.ref(`queues/${queueId}`).update(updates);
    },
    writeLog: async (uid, doc) => {
      await firestore
        .collection(`owners/${uid}/dataRequests`)
        .add({ ...doc, createdAt: Timestamp.fromMillis(doc.createdAt) });
    },
  };
}

function dsrCallable(name, run) {
  return onCall(
    {
      region: 'us-central1',
      invoker: 'public',
      timeoutSeconds: 300,
      memory: '512MiB',
      enforceAppCheck: isEnforced(name),
    },
    guarded(name, async (request) => {
      logAppCheck(name, request);
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError('unauthenticated', 'Faça login para continuar.');
      }
      const digits = normalizePhone(request.data?.phone);
      if (!digits) {
        throw new HttpsError('invalid-argument', 'Telefone inválido.');
      }
      const extra = run.validate ? run.validate(request.data) : {};
      assertRecentLogin(
        request.auth?.token?.auth_time,
        Math.floor(Date.now() / 1000),
        300,
        (message, details) => new HttpsError('failed-precondition', message, details),
      );
      const now = Date.now();
      let limited = false;
      await getDatabase()
        .ref(`rateLimits/_dsr/${dsrRateKey(uid)}`)
        .transaction((current) => {
          const state = nextDsrRateState(current, now, DSR_RATE_LIMIT);
          limited = state.limited;
          return state.timestamps;
        });
      if (limited) {
        throw new HttpsError(
          'resource-exhausted',
          'Muitas consultas. Aguarde antes de tentar de novo.',
          { reason: 'rate-limited' },
        );
      }
      return run.exec(
        {
          uid,
          digits,
          now,
          pepper: process.env.DSR_HASH_PEPPER ?? '',
          onError: (err, ctx) => logError(`${name} failed`, err, ctx),
          ...extra,
        },
        dsrDeps(),
      );
    }),
  );
}

exports.findCustomerData = dsrCallable('findCustomerData', {
  exec: findCustomerData,
});

exports.exportCustomerData = dsrCallable('exportCustomerData', {
  exec: exportCustomerData,
});

exports.eraseCustomerData = dsrCallable('eraseCustomerData', {
  validate: (data) => {
    const mode = normalizeDsrMode(data?.mode);
    if (!mode) throw new HttpsError('invalid-argument', 'Modo inválido.');
    return { mode };
  },
  exec: eraseCustomerData,
});

exports.syncPublicTicket = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    await applyEntryChange(
      getDatabase(),
      {
        queueId: event.params.queueId,
        entryId: event.params.entryId,
        before: event.data.before.val(),
        after: event.data.after.val(),
      },
      { archiveLeftEntry, logError },
    );
    return null;
  },
);

exports.reconcileWaitingCounts = onSchedule(
  { schedule: 'every 15 minutes', region: 'us-central1', timeZone: 'UTC' },
  async () => {
    const snap = await getFirestore().collection('queues').select().get();
    const results = await reconcileWaitingCounts(
      getDatabase(),
      snap.docs.map((d) => d.id),
      {
        concurrency: 5,
        onError: (err, queueId) => logError('reconcileWaitingCounts failed', err, { queueId }),
      },
    );
    console.log(`reconcileWaitingCounts: ${results.length} filas`);
  },
);

async function archiveLeftEntry(queueId, entryId, entry) {
  const firestore = getFirestore();
  const queueDoc = await firestore.doc(`queues/${queueId}`).get();
  if (!queueDoc.exists) return;
  try {
    await firestore
      .doc(`queues/${queueId}/history/${entryId}`)
      .create(
        historyFromLeftEntry(entry, Date.now(), {
          anonymizePhone: queueDoc.data()?.anonymizePhone === true,
        }),
      );
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
        if (data.deleting) continue;
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

exports.purgeOldHistory = onSchedule(
  {
    schedule: 'every day 03:30',
    region: 'us-central1',
    timeZone: 'America/Sao_Paulo',
    timeoutSeconds: 540,
  },
  async () => {
    const firestore = getFirestore();
    const snap = await firestore
      .collection('queues')
      .select('retentionDays', 'deleting')
      .get();
    const totals = await purgeAllRetention(
      firestore,
      snap.docs,
      Date.now(),
      (ms) => Timestamp.fromMillis(ms),
      { onError: (err, ctx) => logError('purgeOldHistory failed', err, ctx) },
    );
    logger.info('purgeOldHistory', { event: 'purgeOldHistory', ...totals });
  },
);

exports.onEntryJoined = onValueCreated(
  { ref: 'queues/{queueId}/entries/{entryId}', region: 'us-central1' },
  async (event) => {
    const entry = event.data.val();
    if (!entry || entry.status !== 'waiting' || entry.manual === true) return null;
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
