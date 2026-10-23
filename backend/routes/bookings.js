const express = require('express');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const { reserveBookingResources } = require('../booking_transactions');

const router = express.Router();
router.use(requireAuth);

const VALID_HOURS = new Set([9, 10, 11, 12, 13, 14, 15, 16, 17]);

function fail(res, status, message) {
  return res.status(status).json({ success: false, message });
}

function bookingData(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    ...data,
    startAt: data.startAt?.toDate?.().toISOString() || null,
    createdAt: data.createdAt?.toDate?.().toISOString() || null,
    cancelledAt: data.cancelledAt?.toDate?.().toISOString() || null,
  };
}

// GET /api/bookings
router.get('/', async (req, res) => {
  try {
    const snapshot = await db.collection('bookings')
      .where('userId', '==', req.user.uid)
      .get();

    const bookings = snapshot.docs.map(bookingData)
      .sort((a, b) => (b.startAt || '').localeCompare(a.startAt || ''));

    return res.json({ success: true, data: bookings });
  } catch (error) {
    console.error('Booking list error:', error);
    return fail(res, 500, 'Không thể tải lịch hẹn.');
  }
});

// POST /api/bookings
router.post('/', async (req, res) => {
  try {
    const { serviceId, date, hour, contactName, contactPhone } = req.body || {};

    if (
      typeof serviceId !== 'string' ||
      !/^[A-Za-z0-9_-]{1,100}$/.test(serviceId) ||
      typeof date !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}$/.test(date) ||
      !Number.isInteger(hour) ||
      !VALID_HOURS.has(hour) ||
      typeof contactName !== 'string' ||
      !contactName.trim() ||
      contactName.trim().length > 100 ||
      typeof contactPhone !== 'string' ||
      !/^[0-9+().\s-]{8,20}$/.test(contactPhone.trim())
    ) {
      return fail(res, 400, 'Dữ liệu đặt lịch không hợp lệ.');
    }

    const [year, month, day] = date.split('-').map(Number);
    const startAt = new Date(Date.UTC(year, month - 1, day, hour - 7));
    const localCheck = new Date(startAt.getTime() + 7 * 60 * 60 * 1000);

    if (
      localCheck.getUTCFullYear() !== year ||
      localCheck.getUTCMonth() + 1 !== month ||
      localCheck.getUTCDate() !== day ||
      localCheck.getUTCHours() !== hour
    ) {
      return fail(res, 400, 'Ngày đặt lịch không hợp lệ.');
    }

    const now = Date.now();
    if (
      startAt.getTime() <= now ||
      startAt.getTime() > now + 60 * 24 * 60 * 60 * 1000
    ) {
      return fail(res, 400, 'Chỉ được đặt lịch trong 60 ngày tới.');
    }

    const serviceDoc = await db.collection('services').doc(serviceId).get();

    if (!serviceDoc.exists || serviceDoc.data().isActive === false) {
      return fail(res, 404, 'Dịch vụ không tồn tại hoặc đã ngừng hoạt động.');
    }

    const service = serviceDoc.data();
    const price = Number(service.price);
    const durationMinutes = Number(service.durationMinutes);
    const categoryId = service.categoryId;

    if (
      !Number.isFinite(price) || price < 0 ||
      !Number.isInteger(durationMinutes) || durationMinutes <= 0 ||
      typeof categoryId !== 'string' || !categoryId
    ) {
      return fail(res, 422, 'Thông tin dịch vụ chưa hợp lệ.');
    }

    // Spa hoạt động 09:00–18:00, dịch vụ phải kết thúc trước 18:00.
    if (hour * 60 + durationMinutes > 18 * 60) {
      return fail(res, 400, 'Dịch vụ phải kết thúc trước 18:00.');
    }

    const bookingRef = db.collection('bookings').doc();

    const result = await reserveBookingResources(db, {
      bookingRef,
      bookingData: {
        userId: req.user.uid,
        contactName: contactName.trim(),
        contactPhone: contactPhone.trim(),
        serviceId,
        serviceName: service.name || serviceId,
        categoryId,
        price,
        durationMinutes,
      },
      startAt,
      durationMinutes,
      categoryId,
    });

    return res.status(201).json({
      success: true,
      data: result,
      message: 'Đã tiếp nhận yêu cầu đặt lịch, đang chờ spa xác nhận.',
    });
  } catch (error) {
    if (error.code === 'SLOT_TAKEN') {
      return fail(res, 409, error.message);
    }
    if (error.code === 'NO_RESOURCES') {
      return fail(res, 409, error.message);
    }
    console.error('Booking create error:', error);
    return fail(res, 500, 'Không thể tạo lịch hẹn.');
  }
});

// PATCH /api/bookings/:id/cancel
router.patch('/:id/cancel', async (req, res) => {
  try {
    const bookingRef = db.collection('bookings').doc(req.params.id);

    await db.runTransaction(async tx => {
      const booking = await tx.get(bookingRef);

      if (!booking.exists || booking.data().userId !== req.user.uid) {
        const error = new Error('Không tìm thấy lịch hẹn.');
        error.code = 'NOT_FOUND';
        throw error;
      }

      const data = booking.data();

      if (!['pending', 'confirmed'].includes(data.status)) {
        const error = new Error('Lịch hẹn không thể hủy.');
        error.code = 'INVALID_STATUS';
        throw error;
      }

      if (data.startAt.toMillis() <= Date.now()) {
        const error = new Error('Không thể hủy lịch đã bắt đầu.');
        error.code = 'INVALID_STATUS';
        throw error;
      }

      if (!Array.isArray(data.resourceSlotIds) ||
          data.resourceSlotIds.length === 0) {
        const error = new Error('Booking chưa có thông tin khóa tài nguyên.');
        error.code = 'INVALID_RESOURCES';
        throw error;
      }

      const slotRefs = data.resourceSlotIds.map(id =>
        db.collection('resource_slots').doc(id)
      );

      // Đọc toàn bộ khóa trước khi thực hiện ghi.
      const slots = await tx.getAll(...slotRefs);

      slots.forEach((slot, index) => {
        if (slot.exists && slot.data().bookingId === bookingRef.id) {
          tx.delete(slotRefs[index]);
        }
      });

      tx.update(bookingRef, {
        status: 'cancelled',
        cancelledAt: FieldValue.serverTimestamp(),
      });
    });

    return res.json({
      success: true,
      message: 'Đã hủy lịch hẹn và giải phóng tài nguyên.',
    });
  } catch (error) {
    if (error.code === 'NOT_FOUND') {
      return fail(res, 404, error.message);
    }
    if (error.code === 'INVALID_STATUS' ||
        error.code === 'INVALID_RESOURCES') {
      return fail(res, 409, error.message);
    }

    console.error('Booking cancel error:', error);
    return fail(res, 500, 'Không thể hủy lịch hẹn.');
  }
});

module.exports = router;
