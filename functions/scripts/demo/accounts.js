'use strict';

const DEMO_PASSWORD = 'qio-demo-2026';
const EMAIL_DOMAIN = 'qio.demo';
const ID_PREFIX = 'demo-';

const week = (weekday, sat = null, sun = null) => [sun, weekday, weekday, weekday, weekday, weekday, sat];

function makeSlots(ranges, stepMin, capacity) {
  const slots = [];
  for (const [from, to] of ranges) {
    const [fh, fm] = from.split(':').map(Number);
    const [th, tm] = to.split(':').map(Number);
    for (let m = fh * 60 + fm; m < th * 60 + tm; m += stepMin) {
      const hh = String(Math.floor(m / 60)).padStart(2, '0');
      const mm = String(m % 60).padStart(2, '0');
      slots.push({ id: `s${hh}${mm}`, start: `${hh}:${mm}`, capacity });
    }
  }
  return slots;
}

const OPERATORS = [
  { key: 'operador1', name: 'Marina Lopes', factor: 0.8 },
  { key: 'operador2', name: 'Rafael Teixeira', factor: 1.0 },
  { key: 'operador3', name: 'Juliana Prado', factor: 1.3 },
  { key: 'operador4', name: 'Carlos Mendes', factor: 1.0 },
  { key: 'operador5', name: 'Beatriz Nunes', factor: 1.1 },
  { key: 'barbeiro1', name: 'Thiago Ramos', factor: 0.9 },
  { key: 'barbeiro2', name: 'Caio Freitas', factor: 1.15 },
  { key: 'atendente1', name: 'Patrícia Gomes', factor: 1.2 },
  { key: 'atendente2', name: 'Sérgio Batista', factor: 1.5 },
  { key: 'atendente3', name: 'Luana Cardoso', factor: 0.95 },
  { key: 'balconista1', name: 'Davi Ribeiro', factor: 0.85 },
].map((o) => ({ ...o, uid: `${ID_PREFIX}${o.key}`, email: `${o.key}@${EMAIL_DOMAIN}` }));

const WEEKDAY_ALL = [0, 1, 2, 3, 4, 5, 6];

const padaria = {
  key: 'padaria',
  displayName: 'Helena Duarte',
  businessName: 'Padaria Pão Quente',
  factor: 1.0,
  ddd: [41],
  groups: [],
  queues: [
    {
      key: 'balcao',
      name: 'Balcão',
      description: 'Pães, doces e café: pegue sua senha e aguarde ser chamado.',
      avgServiceMin: 3,
      brandColor: '#C2410C',
      slug: 'paopquente',
      posterTitle: 'Entre na fila pelo celular',
      createdDaysAgo: 200,
      invite: 'valid',
      expiry: { enabled: true, hours: 4, clearOnClose: false, resetTicketDaily: true },
      hours: week([6, 20], [6, 20], [6, 14]),
      hourly: { 6: 0.8, 7: 2.4, 8: 3, 9: 2.2, 10: 1, 11: 1, 12: 1.3, 13: 0.8, 14: 0.6, 15: 0.9, 16: 2, 17: 2.4, 18: 1.4, 19: 0.6 },
      demand: { base: 150, dow: [1.35, 0.95, 0.9, 0.9, 0.95, 1.05, 1.4], trend: [[120, 1], [32, 1], [26, 1.15], [0, 1.15]], noise: 0.12 },
      service: { median: 2.2, sigma: 0.35, outlierProb: 0.01, outlierMult: [2, 3] },
      patience: { median: 14, sigma: 0.6 },
      noShow: { base: 0.015 },
      recallProb: 0.05,
      skipProb: 0.01,
      manualShare: 0.1,
      rating: { mean: 4.75, sd: 0.75, refWait: 5 },
      ratingRate: 0.5,
      staff: [{ ref: 'owner' }, { ref: 'balconista1', shifts: [[7, 10], [16, 19]], days: [0, 6] }],
      live: { waiting: 6, called: 1 },
    },
    {
      key: 'encomendas',
      name: 'Encomendas',
      description: 'Retirada de bolos, tortas e encomendas de festa.',
      avgServiceMin: 5,
      brandColor: '#C2410C',
      createdDaysAgo: 170,
      hours: week([7, 19], [7, 19], [7, 13]),
      hourly: { 9: 1, 10: 1.4, 11: 1.6, 12: 1, 15: 1.4, 16: 1.6, 17: 1.4, 18: 0.8 },
      demand: { base: 22, dow: [1.5, 0.8, 0.8, 0.9, 0.9, 1.2, 1.6], trend: [[120, 1], [32, 1], [26, 1.15], [0, 1.15]], noise: 0.2 },
      service: { median: 4.5, sigma: 0.4, outlierProb: 0.02, outlierMult: [2, 3] },
      patience: { median: 20, sigma: 0.6 },
      noShow: { base: 0.02 },
      manualShare: 0.15,
      rating: { mean: 4.6, sd: 0.8, refWait: 6 },
      ratingRate: 0.45,
      staff: [{ ref: 'owner', factor: 1.1 }],
      live: { waiting: 2, called: 0 },
    },
  ],
};

