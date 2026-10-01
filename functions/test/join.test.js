const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeName,
  isValidPhone,
  pruneTimestamps,
  isRateLimited,
} = require('../lib/join');

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
