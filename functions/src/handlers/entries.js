const { onValueWritten } = require('firebase-functions/v2/database');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { applyEntryChange, reconcileWaitingCounts } = require('../waiting');
const { routeEntryWrite } = require('../entryRouter');
const { logError } = require('../log');
const { archiveLeftEntry } = require('./_shared');
const { notifyEntryCalled, notifyEntryJoined, notifyQueueAdvanced } = require('./push');

const entryHandlers = {
  sync: ({ queueId, entryId, before, after }) =>
    applyEntryChange(
      getDatabase(),
      { queueId, entryId, before, after },
      { archiveLeftEntry, logError },
    ),
  joined: notifyEntryJoined,
  called: notifyEntryCalled,
  advanced: notifyQueueAdvanced,
};

exports.syncPublicTicket = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  (event) =>
    routeEntryWrite(
      {
        queueId: event.params.queueId,
        entryId: event.params.entryId,
        before: event.data.before.val(),
        after: event.data.after.val(),
      },
      entryHandlers,
    ),
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
