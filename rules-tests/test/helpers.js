import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const root = new URL('../../', import.meta.url);

export const OWNER = 'owner';
export const OPERATOR = 'operator';
export const STRANGER = 'stranger';
export const QUEUE = 'q1';

export async function setupEnv() {
  return initializeTestEnvironment({
    projectId: 'demo-qio',
    firestore: { rules: readFileSync(new URL('firestore.rules', root), 'utf8') },
    database: { rules: readFileSync(new URL('database.rules.json', root), 'utf8') },
  });
}
