const crypto = require('node:crypto');
const { pruneTimestamps, isRateLimited } = require('./join');

const DSR_RATE_LIMIT = { max: 20, windowMs: 60 * 60 * 1000 };
const BATCH_SIZE = 450;
const MAX_PAGES = 200;
const MAX_EXPORT_RECORDS = 5000;
const MAX_LOG_QUEUES = 100;
const ANONYMOUS_NAME = 'Anônimo';

function normalizePhone(raw) {
  if (typeof raw !== 'string' || raw.length > 40) return null;
  const digits = raw.replace(/\D/g, '');
  return digits.length === 10 || digits.length === 11 ? digits : null;
}

function maskPhone(digits) {
  const area = digits.slice(0, 2);
  const rest = digits.slice(2);
  const split = digits.length === 11 ? 5 : 4;
  return `(${area}) ${rest.slice(0, split)}-${rest.slice(split)}`;
}

function phoneForms(digits) {
  return [maskPhone(digits), digits];
}

function hashPhone(digits, uid, pepper = '') {
  return crypto
    .createHash('sha256')
    .update(`${pepper}:${uid}:${digits}`)
    .digest('hex')
    .slice(0, 32);
}

function normalizeMode(value) {
  return value === 'delete' || value === 'anonymize' ? value : null;
}

function dsrRateKey(uid) {
  return uid;
}

function nextDsrRateState(current, now, options = DSR_RATE_LIMIT) {
  const recent = pruneTimestamps(current, now, options.windowMs);
  if (isRateLimited(recent, now, options)) return { limited: true, timestamps: recent };
  return { limited: false, timestamps: [...recent, now] };
}

function toMs(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  return null;
}

async function collectPages(page, limit = BATCH_SIZE, maxPages = MAX_PAGES) {
  const all = [];
  let after = null;
  for (let i = 0; i < maxPages; i += 1) {
    const docs = await page(after, limit);
    if (docs.length === 0) break;
    all.push(...docs);
    after = docs[docs.length - 1].id;
    if (docs.length < limit) break;
  }
  return all;
}

function chunk(list, size = BATCH_SIZE) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

async function loadQueueData(queue, forms, deps) {
  const history = await collectPages((after, limit) =>
    deps.pageHistory(queue.id, forms, after, limit),
  );
  const feedback = [];
  for (const ids of chunk(
    history.map((h) => h.id),
    BATCH_SIZE,
  )) {
    feedback.push(...(await deps.getFeedback(queue.id, ids)));
  }
  const entries = await deps.findEntries(queue.id, forms);
  return { history, feedback, entries };
}

function range(values) {
  const list = values.filter((v) => typeof v === 'number');
  if (list.length === 0) return { firstAt: null, lastAt: null };
  return { firstAt: Math.min(...list), lastAt: Math.max(...list) };
}

function summarize(queue, data) {
  const times = [
    ...data.history.map((h) => toMs(h.data.finishedAt) ?? toMs(h.data.joinedAt)),
    ...data.entries.map((e) => toMs(e.data.joinedAt)),
  ];
  return {
    queueId: queue.id,
    queueName: queue.name ?? '',
    history: data.history.length,
    feedback: data.feedback.length,
    entries: data.entries.length,
    ...range(times),
  };
}

function totalsOf(queues) {
  return queues.reduce(
    (acc, q) => ({
      history: acc.history + q.history,
      feedback: acc.feedback + q.feedback,
      entries: acc.entries + q.entries,
    }),
    { history: 0, feedback: 0, entries: 0 },
  );
}

function auditDoc({ action, mode, phoneHash, queues, complete, now }) {
  const doc = {
    action,
    phoneHash,
    totals: totalsOf(queues),
    queues: queues.slice(0, MAX_LOG_QUEUES).map((q) => ({
      queueId: q.queueId,
      history: q.history,
      feedback: q.feedback,
      entries: q.entries,
    })),
    complete,
    createdAt: now,
  };
  if (mode) doc.mode = mode;
  return doc;
}

async function findCustomerData({ uid, digits, now, pepper }, deps) {
  const forms = phoneForms(digits);
  const queues = await deps.listOwnedQueues(uid);
  const summaries = [];
  for (const queue of queues) {
    const data = await loadQueueData(queue, forms, deps);
    const summary = summarize(queue, data);
    if (summary.history + summary.feedback + summary.entries > 0) summaries.push(summary);
  }
  await deps.writeLog(
    uid,
    auditDoc({
      action: 'find',
      phoneHash: hashPhone(digits, uid, pepper),
      queues: summaries,
      complete: true,
      now,
    }),
  );
  return { queues: summaries, totals: totalsOf(summaries), queuesScanned: queues.length };
}

