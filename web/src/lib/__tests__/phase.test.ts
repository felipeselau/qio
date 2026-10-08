import { describe, expect, it } from 'vitest';
import { derivePhase, shouldClearStoredEntry, type PhaseInput } from '../phase';

const base: PhaseInput = {
  loading: false,
  authed: true,
  failed: false,
  exists: true,
  hasLeft: false,
  metaStatus: 'open',
  myEntryStatus: null,
  hasEntry: false,
  thanked: false,
  feedbackId: null,
};
const p = (o: Partial<PhaseInput>) => derivePhase({ ...base, ...o });
const withEntry = (status: string, o: Partial<PhaseInput> = {}) =>
  p({ hasEntry: true, myEntryStatus: status, ...o });

describe('derivePhase', () => {
  it('is loading until authed, loaded and not failed', () => {
    expect(p({ loading: true })).toBe('loading');
    expect(p({ authed: false })).toBe('loading');
    expect(p({ failed: true })).toBe('loading');
    expect(p({ loading: true, exists: false })).toBe('loading');
  });

  it('is gone when the queue does not exist', () => {
    expect(p({ exists: false })).toBe('gone');
    expect(p({ exists: false, hasLeft: true })).toBe('gone');
  });

  it('shows join for a visitor on an open or paused queue', () => {
    expect(p({})).toBe('join');
    expect(p({ metaStatus: 'paused' })).toBe('join');
    expect(p({ metaStatus: undefined })).toBe('join');
  });

  it('shows closed only when there is no entry', () => {
    expect(p({ metaStatus: 'closed' })).toBe('closed');
    expect(withEntry('waiting', { metaStatus: 'closed' })).toBe('ticket');
    expect(withEntry('called', { metaStatus: 'closed' })).toBe('called');
  });

  it('maps entry statuses', () => {
    expect(withEntry('waiting')).toBe('ticket');
    expect(withEntry('called')).toBe('called');
    expect(withEntry('left')).toBe('left');
  });

  it('shows left after leaving, even if the entry vanished', () => {
    expect(p({ hasLeft: true })).toBe('left');
    expect(withEntry('waiting', { hasLeft: true })).toBe('left');
    expect(p({ hasLeft: true, metaStatus: 'closed' })).toBe('left');
  });

  it('shows feedback then thanks after being served', () => {
    expect(p({ feedbackId: 'e1' })).toBe('feedback');
    expect(p({ feedbackId: 'e1', thanked: true })).toBe('thanks');
    expect(p({ thanked: true })).toBe('thanks');
    expect(p({ feedbackId: 'e1', metaStatus: 'closed' })).toBe('closed');
  });

  it('does not show feedback or thanks while an entry is active', () => {
    expect(withEntry('waiting', { feedbackId: 'e1', thanked: true })).toBe('ticket');
  });

  describe('regression: infinite re-entry after the entry leaves RTDB', () => {
    it('called then entry removed with feedback pending goes to feedback, not join', () => {
      expect(withEntry('called')).toBe('called');
      expect(p({ feedbackId: 'e1' })).toBe('feedback');
    });

    it('goes back to join only after feedback is dismissed', () => {
      expect(p({ feedbackId: null })).toBe('join');
    });

    it('left then removal keeps the left screen until rejoin', () => {
      expect(withEntry('left', { hasLeft: true })).toBe('left');
      expect(p({ hasLeft: true })).toBe('left');
      expect(p({ hasLeft: false })).toBe('join');
    });

    it('closed queue after being served does not reopen the join form', () => {
      expect(p({ metaStatus: 'closed' })).toBe('closed');
    });
  });
});

describe('shouldClearStoredEntry', () => {
  const ok = {
    entryId: 'e1',
    hasEntry: false,
    resolved: true,
    loading: false,
    authed: true,
    storedEntryId: 'e1',
  };

  it('clears when the entry vanished after the first listener value', () => {
    expect(shouldClearStoredEntry(ok)).toBe(true);
  });

  it('does not clear a fresh entry before the first onValue (gap after join)', () => {
    expect(shouldClearStoredEntry({ ...ok, resolved: false })).toBe(false);
  });

  it('does not clear while the entry exists', () => {
    expect(shouldClearStoredEntry({ ...ok, hasEntry: true })).toBe(false);
  });

  it('does not clear while loading, unauthenticated or without entryId', () => {
    expect(shouldClearStoredEntry({ ...ok, loading: true })).toBe(false);
    expect(shouldClearStoredEntry({ ...ok, authed: false })).toBe(false);
    expect(shouldClearStoredEntry({ ...ok, entryId: null })).toBe(false);
  });

  it('does not clear when storage holds a different entry (rejoin)', () => {
    expect(shouldClearStoredEntry({ ...ok, storedEntryId: 'e2' })).toBe(false);
    expect(shouldClearStoredEntry({ ...ok, storedEntryId: null })).toBe(false);
  });
});
