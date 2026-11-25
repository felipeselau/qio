const test = require('node:test');
const assert = require('node:assert/strict');
const { buildUniverse } = require('../scripts/demo/build');
const bi = require('../scripts/demo/bi');
const { build: buildExpected, HISTORY_LIMIT } = require('../scripts/demo/expected');

const NOW = Date.parse(process.env.DEMO_TEST_NOW || '2026-10-11T15:30:00Z');
const OTHER_NOWS = ['2026-10-14T20:10:00Z', '2026-11-02T18:45:00Z'].map((d) => Date.parse(d));
const ONLY = ['padaria', 'clinica', 'otica'];
const ANA = 'demo-operador1';
const BRUNO = 'demo-operador2';
const CARLA = 'demo-operador3';
const DIEGO = 'demo-operador6';
const SHOWCASE = ['demo-padaria-balcao', 'demo-clinica-exames', 'demo-otica-centro-atendimento'];
const CENTRO = 'demo-otica-centro-atendimento';
const EXAMES = 'demo-clinica-exames';
const PADARIA = 'demo-padaria-balcao';
const NORTE = 'demo-otica-norte-atendimento';
const RUAXV = 'demo-otica-ruaxv-atendimento';
const CALM_NOW = Date.parse('2026-11-24T17:30:00Z');
const ALL_NOWS = [NOW, ...OTHER_NOWS, Date.parse('2026-11-25T15:00:00Z'), Date.parse('2026-12-06T12:00:00Z')];

const universes = new Map();
function universeAt(now) {
  if (!universes.has(now)) universes.set(now, buildUniverse({ now, only: ONLY }));
  return universes.get(now);
}

const queueOf = (u, id) => u.queues.find((q) => q.id === id);
const recordsOf = (q) => bi.toRecords(q.history);
const latest = (records) => [...records].sort((a, b) => b.finishedAt - a.finishedAt).slice(0, HISTORY_LIMIT);
const byAttendant = (rows) => Object.fromEntries(rows.map((r) => [r.attendantId, r]));

function checkProfiles(u) {
  for (const id of SHOWCASE) {
    const q = queueOf(u, id);
    const all = recordsOf(q);
    for (const [label, records] of [['tudo', all], ['500 recentes', latest(all)]]) {
      const rows = byAttendant(bi.attendantRows(records, new Set([q.ownerUid])).rows);
      for (const uid of [ANA, BRUNO, CARLA, DIEGO]) {
        assert.ok(rows[uid], `${id} (${label}): falta ${uid}`);
        assert.ok(rows[uid].serviceSamples >= 3, `${id} (${label}): ${uid} com ${rows[uid].serviceSamples} amostras`);
      }
      if (label !== 'tudo') continue;
      assert.ok(rows[ANA].avgServiceMin < rows[BRUNO].avgServiceMin * 0.75, `${id}: Ana deveria ser ~0,6x Bruno`);
      assert.ok(rows[CARLA].avgServiceMin > rows[BRUNO].avgServiceMin * 1.3, `${id}: Carla deveria ser ~1,5x Bruno`);
      assert.ok(rows[ANA].deviationPct < -20, id);
      assert.ok(rows[CARLA].deviationPct > 20, id);
      assert.equal(rows[ANA].rank, 1, id);
      const others = [ANA, BRUNO, CARLA].map((uid) => rows[uid].idlePct);
      assert.ok(rows[DIEGO].idlePct >= 0.03, `${id}: ociosidade de Diego ${rows[DIEGO].idlePct}`);
      assert.ok(rows[DIEGO].idlePct > 2.5 * Math.max(...others), `${id}: Diego ${rows[DIEGO].idlePct} vs ${others}`);
    }
  }
}

