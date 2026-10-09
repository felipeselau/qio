function orderOf(entry) {
  if (typeof entry?.order === 'number') return entry.order;
  if (typeof entry?.joinedAt === 'number') return entry.joinedAt;
  return 0;
}

function publicTicketFor(entry) {
  const pub = { ticket: entry.ticket, status: entry.status, order: orderOf(entry) };
  if (typeof entry.slotId === 'string' && entry.slotId) {
    pub.slotId = entry.slotId;
    if (typeof entry.slotStart === 'number') pub.slotStart = entry.slotStart;
  }
  return pub;
}

function shouldRenotify(before, after) {
  if (!after || after.status !== 'called') return false;
  if (!before || before.status !== 'called') return true;
  return (after.recalledAt ?? 0) !== (before.recalledAt ?? 0);
}

function countWaiting(publicMap) {
  if (!publicMap || typeof publicMap !== 'object') return 0;
  let n = 0;
  for (const v of Object.values(publicMap)) {
    if (v && v.status === 'waiting') n += 1;
  }
  return n;
}

function waitingChanged(before, after) {
  return (before?.status === 'waiting') !== (after?.status === 'waiting');
}

module.exports = { orderOf, publicTicketFor, shouldRenotify, countWaiting, waitingChanged };
