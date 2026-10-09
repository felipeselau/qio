import { describe, expect, it } from 'vitest';
import raw from '../../../../firebase.json?raw';

type Header = { key: string; value: string };
type Config = {
  hosting: {
    headers: { source: string; headers: Header[] }[];
    rewrites: { source: string; destination: string }[];
  };
};

const config: Config = JSON.parse(raw);

describe('firebase.json hosting', () => {
  it('reescreve /w/** para widget.html antes do catch-all', () => {
    const sources = config.hosting.rewrites.map((r) => r.source);
    const w = sources.indexOf('/w/**');
    const all = sources.indexOf('**');
    expect(w).toBeGreaterThanOrEqual(0);
    expect(all).toBeGreaterThan(w);
    expect(config.hosting.rewrites[w].destination).toBe('/widget.html');
  });

  it('frame-ancestors liberado so em /w/**', () => {
    const framing = config.hosting.headers.filter((h) =>
      h.headers.some((x) => /frame-ancestors|x-frame-options/i.test(`${x.key} ${x.value}`)),
    );
    expect(framing.map((h) => h.source)).toEqual(['/w/**']);
  });
});
