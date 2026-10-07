const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeAlerts,
  startOfDaySaoPaulo,
  lastActivityOf,
  mapLimit,
  evaluateAlerts,
  stateAfter,
  buildAlertMessage,
  buildAlertPush,
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
  it('cooldown abaixo de 5 cai no padrão', () => {
    const c = normalizeAlerts({ enabled: true, idleMin: 10, cooldownMin: 1 });
    assert.equal(c.cooldownMin, 30);
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
  it('usa o maior entre updatedAt da meta e a entrada mais antiga em espera', () => {
    assert.equal(lastActivityOf({ updatedAt: 300, waitingOrders: [200, 500] }), 300);
    assert.equal(lastActivityOf({ updatedAt: 100, waitingOrders: [200, 500] }), 200);
  });
  it('sem updatedAt usa a entrada mais antiga', () => {
    assert.equal(lastActivityOf({ waitingOrders: [500, 200] }), 200);
  });
  it('só com updatedAt usa ele', () => {
    assert.equal(lastActivityOf({ updatedAt: 70, waitingOrders: [] }), 70);
  });
  it('sem sinal devolve null', () => {
    assert.equal(lastActivityOf({ waitingOrders: [] }), null);
  });
  it('fila andando com entries antigas já removidas não alerta', () => {
    const lastActivityAt = lastActivityOf({
      updatedAt: NOW - 2 * MIN,
      waitingOrders: [NOW - 90 * MIN],
    });
    assert.deepEqual(evaluateAlerts(base({ waiting: 1, lastActivityAt })), []);
  });
  it('fila parada de verdade alerta', () => {
    const lastActivityAt = lastActivityOf({
      updatedAt: NOW - 40 * MIN,
      waitingOrders: [NOW - 90 * MIN],
    });
    const r = evaluateAlerts(base({ waiting: 1, lastActivityAt }));
    assert.deepEqual(r, [{ rule: 'idle', value: 40, limit: 15 }]);
  });
  it('pessoa que acabou de entrar numa fila ociosa não alerta', () => {
    const lastActivityAt = lastActivityOf({
      updatedAt: NOW - 120 * MIN,
      waitingOrders: [NOW - MIN],
    });
    assert.deepEqual(evaluateAlerts(base({ waiting: 1, lastActivityAt })), []);
  });
});

describe('mapLimit', () => {
  it('processa tudo respeitando a concorrência', async () => {
    let running = 0;
    let peak = 0;
    const seen = [];
    await mapLimit([1, 2, 3, 4, 5, 6, 7], 3, async (n) => {
      running++;
      peak = Math.max(peak, running);
      await new Promise((r) => setTimeout(r, 5));
      seen.push(n);
      running--;
    });
    assert.equal(seen.length, 7);
    assert.ok(peak <= 3);
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

describe('buildAlertPush', () => {
  it('monta payload com tipo, tag por fila e regra', () => {
    const m = buildAlertPush({
      queueId: 'q1',
      queueName: 'Loja',
      rule: 'idle',
      vars: { value: 20, limit: 15 },
      lang: 'en',
    });
    assert.equal(m.notification.title, 'Loja');
    assert.equal(m.notification.body, buildAlertMessage('idle', { value: 20, limit: 15 }, 'en'));
    assert.deepEqual(m.data, { type: 'queue-alert', queueId: 'q1', rule: 'idle' });
    assert.equal(m.android.notification.tag, 'q1-idle');
    assert.equal(m.android.notification.channelId, 'qio_new_entries');
  });
  it('sem nome usa Qio', () => {
    const m = buildAlertPush({ queueId: 'q', rule: 'wait', vars: { value: 1, limit: 1 } });
    assert.equal(m.notification.title, 'Qio');
  });
});
