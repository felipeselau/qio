const { buildOpenMessage } = require('./webpush');
const { isStaleTokenError } = require('./push');

const WATCHER_LIMIT = 500;
const WATCHER_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_TOKEN_LENGTH = 4096;
const MAX_ROUNDS = 20;
const FROM_STATUSES = new Set(['closed', 'paused']);

function openedFromClosed(before, after) {
  return after === 'open' && FROM_STATUSES.has(before);
}

function activeWatchers(watchers, now, ttlMs = WATCHER_TTL_MS, limit = WATCHER_LIMIT) {
  const result = [];
  for (const [uid, w] of Object.entries(watchers ?? {})) {
    if (result.length >= limit) break;
    if (typeof w?.fcmToken !== 'string' || w.fcmToken.length === 0) continue;
    if (w.fcmToken.length > MAX_TOKEN_LENGTH) continue;
    if (typeof w.createdAt !== 'number' || now - w.createdAt > ttlMs) continue;
    result.push({ uid, token: w.fcmToken, lang: w.lang });
  }
  return result;
}

function nullPatch(keys) {
  return Object.fromEntries([...keys].map((k) => [k, null]));
}

async function processQueueOpened({ queueId, now, deps, log = () => {} }) {
  const minCreatedAt = now - WATCHER_TTL_MS;
  const first = await deps.fetchActive(WATCHER_LIMIT, minCreatedAt);
  const restore = {};
  let sent = 0;
  let batch = first;

  for (let round = 0; round < MAX_ROUNDS && batch && Object.keys(batch).length > 0; round++) {
    const keys = Object.keys(batch);
    await deps.update(nullPatch(keys));
    const watchers = activeWatchers(batch, now);
    if (watchers.length > 0) {
      const queueName = await deps.queueName();
      for (let i = 0; i < watchers.length; i += WATCHER_LIMIT) {
        const chunk = watchers.slice(i, i + WATCHER_LIMIT);
        let responses;
        try {
          responses = await deps.send(
            chunk.map((w) =>
              buildOpenMessage({ token: w.token, queueName, queueId, lang: w.lang }),
            ),
          );
        } catch (err) {
          log('onQueueOpened:send-failed', err);
          for (const w of chunk) restore[w.uid] = batch[w.uid];
          continue;
        }
        responses.forEach((r, idx) => {
          if (r.success) {
            sent += 1;
          } else if (!isStaleTokenError(r.error?.code)) {
            restore[chunk[idx].uid] = batch[chunk[idx].uid];
          }
        });
      }
    }
    if (keys.length < WATCHER_LIMIT) break;
    batch = await deps.fetchActive(WATCHER_LIMIT, minCreatedAt);
  }

  if (Object.keys(restore).length > 0) await deps.update(restore);

  for (let round = 0; round < MAX_ROUNDS; round++) {
    const expired = await deps.fetchExpired(WATCHER_LIMIT, minCreatedAt);
    const keys = Object.keys(expired ?? {});
    if (keys.length === 0) break;
    await deps.update(nullPatch(keys));
    if (keys.length < WATCHER_LIMIT) break;
  }

  return { sent, restored: Object.keys(restore).length };
}

module.exports = {
  WATCHER_LIMIT,
  WATCHER_TTL_MS,
  openedFromClosed,
  activeWatchers,
  processQueueOpened,
};
