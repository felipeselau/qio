import { describe, expect, it } from 'vitest';
import en from '../locales/en.json';
import es from '../locales/es.json';
import pt from '../locales/pt.json';

function shape(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(shape);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([k, v]) => [k, shape(v)]),
    );
  }
  return typeof value;
}

describe('landing copy', () => {
  it('has the same structure in every language', () => {
    expect(shape(en.landing)).toEqual(shape(pt.landing));
    expect(shape(es.landing)).toEqual(shape(pt.landing));
  });

  it('has one image alt per highlight', () => {
    expect(pt.landing.highlights.items).toHaveLength(5);
    for (const item of pt.landing.highlights.items) expect(item.alt.length).toBeGreaterThan(0);
  });
});
