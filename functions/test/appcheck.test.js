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

  it('flags específicas toleram caixa e espaços', () => {
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK_JOIN: 'TRUE' }), true);
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK_JOIN: ' true ' }), true);
    assert.equal(
      isEnforced('joinQueue', { ENFORCE_APP_CHECK: 'true', ENFORCE_APP_CHECK_JOIN: 'False' }),
      false,
    );
    assert.equal(
      isEnforced('submitFeedback', { ENFORCE_APP_CHECK: 'true', ENFORCE_APP_CHECK_FEEDBACK: ' FALSE ' }),
      false,
    );
  });

  it('valor específico estranho cai no fallback', () => {
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK_JOIN: 'yes' }), false);
    assert.equal(
      isEnforced('joinQueue', { ENFORCE_APP_CHECK: 'true', ENFORCE_APP_CHECK_JOIN: 'yes' }),
      true,
    );
  });

  it('flag geral só liga com true (trim e caixa)', () => {
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK: ' TRUE ' }), true);
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK: 'yes' }), false);
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK: '1' }), false);
    assert.equal(isEnforced('joinQueue', { ENFORCE_APP_CHECK: '' }), false);
  });
});
