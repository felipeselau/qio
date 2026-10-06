const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { MAX_ALLOWED_WAITING, normalizeMaxWaiting, isQueueFull } = require('../src/capacity');

describe('normalizeMaxWaiting', () => {
  it('trata ausente, inválido e negativo como sem limite', () => {
    for (const v of [undefined, null, '5', 2.5, -1, NaN, 0]) {
      assert.equal(normalizeMaxWaiting(v), 0);
    }
  });

  it('mantém inteiros válidos e limita o teto', () => {
    assert.equal(normalizeMaxWaiting(30), 30);
    assert.equal(normalizeMaxWaiting(MAX_ALLOWED_WAITING + 50), MAX_ALLOWED_WAITING);
  });
});

describe('isQueueFull', () => {
  it('nunca lota sem limite', () => {
    assert.equal(isQueueFull(0, 999), false);
    assert.equal(isQueueFull(undefined, 5), false);
  });

  it('lota quando a contagem alcança o limite', () => {
    assert.equal(isQueueFull(3, 2), false);
    assert.equal(isQueueFull(3, 3), true);
    assert.equal(isQueueFull(3, 4), true);
  });
});
