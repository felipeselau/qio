'use strict';

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const SP_OFFSET = 3 * HOUR;
const MAX_WAIT_MS = 24 * HOUR;

const WAIT_EDGES = [5, 10, 20, 40];
const ESTIMATE_EDGES = [5, 10, 20, 40];
const ABANDON_MIN_SAMPLES = 5;
const INFLECTION_THRESHOLD = 0.2;
const WAIT_THRESHOLD_MIN = 15;
const IDLE_CAP_MIN = 30;
const MIN_RATE_SAMPLES = 3;
const MIN_WINDOW_MIN = 30;
const MIN_SERVICE_SAMPLES = 3;
const MIN_BAND_WIDTH_MIN = 5;
const GOAL_MIN_SAMPLES = 5;
const DEFAULT_TARGET_PCT = 80;
const TARGET_OCCUPANCY = 0.85;
const DEFICIT_LIMIT = 5;
const SEASON_WEEKS = 8;
const MIN_SEASON_WEEKS = 3;
const SEASON_TOP_CELLS = 5;
const RECURRENCE_PCT = 70;
const STABLE_TREND_PCT = 5;
const DEFAULT_AVG_SERVICE_MIN = 10;

const spHour = (ms) => new Date(ms - SP_OFFSET).getUTCHours();
const spDow = (ms) => new Date(ms - SP_OFFSET).getUTCDay();
const spDay = (ms) => Math.floor((ms - SP_OFFSET) / DAY);

const millis = (v) => (v && typeof v.toMillis === 'function' ? v.toMillis() : v);

function toRecords(history) {
  return history.map((h) => {
    const d = h.data ?? h;
    return {
      result: d.result,
      reason: d.reason,
      joinedAt: millis(d.joinedAt),
      calledAt: d.calledAt == null ? null : millis(d.calledAt),
      finishedAt: d.finishedAt == null ? null : millis(d.finishedAt),
      attendant: d.calledBy || d.operatorId || null,
      estimateMin: typeof d.estimateMin === 'number' ? d.estimateMin : null,
    };
  });
}

function inPeriod(records, now, days) {
  if (days == null) return records;
  const from = now - days * DAY;
  return records.filter((r) => (r.finishedAt ?? r.joinedAt) >= from);
}

const isSystemRemoved = (r) => r.result === 'left' && (r.reason === 'expired' || r.reason === 'closed');

function waitSamples(records) {
  const out = [];
  for (const r of records) {
    if (isSystemRemoved(r)) continue;
    if (!r.joinedAt) continue;
    let d;
    if (r.result === 'left') d = r.finishedAt == null ? null : r.finishedAt - r.joinedAt;
    else if (r.result === 'served' || r.result === 'no_show') d = r.calledAt == null ? null : r.calledAt - r.joinedAt;
    else continue;
    if (d == null || d < 0 || d > MAX_WAIT_MS) continue;
    out.push({ joinedAt: r.joinedAt, waitMin: d / MINUTE, left: r.result === 'left' });
  }
  return out;
}

function abandonmentByWait(records, edges = WAIT_EDGES, minSamples = ABANDON_MIN_SAMPLES) {
  const samples = waitSamples(records);
  const starts = [0, ...edges];
  return starts.map((start, i) => {
    const end = i + 1 < starts.length ? starts[i + 1] : null;
    let atRisk = 0;
    let left = 0;
    let maxWait = 0;
    for (const s of samples) {
      if (s.waitMin < start) continue;
      atRisk += 1;
      if (s.waitMin > maxWait) maxWait = s.waitMin;
      if (s.left && (end === null || s.waitMin < end)) left += 1;
    }
    const width = end === null ? maxWait - start : end - start;
    const rate = atRisk >= minSamples && atRisk > 0 ? left / atRisk : null;
    const hazard = rate !== null ? rate / Math.max(width, MIN_BAND_WIDTH_MIN) : null;
    return { startMin: start, endMin: end, atRisk, left, rate, hazardPerMin: hazard, ratePer10Min: hazard === null ? null : Math.min(1, hazard * 10) };
  });
}

