const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');
const {
  normalizeRating,
  normalizeComment,
  isValidId,
  buildFeedbackDoc,
} = require('../feedback');
const { logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { isEnforced } = require('../appcheck');

exports.submitFeedback = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: isEnforced('submitFeedback'),
  },
  guarded('submitFeedback', async (request) => {
    logAppCheck('submitFeedback', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para avaliar.');
    }
    const data = request.data ?? {};
    if (!isValidId(data.queueId) || !isValidId(data.entryId)) {
      throw new HttpsError('invalid-argument', 'Atendimento inválido.');
    }
    const rating = normalizeRating(data.rating);
    if (rating === null) {
      throw new HttpsError('invalid-argument', 'A nota deve ser de 1 a 5.');
    }
    const comment = normalizeComment(data.comment);
    if (comment === null) {
      throw new HttpsError('invalid-argument', 'Comentário muito longo.');
    }

    const firestore = getFirestore();
    const historySnap = await firestore
      .doc(`queues/${data.queueId}/history/${data.entryId}`)
      .get();
    if (!historySnap.exists || historySnap.get('result') !== 'served') {
      throw new HttpsError('failed-precondition', 'Atendimento não encontrado.');
    }

    try {
      await firestore
        .doc(`queues/${data.queueId}/feedback/${data.entryId}`)
        .create(buildFeedbackDoc({ rating, comment, uid }, Date.now()));
    } catch (err) {
      if (err?.code !== 6) throw err;
      return { ok: true, existing: true };
    }
    return { ok: true, existing: false };
  }),
);
