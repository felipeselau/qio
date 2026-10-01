const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { serviceMinutesOf, estimateServiceMin } = require('../src/estimate');

const MIN = 60000;
const served = (minutes, finishedAt = 1000 * MIN) => ({
  result: 'served',
  calledAt: finishedAt - minutes * MIN,
  finishedAt,
});

describe('serviceMinutesOf', () => {
  it('calcula minutos entre calledAt e finishedAt', () => {
    assert.equal(serviceMinutesOf(served(5)), 5);
  });

  it('retorna null sem calledAt ou finishedAt', () => {
    assert.equal(serviceMinutesOf({ result: 'served', finishedAt: 10 }), null);
    assert.equal(serviceMinutesOf({ result: 'served', calledAt: null, finishedAt: 10 }), null);
    assert.equal(serviceMinutesOf({ result: 'served', calledAt: 10 }), null);
  });

  it('retorna null para no_show e duração não positiva', () => {
    assert.equal(serviceMinutesOf({ ...served(5), result: 'no_show' }), null);
    assert.equal(serviceMinutesOf({ result: 'served', calledAt: 10, finishedAt: 10 }), null);
    assert.equal(serviceMinutesOf({ result: 'served', calledAt: 20, finishedAt: 10 }), null);
  });

  it('aceita Timestamps com toMillis()', () => {
    const ts = (ms) => ({ toMillis: () => ms });
    const doc = { result: 'served', calledAt: ts(0), finishedAt: ts(4 * MIN) };
    assert.equal(serviceMinutesOf(doc), 4);
  });
});

describe('estimateServiceMin', () => {
  it('retorna null com menos de 3 amostras válidas', () => {
    assert.equal(estimateServiceMin([served(5), served(6)]), null);
    assert.equal(estimateServiceMin([]), null);
  });

  it('ignora docs sem calledAt e no_show na contagem', () => {
    const docs = [
      served(5),
      served(5),
      { result: 'served', finishedAt: 1000 * MIN },
      { ...served(5), result: 'no_show' },
    ];
    assert.equal(estimateServiceMin(docs), null);
    assert.equal(estimateServiceMin([...docs, served(5)]), 5);
  });

  it('descarta outliers acima de 3x a mediana', () => {
    const docs = [served(4), served(5), served(6), served(100)];
    assert.equal(estimateServiceMin(docs), 5);
  });

  it('usa só as 20 amostras mais recentes', () => {
    const recent = Array.from({ length: 20 }, (_, i) => served(10, 5000 * MIN - i * MIN));
    const old = Array.from({ length: 10 }, (_, i) => served(2, 1000 * MIN - i * MIN));
    assert.equal(estimateServiceMin([...old, ...recent]), 10);
  });

  it('calcula média arredondada para 1 casa', () => {
    const docs = [served(1), served(2), served(2)];
    assert.equal(estimateServiceMin(docs), 1.7);
  });

  it('aceita Timestamps com toMillis()', () => {
    const ts = (ms) => ({ toMillis: () => ms });
    const doc = (m) => ({
      result: 'served',
      calledAt: ts(1000 * MIN - m * MIN),
      finishedAt: ts(1000 * MIN),
    });
    assert.equal(estimateServiceMin([doc(3), doc(6), doc(9)]), 6);
  });
});
