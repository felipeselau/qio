const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore } = require('firebase-admin/firestore');
const { normalizeExpiry, maintainQueue, runTicketReset } = require('../expire');
const { mapLimit } = require('../alerts');
const { logError } = require('../log');
const { expireDeps } = require('./_shared');

exports.expireStaleEntries = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeZone: 'UTC',
    timeoutSeconds: 540,
  },
  async () => {
    const snap = await getFirestore()
      .collection('queues')
      .where('expiry.enabled', '==', true)
      .get();
    const now = Date.now();
    let expired = 0;
    await mapLimit(snap.docs, 5, async (doc) => {
      try {
        const data = doc.data();
        const config = normalizeExpiry(data.expiry);
        if (!config || data.deleting) return;
        const deps = expireDeps(doc.id, data.anonymizePhone === true);
        const result = await maintainQueue({ queueId: doc.id, config, now, deps });
        expired += result.expired;
        if (config.resetTicketDaily) {
          await runTicketReset({
            queueId: doc.id,
            lastDay: data.lastTicketResetDay,
            now,
            activeCount: result.remaining,
            deps,
          });
        }
      } catch (err) {
        logError('expireStaleEntries failed', err, { queueId: doc.id });
      }
    });
    console.log(`expireStaleEntries: ${snap.size} filas, ${expired} expiradas`);
  },
);
