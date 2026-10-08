import i18n from '../i18n';
import { getMessagingSafe } from '../firebase';

const vapidKey = import.meta.env.VITE_VAPID_KEY as string | undefined;

export type PushSupport = 'ready' | 'granted' | 'denied' | 'unsupported';

export async function pushSupport(): Promise<PushSupport> {
  if (!vapidKey) return 'unsupported';
  if (typeof Notification === 'undefined') return 'unsupported';
  try {
    const { isSupported } = await import('firebase/messaging');
    if (!(await isSupported())) return 'unsupported';
  } catch {
    return 'unsupported';
  }
  if (Notification.permission === 'granted') return 'granted';
  if (Notification.permission === 'denied') return 'denied';
  return 'ready';
}

export async function requestPushPermission(): Promise<'granted' | 'denied'> {
  const result = await Notification.requestPermission();
  return result === 'granted' ? 'granted' : 'denied';
}

export async function getFcmToken(): Promise<string | null> {
  if (!vapidKey) return null;
  try {
    const { getToken, isSupported } = await import('firebase/messaging');
    if (!(await isSupported())) return null;
    const messaging = await getMessagingSafe();
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
  let cancelled = false;
  void (async () => {
    try {
      const { isSupported, onMessage } = await import('firebase/messaging');
      if (!(await isSupported())) return;
      const messaging = await getMessagingSafe();
      if (!messaging || cancelled) return;
      unsub = onMessage(messaging, () => {
        if (document.hidden) {
          new Notification(i18n.t('queue.yourTurn'), {
            body: i18n.t('push.called'),
            icon: '/icon-192.png',
          });
          onTurn();
        }
      });
    } catch {
    }
  })();
  return () => {
    cancelled = true;
    unsub?.();
  };
}
