import { describe, expect, it } from 'vitest';
import { firebaseConfig } from '../src/firebaseConfig.ts';
import { renderServiceWorker, SW_PLACEHOLDER } from './swConfig.ts';

describe('renderServiceWorker', () => {
  const template = `firebase.initializeApp(${SW_PLACEHOLDER});\nconst a = 1;`;

  it('substitui o placeholder pelo config serializado', () => {
    const out = renderServiceWorker(template, firebaseConfig);
    expect(out).not.toContain(SW_PLACEHOLDER);
    const match = out.match(/initializeApp\(([\s\S]*?)\);/);
    expect(JSON.parse(match![1])).toEqual(firebaseConfig);
  });

  it('omite valores indefinidos', () => {
    const out = renderServiceWorker(template, { apiKey: 'k', measurementId: undefined });
    expect(out).not.toContain('measurementId');
    expect(out).toContain('"apiKey": "k"');
  });

  it('falha sem placeholder', () => {
    expect(() => renderServiceWorker('nada', firebaseConfig)).toThrow();
  });
});
