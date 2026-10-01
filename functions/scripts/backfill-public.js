const { initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');

async function main() {
  initializeApp();
  const db = getDatabase();
  const snap = await db.ref('queues').once('value');
  const updates = {};
  let count = 0;
  snap.forEach((queue) => {
    const entries = queue.child('entries');
    entries.forEach((entry) => {
      const val = entry.val();
      if (val && (val.status === 'waiting' || val.status === 'called')) {
        updates[`queues/${queue.key}/public/${entry.key}`] = {
          ticket: val.ticket,
          status: val.status,
        };
        count += 1;
      }
    });
  });
  if (count > 0) {
    await db.ref().update(updates);
  }
  console.log(`public populado para ${count} entries ativas`);
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error(err);
    process.exit(1);
  },
);
