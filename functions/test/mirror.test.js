const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  buildMetaPatch,
  buildOwnerPatch,
  changedFields,
  ownerChanged,
  isValidUid,
  normalizeAvgServiceMin,
  normalizeName,
  expectedSlots,
} = require('../src/mirror');

const LOGO = 'https://firebasestorage.googleapis.com/v0/b/x/o/logo.jpg';
const doc = (extra = {}) => ({
  ownerId: 'u1',
  name: 'Balcão',
  description: 'Atendimento',
  status: 'open',
  avgServiceMin: 12,
  maxWaiting: 5,
  ...extra,
});
const meta = (extra = {}) => ({
  nextTicket: 3,
  serving: 2,
  updatedAt: 111,
  name: 'Balcão',
  description: 'Atendimento',
  status: 'open',
  avgServiceMin: 12,
  maxWaiting: 5,
  ...extra,
});
const ts = (ms) => ({ toMillis: () => ms });

describe('buildMetaPatch idempotência', () => {
  it('meta igual ao doc não gera patch', () => {
    assert.deepEqual(buildMetaPatch(doc(), meta()), {});
  });

  it('aplicar o patch e recalcular devolve vazio', () => {
    const d = doc({
      name: '  Novo  ',
      description: '',
      statusMessage: 'Volto já',
      resumeAt: ts(5000),
      status: 'paused',
      brandColor: '#112233',
      logoUrl: LOGO,
      mode: 'schedule',
      slots: [{ id: 'a', start: '09:00', capacity: 2 }],
    });
    const m = meta({ description: 'velha', maxWaiting: 9 });
    const patch = buildMetaPatch(d, m);
    const next = { ...m };
    for (const [k, v] of Object.entries(patch)) {
      if (v === null) delete next[k];
      else next[k] = v;
    }
    assert.deepEqual(buildMetaPatch(d, next), {});
  });

  it('devolve só os campos divergentes', () => {
    assert.deepEqual(buildMetaPatch(doc({ name: 'Outro' }), meta()), { name: 'Outro' });
    assert.deepEqual(buildMetaPatch(doc({ status: 'closed' }), meta()), { status: 'closed' });
    assert.deepEqual(buildMetaPatch(doc({ avgServiceMin: 20 }), meta()), { avgServiceMin: 20 });
    assert.deepEqual(buildMetaPatch(doc({ maxWaiting: 0 }), meta()), { maxWaiting: 0 });
  });
});

