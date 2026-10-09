const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizePhone,
  maskPhone,
  phoneForms,
  hashPhone,
  normalizeMode,
  nextDsrRateState,
  DSR_RATE_LIMIT,
  collectPages,
  chunk,
  toCsv,
  auditDoc,
  findCustomerData,
  exportCustomerData,
  eraseCustomerData,
} = require('../src/dsr');
const { isEnforced } = require('../src/appcheck');

function fakeDeps({ queues, history = {}, feedback = {}, entries = {}, failOn } = {}) {
  const calls = [];
  const logs = [];
  const state = {
    history: structuredClone(history),
    feedback: structuredClone(feedback),
    entries: structuredClone(entries),
  };
  const matches = (forms, phone) => forms.includes(phone);
  return {
    calls,
    logs,
    state,
    listOwnedQueues: async () => queues,
    pageHistory: async (queueId, forms, afterId, limit) => {
      calls.push(['pageHistory', queueId, forms]);
      const docs = Object.entries(state.history[queueId] ?? {})
        .filter(([, d]) => matches(forms, d.phone))
        .map(([id, data]) => ({ id, data }))
        .sort((a, b) => (a.id < b.id ? -1 : 1))
        .filter((d) => !afterId || d.id > afterId);
      return docs.slice(0, limit);
    },
    getFeedback: async (queueId, ids) =>
      ids
        .filter((id) => state.feedback[queueId]?.[id])
        .map((id) => ({ id, data: state.feedback[queueId][id] })),
    findEntries: async (queueId, forms) =>
      Object.entries(state.entries[queueId] ?? {})
        .filter(([, d]) => matches(forms, d.phone))
        .map(([id, data]) => ({ id, data })),
    deleteHistory: async (queueId, ids) => {
      if (failOn === queueId) throw new Error('boom');
      calls.push(['deleteHistory', queueId, ids]);
      ids.forEach((id) => delete state.history[queueId][id]);
    },
    anonymizeHistory: async (queueId, ids) => {
      calls.push(['anonymizeHistory', queueId, ids]);
      ids.forEach((id) => {
        state.history[queueId][id].name = 'Anônimo';
        state.history[queueId][id].phone = null;
      });
    },
    deleteFeedback: async (queueId, ids) => {
      calls.push(['deleteFeedback', queueId, ids]);
      ids.forEach((id) => delete state.feedback[queueId][id]);
    },
    clearFeedbackComments: async (queueId, ids) => {
      calls.push(['clearFeedbackComments', queueId, ids]);
      ids.forEach((id) => {
        state.feedback[queueId][id].comment = '';
      });
    },
    removeEntries: async (queueId, ids) => {
      calls.push(['removeEntries', queueId, ids]);
      ids.forEach((id) => delete state.entries[queueId][id]);
    },
    writeLog: async (uid, doc) => {
      logs.push([uid, doc]);
    },
  };
}

const MASKED = '(11) 99999-9999';
const DIGITS = '11999999999';

function seed() {
  return {
    queues: [
      { id: 'q1', name: 'Balcão' },
      { id: 'q2', name: 'Caixa' },
      { id: 'q3', name: 'Vazia' },
    ],
    history: {
      q1: {
        h1: { name: 'Ana', phone: MASKED, result: 'served', ticket: 1, finishedAt: 2000, joinedAt: 1000 },
        h2: { name: 'Bia', phone: '(11) 88888-8888', result: 'served', ticket: 2, finishedAt: 3000 },
      },
      q2: {
        h3: { name: 'Ana', phone: DIGITS, result: 'no_show', ticket: 3, finishedAt: 5000 },
      },
      q3: {},
    },
    feedback: {
      q1: { h1: { rating: 4, comment: 'ótimo, "bom"', uid: 'c1' } },
      q2: {},
    },
    entries: {
      q1: { e1: { name: 'Ana', phone: MASKED, status: 'waiting', ticket: 9, joinedAt: 7000 } },
    },
  };
}

