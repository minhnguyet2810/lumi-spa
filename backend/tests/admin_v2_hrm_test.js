const assert = require('node:assert/strict');
const { requireRoles } = require('../middlewares/rbac_guard');
const hrmService = require('../services/staff_hrm_service');

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(obj) {
      this.body = obj;
      return this;
    },
  };
  return res;
}

async function runHrmTests() {
  console.log('🧪 Bắt đầu kiểm thử Module 4: HRM & Staff Scheduling (Không có hoa hồng)...');

  // Test 1: Khai báo đầy đủ các ca làm việc chuẩn
  {
    assert.ok(hrmService.SHIFT_TYPES.morning, 'Phải có ca sáng.');
    assert.ok(hrmService.SHIFT_TYPES.afternoon, 'Phải có ca chiều.');
    assert.ok(hrmService.SHIFT_TYPES.full, 'Phải có ca cả ngày.');
    assert.equal(hrmService.SHIFT_TYPES.morning.timeRange, '08:30 - 14:30');
    assert.equal(hrmService.SHIFT_TYPES.afternoon.timeRange, '13:30 - 19:30');
    assert.equal(hrmService.SHIFT_TYPES.full.timeRange, '09:00 - 18:00');
    console.log('✅ PASS: SHIFT_TYPES định nghĩa chính xác 3 khung giờ ca trực tiêu chuẩn.');
  }

  // Test 2: Xác nhận hoàn toàn KHÔNG có bảng tính hoa hồng
  {
    assert.equal(hrmService.calculateCommission, undefined, 'Tuyệt đối không có hàm tính hoa hồng.');
    assert.equal(hrmService.commissions, undefined, 'Tuyệt đối không có bảng hoa hồng.');
    console.log('✅ PASS: Module 4 tuân thủ nghiêm ngặt yêu cầu loại bỏ bảng tính hoa hồng KTV.');
  }

  // Test 3: RBAC Phân quyền xếp ca
  {
    const reqSa = { user: { uid: 'sa1', role: 'super_admin' } };
    const resSa = createMockRes();
    let nextSa = false;
    requireRoles(['super_admin', 'branch_manager'])(reqSa, resSa, () => { nextSa = true; });
    assert.equal(nextSa, true, 'SuperAdmin phải được xếp ca.');

    const reqBm = { user: { uid: 'bm1', role: 'branch_manager' } };
    const resBm = createMockRes();
    let nextBm = false;
    requireRoles(['super_admin', 'branch_manager'])(reqBm, resBm, () => { nextBm = true; });
    assert.equal(nextBm, true, 'BranchManager phải được xếp ca.');

    const reqSp = { user: { uid: 'sp1', role: 'specialist' } };
    const resSp = createMockRes();
    let nextSp = false;
    requireRoles(['super_admin', 'branch_manager'])(reqSp, resSp, () => { nextSp = true; });
    assert.equal(nextSp, false, 'Specialist không được tự ý xếp ca.');
    assert.equal(resSp.statusCode, 403, 'Specialist bị từ chối với 403 Forbidden.');
    console.log('✅ PASS: RBAC bảo vệ chặt chẽ quyền xếp ca (Chỉ SuperAdmin & BranchManager).');
  }

  // Test 4: Lấy danh sách nhân viên thực tế
  {
    const result = await hrmService.listStaffMembers({});
    assert.equal(result.success, true);
    assert.ok(Array.isArray(result.data));
    assert.ok(result.count >= 0);
    console.log(`✅ PASS: listStaffMembers tải thành công ${result.count} nhân sự trong hệ thống.`);
  }

  // Test 5: Tạo / Cập nhật nhân viên mới
  {
    const testStaffName = 'Chuyên viên Kiểm Thử Auto';
    const result = await hrmService.createOrUpdateStaffMember({
      staffId: 'staff_test_auto_99',
      name: testStaffName,
      role: 'specialist',
      phone: '0988776655',
      categories: ['facial', 'body'],
      branchId: 'central_hub',
      isActive: true,
    });
    assert.equal(result.success, true);
    assert.equal(result.data.name, testStaffName);
    assert.equal(result.data.role, 'specialist');
    console.log('✅ PASS: createOrUpdateStaffMember tạo và lưu nhân sự thành công.');
  }

  // Test 6: Xếp ca làm việc & Chống trùng ca trong cùng ngày
  {
    const testDate = '2026-11-20';
    // Xếp ca sáng
    const shiftRes = await hrmService.createStaffShift({
      staffId: 'staff_test_auto_99',
      staffName: 'Chuyên viên Kiểm Thử Auto',
      role: 'specialist',
      branchId: 'central_hub',
      date: testDate,
      shiftType: 'morning',
      notes: 'Ca kiểm thử tự động',
    });
    assert.equal(shiftRes.success, true);
    assert.equal(shiftRes.data.status, 'scheduled');

    // Thử xếp trùng ca trong ngày
    let conflictOccurred = false;
    try {
      await hrmService.createStaffShift({
        staffId: 'staff_test_auto_99',
        staffName: 'Chuyên viên Kiểm Thử Auto',
        date: testDate,
        shiftType: 'morning',
      });
    } catch (err) {
      conflictOccurred = true;
      assert.equal(err.statusCode, 409, 'Phải trả về mã lỗi 409 Conflict.');
    }
    assert.equal(conflictOccurred, true, 'Phải phát hiện và chặn trùng ca.');
    console.log('✅ PASS: createStaffShift xếp ca và ngăn chặn xung đột trùng ca nguyên tử.');

    // Test 7: Chấm công Vào ca (Check-in) & Kết ca (Check-out)
    const shiftId = shiftRes.data.id;
    const checkInRes = await hrmService.checkInShift({ shiftId, staffId: 'staff_test_auto_99' });
    assert.equal(checkInRes.success, true);
    assert.equal(checkInRes.data.status, 'checked_in');

    const checkOutRes = await hrmService.checkOutShift({ shiftId, staffId: 'staff_test_auto_99' });
    assert.equal(checkOutRes.success, true);
    assert.equal(checkOutRes.data.status, 'completed');
    console.log('✅ PASS: checkInShift và checkOutShift cập nhật trạng thái chấm công chính xác.');

    // Dọn dẹp ca test
    await hrmService.deleteStaffShift({ shiftId });
  }

  // Test 8: KPI Metrics HRM
  {
    const metricsRes = await hrmService.getHrmKpiMetrics({});
    assert.equal(metricsRes.success, true);
    assert.ok(typeof metricsRes.data.totalStaff === 'number');
    assert.ok(typeof metricsRes.data.onDutyToday === 'number');
    assert.ok(typeof metricsRes.data.pendingLeaveCount === 'number');
    console.log(`✅ PASS: getHrmKpiMetrics tổng hợp KPI chuẩn xác (Tổng nhân sự: ${metricsRes.data.totalStaff}, Trực hôm nay: ${metricsRes.data.onDutyToday}).`);
  }

  console.log('🎉 TOÀN BỘ KIỂM THỬ MODULE 4 HRM & STAFF SCHEDULING ĐÃ VƯỢT QUA!');
}

runHrmTests()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('❌ Kiểm thử HRM thất bại:', err);
    process.exit(1);
  });
