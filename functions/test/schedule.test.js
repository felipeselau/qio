const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  parseTime,
  normalizeSchedule,
  isWithinSchedule,
  nextOpening,
  planScheduleChange,
} = require('../src/schedule');

const weekdays = {
  enabled: true,
  timezone: 'America/Sao_Paulo',
  windows: [{ days: [1, 2, 3, 4, 5], open: '08:00', close: '18:00' }],
};

const at = (iso) => Date.parse(iso);

describe('parseTime', () => {
  it('aceita HH:mm válido e recusa o resto', () => {
    assert.equal(parseTime('08:30'), 510);
    assert.equal(parseTime('23:59'), 1439);
    for (const v of ['8:30', '24:00', '12:60', 'abc', null, 830]) assert.equal(parseTime(v), null);
  });
});

describe('normalizeSchedule', () => {
  it('ignora agenda desligada, vazia ou inválida', () => {
    assert.equal(normalizeSchedule(null), null);
    assert.equal(normalizeSchedule({ enabled: false, windows: [] }), null);
    assert.equal(normalizeSchedule({ enabled: true, windows: [{ days: [], open: '08:00', close: '18:00' }] }), null);
    assert.equal(normalizeSchedule({ enabled: true, windows: [{ days: [1], open: '08:00', close: '08:00' }] }), null);
  });

  it('cai no fuso padrão quando o fuso é inválido', () => {
    const s = normalizeSchedule({ ...weekdays, timezone: 'Nao/Existe' });
    assert.equal(s.timezone, 'America/Sao_Paulo');
  });
});

describe('isWithinSchedule (fuso de São Paulo, UTC-3)', () => {
  it('dentro do horário em dia útil', () => {
    assert.equal(isWithinSchedule(weekdays, at('2026-10-07T14:00:00Z')), true);
  });

  it('antes de abrir e depois de fechar', () => {
    assert.equal(isWithinSchedule(weekdays, at('2026-10-07T10:59:00Z')), false);
    assert.equal(isWithinSchedule(weekdays, at('2026-10-07T21:00:00Z')), false);
  });

  it('o horário de fechamento é exclusivo e o de abertura inclusivo', () => {
    assert.equal(isWithinSchedule(weekdays, at('2026-10-07T11:00:00Z')), true);
    assert.equal(isWithinSchedule(weekdays, at('2026-10-07T21:00:00Z')), false);
  });

  it('fim de semana fica fechado', () => {
    assert.equal(isWithinSchedule(weekdays, at('2026-10-10T14:00:00Z')), false);
  });

  it('usa o dia local, não o UTC', () => {
    assert.equal(isWithinSchedule(weekdays, at('2026-10-10T01:00:00Z')), false);
    assert.equal(isWithinSchedule(weekdays, at('2026-10-09T23:00:00Z')), false);
  });

  it('devolve null sem agenda', () => {
    assert.equal(isWithinSchedule(null, Date.now()), null);
  });

  it('janela que atravessa a meia-noite', () => {
    const night = { enabled: true, timezone: 'America/Sao_Paulo', windows: [{ days: [5], open: '22:00', close: '02:00' }] };
    assert.equal(isWithinSchedule(night, at('2026-10-10T01:30:00Z')), true);
    assert.equal(isWithinSchedule(night, at('2026-10-10T04:30:00Z')), true);
    assert.equal(isWithinSchedule(night, at('2026-10-10T06:00:00Z')), false);
    assert.equal(isWithinSchedule(night, at('2026-10-09T23:00:00Z')), false);
  });

  it('respeita o horário de verão de outro fuso', () => {
    const ny = { enabled: true, timezone: 'America/New_York', windows: [{ days: [1, 2, 3, 4, 5, 6, 7], open: '09:00', close: '17:00' }] };
    assert.equal(isWithinSchedule(ny, at('2026-07-01T13:30:00Z')), true);
    assert.equal(isWithinSchedule(ny, at('2026-07-01T12:30:00Z')), false);
    assert.equal(isWithinSchedule(ny, at('2026-01-05T14:30:00Z')), true);
    assert.equal(isWithinSchedule(ny, at('2026-01-05T13:30:00Z')), false);
  });
});

describe('nextOpening', () => {
  it('na sexta à noite, a próxima abertura é a segunda de manhã', () => {
    const next = nextOpening(weekdays, at('2026-10-09T22:00:00Z'));
    assert.equal(new Date(next).toISOString(), '2026-10-12T11:00:00.000Z');
  });

  it('antes de abrir no mesmo dia', () => {
    const next = nextOpening(weekdays, at('2026-10-07T09:00:00Z'));
    assert.equal(new Date(next).toISOString(), '2026-10-07T11:00:00.000Z');
  });

  it('dentro do horário devolve o próprio instante', () => {
    const now = at('2026-10-07T14:00:00Z');
    assert.equal(nextOpening(weekdays, now), now);
  });

  it('sem agenda devolve null', () => {
    assert.equal(nextOpening(null, Date.now()), null);
  });
});

describe('planScheduleChange', () => {
  const inside = at('2026-10-07T14:00:00Z');
  const outside = at('2026-10-07T22:00:00Z');

  it('abre quando a janela começa e ainda não aplicou', () => {
    const plan = planScheduleChange({ schedule: weekdays, lastDesired: false, status: 'closed' }, inside);
    assert.deepEqual(plan, { status: 'open', opensAt: null, desired: true });
  });

  it('fecha ao sair da janela e guarda a próxima abertura', () => {
    const plan = planScheduleChange({ schedule: weekdays, lastDesired: true, status: 'open' }, outside);
    assert.equal(plan.status, 'closed');
    assert.equal(plan.desired, false);
    assert.equal(new Date(plan.opensAt).toISOString(), '2026-10-08T11:00:00.000Z');
  });

  it('aplica na primeira execução (lastDesired ausente)', () => {
    const plan = planScheduleChange({ schedule: weekdays, lastDesired: undefined, status: 'open' }, outside);
    assert.equal(plan.status, 'closed');
  });

  it('não mexe quando nada mudou, preservando ação manual', () => {
    assert.equal(planScheduleChange({ schedule: weekdays, lastDesired: true, status: 'paused' }, inside), null);
    assert.equal(planScheduleChange({ schedule: weekdays, lastDesired: false, status: 'open' }, outside), null);
  });

  it('só atualiza a previsão de abertura quando fechada fora do horário', () => {
    const plan = planScheduleChange({ schedule: weekdays, lastDesired: false, status: 'closed', currentOpensAt: null }, outside);
    assert.equal(plan.status, null);
    assert.equal(new Date(plan.opensAt).toISOString(), '2026-10-08T11:00:00.000Z');
    const same = planScheduleChange(
      { schedule: weekdays, lastDesired: false, status: 'closed', currentOpensAt: plan.opensAt },
      outside,
    );
    assert.equal(same, null);
  });

  it('sem agenda válida não faz nada', () => {
    assert.equal(planScheduleChange({ schedule: { enabled: false }, lastDesired: true, status: 'open' }, inside), null);
  });
});
