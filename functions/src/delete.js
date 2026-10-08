const QUEUE_RTDB_PATHS = (queueId) => [
  `queues/${queueId}/meta`,
  `queues/${queueId}/entries`,
  `queues/${queueId}/public`,
  `queues/${queueId}/operatorUids`,
  `tickets/${queueId}`,
  `rateLimits/${queueId}`,
];

const MAX_ID = 128;

function isSafeId(value) {
  return (
    typeof value === 'string' &&
    value.length > 0 &&
    value.length <= MAX_ID &&
    !value.includes('/') &&
    !/[.#$\[\]]/.test(value)
  );
}

async function deleteQueueData(queueId, deps, log = () => {}) {
  await deps.markDeleting(queueId);
  log('delete-queue:marked', { queueId });

  for (const path of QUEUE_RTDB_PATHS(queueId)) {
    await deps.removeRtdb(path);
  }
  log('delete-queue:rtdb', { queueId });

  await deps.deleteSubcollections(queueId);
  log('delete-queue:subcollections', { queueId });

  const code = await deps.inviteCodeOf(queueId);
  if (code) await deps.deleteInvite(code);

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
  await deleteQueueData(queueId, deps, log);
  return { deleted: true, alreadyGone: false };
}

async function deleteAccountData(uid, deps, log = () => {}) {
  const failures = { queues: 0, operatorLinks: 0 };

  const queueIds = await deps.listOwnedQueueIds(uid);
  let queuesDeleted = 0;
  for (const queueId of queueIds) {
    try {
      await deleteQueueData(queueId, deps, log);
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
  deleteQueueData,
  deleteOwnedQueue,
  deleteAccountData,
};
