import { beforeEach, describe, expect, it, vi } from 'vitest';

const { loadMessagingModule, getMessaging } = vi.hoisted(() => ({
  loadMessagingModule: vi.fn(),
  getMessaging: vi.fn(),
}));

vi.mock('../messagingModule', () => ({ loadMessagingModule }));
vi.mock('../../firebase', () => ({ app: { name: 'app' } }));

beforeEach(() => {
  vi.resetModules();
  loadMessagingModule.mockReset();
  getMessaging.mockReset();
});

describe('getMessagingSafe', () => {
  it('does not cache a failed import and retries on the next call', async () => {
    const { getMessagingSafe, MessagingLoadError } = await import('../messaging');
    loadMessagingModule.mockRejectedValueOnce(new Error('chunk'));
    loadMessagingModule.mockResolvedValueOnce({ getMessaging });
    getMessaging.mockReturnValue({ id: 'm' });
    await expect(getMessagingSafe()).rejects.toBeInstanceOf(MessagingLoadError);
    await expect(getMessagingSafe()).resolves.toEqual({ id: 'm' });
    expect(loadMessagingModule).toHaveBeenCalledTimes(2);
  });

  it('caches null when getMessaging throws', async () => {
    const { getMessagingSafe } = await import('../messaging');
    loadMessagingModule.mockResolvedValue({ getMessaging });
    getMessaging.mockImplementation(() => {
      throw new Error('unsupported');
    });
    await expect(getMessagingSafe()).resolves.toBeNull();
    await expect(getMessagingSafe()).resolves.toBeNull();
    expect(loadMessagingModule).toHaveBeenCalledTimes(1);
    expect(getMessaging).toHaveBeenCalledTimes(1);
  });
});
