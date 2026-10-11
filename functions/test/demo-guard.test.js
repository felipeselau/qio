const test = require('node:test');
const assert = require('node:assert/strict');
const { assertEmulatorEnv, isLocalHost } = require('../scripts/demo/guard');

const local = {
  FIRESTORE_EMULATOR_HOST: 'localhost:8080',
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  FIREBASE_DATABASE_EMULATOR_HOST: 'localhost:9000',
};

test('aceita os três emuladores em localhost', () => {
  const hosts = assertEmulatorEnv(local);
  assert.equal(hosts.firestore, 'localhost:8080');
  assert.equal(hosts.auth, '127.0.0.1:9099');
});

test('aceita ::1 e prefixo http', () => {
  assert.ok(isLocalHost('[::1]:8080'));
  assert.ok(isLocalHost('http://localhost:9000'));
});

test('recusa quando alguma variável falta', () => {
  for (const name of Object.keys(local)) {
    const env = { ...local };
    delete env[name];
    assert.throws(() => assertEmulatorEnv(env), new RegExp(name));
  }
  assert.throws(() => assertEmulatorEnv({}), /Recusado/);
});

test('recusa host que não é local', () => {
  for (const name of Object.keys(local)) {
    assert.throws(() => assertEmulatorEnv({ ...local, [name]: 'firestore.googleapis.com:443' }), /localhost/);
    assert.throws(() => assertEmulatorEnv({ ...local, [name]: '10.0.0.5:8080' }), /localhost/);
    assert.throws(() => assertEmulatorEnv({ ...local, [name]: 'localhost.evil.com:8080' }), /localhost/);
  }
});

test('o CLI recusa sem variáveis de emulator e sem --dry-run', () => {
  const { spawnSync } = require('node:child_process');
  const path = require('node:path');
  const env = { ...process.env };
  for (const name of Object.keys(local)) delete env[name];
  const run = spawnSync(process.execPath, [path.join(__dirname, '../scripts/demo/index.js')], { env, encoding: 'utf8' });
  assert.equal(run.status, 1);
  assert.match(run.stderr, /Recusado/);
});
