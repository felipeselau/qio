const {
  buildMetaPatch,
  buildOwnerPatch,
  changedFields,
  ownerChanged,
  isMirrorable,
  isValidUid,
} = require('../mirror');

function snapData(snap) {
  return snap && snap.exists ? snap.data() : null;
}

function createMirrorQueueHandler(deps) {
  return async (event) => {
    const { queueId } = event.params;
    try {
      const before = snapData(event.data?.before);
      const after = snapData(event.data?.after);
      if (!after || after.deleting) return null;

      const fields = changedFields(before, after);
      const ownerDirty = ownerChanged(before, after);
      if (fields.size === 0 && !ownerDirty) return null;

      const current = await deps.readQueueDoc(queueId);
      if (!isMirrorable(current)) return null;

      if (ownerDirty) {
        const ownerPatch = buildOwnerPatch(current, await deps.readOwner(queueId));
        if (ownerPatch) await deps.setOwner(queueId, ownerPatch);
      }
      if (fields.size === 0) return { ok: true };

      const meta = await deps.readMeta(queueId);
      if (meta === null || meta === undefined) {
        if (before) {
          deps.warn('mirrorQueueToRtdb: meta ausente em fila existente, nada criado', { queueId });
          return null;
        }
        const patch = buildMetaPatch(current, null);
        await deps.createMeta(queueId, { ...patch, updatedAt: deps.now() });
        return { ok: true };
      }

      const patch = buildMetaPatch(current, meta, fields);
      if (Object.keys(patch).length === 0) return null;
      await deps.updateMeta(queueId, patch);
      return { ok: true };
    } catch (err) {
      deps.onError('mirrorQueueToRtdb failed', err, { queueId });
      return null;
    }
  };
}

function createMirrorOperatorHandler(deps) {
  return async (event) => {
    const { queueId, uid } = event.params;
    try {
      if (!isValidUid(uid)) return null;
      const exists = await deps.operatorExists(queueId, uid);
      if (!exists) {
        await deps.removeOperator(queueId, uid);
        return { ok: true };
      }
      const queue = await deps.readQueueDoc(queueId);
      if (!isMirrorable(queue)) return null;
      if (await deps.readOperator(queueId, uid)) return null;
      await deps.setOperator(queueId, uid);
      return { ok: true };
    } catch (err) {
      deps.onError('mirrorOperatorToRtdb failed', err, { queueId });
      return null;
    }
  };
}

module.exports = { createMirrorQueueHandler, createMirrorOperatorHandler };
