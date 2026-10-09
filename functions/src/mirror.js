const NAME_MAX = 60;
const FALLBACK_NAME = 'Fila';
const DESCRIPTION_MAX = 300;
const DEFAULT_AVG_SERVICE_MIN = 10;
const MAX_WAITING_MAX = 1000;
const STATUS_MESSAGE_MAX = 120;
const LOGO_URL_MAX = 600;
const MAX_MIRROR_SLOTS = 24;
const STATUSES = ['open', 'paused', 'closed'];
const HEX_RE = /^#[0-9A-Fa-f]{6}$/;
const LOGO_RE = /^https:\/\/firebasestorage\.googleapis\.com\//;
const SLOT_ID_RE = /^[A-Za-z0-9_-]{1,20}$/;
const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)$/;
const UID_RE = /^[A-Za-z0-9_-]{1,128}$/;

function normalizeName(raw) {
  const trimmed = typeof raw === 'string' ? raw.trim() : '';
  if (!trimmed) return FALLBACK_NAME;
  return trimmed.length > NAME_MAX ? trimmed.slice(0, NAME_MAX).trimEnd() : trimmed;
}

function normalizeDescription(raw) {
  const text = typeof raw === 'string' ? raw.trim() : '';
  if (!text) return null;
  return text.length > DESCRIPTION_MAX ? text.slice(0, DESCRIPTION_MAX) : text;
}

function normalizeAvgServiceMin(raw) {
  if (typeof raw === 'number' && Number.isInteger(raw) && raw >= 1 && raw <= 240) return raw;
  return DEFAULT_AVG_SERVICE_MIN;
}

function normalizeMaxWaiting(raw) {
  if (typeof raw === 'number' && Number.isInteger(raw) && raw >= 0 && raw <= MAX_WAITING_MAX) {
    return raw;
  }
  return 0;
}

function normalizeStatus(raw) {
  return STATUSES.includes(raw) ? raw : 'open';
}

function normalizeStatusMessage(raw) {
  const text = typeof raw === 'string' ? raw.trim() : '';
  if (!text) return null;
  return text.length > STATUS_MESSAGE_MAX ? text.slice(0, STATUS_MESSAGE_MAX) : text;
}

function toMillis(raw) {
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  if (raw && typeof raw.toMillis === 'function') {
    const ms = raw.toMillis();
    return Number.isFinite(ms) ? ms : null;
  }
  return null;
}

function normalizeBrandColor(raw) {
  return typeof raw === 'string' && HEX_RE.test(raw) ? raw : null;
}

function normalizeLogoUrl(raw) {
  return typeof raw === 'string' && raw.length <= LOGO_URL_MAX && LOGO_RE.test(raw) ? raw : null;
}

function normalizeMode(raw) {
  return raw === 'schedule' ? 'schedule' : 'queue';
}

