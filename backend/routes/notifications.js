const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');

const router = express.Router();
router.use(requireAuth);

function serialize(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    ...data,
    createdAt: data.createdAt?.toDate?.().toISOString() || null,
    readAt: data.readAt?.toDate?.().toISOString() || null,
  };
}

// GET /api/notifications
router.get('/', async (req, res) => {
  try {
    const snapshot = await db.collection('notifications')
      .where('userId', '==', req.user.uid)
      .limit(100)
      .get();

    const notifications = snapshot.docs
      .map(serialize)
      .sort((a, b) =>
        (b.createdAt || '').localeCompare(a.createdAt || '')
      );

    return res.json({
      success: true,
      count: notifications.length,
      unreadCount: notifications.filter(n => !n.isRead).length,
      data: notifications,
    });
  } catch (error) {
    console.error('Notifications GET error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải thông báo.',
    });
  }
});

// PATCH /api/notifications/read-all
router.patch('/read-all', async (req, res) => {
  try {
    let updated = 0;
    while (true) {
      const snapshot = await db.collection('notifications')
        .where('userId', '==', req.user.uid)
        .where('isRead', '==', false)
        .limit(400)
        .get();

      if (snapshot.empty) break;

      const batch = db.batch();
      snapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          isRead: true,
          readAt: FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      updated += snapshot.size;
    }

    return res.json({
      success: true,
      updated,
    });
  } catch (error) {
    console.error('Notifications read-all error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật thông báo.',
    });
  }
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', async (req, res) => {
  try {
    const ref = db.collection('notifications').doc(req.params.id);

    await db.runTransaction(async tx => {
      const doc = await tx.get(ref);

      if (!doc.exists || doc.data().userId !== req.user.uid) {
        const error = new Error('NOT_FOUND');
        throw error;
      }

      if (!doc.data().isRead) {
        tx.update(ref, {
          isRead: true,
          readAt: FieldValue.serverTimestamp(),
        });
      }
    });

    return res.json({
      success: true,
      message: 'Đã đánh dấu thông báo là đã đọc.',
    });
  } catch (error) {
    if (error.message === 'NOT_FOUND') {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông báo.',
      });
    }

    console.error('Notification read error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật thông báo.',
    });
  }
});

// DELETE /api/notifications (Xóa tất cả thông báo của người dùng hiện tại)
router.delete('/', async (req, res) => {
  try {
    let deleted = 0;
    while (true) {
      const snapshot = await db.collection('notifications')
        .where('userId', '==', req.user.uid)
        .limit(400)
        .get();

      if (snapshot.empty) break;

      if (typeof db.batch === 'function') {
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
      } else {
        await Promise.all(snapshot.docs.map(doc => {
          if (doc.ref && typeof doc.ref.delete === 'function') {
            return doc.ref.delete();
          }
          return db.collection('notifications').doc(doc.id).delete();
        }));
      }
      deleted += snapshot.size;
    }

    return res.json({
      success: true,
      message: 'Đã xóa tất cả thông báo.',
      deleted,
    });
  } catch (error) {
    console.error('Notifications delete-all error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể xóa tất cả thông báo.',
    });
  }
});

// DELETE /api/notifications/:id (Xóa 1 thông báo cụ thể)
router.delete('/:id', async (req, res) => {
  try {
    const ref = db.collection('notifications').doc(req.params.id);

    await db.runTransaction(async tx => {
      const doc = await tx.get(ref);

      if (!doc.exists || doc.data().userId !== req.user.uid) {
        throw new Error('NOT_FOUND');
      }

      tx.delete(ref);
    });

    return res.json({
      success: true,
      message: 'Đã xóa thông báo.',
    });
  } catch (error) {
    if (error.message === 'NOT_FOUND') {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông báo.',
      });
    }

    console.error('Notification delete error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể xóa thông báo.',
    });
  }
});

module.exports = router;
