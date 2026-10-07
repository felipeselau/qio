const { normalizeLang } = require('./push');

const TEXT = {
  pt: {
    calledTitle: 'É a sua vez!',
    called: (ticket, queue) => `Senha #${ticket}: dirija-se ao atendimento (${queue})`,
    nextTitle: 'Você é o próximo',
    next: (queue) => `Fique por perto: a próxima senha em ${queue} é a sua.`,
  },
  en: {
    calledTitle: "It's your turn!",
    called: (ticket, queue) => `Ticket #${ticket}: please go to the service desk (${queue})`,
    nextTitle: "You're next",
    next: (queue) => `Stay close: you are next in ${queue}.`,
  },
  es: {
    calledTitle: '¡Es tu turno!',
    called: (ticket, queue) => `Turno #${ticket}: dirígete a la atención (${queue})`,
    nextTitle: 'Eres el siguiente',
    next: (queue) => `Quédate cerca: eres el siguiente en ${queue}.`,
  },
};

function queueLabel(name) {
  return typeof name === 'string' && name.trim() ? name.trim() : 'Qio';
}

function webpushFor(queueId) {
  return { fcmOptions: { link: `https://qio.web.app/q/${queueId}` } };
}

function buildCalledMessage({ token, ticket, queueName, queueId, lang }) {
  const t = TEXT[normalizeLang(lang)];
  return {
    token,
    notification: {
      title: t.calledTitle,
      body: t.called(ticket ?? '', queueLabel(queueName)),
    },
    data: { type: 'called', queueId },
    webpush: webpushFor(queueId),
  };
}

function buildNextMessage({ token, queueName, queueId, lang }) {
  const t = TEXT[normalizeLang(lang)];
  return {
    token,
    notification: { title: t.nextTitle, body: t.next(queueLabel(queueName)) },
    data: { type: 'next', queueId },
    webpush: webpushFor(queueId),
  };
}

function orderKey(entry) {
  if (typeof entry.order === 'number') return entry.order;
  if (typeof entry.joinedAt === 'number') return entry.joinedAt;
  return 0;
}

function pickNextWaiting(entries) {
  const waiting = Object.entries(entries ?? {})
    .map(([id, e]) => ({ id, ...e }))
    .filter((e) => e.status === 'waiting');
  waiting.sort((a, b) => orderKey(a) - orderKey(b) || (a.ticket ?? 0) - (b.ticket ?? 0));
  return waiting[0] ?? null;
}

function advancedFromWaiting(before, after) {
  return before?.status === 'waiting' && (!after || after.status !== 'waiting');
}

module.exports = {
  buildCalledMessage,
  buildNextMessage,
  pickNextWaiting,
  advancedFromWaiting,
};
