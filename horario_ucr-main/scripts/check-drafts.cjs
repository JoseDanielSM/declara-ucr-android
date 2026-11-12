'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, getDoc, getDocs, doc, collection, terminate } = require('firebase/firestore');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');
const results = [], sessions = [];
async function session(role) {
  const app = initializeApp({ apiKey: 'local-emulator-api-key', projectId: 'demo-declaraucr-local', appId: `draft-${role}` }, `draft-${role}`);
  const auth = getAuth(app); connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8180);
  const functions = getFunctions(app, 'us-east1'); connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  await signInWithEmailAndPassword(auth, `${role}@local.test`, 'PruebaUCR2026!');
  const s = {app, db, call: async (name, data) => (await httpsCallable(functions, name)(data)).data}; sessions.push(s); return s;
}
async function check(name, fn) { await fn(); results.push({name, pass: true}); console.log('OK: '+name); }
async function main() {
  const owner = await session('declarante'), superior = await session('superior');
  const id = doc(collection(owner.db, 'declarations')).id;
  const call = data => owner.call('saveDeclarationDraft', {id, version: 1, ...data});
  await check('Guardar borrador sin datos obligatorios', async () => { assert.equal((await call({})).id, id); assert.equal((await getDoc(doc(owner.db, 'declarations', id))).data().status, 'BORRADOR'); });
  await check('Reintentar no duplica documento ni historial', async () => { assert.equal((await call({})).saved, false); assert.equal((await getDocs(collection(owner.db, 'declarations', id, 'events'))).size, 1); });
  await check('Borrador incompleto no puede validarse', () => assert.rejects(owner.call('validateDeclarationSchedule', {id, version:1}), e => e.code.startsWith('functions/')));
  await check('Rechazar propietario o estado enviados por cliente', () => assert.rejects(call({ownerId: 'otro', status:'FINALIZADA'}), e => e.code === 'functions/invalid-argument'));
  await check('Otro rol no puede editar el borrador', () => assert.rejects(superior.call('saveDeclarationDraft', {id, version:1}), e => e.code === 'functions/permission-denied'));
  await check('Rechazar versión desactualizada', () => assert.rejects(call({version:2}), e => e.code === 'functions/failed-precondition'));
  await check('Rechazar jornada NaN y observaciones excesivas', async () => {
    await assert.rejects(call({appointments:[{expectedHours:-1}]}), e => e.code === 'functions/invalid-argument');
    for (const value of [NaN, Infinity]) {
      assert.throws(() => require('../functions/draft-validation').normalizeDraft({appointments:[{expectedHours:value}]}), /Jornada inválida/);
      await assert.rejects(call({appointments:[{expectedHours:value}]}), /cannot be encoded in JSON/);
    }
    for (const value of [null, '5']) {
      await assert.rejects(call({appointments:[{expectedHours:value}]}), e => e.code === 'functions/invalid-argument');
    }
    await assert.rejects(call({additionalObservations:'x'.repeat(2001)}), e => e.code === 'functions/invalid-argument');
  });
  const job = {workplace:'Universidad de Costa Rica', position:'Proyectos', workloadFraction:'1/8', expectedHours:5, startDate:'2026-08-01', endDate:'2026-12-31', blocks:[
    {day:1,start:'08:00',end:'12:00',activityName:'Proyecto de laboratorio'},
    {day:1,start:'11:00',end:'14:00',activityName:'Proyecto de laboratorio'},
  ]};
  const payload = {ownerName:'Ana Declarante Prueba',identification:'111111111',phone:'88887777',email:'declarante@local.test',unit:'Escuela de Informática',periodId:'2026-II',superiorId:'local-superior',appointments:[job],externalJobs:[],additionalObservations:'Observación escrita por la persona declarante.'};
  await check('Completar período y superior del borrador', async () => { await call(payload); const d=(await getDoc(doc(owner.db,'declarations',id))).data(); assert.equal(d.superiorId,'local-superior'); assert.equal(d.additionalObservations,payload.additionalObservations); });
  await check('Guardar conflictos sin considerarlos validados', async () => { await assert.rejects(owner.call('validateDeclarationSchedule',{id,version:1}), e => e.code === 'functions/invalid-argument'); assert.equal((await getDoc(doc(owner.db,'declarations',id))).data().status,'BORRADOR'); });
  job.blocks[1]={...job.blocks[1],start:'13:00',end:'14:00'};
  payload.externalJobs=[{workplace:'Institución de prueba',position:'Analista de soporte',expectedHours:2,startDate:'2026-08-01',endDate:'No aplica',blocks:[{day:2,start:'08:00',end:'10:00'}]}];
  await check('Aceptar puesto libre en institución externa', () => call(payload));
  await check('Escritura antigua conserva observaciones adicionales', async () => { const legacy={...payload}; delete legacy.additionalObservations; await owner.call('saveDeclarationValidated',{...legacy,id,version:1}); assert.equal((await getDoc(doc(owner.db,'declarations',id))).data().additionalObservations,payload.additionalObservations); });
  await check('Corregir conflicto permite validar las cinco horas UCR', async () => { const r=await owner.call('validateDeclarationSchedule',{id,version:1}); assert.equal(r.status,'VALIDADA'); assert.equal(r.institutionalHours,5); });
  await check('Estado validado impide reescribir contenido', () => assert.rejects(call(payload), e => e.code === 'functions/failed-precondition'));
  console.log('Borrador comprobado: '+id);
}
main().catch(e => { results.push({name:'Error',pass:false,error:e.message}); console.error(e); process.exitCode=1; }).finally(async () => {
  fs.writeFileSync('.local/draft-checks.json',JSON.stringify({passed:results.filter(r=>r.pass).length,failed:results.filter(r=>!r.pass).length,results},null,2));
  for(const s of sessions){await terminate(s.db);await deleteApp(s.app);}
});
