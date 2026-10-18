LUMI SPA FIREBASE SETUP

1. In Firebase Console > Project settings > Service accounts > Firebase Admin SDK > Generate new private key, download JSON.
2. Keep JSON OUTSIDE your repo, e.g. ~/lumi-secrets/lumi-service-account.json.
3. In backend/ run: npm install firebase-admin
4. Copy firebase.js and seed.js into backend/ alongside server.js.
5. In Terminal:
   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/lumi-secrets/lumi-service-account.json"
   cd ~/AndroidStudioProjects/lumi_spa/backend
   node seed.js
6. Verify documents in Firebase Console > Firestore Database.

Do not share the private key or commit it. This script adds demo data only; it does not change your existing server.js. Your GET /api/services route must be changed to read Firestore separately.
