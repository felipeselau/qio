const { HttpsError } = require('firebase-functions/v2/https');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { historyFromLeftEntry } = require('../history');
const { slotStartMs, isSlotBookable, countSlotEntries, isSlotFull } = require('../slots');
const { isStale } = require('../expire');
const { logError } = require('../log');

const ACTIVE_STATUSES = ['waiting', 'called'];

function findActive(snap) {
  const found = [];
  snap.forEach((child) => {
    const val = child.val();
    if (val && ACTIVE_STATUSES.includes(val.status)) {
      found.push({ entryId: child.key, ...val });
    }
  });
  return found;
}

async function resolveSlot({ entriesRef, slots, slotId, now }) {
  if (typeof slotId !== 'string' || !slotId) {
    throw new HttpsError('invalid-argument', 'Escolha um horário.', {
      reason: 'slot-required',
    });
  }
  const slot = slots.find((s) => s.id === slotId);
  if (!slot) {
    throw new HttpsError('invalid-argument', 'Horário inválido.', {
      reason: 'slot-invalid',
    });
  }
  const slotStart = slotStartMs(now, slot.start);
  if (!isSlotBookable(now, slotStart)) {
    throw new HttpsError('failed-precondition', 'Horário já passou.', {
      reason: 'slot-passed',
    });
  }
  const snap = await entriesRef.orderByChild('slotId').equalTo(slotId).once('value');
  if (isSlotFull(slot.capacity, countSlotEntries(snap.val(), slotId))) {
    throw new HttpsError('resource-exhausted', 'Horário lotado.', {
      reason: 'slot-full',
    });
  }
  return { slotId, slotStart, order: slotStart };
}

async function archiveLeftEntry(queueId, entryId, entry, options = {}) {
  const firestore = getFirestore();
  let anonymizePhone = options.anonymizePhone;
  if (typeof anonymizePhone !== 'boolean') {
    const queueDoc = await firestore.doc(`queues/${queueId}`).get();
    if (!queueDoc.exists) return;
    anonymizePhone = queueDoc.data()?.anonymizePhone === true;
  }
  try {
    await firestore
      .doc(`queues/${queueId}/history/${entryId}`)
      .create(
        historyFromLeftEntry(entry, Date.now(), {
          anonymizePhone,
          reason: options.reason,
        }),
      );
  } catch (err) {
    if (err?.code !== 6) throw err;
  }
}

function expireDeps(queueId, anonymizePhone) {
  const db = getDatabase();
  const removeWhere = async (entryId, keep) => {
    let removed = false;
    await db.ref(`queues/${queueId}/entries/${entryId}`).transaction((current) => {
      removed = false;
      if (current === null || current === undefined) return current;
      if (!keep(current)) return undefined;
      removed = true;
      return null;
    });
    return removed;
  };
  return {
    readEntries: async (id) => (await db.ref(`queues/${id}/entries`).once('value')).val(),
    archive: (id, entryId, entry, reason) =>
      archiveLeftEntry(id, entryId, entry, { anonymizePhone, reason }),
    removeIfStale: (id, entryId, now, hours) =>
      removeWhere(entryId, (current) => isStale(current, now, hours)),
    removeIfWaiting: (id, entryId) =>
      removeWhere(entryId, (current) => current.status === 'waiting'),
    undoArchive: async (id, entryId, reason) => {
      const ref = getFirestore().doc(`queues/${id}/history/${entryId}`);
      const snap = await ref.get();
      if (snap.exists && snap.data()?.reason === reason) await ref.delete();
    },
    readStatus: async (id) =>
      (await db.ref(`queues/${id}/meta/status`).once('value')).val(),
    removePublic: (id, entryId) => db.ref(`queues/${id}/public/${entryId}`).remove(),
    resetTicket: (id) => db.ref(`tickets/${id}`).remove(),
    markResetDay: (id, day) =>
      getFirestore().doc(`queues/${id}`).update({ lastTicketResetDay: day }),
    onError: (err, ctx) => logError('expireStaleEntries entry failed', err, ctx),
  };
}

module.exports = { findActive, resolveSlot, archiveLeftEntry, expireDeps };
