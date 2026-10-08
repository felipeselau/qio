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

const MAX_MESSAGE = 500;
const MAX_STACK = 2000;

function maskPii(text) {
  return text
    .replace(/\(\d{2}\) ?\d{4,5}-\d{4}/g, '[phone]')
    .replace(/[\w.+-]+@[\w-]+(\.[\w-]+)+/g, '[email]')
    .replace(/[A-Za-z0-9_:-]{40,}/g, '[token]');
}

function clean(value, max) {
  if (typeof value !== 'string') return value;
  return maskPii(value).slice(0, max);
}

function describeError(err) {
  if (err instanceof Error) {
    return {
      name: err.name,
      message: clean(err.message, MAX_MESSAGE),
      code: err.code,
      stack: clean(err.stack, MAX_STACK),
    };
  }
  return { message: clean(String(err), MAX_MESSAGE) };
}

function logError(event, err, ctx = {}, logger = defaultLogger) {
  logger.error(event, { ...scrub(ctx), event, error: describeError(err) });
}

function appCheckStatus(request) {
  return request && request.app ? 'present' : 'absent';
}

function logAppCheck(callable, request, logger = defaultLogger) {
  logger.info('appcheck', { event: 'appcheck', callable, appCheck: appCheckStatus(request) });
}

module.exports = { logError, scrub, appCheckStatus, logAppCheck };
