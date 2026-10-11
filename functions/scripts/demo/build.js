'use strict';

const { Timestamp } = require('firebase-admin/firestore');
const { createRng } = require('./rng');
const { simulateQueue } = require('./simulate');
const accounts = require('./accounts');
const { estimateServiceMin } = require('../../src/estimate');
const { publicTicketFor, countWaiting } = require('../../src/ticket');
const { isWithinSchedule, nextOpening, DEFAULT_TIMEZONE } = require('../../src/schedule');
const { MINUTE, HOUR, DAY, spStartOfDay, spDayKey } = require('./timeutil');

const DEFAULT_SEED = 'qio-demo-v1';
const DEFAULT_DAYS = 120;
const INVITE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const ts = (ms) => Timestamp.fromMillis(Math.floor(ms));
const pad2 = (n) => String(n).padStart(2, '0');

function queueIdOf(owner, queue) {
  return `${accounts.ID_PREFIX}${owner.key}-${queue.key}`;
}

function resolveStaff(owner, def) {
  return def.staff.map((s) => {
    if (s.ref === 'owner') return { ...s, uid: owner.uid, factor: s.factor ?? owner.factor ?? 1 };
    const op = accounts.OPERATORS.find((o) => o.key === s.ref);
    if (!op) throw new Error(`Operador desconhecido: ${s.ref}`);
    return { ...s, uid: op.uid, factor: s.factor ?? op.factor, op };
  });
}

function resolveSchedule(def, now) {
  if (!def.schedule) return null;
  let windows = def.schedule.windows;
  const probe = { enabled: true, timezone: DEFAULT_TIMEZONE, windows };
  if (def.closedNow && isWithinSchedule(probe, now)) {
    const hh = Math.floor((now - spStartOfDay(now)) / HOUR);
    windows = [{ days: [1, 2, 3, 4, 5, 6, 7], open: `${pad2((hh + 2) % 24)}:00`, close: `${pad2((hh + 10) % 24)}:00` }];
  }
  return { enabled: true, timezone: DEFAULT_TIMEZONE, windows };
}

function strip(obj) {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== undefined));
}

