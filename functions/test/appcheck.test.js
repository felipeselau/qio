const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { isEnforced } = require('../src/appcheck');

describe('isEnforced', () => {
  it('desligado por padrão', () => {
    assert.equal(isEnforced('joinQueue', {}), false);
    assert.equal(isEnforced('submitFeedback', {}), false);
  });

  it('usa ENFORCE_APP_CHECK como fallback', () => {
    const env = { ENFORCE_APP_CHECK: 'true' };
    assert.equal(isEnforced('joinQueue', env), true);
    assert.equal(isEnforced('submitFeedback', env), true);
  });

  it('flag específica liga só a sua callable', () => {
    const env = { ENFORCE_APP_CHECK: 'false', ENFORCE_APP_CHECK_JOIN: 'true' };
    assert.equal(isEnforced('joinQueue', env), true);
    assert.equal(isEnforced('submitFeedback', env), false);
  });

  it('flag específica false prevalece sobre ENFORCE_APP_CHECK=true', () => {
    const env = { ENFORCE_APP_CHECK: 'true', ENFORCE_APP_CHECK_FEEDBACK: 'false' };
    assert.equal(isEnforced('joinQueue', env), true);
    assert.equal(isEnforced('submitFeedback', env), false);
  });

  it('valores vazios ou inválidos caem no fallback', () => {
    const env = { ENFORCE_APP_CHECK: 'true', ENFORCE_APP_CHECK_JOIN: '' };
    assert.equal(isEnforced('joinQueue', env), true);
    assert.equal(isEnforced('desconhecida', { ENFORCE_APP_CHECK: 'true' }), true);
  });
});
