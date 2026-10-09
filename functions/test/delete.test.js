const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  QUEUE_RTDB_PATHS,
  isSafeId,
  assertRecentLogin,
  invitesToDelete,
  slugsToDelete,
  deleteLogoFiles,
  deleteQueueData,
  deleteOwnedQueue,
  deleteAccountData,
} = require('../src/delete');

function fakeDeps(overrides = {}) {
  const calls = [];
  const rec = (name) => async (...args) => {
    calls.push([name, ...args]);
  };
  return {
    calls,
    getQueue: async () => ({ ownerId: 'u1' }),
    markDeleting: rec('markDeleting'),
    removeRtdb: rec('removeRtdb'),
    deleteSubcollections: rec('deleteSubcollections'),
    listInvites: async () => [{ code: 'ABC123', queueId: 'q1', ownerId: 'u1' }],
    deleteInvite: rec('deleteInvite'),
    listSlugs: async () => [{ slug: 'minha-fila', queueId: 'q1', ownerId: 'u1' }],
    deleteSlug: rec('deleteSlug'),
    deleteLogos: rec('deleteLogos'),
    deleteQueueDoc: rec('deleteQueueDoc'),
    listOwnedQueueIds: async () => ['a', 'b'],
    listOperatorLinks: async () => [],
    removeOperatorLink: rec('removeOperatorLink'),
    deleteOwnerData: rec('deleteOwnerData'),
    deleteAuthUser: rec('deleteAuthUser'),
    ...overrides,
  };
}

const names = (calls) => calls.map((c) => c[0]);

describe('isSafeId', () => {
  it('aceita ids de push key e recusa caminhos', () => {
    assert.equal(isSafeId('-Nabc_12'), true);
    for (const bad of ['', 'a/b', '..', '*', 'a.b', 'a#b', 'a$b', 'a[b', 5, null, undefined, {}, 'x'.repeat(129)]) {
      assert.equal(isSafeId(bad), false);
    }
  });
});

describe('assertRecentLogin', () => {
  const now = 1_000_000;
  it('login recente passa', () => {
    assert.doesNotThrow(() => assertRecentLogin(now - 10, now));
    assert.doesNotThrow(() => assertRecentLogin(now - 300, now));
  });

  it('301 s falha com reason recent-login', () => {
    assert.throws(
      () => assertRecentLogin(now - 301, now),
      (err) => err.code === 'failed-precondition' && err.details.reason === 'recent-login',
    );
  });

  it('auth_time ausente ou inválido falha', () => {
    for (const bad of [undefined, null, '123', NaN]) {
      assert.throws(() => assertRecentLogin(bad, now), /Confirme/);
    }
  });
});

describe('invitesToDelete', () => {
  it('filtra por fila e dono', () => {
    const list = [
      { code: 'a', queueId: 'q1', ownerId: 'u1' },
      { code: 'b', queueId: 'q2', ownerId: 'u1' },
      { code: 'c', queueId: 'q1', ownerId: 'u2' },
    ];
    assert.deepEqual(invitesToDelete(list, 'q1', 'u1'), ['a']);
  });
});

describe('slugsToDelete', () => {
  it('filtra por fila e dono', () => {
    const list = [
      { slug: 'a-fila', queueId: 'q1', ownerId: 'u1' },
      { slug: 'b-fila', queueId: 'q2', ownerId: 'u1' },
      { slug: 'c-fila', queueId: 'q1', ownerId: 'u2' },
    ];
    assert.deepEqual(slugsToDelete(list, 'q1', 'u1'), ['a-fila']);
  });
});

describe('deleteLogoFiles', () => {
  it('apaga pelo prefixo quando o bucket existe', async () => {
    const calls = [];
    const bucket = {
      exists: async () => [true],
      deleteFiles: async (o) => calls.push(o),
    };
    assert.equal(await deleteLogoFiles(bucket, 'q1'), true);
    assert.deepEqual(calls, [{ prefix: 'queue-logos/q1/', force: true }]);
  });

  it('bucket inexistente loga aviso e não apaga', async () => {
    const warns = [];
    const bucket = {
      exists: async () => [false],
      deleteFiles: async () => assert.fail('não deveria apagar'),
    };
    assert.equal(await deleteLogoFiles(bucket, 'q1', (e, c) => warns.push([e, c])), false);
    assert.deepEqual(warns, [['delete-queue:bucket-missing', { queueId: 'q1' }]]);
  });

  it('erro real do Storage não é engolido', async () => {
    const bucket = {
      exists: async () => [true],
      deleteFiles: async () => {
        const e = new Error('404');
        e.code = 404;
        throw e;
      },
    };
    await assert.rejects(deleteLogoFiles(bucket, 'q1'), /404/);
  });
});

