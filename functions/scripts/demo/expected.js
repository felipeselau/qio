#!/usr/bin/env node
'use strict';

const { buildUniverse, DEFAULT_DAYS, DEFAULT_SEED } = require('./build');
const bi = require('./bi');
const { OPERATORS } = require('./accounts');

const HISTORY_LIMIT = 500;
const PERIODS = [
  { key: '7', label: '7 dias', days: 7 },
  { key: '30', label: '30 dias', days: 30 },
  { key: 'all', label: 'Tudo', days: null },
];

const SHOWCASE = [
  { id: 'demo-padaria-balcao', title: 'Padaria, Balcão (manhã cheia, tarde calma)' },
  { id: 'demo-clinica-exames', title: 'Clínica, Exames (pico das 7 às 9 h)' },
  { id: 'demo-otica-centro-atendimento', title: 'Ótica Loja Centro, Atendimento geral (picos 11-13 h e 17-19 h)', staffing: true },
  { id: 'demo-otica-norte-atendimento', title: 'Ótica Loja Norte, Atendimento geral (crescimento semanal)', staffing: true },
  { id: 'demo-otica-ruaxv-atendimento', title: 'Ótica Loja Rua XV, Atendimento geral (estável, déficit nos picos)', staffing: true },
];

const WEEKDAYS = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

const nameOf = (uid, ownerUid) => {
  if (uid === null || uid === ownerUid) return 'Dono';
  const op = OPERATORS.find((o) => o.uid === uid);
  return op ? op.name.split(' ')[0] : uid;
};

function parseArgs(argv) {
  const opts = { now: Date.now(), seed: DEFAULT_SEED, days: DEFAULT_DAYS, json: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--now') opts.now = Date.parse(argv[(i += 1)]);
    else if (arg === '--seed') opts.seed = String(argv[(i += 1)]);
    else if (arg === '--days') opts.days = Number(argv[(i += 1)]);
    else if (arg === '--json') opts.json = true;
    else throw new Error(`Argumento desconhecido: ${arg}`);
  }
  if (!Number.isFinite(opts.now)) throw new Error('--now inválido');
  return opts;
}

function appWindow(queue, now, days) {
  const latest = bi
    .toRecords(queue.history)
    .sort((a, b) => b.finishedAt - a.finishedAt)
    .slice(0, HISTORY_LIMIT);
  return {
    records: bi.inPeriod(latest, now, days),
    truncated: queue.history.length >= HISTORY_LIMIT,
  };
}

