const express = require('express');
const { authenticateToken, requireRoles, enforceBranchAccess } = require('../../middlewares/rbac_guard');
const {
  listStaffMembers,
  createOrUpdateStaffMember,
  getStaffRoster,
  createStaffShift,
  updateStaffShift,
  deleteStaffShift,
  checkInShift,
  checkOutShift,
  requestShiftLeave,
  approveShiftLeave,
  getHrmKpiMetrics,
} = require('../../services/staff_hrm_service');

const router = express.Router();

// Bảo vệ RBAC cho toàn bộ route quản lý nhân sự & phân ca
router.use(authenticateToken);
router.use(requireRoles(['super_admin', 'branch_manager', 'receptionist', 'specialist']));
router.use(enforceBranchAccess);

/**
 * GET /api/v2/admin/staff/metrics
 * Thống kê KPI nhân sự, ca trực hôm nay & đơn nghỉ phép
 */
router.get('/metrics', async (req, res) => {
  try {
    const { date, branchId } = req.query;
    const targetBranch = req.branchContext || branchId;
    const result = await getHrmKpiMetrics({ branchId: targetBranch, date });
    return res.json(result);
  } catch (err) {
    console.error('[AdminStaffHrmV2] Metrics error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể tải thống kê nhân sự.' });
  }
});

/**
 * GET /api/v2/admin/staff/members
 * Lấy danh sách nhân viên & chuyên môn
 */
router.get('/members', async (req, res) => {
  try {
    const { branchId, role, status } = req.query;
    const targetBranch = req.branchContext || branchId;
    const result = await listStaffMembers({ branchId: targetBranch, role, status });
    return res.json(result);
  } catch (err) {
    console.error('[AdminStaffHrmV2] List staff error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể tải danh sách nhân viên.' });
  }
});

/**
 * POST /api/v2/admin/staff/members
 * Thêm hoặc cập nhật hồ sơ nhân viên (SuperAdmin, BranchManager)
 */
router.post('/members', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const { staffId, name, role, phone, email, branchId, categories, isActive } = req.body || {};
    const targetBranch = req.branchContext || branchId || 'central_hub';
    const result = await createOrUpdateStaffMember({
      staffId,
      name,
      role,
      phone,
      email,
      branchId: targetBranch,
      categories,
      isActive,
    });
    return res.json(result);
  } catch (err) {
    console.error('[AdminStaffHrmV2] Create staff member error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể lưu thông tin nhân viên.' });
  }
});

/**
 * GET /api/v2/admin/staff/roster
 * Bảng phân ca trực tuần / tháng
 */
router.get('/roster', async (req, res) => {
  try {
    const { branchId, startDate, endDate, staffId } = req.query;
    const targetBranch = req.branchContext || branchId;
    const result = await getStaffRoster({
      branchId: targetBranch,
      startDate,
      endDate,
      staffId,
    });
    return res.json(result);
  } catch (err) {
    console.error('[AdminStaffHrmV2] Roster error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể tải bảng phân ca trực.' });
  }
});

/**
 * POST /api/v2/admin/staff/shifts
 * Xếp ca làm việc mới cho nhân viên (SuperAdmin, BranchManager)
 */
router.post('/shifts', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const { staffId, staffName, role, branchId, date, shiftType, notes } = req.body || {};
    const targetBranch = req.branchContext || branchId || 'central_hub';
    const createdBy = req.user?.uid || 'admin';

    const result = await createStaffShift({
      staffId,
      staffName,
      role,
      branchId: targetBranch,
      date,
      shiftType,
      notes,
      createdBy,
    });
    return res.json(result);
  } catch (err) {
    console.error('[AdminStaffHrmV2] Create shift error:', err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể xếp ca làm việc.' });
  }
});

/**
 * PUT /api/v2/admin/staff/shifts/:id
 * Cập nhật ca làm việc (SuperAdmin, BranchManager)
 */
router.put('/shifts/:id', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const shiftId = req.params.id;
    const { shiftType, date, notes } = req.body || {};
    const updatedBy = req.user?.uid || 'admin';

    const result = await updateStaffShift({
      shiftId,
      shiftType,
      date,
      notes,
      updatedBy,
    });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Update shift error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể cập nhật ca trực.' });
  }
});

/**
 * DELETE /api/v2/admin/staff/shifts/:id
 * Xóa ca trực khỏi lịch làm việc (SuperAdmin, BranchManager)
 */
router.delete('/shifts/:id', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const shiftId = req.params.id;
    const result = await deleteStaffShift({ shiftId });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Delete shift error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể xóa ca trực.' });
  }
});

/**
 * POST /api/v2/admin/staff/shifts/:id/check-in
 * Chấm công vào ca trực
 */
router.post('/shifts/:id/check-in', async (req, res) => {
  try {
    const shiftId = req.params.id;
    const staffId = req.user?.uid || 'staff';
    const result = await checkInShift({ shiftId, staffId });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Check-in error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể chấm công vào ca.' });
  }
});

/**
 * POST /api/v2/admin/staff/shifts/:id/check-out
 * Chấm công kết ca trực
 */
router.post('/shifts/:id/check-out', async (req, res) => {
  try {
    const shiftId = req.params.id;
    const staffId = req.user?.uid || 'staff';
    const result = await checkOutShift({ shiftId, staffId });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Check-out error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể kết thúc ca trực.' });
  }
});

/**
 * POST /api/v2/admin/staff/shifts/:id/leave-request
 * Gửi đơn xin nghỉ phép ca trực
 */
router.post('/shifts/:id/leave-request', async (req, res) => {
  try {
    const shiftId = req.params.id;
    const { reason } = req.body || {};
    const staffId = req.user?.uid || 'staff';
    const result = await requestShiftLeave({ shiftId, reason, staffId });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Leave request error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể gửi yêu cầu xin nghỉ phép.' });
  }
});

/**
 * PATCH /api/v2/admin/staff/shifts/:id/leave-approval
 * Phê duyệt hoặc từ chối đơn xin nghỉ phép (SuperAdmin, BranchManager)
 */
router.patch('/shifts/:id/leave-approval', requireRoles(['super_admin', 'branch_manager']), async (req, res) => {
  try {
    const shiftId = req.params.id;
    const { approved, note } = req.body || {};
    const reviewedBy = req.user?.uid || 'manager';
    const result = await approveShiftLeave({ shiftId, approved, note, reviewedBy });
    return res.json(result);
  } catch (err) {
    console.error(`[AdminStaffHrmV2] Leave approval error for ${req.params.id}:`, err);
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Không thể duyệt đơn xin nghỉ phép.' });
  }
});

module.exports = router;
