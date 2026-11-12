'use strict';

// Prueba integral contra puertos locales fijos; nunca usa el proyecto real.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { createRequire } = require('node:module');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, getDoc, collection, writeBatch, serverTimestamp, terminate } = require('firebase/firestore');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');
const notificationRequire = createRequire(require.resolve('../websocket_server/package.json'));
const WebSocket = notificationRequire('ws');
const projectId = 'demo-declaraucr-local';
const sessions = [];
const results = [];
const timeout = setTimeout(() => { console.error('La prueba local supero 120 segundos.'); process.exit(1); }, 120000);

function samplePdf() {
  const content = 'BT /F1 16 Tf 50 780 Td (Comprobacion local - DeclaraUCR) Tj ET';
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
    `<< /Length ${Buffer.byteLength(content)} >>\nstream\n${content}\nendstream`,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  let pdf = '%PDF-1.4\n';
  const offsets = [0];
  for (let index = 0; index < objects.length; index++) {
    offsets.push(Buffer.byteLength(pdf));
    pdf += `${index + 1} 0 obj\n${objects[index]}\nendobj\n`;
  }
  const xref = Buffer.byteLength(pdf);
  pdf += `xref\n0 ${offsets.length}\n0000000000 65535 f \n`;
  pdf += offsets.slice(1).map(offset => `${String(offset).padStart(10, '0')} 00000 n \n`).join('');
  pdf += `trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(pdf);
}

async function check(name, fn) {
  await fn();
  results.push({ name, pass: true });
  console.log(`OK: ${name}`);
}

async function session(role) {
  const app = initializeApp({ apiKey: 'local-emulator-api-key', projectId, appId: `local-${role}` }, `check-${role}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, '127.0.0.1', 8180);
  const functions = getFunctions(app, 'us-east1');
  connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  const credential = await signInWithEmailAndPassword(auth, `${role}@local.test`, 'PruebaUCR2026!');
  const value = { app, auth, db, user: credential.user, call: async (name, data) => (await httpsCallable(functions, name)(data)).data };
  sessions.push(value);
  return value;
}

async function move(session, id, event, from, to, signature) {
  const batch = writeBatch(session.db);
  const ref = doc(session.db, 'declarations', id);
  assert.equal((await getDoc(ref)).data().status, from);
  batch.update(ref, { status: to, updatedAt: serverTimestamp() });
  batch.set(doc(collection(ref, 'events')), {
    event, userId: session.user.uid, version: 1,
    dateTime: serverTimestamp(), previousStatus: from, newStatus: to, observation: '',
  });
  if (signature) {
    batch.set(doc(ref, 'versions', '1', 'signatures', signature), {
      userId: session.user.uid, name: session.user.displayName,
      version: 1, dateTime: serverTimestamp(), signatureId: signature,
      hash: createHash('sha256').update(id + event).digest('hex'),
      type: signature === 'owner' ? 'DECLARANTE' : 'SUPERIOR',
    });
  }
  await batch.commit();
}

