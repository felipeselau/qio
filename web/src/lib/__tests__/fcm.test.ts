import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const { loadMessagingModule, getMessagingSafe, MessagingLoadError } = vi.hoisted(() => ({
  loadMessagingModule: vi.fn(),
  getMessagingSafe: vi.fn(),
  MessagingLoadError: class MessagingLoadError extends Error {},
}));

vi.mock('../messagingModule', () => ({ loadMessagingModule }));
vi.mock('../messaging', () => ({ getMessagingSafe, MessagingLoadError }));
vi.mock('../../i18n', () => ({ default: { t: (k: string) => k } }));

const isSupported = vi.fn();
const onMessage = vi.fn();
const getToken = vi.fn();

function mod() {
  return { isSupported, onMessage, getToken };
}

beforeEach(() => {
  vi.resetModules();
  vi.useFakeTimers();
  vi.stubEnv('VITE_VAPID_KEY', 'vapid');
  vi.stubGlobal('Notification', { permission: 'default' });
  for (const f of [loadMessagingModule, getMessagingSafe, isSupported, onMessage, getToken]) {
    f.mockReset();
  }
  vi.spyOn(console, 'debug').mockImplementation(() => {});
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('pushSupport', () => {
  it('is unsupported without vapid key or Notification', async () => {
    vi.stubEnv('VITE_VAPID_KEY', '');
    const { pushSupport } = await import('../fcm');
    await expect(pushSupport()).resolves.toBe('unsupported');
    vi.stubEnv('VITE_VAPID_KEY', 'vapid');
    vi.unstubAllGlobals();
    vi.resetModules();
    const again = await import('../fcm');
    await expect(again.pushSupport()).resolves.toBe('unsupported');
  });

  it('is unsupported when isSupported is false', async () => {
    const { pushSupport } = await import('../fcm');
    loadMessagingModule.mockResolvedValue(mod());
    isSupported.mockResolvedValue(false);
    await expect(pushSupport()).resolves.toBe('unsupported');
  });

  it('maps notification permission', async () => {
    const { pushSupport } = await import('../fcm');
    loadMessagingModule.mockResolvedValue(mod());
    isSupported.mockResolvedValue(true);
    await expect(pushSupport()).resolves.toBe('ready');
    vi.stubGlobal('Notification', { permission: 'granted' });
    await expect(pushSupport()).resolves.toBe('granted');
    vi.stubGlobal('Notification', { permission: 'denied' });
    await expect(pushSupport()).resolves.toBe('denied');
  });

  it('retries the import once and recovers', async () => {
    const { pushSupport } = await import('../fcm');
    loadMessagingModule.mockRejectedValueOnce(new Error('net'));
    loadMessagingModule.mockResolvedValueOnce(mod());
    isSupported.mockResolvedValue(true);
    const p = pushSupport();
    await vi.runAllTimersAsync();
    await expect(p).resolves.toBe('ready');
  });

  it('is unavailable when the import keeps failing', async () => {
    const { pushSupport } = await import('../fcm');
    loadMessagingModule.mockRejectedValue(new Error('net'));
    const p = pushSupport();
    await vi.runAllTimersAsync();
    await expect(p).resolves.toBe('unavailable');
    expect(loadMessagingModule).toHaveBeenCalledTimes(2);
  });
});

describe('getFcmToken', () => {
  it('throws a handleable error when the import fails', async () => {
    const { getFcmToken } = await import('../fcm');
    loadMessagingModule.mockRejectedValue(new Error('net'));
    const p = getFcmToken();
    const assertion = expect(p).rejects.toBeInstanceOf(MessagingLoadError);
    await vi.runAllTimersAsync();
    await assertion;
  });

  it('returns the token when everything works', async () => {
    const { getFcmToken } = await import('../fcm');
    loadMessagingModule.mockResolvedValue(mod());
    isSupported.mockResolvedValue(true);
    getMessagingSafe.mockResolvedValue({});
    getToken.mockResolvedValue('tok');
    await expect(getFcmToken()).resolves.toBe('tok');
  });

  it('returns null when unsupported', async () => {
    const { getFcmToken } = await import('../fcm');
    loadMessagingModule.mockResolvedValue(mod());
    isSupported.mockResolvedValue(true);
    getMessagingSafe.mockResolvedValue(null);
    await expect(getFcmToken()).resolves.toBeNull();
  });
});

describe('listenForMessages', () => {
  it('does not subscribe when cancelled before the import finishes', async () => {
    const { listenForMessages } = await import('../fcm');
    let resolveImport!: (m: ReturnType<typeof mod>) => void;
    loadMessagingModule.mockReturnValue(
      new Promise((r) => {
        resolveImport = r;
      }),
    );
    isSupported.mockResolvedValue(true);
    getMessagingSafe.mockResolvedValue({});
    const stop = listenForMessages(() => {});
    stop();
    resolveImport(mod());
    await vi.runAllTimersAsync();
    expect(onMessage).not.toHaveBeenCalled();
  });

  it('unsubscribes on cleanup after subscribing', async () => {
    const { listenForMessages } = await import('../fcm');
    const unsub = vi.fn();
    loadMessagingModule.mockResolvedValue(mod());
    isSupported.mockResolvedValue(true);
    getMessagingSafe.mockResolvedValue({});
    onMessage.mockReturnValue(unsub);
    const stop = listenForMessages(() => {});
    await vi.runAllTimersAsync();
    expect(onMessage).toHaveBeenCalledTimes(1);
    stop();
    expect(unsub).toHaveBeenCalledTimes(1);
  });

  it('logs and swallows import failures', async () => {
    const { listenForMessages } = await import('../fcm');
    loadMessagingModule.mockRejectedValue(new Error('net'));
    const stop = listenForMessages(() => {});
    await vi.runAllTimersAsync();
    expect(console.debug).toHaveBeenCalled();
    expect(() => stop()).not.toThrow();
  });
});
