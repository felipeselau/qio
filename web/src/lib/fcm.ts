import i18n from '../i18n';
import { getToken, isSupported, onMessage } from 'firebase/messaging';
import { getMessagingSafe } from '../firebase';

const vapidKey = import.meta.env.VITE_VAPID_KEY as string | undefined;

export async function getFcmToken(): Promise<string | null> {
  if (!vapidKey) return null;
  try {
    if (!(await isSupported())) return null;
    const messaging = getMessagingSafe();
    if (!messaging) return null;
    const token = await getToken(messaging, { vapidKey });
    return token || null;
  } catch {
    return null;
  }
}

export function listenForMessages(onTurn: () => void): () => void {
  if (!vapidKey) return () => {};
  let unsub: (() => void) | null = null;
  isSupported().then((supported) => {
    if (!supported) return;
    const messaging = getMessagingSafe();
    if (!messaging) return;
    unsub = onMessage(messaging, () => {
      if (document.hidden) {
        new Notification(i18n.t('queue.yourTurn'), {
          body: i18n.t('push.called'),
          icon: '/icon-192.png',
        });
        onTurn();
      }
    });
  });
  return () => unsub?.();
}
