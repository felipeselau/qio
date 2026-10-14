import { describe, expect, it } from 'vitest';
import raw from '../../../../firebase.json?raw';

type Header = { key: string; value: string };
type Site = {
  site: string;
  public: string;
  headers: { source: string; headers: Header[] }[];
  rewrites: { source: string; destination: string }[];
};
type Config = { hosting: Site[] };

const config: Config = JSON.parse(raw);
const siteOf = (name: string): Site => {
  const found = config.hosting.find((s) => s.site === name);
  if (!found) throw new Error(`site ${name} ausente`);
  return found;
};
const hosting = siteOf('qio');
const ownerApp = siteOf('qio-app');

describe('firebase.json hosting', () => {
  it('reescreve /w/** para widget.html antes do catch-all', () => {
    const sources = hosting.rewrites.map((r) => r.source);
    const w = sources.indexOf('/w/**');
    const all = sources.indexOf('**');
    expect(w).toBeGreaterThanOrEqual(0);
    expect(all).toBeGreaterThan(w);
    expect(hosting.rewrites[w].destination).toBe('/widget.html');
  });

  it('frame-ancestors liberado so em /w/**', () => {
    const framing = hosting.headers.filter((h) =>
      h.headers.some((x) => /frame-ancestors|x-frame-options/i.test(`${x.key} ${x.value}`)),
    );
    expect(framing.map((h) => h.source)).toEqual(['/w/**']);
  });

  it('o site do cliente continua publicando web/dist', () => {
    expect(hosting.public).toBe('web/dist');
  });
});

describe('firebase.json hosting do app do dono (qio-app)', () => {
  it('publica o build web do Flutter', () => {
    expect(ownerApp.public).toBe('app/build/web');
    expect(ownerApp.rewrites).toEqual([{ source: '**', destination: '/index.html' }]);
  });

  it('nunca pode ser embutido em iframe', () => {
    const all = ownerApp.headers.find((h) => h.source === '**');
    const values = Object.fromEntries((all?.headers ?? []).map((x) => [x.key, x.value]));
    expect(values['Content-Security-Policy']).toBe("frame-ancestors 'none'");
    expect(values['X-Frame-Options']).toBe('DENY');
  });

  it('nao usa cache imutavel em arquivos sem hash no nome', () => {
    const values = ownerApp.headers.flatMap((h) => h.headers.map((x) => x.value));
    expect(values.some((v) => /immutable/.test(v))).toBe(false);
    const noCache = ownerApp.headers
      .filter((h) => h.headers.some((x) => x.value === 'no-cache'))
      .map((h) => h.source);
    expect(noCache).toEqual(
      expect.arrayContaining(['/index.html', '/flutter_bootstrap.js', '/main.dart.js']),
    );
  });
});
