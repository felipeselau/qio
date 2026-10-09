import { isValidSlug } from './slug';
import { effectiveAvgMin } from './format';

export const WIDGET_PATH_PREFIX = '/w/';

const QUEUE_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

export type WidgetTarget =
  | { kind: 'slug'; slug: string }
  | { kind: 'id'; queueId: string }
  | { kind: 'invalid' };

export function parseWidgetTarget(raw: unknown): WidgetTarget {
  if (typeof raw !== 'string' || !QUEUE_ID_PATTERN.test(raw)) return { kind: 'invalid' };
  if (isValidSlug(raw)) return { kind: 'slug', slug: raw };
  return { kind: 'id', queueId: raw };
}

export type WidgetCounts = { waiting: number; called: number };

export function countPublic(
  tickets: Record<string, { status?: unknown }> | null | undefined,
): WidgetCounts {
  let waiting = 0;
  let called = 0;
  for (const entry of Object.values(tickets ?? {})) {
    if (entry?.status === 'waiting') waiting += 1;
    else if (entry?.status === 'called') called += 1;
  }
  return { waiting, called };
}

export function widgetEstimateMin(
  waiting: number,
  auto: number | null | undefined,
  manual: number | null | undefined,
  scheduled: boolean,
): number | null {
  if (scheduled || waiting < 1) return null;
  return Math.round((waiting + 1) * effectiveAvgMin(auto, manual));
}

export type WidgetStatus = 'open' | 'paused' | 'closed';

export function widgetStatus(value: unknown): WidgetStatus {
  return value === 'paused' || value === 'closed' ? value : 'open';
}

export function futureTime(value: number | null | undefined, now: number): number | null {
  return typeof value === 'number' && value > now ? value : null;
}
