import { isValidSlug, slugErrorKind } from './slug';
import { effectiveAvgMin } from './format';
import { safeBrandColor, safeLogoUrl } from './queueLogic';

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
  if (value === 'open' || value === 'paused' || value === 'closed') return value;
  return value === undefined || value === null ? 'open' : 'closed';
}

export function futureTime(value: number | null | undefined, now: number): number | null {
  return typeof value === 'number' && value > now ? value : null;
}

export type WidgetMeta = {
  name: string;
  status: WidgetStatus;
  avgServiceMin: number | null;
  avgServiceMinAuto: number | null;
  statusMessage: string | null;
  resumeAt: number | null;
  opensAt: number | null;
  brandColor: string | null;
  logoUrl: string | null;
  scheduled: boolean;
};

export function parseWidgetMeta(val: unknown): WidgetMeta | null {
  if (!val || typeof val !== 'object') return null;
  const raw = val as Record<string, unknown>;
  if (raw.deleting === true) return null;
  const num = (v: unknown) => (typeof v === 'number' ? v : null);
  return {
    name: typeof raw.name === 'string' && raw.name ? raw.name : 'Qio',
    status: widgetStatus(raw.status),
    avgServiceMin: num(raw.avgServiceMin),
    avgServiceMinAuto: num(raw.avgServiceMinAuto),
    statusMessage: typeof raw.statusMessage === 'string' ? raw.statusMessage : null,
    resumeAt: num(raw.resumeAt),
    opensAt: num(raw.opensAt),
    brandColor: safeBrandColor(raw.brandColor),
    logoUrl: safeLogoUrl(raw.logoUrl),
    scheduled: raw.mode === 'schedule',
  };
}

export type Resolved =
  | { kind: 'pending' }
  | { kind: 'ok'; queueId: string }
  | { kind: 'notFound' }
  | { kind: 'failed' };

export async function resolveWidgetSlug(
  slug: string,
  resolver: (slug: string) => Promise<string>,
): Promise<Resolved> {
  try {
    return { kind: 'ok', queueId: await resolver(slug) };
  } catch (err) {
    return slugErrorKind(err) === 'notFound'
      ? { kind: 'ok', queueId: slug }
      : { kind: 'failed' };
  }
}

export type WidgetState =
  | { phase: 'loading' }
  | { phase: 'notFound' }
  | { phase: 'failed' }
  | { phase: 'ready'; meta: WidgetMeta; counts: WidgetCounts };

export type WidgetInputs = {
  resolved: Resolved;
  authFailed: boolean;
  listenFailed: boolean;
  meta: WidgetMeta | null | undefined;
  tickets: Record<string, { status?: unknown }> | null;
};

export function deriveWidgetState(i: WidgetInputs): WidgetState {
  if (i.resolved.kind === 'notFound') return { phase: 'notFound' };
  if (i.resolved.kind === 'failed' || i.authFailed || i.listenFailed) return { phase: 'failed' };
  if (i.meta === null) return { phase: 'notFound' };
  if (i.meta === undefined || i.tickets === null) return { phase: 'loading' };
  return { phase: 'ready', meta: i.meta, counts: countPublic(i.tickets) };
}
