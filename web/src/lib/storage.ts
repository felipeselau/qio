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