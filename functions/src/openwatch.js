const WATCHER_LIMIT = 500;
const WATCHER_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_TOKEN_LENGTH = 4096;
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

module.exports = {
  WATCHER_LIMIT,
  WATCHER_TTL_MS,
  openedFromClosed,
  activeWatchers,
};
