'use strict';

const { createRng } = require('./rng');
const { FIRST_NAMES, SURNAMES, COMMENTS } = require('./names');
const { MINUTE, HOUR, DAY, spStartOfDay, spDow, spDayKey, spMonthDay } = require('./timeutil');

const FIXED_HOLIDAYS = new Set(['01-01', '04-21', '05-01', '09-07', '10-12', '11-02', '11-15', '12-25']);
const OVERTIME_MS = 20 * MINUTE;
const LIVE_WINDOW_MS = 40 * MINUTE;
const CLOSED_CUTOFF_MS = 3 * HOUR;
const CLIENT_ALPHABET = 'abcdefghijklmnopqrstuvwxyz0123456789';

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function interp(points, daysAgo, fallback) {
  if (!Array.isArray(points) || points.length === 0) return fallback;
  const pts = [...points].sort((a, b) => b[0] - a[0]);
  if (daysAgo >= pts[0][0]) return pts[0][1];
  const last = pts[pts.length - 1];
  if (daysAgo <= last[0]) return last[1];
  for (let i = 0; i < pts.length - 1; i += 1) {
    const [a, va] = pts[i];
    const [b, vb] = pts[i + 1];
    if (daysAgo <= a && daysAgo >= b) {
      const f = a === b ? 0 : (a - daysAgo) / (a - b);
      return va + (vb - va) * f;
    }
  }
  return fallback;
}

function makeCustomers(rng, profile) {
  const ddds = profile.ddd && profile.ddd.length > 0 ? profile.ddd : [11];
  const phoneShare = profile.phoneShare ?? 0.7;

  function fresh(r) {
    const first = r.pick(FIRST_NAMES);
    const roll = r.next();
    let name = first;
    if (roll < 0.55) name = `${first} ${r.pick(SURNAMES)[0]}.`;
    else if (roll < 0.95) name = `${first} ${r.pick(SURNAMES)}`;
    let phone = '';
    if (r.chance(phoneShare)) {
      const ddd = r.pick(ddds);
      if (r.chance(0.85)) {
        phone = `(${ddd}) 9${r.int(1000, 9999)}-${r.int(1000, 9999)}`;
      } else {
        phone = `(${ddd}) ${r.int(2, 5)}${r.int(100, 999)}-${r.int(1000, 9999)}`;
      }
    }
    return { name: name.slice(0, 60), phone };
  }

  const poolRng = rng.fork('pool');
  const pool = Array.from({ length: profile.poolSize ?? 160 }, () => fresh(poolRng));
  const repeatShare = profile.repeatShare ?? 0.3;

  return {
    pick(r) {
      if (r.chance(repeatShare)) {
        const idx = Math.floor(pool.length * r.next() ** 2);
        return pool[idx];
      }
      return fresh(r);
    },
    fresh,
  };
}

function hoursOf(profile, dow) {
  const h = profile.hours?.[dow];
  return Array.isArray(h) ? h : null;
}

function isClosedDay(profile, dayStart, dow, rng) {
  if (!hoursOf(profile, dow)) return true;
  if (profile.holidays !== false && FIXED_HOLIDAYS.has(spMonthDay(dayStart + 12 * HOUR))) return true;
  return rng.fork('closed').chance(profile.closureProb ?? 0.01);
}

function queueArrivals(profile, ctx) {
  const { dayStart, dow, daysAgo, drng } = ctx;
  const [open, close] = hoursOf(profile, dow);
  const demand = profile.demand;
  const weights = [];
  let total = 0;
  for (let h = open; h < close; h += 1) {
    const w = profile.hourly?.[h] ?? 1;
    weights.push([h, w]);
    total += w;
  }
  const noise = Math.exp(drng.normal(0, demand.noise ?? 0.15));
  const dayTotal = demand.base * (demand.dow?.[dow] ?? 1) * interp(demand.trend, daysAgo, 1) * noise;
  const out = [];
  for (const [h, w] of weights) {
    const n = drng.poisson((dayTotal * w) / total);
    for (let i = 0; i < n; i += 1) out.push({ joinedAt: dayStart + (h + drng.next()) * HOUR });
  }
  if (profile.bursts) {
    const count = drng.int(profile.bursts.perDay[0], profile.bursts.perDay[1]);
    for (let b = 0; b < count; b += 1) {
      const center = dayStart + (open + drng.next() * (close - open)) * HOUR;
      const size = drng.int(profile.bursts.size[0], profile.bursts.size[1]);
      for (let i = 0; i < size; i += 1) {
        const t = center + Math.abs(drng.normal(0, profile.bursts.spreadMin)) * MINUTE;
        out.push({ joinedAt: Math.min(t, dayStart + close * HOUR - MINUTE) });
      }
    }
  }
  return out;
}

