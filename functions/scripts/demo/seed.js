'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldPath } = require('firebase-admin/firestore');
const { getDatabase } = require('firebase-admin/database');
const { assertEmulatorEnv } = require('./guard');
const { scopeOf } = require('./build');
const { DEMO_PASSWORD, ID_PREFIX, EMAIL_DOMAIN } = require('./accounts');

const PROJECT_ID = process.env.DEMO_PROJECT_ID || 'qio-app';
const RTDB_PATHS = (id) => [`queues/${id}`, `owners/${id}`, `tickets/${id}`, `rateLimits/${id}`];

function connect(env = process.env) {
  const hosts = assertEmulatorEnv(env);
  delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const app = initializeApp(
    { projectId: PROJECT_ID, databaseURL: `http://${hosts.database}?ns=${PROJECT_ID}-default-rtdb` },
    `demo-seed-${Date.now()}`,
  );
  return { auth: getAuth(app), firestore: getFirestore(app), db: getDatabase(app), app };
}

async function mapLimit(items, limit, fn) {
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next;
      next += 1;
      await fn(items[index], index);
    }
  });
  await Promise.all(workers);
}

async function deleteUsers({ auth }, scope, reset, log) {
  const uids = new Set(scope.uids);
  if (reset) {
    let pageToken;
    do {
      const page = await auth.listUsers(1000, pageToken);
      for (const u of page.users) {
        if (u.email && u.email.endsWith(`@${EMAIL_DOMAIN}`)) uids.add(u.uid);
      }
      pageToken = page.pageToken;
    } while (pageToken);
  }
  for (const email of scope.emails) {
    try {
      const u = await auth.getUserByEmail(email);
      uids.add(u.uid);
    } catch (err) {
      if (err.code !== 'auth/user-not-found') throw err;
    }
  }
  const list = [...uids];
  for (let i = 0; i < list.length; i += 100) await auth.deleteUsers(list.slice(i, i + 100));
  log(`auth: ${list.length} contas removidas`);
}

async function wipe(conn, scope, { reset, log }) {
  const { firestore, db } = conn;
  const queueIds = new Set(scope.queueIds);
  const ownerUids = new Set(scope.uids);
  if (reset) {
    const snap = await firestore
      .collection('queues')
      .where(FieldPath.documentId(), '>=', ID_PREFIX)
      .where(FieldPath.documentId(), '<', `${ID_PREFIX}~`)
      .select()
      .get();
    snap.docs.forEach((d) => queueIds.add(d.id));
    const rtdbQueues = await db.ref('queues').orderByKey().startAt(ID_PREFIX).endAt(`${ID_PREFIX}~`).once('value');
    Object.keys(rtdbQueues.val() ?? {}).forEach((id) => queueIds.add(id));
  }

  const writer = firestore.bulkWriter({ throttling: false });
  await mapLimit([...queueIds], 4, (id) => firestore.recursiveDelete(firestore.doc(`queues/${id}`), writer));
  await mapLimit([...ownerUids], 4, (uid) => firestore.recursiveDelete(firestore.doc(`owners/${uid}`), writer));
  for (const slug of scope.slugs) writer.delete(firestore.doc(`queueSlugs/${slug}`)).catch(() => {});
  for (const code of scope.inviteCodes) writer.delete(firestore.doc(`operatorInvites/${code}`)).catch(() => {});
  for (let i = 0; i < scope.uids.length; i += 30) {
    const invites = await firestore.collection('operatorInvites').where('ownerId', 'in', scope.uids.slice(i, i + 30)).get();
    invites.docs.forEach((d) => writer.delete(d.ref).catch(() => {}));
  }
  await writer.close();

  const updates = {};
  for (const id of queueIds) for (const path of RTDB_PATHS(id)) updates[path] = null;
  if (Object.keys(updates).length > 0) await db.ref().update(updates);
  await deleteUsers(conn, scope, reset, log);
  log(`wipe: ${queueIds.size} filas, ${ownerUids.size} donos`);
}

async function createUsers({ auth }, universe, log) {
  for (const a of universe.auth) {
    await auth.createUser({
      uid: a.uid,
      email: a.email,
      password: DEMO_PASSWORD,
      displayName: a.displayName,
      emailVerified: true,
    });
  }
  log(`auth: ${universe.auth.length} contas criadas`);
}

async function writeFirestore({ firestore }, universe, log) {
  const writer = firestore.bulkWriter({ throttling: false });
  let failed = 0;
  writer.onWriteError((err) => {
    if (err.failedAttempts < 5) return true;
    failed += 1;
    console.error('write failed', err.documentRef.path, err.message);
    return false;
  });
  let count = 0;
  const set = (path, data) => {
    count += 1;
    writer.set(firestore.doc(path), data).catch(() => {});
  };

  for (const o of universe.owners) set(`owners/${o.uid}`, o.data);
  for (const g of universe.groups) set(`owners/${g.ownerUid}/groups/${g.id}`, g.data);
  for (const s of universe.slugs) set(`queueSlugs/${s.slug}`, s.data);
  for (const i of universe.invites) set(`operatorInvites/${i.code}`, i.data);
  for (const q of universe.queues) {
    set(`queues/${q.id}`, q.fs);
    for (const o of q.operators) set(`queues/${q.id}/operators/${o.uid}`, o.data);
    for (const r of q.requests) set(`queues/${q.id}/operatorRequests/${r.uid}`, r.data);
    for (const h of q.history) set(`queues/${q.id}/history/${h.id}`, h.data);
    for (const f of q.feedback) set(`queues/${q.id}/feedback/${f.id}`, f.data);
    log(`firestore: ${q.id} (${q.history.length} history, ${q.feedback.length} feedback)`);
  }
  await writer.close();
  if (failed > 0) throw new Error(`${failed} escritas do Firestore falharam`);
  log(`firestore: ${count} docs gravados`);
}

async function writeRtdb({ db }, universe, log) {
  for (const q of universe.queues) {
    const updates = {
      [`queues/${q.id}/meta`]: q.meta,
      [`queues/${q.id}/entries`]: Object.keys(q.entries).length > 0 ? q.entries : null,
      [`queues/${q.id}/public`]: Object.keys(q.public).length > 0 ? q.public : null,
      [`queues/${q.id}/operatorUids`]: Object.keys(q.operatorUids).length > 0 ? q.operatorUids : null,
      [`owners/${q.id}`]: { ownerUid: q.ownerUid },
      [`tickets/${q.id}`]: q.lastTicket > 0 ? q.lastTicket : null,
    };
    await db.ref().update(updates);
  }
  log(`rtdb: ${universe.queues.length} filas gravadas`);
}

async function seedUniverse(universe, { conn, reset = false, log = () => {} } = {}) {
  const connection = conn ?? connect();
  const scope = scopeOf(universe);
  await wipe(connection, scope, { reset, log });
  await createUsers(connection, universe, log);
  await writeFirestore(connection, universe, log);
  await writeRtdb(connection, universe, log);
}

module.exports = { connect, seedUniverse, wipe };
