const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { MAX_SAMPLES, estimateServiceMin } = require('../estimate');
const { logError } = require('../log');

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
