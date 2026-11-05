const express = require('express');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const {
  getCustomer360Profile,
  adjustLoyalty,
  moderateCustomer,
  updateSkinProfile,
  listCustomersWith360Metrics,
} = require('../../services/customer_360_service');

const router = express.Router();

// Áp dụng bảo vệ RBAC cho toàn bộ route CRM & Quản lý Khách hàng
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'receptionist', 'specialist']));
router.use(enforceBranchAccess);

/**
 * GET /api/v2/admin/customers
 * Tra cứu danh sách khách hàng kèm bộ lọc phân khúc và KPI Metrics
 */
router.get('/', async (req, res) => {
  try {
    const { q, tier, status, sortBy, limit, page } = req.query;
    const result = await listCustomersWith360Metrics({
      query: q,
      tier,
      status,
      sortBy,
      limit,
      page,
    });
    return res.json(result);
  } catch (err) {
    console.error('[AdminCustomersV2] List customers error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể tải danh sách khách hàng.' });
  }
});

/**
 * GET /api/v2/admin/customers/:id/360
 * Lấy hồ sơ 360 độ toàn diện của khách hàng (CRM 360 View)
 */
router.get('/:id/360', async (req, res) => {
  try {
    const customerId = req.params.id;
    const result = await getCustomer360Profile(customerId);
    return res.json(result);
  } catch (err) {
    console.error(`[AdminCustomersV2] Get 360 profile error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể tải hồ sơ 360 của khách hàng.' });
  }
});

/**
 * POST /api/v2/admin/customers/:id/loyalty-adjust
 * Điều chỉnh điểm thưởng & thăng/hạ hạng thành viên (SuperAdmin, BranchManager)
 */
router.post('/:id/loyalty-adjust', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const customerId = req.params.id;
    const { pointsDelta, newTier, reason } = req.body || {};
    const staffId = req.user?.uid || 'admin';

    const result = await adjustLoyalty({
      customerId,
      pointsDelta,
      newTier,
      reason,
      staffId,
    });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminCustomersV2] Adjust loyalty error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể điều chỉnh điểm thành viên.' });
  }
});

/**
 * PATCH /api/v2/admin/customers/:id/moderation
 * Khóa hoặc mở khóa tài khoản khách hàng (SuperAdmin, BranchManager)
 */
router.patch('/:id/moderation', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const customerId = req.params.id;
    const { status, reason } = req.body || {};
    const staffId = req.user?.uid || 'admin';

    const result = await moderateCustomer({
      customerId,
      status,
      reason,
      staffId,
    });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminCustomersV2] Moderate customer error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể điều chỉnh trạng thái tài khoản.' });
  }
});

/**
 * PATCH /api/v2/admin/customers/:id/skin-profile
 * Cập nhật hồ sơ da liễu, hoạt chất dị ứng & chống chỉ định lâm sàng
 */
router.patch('/:id/skin-profile', requireRoles(['super_admin', 'branch_manager', 'specialist', 'receptionist']), async (req, res) => {
  try {
    const customerId = req.params.id;
    const { skinType, concerns, knownAllergies, contraindications, currentRoutine } = req.body || {};
    const staffId = req.user?.uid || 'specialist';

    const result = await updateSkinProfile({
      customerId,
      skinType,
      concerns,
      knownAllergies,
      contraindications,
      currentRoutine,
      staffId,
    });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminCustomersV2] Update skin profile error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể cập nhật hồ sơ da liễu.' });
  }
});

module.exports = router;