function checkAbandonment(u) {
  for (const id of ['demo-clinica-exames', 'demo-otica-centro-atendimento']) {
    const q = queueOf(u, id);
    const bands = bi.abandonmentByWait(recordsOf(q)).slice(0, 4);
    const rates = bands.map((b) => b.rate);
    assert.ok(rates.every((r) => r !== null), `${id}: faixa sem taxa`);
    for (let i = 1; i < rates.length; i += 1) assert.ok(rates[i] > rates[i - 1], `${id}: taxa por faixa não cresce ${rates}`);
    assert.ok(rates[0] <= 0.05, `${id}: primeira faixa ${rates[0]}`);
    assert.ok(rates[3] >= 0.3, `${id}: faixa 20-40 min ${rates[3]}`);
    assert.ok(bi.findInflection(bi.abandonmentByWait(latest(recordsOf(q)))), `${id}: sem ponto de inflexão`);

    const est = bi.abandonmentByEstimate(recordsOf(q)).filter((b) => b.rate !== null && b.total >= 50);
    assert.ok(est.length >= 3, id);
    for (let i = 1; i < est.length; i += 1) assert.ok(est[i].rate > est[i - 1].rate, `${id}: estimativa x desistência ${est.map((b) => b.rate)}`);
    assert.ok(est[est.length - 1].rate >= 0.45, `${id}: estimativas altas deveriam desistir mais`);
    assert.ok(est[0].rate <= 0.05, id);
    const acc = bi.estimateAccuracy(recordsOf(q));
    assert.ok(acc.meanAbsErrorMin !== null && acc.meanAbsErrorMin < 15, id);
  }
  const centro = bi.abandonmentByWait(latest(recordsOf(queueOf(u, 'demo-otica-centro-atendimento'))));
  assert.ok(centro[3].rate >= 0.35, `ótica centro 20-40 min: ${centro[3].rate}`);
}

function checkCapacity(u) {
  const hoursOf = (id, windowed = true) => {
    const records = recordsOf(queueOf(u, id));
    return bi.capacitySignalHours(bi.abandonmentByHour(windowed ? latest(records) : records));
  };
  const centro = hoursOf('demo-otica-centro-atendimento');
  assert.ok(centro.includes(12), `centro ${centro}`);
  assert.ok(centro.includes(18), `centro ${centro}`);
  assert.ok(centro.every((h) => [11, 12, 17, 18].includes(h)), `centro ${centro}`);
  assert.ok(hoursOf('demo-clinica-exames').includes(8));
  assert.deepEqual(hoursOf('demo-padaria-balcao', false), []);
  for (const q of u.queues.filter((x) => x.id.startsWith('demo-otica-norte-'))) {
    assert.deepEqual(bi.capacitySignalHours(bi.abandonmentByHour(recordsOf(q))), [], q.id);
  }
}

test('operadores: Ana rápida, Bruno médio, Carla lenta, Diego ocioso em padaria, clínica e ótica', () => {
  checkProfiles(universeAt(NOW));
});

test('desistência cresce com a espera e com a estimativa mostrada', () => {
  checkAbandonment(universeAt(NOW));
});

test('card de capacidade: pico em ótica centro e exames, nada na padaria nem na loja tranquila', () => {
  checkCapacity(universeAt(NOW));
});

test('os padrões se mantêm com outros "agora"', () => {
  for (const now of OTHER_NOWS) {
    const u = universeAt(now);
    checkProfiles(u);
    checkAbandonment(u);
    checkCapacity(u);
  }
});

test('ótica centro: horas de pico concentram a demanda e sexta/sábado enchem', () => {
  const q = queueOf(universeAt(NOW), 'demo-otica-centro-atendimento');
  const records = recordsOf(q);
  const peak = records.filter((r) => [11, 12, 17, 18].includes(bi.spHour(r.joinedAt))).length;
  assert.ok(peak / records.length > 0.85, `pico ${peak}/${records.length}`);

  const perDay = new Map();
  for (const r of records) {
    const key = bi.spDay(r.joinedAt);
    perDay.set(key, (perDay.get(key) ?? 0) + 1);
  }
  const avgFor = (dow) => {
    const days = [...perDay.entries()].filter(([day]) => new Date(day * bi.DAY).getUTCDay() === dow).map(([, n]) => n);
    return days.reduce((a, b) => a + b, 0) / days.length;
  };
  assert.ok(avgFor(6) > avgFor(2) * 1.4, `sábado ${avgFor(6)} vs terça ${avgFor(2)}`);
  assert.ok(avgFor(5) > avgFor(2) * 1.15, `sexta ${avgFor(5)} vs terça ${avgFor(2)}`);

  const padaria = recordsOf(queueOf(universeAt(NOW), 'demo-padaria-balcao'));
  const padariaDays = new Map();
  for (const r of padaria) {
    const key = bi.spDay(r.joinedAt);
    padariaDays.set(key, (padariaDays.get(key) ?? 0) + 1);
  }
  const padariaAvg = (dow) => {
    const days = [...padariaDays.entries()].filter(([day]) => new Date(day * bi.DAY).getUTCDay() === dow).map(([, n]) => n);
    return days.reduce((a, b) => a + b, 0) / days.length;
  };
  assert.ok(padariaAvg(6) > padariaAvg(2) && padariaAvg(5) > padariaAvg(2));
});

