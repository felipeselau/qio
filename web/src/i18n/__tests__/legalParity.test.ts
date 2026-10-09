import { describe, expect, it } from 'vitest';
import { loadLegal } from '../legal';

describe('legal bundles', () => {
  it.each([
    ['pt', 'Me avise quando abrir'],
    ['en', 'Notify me when it opens'],
    ['es', 'Avísame cuando abra'],
  ] as const)('%s cita o pedido de aviso na coleta e na retenção', async (lang, phrase) => {
    const bundle = await loadLegal(lang);
    const items = bundle.privacy.sections.flatMap((s) => s.items ?? []);
    expect(items.filter((i) => i.includes(phrase))).toHaveLength(2);
  });
});