function buildQueue({ owner, def, now, days, seed, groupIds }) {
  const id = queueIdOf(owner, def);
  const createdAt = now - def.createdDaysAgo * DAY;
  const staff = resolveStaff(owner, def);
  const slots = def.slotPlan ? accounts.makeSlots(def.slotPlan.ranges, def.slotPlan.stepMin, def.slotPlan.capacity) : [];
  const schedule = resolveSchedule(def, now);
  let status = def.status ?? 'open';
  let opensAt;
  if (schedule && !def.status) {
    status = isWithinSchedule(schedule, now) ? 'open' : 'closed';
    if (status === 'closed') opensAt = nextOpening(schedule, now);
  }
  const resetTicketDaily = Boolean(def.expiry?.enabled && def.expiry.resetTicketDaily);

  const profile = {
    ...def,
    mode: def.mode ?? 'queue',
    slots,
    staff,
    status,
    resetTicketDaily,
    ddd: owner.ddd,
    demand: def.demand ?? { base: 0 },
  };
  const sim = simulateQueue(profile, { seed, queueId: id, now, days, createdAt });

  const entries = {};
  for (const e of sim.live) {
    const { id: entryId, ...rest } = e;
    entries[entryId] = strip({ ...rest, recalls: rest.recalls, skips: rest.skips });
  }
  const publicMap = {};
  for (const [entryId, entry] of Object.entries(entries)) publicMap[entryId] = publicTicketFor(entry);

  const served = sim.history.filter((h) => h.result === 'served');
  const auto = estimateServiceMin(served);
  const waitingCount = countWaiting(publicMap);

  const resumeAt = def.resumeInMin ? Math.floor(now + def.resumeInMin * MINUTE) : undefined;
  const rng = createRng(`${seed}:invite:${id}`);
  const inviteCode = def.invite ? rng.token(6, INVITE_ALPHABET) : undefined;
  const inviteExpiresAt = def.invite === 'expired' ? now - 30 * HOUR : def.invite ? now + 20 * HOUR : undefined;

  const alertState = def.alertStateAgoMin
    ? Object.fromEntries(Object.entries(def.alertStateAgoMin).map(([k, min]) => [k, Math.floor(now - min * MINUTE)]))
    : undefined;

  const fs = strip({
    ownerId: owner.uid,
    name: def.name,
    description: def.description ?? null,
    status,
    avgServiceMin: def.avgServiceMin,
    maxWaiting: def.maxWaiting ?? 0,
    groupId: def.group ? groupIds[def.group] : undefined,
    schedule: schedule ?? undefined,
    scheduleLastDesired: schedule ? status === 'open' : undefined,
    brandColor: def.brandColor,
    alerts: def.alerts,
    alertState: alertState,
    expiry: def.expiry,
    lastTicketResetDay: resetTicketDaily ? spDayKey(now) : undefined,
    anonymizePhone: def.anonymizePhone ? true : undefined,
    mode: def.mode === 'schedule' ? 'schedule' : undefined,
    slots: def.mode === 'schedule' ? slots : undefined,
    statusMessage: def.statusMessage,
    resumeAt: resumeAt ? ts(resumeAt) : undefined,
    slug: def.slug,
    posterTitle: def.posterTitle,
    operatorInviteCode: inviteCode,
    operatorInviteExpiresAt: inviteExpiresAt ? ts(inviteExpiresAt) : undefined,
    createdAt: ts(createdAt),
  });
  if (fs.alertState) fs.alertState = Object.fromEntries(Object.entries(fs.alertState).map(([k, v]) => [k, v]));

  const meta = strip({
    name: def.name,
    description: def.description ?? null,
    avgServiceMin: def.avgServiceMin,
    avgServiceMinAuto: auto ?? undefined,
    maxWaiting: def.maxWaiting ?? 0,
    status,
    statusMessage: def.statusMessage,
    resumeAt,
    brandColor: def.brandColor,
    mode: def.mode === 'schedule' ? 'schedule' : undefined,
    slots: def.mode === 'schedule' ? Object.fromEntries(slots.map((s) => [s.id, { start: s.start, capacity: s.capacity }])) : undefined,
    serving: sim.serving,
    nextTicket: 0,
    updatedAt: Math.floor(sim.lastActivity ?? createdAt),
    waitingCount,
    opensAt,
  });

  const operatorRefs = [];
  for (const s of staff) {
    if (s.op && !operatorRefs.some((o) => o.uid === s.op.uid)) operatorRefs.push(s.op);
  }
  const operators = operatorRefs.map((op) => ({
    uid: op.uid,
    data: {
      uid: op.uid,
      queueId: id,
      queueName: def.name,
      displayName: op.name,
      email: op.email,
      addedAt: ts(createdAt + 2 * DAY),
      addedBy: owner.uid,
    },
  }));
  const requests = operatorRefs.map((op) => ({
    uid: op.uid,
    data: {
      uid: op.uid,
      queueId: id,
      queueName: def.name,
      code: inviteCode ?? 'XXXXXX',
      status: 'approved',
      displayName: op.name,
      email: op.email,
      requestedAt: ts(createdAt + 1 * DAY),
      respondedAt: ts(createdAt + 2 * DAY),
    },
  }));
  const extra = [];
  if (def.pendingRequest) extra.push({ ref: def.pendingRequest, status: 'pending' });
  for (const r of accounts.requestStatuses) {
    if (r.queue === `${owner.key}/${def.key}`) extra.push({ ref: r.op, status: r.status });
  }
  for (const r of extra) {
    const op = accounts.OPERATORS.find((o) => o.key === r.ref);
    requests.push({
      uid: op.uid,
      data: {
        uid: op.uid,
        queueId: id,
        queueName: def.name,
        code: inviteCode ?? 'XXXXXX',
        status: r.status,
        displayName: op.name,
        email: op.email,
        requestedAt: ts(r.status === 'pending' ? now - 3 * HOUR : now - 20 * DAY),
        respondedAt: r.status === 'pending' ? null : ts(now - 19 * DAY),
      },
    });
  }

  const invite = inviteCode
    ? {
        code: inviteCode,
        data: {
          queueId: id,
          ownerId: owner.uid,
          queueName: def.name,
          expiresAt: ts(inviteExpiresAt),
          createdAt: ts(def.invite === 'expired' ? now - 54 * HOUR : now - 4 * HOUR),
        },
      }
    : null;

  const historyDocs = sim.history.map((h) => {
    const { id: hid, ...rest } = h;
    return {
      id: hid,
      data: strip({
        ...rest,
        joinedAt: ts(h.joinedAt),
        calledAt: h.calledAt == null ? null : ts(h.calledAt),
        finishedAt: ts(h.finishedAt),
      }),
    };
  });
  const feedbackDocs = sim.feedback.map((f) => ({
    id: f.id,
    data: { rating: f.rating, comment: f.comment, uid: f.uid, createdAt: ts(f.createdAt) },
  }));

  return {
    id,
    ownerUid: owner.uid,
    key: def.key,
    fs,
    meta,
    entries,
    public: publicMap,
    operatorUids: Object.fromEntries(operators.map((o) => [o.uid, true])),
    lastTicket: sim.lastTicket,
    history: historyDocs,
    feedback: feedbackDocs,
    operators,
    requests,
    invite,
    slug: def.slug ? { slug: def.slug, data: { queueId: id, ownerId: owner.uid, createdAt: ts(createdAt + DAY) } } : null,
    profile,
  };
}