function findInflection(bands, threshold = INFLECTION_THRESHOLD) {
  return bands.find((b) => b.ratePer10Min !== null && b.ratePer10Min > threshold) ?? null;
}

function abandonmentByHour(records, minSamples = ABANDON_MIN_SAMPLES) {
  const totals = new Array(24).fill(0);
  const lefts = new Array(24).fill(0);
  const waits = new Array(24).fill(0);
  for (const s of waitSamples(records)) {
    const h = spHour(s.joinedAt);
    totals[h] += 1;
    waits[h] += s.waitMin;
    if (s.left) lefts[h] += 1;
  }
  return totals.map((total, hour) => ({
    hour,
    total,
    left: lefts[hour],
    rate: total >= minSamples && total > 0 ? lefts[hour] / total : null,
    avgWaitMin: total > 0 ? waits[hour] / total : null,
  }));
}

function capacitySignalHours(hours, waitThresholdMin = WAIT_THRESHOLD_MIN, rateThreshold = INFLECTION_THRESHOLD) {
  return hours
    .filter((h) => h.rate !== null && h.avgWaitMin !== null && h.avgWaitMin >= waitThresholdMin && h.rate >= rateThreshold)
    .map((h) => h.hour);
}

function abandonmentByEstimate(records, edges = ESTIMATE_EDGES, minSamples = ABANDON_MIN_SAMPLES) {
  const starts = [0, ...edges];
  const totals = new Array(starts.length).fill(0);
  const lefts = new Array(starts.length).fill(0);
  for (const r of records) {
    const est = r.estimateMin;
    if (est === null || est < 0 || isSystemRemoved(r)) continue;
    if (!['served', 'no_show', 'left'].includes(r.result)) continue;
    let i = starts.length - 1;
    while (i > 0 && est < starts[i]) i -= 1;
    totals[i] += 1;
    if (r.result === 'left') lefts[i] += 1;
  }
  return starts.map((start, i) => ({
    startMin: start,
    endMin: i + 1 < starts.length ? starts[i + 1] : null,
    total: totals[i],
    left: lefts[i],
    rate: totals[i] >= minSamples && totals[i] > 0 ? lefts[i] / totals[i] : null,
  }));
}

function estimateAccuracy(records, minSamples = ABANDON_MIN_SAMPLES) {
  let n = 0;
  let sum = 0;
  let abs = 0;
  for (const r of records) {
    if (r.estimateMin === null || r.estimateMin < 0) continue;
    if (r.result !== 'served' && r.result !== 'no_show') continue;
    if (r.calledAt == null) continue;
    const w = r.calledAt - r.joinedAt;
    if (w < 0 || w > MAX_WAIT_MS) continue;
    const err = w / MINUTE - r.estimateMin;
    n += 1;
    sum += err;
    abs += Math.abs(err);
  }
  return { samples: n, meanErrorMin: n >= minSamples && n > 0 ? sum / n : null, meanAbsErrorMin: n >= minSamples && n > 0 ? abs / n : null };
}

function buildAbandonmentReport(records) {
  const waitBands = abandonmentByWait(records);
  const hours = abandonmentByHour(records);
  return {
    samples: waitSamples(records).length,
    waitBands,
    inflection: findInflection(waitBands),
    estimateBands: abandonmentByEstimate(records),
    accuracy: estimateAccuracy(records),
    hours,
    capacityHours: capacitySignalHours(hours),
  };
}

function groupHandled(records, ownerUids) {
  const groups = new Map();
  for (const r of records) {
    if (r.result !== 'served' && r.result !== 'no_show') continue;
    const key = r.attendant === null || ownerUids.has(r.attendant) ? null : r.attendant;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(r);
  }
  return groups;
}

function byCallDay(list) {
  const days = new Map();
  for (const r of list) {
    if (r.calledAt == null || r.finishedAt == null || r.finishedAt < r.calledAt) continue;
    const k = spDay(r.calledAt);
    if (!days.has(k)) days.set(k, []);
    days.get(k).push(r);
  }
  for (const l of days.values()) l.sort((a, b) => a.calledAt - b.calledAt || a.finishedAt - b.finishedAt);
  return days;
}

