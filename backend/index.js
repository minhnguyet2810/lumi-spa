const { onRequest } = require('firebase-functions/v2/https');
const app = require('./server');

exports.backend = onRequest(
  { region: 'asia-southeast1', maxInstances: 3 },
  app
);

// Deploy explicitly when running the backend in Cloud Functions instead of local Node.
const { onSchedule } = require('firebase-functions/v2/scheduler');
exports.bookingReminders = onSchedule(
  { schedule: 'every 1 minutes', region: 'asia-southeast1', timeZone: 'Asia/Ho_Chi_Minh', maxInstances: 1 },
  async () => require('./services/experience_service').runReminders(
    require('./firebase'), require('./services/push_service').sendPushToUser,
  ),
);
