const MIN_SAMPLES = 3;
const MAX_SAMPLES = 20;
const OUTLIER_FACTOR = 3;

function toMillis(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (value && typeof value.toMillis === 'function') {
    const ms = value.toMillis();
    return Number.isFinite(ms) ? ms : null;
  }
  return null;
}

function serviceMinutesOf(doc) {
  if (!doc || doc.result !== 'served') return null;
  const calledAt = toMillis(doc.calledAt);
  const finishedAt = toMillis(doc.finishedAt);
  if (calledAt === null || finishedAt === null) return null;
  const duration = finishedAt - calledAt;
  if (duration <= 0) return null;
  return duration / 60000;
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

function estimateServiceMin(docs, options = {}) {
  const { minSamples = MIN_SAMPLES, maxSamples = MAX_SAMPLES } = options;
  if (!Array.isArray(docs)) return null;
  const samples = docs
    .map((doc) => ({ doc, minutes: serviceMinutesOf(doc) }))
    .filter((s) => s.minutes !== null)
    .sort((a, b) => toMillis(b.doc.finishedAt) - toMillis(a.doc.finishedAt))
    .slice(0, maxSamples)
    .map((s) => s.minutes);
  if (samples.length < minSamples) return null;
  const limit = median(samples) * OUTLIER_FACTOR;
  const kept = samples.filter((m) => m <= limit);
  if (kept.length === 0) return null;
  const avg = kept.reduce((sum, m) => sum + m, 0) / kept.length;
  return Math.round(avg * 10) / 10;
}

module.exports = {
  MIN_SAMPLES,
  MAX_SAMPLES,
  OUTLIER_FACTOR,
  serviceMinutesOf,
  estimateServiceMin,
};