const clinica = {
  key: 'clinica',
  displayName: 'Dra. Renata Albuquerque',
  businessName: 'Clínica Vida Plena',
  factor: 1.0,
  ddd: [11],
  groups: [
    { key: 'centro', name: 'Unidade Centro' },
    { key: 'norte', name: 'Unidade Norte' },
  ],
  queues: [
    {
      key: 'consultas',
      name: 'Consultas',
      description: 'Consultas com hora marcada, clínica geral e especialidades.',
      group: 'centro',
      avgServiceMin: 15,
      brandColor: '#0F766E',
      slug: 'vidaplena',
      posterTitle: 'Chegou? Entre na fila da consulta',
      createdDaysAgo: 220,
      mode: 'schedule',
      slotPlan: { ranges: [['08:00', '17:00']], stepMin: 30, capacity: 2 },
      alerts: { enabled: true, maxNoShowPct: 20, idleMin: 30, cooldownMin: 60 },
      expiry: { enabled: true, hours: 12, clearOnClose: true, resetTicketDaily: true },
      hours: week([8, 17]),
      fill: { base: 0.72, dow: [0, 0.95, 0.85, 0.85, 0.85, 0.75, 0], trend: [[120, 1], [0, 1.05]] },
      lead: { median: 22, sigma: 0.6 },
      service: { median: 13, sigma: 0.4, outlierProb: 0.03, outlierMult: [2, 3] },
      patience: { median: 90, sigma: 0.5 },
      noShow: {
        base: 0.1,
        dow: [0, 0.05, 0, 0, 0, 0.01, 0],
        early: 0.04,
        trend: [[120, 0.025], [48, 0.025], [32, -0.025], [0, -0.025]],
      },
      recallProb: 0.1,
      skipProb: 0.02,
      manualShare: 0.1,
      rating: { mean: 4.4, sd: 0.8, refWait: 20 },
      ratingRate: 0.4,
      staff: [{ ref: 'operador1' }, { ref: 'operador2' }, { ref: 'operador3' }],
      live: { waiting: 4, called: 1 },
    },
    {
      key: 'exames',
      name: 'Exames',
      description: 'Coleta de sangue e exames de imagem por ordem de chegada.',
      group: 'centro',
      avgServiceMin: 8,
      brandColor: '#0F766E',
      createdDaysAgo: 220,
      invite: 'expired',
      alerts: { enabled: true, maxWaitMin: 30, maxNoShowPct: 25, idleMin: 45, cooldownMin: 30 },
      alertStateAgoMin: { noShowAt: 95, waitAt: 180 },
      expiry: { enabled: true, hours: 12, clearOnClose: true, resetTicketDaily: true },
      hours: week([7, 16], [7, 11]),
      hourly: { 7: 3, 8: 3, 9: 2, 10: 1.4, 11: 1, 12: 0.7, 13: 0.8, 14: 1.2, 15: 0.8 },
      demand: { base: 52, dow: [0, 1.25, 1, 0.95, 0.95, 0.9, 0.7], noise: 0.15 },
      service: { median: 8, sigma: 0.5, outlierProb: 0.04, outlierMult: [2, 4] },
      patience: { median: 45, sigma: 0.6 },
      noShow: {
        base: 0.11,
        dow: [0, 0.04, 0, 0, 0, 0.01, 0],
        early: 0.04,
        trend: [[120, 0.025], [48, 0.025], [32, -0.025], [0, -0.025]],
      },
      recallProb: 0.1,
      skipProb: 0.03,
      manualShare: 0.12,
      rating: { mean: 4.2, sd: 0.85, refWait: 15 },
      ratingRate: 0.4,
      staff: [{ ref: 'operador2' }, { ref: 'operador3' }],
      live: { waiting: 5, called: 1 },
    },
    {
      key: 'pediatria',
      name: 'Pediatria',
      description: 'Atendimento pediátrico com hora marcada.',
      group: 'norte',
      avgServiceMin: 20,
      brandColor: '#0F766E',
      createdDaysAgo: 150,
      mode: 'schedule',
      slotPlan: { ranges: [['08:00', '12:00'], ['14:00', '17:00']], stepMin: 30, capacity: 1 },
      anonymizePhone: true,
      status: 'paused',
      statusMessage: 'Pausa para o almoço da equipe. Voltamos em instantes.',
      resumeInMin: 40,
      expiry: { enabled: true, hours: 12, clearOnClose: true, resetTicketDaily: true },
      hours: week([8, 17]),
      fill: { base: 0.8, dow: [0, 0.95, 0.85, 0.85, 0.85, 0.8, 0], trend: [[120, 1], [0, 1.05]] },
      lead: { median: 20, sigma: 0.5 },
      service: { median: 18, sigma: 0.35, outlierProb: 0.03, outlierMult: [1.8, 2.6] },
      patience: { median: 90, sigma: 0.5 },
      noShow: {
        base: 0.12,
        dow: [0, 0.05, 0, 0, 0, 0.01, 0],
        early: 0.04,
        trend: [[120, 0.025], [48, 0.025], [32, -0.025], [0, -0.025]],
      },
      recallProb: 0.12,
      skipProb: 0.02,
      rating: { mean: 4.5, sd: 0.75, refWait: 20 },
      ratingRate: 0.45,
      staff: [{ ref: 'operador1' }, { ref: 'operador3' }],
      live: { waiting: 2, called: 0 },
    },
    {
      key: 'resultados',
      name: 'Retirada de resultados',
      description: 'Retire laudos e resultados de exames.',
      group: 'norte',
      avgServiceMin: 3,
      brandColor: '#0F766E',
      createdDaysAgo: 150,
      schedule: { windows: [{ days: [1, 2, 3, 4, 5], open: '08:00', close: '18:00' }, { days: [6], open: '08:00', close: '12:00' }] },
      closedNow: true,
      expiry: { enabled: true, hours: 12, clearOnClose: true, resetTicketDaily: true },
      hours: week([8, 18], [8, 12]),
      hourly: { 8: 1.2, 9: 1.4, 10: 1.4, 11: 1.1, 12: 0.6, 13: 0.8, 14: 1.2, 15: 1.3, 16: 1.2, 17: 0.9 },
      demand: { base: 30, dow: [0, 1.2, 1, 1, 0.95, 0.9, 0.8], noise: 0.2 },
      service: { median: 2.8, sigma: 0.4, outlierProb: 0.02, outlierMult: [2, 3] },
      patience: { median: 25, sigma: 0.6 },
      noShow: { base: 0.06 },
      manualShare: 0.1,
      rating: { mean: 4.5, sd: 0.75, refWait: 8 },
      ratingRate: 0.4,
      staff: [{ ref: 'operador3' }],
    },
  ],
};

