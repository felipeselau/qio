import i18n from '../i18n';
import { useEffect, useState } from 'react';
import { onValue, ref } from 'firebase/database';
import { db } from '../firebase';

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
};

type PublicTicket = { ticket: number; status: string; order?: number };

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

export function isQueueFull(maxWaiting: number, waitingCount: number): boolean {
  return maxWaiting > 0 && waitingCount >= maxWaiting;
}

export type EntryStatus = 'waiting' | 'called' | 'served' | 'no_show' | 'left';

export type MyEntry = {
  ticket: number;
  name: string;
  status: EntryStatus;
  joinedAt: number;
  order?: number | null;
  calledAt: number | null;
  recalledAt: number | null;
};

export type QueueState = {
  meta: QueueMeta | null;
  myEntry: MyEntry | null;
  myEntryResolved: boolean;
  position: number | null;
  estimatedWaitMin: number | null;
  waitingCount: number;
  full: boolean;
  loading: boolean;
  exists: boolean;
  failed: boolean;
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
  }, [queueId, ready]);

  useEffect(() => {
    if (!ready) return;
    const publicRef = ref(db, `queues/${queueId}/public`);
    const unsub = onValue(publicRef, (snap) => {
      setPublicTickets(snap.val() ?? {});
    });
    return unsub;
  }, [queueId, ready]);

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
        });
      }
    }, () => {
      setMyEntryResolved(true);
      setMyEntry(null);
    });
    return unsub;
  }, [queueId, entryId, ready]);

  let position: number | null = null;
  let estimatedWaitMin: number | null = null;
  if (myEntry && publicTickets) {
    if (myEntry.status === 'waiting') {
      position = positionInQueue(publicTickets, myEntry);
    }
    const avg = meta?.avgServiceMinAuto ?? meta?.avgServiceMin ?? 10;
    if (position != null) estimatedWaitMin = position * avg;
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
    full,
    loading,
    exists,
    failed,
  };
}