test('períodos: a semana recente da ótica centro é pior que o período antigo; loja norte tem poucas desistências', () => {
  const u = universeAt(NOW);
  const centro = recordsOf(queueOf(u, 'demo-otica-centro-atendimento'));
  const leftPct = (list) => list.filter((r) => r.result === 'left').length / list.length;
  const recent = centro.filter((r) => r.joinedAt >= NOW - 7 * bi.DAY);
  const old = centro.filter((r) => r.joinedAt < NOW - 30 * bi.DAY);
  assert.ok(recent.length > 50 && old.length > 50);
  assert.ok(leftPct(recent) > leftPct(old), `${leftPct(recent)} vs ${leftPct(old)}`);

  const norte = recordsOf(queueOf(u, 'demo-otica-norte-atendimento'));
  assert.ok(leftPct(norte) < 0.08, leftPct(norte));
  const norteWindow = latest(norte);
  const counts = [7, 30, null].map((d) => bi.inPeriod(norteWindow, NOW, d).length);
  assert.ok(counts[0] < counts[1] && counts[1] <= counts[2], counts.join('/'));
  assert.ok(counts[1] <= HISTORY_LIMIT && counts[0] > 20, counts.join('/'));
});

test('determinismo: o mesmo universo gera os mesmos indicadores', () => {
  const again = buildUniverse({ now: NOW, only: ONLY });
  for (const id of SHOWCASE) {
    const a = bi.buildAbandonmentReport(recordsOf(queueOf(universeAt(NOW), id)));
    const b = bi.buildAbandonmentReport(recordsOf(queueOf(again, id)));
    assert.deepEqual(a, b, id);
    const ra = bi.attendantRows(recordsOf(queueOf(universeAt(NOW), id)));
    const rb = bi.attendantRows(recordsOf(queueOf(again, id)));
    assert.deepEqual(ra, rb, id);
  }
});

test('expected.js: tabela cobre as filas de referência e bate com o cálculo direto', () => {
  const results = buildExpected({ now: NOW, seed: 'qio-demo-v1', days: 120 });
  assert.equal(results.length, 5);
  const centro = results.find((r) => r.id === 'demo-otica-centro-atendimento');
  const all = centro.periods.find((p) => p.period === 'Tudo');
  assert.equal(all.docs, HISTORY_LIMIT);
  assert.deepEqual(all.capacityHours, bi.capacitySignalHours(bi.abandonmentByHour(latest(recordsOf(queueOf(universeAt(NOW), centro.id))))));
});

test('idempotência: ids de histórico únicos e estimateMin presente nas filas de fila', () => {
  const u = universeAt(NOW);
  for (const id of SHOWCASE) {
    const q = queueOf(u, id);
    assert.equal(new Set(q.history.map((h) => h.id)).size, q.history.length, id);
    assert.ok(q.history.every((h) => typeof h.data.estimateMin === 'number'), id);
  }
});


const goalsOf = (q) => bi.goalsOf(q.fs.goals);
const windowOf = (q) => latest(recordsOf(q));
const goalReport = (q, records = windowOf(q)) => bi.computeGoalReport([{ goals: goalsOf(q), records }]);
const pctOf = (b) => b.ok / b.total;
const SAT = 5;
const FRI = 4;
const PEAK_HOURS = [11, 12, 17, 18];
const PEAK_SPILL_HOURS = [11, 12, 13, 17, 18, 19];

