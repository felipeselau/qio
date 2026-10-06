const MAX_ALLOWED_WAITING = 1000;

function normalizeMaxWaiting(value) {
  if (typeof value !== 'number' || !Number.isInteger(value)) return 0;
  if (value < 0) return 0;
  return Math.min(value, MAX_ALLOWED_WAITING);
}

function isQueueFull(maxWaiting, waitingCount) {
  const limit = normalizeMaxWaiting(maxWaiting);
  if (limit === 0) return false;
  return waitingCount >= limit;
}

module.exports = { MAX_ALLOWED_WAITING, normalizeMaxWaiting, isQueueFull };
