const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const logger = require('firebase-functions/logger');
const {
  rateLimitFromEnv,
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
  CLAIM_RATE_LIMIT,
  CLAIM_PHONE_RATE_LIMIT,
  claimPhoneKey,
  uidHash,
  pickClaimable,
  claimEntryUpdate,
} = require('../join');
const { isQueueFull } = require('../capacity');
const { normalizeMode, parseSlots, slotsFromDoc } = require('../slots');
const { normalizeLang } = require('../push');
const { logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { isEnforced } = require('../appcheck');
const { findActive, resolveSlot } = require('./_shared');

const RATE_LIMIT = rateLimitFromEnv(process.env);

exports.joinQueue = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: isEnforced('joinQueue'),
  },
  guarded('joinQueue', async (request) => {
    logAppCheck('joinQueue', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para entrar na fila.');
    }

    const data = request.data ?? {};
    const queueId = typeof data.queueId === 'string' ? data.queueId.trim() : '';
    if (!queueId || queueId.includes('/') || /[.#$\[\]]/.test(queueId)) {
      throw new HttpsError('invalid-argument', 'Fila inválida.');
    }
    const name = normalizeName(data.name);
    if (!name) {
      throw new HttpsError(
        'invalid-argument',
        'Informe um nome com até 60 caracteres.',
      );
    }
    const phone = data.phone === undefined || data.phone === null ? '' : data.phone;
    if (typeof phone !== 'string' || !isValidPhone(phone.trim())) {
      throw new HttpsError(
        'invalid-argument',
        'Telefone inválido. Use o formato (00) 00000-0000.',
      );
    }
    const cleanPhone = phone.trim();
    const lang = normalizeLang(data.lang);

    const db = getDatabase();
    const metaSnap = await db.ref(`queues/${queueId}/meta`).once('value');
    if (!metaSnap.exists()) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    if (metaSnap.child('status').val() !== 'open') {
      throw new HttpsError('failed-precondition', 'Fila fechada ou pausada.');
    }
    if (metaSnap.child('deleting').val() === true) {
      throw new HttpsError('failed-precondition', 'Fila fechada ou pausada.');
    }

    const entriesRef = db.ref(`queues/${queueId}/entries`);

    const mine = findActive(
      await entriesRef.orderByChild('uid').equalTo(uid).once('value'),
    );
    if (mine.length > 0) {
      const existing = mine.sort((a, b) => (a.joinedAt ?? 0) - (b.joinedAt ?? 0))[0];
      return { entryId: existing.entryId, ticket: existing.ticket, existing: true };
    }

    if (cleanPhone) {
      const samePhone = findActive(
        await entriesRef.orderByChild('phone').equalTo(cleanPhone).once('value'),
      );
      if (samePhone.length > 0) {
        const claimNow = Date.now();
        const consume = async (path, limit) => {
          let limited = false;
          await db.ref(path).transaction((current) => {
            const recent = pruneTimestamps(current, claimNow, limit.windowMs);
            if (isRateLimited(recent, claimNow, limit)) {
              limited = true;
              return recent;
            }
            limited = false;
            return [...recent, claimNow];
          });
          return limited;
        };
        const phoneKey = claimPhoneKey(queueId, cleanPhone, process.env.DSR_HASH_PEPPER ?? '');
        const byUid = await consume(`rateLimits/${queueId}/_claim/uid/${uid}`, CLAIM_RATE_LIMIT);
        const byPhone = await consume(
          `rateLimits/${queueId}/_claim/phone/${phoneKey}`,
          CLAIM_PHONE_RATE_LIMIT,
        );
        if (byUid || byPhone) {
          throw new HttpsError(
            'resource-exhausted',
            'Muitas tentativas. Aguarde alguns minutos.',
            { reason: 'claim-rate' },
          );
        }
        const target = pickClaimable(samePhone, name, uid);
        if (!target) {
          throw new HttpsError('already-exists', 'Este telefone já está na fila.');
        }
        const claimed = await entriesRef
          .child(target.entryId)
          .transaction((current) => claimEntryUpdate(current, target.uid, uid));
        const result = claimed.snapshot.val();
        if (!claimed.committed || !result || result.uid !== uid) {
          throw new HttpsError(
            'aborted',
            'Esta senha mudou enquanto você a recuperava. Tente de novo.',
            { reason: 'claim-lost' },
          );
        }
        logger.info('joinQueue:claimed', {
          event: 'claim',
          claimed: true,
          queueId,
          entryId: target.entryId,
          previousUidHash: uidHash(target.uid),
        });
        return {
          entryId: target.entryId,
          ticket: result.ticket,
          existing: true,
          claimed: true,
        };
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
        slotId: data.slotId,
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

    const now = Date.now();
    let limited = false;
    await db.ref(`rateLimits/${queueId}/${uid}`).transaction((current) => {
      const recent = pruneTimestamps(current, now, RATE_LIMIT.windowMs);
      if (isRateLimited(recent, now, RATE_LIMIT)) {
        limited = true;
        return recent;
      }
      limited = false;
      return [...recent, now];
    });
    if (limited) {
      throw new HttpsError(
        'resource-exhausted',
        'Muitas tentativas. Aguarde alguns minutos.',
      );
    }

    const ticketResult = await db
      .ref(`tickets/${queueId}`)
      .transaction((current) => (current ?? 0) + 1);
    const ticket = ticketResult.snapshot.val();

    const newRef = entriesRef.push();
    await newRef.set({
      ticket,
      name,
      phone: cleanPhone,
      uid,
      lang,
      status: 'waiting',
      joinedAt: Date.now(),
      ...(slotFields ?? {}),
    });

    return { entryId: newRef.key, ticket, existing: false };
  }),
);