function slotMinutes(start) {
  const [h, m] = start.split(':').map(Number);
  return h * 60 + m;
}

function scheduleArrivals(profile, ctx) {
  const { dayStart, dow, daysAgo, drng } = ctx;
  const [open, close] = hoursOf(profile, dow);
  const fill = profile.fill;
  const out = [];
  for (const slot of profile.slots) {
    const minutes = slotMinutes(slot.start);
    if (minutes < open * 60 || minutes >= close * 60) continue;
    const slotStart = dayStart + minutes * MINUTE;
    const p = clamp(
      fill.base * (fill.dow?.[dow] ?? 1) * interp(fill.trend, daysAgo, 1) * (fill.hourly?.[Math.floor(minutes / 60)] ?? 1),
      0,
      1,
    );
    const bookings = drng.binomial(slot.capacity, p);
    for (let i = 0; i < bookings; i += 1) {
      const lead = clamp(drng.lognormal(profile.lead?.median ?? 22, profile.lead?.sigma ?? 0.6), -10, 150);
      const joinedAt = Math.max(dayStart + open * HOUR - 30 * MINUTE, slotStart - lead * MINUTE);
      out.push({ joinedAt, slotId: slot.id, slotStart });
    }
  }
  return out;
}

function noShowProb(profile, daysAgo, dow, early) {
  const ns = profile.noShow;
  if (!ns) return 0;
  const v = (ns.base ?? 0) + (ns.dow?.[dow] ?? 0) + interp(ns.trend, daysAgo, 0) + (early ? ns.early ?? 0 : 0);
  return clamp(v, 0, 0.6);
}

function buildServers(profile, dayStart, dow) {
  const [open, close] = hoursOf(profile, dow);
  const servers = [];
  for (const s of profile.staff) {
    if (s.days && !s.days.includes(dow)) continue;
    const shifts = s.shifts && s.shifts.length > 0 ? s.shifts : [[open, close]];
    const windows = [];
    for (const [from, to] of shifts) {
      const a = Math.max(from, open);
      const b = Math.min(to, close);
      if (b <= a) continue;
      windows.push([dayStart + a * HOUR, dayStart + b * HOUR + (b >= close ? OVERTIME_MS : 0)]);
    }
    if (windows.length > 0) servers.push({ uid: s.uid, factor: s.factor ?? 1, windows, freeAt: 0 });
  }
  return servers;
}

function startFor(server, t) {
  const candidate = Math.max(t, server.freeAt);
  for (const [a, b] of server.windows) {
    const s = Math.max(candidate, a);
    if (s < b) return s;
  }
  return Infinity;
}

function pickRating(profile, waitMin, rng) {
  const r = profile.rating;
  const x = r.mean + rng.normal(0, r.sd ?? 0.85) - (r.waitSens ?? 0.25) * ((waitMin - (r.refWait ?? 10)) / 10);
  return clamp(Math.round(x), 1, 5);
}

function pickComment(rating, rng) {
  const pool = rating <= 2 ? COMMENTS.low : rating === 3 ? COMMENTS.mid : COMMENTS.high;
  return rng.pick(pool);
}

function compactDay(key) {
  return key.replaceAll('-', '');
}

