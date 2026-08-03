import { useEffect, useState } from 'react';
import { onValue, ref } from 'firebase/database';
import { db } from '../firebase';

export type QueueMeta = {
  name: string;
  status: 'open' | 'paused' | 'closed';
  serving: number;
  avgServiceMin: number | null;
  description: string | null;
};

export type EntryStatus = 'waiting' | 'called' | 'served' | 'no_show' | 'left';

export type MyEntry = {
  ticket: number;
  name: string;
  status: EntryStatus;
  joinedAt: number;
  calledAt: number | null;
};

export type QueueState = {
  meta: QueueMeta | null;
  myEntry: MyEntry | null;
  myEntryResolved: boolean;
  position: number | null;
  estimatedWaitMin: number | null;
  loading: boolean;
  exists: boolean;
};

export function useQueue(queueId: string, entryId: string | null): QueueState {
  const [meta, setMeta] = useState<QueueMeta | null>(null);
  const [entries, setEntries] = useState<Record<string, any> | null>(null);
  const [myEntry, setMyEntry] = useState<MyEntry | null>(null);
  const [myEntryResolved, setMyEntryResolved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [exists, setExists] = useState(true);

  useEffect(() => {
    const metaRef = ref(db, `queues/${queueId}/meta`);
    const unsub = onValue(metaRef, (snap) => {
      const val = snap.val();
      if (!val) {
        setExists(false);
        setMeta(null);
      } else {
        setMeta({
          name: val.name ?? 'Fila',
          status: val.status ?? 'open',
          serving: val.serving ?? 0,
          avgServiceMin: val.avgServiceMin ?? null,
          description: val.description ?? null,
        });
      }
      setLoading(false);
    });
    return unsub;
  }, [queueId]);

  useEffect(() => {
    const entriesRef = ref(db, `queues/${queueId}/entries`);
    const unsub = onValue(entriesRef, (snap) => {
      setEntries(snap.val() ?? {});
    });
    return unsub;
  }, [queueId]);

  useEffect(() => {
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
        });
      }
    });
    return unsub;
  }, [queueId, entryId]);

  let position: number | null = null;
  let estimatedWaitMin: number | null = null;
  if (myEntry && entries) {
    const waiting = Object.values(entries)
      .filter((e: any) => e.status === 'waiting')
      .map((e: any) => e.ticket as number)
      .sort((a, b) => a - b);
    const idx = waiting.indexOf(myEntry.ticket);
    if (idx >= 0) position = idx + 1;
    const avg = meta?.avgServiceMin ?? 10;
    if (position != null) estimatedWaitMin = position * avg;
  }

  return { meta, myEntry, myEntryResolved, position, estimatedWaitMin, loading, exists };
}