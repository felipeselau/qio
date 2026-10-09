const { initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const { getFirestore } = require('firebase-admin/firestore');
const { planWaitingCount, writeWaitingCount, mapLimit } = require('../src/waiting');

const dryRun = process.argv.includes('--dry-run');

async function main() {
  const options = {};
  if (process.env.GOOGLE_CLOUD_PROJECT) options.projectId = process.env.GOOGLE_CLOUD_PROJECT;
  if (process.env.FIREBASE_DATABASE_URL) options.databaseURL = process.env.FIREBASE_DATABASE_URL;
  initializeApp(options);
  const db = getDatabase();
  const ids = (await getFirestore().collection('queues').select().get()).docs.map((d) => d.id);
  const totals = { total: ids.length, written: 0, same: 0, skipped: 0 };

  await mapLimit(ids, 5, async (queueId) => {
    const [metaSnap, publicSnap] = await Promise.all([
      db.ref(`queues/${queueId}/meta`).once('value'),
      db.ref(`queues/${queueId}/public`).once('value'),
    ]);
    const plan = planWaitingCount(metaSnap.val(), publicSnap.val());
    if (plan.action === 'missing' || plan.action === 'deleting') {
      totals.skipped += 1;
      return;
    }
    if (plan.action === 'same') {
      totals.same += 1;
      return;
    }
    if (dryRun) {
      console.log(`[dry-run] ${queueId}: waitingCount = ${plan.count}`);
      totals.written += 1;
      return;
    }
    const state = await writeWaitingCount(db, queueId, plan.count);
    if (state === 'written') totals.written += 1;
    else if (state === 'same') totals.same += 1;
    else totals.skipped += 1;
  });

  console.log(
    `${dryRun ? '[dry-run] ' : ''}filas: ${totals.total}, ` +
      `${dryRun ? 'a gravar' : 'gravadas'}: ${totals.written}, ` +
      `já corretas: ${totals.same}, ignoradas: ${totals.skipped}`,
  );
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error(err);
    process.exit(1);
  },
);
