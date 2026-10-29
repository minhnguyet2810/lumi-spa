const express = require('express');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');
const { reserveBookingResources } = require('../booking_transactions');

const router = express.Router();

const VALID_HOURS = new Set([9, 10, 11, 12, 13, 14, 15, 16, 17]);
// Bộ nhớ cục bộ khi chạy local chưa có quyền Google Cloud Firestore
const { devBookings } = require('../dev_store');

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

// GET /api/bookings/slots (Public: Tra cứu khung giờ còn trống)
router.get('/slots', async (req, res) => {
  try {
    const { date, serviceId } = req.query;
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return fail(res, 400, 'Tham số date không hợp lệ (định dạng YYYY-MM-DD).');
    }

    let durationMinutes = 60;
    let categoryId = null;

    if (serviceId && db.hasCredentials) {
      try {
        const sDoc = await db.collection('services').doc(serviceId).get();
        if (sDoc.exists) {
          const sData = sDoc.data();
          durationMinutes = Number(sData.durationMinutes) || 60;
          categoryId = sData.categoryId || null;
        }
      } catch (_) {}
    }

    const [year, month, day] = date.split('-').map(Number);
    const startOfDay = new Date(Date.UTC(year, month - 1, day, 0, 0, 0));
    const endOfDay = new Date(Date.UTC(year, month - 1, day, 23, 59, 59));

    const activeBookings = [];
    if (!db.hasCredentials) {
      activeBookings.push(...devBookings.filter(b => {
        if (!b.startAt || !['pending', 'confirmed'].includes(b.status)) return false;
        const bDate = new Date(b.startAt);
        return bDate >= startOfDay && bDate <= endOfDay;
      }));
    } else {
      try {
        const bookingsSnap = await db.collection('bookings')
          .where('startAt', '>=', Timestamp.fromDate(startOfDay))
          .where('startAt', '<=', Timestamp.fromDate(endOfDay))
          .get();

        activeBookings.push(...bookingsSnap.docs
          .map(d => d.data())
          .filter(b => ['pending', 'confirmed'].includes(b.status)));
      } catch (_) {
        activeBookings.push(...devBookings.filter(b => {
          if (!b.startAt || !['pending', 'confirmed'].includes(b.status)) return false;
          const bDate = new Date(b.startAt);
          return bDate >= startOfDay && bDate <= endOfDay;
        }));
      }
    }

    let capacity = 2;
    if (categoryId === 'beauty') capacity = 1;

    const now = Date.now();
    const slots = [];

    for (const h of [9, 10, 11, 12, 13, 14, 15, 16, 17]) {
      const slotStart = new Date(Date.UTC(year, month - 1, day, h - 7));
      const slotEnd = new Date(slotStart.getTime() + durationMinutes * 60 * 1000);

      if (h * 60 + durationMinutes > 18 * 60) {
        slots.push({ hour: h, status: 'closedExceeded', available: false, reason: 'Quá 18:00' });
        continue;
      }

      if (slotStart.getTime() <= now) {
        slots.push({ hour: h, status: 'past', available: false, reason: 'Đã qua' });
        continue;
      }

      const overlapping = activeBookings.filter(b => {
        if (!b.startAt) return false;
        const bStart = typeof b.startAt.toDate === 'function'
            ? b.startAt.toDate().getTime()
            : new Date(b.startAt).getTime();
        const bDuration = Number(b.durationMinutes) || 60;
        const bEnd = bStart + bDuration * 60 * 1000;
        const catMatch = !categoryId || !b.categoryId || b.categoryId === categoryId;
        return catMatch && slotStart.getTime() < bEnd && bStart < slotEnd.getTime();
      }).length;

      if (overlapping >= capacity) {
        slots.push({ hour: h, status: 'fullyBooked', available: false, remainingCapacity: 0, reason: 'Kín chỗ' });
      } else {
        slots.push({ hour: h, status: 'available', available: true, remainingCapacity: capacity - overlapping });
      }
    }

    return res.json({
      success: true,
      data: {
        date,
        serviceId,
        durationMinutes,
        slots,
      },
    });
  } catch (error) {
    console.error('Slot fetch error:', error);
    return fail(res, 500, 'Không thể tải danh sách khung giờ.');
  }
});

// Các API bên dưới yêu cầu Firebase ID Token
router.use(requireAuth);

// GET /api/bookings
router.get('/', async (req, res) => {
  if (!db.hasCredentials) {
    const userBookings = devBookings
      .filter(b => b.userId === req.user.uid)
      .sort((a, b) => (b.startAt || '').localeCompare(a.startAt || ''));
    return res.json({ success: true, data: userBookings });
  }

  try {
    const snapshot = await db.collection('bookings')
      .where('userId', '==', req.user.uid)
      .get();

    const bookings = snapshot.docs.map(bookingData)
      .sort((a, b) => (b.startAt || '').localeCompare(a.startAt || ''));

    return res.json({ success: true, data: bookings });
  } catch (error) {
    console.warn('Firestore booking query failed, using local dev store:', error.message);
    const userBookings = devBookings
      .filter(b => b.userId === req.user.uid)
      .sort((a, b) => (b.startAt || '').localeCompare(a.startAt || ''));
    return res.json({ success: true, data: userBookings });
  }
});

