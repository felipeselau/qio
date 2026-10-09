const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { logError } = require('../log');
const {
  createMirrorQueueHandler,
  createMirrorOperatorHandler,
} = require('../handlers/mirror');

const region = 'us-central1';

const queueDoc = async (queueId) => {
  const snap = await getFirestore().doc(`queues/${queueId}`).get();
  return snap.exists ? snap.data() : null;
};

const queueDeps = {
  readQueueDoc: queueDoc,
  readOwner: async (queueId) => (await getDatabase().ref(`owners/${queueId}`).once('value')).val(),
  setOwner: (queueId, patch) => getDatabase().ref(`owners/${queueId}`).set(patch),
  readMeta: async (queueId) =>
    (await getDatabase().ref(`queues/${queueId}/meta`).once('value')).val(),
  updateMeta: (queueId, patch) => getDatabase().ref(`queues/${queueId}/meta`).update(patch),
  createMeta: (queueId, meta) =>
    getDatabase()
      .ref(`queues/${queueId}/meta`)
      .transaction((current) => (current === null ? meta : undefined)),
  now: () => Date.now(),
  warn: (message, ctx) => logger.warn(message, ctx),
  onError: logError,
};

const operatorRef = (queueId, uid) => getDatabase().ref(`queues/${queueId}/operatorUids/${uid}`);

const operatorDeps = {
  readQueueDoc: queueDoc,
  operatorExists: async (queueId, uid) =>
    (await getFirestore().doc(`queues/${queueId}/operators/${uid}`).get()).exists,
  readOperator: async (queueId, uid) => (await operatorRef(queueId, uid).once('value')).val() === true,
  setOperator: (queueId, uid) => operatorRef(queueId, uid).set(true),
  removeOperator: (queueId, uid) => operatorRef(queueId, uid).remove(),
  onError: logError,
};

exports.mirrorQueueToRtdb = onDocumentWritten(
  { document: 'queues/{queueId}', region },
  createMirrorQueueHandler(queueDeps),
);

exports.mirrorOperatorToRtdb = onDocumentWritten(
  { document: 'queues/{queueId}/operators/{uid}', region },
  createMirrorOperatorHandler(operatorDeps),
);
