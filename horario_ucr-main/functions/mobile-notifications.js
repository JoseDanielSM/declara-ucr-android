'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

// Solo modifica la bandeja del usuario autenticado; nunca recibe un UID del cliente.
exports.markMobileNotificationsRead = onCall({region:'us-east1',maxInstances:2,invoker:'public'}, async request => {
  if (!request.auth) throw new HttpsError('unauthenticated','Iniciá sesión.');
  const id = request.data?.id;
  const collection = getFirestore().collection('users').doc(request.auth.uid).collection('notifications');
  if (id !== undefined && (typeof id !== 'string' || !id || id.length > 1500 || id.includes('/'))) {
    throw new HttpsError('invalid-argument','Notificación inválida.');
  }
  if (id !== undefined) {
    const ref = collection.doc(id);
    await getFirestore().runTransaction(async tx => {
      const doc = await tx.get(ref);
      if (!doc.exists) throw new HttpsError('not-found','La notificación ya no existe.');
      tx.update(ref,{read:true,readAt:FieldValue.serverTimestamp()});
    });
    return {updated:1};
  }
  const docs = await collection.where('read','==',false).limit(100).get();
  const batch = getFirestore().batch();
  for (const doc of docs.docs) batch.update(doc.ref,{read:true,readAt:FieldValue.serverTimestamp()});
  await batch.commit();
  return {updated:docs.size};
});