// POST /api/bookings
router.post('/', async (req, res) => {
  try {
    const { serviceId, date, hour, contactName, contactPhone, serviceName, durationMinutes: customDuration, price: customPrice, categoryId: customCategory } = req.body || {};

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

    let service = {};
    if (db.hasCredentials) {
      try {
        const serviceDoc = await db.collection('services').doc(serviceId).get();
        if (serviceDoc.exists) {
          service = serviceDoc.data();
        }
      } catch (_) {}
    }

    const price = Number(service.price ?? customPrice ?? 0);
    const durationMinutes = Number(service.durationMinutes ?? customDuration ?? 60);
    const categoryId = service.categoryId ?? customCategory ?? 'general';

    // Spa hoạt động 09:00–18:00, dịch vụ phải kết thúc trước 18:00.
    if (hour * 60 + durationMinutes > 18 * 60) {
      return fail(res, 400, 'Dịch vụ phải kết thúc trước 18:00.');
    }

    if (!db.hasCredentials) {
      const devItem = {
        id: `book_${Date.now()}`,
        userId: req.user.uid,
        contactName: contactName.trim(),
        contactPhone: contactPhone.trim(),
        serviceId,
        serviceName: service.name || serviceName || serviceId,
        categoryId,
        price,
        durationMinutes,
        status: 'pending',
        startAt: startAt.toISOString(),
        createdAt: new Date().toISOString(),
        resourceSlotIds: [`slot_${Date.now()}`],
      };
      devBookings.push(devItem);

      return res.status(201).json({
        success: true,
        data: devItem,
        message: 'Đã tiếp nhận yêu cầu đặt lịch, đang chờ spa xác nhận.',
      });
    }

    try {
      const bookingRef = db.collection('bookings').doc();

      const result = await reserveBookingResources(db, {
        bookingRef,
        bookingData: {
          userId: req.user.uid,
          contactName: contactName.trim(),
          contactPhone: contactPhone.trim(),
          serviceId,
          serviceName: service.name || serviceName || serviceId,
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
    } catch (reserveError) {
      if (reserveError.code === 'SLOT_TAKEN' || reserveError.code === 'NO_RESOURCES') {
        return fail(res, 409, reserveError.message);
      }
      console.warn('Firestore transaction unavailable, storing in devBookings:', reserveError.message);

      const devItem = {
        id: `book_${Date.now()}`,
        userId: req.user.uid,
        contactName: contactName.trim(),
        contactPhone: contactPhone.trim(),
        serviceId,
        serviceName: service.name || serviceName || serviceId,
        categoryId,
        price,
        durationMinutes,
        status: 'pending',
        startAt: startAt.toISOString(),
        createdAt: new Date().toISOString(),
        resourceSlotIds: [`slot_${Date.now()}`],
      };
      devBookings.push(devItem);

      return res.status(201).json({
        success: true,
        data: devItem,
        message: 'Đã tiếp nhận yêu cầu đặt lịch, đang chờ spa xác nhận.',
      });
    }
  } catch (error) {
    console.error('Booking create error:', error);
    return fail(res, 500, 'Không thể tạo lịch hẹn.');
  }
});

// PATCH /api/bookings/:id/cancel
router.patch('/:id/cancel', async (req, res) => {
  try {
    if (!db.hasCredentials) {
      const localItem = devBookings.find(b => b.id === req.params.id && b.userId === req.user.uid);
      if (localItem) {
        localItem.status = 'cancelled';
        localItem.cancelledAt = new Date().toISOString();
        return res.json({ success: true, message: 'Đã hủy lịch hẹn thành công.' });
      }
      return fail(res, 404, 'Không tìm thấy lịch hẹn.');
    }

    const bookingRef = db.collection('bookings').doc(req.params.id);

    try {
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

        if (Array.isArray(data.resourceSlotIds) && data.resourceSlotIds.length > 0) {
          const slotRefs = data.resourceSlotIds.map(id =>
            db.collection('resource_slots').doc(id)
          );

          const slots = await tx.getAll(...slotRefs);
          slots.forEach((slot, index) => {
            if (slot.exists && slot.data().bookingId === bookingRef.id) {
              tx.delete(slotRefs[index]);
            }
          });
        }

        tx.update(bookingRef, {
          status: 'cancelled',
          cancelledAt: FieldValue.serverTimestamp(),
          resourceSlotIds: [],
        });
      });

      return res.json({ success: true, message: 'Đã hủy lịch hẹn thành công.' });
    } catch (txError) {
      if (txError.code === 'NOT_FOUND' || txError.code === 'INVALID_STATUS') {
        return fail(res, 400, txError.message);
      }

      const localItem = devBookings.find(b => b.id === req.params.id && b.userId === req.user.uid);
      if (localItem) {
        localItem.status = 'cancelled';
        localItem.cancelledAt = new Date().toISOString();
        return res.json({ success: true, message: 'Đã hủy lịch hẹn thành công.' });
      }
      throw txError;
    }
  } catch (error) {
    console.error('Cancel booking error:', error);
    return fail(res, 500, error.message || 'Không thể hủy lịch hẹn.');
  }
});

module.exports = router;
