const assert = require('node:assert/strict');
const { requireRoles, enforceBranchAccess } = require('../middlewares/rbac_guard');
const orderTxService = require('../services/order_transaction_service');
const bookingSchedService = require('../services/booking_scheduling_service');

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

async function runTests() {
  console.log('🧪 Bắt đầu kiểm thử Admin v2 Core Services & RBAC...');

  // Test 1: requireRoles cho phép super_admin
  {
    const req = { user: { uid: 'u1', role: 'super_admin' } };
    const res = createMockRes();
    let nextCalled = false;
    const middleware = requireRoles(['branch_manager', 'receptionist']);
    middleware(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, true, 'Super Admin phải luôn được đi tiếp.');
    console.log('✅ PASS: requireRoles cho phép super_admin toàn quyền.');
  }

  // Test 2: requireRoles chặn specialist khi chỉ cho phép branch_manager
  {
    const req = { user: { uid: 'u2', role: 'specialist' } };
    const res = createMockRes();
    let nextCalled = false;
    const middleware = requireRoles(['super_admin', 'branch_manager']);
    middleware(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, false, 'Specialist không được duyệt quyền.');
    assert.equal(res.statusCode, 403, 'Phải trả về 403 Forbidden.');
    console.log('✅ PASS: requireRoles chặn vai trò không hợp lệ với HTTP 403.');
  }

  // Test 3: enforceBranchAccess chặn truy cập chéo chi nhánh
  {
    const req = {
      user: { uid: 'mgr1', role: 'branch_manager', assignedBranchId: 'branch_q1' },
      query: { branchId: 'branch_q7' },
      body: {},
      params: {},
    };
    const res = createMockRes();
    let nextCalled = false;
    enforceBranchAccess(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, false, 'Không được phép truy cập chi nhánh khác.');
    assert.equal(res.statusCode, 403, 'Phải trả về 403 Forbidden.');
    console.log('✅ PASS: enforceBranchAccess bảo vệ dữ liệu đa chi nhánh.');
  }

  // Test 4: enforceBranchAccess cho phép super_admin truy cập mọi chi nhánh
  {
    const req = {
      user: { uid: 'sa1', role: 'super_admin', assignedBranchId: 'central_hub' },
      query: { branchId: 'branch_q7' },
      body: {},
      params: {},
    };
    const res = createMockRes();
    let nextCalled = false;
    enforceBranchAccess(req, res, () => { nextCalled = true; });

    assert.equal(nextCalled, true, 'Super Admin được phép truy cập mọi chi nhánh.');
    assert.equal(req.branchContext, 'branch_q7');
    console.log('✅ PASS: enforceBranchAccess cho phép super_admin xuyên chi nhánh.');
  }

  // Test 5: Kiểm tra các hàm nghiệp vụ của order_transaction_service
  {
    assert.equal(typeof orderTxService.confirmOrderWithAtomicInventory, 'function');
    assert.equal(typeof orderTxService.transitionOrderStatus, 'function');
    assert.equal(typeof orderTxService.cancelOrderWithAtomicRollback, 'function');
    console.log('✅ PASS: order_transaction_service cung cấp đầy đủ 3 hàm giao dịch ACID.');
  }

  // Test 6: Kiểm tra các hàm nghiệp vụ của booking_scheduling_service
  {
    assert.equal(typeof bookingSchedService.getTimelineMatrix, 'function');
    assert.equal(typeof bookingSchedService.confirmBookingAndReserveTechnician, 'function');
    assert.equal(typeof bookingSchedService.checkInBooking, 'function');
    assert.equal(typeof bookingSchedService.updateTreatmentRecord, 'function');
    assert.equal(typeof bookingSchedService.completeBookingAndCalculateCommission, 'function');
    assert.equal(typeof bookingSchedService.cancelBookingAndReleaseResources, 'function');
    console.log('✅ PASS: booking_scheduling_service cung cấp đầy đủ 6 hàm điều phối ma trận.');
  }

  console.log('🎉 TOÀN BỘ KIỂM THỬ ADMIN V2 SERVICES ĐÃ VƯỢT QUA!');
}

runTests().catch(err => {
  console.error('❌ Kiểm thử thất bại:', err);
  process.exit(1);
});

