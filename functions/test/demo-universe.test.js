const test = require('node:test');
const assert = require('node:assert/strict');
const { buildUniverse, scopeOf } = require('../scripts/demo/build');
const { queueStats } = require('../scripts/demo/stats');
const accounts = require('../scripts/demo/accounts');
const { createRng } = require('../scripts/demo/rng');
const { estimateServiceMin, serviceMinutesOf } = require('../src/estimate');
const { publicTicketFor, countWaiting } = require('../src/ticket');
const { normalizeAlerts } = require('../src/alerts');
const { normalizeExpiry } = require('../src/expire');
const { parseSlots, MAX_SLOTS } = require('../src/slots');
const { isValidSlug } = require('../src/slug');

const NOW = Date.parse(process.env.DEMO_TEST_NOW || '2026-10-11T15:30:00Z');
const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;
const PHONE_RE = /^(\(\d{2}\) 9\d{4}-\d{4}|\(\d{2}\) [2-5]\d{3}-\d{4})?$/;

const universe = buildUniverse({ now: NOW });
const byOwner = (key) => universe.queues.filter((q) => q.ownerUid === `demo-${key}`);
const ms = (t) => t.toMillis();
const stats = (key) => byOwner(key).map(queueStats);

function pooledRating(key) {
  const ratings = byOwner(key).flatMap((q) => q.feedback.map((f) => f.data.rating));
  return ratings.reduce((a, b) => a + b, 0) / ratings.length;
}

test('rng: mesma seed gera a mesma sequência e seeds diferentes divergem', () => {
  const a = createRng('x');
  const b = createRng('x');
  const c = createRng('y');
  const seqA = Array.from({ length: 5 }, () => a.next());
  assert.deepEqual(seqA, Array.from({ length: 5 }, () => b.next()));
  assert.notDeepEqual(seqA, Array.from({ length: 5 }, () => c.next()));
});

test('determinismo: mesma seed e mesmo "agora" geram o mesmo universo', () => {
  const again = buildUniverse({ now: NOW });
  assert.equal(again.queues.length, universe.queues.length);
  for (let i = 0; i < universe.queues.length; i += 1) {
    const x = universe.queues[i];
    const y = again.queues[i];
    assert.equal(x.id, y.id);
    assert.equal(x.history.length, y.history.length);
    assert.deepEqual(x.history.slice(0, 30), y.history.slice(0, 30));
    assert.deepEqual(x.history.slice(-30), y.history.slice(-30));
    assert.deepEqual(x.feedback.slice(0, 30), y.feedback.slice(0, 30));
    assert.deepEqual(x.entries, y.entries);
    assert.deepEqual(x.meta, y.meta);
    assert.deepEqual(x.fs, y.fs);
  }
});

test('seed diferente muda os dados', () => {
  const other = buildUniverse({ now: NOW, seed: 'outra', only: ['padaria'] });
  const q = other.queues[0];
  assert.notDeepEqual(q.history.slice(0, 20), universe.queues[0].history.slice(0, 20));
});

test('invariantes de tempo e resultado no history', () => {
  for (const q of universe.queues) {
    const created = ms(q.fs.createdAt);
    for (const { id, data } of q.history) {
      const where = `${q.id}/${id}`;
      assert.ok(['served', 'no_show', 'left'].includes(data.result), where);
      assert.ok(ms(data.joinedAt) >= created, `${where}: antes da criação da fila`);
      assert.ok(ms(data.joinedAt) >= NOW - 121 * DAY, where);
      assert.ok(ms(data.finishedAt) <= NOW, `${where}: no futuro`);
      assert.ok(ms(data.finishedAt) >= ms(data.joinedAt), where);
      assert.ok(data.name.length >= 1 && data.name.length <= 60, where);
      assert.ok(data.phone === null || PHONE_RE.test(data.phone), `${where}: telefone ${data.phone}`);
      if (data.result === 'left') {
        assert.equal(data.calledAt, null, where);
        assert.equal(data.calledBy, null, where);
        assert.equal(serviceMinutesOf(data), null, where);
      } else {
        assert.ok(ms(data.calledAt) >= ms(data.joinedAt), `${where}: calledAt < joinedAt`);
        assert.ok(ms(data.finishedAt) >= ms(data.calledAt), `${where}: finishedAt < calledAt`);
        assert.ok(data.operatorId && data.operatorId === data.calledBy, where);
      }
      if (data.result === 'served') assert.ok(ms(data.finishedAt) > ms(data.calledAt), where);
      if (data.result === 'no_show') {
        assert.equal(serviceMinutesOf(data), null, where);
        assert.ok(ms(data.finishedAt) - ms(data.calledAt) <= 6 * MINUTE, where);
      }
      if (data.recalls !== undefined) assert.ok(Number.isInteger(data.recalls) && data.recalls > 0, where);
      if (data.skips !== undefined) assert.ok(Number.isInteger(data.skips) && data.skips > 0, where);
    }
  }
});