const dayLabel = (day) => {
  const d = new Date(day * bi.DAY);
  return `${String(d.getUTCDate()).padStart(2, '0')}/${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
};

function goalIndicatorSummary(indicator, limit, targetPct) {
  if (indicator.configured === 0) return null;
  const o = indicator.overall;
  return {
    limitMin: limit,
    targetPct,
    evaluated: o.total,
    within: o.ok,
    pctFloor: o.pctFloor,
    met: o.met,
    reliable: o.total >= 5,
    worstOverMin: indicator.worstOverMin,
    worstDay: indicator.worstDay === null ? null : dayLabel(indicator.worstDay),
    daysEvaluated: indicator.days.length,
    missedDays: indicator.missedDays.map((d) => ({ day: dayLabel(d.day), weekday: WEEKDAYS[d.weekday], pctFloor: d.bucket.pctFloor, total: d.bucket.total })),
    missedHours: indicator.missedHours.map((h) => ({ hour: h.hour, pctFloor: h.bucket.pctFloor, total: h.bucket.total })),
  };
}

function goalsSummary(queue, records) {
  const goals = bi.goalsOf(queue.fs.goals);
  if (!bi.hasGoal(goals)) return null;
  const report = bi.computeGoalReport([{ goals, records }]);
  const target = goals.targetPct ?? 80;
  return {
    goals,
    wait: goalIndicatorSummary(report.wait, goals.maxWaitMin, target),
    service: goalIndicatorSummary(report.service, goals.maxServiceMin, target),
  };
}

function staffingSummary(queue, now, records, window) {
  const grid = bi.computeStaffingGrid(records, new Set([queue.ownerUid]));
  const season = bi.computeSeasonality(window, now);
  const flat = grid ? grid.cells.flat() : [];
  return {
    avgServiceMin: grid ? grid.avgServiceMin : null,
    coverageDays: grid ? grid.coverageDays : 0,
    topDeficits: grid ? grid.topDeficits.map((c) => ({ weekday: WEEKDAYS[c.weekday], hour: c.hour, required: c.required, observed: c.observed, arrivals: c.arrivals })) : [],
    slackCells: flat
      .filter((c) => c.required > 0 && c.gap <= -0.25)
      .sort((a, b) => a.gap - b.gap)
      .slice(0, 3)
      .map((c) => ({ weekday: WEEKDAYS[c.weekday], hour: c.hour, required: c.required, observed: c.observed })),
    weekVolumes: season.weeks.map((w) => w.volume),
    trendPct: season.trendPct,
    direction: season.direction,
    recurring: season.recurring.map((c) => ({ weekday: WEEKDAYS[c.weekday], hour: c.hour, weeks: c.weeks, of: c.observedWeeks })),
  };
}

function liveRisk(queue) {
  const goals = bi.goalsOf(queue.fs.goals);
  if (!goals || goals.maxWaitMin === null) return null;
  const waiting = Object.values(queue.entries).filter((e) => e.status === 'waiting').length;
  const auto = queue.meta.avgServiceMinAuto ?? null;
  const manual = queue.fs.avgServiceMin ?? null;
  const panel = bi.estimatedWaitMin(waiting, auto, manual);
  const home = bi.estimatedWaitMin(waiting, null, manual);
  return {
    waiting,
    maxWaitMin: goals.maxWaitMin,
    autoMin: auto,
    manualMin: manual,
    panelEstimateMin: panel,
    panelAtRisk: bi.waitGoalAtRisk(panel, goals),
    homeEstimateMin: home,
    homeAtRisk: bi.waitGoalAtRisk(home, goals),
    joinsToPanelRisk: auto === null && manual === null ? null : Math.max(0, Math.floor(goals.maxWaitMin / bi.effectiveAvgServiceMin(auto, manual)) + 1 - waiting),
    joinsToHomeRisk: manual === null ? null : Math.max(0, Math.floor(goals.maxWaitMin / bi.effectiveAvgServiceMin(null, manual)) + 1 - waiting),
  };
}

function summarize(queue, now, period) {
  const { records } = appWindow(queue, now, period.days);
  const report = bi.buildAbandonmentReport(records);
  const attendants = bi.attendantRows(records, new Set([queue.ownerUid]));
  const left = records.filter((r) => r.result === 'left' && !(r.reason === 'expired' || r.reason === 'closed')).length;
  return {
    period: period.label,
    docs: records.length,
    leftPct: records.length > 0 ? (100 * left) / records.length : null,
    attendants: attendants.rows.map((r) => ({
      name: nameOf(r.attendantId, queue.ownerUid),
      served: r.served,
      volume: r.volume,
      avgServiceMin: r.avgServiceMin,
      deviationPct: r.deviationPct,
      rank: r.rank,
      perHour: r.perHour,
      idlePct: r.idlePct === null ? null : r.idlePct * 100,
    })),
    waitBands: report.waitBands.map((b) => ({
      from: b.startMin,
      to: b.endMin,
      atRisk: b.atRisk,
      left: b.left,
      ratePct: b.rate === null ? null : b.rate * 100,
      per10Pct: b.ratePer10Min === null ? null : Math.min(100, b.ratePer10Min * 100),
    })),
    goals: goalsSummary(queue, records),
    inflectionFromMin: report.inflection ? report.inflection.startMin : null,
    estimateBands: report.estimateBands.map((b) => ({ from: b.startMin, to: b.endMin, total: b.total, left: b.left, ratePct: b.rate === null ? null : b.rate * 100 })),
    accuracy: report.accuracy,
    capacityHours: report.capacityHours,
    peakHours: report.hours
      .filter((h) => h.total > 0)
      .sort((a, b) => b.total - a.total)
      .slice(0, 4)
      .sort((a, b) => a.hour - b.hour)
      .map((h) => ({ hour: h.hour, total: h.total, ratePct: h.rate === null ? null : h.rate * 100, avgWaitMin: h.avgWaitMin })),
  };
}

function build(opts) {
  const universe = buildUniverse({ now: opts.now, seed: opts.seed, days: opts.days, only: ['padaria', 'clinica', 'otica'] });
  return SHOWCASE.map((s) => {
    const queue = universe.queues.find((q) => q.id === s.id);
    return {
      id: s.id,
      title: s.title,
      totalDocs: queue.history.length,
      truncated: queue.history.length >= HISTORY_LIMIT,
      periods: PERIODS.map((p) => summarize(queue, opts.now, p)),
      goals: queue.fs.goals ?? null,
      risk: liveRisk(queue),
      staffing: s.staffing ? staffingSummary(queue, opts.now, appWindow(queue, opts.now, null).records, appWindow(queue, opts.now, null).records) : null,
    };
  });
}

const f1 = (v) => (v === null || v === undefined ? '—' : v.toFixed(1).replace('.', ','));
const f0 = (v) => (v === null || v === undefined ? '—' : String(Math.round(v)));
const signed = (v) => (v === null || v === undefined ? '—' : `${v >= 0 ? '+' : ''}${Math.round(v)}%`);

function bandLabel(b) {
  return b.to === null ? `${b.from}+ min` : `${b.from}-${b.to} min`;
}

const pctText = (v) => (v === null || v === undefined ? '—' : `${v}%`);

function goalLine(label, g) {
  if (!g) return null;
  const verdict = !g.reliable ? 'amostra pequena' : g.met ? 'atingida' : 'não atingida';
  const worst = g.worstOverMin === null ? 'sem violação' : `maior violação +${f0(g.worstOverMin)} min em ${g.worstDay}`;
  const days = g.missedDays.length === 0 ? 'nenhum' : g.missedDays.map((d) => `${d.weekday} ${d.day} (${d.pctFloor}%, ${d.total})`).join(', ');
  const hours = g.missedHours.length === 0 ? 'nenhuma' : g.missedHours.map((h) => `${h.hour} h (${h.pctFloor}%, ${h.total})`).join(', ');
  return `- ${label} até ${g.limitMin} min, alvo ${g.targetPct}%: **${pctText(g.pctFloor)}** (${g.within} de ${g.evaluated}), ${verdict}; ${worst}. Dias não atingidos (${g.missedDays.length}): ${days}. Horas não atingidas: ${hours}.`;
}

function renderGoals(r, pick) {
  const lines = [];
  if (!r.goals) {
    lines.push('Metas: sem meta configurada (a tela mostra o estado "configure").');
    lines.push('');
    return lines;
  }
  lines.push(`Metas (\`goals\` = ${JSON.stringify(r.goals)}), período Tudo (500 mais recentes):`);
  lines.push('');
  for (const line of [goalLine('Espera', pick('all').goals.wait), goalLine('Atendimento', pick('all').goals.service)]) if (line) lines.push(line);
  lines.push('');
  lines.push('Metas por período (espera / atendimento, % dentro do limite):');
  lines.push('');
  lines.push('| Período | Espera | Atendimento |');
  lines.push('| --- | --- | --- |');
  for (const p of r.periods) {
    const cell = (g) => (g ? `${pctText(g.pctFloor)} (${g.evaluated}) ${g.reliable ? (g.met ? 'atingida' : 'não atingida') : 'amostra pequena'}` : '—');
    lines.push(`| ${p.period} | ${cell(p.goals.wait)} | ${cell(p.goals.service)} |`);
  }
  lines.push('');
  if (r.risk) {
    const k = r.risk;
    lines.push(
      `Meta de espera ao vivo: ${k.waiting} esperando, estimativa do painel ${k.panelEstimateMin} min (${f1(k.autoMin)} min automático, ${k.manualMin} min manual), meta ${k.maxWaitMin} min: ` +
        `banner ${k.panelAtRisk ? 'APARECE' : 'não aparece'}; selo da home (só tempo manual) ${k.homeEstimateMin} min: ${k.homeAtRisk ? 'APARECE' : 'não aparece'}. ` +
        `Faltam ${k.joinsToPanelRisk} entrada(s) para o banner e ${k.joinsToHomeRisk} para o selo (com o tempo de hoje).`,
    );
    lines.push('');
  }
  return lines;
}