describe('normalizePhone e formas', () => {
  it('normaliza só dígitos e valida 10 a 11', () => {
    assert.equal(normalizePhone('(11) 99999-9999'), DIGITS);
    assert.equal(normalizePhone('1133334444'), '1133334444');
    for (const bad of ['', '123', '119999999999', 'abc', null, undefined, 5, {}]) {
      assert.equal(normalizePhone(bad), null);
    }
  });

  it('gera máscara de 10 e 11 dígitos e busca nas duas formas', () => {
    assert.equal(maskPhone('1133334444'), '(11) 3333-4444');
    assert.equal(maskPhone(DIGITS), MASKED);
    assert.deepEqual(phoneForms(DIGITS), [MASKED, DIGITS]);
    assert.deepEqual(phoneForms('1133334444'), ['(11) 3333-4444', '1133334444']);
  });

  it('hash não contém o telefone e depende do uid', () => {
    const a = hashPhone(DIGITS, 'u1');
    assert.match(a, /^[0-9a-f]{32}$/);
    assert.ok(!a.includes(DIGITS));
    assert.notEqual(a, hashPhone(DIGITS, 'u2'));
    assert.notEqual(a, hashPhone(DIGITS, 'u1', 'pepper'));
  });

  it('modo aceita só delete e anonymize', () => {
    assert.equal(normalizeMode('delete'), 'delete');
    assert.equal(normalizeMode('anonymize'), 'anonymize');
    assert.equal(normalizeMode('x'), null);
    assert.equal(normalizeMode(undefined), null);
  });
});

describe('limite de taxa', () => {
  it('permite 20 por hora e depois limita', () => {
    let ts = [];
    const now = 1_000_000;
    for (let i = 0; i < 20; i += 1) {
      const s = nextDsrRateState(ts, now + i);
      assert.equal(s.limited, false);
      ts = s.timestamps;
    }
    assert.equal(nextDsrRateState(ts, now + 21).limited, true);
    assert.equal(nextDsrRateState(ts, now + DSR_RATE_LIMIT.windowMs + 100).limited, false);
  });
});

describe('paginação', () => {
  it('collectPages percorre todas as páginas', async () => {
    const all = Array.from({ length: 7 }, (_, i) => ({ id: `d${i}` }));
    const pages = [];
    const out = await collectPages(async (after, limit) => {
      pages.push(after);
      const start = after ? all.findIndex((d) => d.id === after) + 1 : 0;
      return all.slice(start, start + limit);
    }, 3);
    assert.equal(out.length, 7);
    assert.deepEqual(pages, [null, 'd2', 'd5']);
  });

  it('chunk divide em lotes', () => {
    assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  });
});

describe('findCustomerData', () => {
  it('conta por fila nas duas formas, só das filas do dono, e grava log sem PII', async () => {
    const deps = fakeDeps(seed());
    const res = await findCustomerData({ uid: 'u1', digits: DIGITS, now: 9000 }, deps);
    assert.equal(res.queuesScanned, 3);
    assert.deepEqual(
      res.queues.map((q) => [q.queueId, q.history, q.feedback, q.entries]),
      [
        ['q1', 1, 1, 1],
        ['q2', 1, 0, 0],
      ],
    );
    assert.deepEqual(res.totals, { history: 2, feedback: 1, entries: 1 });
    assert.equal(res.queues[0].firstAt, 2000);
    assert.equal(res.queues[0].lastAt, 7000);
    assert.ok(!JSON.stringify(res).includes('Ana'));
    const [uid, log] = deps.logs[0];
    assert.equal(uid, 'u1');
    assert.equal(log.action, 'find');
    const dump = JSON.stringify(log);
    assert.ok(!dump.includes(DIGITS));
    assert.ok(!dump.includes('Ana'));
    assert.match(log.phoneHash, /^[0-9a-f]{32}$/);
  });

  it('sem filas devolve vazio', async () => {
    const deps = fakeDeps({ queues: [] });
    const res = await findCustomerData({ uid: 'u1', digits: DIGITS, now: 1 }, deps);
    assert.deepEqual(res.queues, []);
  });
});

describe('exportCustomerData', () => {
  it('devolve registros com avaliação e CSV escapado', async () => {
    const deps = fakeDeps(seed());
    const res = await exportCustomerData({ uid: 'u1', digits: DIGITS, now: 9000 }, deps);
    assert.equal(res.records.length, 3);
    const h1 = res.records.find((r) => r.ticket === 1);
    assert.equal(h1.rating, 4);
    assert.equal(h1.comment, 'ótimo, "bom"');
    assert.equal(h1.joinedAt, new Date(1000).toISOString());
    assert.ok(res.csv.split('\n')[0].startsWith('queue,source,ticket,name,phone'));
    assert.ok(res.csv.includes('"ótimo, ""bom"""'));
    assert.equal(res.truncated, false);
    assert.equal(deps.logs[0][1].action, 'export');
    assert.ok(!JSON.stringify(deps.logs[0][1]).includes('Ana'));
  });

  it('neutraliza fórmulas no CSV', () => {
    const csv = toCsv([{ queue: 'q', source: 'history', name: '=cmd()', phone: '', comment: '+1' }]);
    assert.ok(csv.includes("'=cmd()"));
    assert.ok(csv.includes("'+1"));
  });
});