describe('buildMetaPatch normalização', () => {
  it('nome vazio vira Fila e longo é truncado a 60', () => {
    assert.equal(buildMetaPatch(doc({ name: '   ' }), meta()).name, 'Fila');
    assert.equal(buildMetaPatch(doc({ name: 'x'.repeat(80) }), meta()).name, 'x'.repeat(60));
    assert.equal(normalizeName(`${'a'.repeat(59)} bbb`), 'a'.repeat(59));
  });

  it('descrição truncada a 300 e vazia remove', () => {
    assert.equal(buildMetaPatch(doc({ description: 'd'.repeat(400) }), meta()).description.length, 300);
    assert.equal(buildMetaPatch(doc({ description: '  ' }), meta()).description, null);
    assert.deepEqual(buildMetaPatch(doc({ description: null }), meta({ description: undefined })), {});
  });

  it('avgServiceMin fora de 1-240 ou não inteiro vira 10', () => {
    for (const bad of [0, 241, 0.5, NaN, Infinity, '5', null, undefined]) {
      assert.equal(buildMetaPatch(doc({ avgServiceMin: bad }), meta()).avgServiceMin, 10);
    }
    assert.deepEqual(buildMetaPatch(doc({ avgServiceMin: 10 }), meta({ avgServiceMin: 10 })), {});
  });

  it('avgServiceMin e maxWaiting fracionários truncam como Queue.fromDoc (toInt)', () => {
    assert.equal(normalizeAvgServiceMin(12.9), 12);
    assert.equal(buildMetaPatch(doc({ avgServiceMin: 12.9 }), meta({ avgServiceMin: 5 })).avgServiceMin, 12);
    assert.equal(buildMetaPatch(doc({ maxWaiting: 7.8 }), meta()).maxWaiting, 7);
  });

  it('maxWaiting ausente equivale a 0; inválido vira 0', () => {
    assert.deepEqual(buildMetaPatch(doc({ maxWaiting: undefined }), meta({ maxWaiting: undefined })), {});
    assert.equal(buildMetaPatch(doc({ maxWaiting: 5000 }), meta()).maxWaiting, 0);
  });

  it('status desconhecido é ignorado, nunca vira open', () => {
    assert.deepEqual(buildMetaPatch(doc({ status: 'x' }), meta({ status: 'closed' })), {});
    assert.ok(!('status' in buildMetaPatch(doc({ status: undefined }), null)));
  });

  it('statusMessage e resumeAt copiam e limpam', () => {
    const patch = buildMetaPatch(doc({ statusMessage: 'Volto', resumeAt: ts(9000) }), meta());
    assert.deepEqual(patch, { statusMessage: 'Volto', resumeAt: 9000 });
    assert.deepEqual(buildMetaPatch(doc({ resumeAt: 1.5 }), meta()), {});
    assert.deepEqual(buildMetaPatch(doc({ resumeAt: NaN }), meta()), {});
    const clear = buildMetaPatch(doc(), meta({ statusMessage: 'Volto', resumeAt: 9000 }));
    assert.deepEqual(clear, { statusMessage: null, resumeAt: null });
    assert.equal(
      buildMetaPatch(doc({ statusMessage: 'm'.repeat(200) }), meta()).statusMessage.length,
      120,
    );
  });

  it('brandColor e logoUrl inválidos são tratados como ausentes', () => {
    assert.deepEqual(buildMetaPatch(doc({ brandColor: 'red', logoUrl: 'http://x' }), meta()), {});
    assert.deepEqual(buildMetaPatch(doc({ brandColor: '#abcdef', logoUrl: LOGO }), meta()), {
      brandColor: '#abcdef',
      logoUrl: LOGO,
    });
    assert.deepEqual(buildMetaPatch(doc(), meta({ brandColor: '#abcdef', logoUrl: LOGO })), {
      brandColor: null,
      logoUrl: null,
    });
  });
});

describe('buildMetaPatch modo e slots', () => {
  const slots = [
    { id: 'b', start: '10:00', capacity: 3 },
    { id: 'a', start: '09:00', capacity: 2 },
  ];

  it('doc em schedule sem mode no meta grava mode e slots', () => {
    const patch = buildMetaPatch(doc({ mode: 'schedule', slots }), meta());
    assert.deepEqual(patch, {
      mode: 'schedule',
      slots: { a: { start: '09:00', capacity: 2 }, b: { start: '10:00', capacity: 3 } },
    });
  });

  it('slots iguais não geram patch; capacidade diferente gera', () => {
    const same = meta({
      mode: 'schedule',
      slots: { a: { start: '09:00', capacity: 2 }, b: { start: '10:00', capacity: 3 } },
    });
    assert.deepEqual(buildMetaPatch(doc({ mode: 'schedule', slots }), same), {});
    const other = meta({
      mode: 'schedule',
      slots: { a: { start: '09:00', capacity: 9 }, b: { start: '10:00', capacity: 3 } },
    });
    assert.equal(buildMetaPatch(doc({ mode: 'schedule', slots }), other).slots.a.capacity, 2);
  });

  it('volta para queue sem slots remove slots; mode ausente = queue', () => {
    const m = meta({ mode: 'schedule', slots: { a: { start: '09:00', capacity: 2 } } });
    assert.deepEqual(buildMetaPatch(doc(), m), { mode: 'queue', slots: null });
    assert.deepEqual(buildMetaPatch(doc({ mode: 'queue' }), meta()), {});
  });

  it('descarta slots inválidos, duplicados e corta em MAX_SLOTS (20, igual à joinQueue)', () => {
    const many = Array.from({ length: 30 }, (_, i) => ({
      id: `s${i}`,
      start: `${String(Math.floor(i / 2)).padStart(2, '0')}:${i % 2 ? '30' : '00'}`,
      capacity: 1,
    }));
    assert.equal(Object.keys(expectedSlots(many)).length, 20);
    assert.deepEqual(expectedSlots([{ id: 'a', start: '09:00', capacity: 2.9 }]), { a: { start: '09:00', capacity: 2 } });
    const mixed = expectedSlots([
      { id: 'ok', start: '08:00', capacity: 1 },
      { id: 'ok', start: '09:00', capacity: 1 },
      { id: 'bad id!', start: '08:00', capacity: 1 },
      { id: 'c', start: '25:00', capacity: 1 },
      { id: 'd', start: '08:00', capacity: 0 },
      { id: 'e', start: '08:00', capacity: 51 },
      { id: 'f', start: '08:00', capacity: NaN },
      null,
    ]);
    assert.deepEqual(mixed, { ok: { start: '08:00', capacity: 1 } });
    assert.equal(expectedSlots('x'), null);
    assert.equal(expectedSlots([]), null);
  });
});

