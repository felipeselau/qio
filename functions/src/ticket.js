function orderOf(entry) {
  if (typeof entry?.order === 'number') return entry.order;
  if (typeof entry?.joinedAt === 'number') return entry.joinedAt;
  return 0;
}

function publicTicketFor(entry) {
  const pub = { ticket: entry.ticket, status: entry.status, order: orderOf(entry) };
  if (typeof entry.slotId === 'string' && entry.slotId) pub.slotId = entry.slotId;
  return pub;
}

function shouldRenotify(before, after) {
  if (!after || after.status !== 'called') return false;
  if (!before || before.status !== 'called') return true;
  return (after.recalledAt ?? 0) !== (before.recalledAt ?? 0);
}

module.exports = { orderOf, publicTicketFor, shouldRenotify };
