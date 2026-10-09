const { onValueWritten } = require('firebase-functions/v2/database');
const { getDatabase } = require('firebase-admin/database');
const { getMessaging } = require('firebase-admin/messaging');
const { openedFromClosed, processQueueOpened } = require('../openwatch');
const { logError } = require('../log');

exports.onQueueOpened = onValueWritten(
  { ref: 'queues/{queueId}/meta/status', region: 'us-central1', retry: true },
  async (event) => {
    if (!openedFromClosed(event.data.before.val(), event.data.after.val())) return null;
    const { queueId } = event.params;
    const db = getDatabase();
    const watchersRef = db.ref(`queues/${queueId}/openWatchers`);
    const byCreatedAt = () => watchersRef.orderByChild('createdAt');
    try {
      await processQueueOpened({
        queueId,
        now: Date.now(),
        log: (message, err) => logError(message, err, { queueId }),
        deps: {
          fetchActive: async (limit, minCreatedAt) =>
            (await byCreatedAt().startAt(minCreatedAt).limitToFirst(limit).once('value')).val(),
          fetchExpired: async (limit, minCreatedAt) =>
            (await byCreatedAt().endAt(minCreatedAt - 1).limitToFirst(limit).once('value')).val(),
          update: (patch) => watchersRef.update(patch),
          queueName: async () =>
            (await db.ref(`queues/${queueId}/meta/name`).once('value')).val(),
          send: async (messages) => (await getMessaging().sendEach(messages)).responses,
        },
      });
    } catch (err) {
      logError('onQueueOpened failed', err, { queueId });
      throw err;
    }
    return null;
  },
);
