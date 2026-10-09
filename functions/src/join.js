const MAX_NAME_LENGTH = 60;
const PHONE_PATTERN = /^\(\d{2}\) \d{4,5}-\d{4}$/;
const DEFAULT_RATE_LIMIT = { max: 3, windowMs: 10 * 60 * 1000 };

function normalizeName(name) {
  if (typeof name !== 'string') return null;
  const trimmed = name.trim();
  if (trimmed.length === 0 || trimmed.length > MAX_NAME_LENGTH) return null;
  return trimmed;
}

const CLAIM_RATE_LIMIT = { max: 3, windowMs: 10 * 60 * 1000 };
const ACTIVE_STATUSES = ['waiting', 'called'];

function nameKey(name) {
  if (typeof name !== 'string') return '';
  return name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function namesMatch(a, b) {
  const ka = nameKey(a);
  return ka.length > 0 && ka === nameKey(b);
}

function pickClaimable(entries, name, uid) {
  if (!Array.isArray(entries)) return null;
  const matches = entries
    .filter(
      (e) =>
        e &&
        ACTIVE_STATUSES.includes(e.status) &&
        e.uid !== uid &&
        namesMatch(e.name, name),
    )
    .sort((a, b) => (a.joinedAt ?? 0) - (b.joinedAt ?? 0));
  return matches[0] ?? null;
}

function claimEntryUpdate(current, expectedUid, newUid) {
  if (current === null || typeof current !== 'object') return current;
  if (current.uid !== expectedUid || !ACTIVE_STATUSES.includes(current.status)) {
    return undefined;
  }
  const { fcmToken, ...rest } = current;
  return { ...rest, uid: newUid };
}

function isValidPhone(phone) {
  if (typeof phone !== 'string') return false;
  return phone === '' || PHONE_PATTERN.test(phone);
}

function pruneTimestamps(timestamps, now, windowMs = DEFAULT_RATE_LIMIT.windowMs) {
  if (!Array.isArray(timestamps)) return [];
  return timestamps.filter(
    (t) => typeof t === 'number' && t > now - windowMs && t <= now,
  );
}

function isRateLimited(timestamps, now, options = DEFAULT_RATE_LIMIT) {
  const { max, windowMs } = { ...DEFAULT_RATE_LIMIT, ...options };
  return pruneTimestamps(timestamps, now, windowMs).length >= max;
}

function positiveInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function rateLimitFromEnv(env = {}) {
  return {
    max: positiveInt(env.JOIN_RATE_LIMIT_MAX, DEFAULT_RATE_LIMIT.max),
    windowMs:
      positiveInt(env.JOIN_RATE_LIMIT_WINDOW_MIN, DEFAULT_RATE_LIMIT.windowMs / 60000) * 60000,
  };
}

module.exports = {
  MAX_NAME_LENGTH,
  DEFAULT_RATE_LIMIT,
  CLAIM_RATE_LIMIT,
  nameKey,
  namesMatch,
  pickClaimable,
  claimEntryUpdate,
  rateLimitFromEnv,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
};