const barbearia = {
  key: 'barbearia',
  displayName: 'Rodrigo Almeida',
  businessName: 'Barbearia Navalha',
  factor: 1.0,
  ddd: [21],
  groups: [],
  queues: [
    {
      key: 'agendados',
      name: 'Hora marcada',
      description: 'Corte e barba com horário reservado.',
      avgServiceMin: 35,
      brandColor: '#334155',
      slug: 'navalha',
      posterTitle: 'Chegou no horário? Entre na fila',
      createdDaysAgo: 140,
      mode: 'schedule',
      slotPlan: { ranges: [['09:00', '19:00']], stepMin: 30, capacity: 1 },
      hours: week([9, 19], [9, 19]),
      fill: { base: 0.8, dow: [0, 0.75, 0.75, 0.8, 0.9, 1.1, 1.22], trend: [[120, 1], [0, 1.05]] },
      lead: { median: 12, sigma: 0.5 },
      service: { median: 33, sigma: 0.22, outlierProb: 0.03, outlierMult: [1.4, 1.8] },
      patience: { median: 120, sigma: 0.4 },
      noShow: { base: 0.05, dow: [0, 0.02, 0, 0, 0, 0, 0] },
      recallProb: 0.2,
      skipProb: 0.06,
      rating: { mean: 5.1, sd: 0.55, refWait: 12 },
      ratingRate: 0.5,
      staff: [{ ref: 'barbeiro1' }, { ref: 'barbeiro2' }],
      live: { waiting: 3, called: 1 },
    },
    {
      key: 'passagem',
      name: 'Fila de passagem',
      description: 'Sem horário? Entre na fila e seja chamado por ordem de chegada.',
      avgServiceMin: 30,
      brandColor: '#334155',
      createdDaysAgo: 140,
      hours: week([9, 19], [9, 19]),
      hourly: { 9: 1, 10: 1.3, 11: 1.3, 12: 1, 13: 0.8, 14: 1.2, 15: 1.5, 16: 1.6, 17: 1.6, 18: 1.2 },
      demand: { base: 12, dow: [0, 0.7, 0.7, 0.8, 0.9, 1.3, 1.9], noise: 0.2 },
      service: { median: 30, sigma: 0.25, outlierProb: 0.03, outlierMult: [1.4, 1.8] },
      patience: { median: 40, sigma: 0.5 },
      noShow: { base: 0.04 },
      recallProb: 0.18,
      skipProb: 0.1,
      manualShare: 0.2,
      rating: { mean: 4.8, sd: 0.55, refWait: 25 },
      ratingRate: 0.5,
      staff: [{ ref: 'barbeiro1', factor: 0.9 }, { ref: 'barbeiro2' }],
      live: { waiting: 3, called: 1 },
    },
  ],
};

