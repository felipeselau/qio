const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeExpiry,
  isStale,
  lastActivity,
  dayKey,
  planTicketReset,
  expireQueue,
  maintainQueue,
  clearWaitingOnClose,
  runTicketReset,
} = require('../src/expire');
const { historyFromLeftEntry } = require('../src/history');

const H = 60 * 60 * 1000;
const now = Date.UTC(2026, 9, 9, 15, 0, 0);

function fakeDeps(initial, { anonymizePhone = false, status = 'open' } = {}) {
  const entries = structuredClone(initial);
  const publicMap = Object.fromEntries(Object.keys(entries).map((id) => [id, true]));
  const history = {};
  const calls = { archive: 0, errors: [] };
  const removeWhere = async (id, keep) => {
    const current = entries[id];
    if (!current || !keep(current)) return false;
    delete entries[id];
    return true;
  };
  return {
    entries,
    publicMap,
    history,
    calls,
    deps: {
      readEntries: async () => structuredClone(entries),
      archive: async (queueId, id, entry, reason) => {
        calls.archive += 1;
        if (history[id]) return;
        history[id] = historyFromLeftEntry(entry, now, { anonymizePhone, reason });
      },
      undoArchive: async (q, id, reason) => {
        if (history[id]?.reason === reason) delete history[id];
      },
      readStatus: async () => status,
      removeIfStale: (q, id, n, hours) => removeWhere(id, (c) => isStale(c, n, hours)),
      removeIfWaiting: (q, id) => removeWhere(id, (c) => c.status === 'waiting'),
      removePublic: async (q, id) => {
        delete publicMap[id];
      },
      onError: (err) => calls.errors.push(err),
    },
  };
}

describe('normalizeExpiry', () => {
  it('desligado ou inválido vira null', () => {
    assert.equal(normalizeExpiry(undefined), null);
    assert.equal(normalizeExpiry({ enabled: false, hours: 5 }), null);
    assert.equal(normalizeExpiry('x'), null);
  });

  it('aplica padrão de 12h fora de 1-48', () => {
    assert.equal(normalizeExpiry({ enabled: true }).hours, 12);
    assert.equal(normalizeExpiry({ enabled: true, hours: 0 }).hours, 12);
    assert.equal(normalizeExpiry({ enabled: true, hours: 49 }).hours, 12);
    assert.equal(normalizeExpiry({ enabled: true, hours: 1.5 }).hours, 12);
    assert.equal(normalizeExpiry({ enabled: true, hours: 48 }).hours, 48);
    assert.equal(normalizeExpiry({ enabled: true, hours: 1 }).hours, 1);
  });

  it('opções são false por padrão', () => {
    const c = normalizeExpiry({ enabled: true, clearOnClose: true });
    assert.equal(c.clearOnClose, true);
    assert.equal(c.resetTicketDaily, false);
  });
});

describe('isStale', () => {
  it('waiting antigo expira na fronteira', () => {
    const e = { status: 'waiting', joinedAt: now - 12 * H };
    assert.equal(isStale(e, now, 12), true);
    assert.equal(isStale({ ...e, joinedAt: now - 12 * H + 1 }, now, 12), false);
  });

  it('called nunca expira', () => {
    assert.equal(isStale({ status: 'called', joinedAt: now - 100 * H }, now, 1), false);
  });

  it('usa a atividade mais recente entre joinedAt, order e recalledAt', () => {
    const e = { status: 'waiting', joinedAt: now - 20 * H, order: now - 2 * H };
    assert.equal(lastActivity(e), now - 2 * H);
    assert.equal(isStale(e, now, 12), false);
    assert.equal(isStale({ ...e, recalledAt: now - 13 * H, order: now - 14 * H }, now, 12), true);
  });

  it('sem timestamps válidos não expira', () => {
    assert.equal(isStale({ status: 'waiting' }, now, 1), false);
    assert.equal(isStale(null, now, 1), false);
  });
});

