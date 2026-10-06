const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_COMMENT_LENGTH,
  normalizeRating,
  normalizeComment,
  isValidId,
  buildFeedbackDoc,
} = require('../src/feedback');

describe('normalizeRating', () => {
  it('aceita inteiros de 1 a 5', () => {
    for (const n of [1, 2, 3, 4, 5]) assert.equal(normalizeRating(n), n);
  });

  it('rejeita fora da faixa, fracionários e não numéricos', () => {
    for (const v of [0, 6, -1, 2.5, '3', null, undefined, NaN]) {
      assert.equal(normalizeRating(v), null);
    }
  });
});

describe('normalizeComment', () => {
  it('vazio quando ausente', () => {
    assert.equal(normalizeComment(undefined), '');
    assert.equal(normalizeComment(null), '');
  });

  it('apara espaços', () => {
    assert.equal(normalizeComment('  ótimo  '), 'ótimo');
  });

  it('rejeita tipo errado e texto longo demais', () => {
    assert.equal(normalizeComment(5), null);
    assert.equal(normalizeComment('a'.repeat(MAX_COMMENT_LENGTH + 1)), null);
    assert.equal(normalizeComment('a'.repeat(MAX_COMMENT_LENGTH)).length, MAX_COMMENT_LENGTH);
  });
});

describe('isValidId', () => {
  it('aceita ids do push do RTDB', () => {
    assert.equal(isValidId('-OabC_123xyz'), true);
  });

  it('rejeita vazio, tipo errado e caracteres de path', () => {
    for (const v of ['', 5, null, 'a/b', 'a.b', 'a#b', 'a$b', 'a[b', 'a]b']) {
      assert.equal(isValidId(v), false);
    }
  });
});

describe('buildFeedbackDoc', () => {
  it('monta o documento', () => {
    assert.deepEqual(buildFeedbackDoc({ rating: 4, comment: 'ok', uid: 'u' }, 123), {
      rating: 4,
      comment: 'ok',
      uid: 'u',
      createdAt: 123,
    });
  });
});
