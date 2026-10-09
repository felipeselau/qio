const { Timestamp } = require('firebase-admin/firestore');

function toTimestamp(ms) {
  return typeof ms === 'number' && Number.isFinite(ms) ? Timestamp.fromMillis(ms) : null;
}

function historyFromLeftEntry(entry, nowMs, options = {}) {
  const source = entry ?? {};
  return {
    ticket: typeof source.ticket === 'number' ? source.ticket : 0,
    name: typeof source.name === 'string' ? source.name : '',
    phone: options.anonymizePhone === true ? null : typeof source.phone === 'string' ? source.phone : '',
    result: 'left',
    joinedAt: toTimestamp(source.joinedAt) ?? Timestamp.fromMillis(nowMs),
    calledAt: toTimestamp(source.calledAt),
    calledBy: null,
    operatorId: null,
    finishedAt: Timestamp.fromMillis(nowMs),
  };
}

module.exports = { historyFromLeftEntry };
