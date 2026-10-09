const { getDatabase } = require('firebase-admin/database');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const {
  buildNewEntryMessage,
  recipientUids,
  wantsNewEntryPush,
  isStaleTokenError,
  groupTokensByLang,
} = require('../push');
const { buildCalledMessage, buildNextMessage, pickNextWaiting } = require('../webpush');
const { logError } = require('../log');

async function notifyEntryCalled({ queueId, after }) {
  const token = after.fcmToken;
  if (!token) {
    return null;
  }

  let queueName = 'Fila';
  try {
    const metaSnap = await getDatabase()
      .ref(`queues/${queueId}/meta/name`)
      .once('value');
    if (metaSnap.exists()) {
      queueName = metaSnap.val();
    }
  } catch {
    // fallback name
  }

  const message = buildCalledMessage({
    token,
    ticket: after.ticket,
    queueName,
    queueId,
    lang: after.lang,
  });

  try {
    await getMessaging().send(message);
    return { ok: true };
  } catch (err) {
    logError('onEntryCalled failed', err, { queueId });
    return null;
  }
}

async function notifyEntryJoined({ queueId, after: entry }) {
  if (!entry || entry.status !== 'waiting' || entry.manual === true) return null;
  const db = getDatabase();
  const firestore = getFirestore();

  try {
    const [ownerSnap, opsSnap, nameSnap] = await Promise.all([
      db.ref(`owners/${queueId}/ownerUid`).once('value'),
      db.ref(`queues/${queueId}/operatorUids`).once('value'),
      db.ref(`queues/${queueId}/meta/name`).once('value'),
    ]);
    const ops = opsSnap.val() ?? {};
    const uids = recipientUids({
      ownerUid: ownerSnap.val(),
      operatorUids: Object.keys(ops).filter((k) => ops[k] === true),
    });

    const devices = [];
    for (const uid of uids) {
      const ownerDoc = await firestore.doc(`owners/${uid}`).get();
      if (!wantsNewEntryPush(ownerDoc.data())) continue;
      const snap = await firestore.collection(`owners/${uid}/devices`).get();
      snap.forEach((d) => devices.push({ ref: d.ref, ...d.data() }));
    }
    if (devices.length === 0) return null;

    const byLang = groupTokensByLang(devices);
    const refsByToken = new Map(devices.map((d) => [d.token, d.ref]));
    for (const [lang, tokens] of Object.entries(byLang)) {
      for (let i = 0; i < tokens.length; i += 500) {
        const chunk = tokens.slice(i, i + 500);
        const response = await getMessaging().sendEachForMulticast({
          tokens: chunk,
          ...buildNewEntryMessage({
            queueId,
            queueName: nameSnap.val(),
            entryName: entry.name,
            lang,
          }),
        });
        await Promise.all(
          response.responses.map((r, idx) =>
            !r.success && isStaleTokenError(r.error?.code)
              ? refsByToken.get(chunk[idx])?.delete()
              : null,
          ),
        );
      }
    }
  } catch (err) {
    logError('onEntryJoined failed', err, { queueId });
  }
  return null;
}

async function notifyQueueAdvanced({ queueId }) {
  const db = getDatabase();
  try {
    const snap = await db
      .ref(`queues/${queueId}/entries`)
      .orderByChild('status')
      .equalTo('waiting')
      .once('value');
    const next = pickNextWaiting(snap.val());
    if (!next || !next.fcmToken || next.nextNotifiedAt) return null;
    const nameSnap = await db.ref(`queues/${queueId}/meta/name`).once('value');
    await db
      .ref(`queues/${queueId}/entries/${next.id}/nextNotifiedAt`)
      .set(Date.now());
    await getMessaging().send(
      buildNextMessage({
        token: next.fcmToken,
        queueName: nameSnap.val(),
        queueId,
        lang: next.lang,
      }),
    );
  } catch (err) {
    logError('onQueueAdvanced failed', err, { queueId });
  }
  return null;
}

module.exports = { notifyEntryCalled, notifyEntryJoined, notifyQueueAdvanced };