test('metas: seed grava goals válidos só nas filas-chave e deixa filas sem meta', () => {
  const u = universeAt(NOW);
  const withGoals = u.queues.filter((q) => q.fs.goals !== undefined).map((q) => q.id).sort();
  assert.deepEqual(withGoals, [CENTRO, EXAMES, NORTE, PADARIA].sort());
  for (const q of u.queues.filter((x) => x.fs.goals)) {
    const g = q.fs.goals;
    assert.deepEqual(Object.keys(g).sort(), ['maxServiceMin', 'maxWaitMin', 'targetPct']);
    for (const [key, lo, hi] of [['maxWaitMin', 1, 240], ['maxServiceMin', 1, 240], ['targetPct', 50, 100]]) {
      assert.ok(Number.isInteger(g[key]) && g[key] >= lo && g[key] <= hi, `${q.id}.${key}=${g[key]}`);
    }
    assert.ok(bi.hasGoal(bi.goalsOf(g)), q.id);
  }
  const without = u.queues.filter((q) => q.fs.goals === undefined);
  assert.ok(without.length >= 10);
  assert.ok(without.some((q) => q.id === RUAXV), 'Rua XV deve ficar sem meta (estado configure)');
  assert.ok(without.some((q) => q.id === 'demo-clinica-consultas'));
});

test('metas: ótica Centro viola nos picos e em sexta/sábado e cumpre fora do pico', () => {
  for (const now of ALL_NOWS) {
    const q = queueOf(universeAt(now), CENTRO);
    const { wait, service } = goalReport(q);
    assert.equal(wait.configured, 1);
    assert.ok(wait.overall.total >= 300, `avaliados ${wait.overall.total}`);
    assert.equal(wait.overall.met, false);
    assert.ok(wait.overall.pct < 0.65, `espera ${wait.overall.pct}`);
    assert.ok(wait.missedHours.length >= 2);
    assert.ok(wait.missedHours.every((h) => PEAK_SPILL_HOURS.includes(h.hour)), JSON.stringify(wait.missedHours.map((h) => h.hour)));
    assert.ok(wait.missedHours.some((h) => h.hour === 12) && wait.missedHours.some((h) => h.hour === 18));
    const offPeak = wait.hours.filter((h) => !PEAK_SPILL_HOURS.includes(h.hour) && h.bucket.total >= 5);
    assert.ok(offPeak.length >= 1, 'precisa de horas fora do pico com amostra');
    assert.ok(offPeak.every((h) => h.bucket.pct >= 0.8), JSON.stringify(offPeak.map((h) => [h.hour, h.bucket.pct])));

    const evaluated = wait.days.filter((d) => d.bucket.total >= 5);
    const fridaysSaturdays = evaluated.filter((d) => d.weekday === FRI || d.weekday === SAT);
    assert.ok(fridaysSaturdays.length >= 4);
    assert.ok(fridaysSaturdays.every((d) => !d.bucket.met), 'sexta e sábado devem violar');
    const midweek = wait.days.filter((d) => [1, 2, 3].includes(d.weekday) && d.bucket.total >= 2);
    assert.ok(midweek.length >= 6);
    assert.ok(midweek.every((d) => d.bucket.pct >= 0.75), 'terça a quinta devem cumprir');
    assert.ok(wait.missedDays.length >= 4);
    assert.ok(wait.missedDays.every((d) => [0, FRI, SAT, 6].includes(d.weekday)));
    assert.ok(wait.worstOverMin > 15);

    assert.equal(service.overall.met, false);
    assert.ok(service.overall.pct > 0.55 && service.overall.pct < 0.8, `atendimento ${service.overall.pct}`);
  }
});

test('metas: tempo de atendimento da meta é coerente com o perfil de cada atendente', () => {
  const q = queueOf(universeAt(NOW), CENTRO);
  const limit = goalsOf(q).maxServiceMin;
  const share = (uid) => {
    const rows = windowOf(q).filter((r) => r.result === 'served' && r.attendant === uid && r.calledAt != null && r.finishedAt != null);
    assert.ok(rows.length >= 15, `${uid}: ${rows.length}`);
    return rows.filter((r) => (r.finishedAt - r.calledAt) / bi.MINUTE <= limit).length / rows.length;
  };
  assert.ok(share(ANA) >= 0.85, `Ana ${share(ANA)}`);
  assert.ok(share(CARLA) <= 0.6, `Carla ${share(CARLA)}`);
  assert.ok(share(ANA) > share(BRUNO) && share(BRUNO) > share(CARLA));
});