const cartorio = {
  key: 'cartorio',
  displayName: 'Antônio Carvalho',
  businessName: 'Cartório Central',
  factor: 1.0,
  ddd: [31],
  groups: [
    { key: 'civil', name: 'Registro Civil' },
    { key: 'notas', name: 'Notas e Protestos' },
  ],
  queues: [
    {
      key: 'certidoes',
      name: 'Certidões',
      description: 'Segunda via de certidões de nascimento, casamento e óbito.',
      group: 'civil',
      avgServiceMin: 9,
      maxWaiting: 60,
      brandColor: '#2563EB',
      slug: 'cartorio-central',
      createdDaysAgo: 400,
      invite: 'valid',
      alerts: { enabled: true, maxWaitMin: 45, idleMin: 20, cooldownMin: 30 },
      alertStateAgoMin: { waitAt: 12 },
      hours: week([8, 17]),
      hourly: { 8: 1.4, 9: 1.8, 10: 1.8, 11: 1.4, 12: 0.8, 13: 1.2, 14: 1.4, 15: 1.2, 16: 1 },
      demand: { base: 125, dow: [0, 1.3, 1.05, 0.95, 0.95, 0.9, 0], trend: [[120, 1], [0, 1.25]], noise: 0.18 },
      service: { median: 8.5, sigma: 0.55, outlierProb: 0.06, outlierMult: [3, 5], trend: [[120, 0.92], [0, 1.15]] },
      patience: { median: 80, sigma: 0.6 },
      noShow: { base: 0.07 },
      recallProb: 0.15,
      skipProb: 0.03,
      manualShare: 0.15,
      rating: { mean: 3.6, sd: 0.95, waitSens: 0.35, refWait: 25 },
      ratingRate: 0.35,
      staff: [{ ref: 'operador1' }, { ref: 'atendente1' }, { ref: 'atendente2' }],
      live: { waiting: 38, called: 2 },
    },
    {
      key: 'casamentos',
      name: 'Casamentos e uniões',
      description: 'Habilitação de casamento e registro de união estável.',
      group: 'civil',
      avgServiceMin: 20,
      brandColor: '#2563EB',
      createdDaysAgo: 400,
      invite: 'valid',
      hours: week([8, 17]),
      hourly: { 8: 1, 9: 1.4, 10: 1.4, 11: 1.2, 12: 0.6, 13: 1, 14: 1.2, 15: 1, 16: 0.8 },
      demand: { base: 28, dow: [0, 1.1, 1, 1, 1, 0.9, 0], noise: 0.2 },
      service: { median: 19, sigma: 0.5, outlierProb: 0.06, outlierMult: [2, 3.5], trend: [[120, 0.95], [0, 1.1]] },
      patience: { median: 90, sigma: 0.5 },
      noShow: { base: 0.08 },
      recallProb: 0.1,
      skipProb: 0.02,
      rating: { mean: 3.2, sd: 0.9, waitSens: 0.3, refWait: 30 },
      ratingRate: 0.35,
      staff: [{ ref: 'operador4' }],
      live: { waiting: 9, called: 1 },
      pendingRequest: 'operador5',
    },
    {
      key: 'nascimentos',
      name: 'Nascimentos e óbitos',
      description: 'Registro de nascimento e de óbito.',
      group: 'civil',
      avgServiceMin: 12,
      brandColor: '#2563EB',
      createdDaysAgo: 300,
      hours: week([8, 17]),
      hourly: { 8: 1.2, 9: 1.5, 10: 1.5, 11: 1.2, 12: 0.7, 13: 1, 14: 1.2, 15: 1, 16: 0.8 },
      demand: { base: 30, dow: [0, 1.2, 1, 1, 0.95, 0.9, 0], noise: 0.2 },
      service: { median: 11, sigma: 0.5, outlierProb: 0.06, outlierMult: [2.5, 4], trend: [[120, 0.93], [0, 1.15]] },
      patience: { median: 80, sigma: 0.5 },
      noShow: { base: 0.06 },
      recallProb: 0.12,
      skipProb: 0.03,
      rating: { mean: 3.3, sd: 0.9, waitSens: 0.3, refWait: 25 },
      ratingRate: 0.35,
      staff: [{ ref: 'atendente3' }, { ref: 'operador4' }],
      live: { waiting: 7, called: 1 },
    },
    {
      key: 'escrituras',
      name: 'Escrituras',
      description: 'Compra e venda, doações, inventários e escrituras públicas.',
      group: 'notas',
      avgServiceMin: 20,
      brandColor: '#2563EB',
      createdDaysAgo: 300,
      hours: week([8, 17]),
      hourly: { 8: 1, 9: 1.4, 10: 1.5, 11: 1.3, 12: 0.7, 13: 1, 14: 1.3, 15: 1.2, 16: 0.9 },
      demand: { base: 26, dow: [0, 1.1, 1, 1, 1, 0.95, 0], noise: 0.2 },
      service: { median: 19, sigma: 0.5, outlierProb: 0.06, outlierMult: [2, 4], trend: [[120, 0.93], [0, 1.12]] },
      patience: { median: 90, sigma: 0.5 },
      noShow: { base: 0.07 },
      recallProb: 0.1,
      skipProb: 0.02,
      rating: { mean: 3.3, sd: 0.9, waitSens: 0.3, refWait: 30 },
      ratingRate: 0.35,
      staff: [{ ref: 'operador4' }, { ref: 'atendente1' }],
      live: { waiting: 6, called: 1 },
    },
    {
      key: 'firma',
      name: 'Reconhecimento de firma',
      description: 'Reconhecimento de firma e autenticação de cópias.',
      group: 'notas',
      avgServiceMin: 5,
      maxWaiting: 30,
      brandColor: '#2563EB',
      createdDaysAgo: 400,
      alerts: { enabled: true, maxWaitMin: 30, maxNoShowPct: 20, cooldownMin: 30 },
      alertStateAgoMin: { waitAt: 9 },
      hours: week([8, 17]),
      hourly: { 8: 1.5, 9: 2, 10: 2, 11: 1.6, 12: 1, 13: 1.4, 14: 1.6, 15: 1.4, 16: 1.2 },
      demand: { base: 170, dow: [0, 1.3, 1.05, 1, 0.95, 0.9, 0], trend: [[120, 1], [0, 1.25]], noise: 0.18 },
      service: { median: 4.5, sigma: 0.55, outlierProb: 0.06, outlierMult: [3, 6], trend: [[120, 0.95], [0, 1.15]] },
      patience: { median: 60, sigma: 0.6 },
      noShow: { base: 0.08 },
      recallProb: 0.15,
      skipProb: 0.03,
      manualShare: 0.15,
      rating: { mean: 3.5, sd: 1, waitSens: 0.4, refWait: 25 },
      ratingRate: 0.35,
      staff: [{ ref: 'atendente2' }, { ref: 'atendente3' }],
      live: { waiting: 30, called: 1 },
    },
    {
      key: 'protestos',
      name: 'Protestos',
      description: 'Consulta, pagamento e cancelamento de protestos.',
      group: 'notas',
      avgServiceMin: 12,
      brandColor: '#2563EB',
      createdDaysAgo: 300,
      hours: week([8, 17]),
      hourly: { 8: 1, 9: 1.3, 10: 1.5, 11: 1.3, 12: 0.8, 13: 1, 14: 1.3, 15: 1.2, 16: 1 },
      demand: { base: 32, dow: [0, 1.15, 1, 1, 1, 0.95, 0], noise: 0.2 },
      service: { median: 11, sigma: 0.55, outlierProb: 0.06, outlierMult: [2.5, 4], trend: [[120, 0.93], [0, 1.15]] },
      patience: { median: 80, sigma: 0.5 },
      noShow: { base: 0.07 },
      recallProb: 0.12,
      skipProb: 0.03,
      rating: { mean: 3.1, sd: 0.9, waitSens: 0.3, refWait: 25 },
      ratingRate: 0.35,
      staff: [{ ref: 'atendente3' }, { ref: 'atendente1' }],
      live: { waiting: 8, called: 1 },
    },
  ],
};

