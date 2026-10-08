export type Slot = { id: string; start: string; capacity: number };

type PublicWithSlot = { status?: string; slotId?: string };

const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)$/;
const SP_OFFSET_MS = 3 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
export const SLOT_GRACE_MS = 15 * 60 * 1000;
export const MAX_SLOTS = 24;

export function parseSlots(raw: unknown): Slot[] {
  if (!raw || typeof raw !== 'object') return [];
  const slots: Slot[] = [];
  for (const [id, value] of Object.entries(raw as Record<string, any>)) {
    const start = value?.start;
    const capacity = value?.capacity;
    if (typeof start !== 'string' || !TIME_RE.test(start)) continue;
    if (!Number.isInteger(capacity) || capacity < 1 || capacity > 50) continue;
    slots.push({ id, start, capacity });
  }
  return slots.sort((a, b) => a.start.localeCompare(b.start)).slice(0, MAX_SLOTS);
}

export function slotStartMs(start: string, now: number): number {
  const m = TIME_RE.exec(start);
  const minutes = m ? Number(m[1]) * 60 + Number(m[2]) : 0;
  const dayStart = Math.floor((now - SP_OFFSET_MS) / DAY_MS) * DAY_MS + SP_OFFSET_MS;
  return dayStart + minutes * 60 * 1000;
}

export function isSlotPast(start: string, now: number): boolean {
  return now > slotStartMs(start, now) + SLOT_GRACE_MS;
}

export function slotTaken(
  publicTickets: Record<string, PublicWithSlot>,
  slot: Slot,
): number {
  return Object.values(publicTickets).filter(
    (e) => (e.status === 'waiting' || e.status === 'called') && e.slotId === slot.id,
  ).length;
}

export function isSlotFull(taken: number, slot: Slot): boolean {
  return taken >= slot.capacity;
}

export function formatSlotTime(ms: number, language: string): string {
  return new Date(ms).toLocaleTimeString(language, {
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
    timeZone: 'America/Sao_Paulo',
  });
}