describe('buildMetaPatch campos que não podem ser tocados', () => {
  const protectedMeta = meta({
    avgServiceMinAuto: 7.5,
    waitingCount: 4,
    serving: 9,
    nextTicket: 8,
    updatedAt: 999,
    opensAt: 123,
    nextNotifiedAt: 5,
    unknown: 'x',
  });

  it('nunca inclui campos de outras fontes, mesmo havendo divergência', () => {
    const patch = buildMetaPatch(
      doc({ name: 'Novo', serving: 0, waitingCount: 0, avgServiceMinAuto: 1, opensAt: 1 }),
      protectedMeta,
    );
    assert.deepEqual(patch, { name: 'Novo' });
    const forbidden = [
      'avgServiceMinAuto',
      'waitingCount',
      'serving',
      'nextTicket',
      'updatedAt',
      'opensAt',
      'nextNotifiedAt',
      'deleting',
    ];
    for (const key of forbidden) assert.ok(!(key in patch), key);
  });

  it('meta sem divergência com campos extras não gera patch', () => {
    assert.deepEqual(buildMetaPatch(doc(), protectedMeta), {});
  });

  it('criação só inicializa nextTicket/serving e nunca os campos Admin', () => {
    const patch = buildMetaPatch(doc({ opensAt: 5, avgServiceMinAuto: 3 }), null);
    assert.equal(patch.nextTicket, 0);
    assert.equal(patch.serving, 0);
    for (const key of ['updatedAt', 'avgServiceMinAuto', 'waitingCount', 'opensAt', 'deleting']) {
      assert.ok(!(key in patch), key);
    }
  });
});

describe('paridade com app/test/models/queue_info_test.dart (forMirror)', () => {
  it('trunca, usa fallback e reseta fora da faixa', () => {
    const patch = buildMetaPatch(
      doc({ name: 'x'.repeat(80), description: 'd'.repeat(400), avgServiceMin: 999 }),
      meta(),
    );
    assert.equal(patch.name.length, 60);
    assert.equal(patch.description.length, 300);
    assert.equal(patch.avgServiceMin, 10);
  });

  it('nome vazio vira Fila, descrição em branco some, tempo 0 vira 10', () => {
    const patch = buildMetaPatch(doc({ name: '   ', description: '  ', avgServiceMin: 0 }), meta());
    assert.deepEqual(patch, { name: 'Fila', description: null, avgServiceMin: 10 });
  });

  it('valores válidos passam intactos', () => {
    const patch = buildMetaPatch(
      doc({ name: 'Padaria', description: 'oi', avgServiceMin: 7 }),
      meta({ name: 'x', description: 'y', avgServiceMin: 1 }),
    );
    assert.deepEqual(patch, { name: 'Padaria', description: 'oi', avgServiceMin: 7 });
  });
});

describe('buildMetaPatch com fields (só o que mudou)', () => {
  it('ignora divergência em campos fora do conjunto', () => {
    const m = meta({ name: 'Adulterado', status: 'closed' });
    assert.deepEqual(buildMetaPatch(doc(), m, new Set(['maxWaiting'])), {});
    assert.deepEqual(buildMetaPatch(doc(), m, new Set(['name'])), { name: 'Balcão' });
    assert.deepEqual(buildMetaPatch(doc(), m, new Set(['status'])), { status: 'open' });
  });

  it('modeSlots escreve mode e slots juntos', () => {
    const m = meta({ mode: 'schedule', slots: { a: { start: '09:00', capacity: 2 } } });
    assert.deepEqual(buildMetaPatch(doc(), m, new Set(['modeSlots'])), { mode: 'queue', slots: null });
    assert.deepEqual(buildMetaPatch(doc(), m, new Set(['name'])), {});
  });
});