const lastFinish = (l) => Math.max(...l.map((r) => r.finishedAt));

function attendantRows(records, ownerUids = new Set()) {
  const groups = groupHandled(records, ownerUids);
  const rows = [];
  for (const [id, list] of groups) {
    const served = list.filter((r) => r.result === 'served');
    const durations = served.filter((r) => r.calledAt != null && r.finishedAt != null && r.finishedAt >= r.calledAt).map((r) => (r.finishedAt - r.calledAt) / MINUTE);
    const avg = durations.length >= MIN_SERVICE_SAMPLES ? durations.reduce((a, b) => a + b, 0) / durations.length : null;
    const volume = list.length;

    let rateServed = 0;
    let rateHours = 0;
    let idleMs = 0;
    let observedMs = 0;
    let gaps = 0;
    const byHour = new Array(24).fill(0);
    for (const r of served) byHour[spHour(r.finishedAt ?? r.calledAt)] += 1;
    for (const dayList of byCallDay(list).values()) {
      const span = lastFinish(dayList) - dayList[0].calledAt;
      const dayServed = dayList.filter((r) => r.result === 'served').length;
      if (dayServed >= MIN_RATE_SAMPLES && span >= MIN_WINDOW_MIN * MINUTE) {
        rateServed += dayServed;
        rateHours += span / HOUR;
      }
      observedMs += span;
      let maxFinish = dayList[0].finishedAt;
      for (let i = 1; i < dayList.length; i += 1) {
        const next = dayList[i];
        const gap = next.calledAt - maxFinish;
        if (gap > 0 && gap <= IDLE_CAP_MIN * MINUTE && spDay(maxFinish) === spDay(next.calledAt) && next.joinedAt <= maxFinish) {
          idleMs += gap;
          gaps += 1;
        }
        if (next.finishedAt > maxFinish) maxFinish = next.finishedAt;
      }
    }
    rows.push({
      attendantId: id,
      served: served.length,
      noShow: list.length - served.length,
      volume,
      serviceSamples: durations.length,
      avgServiceMin: avg,
      perHour: rateHours > 0 ? rateServed / rateHours : null,
      idlePct: volume >= MIN_RATE_SAMPLES && observedMs > 0 ? idleMs / observedMs : null,
      idleMin: idleMs / MINUTE,
      gaps,
      byHour,
    });
  }
  const qualified = rows.filter((r) => r.avgServiceMin !== null && r.serviceSamples >= MIN_SERVICE_SAMPLES);
  const samples = qualified.reduce((n, r) => n + r.serviceSamples, 0);
  const scopeAvg = samples > 0 ? qualified.reduce((s, r) => s + r.avgServiceMin * r.serviceSamples, 0) / samples : null;
  const order = [...qualified].sort((a, b) => a.avgServiceMin - b.avgServiceMin || b.volume - a.volume || String(a.attendantId).localeCompare(String(b.attendantId)));
  for (const r of rows) {
    const q = qualified.includes(r) && scopeAvg > 0;
    r.deviationPct = q ? ((r.avgServiceMin - scopeAvg) / scopeAvg) * 100 : null;
    r.rank = q ? order.indexOf(r) + 1 : null;
  }
  rows.sort((a, b) => b.volume - a.volume || String(a.attendantId).localeCompare(String(b.attendantId)));
  return { rows, scopeAvgMin: scopeAvg };
}

const dayWeekday = (day) => (new Date(day * DAY).getUTCDay() + 6) % 7;
const spWeekday = (ms) => (spDow(ms) + 6) % 7;
const hourIndex = (ms) => Math.floor((ms - SP_OFFSET) / HOUR);

function goalsOf(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const read = (v, lo, hi) => (typeof v === 'number' && Number.isInteger(v) && v >= lo && v <= hi ? v : null);
  return {
    maxWaitMin: read(raw.maxWaitMin, 1, 240),
    maxServiceMin: read(raw.maxServiceMin, 1, 240),
    targetPct: read(raw.targetPct, 50, 100),
  };
}