function renderStaffing(r) {
  const st = r.staffing;
  if (!st) return [];
  const lines = [];
  lines.push(`Planejamento de equipe (tempo médio ${f1(st.avgServiceMin)} min, ocupação-alvo 85%, ${st.coverageDays} dias de base):`);
  lines.push('');
  if (st.topDeficits.length === 0) lines.push('- Maiores déficits: nenhum.');
  else for (const [i, c] of st.topDeficits.entries()) lines.push(`- Déficit ${i + 1}: ${c.weekday} ${c.hour} h, precisa de ${c.required}, tem ${f1(c.observed)} (${f1(c.arrivals)} chegadas/h).`);
  if (st.slackCells.length > 0) lines.push(`- Folga (diferença <= -0,25): ${st.slackCells.map((c) => `${c.weekday} ${c.hour} h (precisa ${c.required}, tem ${f1(c.observed)})`).join('; ')}.`);
  lines.push(`- Sazonalidade (semanas completas, mais antiga primeiro): ${st.weekVolumes.length === 0 ? 'sem dados' : st.weekVolumes.join(', ')}; tendência ${st.trendPct === null ? '—' : `${st.trendPct >= 0 ? '+' : ''}${f1(st.trendPct)}%/semana (${st.direction === 'up' ? 'crescendo' : st.direction === 'down' ? 'caindo' : 'estável'})`}.`);
  lines.push(`- Padrão recorrente: ${st.recurring.length === 0 ? 'nenhum' : st.recurring.map((c) => `${c.weekday} ${c.hour} h (${c.weeks}/${c.of})`).join(', ')}.`);
  lines.push('');
  return lines;
}

