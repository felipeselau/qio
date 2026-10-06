const KEY = 'qio:entries';

type StoredEntry = { queueId: string; entryId: string };

function read(): StoredEntry[] {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function write(entries: StoredEntry[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(entries));
  } catch {
    // ignore
  }
}

export function getStoredEntryId(queueId: string): string | null {
  return read().find((e) => e.queueId === queueId)?.entryId ?? null;
}

export function storeEntryId(queueId: string, entryId: string) {
  const entries = read().filter((e) => e.queueId !== queueId);
  entries.push({ queueId, entryId });
  write(entries);
}

export function clearStoredEntryId(queueId: string) {
  write(read().filter((e) => e.queueId !== queueId));
}

const FEEDBACK_KEY = 'qio:feedback';

function readFeedback(): StoredEntry[] {
  try {
    const raw = localStorage.getItem(FEEDBACK_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeFeedback(entries: StoredEntry[]) {
  try {
    localStorage.setItem(FEEDBACK_KEY, JSON.stringify(entries));
  } catch {
    // ignore
  }
}

export function getPendingFeedback(queueId: string): string | null {
  return readFeedback().find((e) => e.queueId === queueId)?.entryId ?? null;
}

export function storePendingFeedback(queueId: string, entryId: string) {
  const entries = readFeedback().filter((e) => e.queueId !== queueId);
  entries.push({ queueId, entryId });
  writeFeedback(entries);
}

export function clearPendingFeedback(queueId: string) {
  writeFeedback(readFeedback().filter((e) => e.queueId !== queueId));
}
