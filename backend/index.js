const { onRequest } = require('firebase-functions/v2/https');
const app = require('./server');

exports.backend = onRequest(
  { region: 'asia-southeast1', maxInstances: 3 },
  app
);
