const express = require('express');
const db = require('../../firebase');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const {
  getTimelineMatrix,
  confirmBookingAndReserveTechnician,
  checkInBooking,
  updateTreatmentRecord,
  completeBookingAndCalculateCommission,
  cancelBookingAndReleaseResources,
} = require('../../services/booking_scheduling_service');

const router = express.Router();

// Áp dụng bảo vệ RBAC cho toàn bộ route quản lý lịch hẹn
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'receptionist', 'specialist']));
router.use(enforceBranchAccess);

function serialize(doc) {
  if (!doc) return null;
  const data = typeof doc.data === 'function' ? doc.data() : doc;
  const id = doc.id || data.id || data.appointmentId;

  return {
    id,
    appointmentId: id,
    ...data,
    startAt: data.startAt?.toDate ? data.startAt.toDate().toISOString() : data.startAt,
    endAt: data.endAt?.toDate ? data.endAt.toDate().toISOString() : data.endAt,
    createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : data.createdAt,
    updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate().toISOString() : data.updatedAt,
  };
}

/**
 * GET /api/v2/admin/bookings/timeline
 * Trả về ma trận lịch hẹn theo ngày, công suất lấp đầy, danh sách phòng và KTV
 */
router.get('/timeline', async (req, res) => {
  try {
    const { date, roomId, technicianId } = req.query;
    const branchId = req.branchContext || req.query.branchId || 'central_hub';

    const result = await getTimelineMatrix({
      branchId,
      date,
      roomId,
      technicianId,
    });

    return res.json(result);
  } catch (err) {
    console.error('[AdminBookingsV2] Timeline error:', err);
    return res.status(500).json({ success: false, message: 'Không thể tải ma trận lịch hẹn.' });
  }
});

/**
 * GET /api/v2/admin/bookings
 * Danh sách lịch hẹn có bộ lọc tìm kiếm và trạng thái
 */
router.get('/', async (req, res) => {
  try {
    const { status, q, date } = req.query;
    let bookings = [];

    if (db.hasCredentials) {
      let query = db.collection('bookings');
      const snap = await query.get();
      bookings = snap.docs.map(serialize);
    }

    // Sắp xếp lịch hẹn theo thời gian bắt đầu
    bookings.sort((a, b) => {
      const dateA = a.startAt ? new Date(a.startAt).getTime() : 0;
      const dateB = b.startAt ? new Date(b.startAt).getTime() : 0;
      return dateB - dateA;
    });

    const stats = {
      total: bookings.length,
      pending: bookings.filter(b => b.status === 'pending').length,
      confirmed: bookings.filter(b => ['confirmed', 'approved'].includes(b.status)).length,
      checkedIn: bookings.filter(b => b.status === 'checked_in').length,
      inProgress: bookings.filter(b => b.status === 'in_progress').length,
      completed: bookings.filter(b => b.status === 'completed').length,
      cancelled: bookings.filter(b => ['cancelled', 'rejected'].includes(b.status)).length,
    };

    if (status && status !== 'all') {
      const s = status.toLowerCase();
      bookings = bookings.filter(b => (b.status || '').toLowerCase() === s);
    }

    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      bookings = bookings.filter(b => {
        const idMatch = (b.id || '').toLowerCase().includes(term);
        const nameMatch = (b.contactName || '').toLowerCase().includes(term);
        const phoneMatch = (b.contactPhone || '').toLowerCase().includes(term);
        const serviceMatch = (b.serviceName || '').toLowerCase().includes(term);
        return idMatch || nameMatch || phoneMatch || serviceMatch;
      });
    }

    return res.json({
      success: true,
      count: bookings.length,
      stats,
      data: bookings,
    });
  } catch (err) {
    console.error('[AdminBookingsV2] Lỗi tải danh sách:', err);
    return res.status(500).json({ success: false, message: 'Không thể tải danh sách lịch hẹn.' });
  }
});

/**
 * GET /api/v2/admin/bookings/:id
 * Chi tiết lịch hẹn
 */
router.get('/:id', async (req, res) => {
  try {
    const doc = await db.collection('bookings').doc(req.params.id).get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn.' });
    }
    return res.json({ success: true, data: serialize(doc) });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Lỗi khi tải chi tiết lịch hẹn.' });
  }
});

/**
 * POST /api/v2/admin/bookings/:id/confirm
 * Duyệt lịch hẹn và khóa slot KTV/phòng
 */
router.post('/:id/confirm', async (req, res) => {
  try {
    const { id } = req.params;
    const { technicianId, roomId, note, branchId } = req.body || {};

    if (!technicianId || !roomId) {
      return res.status(400).json({
        success: false,
        message: 'Bắt buộc phải chỉ định Kỹ thuật viên (technicianId) và Phòng trị liệu (roomId).',
      });
    }

    const result = await confirmBookingAndReserveTechnician({
      appointmentId: id,
      technicianId,
      roomId,
      staffId: req.user.uid,
      branchId: req.branchContext || branchId || 'central_hub',
      note,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message, conflicts: err.conflicts });
  }
});

/**
 * POST /api/v2/admin/bookings/:id/check-in
 * Tiếp nhận khách đến spa
 */
router.post('/:id/check-in', async (req, res) => {
  try {
    const { id } = req.params;
    const { note } = req.body || {};

    const result = await checkInBooking({
      appointmentId: id,
      staffId: req.user.uid,
      note,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * POST /api/v2/admin/bookings/:id/treatment-record
 * Cập nhật bệnh án da & ghi chú lâm sàng (Chuyên viên thực hiện)
 */
router.post('/:id/treatment-record', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      userId,
      skinConditionBefore,
      treatmentStepsApplied,
      productsUsed,
      skinReactionAfter,
      homecareRecommendations,
    } = req.body || {};

    const result = await updateTreatmentRecord({
      appointmentId: id,
      userId,
      technicianId: req.user.uid,
      skinConditionBefore,
      treatmentStepsApplied,
      productsUsed,
      skinReactionAfter,
      homecareRecommendations,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * POST /api/v2/admin/bookings/:id/complete
 * Hoàn tất liệu trình, tính hoa hồng cho KTV và tích điểm khách hàng
 */
router.post('/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { tips, paymentMethod } = req.body || {};

    const result = await completeBookingAndCalculateCommission({
      appointmentId: id,
      staffId: req.user.uid,
      tips,
      paymentMethod,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * POST /api/v2/admin/bookings/:id/cancel
 * Hủy lịch hẹn và giải phóng tài nguyên
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body || {};

    const result = await cancelBookingAndReleaseResources({
      appointmentId: id,
      staffId: req.user.uid,
      reason,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

module.exports = router;
