export type Phase =
  | 'loading'
  | 'join'
  | 'ticket'
  | 'called'
  | 'left'
  | 'closed'
  | 'gone'
  | 'feedback'
  | 'thanks';

export type PhaseInput = {
  loading: boolean;
  authed: boolean;
  failed: boolean;
  exists: boolean;
  hasLeft: boolean;
  metaStatus: string | null | undefined;
  myEntryStatus: string | null | undefined;
  hasEntry: boolean;
  thanked: boolean;
  feedbackId: string | null;
};

export function derivePhase(i: PhaseInput): Phase {
  if (i.loading || !i.authed || i.failed) return 'loading';
  if (!i.exists) return 'gone';
  if (i.hasLeft) return 'left';
  if (i.metaStatus === 'closed' && !i.hasEntry) return 'closed';
  if (!i.hasEntry && i.thanked) return 'thanks';
  if (!i.hasEntry && i.feedbackId) return 'feedback';
  if (!i.hasEntry) return 'join';
  if (i.myEntryStatus === 'called') return 'called';
  if (i.myEntryStatus === 'left') return 'left';
  return 'ticket';
}

export function shouldClearStoredEntry(i: {
  entryId: string | null;
  hasEntry: boolean;
  resolved: boolean;
  loading: boolean;
  authed: boolean;
  storedEntryId: string | null;
}): boolean {
  return (
    !!i.entryId &&
    !i.hasEntry &&
    i.resolved &&
    !i.loading &&
    i.authed &&
    i.storedEntryId === i.entryId
  );
}