function simulateQueue(profile, ctx) {
  const { now, days, queueId, createdAt } = ctx;
  const rng = createRng(`${ctx.seed}:${queueId}`);
  const customers = makeCustomers(rng, profile);
  const todayStart = spStartOfDay(now);
  const status = profile.status ?? 'open';
  const hasLive = Boolean(profile.live);
  let cutoff = now;
  if (hasLive) cutoff = now - LIVE_WINDOW_MS;
  else if (status !== 'open') cutoff = now - CLOSED_CUTOFF_MS;

  const history = [];
  const feedback = [];
  const live = [];
  let ticket = 0;
  let serving = 0;
  let lastActivity = null;
  const first = spStartOfDay(Math.max(createdAt, now - days * DAY));

  for (let dayStart = first; dayStart <= todayStart; dayStart += DAY) {
    const dayKey = spDayKey(dayStart + 12 * HOUR);
    const dow = spDow(dayStart);
    const daysAgo = Math.round((todayStart - dayStart) / DAY);
    const drng = rng.fork(`day:${dayKey}`);
    if (profile.resetTicketDaily) {
      ticket = 0;
      serving = 0;
    }
    if (isClosedDay(profile, dayStart, dow, drng)) continue;
    if (profile.activeDay && !profile.activeDay({ daysAgo, dow })) continue;

    const [open, close] = hoursOf(profile, dow);
    const openMs = dayStart + open * HOUR;
    const closeMs = dayStart + close * HOUR;
    const closeLimit = closeMs + OVERTIME_MS;

    const raw = profile.mode === 'schedule'
      ? scheduleArrivals(profile, { dayStart, dow, daysAgo, drng })
      : queueArrivals(profile, { dayStart, dow, daysAgo, drng });
    const arrivals = raw
      .filter((a) => a.joinedAt >= createdAt && a.joinedAt <= cutoff)
      .map((a) => ({ ...a, joinedAt: Math.floor(a.joinedAt) }))
      .sort((a, b) => a.joinedAt - b.joinedAt);
    if (arrivals.length === 0) continue;

    const serviceTrend = interp(profile.service.trend, daysAgo, 1);
    const day = arrivals.map((a) => {
      ticket += 1;
      const person = customers.pick(drng);
      const patience = drng.lognormal(profile.patience.median, profile.patience.sigma ?? 0.6) * MINUTE;
      return {
        ...a,
        ticket,
        name: person.name,
        phone: person.phone,
        patience,
        order: a.slotStart ?? a.joinedAt,
        manual: drng.chance(profile.manualShare ?? 0),
        early: a.joinedAt < openMs + 90 * MINUTE,
      };
    });

    const servers = buildServers(profile, dayStart, dow);
    const processing = [...day].sort((a, b) => a.order - b.order || a.joinedAt - b.joinedAt || a.ticket - b.ticket);

    for (const c of processing) {
      const earliest = Math.max(c.joinedAt, c.slotStart ?? 0);
      let best = null;
      let bestStart = Infinity;
      for (const s of servers) {
        const st = startFor(s, earliest);
        if (st < bestStart) {
          bestStart = st;
          best = s;
        }
      }
      const patienceEnd = earliest + c.patience;
      const limit = Math.min(patienceEnd, closeLimit);
      if (!best || bestStart > limit) {
        c.result = 'left';
        c.leaveAt = Math.floor(Math.max(c.joinedAt + MINUTE, limit));
        if (closeLimit < patienceEnd && profile.expiry?.clearOnClose) c.reason = 'closed';
        c.doneAt = c.leaveAt;
        continue;
      }

      c.skips = 0;
      c.recalls = 0;
      let calledAt = bestStart;
      let delay = 0;
      if (drng.chance(profile.skipProb ?? 0)) {
        c.skips = 1;
        delay = drng.float(profile.skipDelay?.[0] ?? 6, profile.skipDelay?.[1] ?? 20) * MINUTE;
        calledAt += delay;
      }
      calledAt = Math.floor(calledAt);
      c.calledAt = calledAt;
      c.operatorId = best.uid;

      if (drng.chance(noShowProb(profile, daysAgo, dow, c.early))) {
        c.result = 'no_show';
        c.recalls = drng.int(1, 3);
        c.finishedAt = calledAt + Math.floor(drng.float(1.5, 5) * MINUTE);
        best.freeAt = Math.max(bestStart + MINUTE, c.finishedAt - delay);
      } else {
        c.result = 'served';
        if (drng.chance(profile.recallProb ?? 0)) c.recalls = 1;
        let svc = drng.lognormal(profile.service.median * best.factor * serviceTrend, profile.service.sigma);
        if (drng.chance(profile.service.outlierProb ?? 0)) {
          svc *= drng.float(profile.service.outlierMult?.[0] ?? 2.5, profile.service.outlierMult?.[1] ?? 5);
        }
        svc = clamp(svc, 0.6, profile.service.median * 14);
        c.finishedAt = calledAt + Math.floor(svc * MINUTE);
        best.freeAt = Math.max(bestStart + MINUTE, c.finishedAt - delay);
      }
      c.doneAt = c.finishedAt;
    }

    for (const c of day) {
      const waitingNow = c.doneAt > now;
      if (!waitingNow) {
        history.push(toHistory(c, queueId, dayKey, profile));
        if (c.result === 'served') {
          const fb = maybeFeedback(profile, c, queueId, dayKey, rng.fork(`fb:${queueId}:${dayKey}:${c.ticket}`), now);
          if (fb) feedback.push(fb);
        }
        if (c.calledAt) {
          if (lastActivity === null || c.calledAt >= lastActivity) {
            lastActivity = c.calledAt;
            serving = c.ticket;
          }
        }
      } else {
        live.push(toLive(c, queueId, dayKey, now, drng));
        if (c.calledAt && c.calledAt <= now) {
          if (lastActivity === null || c.calledAt >= lastActivity) {
            lastActivity = c.calledAt;
            serving = c.ticket;
          }
        }
      }
    }
  }

  const result = {
    history,
    feedback,
    live: live.filter((e) => e.status === 'waiting' || e.status === 'called'),
    lastTicket: ticket,
    serving,
    lastActivity,
  };

  if (status === 'closed') {
    for (const entry of result.live) {
      history.push({
        id: entry.id,
        ticket: entry.ticket,
        name: entry.name,
        phone: profile.anonymizePhone ? null : entry.phone,
        result: 'left',
        joinedAt: entry.joinedAt,
        calledAt: null,
        calledBy: null,
        operatorId: null,
        finishedAt: Math.min(now - MINUTE, Math.max(entry.joinedAt + MINUTE, cutoff + 15 * MINUTE)),
        ...(entry.slotId ? { slotId: entry.slotId } : {}),
      });
    }
    result.live = [];
  } else if (hasLive) {
    injectLive(profile, result, { now, queueId, rng: rng.fork('inject'), customers, cutoff });
  }

  result.history.sort((a, b) => a.finishedAt - b.finishedAt || a.ticket - b.ticket);
  return result;
}

