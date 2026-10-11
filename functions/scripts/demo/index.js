#!/usr/bin/env node
'use strict';

const { buildUniverse, DEFAULT_DAYS, DEFAULT_SEED } = require('./build');
const { summarize } = require('./stats');
const { assertEmulatorEnv } = require('./guard');

function parseArgs(argv) {
  const opts = { reset: false, dryRun: false, days: DEFAULT_DAYS, seed: DEFAULT_SEED, now: Date.now(), only: undefined };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--reset') opts.reset = true;
    else if (arg === '--dry-run') opts.dryRun = true;
    else if (arg === '--days') opts.days = Number(argv[(i += 1)]);
    else if (arg === '--seed') opts.seed = String(argv[(i += 1)]);
    else if (arg === '--now') opts.now = Date.parse(argv[(i += 1)]);
    else if (arg === '--only') opts.only = String(argv[(i += 1)]).split(',');
    else throw new Error(`Argumento desconhecido: ${arg}`);
  }
  if (!Number.isInteger(opts.days) || opts.days < 1 || opts.days > 400) throw new Error('--days deve ser inteiro entre 1 e 400');
  if (!Number.isFinite(opts.now)) throw new Error('--now inválido');
  return opts;
}

function printSummary(universe) {
  const rows = summarize(universe).map(({ id, ...rest }) => ({ fila: id, ...rest }));
  console.table(rows);
  const docs = universe.queues.reduce((n, q) => n + q.history.length, 0);
  const fb = universe.queues.reduce((n, q) => n + q.feedback.length, 0);
  console.log(
    `${universe.owners.length} donos, ${universe.auth.length} contas, ${universe.queues.length} filas, ${docs} atendimentos, ${fb} avaliações`,
  );
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (!opts.dryRun) assertEmulatorEnv();
  const started = Date.now();
  const universe = buildUniverse(opts);
  if (opts.dryRun) {
    printSummary(universe);
    return;
  }
  const { connect, seedUniverse } = require('./seed');
  const conn = connect();
  await seedUniverse(universe, { conn, reset: opts.reset, log: (m) => console.log(m) });
  printSummary(universe);
  console.log(`Concluído em ${Math.round((Date.now() - started) / 1000)}s. Credenciais: docs/demo/README.md`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err.message ?? err);
    process.exit(1);
  });
