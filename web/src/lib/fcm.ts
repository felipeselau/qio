import i18n from '../i18n';
import { getMessagingSafe, MessagingLoadError } from './messaging';
import { loadMessagingModule } from './messagingModule';

const vapidKey = import.meta.env.VITE_VAPID_KEY as string | undefined;

const LOAD_RETRY_DELAY_MS = 600;

export type PushSupport = 'ready' | 'granted' | 'denied' | 'unsupported' | 'unavailable';

type MessagingModule = Awaited<ReturnType<typeof loadMessagingModule>>;

async function loadWithRetry(): Promise<MessagingModule> {
  try {
    return await loadMessagingModule();
  } catch {
    await new Promise((resolve) => setTimeout(resolve, LOAD_RETRY_DELAY_MS));
    try {
      return await loadMessagingModule();
    } catch (e) {
      throw new MessagingLoadError(e);
    }
  }
}

export async function pushSupport(): Promise<PushSupport> {
  if (!vapidKey) return 'unsupported';
  if (typeof Notification === 'undefined') return 'unsupported';
  let mod: MessagingModule;
  try {
    mod = await loadWithRetry();
  } catch {
    return 'unavailable';
  }
  try {
    if (!(await mod.isSupported())) return 'unsupported';
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
  const mod = await loadWithRetry();
  try {
    if (!(await mod.isSupported())) return null;
    const messaging = await getMessagingSafe();
    if (!messaging) return null;
    const token = await mod.getToken(messaging, { vapidKey });
    return token || null;
  } catch (e) {
    if (e instanceof MessagingLoadError) throw e;
    return null;
  }
}

export function listenForMessages(onTurn: () => void): () => void {
  if (!vapidKey) return () => {};
  let unsub: (() => void) | null = null;
  let cancelled = false;
  void (async () => {
    try {
      const { isSupported, onMessage } = await loadMessagingModule();
      if (cancelled || !(await isSupported())) return;
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
    } catch (e) {
      console.debug('[fcm] listenForMessages failed', e);
    }
  })();
  return () => {
    cancelled = true;
    unsub?.();
  };
}
