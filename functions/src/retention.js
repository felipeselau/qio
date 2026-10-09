const DEFAULT_RETENTION_DAYS = 180;
const MIN_RETENTION_DAYS = 30;
const MAX_RETENTION_DAYS = 730;
const BATCH_SIZE = 450;
const MAX_BATCHES_PER_COLLECTION = 200;
const DAY_MS = 24 * 60 * 60 * 1000;

function retentionDaysFor(raw) {
  if (
    typeof raw !== 'number' ||
    !Number.isInteger(raw) ||
    raw < MIN_RETENTION_DAYS ||
    raw > MAX_RETENTION_DAYS
  ) {
    return DEFAULT_RETENTION_DAYS;
  }
  return raw;
}

function cutoffMs(now, days) {
  return now - retentionDaysFor(days) * DAY_MS;
}

function isOlderThan(valueMs, cutoff) {
  return typeof valueMs === 'number' && Number.isFinite(valueMs) && valueMs < cutoff;
}

async function purgeOlderThan(firestore, collectionRef, field, cutoffTs, options = {}) {
  const limit = options.limit ?? BATCH_SIZE;
  const maxBatches = options.maxBatches ?? MAX_BATCHES_PER_COLLECTION;
  let deleted = 0;
  for (let i = 0; i < maxBatches; i += 1) {
    const snap = await collectionRef
      .where(field, '<', cutoffTs)
      .orderBy(field)
      .limit(limit)
      .get();
    if (snap.empty) break;
    const batch = firestore.batch();
    for (const doc of snap.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snap.size;
    if (snap.size < limit) break;
  }
  return deleted;
}

async function purgeQueueRetention(firestore, queueDoc, now, toTimestamp, options = {}) {
  const data = queueDoc.data() ?? {};
  if (data.deleting) return { history: 0, feedback: 0, skipped: true };
  const cutoffTs = toTimestamp(cutoffMs(now, data.retentionDays));
  const history = await purgeOlderThan(
    firestore,
    queueDoc.ref.collection('history'),
    'finishedAt',
    cutoffTs,
    options,
  );
  const feedback = await purgeOlderThan(
    firestore,
    queueDoc.ref.collection('feedback'),
    'createdAt',
    cutoffTs,
    options,
  );
  return { history, feedback, skipped: false };
}

async function purgeAllRetention(firestore, queueDocs, now, toTimestamp, hooks = {}) {
  const onError = hooks.onError ?? (() => {});
  const totals = { queues: 0, history: 0, feedback: 0, failed: 0 };
  for (const queueDoc of queueDocs) {
    try {
      const res = await purgeQueueRetention(firestore, queueDoc, now, toTimestamp, hooks.options);
      if (res.skipped) continue;
      totals.queues += 1;
      totals.history += res.history;
      totals.feedback += res.feedback;
    } catch (err) {
      totals.failed += 1;
      onError(err, { queueId: queueDoc.id });
    }
  }
  return totals;
}

module.exports = {
  DEFAULT_RETENTION_DAYS,
  MIN_RETENTION_DAYS,
  MAX_RETENTION_DAYS,
  BATCH_SIZE,
  retentionDaysFor,
  cutoffMs,
  isOlderThan,
  purgeOlderThan,
  purgeQueueRetention,
  purgeAllRetention,
};
