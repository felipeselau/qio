const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeAlerts,
  startOfDaySaoPaulo,
  lastActivityOf,
  evaluateAlerts,
  stateAfter,
  buildAlertMessage,
  wantsAlertPush,
} = require('../src/alerts');

const MIN = 60000;
const NOW = Date.UTC(2026, 9, 7, 15, 0, 0);

function base(over = {}) {
  return {
    config: { enabled: true, maxWaitMin: 30, maxNoShowPct: 40, idleMin: 15, cooldownMin: 30 },
    state: {},
    now: NOW,
    status: 'open',
    waiting: 0,
    avgServiceMin: 5,
    noShowToday: 0,
    servedToday: 0,
    lastActivityAt: NOW,
    ...over,
  };
}

describe('normalizeAlerts', () => {
  it('desligado ou sem limites devolve null', () => {
    assert.equal(normalizeAlerts(undefined), null);
    assert.equal(normalizeAlerts({ enabled: false, maxWaitMin: 30 }), null);
    assert.equal(normalizeAlerts({ enabled: true }), null);
  });
  it('descarta limites fora do intervalo e aplica cooldown padrão', () => {
    const c = normalizeAlerts({ enabled: true, maxWaitMin: 500, idleMin: 2, maxNoShowPct: 50 });
    assert.deepEqual(c, { maxWaitMin: null, maxNoShowPct: 50, idleMin: null, cooldownMin: 30 });
  });
});

describe('regra wait', () => {
  it('dispara acima do limite', () => {
    const r = evaluateAlerts(base({ waiting: 7 }));
    assert.deepEqual(r, [{ rule: 'wait', value: 35, limit: 30 }]);
  });
  it('não dispara no limite exato', () => {
    assert.deepEqual(evaluateAlerts(base({ waiting: 6 })), []);
  });
  it('usa 10 min quando não há estimativa', () => {
    const r = evaluateAlerts(base({ waiting: 4, avgServiceMin: null }));
    assert.equal(r[0].value, 40);
  });
});

describe('regra noShow', () => {
  it('dispara com taxa >= limite', () => {
    const r = evaluateAlerts(base({ noShowToday: 4, servedToday: 6 }));
    assert.deepEqual(r, [{ rule: 'noShow', value: 40, limit: 40 }]);
  });
  it('não dispara abaixo do limite', () => {
    assert.deepEqual(evaluateAlerts(base({ noShowToday: 3, servedToday: 7 })), []);
  });
  it('exige amostra mínima de 5', () => {
    assert.deepEqual(evaluateAlerts(base({ noShowToday: 4, servedToday: 0 })), []);
    assert.equal(evaluateAlerts(base({ noShowToday: 5, servedToday: 0 })).length, 1);
  });
});

describe('regra idle', () => {
  it('dispara com gente esperando e sem atividade', () => {
    const r = evaluateAlerts(base({ waiting: 1, lastActivityAt: NOW - 16 * MIN }));
    assert.deepEqual(r, [{ rule: 'idle', value: 16, limit: 15 }]);
  });
  it('não dispara sem ninguém esperando', () => {
    assert.deepEqual(evaluateAlerts(base({ waiting: 0, lastActivityAt: NOW - 60 * MIN })), []);
  });
  it('não dispara dentro do limite', () => {
    assert.deepEqual(evaluateAlerts(base({ waiting: 1, lastActivityAt: NOW - 15 * MIN })), []);
  });
});

describe('cooldown e status', () => {
  const hot = { waiting: 7, noShowToday: 5, servedToday: 5, lastActivityAt: NOW - 30 * MIN };
  it('dispara as três e respeita cooldown por regra', () => {
    assert.equal(evaluateAlerts(base(hot)).length, 3);
    const state = { waitAt: NOW - 10 * MIN, noShowAt: NOW - 31 * MIN };
    const r = evaluateAlerts(base({ ...hot, state }));
    assert.deepEqual(r.map((x) => x.rule).sort(), ['idle', 'noShow']);
  });
  it('cooldown personalizado', () => {
    const config = { enabled: true, maxWaitMin: 30, cooldownMin: 5 };
    const state = { waitAt: NOW - 6 * MIN };
    assert.equal(evaluateAlerts(base({ config, state, waiting: 7 })).length, 1);
  });
  it('pausada ou fechada não alerta', () => {
    assert.deepEqual(evaluateAlerts(base({ ...hot, status: 'paused' })), []);
    assert.deepEqual(evaluateAlerts(base({ ...hot, status: 'closed' })), []);
  });
  it('desligado não alerta', () => {
    assert.deepEqual(
      evaluateAlerts(base({ ...hot, config: { enabled: false, maxWaitMin: 1 } })),
      [],
    );
  });
  it('stateAfter grava só as regras disparadas', () => {
    const s = stateAfter({ waitAt: 1 }, [{ rule: 'idle' }], NOW);
    assert.deepEqual(s, { waitAt: 1, idleAt: NOW });
  });
});

describe('startOfDaySaoPaulo', () => {
  it('meia-noite de SP é 03:00 UTC', () => {
    assert.equal(startOfDaySaoPaulo(Date.UTC(2026, 9, 7, 15)), Date.UTC(2026, 9, 7, 3));
  });
  it('02:59 UTC ainda pertence ao dia anterior em SP', () => {
    assert.equal(startOfDaySaoPaulo(Date.UTC(2026, 9, 7, 2, 59)), Date.UTC(2026, 9, 6, 3));
  });
  it('03:00 UTC vira o dia', () => {
    assert.equal(startOfDaySaoPaulo(Date.UTC(2026, 9, 7, 3, 0)), Date.UTC(2026, 9, 7, 3));
  });
});

describe('lastActivityOf', () => {
  it('é o maior entre última chamada e entrada mais antiga em espera', () => {
    assert.equal(lastActivityOf({ calledAts: [100, 300], waitingJoinedAts: [200, 500] }), 300);
    assert.equal(lastActivityOf({ calledAts: [100], waitingJoinedAts: [200, 500] }), 200);
  });
  it('sem chamadas usa a entrada mais antiga', () => {
    assert.equal(lastActivityOf({ calledAts: [], waitingJoinedAts: [500, 200] }), 200);
  });
  it('sem dados devolve null', () => {
    assert.equal(lastActivityOf({ calledAts: [], waitingJoinedAts: [] }), null);
  });
});

describe('buildAlertMessage', () => {
  const v = { value: 35, limit: 30 };
  it('cobre pt/en/es para cada regra', () => {
    for (const rule of ['wait', 'noShow', 'idle']) {
      const texts = ['pt', 'en', 'es'].map((l) => buildAlertMessage(rule, v, l));
      assert.equal(new Set(texts).size, 3);
      texts.forEach((t) => assert.ok(t.includes('35') && t.includes('30')));
    }
  });
  it('idioma desconhecido cai em pt', () => {
    assert.equal(buildAlertMessage('wait', v, 'fr'), buildAlertMessage('wait', v, 'pt'));
  });
});

describe('wantsAlertPush', () => {
  it('padrão ligado', () => {
    assert.equal(wantsAlertPush(undefined), true);
    assert.equal(wantsAlertPush({ notifyAlerts: false }), false);
  });
});
