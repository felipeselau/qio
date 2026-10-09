import { useCallback, useEffect, useState } from 'react';
import { onValue, ref } from 'firebase/database';
import { db } from '../firebase';
import { ensureSignedIn } from './anonAuth';
import { resolveSlugToQueueId } from './resolveSlug';
import {
  deriveWidgetState,
  parseWidgetMeta,
  resolveWidgetSlug,
  type Resolved,
  type WidgetCounts,
  type WidgetMeta,
  type WidgetTarget,
} from './widget';

export type { WidgetMeta };

export type WidgetView =
  | { phase: 'loading' }
  | { phase: 'notFound' }
  | { phase: 'failed'; retry: () => void }
  | { phase: 'ready'; queueId: string; meta: WidgetMeta; counts: WidgetCounts };

export function useWidget(target: WidgetTarget): WidgetView {
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
    let active = true;
    ensureSignedIn()
      .then(() => {
        if (active) {
          setReady(true);
          setAuthFailed(false);
        }
      })
      .catch(() => {
        if (active) setAuthFailed(true);
      });
    return () => {
      active = false;
    };
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
    void resolveWidgetSlug(slug, resolveSlugToQueueId).then((result) => {
      if (active) setResolved(result);
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
        setMeta(parseWidgetMeta(snap.val()));
        setListenFailed(false);
      },
      () => setListenFailed(true),
    );
    const unsubPublic = onValue(
      ref(db, `queues/${queueId}/public`),
      (snap) => setTickets(snap.val() ?? {}),
      () => setListenFailed(true),
    );
    return () => {
      unsubMeta();
      unsubPublic();
    };
  }, [ready, queueId, attempt]);

  const state = deriveWidgetState({ resolved, authFailed, listenFailed, meta, tickets });
  if (state.phase === 'failed') return { phase: 'failed', retry };
  if (state.phase === 'ready') {
    return queueId ? { ...state, queueId } : { phase: 'loading' };
  }
  return state;
}
