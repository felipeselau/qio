const DEFAULT_TIMEZONE = 'America/Sao_Paulo';
const MINUTE = 60 * 1000;
const WEEKDAYS = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };

const formatters = new Map();

function formatterFor(timeZone) {
  if (!formatters.has(timeZone)) {
    formatters.set(
      timeZone,
      new Intl.DateTimeFormat('en-US', {
        timeZone,
        weekday: 'short',
        hour: '2-digit',
        minute: '2-digit',
        hourCycle: 'h23',
      }),
    );
  }
  return formatters.get(timeZone);
}

function localParts(ms, timeZone) {
  const parts = formatterFor(timeZone).formatToParts(new Date(ms));
  const pick = (type) => parts.find((p) => p.type === type)?.value;
  return {
    weekday: WEEKDAYS[pick('weekday')],
    minutes: Number(pick('hour')) * 60 + Number(pick('minute')),
  };
}

function parseTime(value) {
  const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(typeof value === 'string' ? value : '');
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

function normalizeSchedule(raw) {
  if (!raw || raw.enabled !== true || !Array.isArray(raw.windows)) return null;
  let timezone = typeof raw.timezone === 'string' ? raw.timezone : DEFAULT_TIMEZONE;
  try {
    formatterFor(timezone);
  } catch {
    timezone = DEFAULT_TIMEZONE;
  }
  const windows = [];
  for (const w of raw.windows) {
    const open = parseTime(w?.open);
    const close = parseTime(w?.close);
    const days = Array.isArray(w?.days)
      ? [...new Set(w.days.filter((d) => Number.isInteger(d) && d >= 1 && d <= 7))]
      : [];
    if (open === null || close === null || open === close || days.length === 0) continue;
    windows.push({ days, open, close });
  }
  return windows.length === 0 ? null : { timezone, windows };
}

function isWithinSchedule(schedule, ms) {
  const s = normalizeSchedule(schedule);
  if (!s) return null;
  const { weekday, minutes } = localParts(ms, s.timezone);
  const yesterday = weekday === 1 ? 7 : weekday - 1;
  return s.windows.some((w) => {
    if (w.open < w.close) {
      return w.days.includes(weekday) && minutes >= w.open && minutes < w.close;
    }
    return (
      (w.days.includes(weekday) && minutes >= w.open) ||
      (w.days.includes(yesterday) && minutes < w.close)
    );
  });
}

function nextOpening(schedule, ms, horizonDays = 8) {
  const s = normalizeSchedule(schedule);
  if (!s) return null;
  if (isWithinSchedule(schedule, ms)) return ms;
  const start = Math.floor(ms / MINUTE) * MINUTE + MINUTE;
  const end = start + horizonDays * 24 * 60 * MINUTE;
  for (let t = start; t <= end; t += MINUTE) {
    if (isWithinSchedule(schedule, t)) return t;
  }
  return null;
}

function planScheduleChange({ schedule, lastDesired, status, currentOpensAt }, now) {
  const desired = isWithinSchedule(schedule, now);
  if (desired === null) return null;
  if (lastDesired !== desired) {
    return desired
      ? { status: 'open', opensAt: null, desired }
      : { status: 'closed', opensAt: nextOpening(schedule, now), desired };
  }
  if (!desired && status === 'closed') {
    const next = nextOpening(schedule, now);
    if (next !== null && next !== (currentOpensAt ?? null)) {
      return { status: null, opensAt: next, desired };
    }
  }
  return null;
}

module.exports = {
  planScheduleChange,
  DEFAULT_TIMEZONE,
  parseTime,
  normalizeSchedule,
  isWithinSchedule,
  nextOpening,
};
