
const { initializeApp, getApps, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
    projectId: 'lumi-spa',
  });
}

const db = getFirestore();

module.exports = db;
