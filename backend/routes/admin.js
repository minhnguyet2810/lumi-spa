const express = require('express');
const db = require('../firebase');
const { FieldValue } = require('firebase-admin/firestore');
const { requireAuth, requireAdmin } = require('../admin_auth');
const { devBookings } = require('../dev_store');
const mailService = require('../services/mail_service');
const pushService = require('../services/push_service');

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
  if (!db.hasCredentials) {
    if (name === 'bookings') return devBookings;
    return [];
  }
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
    if (!db.hasCredentials) {
      const b = devBookings.find(item => item.id === req.params.id);
      if (!b) return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn.' });
      b.status = 'confirmed';
      b.confirmedAt = new Date().toISOString();
      b.confirmedBy = req.user.uid;
      return res.json({ success: true, message: 'Đã xác nhận lịch hẹn.' });
    }
    const bookingRef = db.collection('bookings').doc(req.params.id);

    let confirmedBooking = null;
    await db.runTransaction(async tx => {
      const snapshot = await tx.get(bookingRef);

      if (!snapshot.exists) {
        const error = new Error('Không tìm thấy lịch hẹn.');
        error.code = 'NOT_FOUND';
        throw error;
      }

      const booking = snapshot.data();
      confirmedBooking = { id: snapshot.id, ...booking };

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

    if (confirmedBooking) {
      (async () => {
        try {
          let recipientEmail = confirmedBooking.userEmail;
          if (!recipientEmail && confirmedBooking.userId) {
            try {
              const uDoc = await db.collection('users').doc(confirmedBooking.userId).get();
              if (uDoc.exists) recipientEmail = uDoc.data().email;
            } catch (_) {}
          }

          let staffName = '';
          if (confirmedBooking.staffId) {
            try {
              const sDoc = await db.collection('staff').doc(confirmedBooking.staffId).get();
              if (sDoc.exists) staffName = sDoc.data().name;
            } catch (_) {}
          }

          let roomName = '';
          if (confirmedBooking.roomId) {
            try {
              const rDoc = await db.collection('rooms').doc(confirmedBooking.roomId).get();
              if (rDoc.exists) roomName = rDoc.data().name;
            } catch (_) {}
          }

          const startAtDate = confirmedBooking.startAt?.toDate ? confirmedBooking.startAt.toDate() : confirmedBooking.startAt;

          await mailService.sendBookingConfirmedEmail({
            to: recipientEmail,
            customerName: confirmedBooking.contactName,
            customerPhone: confirmedBooking.contactPhone,
            bookingId: confirmedBooking.id,
            serviceName: confirmedBooking.serviceName,
            startAt: startAtDate,
            durationMinutes: confirmedBooking.durationMinutes,
            price: confirmedBooking.price,
            staffName,
            roomName,
          });

          if (confirmedBooking.userId) {
            await db.collection('notifications').add({
              userId: confirmedBooking.userId,
              title: 'Lịch hẹn đã được xác nhận ✨',
              message: 'Lịch hẹn "' + (confirmedBooking.serviceName || '') + '" đã được Lễ tân xác nhận. Hân hạnh đón tiếp quý khách!',
              type: 'appointment',
              isRead: false,
              createdAt: FieldValue.serverTimestamp(),
            });

            const startDateObj = startAtDate ? new Date(startAtDate) : new Date();
            const dateStr = startDateObj.toISOString().split('T')[0];
            const hourStr = startDateObj.getHours();

            await pushService.sendBookingConfirmedPush({
              userId: confirmedBooking.userId,
              bookingId: confirmedBooking.id,
              serviceName: confirmedBooking.serviceName || 'Dịch vụ Spa',
              date: dateStr,
              hour: hourStr,
              staffName,
              roomName,
            });
          }
        } catch (mailErr) {
          console.error('[Admin] Failed to send confirm notification/email:', mailErr.message);
        }
      })();
    }

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
    if (!db.hasCredentials) {
      const b = devBookings.find(item => item.id === req.params.id);
      if (!b) return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn.' });
      b.status = 'cancelled';
      b.rejectedAt = new Date().toISOString();
      b.rejectedReason = req.body?.reason || 'Hết chỗ';
      return res.json({ success: true, message: 'Đã từ chối lịch hẹn.' });
    }
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
