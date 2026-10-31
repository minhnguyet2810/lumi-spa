const express = require('express');
const db = require('../firebase');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

// GET /api/membership
router.get('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const doc = await db.collection('memberships').doc(uid).get();

    if (!doc.exists) {
      return res.json({
        success: true,
        data: {
          userId: uid,
          tier: 'Member',
          points: 0,
          totalSpent: 0,
          isDefault: true,
        },
      });
    }

    const data = doc.data();

    return res.json({
      success: true,
      data: {
        userId: uid,
        tier: data.tier || 'Member',
        points: data.points ?? 0,
        totalSpent: data.totalSpent ?? 0,
        updatedAt: data.updatedAt?.toDate?.().toISOString() || null,
        isDefault: false,
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

module.exports = router;
