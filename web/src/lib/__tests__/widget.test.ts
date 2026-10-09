import { describe, expect, it } from 'vitest';
import {
  countPublic,
  deriveWidgetState,
  futureTime,
  parseWidgetMeta,
  parseWidgetTarget,
  resolveWidgetSlug,
  widgetEstimateMin,
  widgetStatus,
} from '../widget';

describe('parseWidgetTarget', () => {
  it('trata slug valido como slug', () => {
    expect(parseWidgetTarget('cafe-do-ze')).toEqual({ kind: 'slug', slug: 'cafe-do-ze' });
  });

  it('trata id com maiusculas como queueId', () => {
    expect(parseWidgetTarget('Ab3dE5fG7hIj9KlMnOpQ')).toEqual({
      kind: 'id',
      queueId: 'Ab3dE5fG7hIj9KlMnOpQ',
    });
  });

  it('slug reservado e curto viram queueId', () => {
    expect(parseWidgetTarget('admin')).toEqual({ kind: 'id', queueId: 'admin' });
    expect(parseWidgetTarget('ab')).toEqual({ kind: 'id', queueId: 'ab' });
  });

  it('rejeita vazio, caracteres invalidos e longos demais', () => {
    expect(parseWidgetTarget(undefined)).toEqual({ kind: 'invalid' });
    expect(parseWidgetTarget('')).toEqual({ kind: 'invalid' });
    expect(parseWidgetTarget('a/b')).toEqual({ kind: 'invalid' });
    expect(parseWidgetTarget('a.b')).toEqual({ kind: 'invalid' });
    expect(parseWidgetTarget('a'.repeat(129))).toEqual({ kind: 'invalid' });
  });
});

describe('countPublic', () => {
  it('conta waiting e called e ignora o resto', () => {
    expect(
      countPublic({
        a: { status: 'waiting' },
        b: { status: 'waiting' },
        c: { status: 'called' },
        d: { status: 'served' },
      }),
    ).toEqual({ waiting: 2, called: 1 });
  });

  it('aceita null e undefined', () => {
    expect(countPublic(null)).toEqual({ waiting: 0, called: 0 });
    expect(countPublic(undefined)).toEqual({ waiting: 0, called: 0 });
  });
});

describe('widgetEstimateMin', () => {
  it('usa auto, depois manual, depois 10', () => {
    expect(widgetEstimateMin(2, 5, 8, false)).toBe(15);
    expect(widgetEstimateMin(2, null, 8, false)).toBe(24);
    expect(widgetEstimateMin(2, null, null, false)).toBe(30);
  });

  it('arredonda', () => {
    expect(widgetEstimateMin(1, 4.3, null, false)).toBe(9);
  });

  it('sem fila ou em modo schedule nao estima', () => {
    expect(widgetEstimateMin(0, 5, 8, false)).toBeNull();
    expect(widgetEstimateMin(3, 5, 8, true)).toBeNull();
  });
});

describe('widgetStatus', () => {
  it('ausente vale open, desconhecido vale closed', () => {
    expect(widgetStatus('paused')).toBe('paused');
    expect(widgetStatus('closed')).toBe('closed');
    expect(widgetStatus('open')).toBe('open');
    expect(widgetStatus(undefined)).toBe('open');
    expect(widgetStatus('x')).toBe('closed');
    expect(widgetStatus(3)).toBe('closed');
  });
});

describe('parseWidgetMeta', () => {
  it('deleting, vazio e nao-objeto viram null', () => {
    expect(parseWidgetMeta({ name: 'A', deleting: true })).toBeNull();
    expect(parseWidgetMeta(null)).toBeNull();
    expect(parseWidgetMeta('x')).toBeNull();
  });

  it('aplica filtros de cor e logo e le campos', () => {
    const meta = parseWidgetMeta({
      name: 'Cafe',
      status: 'paused',
      brandColor: '#2563eb',
      logoUrl: 'https://evil.example/x.png',
      avgServiceMinAuto: 4,
      mode: 'schedule',
    });
    expect(meta).toMatchObject({
      name: 'Cafe',
      status: 'paused',
      brandColor: '#2563EB',
      logoUrl: null,
      avgServiceMinAuto: 4,
      scheduled: true,
    });
  });
});

describe('resolveWidgetSlug', () => {
  it('devolve o queueId resolvido', async () => {
    const r = await resolveWidgetSlug('cafe', async () => 'Q123');
    expect(r).toEqual({ kind: 'ok', queueId: 'Q123' });
  });

  it('not-found cai para o proprio valor como queueId', async () => {
    const r = await resolveWidgetSlug('abc123', async () => {
      throw { code: 'functions/not-found' };
    });
    expect(r).toEqual({ kind: 'ok', queueId: 'abc123' });
  });

  it('outros erros viram failed', async () => {
    const r = await resolveWidgetSlug('abc123', async () => {
      throw { code: 'functions/unavailable' };
    });
    expect(r).toEqual({ kind: 'failed' });
  });
});

describe('deriveWidgetState', () => {
  const meta = parseWidgetMeta({ name: 'A' })!;
  const base = {
    resolved: { kind: 'ok', queueId: 'q' } as const,
    authFailed: false,
    listenFailed: false,
    meta,
    tickets: {} as Record<string, { status?: unknown }> | null,
  };

  it('fica em loading ate meta e public chegarem', () => {
    expect(deriveWidgetState({ ...base, meta: undefined, tickets: null })).toEqual({
      phase: 'loading',
    });
    expect(deriveWidgetState({ ...base, tickets: null })).toEqual({ phase: 'loading' });
    expect(deriveWidgetState({ ...base, meta: undefined })).toEqual({ phase: 'loading' });
    expect(deriveWidgetState({ ...base, resolved: { kind: 'pending' }, meta: undefined })).toEqual({
      phase: 'loading',
    });
  });

  it('pronto com contagem', () => {
    const s = deriveWidgetState({ ...base, tickets: { a: { status: 'waiting' } } });
    expect(s).toEqual({ phase: 'ready', meta, counts: { waiting: 1, called: 0 } });
  });

  it('notFound para meta null e slug invalido', () => {
    expect(deriveWidgetState({ ...base, meta: null })).toEqual({ phase: 'notFound' });
    expect(deriveWidgetState({ ...base, resolved: { kind: 'notFound' } })).toEqual({
      phase: 'notFound',
    });
  });

  it('failed para resolucao, auth e leitura', () => {
    expect(deriveWidgetState({ ...base, resolved: { kind: 'failed' } })).toEqual({ phase: 'failed' });
    expect(deriveWidgetState({ ...base, authFailed: true })).toEqual({ phase: 'failed' });
    expect(deriveWidgetState({ ...base, listenFailed: true })).toEqual({ phase: 'failed' });
  });
});

describe('futureTime', () => {
  it('so devolve instantes futuros', () => {
    expect(futureTime(2000, 1000)).toBe(2000);
    expect(futureTime(1000, 1000)).toBeNull();
    expect(futureTime(null, 1000)).toBeNull();
    expect(futureTime(undefined, 1000)).toBeNull();
  });
});