const hasGoal = (g) => g !== null && (g.maxWaitMin !== null || g.maxServiceMin !== null);
const effectiveTargetPct = (g) => g.targetPct ?? DEFAULT_TARGET_PCT;

function goalWaitSamples(records, goals) {
  const limit = goals.maxWaitMin;
  if (limit === null) return [];
  const target = effectiveTargetPct(goals);
  const out = [];
  for (const r of records) {
    if (!r.joinedAt) continue;
    let d;
    if (r.result === 'served' || r.result === 'no_show') d = r.calledAt == null ? null : r.calledAt - r.joinedAt;
    else if (r.result === 'left' && !isSystemRemoved(r)) d = r.finishedAt == null ? null : r.finishedAt - r.joinedAt;
    else continue;
    if (d == null || d < 0 || d > MAX_WAIT_MS) continue;
    const min = d / MINUTE;
    if (r.result === 'left' && min <= limit) continue;
    out.push({ at: r.joinedAt, value: min, limit, target });
  }
  return out;
}

function goalServiceSamples(records, goals) {
  const limit = goals.maxServiceMin;
  if (limit === null) return [];
  const target = effectiveTargetPct(goals);
  const out = [];
  for (const r of records) {
    if (r.result !== 'served') continue;
    if (r.calledAt == null || r.finishedAt == null) continue;
    const d = r.finishedAt - r.calledAt;
    if (d < 0) continue;
    out.push({ at: r.calledAt, value: d / MINUTE, limit, target });
  }
  return out;
}

function bucketOf(acc) {
  const { total, ok, targetSum } = acc;
  return {
    total,
    ok,
    targetSum,
    violations: total - ok,
    pct: total === 0 ? null : ok / total,
    pctFloor: total === 0 ? null : Math.floor((ok * 100) / total),
    targetPct: total === 0 ? null : targetSum / total,
    met: total > 0 && ok * 100 >= targetSum,
  };
}

function accAdd(map, key, compliant, target) {
  if (!map.has(key)) map.set(key, { total: 0, ok: 0, targetSum: 0 });
  const a = map.get(key);
  a.total += 1;
  if (compliant) a.ok += 1;
  a.targetSum += target;
}

function goalIndicator(perQueue, configured, minSamples) {
  const overall = new Map();
  const days = new Map();
  const hours = new Map();
  let worst = null;
  let worstDay = null;
  let queues = 0;
  for (const samples of perQueue) {
    if (samples.length === 0) continue;
    queues += 1;
    for (const s of samples) {
      const ok = s.value <= s.limit;
      accAdd(overall, 'all', ok, s.target);
      accAdd(days, spDay(s.at), ok, s.target);
      accAdd(hours, spHour(s.at), ok, s.target);
      const over = s.value - s.limit;
      if (over > 0 && (worst === null || over > worst)) {
        worst = over;
        worstDay = spDay(s.at);
      }
    }
  }
  const dayList = [...days.keys()].sort((a, b) => a - b).map((k) => ({ day: k, weekday: dayWeekday(k), bucket: bucketOf(days.get(k)) }));
  const hourList = [...hours.keys()].sort((a, b) => a - b).map((k) => ({ hour: k, bucket: bucketOf(hours.get(k)) }));
  return {
    overall: bucketOf(overall.get('all') ?? { total: 0, ok: 0, targetSum: 0 }),
    days: dayList,
    hours: hourList,
    missedDays: dayList.filter((d) => d.bucket.total >= minSamples && !d.bucket.met),
    missedHours: hourList.filter((h) => h.bucket.total >= minSamples && !h.bucket.met),
    queues,
    configured,
    worstOverMin: worst,
    worstDay,
  };
}

function computeGoalReport(inputs, minSamples = GOAL_MIN_SAMPLES) {
  const withGoals = inputs.filter((i) => hasGoal(i.goals));
  if (withGoals.length === 0) return { wait: null, service: null, queuesWithGoals: 0 };
  return {
    wait: goalIndicator(
      withGoals.map((q) => goalWaitSamples(q.records, q.goals)),
      withGoals.filter((q) => q.goals.maxWaitMin !== null).length,
      minSamples,
    ),
    service: goalIndicator(
      withGoals.map((q) => goalServiceSamples(q.records, q.goals)),
      withGoals.filter((q) => q.goals.maxServiceMin !== null).length,
      minSamples,
    ),
    queuesWithGoals: withGoals.length,
  };
}

