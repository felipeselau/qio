import { describe, expect, it } from 'vitest';
import { ownerAppUrl } from '../landing';

describe('ownerAppUrl', () => {
  it('returns null when missing or blank', () => {
    expect(ownerAppUrl(undefined)).toBeNull();
    expect(ownerAppUrl('')).toBeNull();
    expect(ownerAppUrl('   ')).toBeNull();
  });

  it('accepts https urls', () => {
    expect(ownerAppUrl(' https://play.google.com/store/apps/details?id=x ')).toBe(
      'https://play.google.com/store/apps/details?id=x',
    );
  });

  it('rejects non-https and invalid urls', () => {
    expect(ownerAppUrl('http://example.com')).toBeNull();
    expect(ownerAppUrl('javascript:alert(1)')).toBeNull();
    expect(ownerAppUrl('not a url')).toBeNull();
  });
});