test('metas: exames cumpre na maioria dos dias e falha nas sextas; padaria e Norte cumprem folgado', () => {
  for (const now of ALL_NOWS) {
    const u = universeAt(now);
    const exames = goalReport(queueOf(u, EXAMES)).wait;
    assert.equal(exames.overall.met, true, `exames ${exames.overall.pct}`);
    assert.ok(exames.days.length >= 4, `dias ${exames.days.length}`);
    const full = goalReport(queueOf(u, EXAMES), recordsOf(queueOf(u, EXAMES))).wait;
    const evaluated = full.days.filter((d) => d.bucket.total >= 5);
    assert.ok(evaluated.length >= 60);
    assert.ok(evaluated.filter((d) => d.bucket.met).length >= Math.ceil(evaluated.length * 0.6), 'a maioria dos dias deve cumprir');
    const fridays = evaluated.filter((d) => d.weekday === FRI);
    const others = evaluated.filter((d) => d.weekday !== FRI);
    const avg = (list) => list.reduce((s, d) => s + d.bucket.pct, 0) / list.length;
    assert.ok(avg(fridays) < avg(others) - 0.1, `sexta ${avg(fridays)} vs demais ${avg(others)}`);
    assert.ok(fridays.filter((d) => !d.bucket.met).length >= fridays.length * 0.3, 'parte das sextas deve falhar');
    assert.ok(full.missedDays.length >= 4);

    const padaria = goalReport(queueOf(u, PADARIA));
    assert.ok(padaria.wait.overall.pct >= 0.9, `padaria espera ${padaria.wait.overall.pct}`);
    assert.ok(padaria.service.overall.pct >= 0.88, `padaria atendimento ${padaria.service.overall.pct}`);
    assert.ok(padaria.wait.overall.met && padaria.service.overall.met);

    const norte = goalReport(queueOf(u, NORTE));
    assert.ok(norte.wait.overall.pct >= 0.9 && norte.wait.overall.met, `norte espera ${norte.wait.overall.pct}`);
    assert.ok(norte.service.overall.met);
    assert.ok(norte.wait.missedDays.length <= 3);
  }
});

test('metas ao vivo: Centro começa dentro da meta e o risco aparece com mais gente na fila', () => {
  const q = queueOf(universeAt(CALM_NOW), CENTRO);
  const goals = goalsOf(q);
  const waiting = Object.values(q.entries).filter((e) => e.status === 'waiting').length;
  const auto = q.meta.avgServiceMinAuto;
  const manual = q.fs.avgServiceMin;
  assert.equal(waiting, 1);
  assert.ok(auto > 8 && manual === 6);
  assert.equal(bi.waitGoalAtRisk(bi.estimatedWaitMin(waiting, auto, manual), goals), false);
  assert.equal(bi.waitGoalAtRisk(bi.estimatedWaitMin(waiting + 1, auto, manual), goals), true);
  assert.equal(bi.waitGoalAtRisk(bi.estimatedWaitMin(waiting + 1, null, manual), goals), false);
  assert.equal(bi.waitGoalAtRisk(bi.estimatedWaitMin(waiting + 2, null, manual), goals), true);
  assert.equal(bi.waitGoalAtRisk(15, goals), false);
  assert.equal(bi.waitGoalAtRisk(16, goals), true);
  assert.equal(bi.waitGoalAtRisk(60, null), false);
});

test('metas: fórmulas espelhadas do Dart (esperas, desistência, alvo inteiro, amostra mínima)', () => {
  const T0 = Date.parse('2026-03-02T15:00:00Z');
  const rec = (result, waitMin, extra = {}) => ({
    result,
    reason: extra.reason,
    joinedAt: T0,
    calledAt: result === 'left' ? null : T0 + waitMin * bi.MINUTE,
    finishedAt: result === 'left' ? T0 + waitMin * bi.MINUTE : T0 + (waitMin + (extra.service ?? 5)) * bi.MINUTE,
    attendant: 'x',
    estimateMin: null,
  });
  const goals = { maxWaitMin: 10, maxServiceMin: 6, targetPct: 80 };
  const records = [
    ...Array.from({ length: 7 }, () => rec('served', 10)),
    rec('served', 10, { service: 9 }),
    rec('served', 10.5),
    rec('no_show', 30),
    rec('left', 4),
    rec('left', 25),
    rec('left', 40, { reason: 'expired' }),
    { ...rec('served', 1), joinedAt: 0 },
    { ...rec('served', 2000) },
  ];
  const { wait, service } = bi.computeGoalReport([{ goals, records }]);
  assert.equal(wait.overall.total, 11);
  assert.equal(wait.overall.ok, 8);
  assert.equal(wait.overall.violations, 3);
  assert.equal(wait.overall.pctFloor, 72);
  assert.equal(wait.overall.met, false);
  assert.equal(bi.computeGoalReport([{ goals, records: records.slice(0, 5) }]).wait.overall.met, true);
  assert.equal(service.overall.total, 11);
  assert.equal(service.overall.ok, 10);
  assert.ok(Math.abs(wait.worstOverMin - 20) < 1e-9);
  assert.equal(wait.missedDays.length, 1);
  const few = bi.computeGoalReport([{ goals, records: records.slice(0, 3) }]).wait;
  assert.equal(few.days.length, 1);
  assert.equal(few.missedDays.length, 0);
  assert.equal(bi.computeGoalReport([{ goals: { maxWaitMin: null, maxServiceMin: null, targetPct: 90 }, records }]).queuesWithGoals, 0);
  assert.equal(bi.computeGoalReport([{ goals: { maxWaitMin: 10, maxServiceMin: null, targetPct: null }, records }]).service.configured, 0);
  assert.equal(bi.goalsOf({ maxWaitMin: 0, maxServiceMin: 241, targetPct: 49.5 }).maxWaitMin, null);
  assert.equal(bi.goalsOf({ maxWaitMin: 5 }).targetPct, null);
});

