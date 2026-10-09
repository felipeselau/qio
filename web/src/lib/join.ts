import { ref, update } from 'firebase/database';
import { httpsCallable } from 'firebase/functions';
import { auth, db } from '../firebase';
import { functions } from '../firebaseFunctions';
import { trackEvent } from './analytics';
import i18n from '../i18n';
import { storeEntryId } from './storage';
import { feedbackErrorKey, joinErrorKey } from './joinErrors';

export type JoinResult = { entryId: string; ticket: number; existing: boolean };

export async function joinQueue(
  queueId: string,
  name: string,
  phone: string,
  slotId?: string | null,
): Promise<JoinResult> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error(i18n.t('errors.notAuthenticated'));

  let result: JoinResult;
  try {
    const call = httpsCallable<
      { queueId: string; name: string; phone: string; lang: string; slotId?: string },
      JoinResult
    >(functions, 'joinQueue');
    result = (
      await call({ queueId, name, phone, lang: i18n.language, ...(slotId ? { slotId } : {}) })
    ).data;
  } catch (err) {
    throw new Error(i18n.t(joinErrorKey(err)));
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
    const key = feedbackErrorKey(err);
    if (key === null) return;
    throw new Error(i18n.t(key));
  }
}
