const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { logError, scrub } = require('../src/log');

function fakeLogger() {
  const calls = [];
  return { calls, error: (msg, payload) => calls.push({ msg, payload }) };
}

describe('scrub', () => {
  it('remove chaves de PII em qualquer nível, ignorando caixa', () => {
    const out = scrub({
      queueId: 'q1',
      name: 'Ana',
      Phone: '(11) 99999-9999',
      fcmToken: 'abc',
      token: 'def',
      nested: { entry: { name: 'Bia', ticket: 3 }, list: [{ phone: 'x', n: 1 }] },
    });
    assert.deepEqual(out, {
      queueId: 'q1',
      nested: { entry: { ticket: 3 }, list: [{ n: 1 }] },
    });
  });

  it('mantém primitivos', () => {
    assert.equal(scrub(5), 5);
    assert.equal(scrub(null), null);
  });
});

describe('logError', () => {
  it('registra evento, erro e contexto sem PII', () => {
    const logger = fakeLogger();
    const err = Object.assign(new Error('boom'), { code: 'x' });
    logError('joinQueue failed', err, { queueId: 'q1', name: 'Ana', phone: '1' }, logger);
    assert.equal(logger.calls.length, 1);
    const { msg, payload } = logger.calls[0];
    assert.equal(msg, 'joinQueue failed');
    assert.equal(payload.event, 'joinQueue failed');
    assert.equal(payload.queueId, 'q1');
    assert.equal(payload.error.message, 'boom');
    assert.equal(payload.error.code, 'x');
    assert.equal('name' in payload, false);
    assert.equal('phone' in payload, false);
  });

  it('aceita erro não-Error e ctx ausente', () => {
    const logger = fakeLogger();
    logError('evt', 'texto', undefined, logger);
    assert.equal(logger.calls[0].payload.error.message, 'texto');
  });

  it('mascara telefone, e-mail e token na mensagem', () => {
    const logger = fakeLogger();
    const token = 'a'.repeat(60);
    logError(
      'evt',
      new Error(`falha (11) 99999-9999 ana@exemplo.com ${token}`),
      {},
      logger,
    );
    const { message } = logger.calls[0].payload.error;
    assert.equal(message, 'falha [phone] [email] [token]');
  });

  it('trunca mensagem e stack', () => {
    const logger = fakeLogger();
    const err = new Error('m '.repeat(1000));
    err.stack = 's '.repeat(3000);
    logError('evt', err, {}, logger);
    const { message, stack } = logger.calls[0].payload.error;
    assert.equal(message.length, 500);
    assert.equal(stack.length, 2000);
  });

  it('ctx não sobrescreve event nem error', () => {
    const logger = fakeLogger();
    logError('real', new Error('boom'), { event: 'fake', error: 'fake' }, logger);
    const { payload } = logger.calls[0];
    assert.equal(payload.event, 'real');
    assert.equal(payload.error.message, 'boom');
  });
});

describe('logAppCheck', () => {
  const { appCheckStatus, logAppCheck } = require('../src/log');

  it('appCheckStatus distingue presença do token validado', () => {
    assert.equal(appCheckStatus({ app: { appId: 'x' } }), 'present');
    assert.equal(appCheckStatus({}), 'absent');
    assert.equal(appCheckStatus(undefined), 'absent');
  });

  it('grava só evento, callable e status, sem dados do request', () => {
    const calls = [];
    const logger = { info: (msg, payload) => calls.push({ msg, payload }) };
    logAppCheck(
      'joinQueue',
      { app: { appId: 'x' }, data: { name: 'Ana', phone: '(11) 99999-9999' }, auth: { uid: 'u' } },
      logger,
    );
    assert.deepEqual(calls, [
      {
        msg: 'appcheck',
        payload: { event: 'appcheck', callable: 'joinQueue', appCheck: 'present' },
      },
    ]);
  });
});