const WEEKDAY_MON = 0;
const cellsOf = (list) => list.map((c) => `${c.weekday}-${c.hour}`);

test('sazonalidade: Norte cresce semana a semana e Rua XV fica estável, com os mesmos picos recorrentes', () => {
  for (const now of ALL_NOWS) {
    const u = universeAt(now);
    for (const id of [NORTE, RUAXV]) {
      const season = bi.computeSeasonality(windowOf(queueOf(u, id)), now);
      assert.equal(season.weeks.length, 8, `${id}: ${season.weeks.length} semanas`);
      assert.ok(season.weeks.every((w) => w.volume >= 10), `${id}: ${season.weeks.map((w) => w.volume)}`);
      const keys = cellsOf(season.recurring);
      for (const cell of [`${WEEKDAY_MON}-12`, `${FRI}-18`, `${SAT}-11`]) assert.ok(keys.includes(cell), `${id} ${cell} em ${keys}`);
      for (const c of season.recurring.filter((x) => keys.slice(0, 3).includes(`${x.weekday}-${x.hour}`))) assert.ok(c.weeks >= 6, `${id}: ${c.weeks}/${c.observedWeeks}`);
    }
    const norte = bi.computeSeasonality(windowOf(queueOf(u, NORTE)), now);
    assert.equal(norte.direction, 'up', `norte ${norte.trendPct}`);
    assert.ok(norte.trendPct >= 5 && norte.trendPct <= 15, `norte ${norte.trendPct}`);
    assert.ok(norte.weeks[7].volume > norte.weeks[0].volume * 1.3, norte.weeks.map((w) => w.volume).join());
    const ruaxv = bi.computeSeasonality(windowOf(queueOf(u, RUAXV)), now);
    assert.equal(ruaxv.direction, 'stable', `rua xv ${ruaxv.trendPct}`);
    assert.ok(Math.abs(ruaxv.trendPct) < 5);
  }
});

test('sazonalidade: janela de 500 documentos cobre 8 semanas completas nas filas esparsas e o corte é conhecido nas densas', () => {
  const u = universeAt(NOW);
  for (const id of [NORTE, RUAXV]) {
    const win = windowOf(queueOf(u, id));
    const oldest = Math.min(...win.map((r) => r.joinedAt));
    assert.ok(NOW - oldest >= 9 * 7 * bi.DAY, `${id}: ${(NOW - oldest) / bi.DAY} dias`);
  }
  const centro = bi.computeSeasonality(windowOf(queueOf(u, CENTRO)), NOW);
  assert.ok(centro.weeks.length < 8);
  const padaria = bi.computeSeasonality(windowOf(queueOf(u, PADARIA)), NOW);
  assert.ok(padaria.insufficient);
});

