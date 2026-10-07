const CHANNEL_ID = 'qio_new_entries';
const MAX_NAME = 40;

const STRINGS = {
  pt: { one: (name) => `Nova pessoa na fila: ${name}` },
  en: { one: (name) => `New person in the queue: ${name}` },
  es: { one: (name) => `Nueva persona en la fila: ${name}` },
};

const STALE_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

function normalizeLang(lang) {
  const base = typeof lang === 'string' ? lang.toLowerCase().split(/[-_]/)[0] : '';
  return STRINGS[base] ? base : 'pt';
}

function sanitizeName(name) {
  if (typeof name !== 'string') return '';
  const clean = name.replace(/\s+/g, ' ').trim();
  return clean.length > MAX_NAME ? `${clean.slice(0, MAX_NAME - 1)}…` : clean;
}

function buildNewEntryMessage({ queueId, queueName, entryName, lang }) {
  const l = normalizeLang(lang);
  return {
    notification: {
      title: typeof queueName === 'string' && queueName ? queueName : 'Qio',
      body: STRINGS[l].one(sanitizeName(entryName) || '—'),
    },
    data: { type: 'new-entry', queueId },
    android: {
      priority: 'high',
      collapseKey: queueId,
      notification: { channelId: CHANNEL_ID, tag: queueId },
    },
  };
}

function recipientUids({ ownerUid, operatorUids }) {
  const all = [ownerUid, ...(Array.isArray(operatorUids) ? operatorUids : [])];
  return [...new Set(all.filter((u) => typeof u === 'string' && u.length > 0))];
}

function wantsNewEntryPush(ownerDoc) {
  return ownerDoc?.notifyNewEntries !== false;
}

function isStaleTokenError(code) {
  return STALE_CODES.has(code);
}

function groupTokensByLang(devices) {
  const groups = {};
  for (const d of devices) {
    if (typeof d?.token !== 'string' || d.token.length === 0) continue;
    const lang = normalizeLang(d.lang);
    (groups[lang] ??= []).push(d.token);
  }
  return groups;
}

module.exports = {
  CHANNEL_ID,
  normalizeLang,
  sanitizeName,
  buildNewEntryMessage,
  recipientUids,
  wantsNewEntryPush,
  isStaleTokenError,
  groupTokensByLang,
};
