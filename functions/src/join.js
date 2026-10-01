const MAX_NAME_LENGTH = 60;
const PHONE_PATTERN = /^\(\d{2}\) \d{4,5}-\d{4}$/;
const DEFAULT_RATE_LIMIT = { max: 3, windowMs: 10 * 60 * 1000 };

function normalizeName(name) {
  if (typeof name !== 'string') return null;
  const trimmed = name.trim();
  if (trimmed.length === 0 || trimmed.length > MAX_NAME_LENGTH) return null;
  return trimmed;
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

module.exports = {
  MAX_NAME_LENGTH,
  DEFAULT_RATE_LIMIT,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
};
