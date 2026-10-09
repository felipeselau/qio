import { describe, expect, it } from 'vitest';
import {
  countPublic,
  futureTime,
  parseWidgetTarget,
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
  it('normaliza valores desconhecidos para open', () => {
    expect(widgetStatus('paused')).toBe('paused');
    expect(widgetStatus('closed')).toBe('closed');
    expect(widgetStatus('open')).toBe('open');
    expect(widgetStatus(undefined)).toBe('open');
    expect(widgetStatus('x')).toBe('open');
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
