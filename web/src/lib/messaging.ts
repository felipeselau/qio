import type { Messaging } from 'firebase/messaging';
import { app } from '../firebase';
import { loadMessagingModule } from './messagingModule';

export class MessagingLoadError extends Error {
  constructor(cause: unknown) {
    super('messaging-load-failed', { cause });
    this.name = 'MessagingLoadError';
  }
}

let _messaging: Promise<Messaging | null> | undefined;

export function getMessagingSafe(): Promise<Messaging | null> {
  if (_messaging) return _messaging;
  const pending = (async () => {
    let mod: Awaited<ReturnType<typeof loadMessagingModule>>;
    try {
      mod = await loadMessagingModule();
    } catch (e) {
      throw new MessagingLoadError(e);
    }
    try {
      return mod.getMessaging(app);
    } catch {
      return null;
    }
  })();
  _messaging = pending;
  pending.catch(() => {
    if (_messaging === pending) _messaging = undefined;
  });
  return pending;
}
