export type PublicTicket = {
  ticket: number;
  status: string;
  order?: number;
  slotId?: string;
  slotStart?: number;
};

export function positionInQueue(
  publicTickets: Record<string, PublicTicket>,
  mine: { ticket: number; order?: number | null; joinedAt: number },
): number {
  const myOrder = mine.order ?? mine.joinedAt;
  const ahead = Object.values(publicTickets).filter((e) => {
    if (e.status !== 'waiting') return false;
    if (typeof e.order !== 'number') return e.ticket < mine.ticket;
    return e.order < myOrder || (e.order === myOrder && e.ticket < mine.ticket);
  }).length;
  return ahead + 1;
}

const BRAND_COLORS = [
  '#2563EB',
  '#0F766E',
  '#047857',
  '#7C3AED',
  '#BE185D',
  '#B91C1C',
  '#C2410C',
  '#334155',
];

export function safeBrandColor(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const hex = value.toUpperCase();
  return BRAND_COLORS.includes(hex) ? hex : null;
}

export function safeLogoUrl(value: unknown): string | null {
  if (typeof value !== 'string' || value.length > 600) return null;
  return value.startsWith('https://firebasestorage.googleapis.com/') ? value : null;
}

export function isQueueFull(maxWaiting: number, waitingCount: number): boolean {
  return maxWaiting > 0 && waitingCount >= maxWaiting;
}