function toHistory(c, queueId, dayKey, profile) {
  const doc = {
    id: `${compactDay(dayKey)}-${c.ticket}`,
    ticket: c.ticket,
    name: c.name,
    phone: profile.anonymizePhone ? null : c.phone,
    result: c.result,
    joinedAt: c.joinedAt,
    calledAt: c.result === 'left' ? null : c.calledAt,
    calledBy: c.result === 'left' ? null : c.operatorId,
    operatorId: c.result === 'left' ? null : c.operatorId,
    finishedAt: c.result === 'left' ? c.leaveAt : c.finishedAt,
  };
  if (c.recalls > 0) doc.recalls = c.recalls;
  if (c.skips > 0) doc.skips = c.skips;
  if (c.slotId) doc.slotId = c.slotId;
  if (c.reason) doc.reason = c.reason;
  return doc;
}

function maybeFeedback(profile, c, queueId, dayKey, rng, now) {
  const rate = profile.ratingRate ?? 0.45;
  if (!rng.chance(rate)) return null;
  const waitMin = (c.calledAt - c.joinedAt) / MINUTE;
  const rating = pickRating(profile, waitMin, rng);
  const comment = rng.chance(profile.commentRate ?? 0.3) ? pickComment(rating, rng) : '';
  return {
    id: `${compactDay(dayKey)}-${c.ticket}`,
    rating,
    comment,
    uid: `demo-cli-${rng.token(10, CLIENT_ALPHABET)}`,
    createdAt: Math.min(now - MINUTE, c.finishedAt + Math.floor(rng.float(1, 30) * MINUTE)),
  };
}

