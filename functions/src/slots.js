const { startOfDaySaoPaulo } = require('./alerts');

const MAX_SLOTS = 24;
const MAX_SLOT_CAPACITY = 50;
const SLOT_GRACE_MS = 15 * 60 * 1000;
const MINUTE_MS = 60 * 1000;
const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)$/;

function normalizeMode(value) {
  return value === 'schedule' ? 'schedule' : 'queue';
}

function minutesOf(start) {
  const m = typeof start === 'string' ? TIME_RE.exec(start) : null;
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

function normalizeCapacity(value) {
  if (typeof value !== 'number' || !Number.isInteger(value)) return null;
  if (value < 1 || value > MAX_SLOT_CAPACITY) return null;
  return value;
}

function parseSlots(raw) {
  if (!raw || typeof raw !== 'object') return [];
  const slots = [];
  for (const [id, value] of Object.entries(raw)) {
    const minutes = minutesOf(value?.start);
    const capacity = normalizeCapacity(value?.capacity);
    if (minutes === null || capacity === null) continue;
    slots.push({ id, start: value.start, capacity });
  }
  return slots
    .sort((a, b) => minutesOf(a.start) - minutesOf(b.start))
    .slice(0, MAX_SLOTS);
}

function slotStartMs(now, start) {
  const minutes = minutesOf(start);
  if (minutes === null) return null;
  return startOfDaySaoPaulo(now) + minutes * MINUTE_MS;
}

function isSlotBookable(now, slotStart) {
  if (typeof slotStart !== 'number') return false;
  return now <= slotStart + SLOT_GRACE_MS;
}

function countSlotEntries(entries, slotId) {
  let count = 0;
  for (const entry of Object.values(entries ?? {})) {
    if (!entry) continue;
    if (entry.status !== 'waiting' && entry.status !== 'called') continue;
    if (entry.slotId === slotId) count += 1;
  }
  return count;
}

function slotsFromDoc(list) {
  if (!Array.isArray(list)) return null;
  const map = {};
  for (const item of list) {
    if (item && typeof item.id === 'string' && item.id) {
      map[item.id] = { start: item.start, capacity: item.capacity };
    }
  }
  return map;
}

function isSlotFull(capacity, count) {
  const limit = normalizeCapacity(capacity);
  if (limit === null) return true;
  return count >= limit;
}

module.exports = {
  MAX_SLOTS,
  MAX_SLOT_CAPACITY,
  SLOT_GRACE_MS,
  normalizeMode,
  normalizeCapacity,
  parseSlots,
  slotStartMs,
  isSlotBookable,
  countSlotEntries,
  slotsFromDoc,
  isSlotFull,
};