const foodtruck = {
  key: 'foodtruck',
  displayName: 'Bianca Rocha',
  businessName: 'Food Truck Festival',
  factor: 1.0,
  ddd: [47],
  groups: [],
  queues: [
    {
      key: 'pedidos',
      name: 'Pedidos do truck',
      description: 'Retire seu pedido: hambúrguer artesanal e batata rústica.',
      avgServiceMin: 4,
      brandColor: '#B91C1C',
      posterTitle: 'Peça sem ficar na fila',
      createdDaysAgo: 17,
      status: 'closed',
      holidays: false,
      closureProb: 0,
      activeDay: ({ daysAgo, dow }) => {
        if (![5, 6, 0].includes(dow)) return false;
        const lastSunday = (dow + daysAgo) % 7 || 7;
        const sunday = daysAgo - ((7 - dow) % 7);
        return sunday === lastSunday || sunday === lastSunday + 7;
      },
      hours: [[12, 21], null, null, null, null, [17, 23], [12, 23]],
      hourly: { 12: 1, 13: 1.4, 14: 1, 15: 0.6, 16: 0.6, 17: 1, 18: 1.6, 19: 2, 20: 1.8, 21: 1.2, 22: 0.8 },
      demand: { base: 70, dow: [0.9, 0, 0, 0, 0, 0.8, 1.3], noise: 0.2 },
      bursts: { perDay: [3, 5], size: [14, 30], spreadMin: 7 },
      service: { median: 4.2, sigma: 0.4, outlierProb: 0.03, outlierMult: [2, 3] },
      patience: { median: 11, sigma: 0.55 },
      noShow: { base: 0.06 },
      recallProb: 0.1,
      skipProb: 0.03,
      manualShare: 0.1,
      rating: { mean: 4.2, sd: 0.9, waitSens: 0.3, refWait: 10 },
      ratingRate: 0.4,
      staff: [{ ref: 'owner' }],
    },
  ],
};