describe('deleteQueueData', () => {
  it('segue a ordem: marca, RTDB, subcoleções, convite, logo, owners e doc por último', async () => {
    const deps = fakeDeps();
    await deleteQueueData('q1', 'u1', deps);
    const seq = deps.calls.map((c) => (c[0] === 'removeRtdb' ? `rtdb:${c[1]}` : c[0]));
    assert.deepEqual(seq, [
      'markDeleting',
      ...QUEUE_RTDB_PATHS('q1').map((p) => `rtdb:${p}`),
      'deleteSubcollections',
      'deleteInvite',
      'deleteSlug',
      'deleteLogos',
      'rtdb:owners/q1',
      'deleteQueueDoc',
    ]);
  });

  it('apaga o slug da fila e ignora slug de outra fila', async () => {
    const deps = fakeDeps({
      listSlugs: async () => [
        { slug: 'minha-fila', queueId: 'q1', ownerId: 'u1' },
        { slug: 'outra', queueId: 'q2', ownerId: 'u1' },
      ],
    });
    await deleteQueueData('q1', 'u1', deps);
    assert.deepEqual(
      deps.calls.filter((c) => c[0] === 'deleteSlug'),
      [['deleteSlug', 'minha-fila']],
    );
  });

  it('sem slug não chama deleteSlug', async () => {
    const deps = fakeDeps({ listSlugs: async () => [] });
    await deleteQueueData('q1', 'u1', deps);
    assert.ok(!names(deps.calls).includes('deleteSlug'));
  });

  it('meta é o último caminho do RTDB removido', () => {
    assert.equal(QUEUE_RTDB_PATHS('q1').at(-1), 'queues/q1/meta');
  });

  it('não apaga convite de outra fila nem de outro dono', async () => {
    const deps = fakeDeps({
      listInvites: async () => [
        { code: 'OUTRA', queueId: 'q2', ownerId: 'u1' },
        { code: 'ALHEIO', queueId: 'q1', ownerId: 'u9' },
      ],
    });
    await deleteQueueData('q1', 'u1', deps);
    assert.ok(!names(deps.calls).includes('deleteInvite'));
  });

  it('não apaga convite quando a fila não tem código', async () => {
    const deps = fakeDeps({ listInvites: async () => [] });
    await deleteQueueData('q1', 'u1', deps);
    assert.ok(!names(deps.calls).includes('deleteInvite'));
  });

  it('falha no meio não apaga owners nem o doc da fila', async () => {
    const deps = fakeDeps({
      deleteSubcollections: async () => {
        throw new Error('boom');
      },
    });
    await assert.rejects(deleteQueueData('q1', 'u1', deps), /boom/);
    assert.ok(!names(deps.calls).includes('deleteQueueDoc'));
    assert.ok(!deps.calls.some((c) => c[0] === 'removeRtdb' && c[1] === 'owners/q1'));
  });

  it('é re-executável: segunda chamada conclui após falha no logo', async () => {
    let fail = true;
    const deps = fakeDeps({
      deleteLogos: async () => {
        if (fail) throw new Error('storage');
      },
    });
    await assert.rejects(deleteQueueData('q1', 'u1', deps), /storage/);
    fail = false;
    deps.calls.length = 0;
    await deleteQueueData('q1', 'u1', deps);
    assert.equal(names(deps.calls).at(-1), 'deleteQueueDoc');
  });

  it('loga só o queueId', async () => {
    const logs = [];
    await deleteQueueData('q1', 'u1', fakeDeps(), (e, ctx) => logs.push([e, ctx]));
    assert.ok(logs.length >= 4);
    for (const [, ctx] of logs) assert.deepEqual(Object.keys(ctx), ['queueId']);
  });
});

