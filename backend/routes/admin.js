const express = require('express');
const db = require('../firebase');
const { FieldValue } = require('firebase-admin/firestore');
const { requireAuth, requireAdmin } = require('../admin_auth');

const router = express.Router();

router.use(requireAuth);
router.use(requireAdmin);

function serialize(value) {
  if (value == null) return value;
  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (Array.isArray(value)) return value.map(serialize);
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, val]) => [key, serialize(val)])
    );
  }
  return value;
}

async function listCollection(name) {
  const snapshot = await db.collection(name).limit(100).get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...serialize(doc.data()),
  }));
}

// GET /api/admin/health
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'LUMI Admin API is available',
  });
});

// GET /api/admin/bookings
router.get('/bookings', async (req, res) => {
  try {
    const data = await listCollection('bookings');
    return res.json({ success: true, count: data.length, data });
  } catch (error) {
    console.error('Admin bookings error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách lịch hẹn.',
    });
  }
});

// PATCH /api/admin/bookings/:id/confirm
router.patch('/bookings/:id/confirm', async (req, res) => {
  try {
    const bookingRef = db.collection('bookings').doc(req.params.id);

    await db.runTransaction(async tx => {
      const snapshot = await tx.get(bookingRef);

      if (!snapshot.exists) {
        const error = new Error('Không tìm thấy lịch hẹn.');
        error.code = 'NOT_FOUND';
        throw error;
      }

      const booking = snapshot.data();

      if (booking.status !== 'pending') {
        const error = new Error('Chỉ có thể xác nhận lịch đang chờ.');
        error.code = 'INVALID_STATUS';
        throw error;
      }

      if (!booking.startAt ||
          booking.startAt.toMillis() <= Date.now()) {
        const error = new Error('Không thể xác nhận lịch đã bắt đầu.');
        error.code = 'INVALID_STATUS';
        throw error;
      }

      if (!booking.staffId || !booking.roomId ||
          !Array.isArray(booking.resourceSlotIds) ||
          booking.resourceSlotIds.length === 0) {
        const error = new Error('Lịch hẹn thiếu thông tin tài nguyên.');
        error.code = 'INVALID_RESOURCES';
        throw error;
      }

      const slotRefs = booking.resourceSlotIds.map(id =>
        db.collection('resource_slots').doc(id)
      );
      const slots = await tx.getAll(...slotRefs);

      if (slots.some(slot =>
        !slot.exists || slot.data().bookingId !== bookingRef.id
      )) {
        const error = new Error('Tài nguyên của lịch hẹn không còn hợp lệ.');
        error.code = 'INVALID_RESOURCES';
        throw error;
      }

      tx.update(bookingRef, {
        status: 'confirmed',
        confirmedAt: FieldValue.serverTimestamp(),
        confirmedBy: req.user.uid,
      });
    });

    return res.json({
      success: true,
      message: 'Đã xác nhận lịch hẹn.',
    });
  } catch (error) {
    if (error.code === 'NOT_FOUND') {
      return res.status(404).json({
        success: false, message: error.message,
      });
    }

    if (['INVALID_STATUS', 'INVALID_RESOURCES'].includes(error.code)) {
      return res.status(409).json({
        success: false, message: error.message,
      });
    }

    console.error('Admin confirm booking error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể xác nhận lịch hẹn.',
    });
  }
});

// PATCH /api/admin/bookings/:id/reject
router.patch('/bookings/:id/reject', async (req, res) => {
  try {
    const bookingRef = db.collection('bookings').doc(req.params.id);

    await db.runTransaction(async tx => {
      const snapshot = await tx.get(bookingRef);

      if (!snapshot.exists) {
        const error = new Error('Không tìm thấy lịch hẹn.');
        error.code = 'NOT_FOUND';
        throw error;
      }

      const booking = snapshot.data();

      if (booking.status !== 'pending') {
        const error = new Error('Chỉ có thể từ chối lịch đang chờ.');
        error.code = 'INVALID_STATUS';
        throw error;
      }

      if (!Array.isArray(booking.resourceSlotIds) ||
          booking.resourceSlotIds.length === 0) {
        const error = new Error('Booking thiếu thông tin khóa tài nguyên.');
        error.code = 'INVALID_RESOURCES';
        throw error;
      }

      const slotRefs = booking.resourceSlotIds.map(id =>
        db.collection('resource_slots').doc(id)
      );

      // Đọc toàn bộ khóa trước khi thực hiện ghi.
      const slots = await tx.getAll(...slotRefs);

      if (slots.some(slot =>
        !slot.exists || slot.data().bookingId !== bookingRef.id
      )) {
        const error = new Error('Khóa tài nguyên không hợp lệ.');
        error.code = 'INVALID_RESOURCES';
        throw error;
      }

      for (const ref of slotRefs) {
        tx.delete(ref);
      }

      tx.update(bookingRef, {
        status: 'cancelled',
        rejectedAt: FieldValue.serverTimestamp(),
        rejectedBy: req.user.uid,
      });
    });

    return res.json({
      success: true,
      message: 'Đã từ chối lịch hẹn và giải phóng tài nguyên.',
    });
  } catch (error) {
    if (error.code === 'NOT_FOUND') {
      return res.status(404).json({
        success: false,
        message: error.message,
      });
    }

    if (['INVALID_STATUS', 'INVALID_RESOURCES'].includes(error.code)) {
      return res.status(409).json({
        success: false,
        message: error.message,
      });
    }

    console.error('Admin reject booking error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể từ chối lịch hẹn.',
    });
  }
});

// GET /api/admin/orders
router.get('/orders', async (req, res) => {
  try {
    const data = await listCollection('orders');
    return res.json({ success: true, count: data.length, data });
  } catch (error) {
    console.error('Admin orders error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách đơn hàng.',
    });
  }
});

// GET /api/admin/users
router.get('/users', async (req, res) => {
  try {
    const data = await listCollection('users');
    return res.json({ success: true, count: data.length, data });
  } catch (error) {
    console.error('Admin users error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách khách hàng.',
    });
  }
});

module.exports = router;
