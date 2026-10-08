import { describe, expect, it } from 'vitest';
import { feedbackErrorKey, joinErrorKey } from '../joinErrors';

describe('joinErrorKey', () => {
  it.each([
    ['functions/already-exists', 'errors.alreadyExists'],
    ['functions/resource-exhausted', 'errors.resourceExhausted'],
    ['functions/failed-precondition', 'errors.failedPrecondition'],
    ['functions/invalid-argument', 'errors.invalidArgument'],
    ['functions/not-found', 'errors.notFound'],
    ['functions/unauthenticated', 'errors.securityCheckFailed'],
  ])('maps %s', (code, key) => {
    expect(joinErrorKey({ code })).toBe(key);
  });

  it('maps queue-full on resource-exhausted', () => {
    expect(
      joinErrorKey({ code: 'functions/resource-exhausted', details: { reason: 'queue-full' } }),
    ).toBe('errors.queueFull');
  });

  it('keeps resource-exhausted for other reasons', () => {
    expect(
      joinErrorKey({ code: 'functions/resource-exhausted', details: { reason: 'rate' } }),
    ).toBe('errors.resourceExhausted');
  });

  it.each([
    ['slot-full', 'errors.slotFull'],
    ['slot-required', 'errors.reloadPage'],
    ['slot-invalid', 'errors.reloadPage'],
    ['slot-passed', 'errors.slotPassed'],
  ])('maps slot reason %s', (reason, key) => {
    expect(joinErrorKey({ code: 'functions/failed-precondition', details: { reason } })).toBe(key);
  });

  it('falls back to joinFailed', () => {
    expect(joinErrorKey({ code: 'functions/internal' })).toBe('errors.joinFailed');
    expect(joinErrorKey(null)).toBe('errors.joinFailed');
    expect(joinErrorKey(new Error('x'))).toBe('errors.joinFailed');
  });
});

describe('feedbackErrorKey', () => {
  it('treats failed-precondition as done', () => {
    expect(feedbackErrorKey({ code: 'functions/failed-precondition' })).toBeNull();
  });
  it('maps unauthenticated and others', () => {
    expect(feedbackErrorKey({ code: 'functions/unauthenticated' })).toBe(
      'errors.securityCheckFailed',
    );
    expect(feedbackErrorKey({ code: 'functions/internal' })).toBe('errors.feedbackFailed');
    expect(feedbackErrorKey(undefined)).toBe('errors.feedbackFailed');
  });
});
