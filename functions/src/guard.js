const { HttpsError } = require('firebase-functions/v2/https');
const { logError } = require('./log');

const CLIENT_ERROR_CODES = new Set([
  'invalid-argument',
  'not-found',
  'already-exists',
  'failed-precondition',
  'resource-exhausted',
  'unauthenticated',
  'permission-denied',
  'out-of-range',
  'cancelled',
]);

const MAX_QUEUE_ID = 64;

function isClientError(err) {
  return err instanceof HttpsError && CLIENT_ERROR_CODES.has(err.code);
}

function safeQueueId(value) {
  return typeof value === 'string' ? value.slice(0, MAX_QUEUE_ID) : undefined;
}

function guarded(event, handler, log = logError) {
  return async (request) => {
    try {
      return await handler(request);
    } catch (err) {
      if (!isClientError(err)) {
        log(`${event} failed`, err, { queueId: safeQueueId(request?.data?.queueId) });
      }
      throw err;
    }
  };
}

module.exports = { guarded, isClientError, safeQueueId };