describe('eraseCustomerData', () => {
  it('delete apaga history, feedback e entries do telefone, preservando os outros', async () => {
    const deps = fakeDeps(seed());
    const res = await eraseCustomerData({ uid: 'u1', digits: DIGITS, mode: 'delete', now: 9000 }, deps);
    assert.equal(res.complete, true);
    assert.deepEqual(res.totals, { history: 2, feedback: 1, entries: 1 });
    assert.deepEqual(Object.keys(deps.state.history.q1), ['h2']);
    assert.deepEqual(Object.keys(deps.state.history.q2), []);
    assert.deepEqual(deps.state.feedback.q1, {});
    assert.deepEqual(deps.state.entries.q1, {});
    const names = deps.calls.map((c) => c[0]);
    assert.ok(names.indexOf('deleteFeedback') < names.indexOf('deleteHistory'));
    const [, log] = deps.logs[0];
    assert.equal(log.action, 'erase');
    assert.equal(log.mode, 'delete');
    assert.equal(log.complete, true);
    const dump = JSON.stringify(log);
    assert.ok(!dump.includes(DIGITS) && !dump.includes(MASKED) && !dump.includes('Ana'));
  });

  it('anonymize troca nome e telefone, limpa comentário e remove entries', async () => {
    const deps = fakeDeps(seed());
    const res = await eraseCustomerData({ uid: 'u1', digits: DIGITS, mode: 'anonymize', now: 9000 }, deps);
    assert.deepEqual(res.totals, { history: 2, feedback: 1, entries: 1 });
    assert.equal(deps.state.history.q1.h1.name, 'Anônimo');
    assert.equal(deps.state.history.q1.h1.phone, null);
    assert.equal(deps.state.history.q1.h2.name, 'Bia');
    assert.equal(deps.state.feedback.q1.h1.comment, '');
    assert.equal(deps.state.feedback.q1.h1.rating, 4);
    assert.deepEqual(deps.state.entries.q1, {});
  });

  it('falha em uma fila não impede as outras e marca incompleto', async () => {
    const deps = fakeDeps({ ...seed(), failOn: 'q1' });
    const errors = [];
    const res = await eraseCustomerData(
      { uid: 'u1', digits: DIGITS, mode: 'delete', now: 9000, onError: (e, c) => errors.push(c) },
      deps,
    );
    assert.equal(res.complete, false);
    assert.equal(res.failedQueues, 1);
    assert.deepEqual(errors, [{ queueId: 'q1' }]);
    assert.deepEqual(Object.keys(deps.state.history.q2), []);
    assert.equal(deps.logs[0][1].complete, false);
  });

  it('processa mais de um lote', async () => {
    const history = {};
    for (let i = 0; i < 1000; i += 1) {
      history[`h${String(i).padStart(4, '0')}`] = { phone: DIGITS, name: 'X', result: 'served' };
    }
    const deps = fakeDeps({ queues: [{ id: 'q1' }], history: { q1: history } });
    const res = await eraseCustomerData({ uid: 'u1', digits: DIGITS, mode: 'delete', now: 1 }, deps);
    assert.equal(res.totals.history, 1000);
    assert.equal(Object.keys(deps.state.history.q1).length, 0);
    assert.ok(deps.calls.filter((c) => c[0] === 'deleteHistory').every((c) => c[2].length <= 450));
  });
});

describe('auditDoc', () => {
  it('limita filas e omite modo quando ausente', () => {
    const queues = Array.from({ length: 150 }, (_, i) => ({ queueId: `q${i}`, history: 1, feedback: 0, entries: 0 }));
    const doc = auditDoc({ action: 'find', phoneHash: 'h', queues, complete: true, now: 1 });
    assert.equal(doc.queues.length, 100);
    assert.equal(doc.totals.history, 150);
    assert.equal('mode' in doc, false);
  });
});

describe('App Check das callables de titular', () => {
  it('só liga por ENFORCE_APP_CHECK_DSR', () => {
    for (const name of ['findCustomerData', 'exportCustomerData', 'eraseCustomerData']) {
      assert.equal(isEnforced(name, { ENFORCE_APP_CHECK: 'true' }), false);
      assert.equal(isEnforced(name, { ENFORCE_APP_CHECK_DSR: 'true' }), true);
    }
  });
});
