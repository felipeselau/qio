import { beforeEach, describe, expect, it, vi } from 'vitest';

const { set, get, remove, getFcmToken } = vi.hoisted(() => ({
  set: vi.fn(),
  get: vi.fn(),
  remove: vi.fn(),
  getFcmToken: vi.fn(),
}));

vi.mock('firebase/database', () => ({
  ref: (_db: unknown, path: string) => ({ path }),
  serverTimestamp: () => ({ '.sv': 'timestamp' }),
  set,
  get,
  remove,
}));
vi.mock('../../firebase', () => ({ auth: { currentUser: { uid: 'u1' } }, db: {} }));
vi.mock('../../i18n', () => ({ default: { language: 'en-US', t: (k: string) => k } }));
vi.mock('../fcm', () => ({ getFcmToken }));

import {
  WATCH_TTL_MS,
  isWatchActive,
  isWatchingOpen,
  unwatchOpen,
  watchOpen,
  watcherLang,
} from '../openWatch';

beforeEach(() => {
  for (const f of [set, get, remove, getFcmToken]) f.mockReset();
});

describe('watcherLang', () => {
  it('normaliza para pt/en/es', () => {
    expect(watcherLang('en-US')).toBe('en');
    expect(watcherLang('ES')).toBe('es');
    expect(watcherLang('pt-BR')).toBe('pt');
    expect(watcherLang('fr')).toBe('pt');
    expect(watcherLang(undefined)).toBe('pt');
  });
});

describe('isWatchActive', () => {
  it('respeita o TTL de 24h', () => {
    expect(isWatchActive(1000, 1000 + WATCH_TTL_MS)).toBe(true);
    expect(isWatchActive(1000, 1001 + WATCH_TTL_MS)).toBe(false);
    expect(isWatchActive(undefined, 5)).toBe(false);
  });
});

describe('watchOpen', () => {
  it('grava token, idioma e createdAt no caminho do uid', async () => {
    getFcmToken.mockResolvedValue('tok');
    await expect(watchOpen('q1')).resolves.toBe(true);
    expect(set).toHaveBeenCalledWith(
      { path: 'queues/q1/openWatchers/u1' },
      { fcmToken: 'tok', lang: 'en', createdAt: { '.sv': 'timestamp' } },
    );
  });

  it('não grava sem token', async () => {
    getFcmToken.mockResolvedValue(null);
    await expect(watchOpen('q1')).resolves.toBe(false);
    expect(set).not.toHaveBeenCalled();
  });
});

describe('isWatchingOpen / unwatchOpen', () => {
  it('lê o próprio pedido e ignora vencido', async () => {
    get.mockResolvedValueOnce({ exists: () => true, val: () => ({ createdAt: Date.now() }) });
    await expect(isWatchingOpen('q1')).resolves.toBe(true);
    get.mockResolvedValueOnce({
      exists: () => true,
      val: () => ({ createdAt: Date.now() - WATCH_TTL_MS - 1000 }),
    });
    await expect(isWatchingOpen('q1')).resolves.toBe(false);
    get.mockResolvedValueOnce({ exists: () => false, val: () => null });
    await expect(isWatchingOpen('q1')).resolves.toBe(false);
  });

  it('propaga falha de leitura', async () => {
    get.mockRejectedValueOnce(new Error('denied'));
    await expect(isWatchingOpen('q1')).rejects.toThrow('denied');
  });

  it('remove o pedido', async () => {
    await unwatchOpen('q1');
    expect(remove).toHaveBeenCalledWith({ path: 'queues/q1/openWatchers/u1' });
  });
});
