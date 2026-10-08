import i18n from '../i18n';
import { useCallback, useEffect, useState } from 'react';
import { onValue, ref } from 'firebase/database';
import { db } from '../firebase';
import { effectiveAvgMin } from './format';
import { parseSlots, type Slot } from './slots';
import {
  isQueueFull,
  positionInQueue,
  safeBrandColor,
  safeLogoUrl,
  type PublicTicket,
} from './queueLogic';

export { isQueueFull, positionInQueue, safeBrandColor, safeLogoUrl, type PublicTicket };

export type QueueMeta = {
  name: string;
  status: 'open' | 'paused' | 'closed';
  serving: number;
  avgServiceMin: number | null;
  avgServiceMinAuto: number | null;
  description: string | null;
  maxWaiting: number;
  statusMessage: string | null;
  resumeAt: number | null;
  opensAt: number | null;
  brandColor: string | null;
  logoUrl: string | null;
  mode: 'queue' | 'schedule';
  slots: Slot[];
};

export type EntryStatus = 'waiting' | 'called' | 'served' | 'no_show' | 'left';

export type MyEntry = {
  ticket: number;
  name: string;
  status: EntryStatus;
  joinedAt: number;
  order?: number | null;
  calledAt: number | null;
  recalledAt: number | null;
  slotStart: number | null;
};

export type QueueState = {
  meta: QueueMeta | null;
  myEntry: MyEntry | null;
  myEntryResolved: boolean;
  position: number | null;
  estimatedWaitMin: number | null;
  waitingCount: number;
  avgServiceMin: number;
  publicReady: boolean;
  publicTickets: Record<string, PublicTicket>;
  full: boolean;
  loading: boolean;
  exists: boolean;
  failed: boolean;
  retry: () => void;
};

export function useQueue(
  queueId: string,
  entryId: string | null,
  ready: boolean,
): QueueState {
  const [meta, setMeta] = useState<QueueMeta | null>(null);
  const [publicTickets, setPublicTickets] = useState<Record<string, any> | null>(null);
  const [myEntry, setMyEntry] = useState<MyEntry | null>(null);
  const [myEntryResolved, setMyEntryResolved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [exists, setExists] = useState(true);
  const [failed, setFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const retry = useCallback(() => {
    setFailed(false);
    setLoading(true);
    setAttempt((n) => n + 1);
  }, []);

  // As regras da RTDB exigem auth != null para ler meta/public. Se o listener
  // for anexado antes do signInAnonymously terminar, a leitura é negada, o
  // onValue cai no callback de erro e o listener é descartado sem retry —
  // deixando a tela presa no spinner no PRIMEIRO acesso de cada usuário
  // (justamente o fluxo do QR code). Só anexamos quando `ready` (autenticado).
  useEffect(() => {
    if (!ready) return;
    const metaRef = ref(db, `queues/${queueId}/meta`);
    const unsub = onValue(
      metaRef,
      (snap) => {
        const val = snap.val();
        if (!val) {
          setExists(false);
          setMeta(null);
        } else {
          setMeta({
            name: val.name ?? i18n.t('queue.defaultName'),
            status: val.status ?? 'open',
            serving: val.serving ?? 0,
            avgServiceMin: val.avgServiceMin ?? null,
            avgServiceMinAuto: val.avgServiceMinAuto ?? null,
            description: val.description ?? null,
            maxWaiting: typeof val.maxWaiting === 'number' ? val.maxWaiting : 0,
            statusMessage: val.statusMessage ?? null,
            resumeAt: typeof val.resumeAt === 'number' ? val.resumeAt : null,
            opensAt: typeof val.opensAt === 'number' ? val.opensAt : null,
            brandColor: safeBrandColor(val.brandColor),
            logoUrl: safeLogoUrl(val.logoUrl),
            mode: val.mode === 'schedule' ? 'schedule' : 'queue',
            slots: parseSlots(val.slots),
          });
        }
        setFailed(false);
        setLoading(false);
      },
      () => {
        setFailed(true);
        setLoading(false);
      },
    );
    return unsub;
  }, [queueId, ready, attempt]);

  useEffect(() => {
    if (!ready) return;
    const publicRef = ref(db, `queues/${queueId}/public`);
    const unsub = onValue(
      publicRef,
      (snap) => {
        setPublicTickets(snap.val() ?? {});
      },
      () => {},
    );
    return unsub;
  }, [queueId, ready, attempt]);

  useEffect(() => {
    if (!ready) return;
    if (!entryId) {
      setMyEntry(null);
      setMyEntryResolved(false);
      return;
    }
    setMyEntryResolved(false);
    const entryRef = ref(db, `queues/${queueId}/entries/${entryId}`);
    const unsub = onValue(entryRef, (snap) => {
      const val = snap.val();
      setMyEntryResolved(true);
      if (!val) {
        setMyEntry(null);
      } else {
        setMyEntry({
          ticket: val.ticket,
          name: val.name,
          status: val.status as EntryStatus,
          joinedAt: val.joinedAt,
          calledAt: val.calledAt,
          recalledAt: typeof val.recalledAt === 'number' ? val.recalledAt : null,
          order: typeof val.order === 'number' ? val.order : null,
          slotStart: typeof val.slotStart === 'number' ? val.slotStart : null,
        });
      }
    }, () => {
      setMyEntryResolved(true);
      setMyEntry(null);
    });
    return unsub;
  }, [queueId, entryId, ready, attempt]);

  let position: number | null = null;
  let estimatedWaitMin: number | null = null;
  if (myEntry && publicTickets) {
    if (myEntry.status === 'waiting') {
      position = positionInQueue(publicTickets, myEntry);
    }
    const avg = effectiveAvgMin(meta?.avgServiceMinAuto, meta?.avgServiceMin);
    if (position != null && meta?.mode !== 'schedule') estimatedWaitMin = position * avg;
  }

  const waitingCount = Object.values(publicTickets ?? {}).filter(
    (e: any) => e.status === 'waiting',
  ).length;
  const full = isQueueFull(meta?.maxWaiting ?? 0, waitingCount);

  return {
    meta,
    myEntry,
    myEntryResolved,
    position,
    estimatedWaitMin,
    waitingCount,
    avgServiceMin: effectiveAvgMin(meta?.avgServiceMinAuto, meta?.avgServiceMin),
    publicReady: publicTickets !== null,
    publicTickets: (publicTickets ?? {}) as Record<string, PublicTicket>,
    full,
    loading,
    exists,
    failed,
    retry,
  };
}