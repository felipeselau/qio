'use strict';

const MINUTE = 60 * 1000;

function percentile(sorted, p) {
  if (sorted.length === 0) return null;
  const idx = Math.min(sorted.length - 1, Math.floor(p * sorted.length));
  return sorted[idx];
}

function round(v, d = 1) {
  return v === null || v === undefined ? null : Math.round(v * 10 ** d) / 10 ** d;
}

function queueStats(q) {
  const h = q.history;
  const served = h.filter((d) => d.data.result === 'served');
  const noShow = h.filter((d) => d.data.result === 'no_show');
  const left = h.filter((d) => d.data.result === 'left');
  const waits = [...served, ...noShow]
    .map((d) => (d.data.calledAt.toMillis() - d.data.joinedAt.toMillis()) / MINUTE)
    .sort((a, b) => a - b);
  const services = served
    .map((d) => (d.data.finishedAt.toMillis() - d.data.calledAt.toMillis()) / MINUTE)
    .sort((a, b) => a - b);
  const rated = q.feedback.map((f) => f.data.rating);
  const attended = served.length + noShow.length;
  const days = new Set(h.map((d) => d.data.joinedAt.toDate().toISOString().slice(0, 10)));
  return {
    id: q.id,
    docs: h.length,
    days: days.size,
    served: served.length,
    noShowPct: attended > 0 ? round((100 * noShow.length) / attended) : null,
    leftPct: h.length > 0 ? round((100 * left.length) / h.length) : null,
    waitAvg: waits.length ? round(waits.reduce((a, b) => a + b, 0) / waits.length) : null,
    waitP90: round(percentile(waits, 0.9)),
    svcAvg: services.length ? round(services.reduce((a, b) => a + b, 0) / services.length) : null,
    feedback: rated.length,
    rating: rated.length ? round(rated.reduce((a, b) => a + b, 0) / rated.length, 2) : null,
    waitingNow: q.meta.waitingCount,
    calledNow: Object.values(q.entries).filter((e) => e.status === 'called').length,
    auto: q.meta.avgServiceMinAuto ?? null,
    status: q.meta.status,
  };
}

function summarize(universe) {
  return universe.queues.map(queueStats);
}

module.exports = { queueStats, summarize, percentile };