test('tickets únicos por fila por dia e ids únicos', () => {
  for (const q of universe.queues) {
    const ids = new Set();
    const perDay = new Map();
    for (const { id, data } of q.history) {
      assert.ok(!ids.has(id), `${q.id}: id repetido ${id}`);
      ids.add(id);
      const day = id.split('-')[0];
      const set = perDay.get(day) ?? new Set();
      assert.ok(!set.has(data.ticket), `${q.id}: ticket ${data.ticket} repetido em ${day}`);
      set.add(data.ticket);
      perDay.set(day, set);
    }
    for (const entryId of Object.keys(q.entries)) assert.ok(!ids.has(entryId), `${q.id}: entry ${entryId} colide com history`);
    if (!q.fs.expiry?.resetTicketDaily) {
      const tickets = new Set(q.history.map((h) => h.data.ticket));
      assert.equal(tickets.size, q.history.length, `${q.id}: sem reset diário os tickets são globalmente únicos`);
    }
  }
});

test('feedback só para served, com nota e comentário válidos', () => {
  for (const q of universe.queues) {
    const served = new Map(q.history.filter((h) => h.data.result === 'served').map((h) => [h.id, h.data]));
    for (const f of q.feedback) {
      const h = served.get(f.id);
      assert.ok(h, `${q.id}: feedback ${f.id} sem atendimento served`);
      assert.ok(Number.isInteger(f.data.rating) && f.data.rating >= 1 && f.data.rating <= 5);
      assert.ok(typeof f.data.comment === 'string' && f.data.comment.length <= 300);
      assert.ok(ms(f.data.createdAt) >= ms(h.finishedAt));
      assert.ok(ms(f.data.createdAt) <= NOW);
      assert.ok(f.data.uid.startsWith('demo-cli-'));
    }
  }
  const all = universe.queues.flatMap((q) => q.feedback);
  const withComment = all.filter((f) => f.data.comment !== '').length / all.length;
  assert.ok(withComment > 0.2 && withComment < 0.4, `comentários em ${withComment}`);
});

