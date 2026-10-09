const { initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const { countWaiting } = require('../src/ticket');

async function main() {
  initializeApp();
  const db = getDatabase();
  const snap = await db.ref('queues').once('value');
  const updates = {};
  let queues = 0;
  snap.forEach((queue) => {
    if (!queue.child('meta/name').exists()) return;
    const entries = {};
    queue.child('entries').forEach((entry) => {
      const val = entry.val();
      if (val) entries[entry.key] = val;
    });
    updates[`queues/${queue.key}/meta/waitingCount`] = countWaiting(entries);
    queues += 1;
  });
  if (queues > 0) {
    await db.ref().update(updates);
  }
  console.log(`waitingCount gravado em ${queues} filas`);
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error(err);
    process.exit(1);
  },
);
