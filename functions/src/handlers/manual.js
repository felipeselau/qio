const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { isQueueFull } = require('../capacity');
const { normalizeMode, parseSlots, slotsFromDoc } = require('../slots');
const {
  parseManualInput,
  isQueueStaff,
  buildManualEntry,
  manualRateKey,
  nextManualRateState,
  isActiveCeilingReached,
  resolveActiveCeiling,
} = require('../manual');
const { logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { findActive, resolveSlot } = require('./_shared');

exports.addManualEntry = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: false,
  },
  guarded('addManualEntry', async (request) => {
    logAppCheck('addManualEntry', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para adicionar pessoas.');
    }

    const parsed = parseManualInput(request.data);
    if (parsed.error === 'invalid-queue') {
      throw new HttpsError('invalid-argument', 'Fila inválida.');
    }
    if (parsed.error === 'invalid-name') {
      throw new HttpsError('invalid-argument', 'Informe um nome com até 60 caracteres.');
    }
    if (parsed.error === 'invalid-phone') {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use o formato (00) 00000-0000.',
      );
    }
    const { queueId, name, phone, slotId } = parsed;

    const db = getDatabase();
    const [ownerSnap, opsSnap] = await Promise.all([
      db.ref(`owners/${queueId}/ownerUid`).once('value'),
      db.ref(`queues/${queueId}/operatorUids`).once('value'),
    ]);
    if (!isQueueStaff(uid, ownerSnap.val(), opsSnap.val())) {
      throw new HttpsError('permission-denied', 'Sem permissão para esta fila.');
    }

    const metaSnap = await db.ref(`queues/${queueId}/meta`).once('value');
    if (!metaSnap.exists()) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    if (metaSnap.child('status').val() !== 'open') {
      throw new HttpsError('failed-precondition', 'Fila fechada ou pausada.');
    }

    const entriesRef = db.ref(`queues/${queueId}/entries`);

    if (phone) {
      const samePhone = findActive(
        await entriesRef.orderByChild('phone').equalTo(phone).once('value'),
      );
      if (samePhone.length > 0) {
        throw new HttpsError('already-exists', 'Este telefone já está na fila.');
      }
    }

    let mode = normalizeMode(metaSnap.child('mode').val());
    let rawSlots = metaSnap.child('slots').val();
    if (!metaSnap.child('mode').exists()) {
      const queueDoc = await getFirestore().doc(`queues/${queueId}`).get();
      if (queueDoc.exists && normalizeMode(queueDoc.get('mode')) === 'schedule') {
        mode = 'schedule';
        rawSlots = slotsFromDoc(queueDoc.get('slots'));
      }
    }
    let slotFields = null;
    if (mode === 'schedule') {
      slotFields = await resolveSlot({
        entriesRef,
        slots: parseSlots(rawSlots),
        slotId,
        now: Date.now(),
      });
    }

    const maxWaiting = metaSnap.child('maxWaiting').val();
    if (maxWaiting) {
      const waitingSnap = await entriesRef
        .orderByChild('status')
        .equalTo('waiting')
        .once('value');
      if (isQueueFull(maxWaiting, waitingSnap.numChildren())) {
        throw new HttpsError('resource-exhausted', 'Fila lotada no momento.', {
          reason: 'queue-full',
        });
      }
    }

    if (!maxWaiting) {
      const [waitingSnap, calledSnap] = await Promise.all([
        entriesRef.orderByChild('status').equalTo('waiting').once('value'),
        entriesRef.orderByChild('status').equalTo('called').once('value'),
      ]);
      if (
        isActiveCeilingReached(
          maxWaiting,
          waitingSnap.numChildren() + calledSnap.numChildren(),
          resolveActiveCeiling(),
        )
      ) {
        throw new HttpsError('resource-exhausted', 'Fila lotada no momento.', {
          reason: 'queue-full',
        });
      }
    }

    const rateNow = Date.now();
    let limited = false;
    await db.ref(`rateLimits/${queueId}/${manualRateKey(uid)}`).transaction((current) => {
      const state = nextManualRateState(current, rateNow);
      limited = state.limited;
      return state.timestamps;
    });
    if (limited) {
      throw new HttpsError(
        'resource-exhausted',
        'Muitas adições. Aguarde alguns minutos.',
        { reason: 'rate-limited' },
      );
    }

    const ticketResult = await db
      .ref(`tickets/${queueId}`)
      .transaction((current) => (current ?? 0) + 1);
    const ticket = ticketResult.snapshot.val();

    const newRef = entriesRef.push();
    await newRef.set(
      buildManualEntry({ ticket, name, phone, now: Date.now(), slotFields }),
    );

    return { entryId: newRef.key, ticket };
  }),
);
