'use strict';

const REQUIRED = [
  'FIRESTORE_EMULATOR_HOST',
  'FIREBASE_AUTH_EMULATOR_HOST',
  'FIREBASE_DATABASE_EMULATOR_HOST',
];

function hostOf(value) {
  const text = String(value ?? '').trim();
  if (text.startsWith('[')) return text.slice(1, text.indexOf(']'));
  return text.replace(/^[a-z]+:\/\//i, '').split('/')[0].split(':')[0];
}

function isLocalHost(value) {
  return ['localhost', '127.0.0.1', '::1'].includes(hostOf(value).toLowerCase());
}

function assertEmulatorEnv(env = process.env) {
  const missing = REQUIRED.filter((name) => !env[name]);
  if (missing.length > 0) {
    throw new Error(
      `Recusado: o universo demo só roda contra emuladores. Variáveis ausentes: ${missing.join(', ')}.`,
    );
  }
  const remote = REQUIRED.filter((name) => !isLocalHost(env[name]));
  if (remote.length > 0) {
    throw new Error(
      `Recusado: ${remote.join(', ')} não aponta para localhost/127.0.0.1. Nunca rode o seed contra produção.`,
    );
  }
  return {
    firestore: env.FIRESTORE_EMULATOR_HOST,
    auth: env.FIREBASE_AUTH_EMULATOR_HOST,
    database: env.FIREBASE_DATABASE_EMULATOR_HOST,
  };
}

module.exports = { REQUIRED, isLocalHost, assertEmulatorEnv };