test('equipe: déficit mensurável nos picos e folga nos horários calmos', () => {
  for (const now of ALL_NOWS) {
    const u = universeAt(now);

    const ruaxv = queueOf(u, RUAXV);
    const grid = bi.computeStaffingGrid(windowOf(ruaxv), new Set([ruaxv.ownerUid]));
    assert.ok(grid.avgServiceMin > 6 && grid.avgServiceMin < 9);
    const top = grid.topDeficits.slice(0, 3);
    assert.deepEqual(cellsOf(top).sort(), [`${WEEKDAY_MON}-12`, `${FRI}-18`, `${SAT}-11`].sort());
    for (const c of top) {
      assert.equal(c.required, 2);
      assert.ok(c.observed <= 1.3, `observado ${c.observed}`);
      assert.ok(c.gap >= 0.7);
    }
    const slack = grid.cells.flat().filter((c) => c.required > 0 && c.gap <= -0.25);
    assert.ok(slack.length >= 3, `folgas ${slack.length}`);
    assert.ok(slack.every((c) => [15, 16].includes(c.hour) && c.weekday >= 1 && c.weekday <= 3));

    const centro = queueOf(u, CENTRO);
    const cg = bi.computeStaffingGrid(windowOf(centro), new Set([centro.ownerUid]));
    const big = cg.topDeficits.filter((c) => c.gap >= 0.75 && c.required >= 2 && PEAK_HOURS.includes(c.hour) && c.weekday !== 6);
    assert.ok(big.length >= 2, JSON.stringify(cg.topDeficits.map((c) => [c.weekday, c.hour, c.gap])));
    assert.ok(cg.topDeficits[0].gap >= 1 && PEAK_HOURS.includes(cg.topDeficits[0].hour));
        assert.ok(big.some((c) => c.weekday === FRI || c.weekday === SAT));
    assert.ok(cg.cells.flat().filter((c) => c.required > 0 && c.gap <= -0.25).length >= 5);

    const norte = queueOf(u, NORTE);
    const ng = bi.computeStaffingGrid(windowOf(norte), new Set([norte.ownerUid]));
    assert.ok(ng.topDeficits.every((c) => c.gap < 0.5));
    assert.ok(ng.cells.flat().some((c) => c.gap <= -0.5));
  }
});

test('equipe: fórmulas espelhadas do Dart (recomendado, observado, ocorrências do dia da semana)', () => {
  const MON = Date.parse('2026-03-02T15:00:00Z');
  const rows = [];
  for (let w = 0; w < 2; w += 1) {
    const base = MON + w * 7 * bi.DAY;
    for (let i = 0; i < 6; i += 1) {
      const joinedAt = base + i * 8 * bi.MINUTE;
      rows.push({ result: 'served', joinedAt, calledAt: joinedAt, finishedAt: joinedAt + 20 * bi.MINUTE, attendant: i % 2 === 0 ? 'a' : 'b', estimateMin: null });
    }
  }
  const grid = bi.computeStaffingGrid(rows, new Set(), 1);
  const cell = grid.cells[0][12];
  assert.equal(grid.avgServiceMin, 20);
  assert.equal(grid.coverageDays, 8);
  assert.equal(cell.arrivals, 6);
  assert.equal(cell.required, 2);
  assert.equal(cell.observed, 2);
  assert.equal(cell.gap, 0);
  const defaults = bi.computeStaffingGrid(rows, new Set());
  assert.equal(defaults.cells[0][12].required, 3);
  assert.equal(defaults.topDeficits[0].weekday, 0);
  assert.equal(defaults.topDeficits[0].hour, 12);
  const exact = bi.computeStaffingGrid(rows.slice(0, 3).map((r, i) => ({ ...r, joinedAt: MON + i * 20 * bi.MINUTE, calledAt: MON + i * 20 * bi.MINUTE, finishedAt: MON + (i + 1) * 20 * bi.MINUTE })), new Set(), 1);
  assert.equal(exact.cells[0][12].required, 1);
  assert.equal(bi.computeStaffingGrid(rows.slice(0, 2), new Set()).avgServiceMin, null);
  assert.equal(bi.computeStaffingGrid([], new Set()), null);
});

