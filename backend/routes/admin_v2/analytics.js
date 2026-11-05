/**
 * analytics.js - Route Admin v2: Báo cáo Doanh thu & Lợi nhuận gộp
 */

const express = require('express');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const { getFinancialOverview } = require('../../services/financial_analytics_service');

const router = express.Router();

// Áp dụng bảo vệ RBAC cho module Financial Analytics & Reports
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'accountant']));
router.use(enforceBranchAccess);

/**
 * GET /api/v2/admin/analytics/overview
 * Báo cáo tổng thể: Tổng doanh thu, COGS, Lợi nhuận gộp, cơ cấu Bán lẻ vs Spa, chuỗi ngày & top biểu đồ
 */
router.get('/overview', async (req, res) => {
  try {
    const { period, startDate, endDate, branchId } = req.query;
    
    // Nếu là branch_manager thì ràng buộc chi nhánh nếu có gán
    let targetBranchId = branchId || 'all';
    if (req.user?.role === 'branch_manager' && req.user?.branchId) {
      targetBranchId = req.user.branchId;
    }

    const report = await getFinancialOverview({
      period: period || 'last_30_days',
      startDate: startDate || null,
      endDate: endDate || null,
      branchId: targetBranchId,
    });

    return res.json({
      success: true,
      data: report,
    });
  } catch (err) {
    console.error('[AdminAnalyticsV2] Overview report error:', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Không thể tổng hợp báo cáo tài chính.',
    });
  }
});

/**
 * GET /api/v2/admin/analytics/daily-trend
 * Chỉ lấy chuỗi ngày cho biểu đồ thời gian
 */
router.get('/daily-trend', async (req, res) => {
  try {
    const { period, startDate, endDate, branchId } = req.query;
    const report = await getFinancialOverview({
      period: period || 'last_30_days',
      startDate: startDate || null,
      endDate: endDate || null,
      branchId: branchId || 'all',
    });

    return res.json({
      success: true,
      data: report.dailyTrend,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Không thể lấy dữ liệu biểu đồ ngày.',
    });
  }
});

/**
 * GET /api/v2/admin/analytics/top-performers
 * Top sản phẩm bán chạy & Top dịch vụ được ưa chuộng nhất
 */
router.get('/top-performers', async (req, res) => {
  try {
    const { period, startDate, endDate, branchId } = req.query;
    const report = await getFinancialOverview({
      period: period || 'last_30_days',
      startDate: startDate || null,
      endDate: endDate || null,
      branchId: branchId || 'all',
    });

    return res.json({
      success: true,
      data: {
        topProducts: report.topProducts,
        topServices: report.topServices,
      },
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: err.message || 'Không thể lấy danh sách top doanh thu.',
    });
  }
});

module.exports = router;
