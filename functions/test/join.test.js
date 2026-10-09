const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
  rateLimitFromEnv,
  nameKey,
  namesMatch,
  pickClaimable,
  claimEntryUpdate,
  CLAIM_RATE_LIMIT,
} = require('../src/join');

describe('normalizeName', () => {
  it('faz trim', () => {
    assert.equal(normalizeName('  Ana  '), 'Ana');
  });

  it('rejeita vazio e só espaços', () => {
    assert.equal(normalizeName(''), null);
    assert.equal(normalizeName('   '), null);
  });

  it('rejeita não string', () => {
    assert.equal(normalizeName(undefined), null);
    assert.equal(normalizeName(12), null);
  });

  it('aceita 60 e rejeita 61 caracteres', () => {
    assert.equal(normalizeName('a'.repeat(60)), 'a'.repeat(60));
    assert.equal(normalizeName('a'.repeat(61)), null);
  });

  it('mede o tamanho depois do trim', () => {
    assert.equal(normalizeName(` ${'a'.repeat(60)} `), 'a'.repeat(60));
  });
});

describe('isValidPhone', () => {
  it('aceita vazio', () => {
    assert.equal(isValidPhone(''), true);
  });

  it('aceita celular e fixo', () => {
    assert.equal(isValidPhone('(11) 91234-5678'), true);
    assert.equal(isValidPhone('(11) 3333-4444'), true);
  });

  it('rejeita formatos inválidos', () => {
    assert.equal(isValidPhone('11912345678'), false);
    assert.equal(isValidPhone('(11)91234-5678'), false);
    assert.equal(isValidPhone('(11) 123-4567'), false);
    assert.equal(isValidPhone('(11) 91234-56789'), false);
    assert.equal(isValidPhone('<script>'), false);
    assert.equal(isValidPhone(' (11) 91234-5678'), false);
    assert.equal(isValidPhone('(11) 91234-5678\n'), false);
  });

  it('rejeita não string', () => {
    assert.equal(isValidPhone(undefined), false);
    assert.equal(isValidPhone(null), false);
    assert.equal(isValidPhone(11912345678), false);
  });
});

describe('pruneTimestamps', () => {
  const now = 1_000_000;
  const windowMs = 600_000;

  it('remove antigos e mantém os da janela', () => {
    const result = pruneTimestamps([now - windowMs - 1, now - windowMs, now - 10, now], now, windowMs);
    assert.deepEqual(result, [now - 10, now]);
  });

  it('trata entrada inválida', () => {
    assert.deepEqual(pruneTimestamps(null, now), []);
    assert.deepEqual(pruneTimestamps(undefined, now), []);
    assert.deepEqual(pruneTimestamps(['x', now - 1], now), [now - 1]);
  });
});

describe('isRateLimited', () => {
  const now = 10_000_000;

  it('permite até 3 tentativas', () => {
    assert.equal(isRateLimited([], now), false);
    assert.equal(isRateLimited([now - 1, now - 2], now), false);
  });

  it('bloqueia na 4a tentativa dentro da janela', () => {
    assert.equal(isRateLimited([now - 1, now - 2, now - 3], now), true);
  });

  it('ignora tentativas fora da janela', () => {
    const old = now - 10 * 60 * 1000 - 1;
    assert.equal(isRateLimited([old, old, old], now), false);
  });

  it('respeita opções customizadas', () => {
    assert.equal(isRateLimited([now - 1], now, { max: 1, windowMs: 1000 }), true);
  });
});

describe('rateLimitFromEnv', () => {
  it('usa os defaults sem variáveis', () => {
    assert.deepEqual(rateLimitFromEnv({}), { max: 3, windowMs: 10 * 60 * 1000 });
    assert.deepEqual(rateLimitFromEnv(), { max: 3, windowMs: 10 * 60 * 1000 });
  });

  it('lê max e janela em minutos', () => {
    assert.deepEqual(
      rateLimitFromEnv({ JOIN_RATE_LIMIT_MAX: '20', JOIN_RATE_LIMIT_WINDOW_MIN: '1' }),
      { max: 20, windowMs: 60 * 1000 },
    );
  });

  it('ignora valores inválidos', () => {
    assert.deepEqual(
      rateLimitFromEnv({ JOIN_RATE_LIMIT_MAX: 'abc', JOIN_RATE_LIMIT_WINDOW_MIN: '-5' }),
      { max: 3, windowMs: 10 * 60 * 1000 },
    );
    assert.deepEqual(rateLimitFromEnv({ JOIN_RATE_LIMIT_MAX: '0' }).max, 3);
  });
});

describe('namesMatch', () => {
  it('ignora acento, caixa, bordas e espaços repetidos', () => {
    assert.equal(nameKey('  JOÃO   da  Silva '), 'joao da silva');
    assert.equal(namesMatch('José Álvares', 'jose   alvares'), true);
  });

  it('diferencia nomes distintos e vazios', () => {
    assert.equal(namesMatch('Ana', 'Ana Maria'), false);
    assert.equal(namesMatch('', ''), false);
    assert.equal(namesMatch('Ana', null), false);
  });
});

describe('pickClaimable', () => {
  const entries = [
    { entryId: 'a', uid: 'u1', name: 'Ana Souza', status: 'waiting', joinedAt: 2 },
    { entryId: 'b', uid: 'u2', name: 'ana souza', status: 'called', joinedAt: 1 },
    { entryId: 'c', uid: 'u3', name: 'Ana Souza', status: 'served', joinedAt: 0 },
  ];

  it('escolhe a ativa mais antiga com nome igual', () => {
    assert.equal(pickClaimable(entries, 'ANA  souza', 'novo').entryId, 'b');
  });

  it('devolve null se o nome diverge', () => {
    assert.equal(pickClaimable(entries, 'Bia', 'novo'), null);
  });

  it('ignora entries do próprio uid e inativas', () => {
    assert.equal(pickClaimable(entries, 'Ana Souza', 'u1').entryId, 'b');
    assert.equal(pickClaimable([entries[2]], 'Ana Souza', 'novo'), null);
    assert.equal(pickClaimable(null, 'Ana', 'novo'), null);
  });
});

describe('claimEntryUpdate', () => {
  const entry = {
    uid: 'old',
    ticket: 7,
    name: 'Ana',
    phone: '(11) 91234-5678',
    status: 'waiting',
    joinedAt: 5,
    order: 9,
    fcmToken: 'tok',
  };

  it('troca o uid, limpa o fcmToken e mantém o resto', () => {
    const out = claimEntryUpdate(entry, 'old', 'new');
    assert.equal(out.uid, 'new');
    assert.equal('fcmToken' in out, false);
    assert.equal(out.ticket, 7);
    assert.equal(out.joinedAt, 5);
    assert.equal(out.order, 9);
    assert.equal(entry.uid, 'old');
  });

  it('aborta se o dono mudou ou a entry não está ativa', () => {
    assert.equal(claimEntryUpdate(entry, 'other', 'new'), undefined);
    assert.equal(claimEntryUpdate({ ...entry, status: 'left' }, 'old', 'new'), undefined);
  });

  it('repassa null (palpite inicial da transação)', () => {
    assert.equal(claimEntryUpdate(null, 'old', 'new'), null);
  });

  it('limite de reivindicação é 3 por 10 min', () => {
    assert.deepEqual(CLAIM_RATE_LIMIT, { max: 3, windowMs: 600000 });
  });
});
