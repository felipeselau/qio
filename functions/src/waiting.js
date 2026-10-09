const { countWaiting, waitingChanged, publicTicketFor } = require('./ticket');

const ACTIVE_STATUSES = ['waiting', 'called'];

function planWaitingCount(meta, publicVal) {
  if (!meta || typeof meta.name === 'undefined' || meta.name === null) {
    return { action: 'missing', count: 0 };
  }
  if (meta.deleting === true) return { action: 'deleting', count: 0 };
  const count = countWaiting(publicVal);
  if (meta.waitingCount === count) return { action: 'same', count };
  return { action: 'write', count };
}

async function writeWaitingCount(db, queueId, count) {
  let state = 'missing';
  await db.ref(`queues/${queueId}/meta`).transaction((meta) => {
    if (meta === null || meta === undefined) {
      state = 'missing';
      return meta;
    }
    const plan = planWaitingCount(meta, null);
    if (plan.action === 'missing' || plan.action === 'deleting') {
      state = plan.action;
      return undefined;
    }
    if (meta.waitingCount === count) {
      state = 'same';
      return undefined;
    }
    state = 'written';
    return { ...meta, waitingCount: count };
  });
  return state;
}

async function refreshWaitingCount(db, queueId, maxWrites = 2) {
  let last = null;
  for (let i = 0; i < maxWrites; i += 1) {
    const snap = await db.ref(`queues/${queueId}/public`).once('value');
    const count = countWaiting(snap.val());
    if (last !== null && count === last) return 'stable';
    const state = await writeWaitingCount(db, queueId, count);
    if (state === 'missing' || state === 'deleting') return state;
    last = count;
  }
  return 'written';
}

async function mapLimit(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const index = next;
      next += 1;
      results[index] = await fn(items[index], index);
    }
  };
  const workers = [];
  for (let i = 0; i < Math.min(limit, items.length); i += 1) workers.push(worker());
  await Promise.all(workers);
  return results;
}

async function reconcileWaitingCounts(db, queueIds, { concurrency = 5, onError } = {}) {
  const results = await mapLimit(queueIds, concurrency, async (queueId) => {
    try {
      return await refreshWaitingCount(db, queueId);
    } catch (err) {
      if (onError) onError(err, queueId);
      return 'error';
    }
  });
  return results;
}

async function applyEntryChange(db, { queueId, entryId, before, after }, { archiveLeftEntry, logError }) {
  const publicRef = db.ref(`queues/${queueId}/public/${entryId}`);
  let failure = null;
  try {
    if (after && after.status === 'left') {
      try {
        await archiveLeftEntry(queueId, entryId, after);
        await db.ref(`queues/${queueId}/entries/${entryId}`).remove();
      } finally {
        await publicRef.remove();
      }
    } else if (after && ACTIVE_STATUSES.includes(after.status)) {
      await publicRef.set(publicTicketFor(after));
    } else {
      await publicRef.remove();
    }
  } catch (err) {
    failure = err;
  }
  if (waitingChanged(before, after)) {
    try {
      await refreshWaitingCount(db, queueId);
    } catch (err) {
      logError('refreshWaitingCount failed', err, { queueId, entryId });
      failure = failure ?? err;
    }
  }
  if (failure) {
    logError('syncPublicTicket failed', failure, { queueId, entryId });
    throw failure;
  }
}

module.exports = {
  planWaitingCount,
  writeWaitingCount,
  refreshWaitingCount,
  mapLimit,
  reconcileWaitingCounts,
  applyEntryChange,
};