const OTICA_STORES = [
  { key: 'centro', name: 'Loja Shopping Centro', color: '#7C3AED', mult: 1.2, createdDaysAgo: 60, sunday: [12, 18] },
  { key: 'norte', name: 'Loja Shopping Norte', color: '#BE185D', mult: 1.0, createdDaysAgo: 52, sunday: [12, 18] },
  { key: 'ruaxv', name: 'Loja Rua XV', color: '#047857', mult: 0.7, createdDaysAgo: 45, sunday: null },
  { key: 'jardins', name: 'Loja Jardins', color: '#2563EB', mult: 0.5, createdDaysAgo: 34, sunday: null },
];

const OTICA_TYPES = [
  { key: 'atendimento', name: 'Atendimento geral', desc: 'Armações, lentes e orçamentos.', base: 14, svc: 7, sigma: 0.4, patience: 18, avg: 7 },
  { key: 'exame', name: 'Exame de vista', desc: 'Exame de acuidade visual com hora marcada.', schedule: true, svc: 24, sigma: 0.3, avg: 25 },
  { key: 'retirada', name: 'Retirada de óculos', desc: 'Retire seus óculos prontos.', base: 10, svc: 4, sigma: 0.35, patience: 12, avg: 4 },
  { key: 'assistencia', name: 'Assistência técnica', desc: 'Ajustes, reparos e troca de parafusos.', base: 6, svc: 11, sigma: 0.6, patience: 25, avg: 12 },
  { key: 'lentes', name: 'Lentes de contato', desc: 'Adaptação e entrega de lentes de contato.', base: 5, svc: 15, sigma: 0.45, patience: 30, avg: 15 },
];

