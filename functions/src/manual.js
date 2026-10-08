const { normalizeName, isValidPhone } = require('./join');

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

module.exports = { parseManualInput, isQueueStaff, buildManualEntry };