async function main() {
  const clients = {};
  for (const role of ['declarante', 'superior', 'rrhh', 'admin']) {
    await check(`Inicio de sesion y perfil de ${role}`, async () => {
      clients[role] = await session(role);
      assert.equal((await getDoc(doc(clients[role].db, 'users', clients[role].user.uid))).data().role, role);
    });
  }
  const owner = clients.declarante;
  await check('Listado de superiores mediante funcion local', async () => {
    const response = await owner.call('listSuperiors', {});
    assert.match(JSON.stringify(response), /Carlos Superior Prueba/);
  });
  await check('Notificaciones WebSocket autenticadas', async () => {
    const token = await owner.user.getIdToken();
    await new Promise((resolve, reject) => {
      const ws = new WebSocket('ws://127.0.0.1:8080');
      const timer = setTimeout(() => { ws.terminate(); reject(new Error('WebSocket no respondio')); }, 10000);
      ws.on('open', () => ws.send(JSON.stringify({ type: 'auth', token })));
      ws.on('error', reject);
      ws.on('message', raw => {
        if (JSON.parse(raw.toString()).type === 'authenticated') {
          clearTimeout(timer); ws.close(); resolve();
        }
      });
    });
  });
  let id;
  await check('Guardar declaracion con funcion y reglas reales del proyecto', async () => {
    const result = await owner.call('saveDeclarationValidated', {
      id: '', version: 1, periodId: '2026-II', superiorId: 'local-superior',
      ownerName: 'Ana Declarante Prueba', identification: '111111111',
      phone: '88887777', email: 'declarante@local.test', unit: 'Escuela de Informática',
      observations: '', externalJobs: [],
      appointments: [{
        workplace: 'Universidad de Costa Rica', position: 'Proyectos',
        startDate: '2026-08-01', endDate: '2026-12-31', expectedHours: 5, workloadFraction: '1/8',
        blocks: [{ day: 3, start: '07:00', end: '12:00', activityName: 'Comprobación local' }],
      }],
    });
    id = result.id;
    assert.equal((await getDoc(doc(owner.db, 'declarations', id))).data().status, 'BORRADOR');
  });
  await check('Validacion de horas en el servidor local', async () => {
    await owner.call('validateDeclarationSchedule', { id, version: 1 });
    assert.equal((await getDoc(doc(owner.db, 'declarations', id))).data().status, 'VALIDADA');
  });
  await check('Envio y firma del declarante', async () => {
    await move(owner, id, 'submit', 'VALIDADA', 'PENDIENTE_FIRMA_DECLARANTE');
    await move(owner, id, 'signOwner', 'PENDIENTE_FIRMA_DECLARANTE', 'FIRMADA_POR_DECLARANTE', 'owner');
    await move(owner, id, 'route', 'FIRMADA_POR_DECLARANTE', 'PENDIENTE_FIRMA_SUPERIOR');
  });
  await check('Firma del superior y envio a RRHH', async () => {
    await move(clients.superior, id, 'signSuperior', 'PENDIENTE_FIRMA_SUPERIOR', 'FIRMADA_POR_SUPERIOR', 'superior');
    await move(clients.superior, id, 'sendHr', 'FIRMADA_POR_SUPERIOR', 'ENVIADA_A_RRHH');
  });
  await check('Recepcion y finalizacion por RRHH', async () => {
    await move(clients.rrhh, id, 'receive', 'ENVIADA_A_RRHH', 'RECIBIDA_RRHH');
    await move(clients.rrhh, id, 'finish', 'RECIBIDA_RRHH', 'FINALIZADA');
  });
  await check('Archivo y descarga del PDF con huella verificada', async () => {
    // Documento mínimo de prueba del transporte; la interfaz genera el formulario completo.
    const pdf = samplePdf();
    const saved = await clients.rrhh.call('archiveDeclarationPdf', { declarationId: id, version: 1, pdfBase64: pdf.toString('base64') });
    const downloaded = await owner.call('downloadDeclarationPdf', { declarationId: id, version: 1 });
    assert.equal(saved.sha256, createHash('sha256').update(pdf).digest('hex'));
    assert.equal(downloaded.pdfBase64, pdf.toString('base64'));
  });
  console.log(`Declaracion de comprobacion finalizada: ${id}`);
}

main().catch(error => {
  results.push({ name: 'Error de comprobacion', pass: false, error: error.message });
  console.error(error);
  process.exitCode = 1;
}).finally(async () => {
  fs.writeFileSync(path.join(__dirname, '../.local/local-checks.json'), JSON.stringify({
    projectId, date: new Date().toISOString(), passed: results.filter(r => r.pass).length,
    failed: results.filter(r => !r.pass).length, results,
  }, null, 2));
  for (const s of sessions) { await terminate(s.db); await deleteApp(s.app); }
  clearTimeout(timeout);
});
