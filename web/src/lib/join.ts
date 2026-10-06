import { ref, update } from 'firebase/database';
import { httpsCallable } from 'firebase/functions';
import { auth, db, functions } from '../firebase';
import i18n from '../i18n';
import { storeEntryId } from './storage';

export type JoinResult = { entryId: string; ticket: number; existing: boolean };

const JOIN_ERROR_KEYS: Record<string, string> = {
  'functions/already-exists': 'errors.alreadyExists',
  'functions/resource-exhausted': 'errors.resourceExhausted',
  'functions/failed-precondition': 'errors.failedPrecondition',
  'functions/invalid-argument': 'errors.invalidArgument',
  'functions/not-found': 'errors.notFound',
};

export async function joinQueue(
  queueId: string,
  name: string,
  phone: string,
): Promise<JoinResult> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error(i18n.t('errors.notAuthenticated'));

  let result: JoinResult;
  try {
    const call = httpsCallable<
      { queueId: string; name: string; phone: string },
      JoinResult
    >(functions, 'joinQueue');
    result = (await call({ queueId, name, phone })).data;
  } catch (err) {
    const code = (err as { code?: string } | null)?.code ?? '';
    throw new Error(i18n.t(JOIN_ERROR_KEYS[code] ?? 'errors.joinFailed'));
  }

  storeEntryId(queueId, result.entryId);
  return result;
}

export async function leaveQueue(queueId: string, entryId: string): Promise<void> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error(i18n.t('errors.notAuthenticated'));
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

export async function submitFeedback(
  queueId: string,
  entryId: string,
  rating: number,
  comment: string,
): Promise<void> {
  try {
    const call = httpsCallable(functions, 'submitFeedback');
    await call({ queueId, entryId, rating, comment });
  } catch (err) {
    const code = (err as { code?: string } | null)?.code ?? '';
    if (code === 'functions/failed-precondition') return;
    throw new Error(i18n.t('errors.feedbackFailed'));
  }
}
