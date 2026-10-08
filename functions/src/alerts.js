const { CHANNEL_ID, normalizeLang } = require('./push');

const MINUTE = 60 * 1000;
const DEFAULT_COOLDOWN_MIN = 30;
const DEFAULT_SERVICE_MIN = 10;
const MIN_NO_SHOW_SAMPLES = 5;
const SP_OFFSET_MS = -3 * 60 * MINUTE;
const DAY_MS = 86400000;
const RULES = ['wait', 'noShow', 'idle'];
const STATE_KEYS = { wait: 'waitAt', noShow: 'noShowAt', idle: 'idleAt' };

function limitIn(value, min, max) {
  return typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max
    ? value
    : null;
}

function normalizeAlerts(raw) {
  if (!raw || raw.enabled !== true) return null;
  const config = {
    maxWaitMin: limitIn(raw.maxWaitMin, 1, 240),
    maxNoShowPct: limitIn(raw.maxNoShowPct, 1, 100),
    idleMin: limitIn(raw.idleMin, 5, 240),
    cooldownMin: limitIn(raw.cooldownMin, 5, 1440) ?? DEFAULT_COOLDOWN_MIN,
  };
  if (config.maxWaitMin === null && config.maxNoShowPct === null && config.idleMin === null) {
    return null;
  }
  return config;
}

function startOfDaySaoPaulo(now) {
  const local = now + SP_OFFSET_MS;
  const day = local - (((local % DAY_MS) + DAY_MS) % DAY_MS);
  return day - SP_OFFSET_MS;
}

function finite(list) {
  return (Array.isArray(list) ? list : []).filter(
    (v) => typeof v === 'number' && Number.isFinite(v),
  );
}

function lastActivityOf({ updatedAt, waitingOrders }) {
  const orders = finite(waitingOrders);
  const signals = [];
  if (typeof updatedAt === 'number' && Number.isFinite(updatedAt)) signals.push(updatedAt);
  if (orders.length > 0) signals.push(Math.min(...orders));
  return signals.length > 0 ? Math.max(...signals) : null;
}

async function mapLimit(items, limit, fn) {
  const queue = [...items];
  const size = Math.max(1, Math.min(limit, queue.length));
  const workers = Array.from({ length: size }, async () => {
    while (queue.length > 0) await fn(queue.shift());
  });
  await Promise.all(workers);
}

function cooledDown(state, rule, now, cooldownMin) {
  const last = state?.[STATE_KEYS[rule]];
  if (typeof last !== 'number') return true;
  return now - last >= cooldownMin * MINUTE;
}

function evaluateAlerts({
  config,
  state,
  now,
  status,
  waiting,
  avgServiceMin,
  noShowToday,
  servedToday,
  lastActivityAt,
}) {
  const cfg = normalizeAlerts(config);
  if (!cfg || status !== 'open') return [];
  const fired = [];

  if (cfg.maxWaitMin !== null && waiting > 0) {
    const perPerson =
      typeof avgServiceMin === 'number' && avgServiceMin > 0 ? avgServiceMin : DEFAULT_SERVICE_MIN;
    const estimate = waiting * perPerson;
    if (estimate > cfg.maxWaitMin && cooledDown(state, 'wait', now, cfg.cooldownMin)) {
      fired.push({ rule: 'wait', value: Math.round(estimate), limit: cfg.maxWaitMin });
    }
  }

  if (cfg.maxNoShowPct !== null) {
    const noShow = noShowToday ?? 0;
    const total = noShow + (servedToday ?? 0);
    if (total >= MIN_NO_SHOW_SAMPLES) {
      const pct = (noShow / total) * 100;
      if (pct >= cfg.maxNoShowPct && cooledDown(state, 'noShow', now, cfg.cooldownMin)) {
        fired.push({ rule: 'noShow', value: Math.round(pct), limit: cfg.maxNoShowPct });
      }
    }
  }

  if (cfg.idleMin !== null && waiting > 0 && typeof lastActivityAt === 'number') {
    const idleFor = (now - lastActivityAt) / MINUTE;
    if (idleFor > cfg.idleMin && cooledDown(state, 'idle', now, cfg.cooldownMin)) {
      fired.push({ rule: 'idle', value: Math.floor(idleFor), limit: cfg.idleMin });
    }
  }

  return fired;
}

function stateAfter(state, fired, now) {
  const next = { ...(state ?? {}) };
  for (const { rule } of fired) next[STATE_KEYS[rule]] = now;
  return next;
}

const MESSAGES = {
  pt: {
    wait: (v) => `Espera estimada de ${v.value} min (limite ${v.limit} min).`,
    noShow: (v) => `${v.value}% de não comparecimento hoje (limite ${v.limit}%).`,
    idle: (v) => `Fila parada há ${v.value} min com gente esperando (limite ${v.limit} min).`,
  },
  en: {
    wait: (v) => `Estimated wait is ${v.value} min (limit ${v.limit} min).`,
    noShow: (v) => `${v.value}% no-shows today (limit ${v.limit}%).`,
    idle: (v) => `No calls for ${v.value} min with people waiting (limit ${v.limit} min).`,
  },
  es: {
    wait: (v) => `Espera estimada de ${v.value} min (límite ${v.limit} min).`,
    noShow: (v) => `${v.value}% de ausencias hoy (límite ${v.limit}%).`,
    idle: (v) => `Fila detenida hace ${v.value} min con gente esperando (límite ${v.limit} min).`,
  },
};

function buildAlertMessage(rule, vars, lang) {
  const base = typeof lang === 'string' ? lang.toLowerCase().split(/[-_]/)[0] : '';
  const l = MESSAGES[base] ? base : 'pt';
  const fn = MESSAGES[l][rule];
  return fn ? fn(vars) : '';
}

function buildAlertPush({ queueId, queueName, rule, vars, lang }) {
  return {
    notification: {
      title: typeof queueName === 'string' && queueName ? queueName : 'Qio',
      body: buildAlertMessage(rule, vars, normalizeLang(lang)),
    },
    data: { type: 'queue-alert', queueId, rule },
    android: {
      priority: 'high',
      collapseKey: `${queueId}-${rule}`,
      notification: { channelId: CHANNEL_ID, tag: `${queueId}-${rule}` },
    },
  };
}

function wantsAlertPush(ownerDoc) {
  return ownerDoc?.notifyAlerts !== false;
}

module.exports = {
  RULES,
  STATE_KEYS,
  MIN_NO_SHOW_SAMPLES,
  DEFAULT_COOLDOWN_MIN,
  normalizeAlerts,
  startOfDaySaoPaulo,
  lastActivityOf,
  mapLimit,
  evaluateAlerts,
  stateAfter,
  buildAlertMessage,
  buildAlertPush,
  wantsAlertPush,
};