function effectiveAvgServiceMin(auto, manual) {
  const valid = (n) => typeof n === 'number' && Number.isFinite(n) && n > 0;
  if (valid(auto)) return auto;
  if (valid(manual)) return manual;
  return DEFAULT_AVG_SERVICE_MIN;
}

function estimatedWaitMin(waiting, auto, manual) {
  if (waiting <= 0) return 0;
  return Math.round(waiting * effectiveAvgServiceMin(auto, manual));
}

function waitGoalAtRisk(estimatedMin, goals) {
  const max = goals ? goals.maxWaitMin : null;
  return max !== null && max !== undefined && estimatedMin > max;
}

function emptyGrid() {
  return Array.from({ length: 7 }, () => new Array(24).fill(0));
}

function computeStaffingGrid(records, ownerUids = new Set(), occupancy = TARGET_OCCUPANCY, minServiceSamples = MIN_SERVICE_SAMPLES, deficitLimit = DEFICIT_LIMIT) {
  const valid = records.filter((r) => r.joinedAt);
  if (valid.length === 0) return null;
  const arrivals = emptyGrid();
  let first = spDay(valid[0].joinedAt);
  let last = first;
  const cover = (ms) => {
    const day = spDay(ms);
    if (day < first) first = day;
    if (day > last) last = day;
  };
  let serviceSum = 0;
  let serviceSamples = 0;
  const slots = new Map();
  for (const r of valid) {
    arrivals[spWeekday(r.joinedAt)][spHour(r.joinedAt)] += 1;
    cover(r.joinedAt);
    if (r.calledAt == null || !(r.result === 'served' || r.result === 'no_show')) continue;
    cover(r.calledAt);
    const end = r.finishedAt != null && r.finishedAt > r.calledAt ? r.finishedAt : r.calledAt;
    let startIdx = hourIndex(r.calledAt);
    let endIdx = end > r.calledAt ? hourIndex(end - 1) : startIdx;
    if (endIdx < startIdx) endIdx = startIdx;
    if (endIdx > startIdx + 23) endIdx = startIdx + 23;
    const key = r.attendant === null || ownerUids.has(r.attendant) ? '' : r.attendant;
    for (; startIdx <= endIdx; startIdx += 1) {
      if (!slots.has(startIdx)) slots.set(startIdx, new Set());
      slots.get(startIdx).add(key);
    }
    if (r.result === 'served' && r.finishedAt != null) {
      const s = r.finishedAt - r.calledAt;
      if (s >= 0 && s <= MAX_WAIT_MS) {
        serviceSum += s / MINUTE;
        serviceSamples += 1;
      }
    }
  }
  const occurrences = new Array(7).fill(0);
  for (let day = first; day <= last; day += 1) occurrences[dayWeekday(day)] += 1;
  const observedSum = emptyGrid();
  for (const [idx, set] of slots) {
    const at = new Date(idx * HOUR);
    observedSum[(at.getUTCDay() + 6) % 7][at.getUTCHours()] += set.size;
  }
  const avg = serviceSamples >= minServiceSamples ? serviceSum / serviceSamples : null;
  const cells = [];
  const deficits = [];
  for (let d = 0; d < 7; d += 1) {
    const row = [];
    const occ = occurrences[d];
    for (let h = 0; h < 24; h += 1) {
      const perHour = occ === 0 ? 0 : arrivals[d][h] / occ;
      let needed = 0;
      if (avg !== null && perHour > 0) {
        needed = Math.ceil((perHour * avg) / 60 / occupancy - 1e-9);
        if (needed < 1) needed = 1;
      }
      const cell = { weekday: d, hour: h, arrivals: perHour, required: needed, observed: occ === 0 ? 0 : observedSum[d][h] / occ };
      cell.gap = cell.required - cell.observed;
      row.push(cell);
      if (cell.required > 0 && cell.gap > 0) deficits.push(cell);
    }
    cells.push(row);
  }
  deficits.sort((a, b) => b.gap - a.gap || b.required - a.required || a.weekday - b.weekday || a.hour - b.hour);
  return { cells, topDeficits: deficits.slice(0, deficitLimit), avgServiceMin: avg, serviceSamples, occupancy, coverageDays: last - first + 1 };
}

