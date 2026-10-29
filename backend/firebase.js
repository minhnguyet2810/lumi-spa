const fs = require('fs');
const path = require('path');
const { initializeApp, getApps, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const gcloudCredPath = process.env.APPDATA ? path.join(process.env.APPDATA, 'gcloud', 'application_default_credentials.json') : '';
const hasServiceAccount = Boolean(process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS));
const hasGcloudCred = Boolean(gcloudCredPath && fs.existsSync(gcloudCredPath));
const hasCredentials = hasServiceAccount || hasGcloudCred;

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
    projectId: 'lumi-spa',
  });
}

const db = getFirestore();
db.hasCredentials = hasCredentials;

module.exports = db;
