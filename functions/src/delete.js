const QUEUE_RTDB_PATHS = (queueId) => [
  `queues/${queueId}/entries`,
  `queues/${queueId}/public`,
  `queues/${queueId}/operatorUids`,
  `tickets/${queueId}`,
  `rateLimits/${queueId}`,
  `queues/${queueId}/meta`,
];

const MAX_ID = 128;
const SAFE_ID = /^[A-Za-z0-9_-]+$/;
const DEFAULT_MAX_LOGIN_AGE_SEC = 300;

function isSafeId(value) {
  return typeof value === 'string' && value.length <= MAX_ID && SAFE_ID.test(value);
}

function assertRecentLogin(
  authTimeSec,
  nowSec,
  maxAgeSec = DEFAULT_MAX_LOGIN_AGE_SEC,
  makeError = (message, details) => {
    const err = new Error(message);
    err.code = 'failed-precondition';
    err.details = details;
    return err;
  },
) {
  const valid =
    typeof authTimeSec === 'number' &&
    Number.isFinite(authTimeSec) &&
    nowSec - authTimeSec <= maxAgeSec;
  if (!valid) {
    throw makeError('Confirme sua identidade novamente.', { reason: 'recent-login' });
  }
}

function invitesToDelete(invites, queueId, ownerId) {
  return invites
    .filter((i) => i && i.queueId === queueId && i.ownerId === ownerId)
    .map((i) => i.code);
}

function slugsToDelete(slugs, queueId, ownerId) {
  return slugs
    .filter((s) => s && s.queueId === queueId && s.ownerId === ownerId)
    .map((s) => s.slug);
}

async function deleteLogoFiles(bucket, queueId, warn = () => {}) {
  const [exists] = await bucket.exists();
  if (!exists) {
    warn('delete-queue:bucket-missing', { queueId });
    return false;
  }
  await bucket.deleteFiles({ prefix: `queue-logos/${queueId}/`, force: true });
  return true;
}

async function deleteQueueData(queueId, ownerId, deps, log = () => {}) {
  await deps.markDeleting(queueId);
  log('delete-queue:marked', { queueId });

  for (const path of QUEUE_RTDB_PATHS(queueId)) {
    await deps.removeRtdb(path);
  }
  log('delete-queue:rtdb', { queueId });

  await deps.deleteSubcollections(queueId);
  log('delete-queue:subcollections', { queueId });

  const invites = await deps.listInvites(queueId);
  for (const code of invitesToDelete(invites, queueId, ownerId)) {
    await deps.deleteInvite(code);
  }

  const slugs = await deps.listSlugs(queueId);
  for (const slug of slugsToDelete(slugs, queueId, ownerId)) {
    await deps.deleteSlug(slug);
  }

  await deps.deleteLogos(queueId);
  log('delete-queue:storage', { queueId });

  await deps.removeRtdb(`owners/${queueId}`);
  await deps.deleteQueueDoc(queueId);
  log('delete-queue:done', { queueId });
}

async function deleteOwnedQueue(queueId, uid, deps, log = () => {}) {
  const queue = await deps.getQueue(queueId);
  if (!queue) return { deleted: false, alreadyGone: true };
  if (queue.ownerId !== uid) return { deleted: false, forbidden: true };
  await deleteQueueData(queueId, uid, deps, log);
  return { deleted: true, alreadyGone: false };
}

async function deleteAccountData(uid, deps, log = () => {}) {
  const failures = { queues: 0, operatorLinks: 0 };

  const queueIds = await deps.listOwnedQueueIds(uid);
  let queuesDeleted = 0;
  for (const queueId of queueIds) {
    try {
      await deleteQueueData(queueId, uid, deps, log);
      queuesDeleted += 1;
    } catch (err) {
      failures.queues += 1;
      log('delete-account:queue-failed', { queueId, code: err?.code });
    }
  }

  const links = await deps.listOperatorLinks(uid);
  let linksRemoved = 0;
  for (const link of links) {
    try {
      await deps.removeOperatorLink(link, uid);
      linksRemoved += 1;
    } catch (err) {
      failures.operatorLinks += 1;
      log('delete-account:link-failed', { queueId: link.queueId, code: err?.code });
    }
  }

  const summary = {
    queuesDeleted,
    operatorLinksRemoved: linksRemoved,
    failures,
  };
  if (failures.queues > 0 || failures.operatorLinks > 0) {
    return { ...summary, complete: false };
  }

  await deps.deleteOwnerData(uid);
  log('delete-account:owner', {});
  await deps.deleteAuthUser(uid);
  log('delete-account:done', { queuesDeleted, operatorLinksRemoved: linksRemoved });
  return { ...summary, complete: true };
}

module.exports = {
  QUEUE_RTDB_PATHS,
  isSafeId,
  assertRecentLogin,
  invitesToDelete,
  slugsToDelete,
  deleteLogoFiles,
  deleteQueueData,
  deleteOwnedQueue,
  deleteAccountData,
};