function computeSeasonality(records, now, weeks = SEASON_WEEKS, minWeeks = MIN_SEASON_WEEKS, topCells = SEASON_TOP_CELLS, recurrenceMinPct = RECURRENCE_PCT) {
  const currentMonday = spDay(now) - spWeekday(now);
  const windowStart = currentMonday - 7 * weeks;
  const volumes = new Array(weeks).fill(0);
  const cellCounts = Array.from({ length: weeks }, () => new Array(168).fill(0));
  for (const r of records) {
    if (!r.joinedAt) continue;
    const day = spDay(r.joinedAt);
    if (day < windowStart || day >= currentMonday) continue;
    const idx = Math.floor((day - windowStart) / 7);
    volumes[idx] += 1;
    cellCounts[idx][spWeekday(r.joinedAt) * 24 + spHour(r.joinedAt)] += 1;
  }
  const firstIdx = volumes.findIndex((v) => v > 0);
  if (firstIdx < 0) return { weeks: [], recurring: [], trendPct: null, direction: null, insufficient: true };
  const observed = [];
  for (let i = firstIdx; i < weeks; i += 1) observed.push({ weekStart: windowStart + 7 * i, volume: volumes[i] });
  if (observed.length < minWeeks) return { weeks: observed, recurring: [], trendPct: null, direction: null, insufficient: true };
  const n = observed.length;
  const mean = observed.reduce((s, w) => s + w.volume, 0) / n;
  const xMean = (n - 1) / 2;
  let cov = 0;
  let den = 0;
  for (let i = 0; i < n; i += 1) {
    cov += (i - xMean) * (observed[i].volume - mean);
    den += (i - xMean) * (i - xMean);
  }
  const trend = mean > 0 && den > 0 ? (cov / den / mean) * 100 : null;
  const direction = trend === null ? null : Math.abs(trend) < STABLE_TREND_PCT ? 'stable' : trend > 0 ? 'up' : 'down';
  const tally = new Array(168).fill(0);
  for (let i = firstIdx; i < weeks; i += 1) {
    const ranked = [];
    for (let c = 0; c < 168; c += 1) if (cellCounts[i][c] > 0) ranked.push(c);
    ranked.sort((a, b) => cellCounts[i][b] - cellCounts[i][a] || a - b);
    for (const c of ranked.slice(0, topCells)) tally[c] += 1;
  }
  const recurring = [];
  for (let c = 0; c < 168; c += 1) {
    if (tally[c] > 0 && tally[c] * 100 >= recurrenceMinPct * n) recurring.push({ weekday: Math.floor(c / 24), hour: c % 24, weeks: tally[c], observedWeeks: n });
  }
  recurring.sort((a, b) => b.weeks - a.weeks);
  return { weeks: observed, recurring, trendPct: trend, direction, insufficient: false };
}

const round = (v, d = 1) => (v === null || v === undefined ? null : Math.round(v * 10 ** d) / 10 ** d);

module.exports = {
  MINUTE,
  HOUR,
  DAY,
  spHour,
  spDow,
  spDay,
  toRecords,
  inPeriod,
  waitSamples,
  abandonmentByWait,
  findInflection,
  abandonmentByHour,
  capacitySignalHours,
  abandonmentByEstimate,
  estimateAccuracy,
  buildAbandonmentReport,
  attendantRows,
  goalsOf,
  hasGoal,
  computeGoalReport,
  effectiveAvgServiceMin,
  estimatedWaitMin,
  waitGoalAtRisk,
  computeStaffingGrid,
  computeSeasonality,
  spWeekday,
  dayWeekday,
  round,
};
