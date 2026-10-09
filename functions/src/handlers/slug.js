const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { isSafeId } = require('../delete');
const {
  parseSlug,
  SLUG_RATE_USER,
  SLUG_RATE_IP,
  nextSlugRate,
  hashIp,
  isReleasedSlug,
} = require('../slug');
const { logAppCheck } = require('../log');
const { guarded } = require('../guard');
const { isEnforced } = require('../appcheck');

async function slugRateLimit(path, options, now) {
  let limited = false;
  await getDatabase()
    .ref(path)
    .transaction((current) => {
      const state = nextSlugRate(current, now, options);
      limited = state.limited;
      return state.timestamps;
    });
  return limited;
}

exports.resolveSlug = onCall(
  {
    region: 'us-central1',
    invoker: 'public',
    enforceAppCheck: isEnforced('resolveSlug'),
  },
  guarded('resolveSlug', async (request) => {
    logAppCheck('resolveSlug', request);
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Faça login para abrir o link.');
    }
    const slug = parseSlug(request.data?.slug);
    if (!slug) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    const now = Date.now();
    const ipHash = hashIp(request.rawRequest?.ip);
    const limited =
      (await slugRateLimit(`rateLimits/slug/${uid}`, SLUG_RATE_USER, now)) ||
      (ipHash !== null && (await slugRateLimit(`rateLimits/slugIp/${ipHash}`, SLUG_RATE_IP, now)));
    if (limited) {
      throw new HttpsError('resource-exhausted', 'Muitas tentativas. Aguarde um instante.');
    }
    const snap = await getFirestore().doc(`queueSlugs/${slug}`).get();
    const queueId = snap.exists && !isReleasedSlug(snap.data()) ? snap.get('queueId') : null;
    if (!isSafeId(queueId)) {
      throw new HttpsError('not-found', 'Fila não encontrada.');
    }
    return { queueId };
  }),
);
