const fs = require('fs');
const path = require('path');
const { initializeApp, getApps, applicationDefault, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
const hasLocalKey = fs.existsSync(serviceAccountPath);
const gcloudCredPath = process.env.APPDATA ? path.join(process.env.APPDATA, 'gcloud', 'application_default_credentials.json') : '';
const hasServiceAccount = Boolean(process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS));
const hasGcloudCred = Boolean(gcloudCredPath && fs.existsSync(gcloudCredPath));
const hasCredentials = hasLocalKey || hasServiceAccount || hasGcloudCred;

if (getApps().length === 0) {
  if (hasLocalKey) {
    try {
      const serviceAccount = require(serviceAccountPath);
      initializeApp({
        credential: cert(serviceAccount),
        projectId: 'lumi-spa',
      });
      console.log('Firebase Admin initialized with serviceAccountKey.json');
    } catch (e) {
      console.warn('Failed to load serviceAccountKey.json, falling back to applicationDefault:', e.message);
      initializeApp({
        credential: applicationDefault(),
        projectId: 'lumi-spa',
      });
    }
  } else {
    initializeApp({
      credential: applicationDefault(),
      projectId: 'lumi-spa',
    });
  }
}

const db = getFirestore();
db.hasCredentials = hasCredentials;

module.exports = db;