describe('deleteOwnedQueue', () => {
  it('fila inexistente é sucesso idempotente sem tocar em nada', async () => {
    const deps = fakeDeps({ getQueue: async () => null });
    assert.deepEqual(await deleteOwnedQueue('q1', 'u1', deps), {
      deleted: false,
      alreadyGone: true,
    });
    assert.equal(deps.calls.length, 0);
  });

  it('recusa quem não é dono sem apagar', async () => {
    const deps = fakeDeps();
    const res = await deleteOwnedQueue('q1', 'intruso', deps);
    assert.equal(res.forbidden, true);
    assert.equal(deps.calls.length, 0);
  });

  it('dono apaga', async () => {
    const deps = fakeDeps();
    const res = await deleteOwnedQueue('q1', 'u1', deps);
    assert.equal(res.deleted, true);
    assert.equal(names(deps.calls).at(-1), 'deleteQueueDoc');
  });
});

describe('deleteAccountData', () => {
  it('apaga filas, vínculos de operador, dados do dono e por fim a conta', async () => {
    const deps = fakeDeps({
      listOperatorLinks: async () => [{ queueId: 'x', kind: 'operators' }],
    });
    const res = await deleteAccountData('u1', deps);
    assert.equal(res.complete, true);
    assert.equal(res.queuesDeleted, 2);
    assert.equal(res.operatorLinksRemoved, 1);
    const seq = names(deps.calls);
    assert.ok(seq.indexOf('removeOperatorLink') < seq.indexOf('deleteOwnerData'));
    assert.deepEqual(seq.slice(-2), ['deleteOwnerData', 'deleteAuthUser']);
    assert.equal(seq.filter((n) => n === 'deleteQueueDoc').length, 2);
  });

  it('falha parcial em uma fila segue com as outras e não apaga a conta', async () => {
    const deps = fakeDeps({
      deleteLogos: async (id) => {
        if (id === 'a') throw new Error('x');
      },
    });
    const res = await deleteAccountData('u1', deps);
    assert.equal(res.complete, false);
    assert.equal(res.queuesDeleted, 1);
    assert.equal(res.failures.queues, 1);
    assert.ok(!names(deps.calls).includes('deleteOwnerData'));
    assert.ok(!names(deps.calls).includes('deleteAuthUser'));
  });

  it('falha ao remover vínculo de operador impede apagar a conta', async () => {
    const deps = fakeDeps({
      listOperatorLinks: async () => [{ queueId: 'x' }],
      removeOperatorLink: async () => {
        throw new Error('x');
      },
    });
    const res = await deleteAccountData('u1', deps);
    assert.equal(res.complete, false);
    assert.equal(res.failures.operatorLinks, 1);
    assert.ok(!names(deps.calls).includes('deleteAuthUser'));
  });

  it('só toca nas filas listadas para o uid, nunca em outras', async () => {
    const deps = fakeDeps({ listOwnedQueueIds: async () => ['a'] });
    await deleteAccountData('u1', deps, () => {}, { queueId: 'alheia', ownerId: 'x' });
    const touched = deps.calls.flatMap((c) => c.slice(1)).filter((v) => typeof v === 'string');
    assert.ok(!touched.some((v) => v.includes('alheia')));
    assert.ok(touched.some((v) => v.includes('a')));
  });

  it('sem filas nem vínculos apaga owner e conta', async () => {
    const deps = fakeDeps({ listOwnedQueueIds: async () => [] });
    const res = await deleteAccountData('u1', deps);
    assert.equal(res.complete, true);
    assert.deepEqual(names(deps.calls), ['deleteOwnerData', 'deleteAuthUser']);
  });

  it('re-execução após falha conclui', async () => {
    let fail = true;
    const deps = fakeDeps({
      deleteQueueDoc: async (id) => {
        if (fail && id === 'b') throw new Error('x');
      },
    });
    assert.equal((await deleteAccountData('u1', deps)).complete, false);
    fail = false;
    assert.equal((await deleteAccountData('u1', deps)).complete, true);
  });
});