describe('dayKey e planTicketReset', () => {
  it('meia-noite de São Paulo vira o dia', () => {
    const before = Date.UTC(2026, 9, 10, 2, 59, 59);
    const at = Date.UTC(2026, 9, 10, 3, 0, 0);
    assert.equal(dayKey(before), '2026-10-09');
    assert.equal(dayKey(at), '2026-10-10');
  });

  it('primeira execução só marca o dia', () => {
    assert.deepEqual(planTicketReset({ lastDay: undefined, now, activeCount: 0 }), {
      action: 'mark',
      day: '2026-10-09',
    });
  });

  it('mesmo dia não faz nada', () => {
    assert.equal(planTicketReset({ lastDay: '2026-10-09', now, activeCount: 0 }).action, 'none');
  });

  it('dia novo com fila vazia zera', () => {
    assert.equal(planTicketReset({ lastDay: '2026-10-08', now, activeCount: 0 }).action, 'reset');
  });

  it('dia novo com entries ativas adia', () => {
    assert.equal(planTicketReset({ lastDay: '2026-10-08', now, activeCount: 1 }).action, 'none');
  });
});

describe('runTicketReset', () => {
  it('zera e marca, depois fica idempotente', async () => {
    const state = { resets: 0, day: '2026-10-08' };
    const deps = {
      readStatus: async () => 'open',
      readEntries: async () => null,
      resetTicket: async () => {
        state.resets += 1;
      },
      markResetDay: async (q, d) => {
        state.day = d;
      },
    };
    await runTicketReset({ queueId: 'q', lastDay: state.day, now, activeCount: 0, deps });
    await runTicketReset({ queueId: 'q', lastDay: state.day, now, activeCount: 0, deps });
    assert.equal(state.resets, 1);
    assert.equal(state.day, '2026-10-09');
  });

  it('não zera se a releitura achar entry ativa', async () => {
    let resets = 0;
    let marks = 0;
    const deps = {
      readStatus: async () => 'open',
      readEntries: async () => ({ a: { status: 'waiting' } }),
      resetTicket: async () => (resets += 1),
      markResetDay: async () => (marks += 1),
    };
    const r = await runTicketReset({ queueId: 'q', lastDay: '2026-10-08', now, activeCount: 0, deps });
    assert.equal(r.action, 'none');
    assert.equal(resets, 0);
    assert.equal(marks, 0);
  });

  it('não zera se a fila não existe no RTDB', async () => {
    let resets = 0;
    const deps = {
      readStatus: async () => null,
      readEntries: async () => null,
      resetTicket: async () => (resets += 1),
      markResetDay: async () => {},
    };
    await runTicketReset({ queueId: 'q', lastDay: '2026-10-08', now, activeCount: 0, deps });
    assert.equal(resets, 0);
  });

  it('zera quando a releitura está vazia', async () => {
    let resets = 0;
    const deps = {
      readStatus: async () => 'closed',
      readEntries: async () => null,
      resetTicket: async () => (resets += 1),
      markResetDay: async () => {},
    };
    await runTicketReset({ queueId: 'q', lastDay: '2026-10-08', now, activeCount: 0, deps });
    assert.equal(resets, 1);
  });

  it('não zera com entries ativas', async () => {
    let resets = 0;
    const deps = { resetTicket: async () => (resets += 1), markResetDay: async () => {} };
    await runTicketReset({ queueId: 'q', lastDay: '2026-10-08', now, activeCount: 2, deps });
    assert.equal(resets, 0);
  });
});