test('estado vivo: waitingCount, public e entries coerentes', () => {
  for (const q of universe.queues) {
    const waiting = Object.values(q.entries).filter((e) => e.status === 'waiting').length;
    assert.equal(q.meta.waitingCount, waiting, q.id);
    assert.equal(countWaiting(q.public), waiting, q.id);
    assert.deepEqual(Object.keys(q.public).sort(), Object.keys(q.entries).sort(), q.id);
    const phones = new Set();
    const tickets = new Set();
    for (const [id, e] of Object.entries(q.entries)) {
      assert.deepEqual(q.public[id], publicTicketFor(e), `${q.id}/${id}`);
      assert.ok(['waiting', 'called'].includes(e.status));
      assert.ok(e.joinedAt <= NOW);
      assert.ok(Number.isInteger(e.ticket) && e.ticket > 0 && !tickets.has(e.ticket));
      tickets.add(e.ticket);
      assert.ok(PHONE_RE.test(e.phone));
      if (e.phone) {
        assert.ok(!phones.has(e.phone), `${q.id}: telefone ativo repetido`);
        phones.add(e.phone);
      }
      if (e.manual) assert.equal(e.uid, undefined);
      else assert.ok(e.uid.startsWith('demo-cli-'));
      if (e.status === 'called') {
        assert.ok(e.calledAt >= e.joinedAt && e.calledAt <= NOW, `${q.id}/${id}`);
        const staff = new Set([q.ownerUid, ...Object.keys(q.operatorUids)]);
        assert.ok(staff.has(e.operatorId), `${q.id}: operador ${e.operatorId}`);
      } else {
        assert.equal(e.calledAt, undefined);
      }
      if (e.recalledAt) assert.ok(e.recalledAt >= e.calledAt && e.recalledAt <= NOW);
    }
    assert.ok(q.lastTicket >= Math.max(0, ...tickets), q.id);
    assert.ok(q.meta.serving <= q.lastTicket, q.id);
    assert.equal(q.meta.nextTicket, 0);
    assert.ok(q.meta.updatedAt <= NOW);
  }
});

test('avgServiceMinAuto = estimate das últimas 20 served', () => {
  for (const q of universe.queues) {
    const served = q.history.filter((h) => h.data.result === 'served');
    const last20 = [...served].sort((a, b) => ms(b.data.finishedAt) - ms(a.data.finishedAt)).slice(0, 20);
    const expected = estimateServiceMin(last20.map((h) => h.data));
    if (expected === null) assert.equal(q.meta.avgServiceMinAuto, undefined, q.id);
    else assert.equal(q.meta.avgServiceMinAuto, expected, q.id);
    if (served.length >= 3) assert.notEqual(q.meta.avgServiceMinAuto, undefined, q.id);
  }
});

