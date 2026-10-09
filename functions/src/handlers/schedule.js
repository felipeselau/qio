const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { planScheduleChange } = require('../schedule');
const { normalizeExpiry, clearWaitingOnClose } = require('../expire');
const { logError } = require('../log');
const { expireDeps } = require('./_shared');

exports.applyQueueSchedules = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'us-central1',
    timeZone: 'UTC',
    timeoutSeconds: 300,
  },
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
        if (plan.status === 'closed') {
          const config = normalizeExpiry(data.expiry);
          if (config?.clearOnClose) {
            await clearWaitingOnClose({
              queueId: doc.id,
              deps: expireDeps(doc.id, data.anonymizePhone === true),
            });
          }
        }
      } catch (err) {
        logError('applyQueueSchedules failed', err, { queueId: doc.id });
      }
    }
  },
);