function slotMinutes(start) {
  const m = typeof start === 'string' ? TIME_RE.exec(start) : null;
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

function expectedSlots(list) {
  if (!Array.isArray(list)) return null;
  const valid = [];
  const seen = new Set();
  for (const item of list) {
    if (!item || typeof item.id !== 'string' || !SLOT_ID_RE.test(item.id)) continue;
    if (seen.has(item.id)) continue;
    const minutes = slotMinutes(item.start);
    const cap = item.capacity;
    if (minutes === null) continue;
    if (typeof cap !== 'number' || !Number.isInteger(cap) || cap < 1 || cap > 50) continue;
    seen.add(item.id);
    valid.push({ id: item.id, start: item.start, capacity: cap, minutes });
  }
  valid.sort((a, b) => a.minutes - b.minutes);
  const map = {};
  for (const s of valid.slice(0, MAX_MIRROR_SLOTS)) {
    map[s.id] = { start: s.start, capacity: s.capacity };
  }
  return Object.keys(map).length === 0 ? null : map;
}

function currentSlots(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const map = {};
  for (const [id, value] of Object.entries(raw)) {
    if (value && typeof value === 'object') {
      map[id] = { start: value.start, capacity: value.capacity };
    }
  }
  return Object.keys(map).length === 0 ? null : map;
}

function sameSlots(a, b) {
  if (a === null || b === null) return a === b;
  const ak = Object.keys(a);
  if (ak.length !== Object.keys(b).length) return false;
  return ak.every(
    (id) => b[id] && b[id].start === a[id].start && b[id].capacity === a[id].capacity,
  );
}

function expectedMeta(queueDoc) {
  return {
    name: normalizeName(queueDoc.name),
    description: normalizeDescription(queueDoc.description),
    avgServiceMin: normalizeAvgServiceMin(queueDoc.avgServiceMin),
    maxWaiting: normalizeMaxWaiting(queueDoc.maxWaiting),
    status: normalizeStatus(queueDoc.status),
    statusMessage: normalizeStatusMessage(queueDoc.statusMessage),
    resumeAt: toMillis(queueDoc.resumeAt),
    brandColor: normalizeBrandColor(queueDoc.brandColor),
    logoUrl: normalizeLogoUrl(queueDoc.logoUrl),
    mode: normalizeMode(queueDoc.mode),
    slots: expectedSlots(queueDoc.slots),
  };
}

function isMirrorable(queueDoc) {
  return !!queueDoc && typeof queueDoc === 'object' && !queueDoc.deleting;
}

function buildMetaPatch(queueDoc, currentMeta) {
  if (!isMirrorable(queueDoc)) return {};
  const want = expectedMeta(queueDoc);

  if (currentMeta === null || currentMeta === undefined) {
    const patch = { nextTicket: 0, serving: 0 };
    for (const key of ['name', 'avgServiceMin', 'maxWaiting', 'status']) patch[key] = want[key];
    for (const key of ['description', 'statusMessage', 'resumeAt', 'brandColor', 'logoUrl']) {
      if (want[key] !== null) patch[key] = want[key];
    }
    if (want.mode === 'schedule' || want.slots) {
      patch.mode = want.mode;
      if (want.slots) patch.slots = want.slots;
    }
    return patch;
  }

  if (currentMeta.deleting === true) return {};

  const patch = {};
  for (const key of ['name', 'avgServiceMin', 'status']) {
    if (currentMeta[key] !== want[key]) patch[key] = want[key];
  }

  const nullable = (v) => (v === undefined || v === '' ? null : v);
  for (const key of ['description', 'statusMessage', 'resumeAt', 'brandColor', 'logoUrl']) {
    if (nullable(currentMeta[key]) !== want[key]) patch[key] = want[key];
  }

  const haveMax = typeof currentMeta.maxWaiting === 'number' ? currentMeta.maxWaiting : 0;
  if (haveMax !== want.maxWaiting) patch.maxWaiting = want.maxWaiting;

  const haveMode = normalizeMode(currentMeta.mode);
  if (haveMode !== want.mode || !sameSlots(currentSlots(currentMeta.slots), want.slots)) {
    patch.mode = want.mode;
    patch.slots = want.slots;
  }
  return patch;
}

function buildOwnerPatch(queueDoc, currentOwner) {
  if (!isMirrorable(queueDoc)) return null;
  const ownerUid = queueDoc.ownerId;
  if (typeof ownerUid !== 'string' || !ownerUid) return null;
  if (currentOwner && currentOwner.ownerUid === ownerUid) return null;
  return { ownerUid };
}

function operatorMirrorAction(before, after, uid) {
  if (typeof uid !== 'string' || !UID_RE.test(uid)) return 'none';
  if (after) return 'add';
  if (before) return 'remove';
  return 'none';
}

module.exports = {
  buildMetaPatch,
  buildOwnerPatch,
  operatorMirrorAction,
  normalizeName,
  normalizeDescription,
  normalizeAvgServiceMin,
  expectedSlots,
};
