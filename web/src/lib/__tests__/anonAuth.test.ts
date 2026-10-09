import { beforeEach, describe, expect, it, vi } from 'vitest';

const { signInAnonymously, authStateReady, authMock } = vi.hoisted(() => {
  const authStateReady = vi.fn();
  return {
    signInAnonymously: vi.fn(),
    authStateReady,
    authMock: { authStateReady, currentUser: null as unknown },
  };
});

vi.mock('firebase/auth', () => ({ signInAnonymously }));
vi.mock('../../firebase', () => ({ auth: authMock }));

beforeEach(() => {
  vi.resetModules();
  signInAnonymously.mockReset();
  authStateReady.mockReset();
  authStateReady.mockResolvedValue(undefined);
  authMock.currentUser = null;
});

describe('ensureSignedIn', () => {
  it('chamadas concorrentes fazem um unico sign-in', async () => {
    signInAnonymously.mockResolvedValue({});
    const { ensureSignedIn } = await import('../anonAuth');
    await Promise.all([ensureSignedIn(), ensureSignedIn(), ensureSignedIn()]);
    expect(signInAnonymously).toHaveBeenCalledTimes(1);
  });

  it('nao faz sign-in se ja ha usuario', async () => {
    authMock.currentUser = { uid: 'u' };
    const { ensureSignedIn } = await import('../anonAuth');
    await ensureSignedIn();
    expect(signInAnonymously).not.toHaveBeenCalled();
  });

  it('nao guarda falha em cache', async () => {
    signInAnonymously.mockRejectedValueOnce(new Error('net')).mockResolvedValueOnce({});
    const { ensureSignedIn } = await import('../anonAuth');
    await expect(ensureSignedIn()).rejects.toThrow('net');
    await ensureSignedIn();
    expect(signInAnonymously).toHaveBeenCalledTimes(2);
  });
});
