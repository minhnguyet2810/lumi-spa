const express = require('express');
const db = require('../../firebase');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const {
  confirmOrderWithAtomicInventory,
  transitionOrderStatus,
  cancelOrderWithAtomicRollback,
} = require('../../services/order_transaction_service');

const router = express.Router();

// Áp dụng bảo vệ RBAC cho toàn bộ route quản lý đơn hàng
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'receptionist']));
router.use(enforceBranchAccess);

function serialize(doc) {
  if (!doc) return null;
  const data = typeof doc.data === 'function' ? doc.data() : doc;
  const id = doc.id || data.id || data.orderId;

  return {
    id,
    orderId: id,
    ...data,
    createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : data.createdAt,
    updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate().toISOString() : data.updatedAt,
    confirmedAt: data.confirmedAt?.toDate ? data.confirmedAt.toDate().toISOString() : data.confirmedAt,
  };
}

/**
 * GET /api/v2/admin/orders
 * Lấy danh sách đơn hàng có lọc theo chi nhánh, trạng thái, tìm kiếm và khoảng ngày
 */
router.get('/', async (req, res) => {
  try {
    const { status, q, branchId, startDate, endDate } = req.query;
    let orders = [];

    if (db.hasCredentials) {
      let query = db.collection('orders');

      const targetBranch = req.branchContext || branchId;
      if (targetBranch && targetBranch !== 'all') {
        query = query.where('branchId', '==', targetBranch);
      }

      const snap = await query.get();
      orders = snap.docs.map(serialize);
    }

    // Sắp xếp đơn mới nhất lên trên
    orders.sort((a, b) => {
      const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return dateB - dateA;
    });

    // Thống kê tài chính & vận hành
    const stats = {
      totalOrders: orders.length,
      pending: orders.filter(o => o.status === 'pending').length,
      confirmed: orders.filter(o => o.status === 'confirmed').length,
      packaging: orders.filter(o => o.status === 'packaging').length,
      shipping: orders.filter(o => o.status === 'shipping').length,
      completed: orders.filter(o => o.status === 'completed').length,
      cancelled: orders.filter(o => o.status === 'cancelled').length,
      totalRevenue: orders
        .filter(o => ['confirmed', 'packaging', 'shipping', 'completed'].includes(o.status))
        .reduce((sum, o) => sum + (Number(o.total) || 0), 0),
    };

    // Bộ lọc trạng thái
    if (status && status !== 'all') {
      const s = status.toLowerCase();
      orders = orders.filter(o => (o.status || '').toLowerCase() === s);
    }

    // Bộ lọc tìm kiếm
    if (q && q.trim()) {
      const term = q.trim().toLowerCase();
      orders = orders.filter(o => {
        const idMatch = (o.id || o.orderId || '').toLowerCase().includes(term);
        const nameMatch = (o.customerName || '').toLowerCase().includes(term);
        const phoneMatch = (o.phone || '').toLowerCase().includes(term);
        return idMatch || nameMatch || phoneMatch;
      });
    }

    return res.json({
      success: true,
      count: orders.length,
      stats,
      data: orders,
    });
  } catch (err) {
    console.error('[AdminOrdersV2] Lỗi tải danh sách:', err);
    return res.status(500).json({ success: false, message: 'Không thể tải danh sách đơn hàng.' });
  }
});

/**
 * GET /api/v2/admin/orders/:id
 * Chi tiết đơn hàng kèm lịch sử trạng thái (Audit Trail)
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('orders').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng.' });
    }

    return res.json({
      success: true,
      data: serialize(doc),
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Lỗi khi tải chi tiết đơn hàng.' });
  }
});

/**
 * POST /api/v2/admin/orders/:id/confirm
 * Duyệt đơn và trừ tồn kho chi nhánh nguyên tử
 */
router.post('/:id/confirm', async (req, res) => {
  try {
    const { id } = req.params;
    const { note, branchId } = req.body || {};
    const effectiveBranch = req.branchContext || branchId || 'central_hub';

    const result = await confirmOrderWithAtomicInventory({
      orderId: id,
      staffId: req.user.uid,
      branchId: effectiveBranch,
      note,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * POST /api/v2/admin/orders/:id/transition
 * Chuyển trạng thái giao hàng (packaging -> shipping -> completed)
 */
router.post('/:id/transition', async (req, res) => {
  try {
    const { id } = req.params;
    const { toStatus, note, trackingNumber, shippingCarrier } = req.body || {};

    if (!toStatus) {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp trạng thái toStatus.' });
    }

    const result = await transitionOrderStatus({
      orderId: id,
      toStatus,
      staffId: req.user.uid,
      note,
      trackingNumber,
      shippingCarrier,
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * POST /api/v2/admin/orders/:id/cancel
 * Hủy đơn hàng và tự động hoàn trả tồn kho (Rollback)
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body || {};

    if (!reason || typeof reason !== 'string' || !reason.trim()) {
      return res.status(400).json({ success: false, message: 'Bắt buộc phải nhập lý do hủy đơn hàng.' });
    }

    const result = await cancelOrderWithAtomicRollback({
      orderId: id,
      staffId: req.user.uid,
      reason: reason.trim(),
    });

    return res.json(result);
  } catch (err) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

module.exports = router;