function csvCell(value) {
  let v = value === null || value === undefined ? '' : String(value);
  if (v.length > 0 && (v.charCodeAt(0) < 0x20 || '=+-@'.includes(v[0]))) v = `'${v}`;
  return /[",\n\r]/.test(v) ? `"${v.replace(/"/g, '""')}"` : v;
}

const CSV_HEADER = [
  'queue',
  'source',
  'ticket',
  'name',
  'phone',
  'result',
  'joinedAt',
  'calledAt',
  'finishedAt',
  'rating',
  'comment',
];

function iso(value) {
  const ms = toMs(value);
  return ms === null ? '' : new Date(ms).toISOString();
}

function toCsv(records) {
  const lines = [CSV_HEADER.join(',')];
  for (const r of records) {
    lines.push(
      [
        r.queue,
        r.source,
        r.ticket,
        r.name,
        r.phone,
        r.result,
        r.joinedAt,
        r.calledAt,
        r.finishedAt,
        r.rating,
        r.comment,
      ]
        .map(csvCell)
        .join(','),
    );
  }
  return lines.join('\n');
}

function recordsFor(queue, data) {
  const feedbackById = new Map(data.feedback.map((f) => [f.id, f.data]));
  const records = [];
  for (const h of data.history) {
    const fb = feedbackById.get(h.id);
    records.push({
      queue: queue.name ?? queue.id,
      source: 'history',
      ticket: h.data.ticket ?? null,
      name: h.data.name ?? '',
      phone: h.data.phone ?? '',
      result: h.data.result ?? '',
      joinedAt: iso(h.data.joinedAt),
      calledAt: iso(h.data.calledAt),
      finishedAt: iso(h.data.finishedAt),
      rating: fb && typeof fb.rating === 'number' ? fb.rating : null,
      comment: fb && typeof fb.comment === 'string' ? fb.comment : '',
    });
  }
  for (const e of data.entries) {
    records.push({
      queue: queue.name ?? queue.id,
      source: 'active',
      ticket: e.data.ticket ?? null,
      name: e.data.name ?? '',
      phone: e.data.phone ?? '',
      result: e.data.status ?? '',
      joinedAt: iso(e.data.joinedAt),
      calledAt: iso(e.data.calledAt),
      finishedAt: '',
      rating: null,
      comment: '',
    });
  }
  return records;
}

async function exportCustomerData({ uid, digits, now, pepper }, deps) {
  const forms = phoneForms(digits);
  const queues = await deps.listOwnedQueues(uid);
  const summaries = [];
  const records = [];
  for (const queue of queues) {
    const data = await loadQueueData(queue, forms, deps);
    const summary = summarize(queue, data);
    if (summary.history + summary.feedback + summary.entries === 0) continue;
    summaries.push(summary);
    records.push(...recordsFor(queue, data));
  }
  const truncated = records.length > MAX_EXPORT_RECORDS;
  const kept = truncated ? records.slice(0, MAX_EXPORT_RECORDS) : records;
  await deps.writeLog(
    uid,
    auditDoc({
      action: 'export',
      phoneHash: hashPhone(digits, uid, pepper),
      queues: summaries,
      complete: !truncated,
      now,
    }),
  );
  return {
    records: kept,
    csv: toCsv(kept),
    truncated,
    totals: totalsOf(summaries),
  };
}

async function eraseQueue(queue, forms, mode, deps) {
  const summary = { queueId: queue.id, queueName: queue.name ?? '', history: 0, feedback: 0, entries: 0 };

  const ids = new Set();
  const feedbackIds = new Set();
  for (let i = 0; i < MAX_PAGES; i += 1) {
    const docs = await deps.pageHistory(queue.id, forms, null, BATCH_SIZE);
    if (docs.length === 0) break;
    const batchIds = docs.map((d) => d.id);
    const feedback = await deps.getFeedback(queue.id, batchIds);
    const fbIds = feedback.map((f) => f.id);
    if (mode === 'delete') {
      if (fbIds.length) await deps.deleteFeedback(queue.id, fbIds);
      await deps.deleteHistory(queue.id, batchIds);
    } else {
      if (fbIds.length) await deps.clearFeedbackComments(queue.id, fbIds);
      await deps.anonymizeHistory(queue.id, batchIds);
    }
    batchIds.forEach((id) => ids.add(id));
    fbIds.forEach((id) => feedbackIds.add(id));
    if (docs.length < BATCH_SIZE) break;
  }
  summary.history = ids.size;
  summary.feedback = feedbackIds.size;

  const entries = await deps.findEntries(queue.id, forms);
  if (entries.length > 0) {
    await deps.removeEntries(
      queue.id,
      entries.map((e) => e.id),
    );
  }
  summary.entries = entries.length;
  return summary;
}

async function eraseCustomerData({ uid, digits, mode, now, pepper, onError = () => {} }, deps) {
  const forms = phoneForms(digits);
  const queues = await deps.listOwnedQueues(uid);
  const summaries = [];
  let failed = 0;
  for (const queue of queues) {
    try {
      const summary = await eraseQueue(queue, forms, mode, deps);
      if (summary.history + summary.feedback + summary.entries > 0) summaries.push(summary);
    } catch (err) {
      failed += 1;
      onError(err, { queueId: queue.id });
    }
  }
  const complete = failed === 0;
  await deps.writeLog(
    uid,
    auditDoc({
      action: 'erase',
      mode,
      phoneHash: hashPhone(digits, uid, pepper),
      queues: summaries,
      complete,
      now,
    }),
  );
  return { queues: summaries, totals: totalsOf(summaries), complete, failedQueues: failed };
}

module.exports = {
  DSR_RATE_LIMIT,
  BATCH_SIZE,
  MAX_EXPORT_RECORDS,
  ANONYMOUS_NAME,
  normalizePhone,
  maskPhone,
  phoneForms,
  hashPhone,
  normalizeMode,
  dsrRateKey,
  nextDsrRateState,
  toMs,
  collectPages,
  chunk,
  toCsv,
  csvCell,
  auditDoc,
  findCustomerData,
  exportCustomerData,
  eraseCustomerData,
};
