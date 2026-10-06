process.env.FIRESTORE_EMULATOR_HOST='localhost:8080';
process.env.FIREBASE_DATABASE_EMULATOR_HOST='localhost:9000';
process.env.FIREBASE_AUTH_EMULATOR_HOST='localhost:9099';
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getDatabase } = require('firebase-admin/database');
initializeApp({ projectId: 'qio-app', databaseURL: 'http://localhost:9000?ns=qio-app-default-rtdb' });
(async () => {
  const auth = getAuth(); const fs = getFirestore(); const db = getDatabase();
  let u; try { u = await auth.getUserByEmail('dono@qio.test'); } catch { u = await auth.createUser({ email:'dono@qio.test', password:'teste-qio-2026', displayName:'Dono Teste' }); }
  const uid = u.uid;
  await fs.doc(`owners/${uid}`).set({ name:'Dono Teste', businessName:'Clínica Exemplo', createdAt: Timestamp.now() });
  const queues = [
    { id:'qdemo1', name:'Balcão de Atendimento', description:'Atendimento geral' },
    { id:'qdemo2', name:'Retirada de Exames', description:null },
  ];
  const now = Date.now();
  for (const q of queues) {
    await fs.doc(`queues/${q.id}`).set({ ownerId: uid, name:q.name, description:q.description, status:'open', avgServiceMin:8, createdAt: Timestamp.fromMillis(now-9*86400e3) });
    await db.ref(`owners/${q.id}`).set({ ownerUid: uid });
    await db.ref(`queues/${q.id}/meta`).set({ nextTicket:0, serving:0, status:'open', name:q.name, description:q.description, avgServiceMin:8, avgServiceMinAuto:7.5, updatedAt: now });
  }
  const names=['Ana','Bruno','Carla','Diego','Elisa','Fábio','Gabi','Hugo','Iara','João','Karen','Lucas','Marta','Nuno','Olga'];
  let n=0;
  const hoursPool=[8,9,9,9,10,10,11,12,14,14,15,15,15,16,17];
  for (const [qi,q] of queues.entries()) {
    const count = qi===0?30:14;
    for (let i=0;i<count;i++) {
      const day = Math.floor(Math.random()*8);
      const h = hoursPool[(i+qi*3)%hoursPool.length];
      const joined = new Date(now - day*86400e3); joined.setHours(h, (i*7)%60, 0, 0);
      const wait = (3+((i*5)%14))*60e3; const svc=(4+((i*3)%9))*60e3;
      const r = i%7===0?'no_show':(i%9===0?'left':'served');
      const called = joined.getTime()+wait;
      const id=`h${qi}_${i}`;
      const doc={ ticket:i+1, name:names[i%names.length]+' '+String.fromCharCode(65+i%26)+'.', phone:'', result:r, joinedAt:Timestamp.fromMillis(joined.getTime()), calledAt: r==='left'?null:Timestamp.fromMillis(called), calledBy:r==='left'?null:uid, operatorId:r==='left'?null:uid, finishedAt:Timestamp.fromMillis(called+(r==='served'?svc:0)) };
      await fs.doc(`queues/${q.id}/history/${id}`).set(doc);
      if (r==='served' && i%2===0) await fs.doc(`queues/${q.id}/feedback/${id}`).set({ rating: [5,4,5,3,4,5][i%6], comment: i%4===0?'Atendimento rápido':'', uid:'x', createdAt: now });
    }
  }
  // fila ativa com gente esperando em qdemo1
  const entries={}; const pub={};
  for (let i=0;i<4;i++){ const id=`e${i}`; const status=i===0?'called':'waiting'; entries[id]={ticket:31+i,name:['Paulo R.','Quésia M.','Rafael T.','Sônia L.'][i],phone:'',uid:`cli${i}`,status,joinedAt:now-(10-i)*60e3, ...(i===0?{calledAt:now-60e3,operatorId:uid}:{})}; pub[id]={ticket:31+i,status}; }
  await db.ref('queues/qdemo1/entries').set(entries); await db.ref('queues/qdemo1/public').set(pub);
  await db.ref('tickets/qdemo1').set(34); await db.ref('queues/qdemo1/meta/serving').set(31);
  console.log('seeded', uid);
  process.exit(0);
})().catch(e=>{console.error(e);process.exit(1)});