test('slots, modo, alertas e expiração válidos conforme as normalizações', () => {
  for (const q of universe.queues) {
    const { fs, meta } = q;
    assert.ok(meta.avgServiceMin >= 1 && meta.avgServiceMin <= 240, q.id);
    assert.ok(fs.name.length >= 1 && fs.name.length <= 60, q.id);
    assert.ok((fs.description ?? '').length <= 300, q.id);
    assert.ok(Number.isInteger(fs.maxWaiting) && fs.maxWaiting >= 0 && fs.maxWaiting <= 1000, q.id);
    assert.ok(/^#[0-9A-Fa-f]{6}$/.test(fs.brandColor), q.id);
    if (fs.mode === 'schedule') {
      assert.ok(fs.slots.length >= 1 && fs.slots.length <= MAX_SLOTS, q.id);
      assert.equal(new Set(fs.slots.map((s) => s.start)).size, fs.slots.length, q.id);
      assert.equal(new Set(fs.slots.map((s) => s.id)).size, fs.slots.length, q.id);
      for (const s of fs.slots) {
        assert.match(s.id, /^[A-Za-z0-9_-]{1,20}$/);
        assert.match(s.start, /^([01]\d|2[0-3]):[0-5]\d$/);
        assert.ok(Number.isInteger(s.capacity) && s.capacity >= 1 && s.capacity <= 50);
      }
      assert.equal(meta.mode, 'schedule');
      assert.equal(parseSlots(meta.slots).length, fs.slots.length, q.id);
      const slotIds = new Set(fs.slots.map((s) => s.id));
      for (const h of q.history) assert.ok(slotIds.has(h.data.slotId), `${q.id}/${h.id}`);
      for (const e of Object.values(q.entries)) {
        assert.ok(slotIds.has(e.slotId), q.id);
        if (!e.skips) assert.equal(e.order, e.slotStart);
      }
    } else {
      assert.equal(fs.slots, undefined);
      assert.equal(meta.mode, undefined);
      for (const h of q.history) assert.equal(h.data.slotId, undefined);
    }
    if (fs.alerts) assert.ok(normalizeAlerts(fs.alerts), `${q.id}: alerts inválido`);
    if (fs.alertState) {
      for (const v of Object.values(fs.alertState)) assert.ok(v < NOW && v > NOW - 7 * DAY);
      assert.ok(fs.alerts?.enabled, q.id);
    }
    if (fs.expiry) {
      const norm = normalizeExpiry(fs.expiry);
      assert.ok(norm, q.id);
      assert.equal(norm.hours, fs.expiry.hours);
      assert.equal(norm.clearOnClose, fs.expiry.clearOnClose);
      assert.equal(norm.resetTicketDaily, fs.expiry.resetTicketDaily);
    }
    if (fs.slug) assert.ok(isValidSlug(fs.slug), fs.slug);
    if (fs.status === 'paused') {
      assert.ok(fs.statusMessage.length <= 120);
      assert.ok(ms(fs.resumeAt) > NOW);
      assert.equal(meta.resumeAt, ms(fs.resumeAt));
    }
    if (fs.status === 'closed' && fs.schedule) assert.ok(meta.opensAt > NOW, q.id);
    assert.equal(meta.status, fs.status);
  }
});

test('limites e prefixo demo: nenhum doc fora do universo', () => {
  const scope = scopeOf(universe);
  for (const uid of scope.uids) assert.ok(uid.startsWith('demo-'), uid);
  for (const email of scope.emails) assert.ok(email.endsWith('@qio.demo'), email);
  for (const id of scope.queueIds) assert.ok(id.startsWith('demo-'), id);
  const ownerUids = new Set(universe.owners.map((o) => o.uid));
  const authUids = new Set(universe.auth.map((a) => a.uid));
  const perOwner = new Map();
  for (const q of universe.queues) {
    assert.ok(ownerUids.has(q.fs.ownerId));
    perOwner.set(q.ownerUid, (perOwner.get(q.ownerUid) ?? 0) + 1);
    for (const uid of Object.keys(q.operatorUids)) assert.ok(authUids.has(uid) && uid.startsWith('demo-'));
    for (const r of q.requests) assert.ok(authUids.has(r.uid));
    for (const h of q.history) for (const uid of [h.data.operatorId, h.data.calledBy]) {
      if (uid) assert.ok(uid === q.ownerUid || q.operatorUids[uid], `${q.id}: ${uid}`);
    }
  }
  for (const [uid, n] of perOwner) assert.ok(n <= 20, `${uid} tem ${n} filas`);
  for (const g of universe.groups) {
    assert.ok(g.id.startsWith('demo-') && ownerUids.has(g.ownerUid));
    assert.ok(g.data.name.length >= 1 && g.data.name.length <= 40);
  }
  const groupIds = new Set(universe.groups.map((g) => g.id));
  for (const q of universe.queues) if (q.fs.groupId) assert.ok(groupIds.has(q.fs.groupId), q.id);
  const queueIds = new Set(scope.queueIds);
  for (const s of universe.slugs) assert.ok(queueIds.has(s.data.queueId) && isValidSlug(s.slug));
  assert.equal(new Set(universe.slugs.map((s) => s.slug)).size, universe.slugs.length);
  for (const i of universe.invites) {
    assert.ok(queueIds.has(i.data.queueId));
    assert.match(i.code, /^[A-HJ-NP-Z2-9]{6}$/);
  }
  assert.equal(new Set(universe.invites.map((i) => i.code)).size, universe.invites.length);
});

test('contas: 7 donos, pelo menos 4 operadores, senha única', () => {
  assert.equal(accounts.OWNERS.length, 7);
  assert.ok(accounts.OPERATORS.length >= 4);
  assert.equal(new Set(universe.auth.map((a) => a.email)).size, universe.auth.length);
  for (const a of universe.auth) assert.ok(a.displayName.length > 0);
  assert.ok(accounts.DEMO_PASSWORD.length >= 6);
  const novo = universe.owners.find((o) => o.uid === 'demo-novo');
  assert.ok(novo);
  assert.equal(byOwner('novo').length, 0);
  assert.equal(byOwner('otica').length, 20);
  assert.equal(universe.groups.filter((g) => g.ownerUid === 'demo-otica').length, 4);
  assert.equal(universe.groups.filter((g) => g.ownerUid === 'demo-clinica').length, 2);
  assert.equal(universe.groups.filter((g) => g.ownerUid === 'demo-cartorio').length, 2);
});

test('operadores: um em donos diferentes, pedido pendente, rejeitado e removido', () => {
  const ownersOf = (uid) => new Set(universe.queues.filter((q) => q.operatorUids[uid]).map((q) => q.ownerUid));
  assert.deepEqual([...ownersOf('demo-operador1')].sort(), ['demo-cartorio', 'demo-clinica']);
  const statuses = new Set(universe.queues.flatMap((q) => q.requests.map((r) => r.data.status)));
  for (const s of ['pending', 'approved', 'rejected', 'removed']) assert.ok(statuses.has(s), s);
  const pending = universe.queues.flatMap((q) => q.requests).find((r) => r.data.status === 'pending');
  assert.equal(pending.uid, 'demo-operador5');
  for (const q of universe.queues) {
    for (const o of q.operators) {
      const req = q.requests.find((r) => r.uid === o.uid);
      assert.equal(req.data.status, 'approved');
    }
  }
  const expired = universe.invites.find((i) => ms(i.data.expiresAt) < NOW);
  assert.ok(expired);
  assert.ok(universe.invites.some((i) => ms(i.data.expiresAt) > NOW));
});

test('padaria: pico de manhã e fim de tarde, ★ ~4,6, ao vivo, truncamento', () => {
  const [balcao] = byOwner('padaria');
  const s = queueStats(balcao);
  assert.ok(s.docs > 500, 'precisa passar de 500 docs para testar o aviso de truncamento');
  assert.ok(s.noShowPct < 4);
  assert.ok(pooledRating('padaria') > 4.4 && pooledRating('padaria') < 4.8, pooledRating('padaria'));
  assert.equal(balcao.fs.slug, 'paopquente');
  assert.ok(balcao.meta.waitingCount >= 5 && balcao.meta.waitingCount <= 8);
  const byHour = new Array(24).fill(0);
  for (const h of balcao.history) byHour[new Date(ms(h.data.joinedAt) - 3 * 60 * MINUTE).getUTCHours()] += 1;
  const peak = byHour[7] + byHour[8] + byHour[17];
  assert.ok(peak > byHour[13] * 3, JSON.stringify(byHour));
  assert.equal(byHour[3], 0);
  const dow = new Array(7).fill(0);
  const days = new Array(7).fill(new Set());
  const seen = Array.from({ length: 7 }, () => new Set());
  for (const h of balcao.history) {
    const d = new Date(ms(h.data.joinedAt) - 3 * 60 * MINUTE);
    dow[d.getUTCDay()] += 1;
    seen[d.getUTCDay()].add(d.toISOString().slice(0, 10));
  }
  const avg = (i) => dow[i] / seen[i].size;
  assert.ok(avg(6) > avg(2) && avg(0) > avg(2));
  const recent = balcao.history.filter((h) => ms(h.data.joinedAt) >= NOW - 30 * DAY).length / 30;
  const before = balcao.history.filter((h) => ms(h.data.joinedAt) < NOW - 30 * DAY).length / 90;
  assert.ok(recent > before * 1.05 && recent < before * 1.3, `${recent} vs ${before}`);
});

test('clínica: no-show 10-18%, pior na segunda, caindo após lembretes, ao vivo variado', () => {
  const rows = byOwner('clinica');
  let ns = 0;
  let attended = 0;
  let monNs = 0;
  let monAtt = 0;
  let olderNs = 0;
  let olderAtt = 0;
  let newerNs = 0;
  let newerAtt = 0;
  for (const q of rows) {
    for (const { data } of q.history) {
      if (data.result === 'left') continue;
      const isNs = data.result === 'no_show' ? 1 : 0;
      ns += isNs;
      attended += 1;
      const d = new Date(ms(data.joinedAt) - 3 * 60 * MINUTE);
      if (d.getUTCDay() === 1) {
        monNs += isNs;
        monAtt += 1;
      }
      if (ms(data.joinedAt) < NOW - 45 * DAY) {
        olderNs += isNs;
        olderAtt += 1;
      } else if (ms(data.joinedAt) > NOW - 30 * DAY) {
        newerNs += isNs;
        newerAtt += 1;
      }
    }
  }
  const pct = (100 * ns) / attended;
  assert.ok(pct >= 10 && pct <= 18, `no-show ${pct}`);
  assert.ok(monNs / monAtt > (ns - monNs) / (attended - monAtt));
  assert.ok(olderNs / olderAtt > (newerNs / newerAtt) * 1.25);
  const byKey = Object.fromEntries(rows.map((q) => [q.key, q]));
  assert.equal(byKey.consultas.fs.mode, 'schedule');
  assert.equal(byKey.consultas.fs.slots.length, 18);
  assert.ok(byKey.consultas.fs.slots.every((s) => s.capacity === 2));
  assert.equal(byKey.pediatria.fs.status, 'paused');
  assert.equal(byKey.pediatria.fs.anonymizePhone, true);
  assert.ok(byKey.pediatria.history.every((h) => h.data.phone === null));
  assert.equal(byKey.resultados.fs.status, 'closed');
  assert.ok(byKey.resultados.meta.opensAt > NOW);
  assert.equal(byKey.resultados.fs.scheduleLastDesired, false);
  assert.ok(byKey.exames.fs.alerts.enabled && byKey.exames.fs.alertState.noShowAt);
  assert.equal(new Set(rows.map((q) => q.fs.groupId)).size, 2);
  const operators = new Set(rows.flatMap((q) => Object.keys(q.operatorUids)));
  assert.equal(operators.size, 3);
  const svc = {};
  for (const q of byKey.consultas.history) {
    if (q.data.result !== 'served') continue;
    const m = serviceMinutesOf(q.data);
    (svc[q.data.operatorId] ??= []).push(m);
  }
  const mean = (a) => a.reduce((x, y) => x + y, 0) / a.length;
  assert.ok(mean(svc['demo-operador3']) > mean(svc['demo-operador1']) * 1.3);
});

test('barbearia: atendimento 25-45 min, sábado lotado, ★ ~4,8, recalls/skips', () => {
  const rows = byOwner('barbearia');
  const agendados = rows.find((q) => q.key === 'agendados');
  const mins = agendados.history.filter((h) => h.data.result === 'served').map((h) => serviceMinutesOf(h.data));
  const mean = mins.reduce((a, b) => a + b, 0) / mins.length;
  assert.ok(mean > 25 && mean < 45, mean);
  const rating = pooledRating('barbearia');
  assert.ok(rating > 4.6 && rating <= 5, rating);
  const perDay = new Map();
  for (const h of agendados.history) {
    const d = new Date(ms(h.data.joinedAt) - 3 * 60 * MINUTE);
    const key = d.toISOString().slice(0, 10);
    perDay.set(key, { dow: d.getUTCDay(), n: (perDay.get(key)?.n ?? 0) + 1 });
  }
  const avgFor = (dow) => {
    const v = [...perDay.values()].filter((x) => x.dow === dow);
    return v.reduce((a, b) => a + b.n, 0) / v.length;
  };
  assert.ok(avgFor(6) > avgFor(2) * 1.3);
  assert.ok(rows.some((q) => q.history.some((h) => h.data.skips > 0)));
  assert.ok(rows.some((q) => q.history.some((h) => h.data.recalls > 0)));
  assert.equal(new Set(rows.flatMap((q) => Object.keys(q.operatorUids))).size, 2);
  assert.ok(rows.some((q) => q.key === 'passagem' && q.fs.mode === undefined));
});

test('cartório: 6 filas, 2 grupos, esperas longas, ★ < 3,8, fila cheia, alertas ativos', () => {
  const rows = byOwner('cartorio');
  assert.equal(rows.length, 6);
  assert.equal(new Set(rows.map((q) => q.fs.groupId)).size, 2);
  const rating = pooledRating('cartorio');
  assert.ok(rating > 3 && rating < 3.8, rating);
  const st = rows.map(queueStats);
  assert.ok(st.some((s) => s.waitP90 > 60), JSON.stringify(st.map((s) => s.waitP90)));
  const limited = rows.filter((q) => q.fs.maxWaiting > 0);
  assert.equal(limited.length, 2);
  assert.ok(limited.some((q) => q.meta.waitingCount >= q.fs.maxWaiting));
  assert.ok(limited.some((q) => q.meta.waitingCount < q.fs.maxWaiting));
  const operators = new Set(rows.flatMap((q) => Object.keys(q.operatorUids)));
  assert.equal(operators.size, 5);
  const certidoes = rows.find((q) => q.key === 'certidoes');
  assert.ok(certidoes.meta.waitingCount * (certidoes.meta.avgServiceMinAuto ?? certidoes.meta.avgServiceMin) > certidoes.fs.alerts.maxWaitMin);
  assert.ok(certidoes.fs.alertState.waitAt > NOW - 30 * MINUTE);
  assert.ok(rows.every((q) => q.fs.deleting === undefined));
  const early = certidoes.history.filter((h) => ms(h.data.joinedAt) < NOW - 90 * DAY);
  const late = certidoes.history.filter((h) => ms(h.data.joinedAt) > NOW - 30 * DAY);
  assert.ok(early.length > 0 && late.length > 0);
});

test('food truck: ~14 dias, rajadas, muitas desistências, fechada agora', () => {
  const [q] = byOwner('foodtruck');
  const s = queueStats(q);
  const first = Math.min(...q.history.map((h) => ms(h.data.joinedAt)));
  assert.ok(NOW - first <= 17 * DAY);
  assert.ok(s.days <= 8, `dias com dados ${s.days}`);
  assert.ok(s.leftPct > 30, `desistências ${s.leftPct}`);
  assert.equal(q.fs.status, 'closed');
  assert.equal(Object.keys(q.entries).length, 0);
  assert.equal(q.meta.waitingCount, 0);
  const dayKeys = [...new Set(q.history.map((h) => Math.floor((NOW - ms(h.data.joinedAt)) / DAY)))].sort((a, b) => a - b);
  assert.ok(dayKeys.length >= 4, `dias com dados ${dayKeys.length}`);
  assert.ok(dayKeys[dayKeys.length - 1] - dayKeys[0] >= 7, 'dois fins de semana distantes');
  assert.ok(dayKeys.some((d, i) => i > 0 && d - dayKeys[i - 1] >= 3), 'buraco entre os dois fins de semana');
});

test('rede ótica: 20 filas em 4 grupos, histórico leve de 30-60 dias, perfis variados', () => {
  const rows = byOwner('otica');
  assert.equal(rows.length, 20);
  assert.equal(new Set(rows.map((q) => q.fs.groupId)).size, 4);
  const spans = rows.map((q) => (NOW - Math.min(...q.history.map((h) => ms(h.data.joinedAt)))) / DAY);
  assert.ok(Math.max(...spans) <= 62 && Math.min(...spans) >= 20, JSON.stringify(spans));
  assert.ok(rows.every((q) => q.history.length < 1500));
  assert.ok(rows.some((q) => q.fs.status === 'paused'));
  assert.ok(rows.some((q) => q.fs.status === 'closed'));
  assert.ok(rows.some((q) => q.fs.mode === 'schedule'));
  assert.ok(rows.some((q) => q.fs.maxWaiting > 0));
});

test('janela de dias respeitada: --days menor reduz o histórico', () => {
  const short = buildUniverse({ now: NOW, days: 30, only: ['padaria'] });
  const q = short.queues[0];
  const oldest = Math.min(...q.history.map((h) => ms(h.data.joinedAt)));
  assert.ok(NOW - oldest <= 31 * DAY);
  assert.ok(q.history.length < universe.queues[0].history.length / 2);
});
