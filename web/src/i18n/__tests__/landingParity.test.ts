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

  it('has three steps per story', () => {
    expect(pt.landing.stories.client.steps).toHaveLength(3);
    expect(pt.landing.stories.owner.steps).toHaveLength(3);
  });
});