describe('expireQueue', () => {
  const base = {
    old: { status: 'waiting', ticket: 1, name: 'Ana', phone: '(11) 91234-5678', joinedAt: now - 13 * H },
    fresh: { status: 'waiting', ticket: 2, name: 'Bia', phone: '', joinedAt: now - H },
    called: { status: 'called', ticket: 3, name: 'Cid', phone: '', joinedAt: now - 30 * H },
  };

  it('arquiva só waiting velhas com reason expired', async () => {
    const f = fakeDeps(base);
    const r = await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    assert.equal(r.expired, 1);
    assert.equal(r.remaining, 2);
    assert.deepEqual(Object.keys(f.entries).sort(), ['called', 'fresh']);
    assert.deepEqual(Object.keys(f.publicMap).sort(), ['called', 'fresh']);
    assert.equal(f.history.old.result, 'left');
    assert.equal(f.history.old.reason, 'expired');
    assert.equal(f.history.old.phone, '(11) 91234-5678');
    assert.equal(f.history.called, undefined);
  });

  it('respeita anonymizePhone', async () => {
    const f = fakeDeps(base, { anonymizePhone: true });
    await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    assert.equal(f.history.old.phone, null);
  });

  it('é idempotente', async () => {
    const f = fakeDeps(base);
    await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    const second = await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    assert.equal(second.expired, 0);
    assert.equal(f.calls.archive, 1);
  });

  it('não remove se a entry mudou entre a leitura e a remoção', async () => {
    const f = fakeDeps(base);
    const original = f.deps.readEntries;
    f.deps.readEntries = async () => {
      const snapshot = await original();
      f.entries.old.status = 'called';
      return snapshot;
    };
    const r = await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    assert.equal(r.expired, 0);
    assert.ok(f.entries.old);
    assert.equal(f.history.old, undefined);
  });

  it('undo não apaga history de outra origem', async () => {
    const f = fakeDeps(base);
    f.history.old = { result: 'left' };
    const original = f.deps.readEntries;
    f.deps.readEntries = async () => {
      const snapshot = await original();
      f.entries.old.status = 'called';
      return snapshot;
    };
    await expireQueue({ queueId: 'q', config: { hours: 12 }, now, deps: f.deps });
    assert.deepEqual(f.history.old, { result: 'left' });
  });

  it('processa em lotes e isola erros', async () => {
    const many = {};
    for (let i = 0; i < 60; i += 1) {
      many[`e${i}`] = { status: 'waiting', ticket: i + 1, name: 'N', phone: '', joinedAt: now - 20 * H };
    }
    const f = fakeDeps(many);
    const archive = f.deps.archive;
    let inFlight = 0;
    let peak = 0;
    f.deps.archive = async (q, id, e, reason) => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise((resolve) => setImmediate(resolve));
      inFlight -= 1;
      if (id === 'e7') throw new Error('boom');
      return archive(q, id, e, reason);
    };
    const r = await expireQueue({
      queueId: 'q',
      config: { hours: 12 },
      now,
      deps: f.deps,
      batchSize: 10,
    });
    assert.equal(r.expired, 59);
    assert.ok(peak <= 10);
    assert.equal(f.calls.errors.length, 1);
    assert.ok(f.entries.e7);
  });
});

describe('clearWaitingOnClose', () => {
  it('arquiva waiting como closed e preserva called', async () => {
    const f = fakeDeps({
      a: { status: 'waiting', ticket: 1, name: 'A', phone: '', joinedAt: now - H },
      b: { status: 'called', ticket: 2, name: 'B', phone: '', joinedAt: now - H },
    });
    const n = await clearWaitingOnClose({ queueId: 'q', deps: f.deps });
    assert.equal(n, 1);
    assert.equal(f.history.a.reason, 'closed');
    assert.deepEqual(Object.keys(f.entries), ['b']);
    assert.deepEqual(Object.keys(f.publicMap), ['b']);
  });
});

describe('maintainQueue', () => {
  const waiting = { status: 'waiting', ticket: 1, name: 'A', phone: '', joinedAt: now - H };
  const called = { status: 'called', ticket: 2, name: 'B', phone: '', joinedAt: now - H };

  it('fila fechada com clearOnClose limpa waiting e preserva called', async () => {
    const f = fakeDeps({ a: waiting, b: called }, { status: 'closed' });
    const r = await maintainQueue({
      queueId: 'q',
      config: { hours: 12, clearOnClose: true },
      now,
      deps: f.deps,
    });
    assert.equal(r.cleared, 1);
    assert.equal(r.remaining, 1);
    assert.equal(f.history.a.reason, 'closed');
    const again = await maintainQueue({
      queueId: 'q',
      config: { hours: 12, clearOnClose: true },
      now,
      deps: f.deps,
    });
    assert.equal(again.cleared, 0);
  });

  it('fila aberta ou sem clearOnClose não limpa', async () => {
    const open = fakeDeps({ a: waiting });
    assert.equal((await maintainQueue({ queueId: 'q', config: { hours: 12, clearOnClose: true }, now, deps: open.deps })).cleared, 0);
    const closed = fakeDeps({ a: waiting }, { status: 'closed' });
    assert.equal((await maintainQueue({ queueId: 'q', config: { hours: 12, clearOnClose: false }, now, deps: closed.deps })).cleared, 0);
  });
});

describe('historyFromLeftEntry reason', () => {
  it('omite reason quando ausente', () => {
    assert.equal('reason' in historyFromLeftEntry({ ticket: 1 }, now), false);
  });
});
