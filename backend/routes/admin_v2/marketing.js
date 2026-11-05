/**
 * marketing.js - Route Admin v2: Cấu hình Voucher & Chiến dịch Marketing
 */

const express = require('express');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const {
  listVouchers,
  getVoucherByCode,
  saveVoucher,
  toggleVoucherStatus,
  deleteVoucher,
  broadcastMarketingCampaign,
  getMarketingKpiStats,
} = require('../../services/marketing_voucher_service');

const router = express.Router();

// Áp dụng bảo vệ RBAC cho module Marketing & Voucher
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'marketing_lead', 'receptionist']));
router.use(enforceBranchAccess);

/**
 * GET /api/v2/admin/marketing/vouchers
 * Danh sách toàn bộ Voucher kèm lọc theo status và tìm kiếm
 */
router.get('/vouchers', async (req, res) => {
  try {
    const { status, search, limit } = req.query;
    const vouchers = await listVouchers({
      status: status || 'all',
      search: search || '',
      limit: Number(limit || 100),
    });
    return res.json({
      success: true,
      data: vouchers,
      total: vouchers.length,
    });
  } catch (err) {
    console.error('[AdminMarketingV2] List vouchers error:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Không thể lấy danh sách voucher.',
    });
  }
});

/**
 * GET /api/v2/admin/marketing/kpis
 * Tổng quan KPI Marketing, hiệu quả voucher & chiến dịch push
 */
router.get('/kpis', async (req, res) => {
  try {
    const stats = await getMarketingKpiStats();
    return res.json({
      success: true,
      data: stats,
    });
  } catch (err) {
    console.error('[AdminMarketingV2] KPI stats error:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Không thể lấy thống kê marketing.',
    });
  }
});

/**
 * GET /api/v2/admin/marketing/vouchers/:code
 * Chi tiết một Voucher
 */
router.get('/vouchers/:code', async (req, res) => {
  try {
    const voucher = await getVoucherByCode(req.params.code);
    return res.json({
      success: true,
      data: voucher,
    });
  } catch (err) {
    return res.status(404).json({
      success: false,
      message: err.message || 'Không tìm thấy voucher.',
    });
  }
});

/**
 * POST /api/v2/admin/marketing/vouchers
 * Tạo Voucher mới
 */
router.post('/vouchers', requireRoles(['super_admin', 'branch_manager', 'marketing_lead']), async (req, res) => {
  try {
    const author = {
      uid: req.user?.uid || 'admin',
      name: req.user?.displayName || req.user?.fullName || req.user?.email || 'Admin',
    };
    const result = await saveVoucher(req.body, author);
    return res.status(201).json(result);
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'Không thể tạo voucher.',
    });
  }
});

/**
 * PUT /api/v2/admin/marketing/vouchers/:code
 * Cập nhật cấu hình Voucher
 */
router.put('/vouchers/:code', requireRoles(['super_admin', 'branch_manager', 'marketing_lead']), async (req, res) => {
  try {
    const author = {
      uid: req.user?.uid || 'admin',
      name: req.user?.displayName || req.user?.fullName || req.user?.email || 'Admin',
    };
    const payload = {
      ...req.body,
      code: req.params.code,
    };
    const result = await saveVoucher(payload, author);
    return res.json(result);
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'Không thể cập nhật voucher.',
    });
  }
});

/**
 * PATCH /api/v2/admin/marketing/vouchers/:code/status
 * Bật/tắt trạng thái Voucher nhanh
 */
router.patch('/vouchers/:code/status', requireRoles(['super_admin', 'branch_manager', 'marketing_lead']), async (req, res) => {
  try {
    const { isActive } = req.body;
    const result = await toggleVoucherStatus(req.params.code, isActive);
    return res.json(result);
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'Không thể đổi trạng thái voucher.',
    });
  }
});

/**
 * DELETE /api/v2/admin/marketing/vouchers/:code
 * Xóa hoặc hủy kích hoạt Voucher
 */
router.delete('/vouchers/:code', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const result = await deleteVoucher(req.params.code);
    return res.json(result);
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'Không thể xóa voucher.',
    });
  }
});

/**
 * POST /api/v2/admin/marketing/broadcast
 * Bắn chiến dịch thông báo & FCM push theo phân khúc khách hàng
 */
router.post('/broadcast', requireRoles(['super_admin', 'branch_manager', 'marketing_lead']), async (req, res) => {
  try {
    const author = {
      uid: req.user?.uid || 'admin',
      name: req.user?.displayName || req.user?.fullName || req.user?.email || 'Admin',
    };
    const { campaignName, title, body, segment, voucherCode, imageUrl } = req.body;
    const result = await broadcastMarketingCampaign({
      campaignName,
      title,
      body,
      segment,
      voucherCode,
      imageUrl,
      author,
    });
    return res.json(result);
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'Không thể gửi chiến dịch marketing.',
    });
  }
});

module.exports = router;
