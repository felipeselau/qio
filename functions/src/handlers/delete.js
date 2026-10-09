const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const logger = require('firebase-functions/logger');
const {
  isSafeId,
  assertRecentLogin,
  deleteLogoFiles,
  deleteOwnedQueue,
  deleteAccountData,
} = require('../delete');
const { logError, logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { isEnforced } = require('../appcheck');

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