function oticaQueues() {
  const out = [];
  OTICA_STORES.forEach((store, si) => {
    OTICA_TYPES.forEach((type, ti) => {
      const n = si * OTICA_TYPES.length + ti;
      const hours = week([9, 19], [9, 15], store.sunday);
      const queue = {
        key: `${store.key}-${type.key}`,
        name: type.name,
        description: `${type.desc} (${store.name})`,
        group: store.key,
        avgServiceMin: type.avg,
        brandColor: store.color,
        createdDaysAgo: store.createdDaysAgo - (ti % 3) * 3,
        hours,
        service: { median: type.svc, sigma: type.sigma, outlierProb: 0.02, outlierMult: [2, 3] },
        patience: { median: type.patience ?? 60, sigma: 0.6 },
        noShow: { base: type.schedule ? 0.09 : 0.03 },
        recallProb: 0.06,
        skipProb: 0.02,
        manualShare: 0.1,
        rating: { mean: 3.9 + ((n * 7) % 9) * 0.1, sd: 0.8, refWait: 10 },
        ratingRate: 0.35 + ((n * 3) % 5) * 0.03,
        staff: [{ ref: 'owner', factor: 0.9 + ((n * 5) % 7) * 0.08 }],
        live: n % 4 === 0 ? { waiting: 1 + (n % 5), called: n % 3 === 0 ? 1 : 0 } : undefined,
      };
      if (type.schedule) {
        queue.mode = 'schedule';
        queue.slotPlan = { ranges: [['09:00', '18:30']], stepMin: 30, capacity: 1 };
        queue.fill = { base: 0.45 * store.mult + 0.25, dow: [0.9, 0.8, 0.8, 0.85, 0.9, 1, 1.2], trend: [[60, 0.9], [0, 1.1]] };
        queue.lead = { median: 15, sigma: 0.5 };
      } else {
        queue.hourly = { 10: 1.1, 11: 1.3, 12: 1, 13: 0.8, 14: 1, 15: 1.3, 16: 1.4, 17: 1.4, 18: 1 };
        queue.demand = {
          base: Math.max(3, type.base * store.mult),
          dow: [0.9, 0.8, 0.85, 0.9, 1, 1.1, 1.5],
          trend: [[60, 0.9], [0, 1.1]],
          noise: 0.25,
        };
      }
      if (n === 3) {
        queue.status = 'paused';
        queue.statusMessage = 'Em manutenção do equipamento. Volta em breve.';
        queue.resumeInMin = 90;
      }
      if (n === 7 || n === 13) queue.status = 'closed';
      if (n % 6 === 2) queue.maxWaiting = 15;
      if (n === 0) queue.slug = 'otica-visao-centro';
      out.push(queue);
    });
  });
  return out;
}

const otica = {
  key: 'otica',
  displayName: 'Marcos Tavares',
  businessName: 'Rede Ótica Visão',
  factor: 1.0,
  ddd: [41, 41, 42],
  groups: OTICA_STORES.map((s) => ({ key: s.key, name: s.name })),
  queues: oticaQueues(),
};

const novo = {
  key: 'novo',
  displayName: 'Lívia Torres',
  businessName: '',
  factor: 1.0,
  ddd: [11],
  groups: [],
  queues: [],
  freshAgoMin: 8,
};

const OWNERS = [padaria, clinica, barbearia, cartorio, foodtruck, otica, novo].map((o) => ({
  ...o,
  uid: `${ID_PREFIX}${o.key}`,
  email: `${o.key === 'novo' ? 'novo' : o.key}@${EMAIL_DOMAIN}`,
}));

OWNERS.forEach((o) => {
  if (o.key === 'padaria') o.email = `padaria@${EMAIL_DOMAIN}`;
});

module.exports = {
  DEMO_PASSWORD,
  EMAIL_DOMAIN,
  ID_PREFIX,
  OPERATORS,
  OWNERS,
  WEEKDAY_ALL,
  makeSlots,
  week,
  requestStatuses: [
    { queue: 'padaria/encomendas', op: 'barbeiro2', status: 'rejected' },
    { queue: 'clinica/consultas', op: 'atendente3', status: 'removed' },
  ],
};
