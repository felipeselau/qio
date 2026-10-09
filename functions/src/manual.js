const { normalizeName, isValidPhone, pruneTimestamps, isRateLimited } = require('./join');
const { normalizeMaxWaiting } = require('./capacity');

const MANUAL_RATE_LIMIT = { max: 30, windowMs: 10 * 60 * 1000 };
const MAX_ACTIVE_ENTRIES = 1000;

function manualRateKey(uid) {
  return `manual-${uid}`;
}

function nextManualRateState(current, now, options = MANUAL_RATE_LIMIT) {
  const recent = pruneTimestamps(current, now, options.windowMs);
  if (isRateLimited(recent, now, options)) return { limited: true, timestamps: recent };
  return { limited: false, timestamps: [...recent, now] };
}

function isActiveCeilingReached(maxWaiting, activeCount, ceiling = MAX_ACTIVE_ENTRIES) {
  if (normalizeMaxWaiting(maxWaiting) !== 0) return false;
  return activeCount >= ceiling;
}

function isValidQueueId(value) {
  return (
    typeof value === 'string' &&
    value.length > 0 &&
    value.length <= 64 &&
    !value.includes('/') &&
    !/[.#$\[\]]/.test(value)
  );
}

function parseManualInput(data) {
  const input = data ?? {};
  const queueId = typeof input.queueId === 'string' ? input.queueId.trim() : '';
  if (!isValidQueueId(queueId)) return { error: 'invalid-queue' };
  const name = normalizeName(input.name);
  if (!name) return { error: 'invalid-name' };
  const rawPhone = input.phone === undefined || input.phone === null ? '' : input.phone;
  if (typeof rawPhone !== 'string' || !isValidPhone(rawPhone.trim())) {
    return { error: 'invalid-phone' };
  }
  return {
    queueId,
    name,
    phone: rawPhone.trim(),
    slotId: typeof input.slotId === 'string' ? input.slotId : undefined,
  };
}

function isQueueStaff(uid, ownerUid, operatorUids) {
  if (typeof uid !== 'string' || !uid) return false;
  if (ownerUid === uid) return true;
  return operatorUids?.[uid] === true;
}

function buildManualEntry({ ticket, name, phone, now, slotFields }) {
  return {
    ticket,
    name,
    phone,
    manual: true,
    status: 'waiting',
    joinedAt: now,
    ...(slotFields ?? {}),
  };
}

module.exports = {
  MANUAL_RATE_LIMIT,
  MAX_ACTIVE_ENTRIES,
  manualRateKey,
  nextManualRateState,
  isActiveCeilingReached,
  parseManualInput,
  isQueueStaff,
  buildManualEntry,
};
