'use strict';

// Impide que esta preparación escriba por accidente en el Firebase real.
if (process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8180' ||
    process.env.GCLOUD_PROJECT !== 'demo-declaraucr-local') {
  throw new Error('Este script solo funciona con los emuladores locales.');
}

const { createRequire } = require('node:module');
const backendRequire = createRequire(require.resolve('../functions/package.json'));
const { initializeApp } = backendRequire('firebase-admin/app');
const { getAuth } = backendRequire('firebase-admin/auth');
const { getFirestore, FieldValue } = backendRequire('firebase-admin/firestore');
const { HttpsError } = backendRequire('firebase-functions/v2/https');
const { createDeclarationHandlers } = require('../functions/declaration-handlers');

const app = initializeApp({ projectId: 'demo-declaraucr-local' });
const auth = getAuth(app);
const db = getFirestore(app);
const password = 'PruebaUCR2026!';

async function main() {
  const accounts = [
    ['declarante', 'Ana Declarante Prueba', '111111111'],
    ['superior', 'Carlos Superior Prueba', '222222222'],
    ['rrhh', 'Rosa Recursos Humanos', '333333333'],
    ['admin', 'Andrea Administradora Prueba', '444444444'],
  ];
  for (const [role, name, identification] of accounts) {
    const uid = `local-${role}`;
    const email = `${role}@local.test`;
    try {
      await auth.getUser(uid);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      await auth.createUser({ uid, email, password, displayName: name, emailVerified: true });
    }
    const profile = db.doc(`users/${uid}`);
    if (!(await profile.get()).exists) {
      await profile.set({
        name, email, role, identification, phone: '88887777',
        unit: 'Escuela de Informática',
      });
    }
  }
  const period = db.doc('periods/2026-II');
  if (!(await period.get()).exists) {
    await period.set({ name: 'II Ciclo 2026', enabled: true });
  }

  const marker = db.doc('localSetup/initialData');
  if (!(await marker.get()).exists) {
    const handlers = createDeclarationHandlers({ db, FieldValue, HttpsError });
    const result = await handlers.save({
      auth: { uid: 'local-declarante' },
      data: {
        id: '', version: 1, periodId: '2026-II', superiorId: 'local-superior',
        ownerName: 'Ana Declarante Prueba', identification: '111111111',
        phone: '88887777', email: 'declarante@local.test',
        unit: 'Escuela de Informática', observations: '', externalJobs: [],
        appointments: [{
          workplace: 'Universidad de Costa Rica', position: 'Proyectos',
          startDate: '2026-08-01', endDate: '2026-12-31',
          expectedHours: 5, workloadFraction: '1/8',
          blocks: [
            { day: 1, start: '08:00', end: '11:00', activityName: 'Proyecto de ejemplo' },
            { day: 2, start: '08:00', end: '10:00', activityName: 'Proyecto de ejemplo' },
          ],
        }],
      },
    });
    await marker.set({ declarationId: result.id, createdAt: FieldValue.serverTimestamp() });
  }
  console.log('Cuentas locales listas: declarante, superior, rrhh y admin @local.test');
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