describe('changedFields / ownerChanged', () => {
  it('create considera tudo', () => {
    assert.equal(changedFields(null, doc()).size, 10);
    assert.equal(ownerChanged(null, doc()), true);
  });

  it('só alertState/scheduleLastDesired/lastTicketResetDay não muda nada', () => {
    const after = doc({ alertState: { waitAt: 1 }, scheduleLastDesired: 'open', lastTicketResetDay: '2026-01-01' });
    assert.equal(changedFields(doc(), after).size, 0);
    assert.equal(ownerChanged(doc(), after), false);
  });

  it('detecta apenas os grupos alterados', () => {
    assert.deepEqual([...changedFields(doc(), doc({ name: 'Novo', status: 'paused' }))].sort(), ['name', 'status']);
    assert.deepEqual([...changedFields(doc(), doc({ mode: 'schedule' }))], ['modeSlots']);
  });

  it('mudança que normaliza para o mesmo valor não conta', () => {
    assert.equal(changedFields(doc({ name: ' Balcão ' }), doc()).size, 0);
    assert.equal(changedFields(doc({ status: 'x' }), doc({ status: 'y' })).size, 0);
  });

  it('owner alterado', () => {
    assert.equal(ownerChanged(doc(), doc({ ownerId: 'u2' })), true);
  });
});

describe('buildMetaPatch criação', () => {
  it('doc novo gera meta completa e sem chaves nulas', () => {
    assert.deepEqual(buildMetaPatch(doc({ description: undefined }), undefined), {
      nextTicket: 0,
      serving: 0,
      name: 'Balcão',
      avgServiceMin: 12,
      maxWaiting: 5,
      status: 'open',
    });
    const full = buildMetaPatch(
      doc({
        statusMessage: 'x',
        resumeAt: ts(1),
        brandColor: '#000000',
        logoUrl: LOGO,
        mode: 'schedule',
        slots: [{ id: 'a', start: '09:00', capacity: 2 }],
      }),
      null,
    );
    for (const v of Object.values(full)) assert.notEqual(v, null);
    assert.equal(full.mode, 'schedule');
    assert.deepEqual(full.slots, { a: { start: '09:00', capacity: 2 } });
  });
});

describe('exclusão e deleting', () => {
  it('doc apagado ou inexistente não recria meta nem owners', () => {
    assert.deepEqual(buildMetaPatch(null, null), {});
    assert.deepEqual(buildMetaPatch(undefined, meta()), {});
    assert.equal(buildOwnerPatch(null, null), null);
  });

  it('doc deleting não gera patch (meta existente ou ausente)', () => {
    assert.deepEqual(buildMetaPatch(doc({ deleting: true, name: 'x' }), meta()), {});
    assert.deepEqual(buildMetaPatch(doc({ deleting: true }), null), {});
    assert.equal(buildOwnerPatch(doc({ deleting: true }), null), null);
  });

  it('meta.deleting não é sobrescrita', () => {
    assert.deepEqual(buildMetaPatch(doc({ name: 'Novo' }), meta({ deleting: true })), {});
  });
});

describe('buildOwnerPatch', () => {
  it('cria quando falta ou diverge, nada quando igual', () => {
    assert.deepEqual(buildOwnerPatch(doc(), null), { ownerUid: 'u1' });
    assert.deepEqual(buildOwnerPatch(doc(), { ownerUid: 'outro' }), { ownerUid: 'u1' });
    assert.equal(buildOwnerPatch(doc(), { ownerUid: 'u1' }), null);
  });

  it('ignora doc sem ownerId válido', () => {
    assert.equal(buildOwnerPatch(doc({ ownerId: '' }), null), null);
    assert.equal(buildOwnerPatch(doc({ ownerId: 5 }), null), null);
    assert.equal(buildOwnerPatch({ name: 'x' }, null), null);
  });
});

describe('isValidUid', () => {
  it('aceita ids seguros e recusa o resto', () => {
    assert.equal(isValidUid('op1'), true);
    for (const bad of ['a/b', '', '..', 5, null]) assert.equal(isValidUid(bad), false);
  });
});
