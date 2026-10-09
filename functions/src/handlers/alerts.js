const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getDatabase } = require('firebase-admin/database');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { isStaleTokenError, groupTokensByLang } = require('../push');
const {
  evaluateAlerts,
  stateAfter,
  startOfDaySaoPaulo,
  lastActivityOf,
  mapLimit,
  buildAlertPush,
  wantsAlertPush,
} = require('../alerts');
const { logError } = require('../log');

const ALERT_CONCURRENCY = 5;

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
