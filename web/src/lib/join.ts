import { runTransaction, ref, push, set, update } from 'firebase/database';
import { auth, db } from '../firebase';
import { storeEntryId } from './storage';

export type JoinResult = { entryId: string; ticket: number };

export async function joinQueue(
  queueId: string,
  name: string,
  phone: string,
): Promise<JoinResult> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('Não autenticado');

  const ticketSnap = await runTransaction(ref(db, `tickets/${queueId}`), (current) => {
    return (current ?? 0) + 1;
  });
  const ticket = ticketSnap.snapshot.val() as number;

  const entriesRef = ref(db, `queues/${queueId}/entries`);
  const newRef = push(entriesRef);
  const entryId = newRef.key!;
  await set(newRef, {
    ticket,
    name,
    phone,
    uid,
    status: 'waiting',
    joinedAt: Date.now(),
    calledAt: null,
  });

  storeEntryId(queueId, entryId);
  return { entryId, ticket };
}
export async function leaveQueue(queueId: string, entryId: string): Promise<void> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('Não autenticado');
  await update(ref(db, `queues/${queueId}/entries/${entryId}`), {
    status: 'left',
  });
}

export async function saveFcmToken(
  queueId: string,
  entryId: string,
  token: string,
): Promise<void> {
  await update(ref(db, `queues/${queueId}/entries/${entryId}`), {
    fcmToken: token,
  });
}
