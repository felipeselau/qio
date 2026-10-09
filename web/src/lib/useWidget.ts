import { useCallback, useEffect, useState } from 'react';
import { onAuthStateChanged, signInAnonymously } from 'firebase/auth';
import { onValue, ref } from 'firebase/database';
import { auth, db } from '../firebase';
import { safeBrandColor, safeLogoUrl } from './queueLogic';
import {
  countPublic,
  widgetStatus,
  type WidgetCounts,
  type WidgetStatus,
  type WidgetTarget,
} from './widget';
import { resolveSlugToQueueId } from './resolveSlug';
import { slugErrorKind } from './slug';

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

export type WidgetState =
  | { phase: 'loading' }
  | { phase: 'notFound' }
  | { phase: 'failed'; retry: () => void }
  | { phase: 'ready'; queueId: string; meta: WidgetMeta; counts: WidgetCounts };

type Resolved =
  | { kind: 'pending' }
  | { kind: 'ok'; queueId: string }
  | { kind: 'notFound' }
  | { kind: 'failed' };

function parseMeta(val: Record<string, unknown>): WidgetMeta {
  const num = (v: unknown) => (typeof v === 'number' ? v : null);
  return {
    name: typeof val.name === 'string' && val.name ? val.name : 'Qio',
    status: widgetStatus(val.status),
    avgServiceMin: num(val.avgServiceMin),
    avgServiceMinAuto: num(val.avgServiceMinAuto),
    statusMessage: typeof val.statusMessage === 'string' ? val.statusMessage : null,
    resumeAt: num(val.resumeAt),
    opensAt: num(val.opensAt),
    brandColor: safeBrandColor(val.brandColor),
    logoUrl: safeLogoUrl(val.logoUrl),
    scheduled: val.mode === 'schedule',
  };
}

export function useWidget(target: WidgetTarget): WidgetState {
  const [ready, setReady] = useState(false);
  const [authFailed, setAuthFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [resolved, setResolved] = useState<Resolved>({ kind: 'pending' });
  const [meta, setMeta] = useState<WidgetMeta | null | undefined>(undefined);
  const [tickets, setTickets] = useState<Record<string, { status?: unknown }> | null>(null);
  const [listenFailed, setListenFailed] = useState(false);
  const retry = useCallback(() => {
    setAuthFailed(false);
    setListenFailed(false);
    setAttempt((n) => n + 1);
  }, []);

  useEffect(() => {
    return onAuthStateChanged(auth, (user) => {
      if (user) {
        setReady(true);
        setAuthFailed(false);
      } else {
        signInAnonymously(auth).catch(() => setAuthFailed(true));
      }
    });
  }, [attempt]);

  const slug = target.kind === 'slug' ? target.slug : null;
  const directId = target.kind === 'id' ? target.queueId : null;

  useEffect(() => {
    setMeta(undefined);
    setTickets(null);
    if (directId) {
      setResolved({ kind: 'ok', queueId: directId });
      return;
    }
    if (!slug) {
      setResolved({ kind: 'notFound' });
      return;
    }
    setResolved({ kind: 'pending' });
    let active = true;
    resolveSlugToQueueId(slug)
      .then((queueId) => {
        if (active) setResolved({ kind: 'ok', queueId });
      })
      .catch((err) => {
        if (!active) return;
        if (slugErrorKind(err) === 'notFound') {
          setResolved({ kind: 'ok', queueId: slug });
        } else {
          setResolved({ kind: 'failed' });
        }
      });
    return () => {
      active = false;
    };
  }, [slug, directId, attempt]);

  const queueId = resolved.kind === 'ok' ? resolved.queueId : null;

  useEffect(() => {
    if (!ready || !queueId) return;
    const unsubMeta = onValue(
      ref(db, `queues/${queueId}/meta`),
      (snap) => {
        const val = snap.val();
        setMeta(val ? parseMeta(val) : null);
        setListenFailed(false);
      },
      () => setListenFailed(true),
    );
    const unsubPublic = onValue(
      ref(db, `queues/${queueId}/public`),
      (snap) => setTickets(snap.val() ?? {}),
      () => {},
    );
    return () => {
      unsubMeta();
      unsubPublic();
    };
  }, [ready, queueId, attempt]);

  if (resolved.kind === 'notFound') return { phase: 'notFound' };
  if (resolved.kind === 'failed' || authFailed || listenFailed) return { phase: 'failed', retry };
  if (meta === null) return { phase: 'notFound' };
  if (meta === undefined) return { phase: 'loading' };
  return { phase: 'ready', queueId: queueId ?? '', meta, counts: countPublic(tickets) };
}
