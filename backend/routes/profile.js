const express = require('express');
const db = require('../firebase');
const { requireAuth } = require('../auth');

const router = express.Router();

router.use(requireAuth);

// GET /api/me
router.get('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const doc = await db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Chưa tìm thấy hồ sơ người dùng.',
      });
    }

    return res.json({
      success: true,
      data: {
        uid,
        ...doc.data(),
      },
    });
  } catch (error) {
    console.error('Profile GET error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải hồ sơ.',
    });
  }
});

// PATCH /api/me
router.patch('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const { displayName, phone } = req.body || {};
    const updates = {};

    if (displayName !== undefined) {
      if (
        typeof displayName !== 'string' ||
        !displayName.trim() ||
        displayName.trim().length > 100
      ) {
        return res.status(400).json({
          success: false,
          message: 'Tên không hợp lệ.',
        });
      }
      updates.displayName = displayName.trim();
    }

    if (phone !== undefined) {
      if (
        typeof phone !== 'string' ||
        !/^[0-9+().\s-]{8,20}$/.test(phone.trim())
      ) {
        return res.status(400).json({
          success: false,
          message: 'Số điện thoại không hợp lệ.',
        });
      }
      updates.phone = phone.trim();
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có thông tin cần cập nhật.',
      });
    }

    const ref = db.collection('users').doc(uid);
    const existing = await ref.get();

    if (!existing.exists) {
      return res.status(404).json({
        success: false,
        message: 'Chưa tìm thấy hồ sơ người dùng.',
      });
    }

    updates.updatedAt =
      require('firebase-admin/firestore').FieldValue.serverTimestamp();

    await ref.update(updates);

    return res.json({
      success: true,
      message: 'Cập nhật hồ sơ thành công.',
    });
  } catch (error) {
    console.error('Profile PATCH error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật hồ sơ.',
    });
  }
});

module.exports = router;
