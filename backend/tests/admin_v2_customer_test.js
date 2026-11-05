const assert = require('node:assert/strict');
const { requireRoles } = require('../middlewares/rbac_guard');
const customerService = require('../services/customer_360_service');

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

async function runCustomerCrmTests() {
  console.log('🧪 Bắt đầu kiểm thử Customer 360 CRM & Tiered Loyalty Management...');

  // Test 1: calculateTierFromMetrics logic
  {
    assert.equal(customerService.calculateTierFromMetrics(0, 0), 'bronze');
    assert.equal(customerService.calculateTierFromMetrics(999, 900000), 'bronze');
    assert.equal(customerService.calculateTierFromMetrics(1000, 500000), 'silver');
    assert.equal(customerService.calculateTierFromMetrics(500, 1000000), 'silver');
    assert.equal(customerService.calculateTierFromMetrics(5000, 0), 'gold');
    assert.equal(customerService.calculateTierFromMetrics(2000, 5000000), 'gold');
    assert.equal(customerService.calculateTierFromMetrics(15000, 0), 'diamond');
    assert.equal(customerService.calculateTierFromMetrics(0, 15000000), 'diamond');
    console.log('✅ PASS: calculateTierFromMetrics tính toán chính xác 4 thứ hạng thành viên.');
  }

  // Test 2: normalizeTier mapping
  {
    assert.equal(customerService.normalizeTier('Bronze'), 'bronze');
    assert.equal(customerService.normalizeTier('Thành viên'), 'bronze');
    assert.equal(customerService.normalizeTier('Bạc'), 'silver');
    assert.equal(customerService.normalizeTier('Silver'), 'silver');
    assert.equal(customerService.normalizeTier('Vàng'), 'gold');
    assert.equal(customerService.normalizeTier('Gold'), 'gold');
    assert.equal(customerService.normalizeTier('Kim Cương'), 'diamond');
    assert.equal(customerService.normalizeTier('Diamond'), 'diamond');
    console.log('✅ PASS: normalizeTier chuẩn hóa tiếng Việt & tiếng Anh sang mã chuẩn.');
  }

  // Test 3: Export đầy đủ các hàm cốt lõi của customer_360_service
  {
    assert.equal(typeof customerService.getCustomer360Profile, 'function');
    assert.equal(typeof customerService.adjustLoyalty, 'function');
    assert.equal(typeof customerService.moderateCustomer, 'function');
    assert.equal(typeof customerService.updateSkinProfile, 'function');
    assert.equal(typeof customerService.updateCustomerProfile, 'function');
    assert.equal(typeof customerService.listCustomersWith360Metrics, 'function');
    console.log('✅ PASS: customer_360_service cung cấp đầy đủ 6 hàm nghiệp vụ CRM.');
  }

  // Test 4: RBAC Guard cho phép super_admin & branch_manager chỉnh sửa Loyalty
  {
    const reqSa = { user: { uid: 'sa1', role: 'super_admin' } };
    const resSa = createMockRes();
    let nextSa = false;
    requireRoles(['super_admin', 'branch_manager'])(reqSa, resSa, () => { nextSa = true; });
    assert.equal(nextSa, true);

    const reqBm = { user: { uid: 'bm1', role: 'branch_manager' } };
    const resBm = createMockRes();
    let nextBm = false;
    requireRoles(['super_admin', 'branch_manager'])(reqBm, resBm, () => { nextBm = true; });
    assert.equal(nextBm, true);
    console.log('✅ PASS: SuperAdmin và BranchManager có quyền điều chỉnh Loyalty và Khóa tài khoản.');
  }

  // Test 5: RBAC Guard chặn Receptionist & Specialist không được can thiệp Loyalty / Moderation
  {
    const reqRec = { user: { uid: 'rec1', role: 'receptionist' } };
    const resRec = createMockRes();
    let nextRec = false;
    requireRoles(['super_admin', 'branch_manager'])(reqRec, resRec, () => { nextRec = true; });
    assert.equal(nextRec, false);
    assert.equal(resRec.statusCode, 403);

    const reqSpec = { user: { uid: 'sp1', role: 'specialist' } };
    const resSpec = createMockRes();
    let nextSpec = false;
    requireRoles(['super_admin', 'branch_manager'])(reqSpec, resSpec, () => { nextSpec = true; });
    assert.equal(nextSpec, false);
    assert.equal(resSpec.statusCode, 403);
    console.log('✅ PASS: Receptionist và Specialist bị chặn quyền điều chỉnh Loyalty và Moderation (403).');
  }

  // Test 6: RBAC Guard cho phép Specialist cập nhật Skin Profile
  {
    const reqSpec = { user: { uid: 'sp1', role: 'specialist' } };
    const resSpec = createMockRes();
    let nextSpec = false;
    requireRoles(['super_admin', 'branch_manager', 'specialist', 'receptionist'])(reqSpec, resSpec, () => { nextSpec = true; });
    assert.equal(nextSpec, true);
    console.log('✅ PASS: Specialist và Receptionist được phép cập nhật hồ sơ da liễu.');
  }

  // Test 7: Kiểm tra truy vấn danh sách & tính toán KPI metrics thực tế
  {
    const result = await customerService.listCustomersWith360Metrics({ limit: 10 });
    assert.equal(result.success, true);
    assert.ok(result.stats, 'Phải có thống kê KPI metrics.');
    assert.ok(typeof result.stats.totalCustomers === 'number');
    assert.ok(typeof result.stats.vipCustomers === 'number');
    assert.ok(typeof result.stats.averageSpend === 'number');
    assert.ok(Array.isArray(result.data));
    console.log(`✅ PASS: listCustomersWith360Metrics thành công (Tìm thấy ${result.stats.totalCustomers} khách, VIP: ${result.stats.vipCustomers}, Chi tiêu TB: ${result.stats.averageSpend.toLocaleString('vi-VN')} đ).`);
  }

  console.log('🎉 TOÀN BỘ KIỂM THỬ CUSTOMER 360 CRM & LOYALTY V2 ĐÃ VƯỢT QUA!');
}

runCustomerCrmTests()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('❌ Kiểm thử thất bại:', err);
    process.exit(1);
  });

