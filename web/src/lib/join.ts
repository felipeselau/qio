import { ref, update } from 'firebase/database';
import { httpsCallable } from 'firebase/functions';
import { auth, db, functions } from '../firebase';
import { trackEvent } from './analytics';
import i18n from '../i18n';
import { storeEntryId } from './storage';

export type JoinResult = { entryId: string; ticket: number; existing: boolean };

const JOIN_ERROR_KEYS: Record<string, string> = {
  'functions/already-exists': 'errors.alreadyExists',
  'functions/resource-exhausted': 'errors.resourceExhausted',
  'functions/failed-precondition': 'errors.failedPrecondition',
  'functions/invalid-argument': 'errors.invalidArgument',
  'functions/not-found': 'errors.notFound',
  'functions/unauthenticated': 'errors.securityCheckFailed',
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
      { queueId: string; name: string; phone: string; lang: string },
      JoinResult
    >(functions, 'joinQueue');
    result = (await call({ queueId, name, phone, lang: i18n.language })).data;
  } catch (err) {
    const e = err as { code?: string; details?: { reason?: string } } | null;
    const code = e?.code ?? '';
    if (code === 'functions/resource-exhausted' && e?.details?.reason === 'queue-full') {
      throw new Error(i18n.t('errors.queueFull'));
    }
    throw new Error(i18n.t(JOIN_ERROR_KEYS[code] ?? 'errors.joinFailed'));
  }

  storeEntryId(queueId, result.entryId);
  if (!result.existing) trackEvent('queue_joined', queueId);
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
    trackEvent('feedback_sent', queueId);
  } catch (err) {
    const code = (err as { code?: string } | null)?.code ?? '';
    if (code === 'functions/failed-precondition') return;
    if (code === 'functions/unauthenticated') throw new Error(i18n.t('errors.securityCheckFailed'));
    throw new Error(i18n.t('errors.feedbackFailed'));
  }
}
