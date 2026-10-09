const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const logger = require('firebase-functions/logger');
const { purgeAllRetention } = require('../retention');
const { logError } = require('../log');

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
