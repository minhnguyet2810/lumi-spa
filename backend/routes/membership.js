const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const {
  calculateMembershipDetails,
  getTierByPoints,
  CONVERSION_RATE,
} = require('../services/membership_service');

const router = express.Router();
router.use(requireAuth);

// GET /api/membership
router.get('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const doc = await db.collection('memberships').doc(uid).get();

    if (!doc.exists) {
      const details = calculateMembershipDetails(0, 0);
      return res.json({
        success: true,
        data: {
          userId: uid,
          isDefault: true,
          ...details,
        },
      });
    }

    const data = doc.data();
    const points = data.points ?? 0;
    const totalSpent = data.totalSpent ?? 0;
    const details = calculateMembershipDetails(points, totalSpent);

    return res.json({
      success: true,
      data: {
        userId: uid,
        isDefault: false,
        updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
        ...details,
      },
    });
  } catch (error) {
    console.error('Membership error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải thông tin thành viên.',
    });
  }
});

// POST /api/membership/sync (Đồng bộ lại điểm từ các đơn hàng đã hoàn tất nếu chưa được tích điểm)
router.post('/sync', async (req, res) => {
  try {
    const uid = req.user.uid;
    if (!db.hasCredentials) {
      const details = calculateMembershipDetails(0, 0);
      return res.json({ success: true, data: { userId: uid, isDefault: true, ...details } });
    }

    const ordersSnap = await db.collection('orders')
      .where('userId', '==', uid)
      .where('status', '==', 'completed')
      .get();

    let uncountedSpent = 0;
    const uncountedOrderDocs = [];
    ordersSnap.docs.forEach(d => {
      const o = d.data();
      if (o.pointsAwarded !== true) {
        uncountedSpent += (Number(o.total) || 0);
        uncountedOrderDocs.push(d);
      }
    });

    if (uncountedSpent > 0) {
      await db.runTransaction(async tx => {
        const memberRef = db.collection('memberships').doc(uid);
        const memberDoc = await tx.get(memberRef);
        const prevPoints = memberDoc.exists ? (Number(memberDoc.data().points) || 0) : 0;
        const prevSpent = memberDoc.exists ? (Number(memberDoc.data().totalSpent) || 0) : 0;

        const newSpent = prevSpent + uncountedSpent;
        const newPoints = prevPoints + Math.floor(uncountedSpent / CONVERSION_RATE);
        const newTierObj = getTierByPoints(newPoints);

        const dataToSave = {
          userId: uid,
          points: newPoints,
          totalSpent: newSpent,
          tier: newTierObj.name,
          tierLabel: newTierObj.label,
          discountPercent: newTierObj.discountPercent,
          updatedAt: FieldValue.serverTimestamp(),
        };

        if (memberDoc.exists) {
          tx.update(memberRef, dataToSave);
        } else {
          tx.create(memberRef, { ...dataToSave, createdAt: FieldValue.serverTimestamp() });
        }

        for (const oDoc of uncountedOrderDocs) {
          tx.update(oDoc.ref, {
            pointsAwarded: true,
            earnedPoints: Math.floor((Number(oDoc.data().total) || 0) / CONVERSION_RATE),
          });
        }
      });
    }

    const updatedDoc = await db.collection('memberships').doc(uid).get();
    const data = updatedDoc.exists ? updatedDoc.data() : {};
    const details = calculateMembershipDetails(data.points ?? 0, data.totalSpent ?? 0);

    return res.json({
      success: true,
      message: 'Đồng bộ điểm thành công.',
      data: {
        userId: uid,
        isDefault: !updatedDoc.exists,
        updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
        ...details,
      },
    });
  } catch (error) {
    console.error('Sync membership error:', error);
    return res.status(500).json({ success: false, message: 'Không thể đồng bộ điểm thành viên.' });
  }
});

module.exports = router;