test('sazonalidade: fórmulas espelhadas do Dart (tendência linear, recorrência, dados insuficientes)', () => {
  const NOW_MON = Date.parse('2026-03-02T15:00:00Z');
  const rec = (joinedAt) => ({ result: 'served', joinedAt, calledAt: joinedAt, finishedAt: joinedAt, attendant: 'a', estimateMin: null });
  const volumes = [10, 12, 14, 16, 18, 20, 22, 24];
  const records = [];
  volumes.forEach((v, i) => {
    const monday = NOW_MON - (8 - i) * 7 * bi.DAY;
    for (let k = 0; k < v; k += 1) records.push(rec(monday + k * 3 * bi.MINUTE));
  });
  const season = bi.computeSeasonality(records, NOW_MON);
  assert.deepEqual(season.weeks.map((w) => w.volume), volumes);
  assert.ok(Math.abs(season.trendPct - (2 / 17) * 100) < 1e-9);
  assert.equal(season.direction, 'up');
  assert.deepEqual(season.recurring.map((c) => [c.weekday, c.hour, c.weeks]), [[0, 12, 8]]);
  const flat = bi.computeSeasonality(volumes.flatMap((_, i) => Array.from({ length: 10 }, (__, k) => rec(NOW_MON - (8 - i) * 7 * bi.DAY + k * bi.MINUTE))), NOW_MON);
  assert.equal(flat.direction, 'stable');
  assert.equal(bi.computeSeasonality(records.filter((r) => r.joinedAt >= NOW_MON - 3 * 7 * bi.DAY), NOW_MON).weeks.length, 3);
  const short = bi.computeSeasonality(records.filter((r) => r.joinedAt > NOW_MON - 2 * 7 * bi.DAY), NOW_MON);
  assert.ok(short.insufficient);
  assert.equal(short.trendPct, null);
  assert.deepEqual(short.recurring, []);
  assert.deepEqual(bi.computeSeasonality([], NOW_MON).weeks, []);
});

test('expected.js: metas e equipe no resultado, com a mesma janela dos 500 mais recentes', () => {
  const results = buildExpected({ now: NOW, seed: 'qio-demo-v1', days: 120 });
  const by = Object.fromEntries(results.map((r) => [r.id, r]));
  assert.deepEqual(Object.keys(by).sort(), [CENTRO, EXAMES, NORTE, PADARIA, RUAXV].sort());
  assert.equal(by[RUAXV].goals, null);
  assert.equal(by[RUAXV].risk, null);
  const centro = by[CENTRO];
  const all = centro.periods.find((p) => p.period === 'Tudo');
  const direct = goalReport(queueOf(universeAt(NOW), CENTRO));
  assert.equal(all.goals.wait.evaluated, direct.wait.overall.total);
  assert.equal(all.goals.wait.pctFloor, direct.wait.overall.pctFloor);
  assert.equal(all.goals.service.met, direct.service.overall.met);
  assert.equal(centro.staffing.topDeficits.length, 5);
  assert.equal(by[NORTE].staffing.weekVolumes.length, 8);
  assert.equal(by[NORTE].staffing.direction, 'up');
  assert.equal(by[RUAXV].staffing.direction, 'stable');
  assert.ok(centro.risk.waiting >= 0 && centro.risk.maxWaitMin === 15);
  const bands = all.waitBands;
  const direct10 = bi.abandonmentByWait(latest(recordsOf(queueOf(universeAt(NOW), CENTRO))));
  assert.deepEqual(bands.map((b) => b.per10Pct), direct10.map((b) => (b.ratePer10Min === null ? null : Math.min(100, b.ratePer10Min * 100))));
});

test('desistência por faixa: taxa por 10 min usa largura mínima de 5 min e teto de 100%', () => {
  const T0 = Date.parse('2026-03-02T15:00:00Z');
  const rec = (result, waitMin) => ({
    result,
    joinedAt: T0,
    calledAt: result === 'left' ? null : T0 + waitMin * bi.MINUTE,
    finishedAt: T0 + waitMin * bi.MINUTE + (result === 'left' ? 0 : 5 * bi.MINUTE),
    attendant: 'a',
    estimateMin: null,
  });
  const narrow = [...Array.from({ length: 5 }, () => rec('left', 40.2)), ...Array.from({ length: 5 }, () => rec('served', 40.5))];
  const bands = bi.abandonmentByWait(narrow);
  const open = bands[4];
  assert.equal(open.atRisk, 10);
  assert.equal(open.rate, 0.5);
  assert.equal(open.hazardPerMin, 0.5 / 5);
  assert.equal(open.ratePer10Min, 1);
  const mid = bi.abandonmentByWait([...Array.from({ length: 4 }, () => rec('served', 12)), rec('left', 12), ...Array.from({ length: 5 }, () => rec('served', 30))]);
  assert.ok(Math.abs(mid[2].rate - 1 / 10) < 1e-9);
  assert.ok(Math.abs(mid[2].ratePer10Min - 0.1 / 10 * 10) < 1e-9);
});
