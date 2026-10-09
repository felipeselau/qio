const { mapLimit } = require('./waiting');

const DEFAULT_HOURS = 12;
const MIN_HOURS = 1;
const MAX_HOURS = 48;
const HOUR_MS = 60 * 60 * 1000;
const BATCH_SIZE = 25;
const RESET_TIMEZONE = 'America/Sao_Paulo';

const dayFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: RESET_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

function normalizeExpiry(raw) {
  if (!raw || typeof raw !== 'object' || raw.enabled !== true) return null;
  const hours =
    Number.isInteger(raw.hours) && raw.hours >= MIN_HOURS && raw.hours <= MAX_HOURS
      ? raw.hours
      : DEFAULT_HOURS;
  return {
    hours,
    clearOnClose: raw.clearOnClose === true,
    resetTicketDaily: raw.resetTicketDaily === true,
  };
}

function lastActivity(entry) {
  let latest = 0;
  for (const key of ['joinedAt', 'order', 'recalledAt']) {
    const v = entry?.[key];
    if (typeof v === 'number' && Number.isFinite(v) && v > latest) latest = v;
  }
  return latest;
}

function isStale(entry, now, hours) {
  if (!entry || entry.status !== 'waiting') return false;
  const last = lastActivity(entry);
  if (last <= 0) return false;
  return now - last >= hours * HOUR_MS;
}

function isActive(entry) {
  return entry?.status === 'waiting' || entry?.status === 'called';
}

function dayKey(ms) {
  return dayFormatter.format(new Date(ms));
}

function planTicketReset({ lastDay, now, activeCount }) {
  const today = dayKey(now);
  if (lastDay === today) return { action: 'none', day: today };
  if (typeof lastDay !== 'string' || lastDay === '') return { action: 'mark', day: today };
  if (activeCount > 0) return { action: 'none', day: today };
  return { action: 'reset', day: today };
}

function entriesOf(map) {
  if (!map || typeof map !== 'object') return [];
  return Object.entries(map).filter(([, v]) => v && typeof v === 'object');
}

async function archiveEntries({ queueId, candidates, reason, removeEntry, deps, batchSize = BATCH_SIZE }) {
  let archived = 0;
  for (let i = 0; i < candidates.length; i += batchSize) {
    const batch = candidates.slice(i, i + batchSize);
    const results = await mapLimit(batch, batchSize, async ([entryId, entry]) => {
      try {
        await deps.archive(queueId, entryId, entry, reason);
        const removed = await removeEntry(queueId, entryId);
        if (!removed) {
          if (deps.undoArchive) await deps.undoArchive(queueId, entryId, reason);
          return false;
        }
        await deps.removePublic(queueId, entryId);
        return true;
      } catch (err) {
        deps.onError?.(err, { queueId, entryId });
        return false;
      }
    });
    archived += results.filter(Boolean).length;
  }
  return archived;
}

async function expireQueue({ queueId, config, now, deps, batchSize }) {
  const entries = entriesOf(await deps.readEntries(queueId));
  const stale = entries.filter(([, e]) => isStale(e, now, config.hours));
  const expired = await archiveEntries({
    queueId,
    candidates: stale,
    reason: 'expired',
    removeEntry: (q, id) => deps.removeIfStale(q, id, now, config.hours),
    deps,
    batchSize,
  });
  const active = entries.filter(([, e]) => isActive(e)).length;
  return { expired, remaining: active - expired };
}

async function clearWaitingOnClose({ queueId, deps, batchSize }) {
  const entries = entriesOf(await deps.readEntries(queueId));
  const waiting = entries.filter(([, e]) => e.status === 'waiting');
  return archiveEntries({
    queueId,
    candidates: waiting,
    reason: 'closed',
    removeEntry: (q, id) => deps.removeIfWaiting(q, id),
    deps,
    batchSize,
  });
}

async function maintainQueue({ queueId, config, now, deps, batchSize }) {
  const result = await expireQueue({ queueId, config, now, deps, batchSize });
  let { remaining } = result;
  let cleared = 0;
  if (config.clearOnClose && (await deps.readStatus(queueId)) === 'closed') {
    cleared = await clearWaitingOnClose({ queueId, deps, batchSize });
    remaining -= cleared;
  }
  return { expired: result.expired, cleared, remaining };
}

async function runTicketReset({ queueId, lastDay, now, activeCount, deps }) {
  const plan = planTicketReset({ lastDay, now, activeCount });
  if (plan.action === 'none') return plan;
  if (plan.action === 'reset') {
    const status = await deps.readStatus(queueId);
    if (status === null || status === undefined) return { action: 'none', day: plan.day };
    const fresh = entriesOf(await deps.readEntries(queueId));
    if (fresh.some(([, e]) => isActive(e))) return { action: 'none', day: plan.day };
    await deps.resetTicket(queueId);
  }
  await deps.markResetDay(queueId, plan.day);
  return plan;
}

module.exports = {
  DEFAULT_HOURS,
  MIN_HOURS,
  MAX_HOURS,
  BATCH_SIZE,
  normalizeExpiry,
  lastActivity,
  isStale,
  dayKey,
  planTicketReset,
  archiveEntries,
  expireQueue,
  maintainQueue,
  clearWaitingOnClose,
  runTicketReset,
};