function toLive(c, queueId, dayKey, now, drng) {
  const entry = {
    id: `${compactDay(dayKey)}-${c.ticket}`,
    ticket: c.ticket,
    name: c.name,
    phone: c.phone,
    status: 'waiting',
    joinedAt: c.joinedAt,
  };
  if (c.manual) entry.manual = true;
  else entry.uid = `demo-cli-${drng.token(10, CLIENT_ALPHABET)}`;
  if (c.slotId) {
    entry.slotId = c.slotId;
    entry.slotStart = c.slotStart;
    entry.order = c.slotStart;
  }
  if (c.result !== 'left' && c.calledAt && c.calledAt <= now) {
    entry.status = 'called';
    entry.calledAt = c.calledAt;
    entry.operatorId = c.operatorId;
    if (c.skips > 0) {
      entry.skips = c.skips;
      entry.order = c.calledAt;
    }
    if (c.recalls > 0 && c.calledAt + 90 * 1000 <= now) {
      entry.recalls = c.recalls;
      entry.recalledAt = c.calledAt + 90 * 1000;
    }
  }
  return entry;
}

function injectLive(profile, result, { now, queueId, rng, customers, cutoff }) {
  const natural = result.live;
  const haveWaiting = natural.filter((e) => e.status === 'waiting').length;
  const haveCalled = natural.filter((e) => e.status === 'called').length;
  const needCalled = Math.max(0, (profile.live.called ?? 0) - haveCalled);
  const needWaiting = Math.max(0, (profile.live.waiting ?? 0) - haveWaiting);
  const total = needCalled + needWaiting;
  if (total === 0) return;

  const phones = new Set(natural.map((e) => e.phone).filter(Boolean));
  const dayKey = spDayKey(now);
  const todayStart = spStartOfDay(now);
  const span = now - 2 * MINUTE - cutoff;
  const slotPool = profile.mode === 'schedule' ? slotAllocator(profile, todayStart, now) : null;
  const staff = profile.staff;
  let ticket = result.lastTicket;

  for (let i = 0; i < total; i += 1) {
    ticket += 1;
    const isCalled = i < needCalled;
    const joinedAt = Math.floor(cutoff + ((i + rng.next() * 0.9) / total) * span);
    let person = customers.fresh(rng);
    while (person.phone && phones.has(person.phone)) person = customers.fresh(rng);
    if (person.phone) phones.add(person.phone);
    const entry = {
      id: `${compactDay(dayKey)}-${ticket}`,
      ticket,
      name: person.name,
      phone: person.phone,
      status: isCalled ? 'called' : 'waiting',
      joinedAt,
    };
    if (rng.chance(profile.manualShare ?? 0)) entry.manual = true;
    else entry.uid = `demo-cli-${rng.token(10, CLIENT_ALPHABET)}`;
    if (slotPool) {
      const slot = slotPool.next();
      entry.slotId = slot.id;
      entry.slotStart = slot.startMs;
      entry.order = slot.startMs;
    }
    if (isCalled) {
      const calledAt = Math.floor(Math.max(joinedAt + 30 * 1000, now - rng.float(0.5, 4) * MINUTE));
      entry.calledAt = calledAt;
      entry.operatorId = rng.pick(staff).uid;
      if (rng.chance(profile.recallProb ?? 0)) {
        entry.recalls = 1;
        entry.recalledAt = Math.min(now - 10 * 1000, calledAt + 60 * 1000);
      }
      if (calledAt >= (result.lastActivity ?? 0)) {
        result.lastActivity = calledAt;
        result.serving = ticket;
      }
    }
    natural.push(entry);
  }
  result.lastTicket = ticket;
  result.live = natural;
}

function slotAllocator(profile, todayStart, now) {
  const slots = [...profile.slots]
    .map((s) => ({ ...s, startMs: todayStart + slotMinutes(s.start) * MINUTE }))
    .sort((a, b) => a.startMs - b.startMs);
  let idx = 0;
  let best = Infinity;
  slots.forEach((s, i) => {
    const d = Math.abs(s.startMs - now);
    if (d < best) {
      best = d;
      idx = i;
    }
  });
  let used = 0;
  return {
    next() {
      if (used >= slots[idx].capacity && idx < slots.length - 1) {
        idx += 1;
        used = 0;
      }
      used += 1;
      return slots[idx];
    },
  };
}

module.exports = { simulateQueue, interp, OVERTIME_MS, LIVE_WINDOW_MS };