function render(results, opts) {
  const lines = [];
  lines.push(`Gerado por \`node functions/scripts/demo/expected.js --now ${new Date(opts.now).toISOString()}\` (seed \`${opts.seed}\`, ${opts.days} dias).`);
  lines.push('');
  for (const r of results) {
    lines.push(`#### ${r.title}`);
    lines.push('');
    lines.push(`\`${r.id}\`: ${r.totalDocs} atendimentos no histórico${r.truncated ? ' (o app lê só os 500 mais recentes)' : ''}.`);
    lines.push('');
    const pick = (key) => r.periods[PERIODS.findIndex((p) => p.key === key)];
    lines.push('Por atendente (período Tudo, como o app mostra):');
    lines.push('');
    lines.push('| Atendente | Atendidos | Tempo médio (min) | Desvio | Atend./h na janela | Ociosidade |');
    lines.push('| --- | ---: | ---: | ---: | ---: | ---: |');
    for (const a of pick('all').attendants) {
      lines.push(`| ${a.name} | ${a.served} | ${f1(a.avgServiceMin)} | ${signed(a.deviationPct)} | ${f1(a.perHour)} | ${a.idlePct === null ? '—' : `${f0(a.idlePct)}%`} |`);
    }
    lines.push('');
    lines.push('Desistência por faixa de espera (Tudo). A tela mostra a coluna "A cada 10 min" (taxa por 10 min, largura mínima 5 min); a proporção simples é só para conferência:');
    lines.push('');
    lines.push('| Faixa | Chegaram à faixa | Desistiram | A cada 10 min (o que a tela mostra) | Proporção simples |');
    lines.push('| --- | ---: | ---: | ---: | ---: |');
    for (const b of pick('all').waitBands) {
      lines.push(`| ${bandLabel(b)} | ${b.atRisk} | ${b.left} | ${b.per10Pct === null ? '—' : `${f0(b.per10Pct)}%`} | ${b.ratePct === null ? '—' : `${f0(b.ratePct)}%`} |`);
    }
    lines.push('');
    lines.push('Desistência por estimativa mostrada (Tudo):');
    lines.push('');
    lines.push('| Estimativa | Pessoas | Desistiram | Taxa |');
    lines.push('| --- | ---: | ---: | ---: |');
    for (const b of pick('all').estimateBands) {
      lines.push(`| ${bandLabel(b)} | ${b.total} | ${b.left} | ${b.ratePct === null ? '—' : `${f0(b.ratePct)}%`} |`);
    }
    lines.push('');
    const acc = pick('all').accuracy;
    lines.push(
      `Ponto de inflexão: ${pick('all').inflectionFromMin === null ? 'nenhum' : `faixa a partir de ${pick('all').inflectionFromMin} min`}. ` +
        `Erro médio da estimativa: ${f1(acc.meanErrorMin)} min (absoluto ${f1(acc.meanAbsErrorMin)}). ` +
        `Card de capacidade (Tudo): ${pick('all').capacityHours.length > 0 ? `horas ${pick('all').capacityHours.join(', ')}` : 'não aparece'}.`,
    );
    lines.push('');
    lines.push('Períodos (atendimentos no período / % desistência / card de capacidade):');
    lines.push('');
    lines.push('| Período | Atendimentos | Desistência | Horas do card |');
    lines.push('| --- | ---: | ---: | --- |');
    for (const p of r.periods) {
      lines.push(`| ${p.period} | ${p.docs} | ${f1(p.leftPct)}% | ${p.capacityHours.length > 0 ? p.capacityHours.join(', ') : '—'} |`);
    }
    lines.push('');
    lines.push('Horas mais movimentadas (Tudo): ' + pick('all').peakHours.map((h) => `${h.hour} h (${h.total}, desist. ${h.ratePct === null ? '—' : `${f0(h.ratePct)}%`}, espera ${f1(h.avgWaitMin)} min)`).join('; ') + '.');
    lines.push('');
    lines.push(...renderGoals(r, pick));
    lines.push(...renderStaffing(r));
  }
  return lines.join('\n');
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const results = build(opts);
  if (opts.json) console.log(JSON.stringify({ now: opts.now, seed: opts.seed, days: opts.days, results }, null, 2));
  else console.log(render(results, opts));
}

if (require.main === module) main();

module.exports = { build, summarize, appWindow, SHOWCASE, PERIODS, HISTORY_LIMIT };