function buildUniverse({ now = Date.now(), days = DEFAULT_DAYS, seed = DEFAULT_SEED, only } = {}) {
  const auth = [];
  const owners = [];
  const groups = [];
  const queues = [];
  const slugs = [];
  const invites = [];

  for (const op of accounts.OPERATORS) {
    auth.push({ uid: op.uid, email: op.email, displayName: op.name, role: 'operator' });
  }

  for (const owner of accounts.OWNERS) {
    if (only && !only.includes(owner.key)) continue;
    auth.push({ uid: owner.uid, email: owner.email, displayName: owner.displayName, role: 'owner' });
    const groupIds = {};
    for (const g of owner.groups) groupIds[g.key] = `${accounts.ID_PREFIX}grp-${owner.key}-${g.key}`;
    const built = owner.queues.map((def) => buildQueue({ owner, def, now, days, seed, groupIds }));
    queues.push(...built);
    const oldest = built.length > 0 ? Math.min(...built.map((q) => q.fs.createdAt.toMillis())) : now - (owner.freshAgoMin ?? 60) * MINUTE;
    const ownerCreated = built.length > 0 ? oldest - 3 * DAY : oldest;
    owners.push({
      uid: owner.uid,
      data: {
        name: owner.displayName,
        businessName: owner.businessName,
        notifyNewEntries: true,
        notifyAlerts: true,
        createdAt: ts(ownerCreated),
      },
    });
    for (const g of owner.groups) {
      groups.push({ ownerUid: owner.uid, id: groupIds[g.key], data: { name: g.name, createdAt: ts(ownerCreated + DAY) } });
    }
  }
  for (const q of queues) {
    if (q.slug) slugs.push(q.slug);
    if (q.invite) invites.push(q.invite);
  }

  return { now, days, seed, auth, owners, groups, queues, slugs, invites };
}

function scopeOf(universe) {
  return {
    uids: universe.auth.map((a) => a.uid),
    emails: universe.auth.map((a) => a.email),
    queueIds: universe.queues.map((q) => q.id),
    slugs: universe.slugs.map((s) => s.slug),
    inviteCodes: universe.invites.map((i) => i.code),
  };
}

module.exports = { buildUniverse, scopeOf, queueIdOf, DEFAULT_SEED, DEFAULT_DAYS };
