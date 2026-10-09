const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore, FieldPath, Timestamp } = require('firebase-admin/firestore');
const { assertRecentLogin } = require('../delete');
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
} = require('../dsr');
const { logError, logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { isEnforced } = require('../appcheck');

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
