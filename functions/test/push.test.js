const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  CHANNEL_ID,
  normalizeLang,
  sanitizeName,
  buildNewEntryMessage,
  recipientUids,
  wantsNewEntryPush,
  isStaleTokenError,
  groupTokensByLang,
} = require('../src/push');

describe('normalizeLang', () => {
  it('aceita pt/en/es com região e cai em pt', () => {
    assert.equal(normalizeLang('en-US'), 'en');
    assert.equal(normalizeLang('es_AR'), 'es');
    assert.equal(normalizeLang('pt-BR'), 'pt');
    assert.equal(normalizeLang('fr'), 'pt');
    assert.equal(normalizeLang(undefined), 'pt');
  });
});

describe('sanitizeName', () => {
  it('limpa espaços e limita o tamanho', () => {
    assert.equal(sanitizeName('  Ana   Souza '), 'Ana Souza');
    assert.equal(sanitizeName('x'.repeat(100)).length, 40);
    assert.equal(sanitizeName(5), '');
  });
});

describe('buildNewEntryMessage', () => {
  it('monta a notificação no idioma do aparelho, sem telefone', () => {
    const m = buildNewEntryMessage({ queueId: 'q1', queueName: 'Balcão', entryName: 'Ana', lang: 'en' });
    assert.equal(m.notification.title, 'Balcão');
    assert.equal(m.notification.body, 'New person in the queue: Ana');
    assert.deepEqual(m.data, { type: 'new-entry', queueId: 'q1' });
    assert.equal(m.android.notification.channelId, CHANNEL_ID);
    assert.equal(m.android.collapseKey, 'q1');
    assert.equal(m.android.priority, 'high');
  });

  it('usa pt por padrão e título de reserva', () => {
    const m = buildNewEntryMessage({ queueId: 'q1', queueName: '', entryName: 'Bia' });
    assert.equal(m.notification.title, 'Qio');
    assert.match(m.notification.body, /Nova pessoa na fila: Bia/);
  });
});

describe('recipientUids', () => {
  it('une dono e operadores sem duplicar nem aceitar lixo', () => {
    assert.deepEqual(recipientUids({ ownerUid: 'a', operatorUids: ['b', 'a', '', null, 'c'] }), ['a', 'b', 'c']);
    assert.deepEqual(recipientUids({ ownerUid: undefined, operatorUids: undefined }), []);
  });
});

describe('wantsNewEntryPush', () => {
  it('é ligado por padrão e só desliga com false explícito', () => {
    assert.equal(wantsNewEntryPush(undefined), true);
    assert.equal(wantsNewEntryPush({}), true);
    assert.equal(wantsNewEntryPush({ notifyNewEntries: true }), true);
    assert.equal(wantsNewEntryPush({ notifyNewEntries: false }), false);
  });
});

describe('isStaleTokenError', () => {
  it('reconhece tokens inválidos', () => {
    assert.equal(isStaleTokenError('messaging/registration-token-not-registered'), true);
    assert.equal(isStaleTokenError('messaging/internal-error'), false);
  });
});

describe('groupTokensByLang', () => {
  it('agrupa por idioma e ignora tokens vazios', () => {
    const g = groupTokensByLang([
      { token: 't1', lang: 'en' },
      { token: 't2', lang: 'en-GB' },
      { token: 't3' },
      { token: '' },
      null,
    ]);
    assert.deepEqual(g, { en: ['t1', 't2'], pt: ['t3'] });
  });
});
