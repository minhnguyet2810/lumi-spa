# LUMI SPA - Backend Handoff

## Repository
https://github.com/minhnguyet2810/lumi-spa

Firebase project: lumi-spa
Backend directory: backend/
Local API port: 3000

## Setup
Requirements: Node.js 22, Google Cloud CLI, Firebase project access.

1. Clone the repository and open its root directory.
2. Run `cd backend && npm ci`.
3. Run `gcloud auth application-default login` with your own Google account.
4. Run `node server.js` from the backend directory.
5. Check `http://localhost:3000/api/health`.

Firebase Console Viewer access alone may not grant Firestore read/write permissions. Contact the backend owner if permission is denied.

## API Base URL
- Browser on backend computer: http://localhost:3000
- Android Emulator on backend computer: http://10.0.2.2:3000
- Physical Android device: http://<computer-LAN-IP>:3000

## Available APIs
Public:
- GET /api/services
- GET /api/services/:id
- GET /api/products
- GET /api/products/:id
- GET /api/categories
- GET /api/banners

Firebase ID Token required:
- GET /api/me
- PATCH /api/me
- GET /api/bookings
- POST /api/bookings
- PATCH /api/bookings/:id/cancel
- GET /api/orders
- POST /api/orders
- GET /api/orders/:id
- PATCH /api/orders/:id/cancel
- GET /api/membership
- GET /api/notifications
- PATCH /api/notifications/:id/read
- PATCH /api/notifications/read-all

Use Authorization: Bearer <Firebase ID Token>.
Check backend/routes/ for exact request bodies.

## Team Branches
- Thanh Thao: feature/booking-ui
- Thanh Nhi: feature/profile-ui
- Nha Doan: feature/shopping-ui

## Important Notes
- Cloud Functions have not been deployed.
- Each developer runs the backend locally.
- The backend connects to real Cloud Firestore by default.
- Do not create test bookings or orders in shared Cloud Firestore without coordination.
- Do not share credentials or commit secrets.
- Submit changes through Pull Requests, not directly to main.
