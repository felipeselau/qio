const defaultLogger = require('firebase-functions/logger');

const PII_KEYS = new Set([
  'name',
  'entryname',
  'phone',
  'token',
  'fcmtoken',
  'tokens',
  'comment',
  'email',
]);

function scrub(value, depth = 0) {
  if (value === null || typeof value !== 'object') return value;
  if (depth >= 4) return '[truncated]';
  if (Array.isArray(value)) return value.map((v) => scrub(v, depth + 1));
  const out = {};
  for (const [key, val] of Object.entries(value)) {
    if (PII_KEYS.has(key.toLowerCase())) continue;
    out[key] = scrub(val, depth + 1);
  }
  return out;
}

function describeError(err) {
  if (err instanceof Error) {
    return {
      name: err.name,
      message: err.message,
      code: err.code,
      stack: err.stack,
    };
  }
  return { message: String(err) };
}

function logError(event, err, ctx = {}, logger = defaultLogger) {
  logger.error(event, { event, error: describeError(err), ...scrub(ctx) });
}

module.exports = { logError, scrub };
