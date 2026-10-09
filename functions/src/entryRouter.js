const { shouldRenotify } = require('./ticket');
const { advancedFromWaiting } = require('./webpush');

const STEPS = ['sync', 'joined', 'called', 'advanced'];

function planEntryWrite(before, after) {
  return {
    sync: true,
    joined: (before === null || before === undefined) && !!after,
    called: shouldRenotify(before, after),
    advanced: advancedFromWaiting(before, after),
  };
}

async function routeEntryWrite({ queueId, entryId, before, after }, handlers) {
  const plan = planEntryWrite(before, after);
  const ctx = { queueId, entryId, before, after };
  const tasks = STEPS.filter((step) => plan[step] && handlers[step]).map(async (step) =>
    handlers[step](ctx),
  );
  const settled = await Promise.allSettled(tasks);
  const failed = settled.find((r) => r.status === 'rejected');
  if (failed) throw failed.reason;
  return null;
}

module.exports = { STEPS, planEntryWrite, routeEntryWrite };
