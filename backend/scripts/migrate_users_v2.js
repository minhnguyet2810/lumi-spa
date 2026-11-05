/**
 * LUMI SPA - Data Migration Script (v1 -> v2 Enterprise)
 * Chạy: node backend/scripts/migrate_users_v2.js
 */
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('../serviceAccountKey.json');

if (!getApps().length) {
  initializeApp({ credential: cert(serviceAccount) });
}

const db = getFirestore();
const BATCH_SIZE = 400;

async function migrateUsers() {
  console.log('🚀 Bắt đầu quá trình di chuyển CSDL users sang Enterprise v2...');
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();

  console.log(`📊 Tìm thấy tổng cộng ${snapshot.size} tài liệu người dùng.`);
  let count = 0;
  let skipped = 0;
  let batch = db.batch();

  for (const doc of snapshot.docs) {
    const data = doc.data();

    // Tránh xử lý lặp lại nếu đã di chuyển
    if (data.schemaVersion === 2) {
      skipped++;
      continue;
    }

    const points = Number(data.points) || 0;
    const lifetimeSpent = Number(data.totalSpent) || 0;
    let tier = 'bronze';
    if (points >= 15000 || lifetimeSpent >= 25000000) tier = 'diamond';
    else if (points >= 5000 || lifetimeSpent >= 10000000) tier = 'gold';
    else if (points >= 1000 || lifetimeSpent >= 3000000) tier = 'silver';

    let role = data.role || 'customer';
    if (data.isAdmin === true || data.role === 'admin') {
      role = 'super_admin';
    }

    const updatePayload = {
      schemaVersion: 2,
      role,
      status: data.status || 'active',
      assignedBranchId: data.assignedBranchId || (role === 'super_admin' ? 'central_hub' : null),

      skinProfile: data.skinProfile || {
        skinType: 'normal',
        concerns: [],
        knownAllergies: [],
        contraindications: [],
        currentRoutine: '',
        lastConsultationAt: null,
        consultedBy: null,
      },

      loyalty: {
        points,
        lifetimeSpent,
        tier,
        tierUpdatedAt: data.tierUpdatedAt || FieldValue.serverTimestamp(),
        tierExpiration: null,
      },

      fcmTokens: Array.isArray(data.fcmTokens) ? data.fcmTokens : (data.fcmToken ? [data.fcmToken] : []),
      updatedAt: FieldValue.serverTimestamp(),
    };

    batch.set(doc.ref, updatePayload, { merge: true });
    count++;

    if (count % BATCH_SIZE === 0) {
      await batch.commit();
      console.log(`✅ Đã di chuyển thành công ${count} tài liệu...`);
      batch = db.batch();
    }
  }

  if (count > 0 && count % BATCH_SIZE !== 0) {
    await batch.commit();
  }

  console.log(`🎉 Hoàn tất! Đã nâng cấp ${count} tài liệu, bỏ qua ${skipped} tài liệu đã chuẩn v2.`);
}

migrateUsers()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Lỗi di chuyển dữ liệu:', err);
    process.exit(1);
  });
