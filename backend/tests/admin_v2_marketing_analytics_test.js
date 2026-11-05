const assert = require('node:assert/strict');
const { requireRoles } = require('../middlewares/rbac_guard');
const marketingService = require('../services/marketing_voucher_service');
const analyticsService = require('../services/financial_analytics_service');

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
  console.log('🧪 Bắt đầu kiểm thử Module Marketing Voucher & Financial Analytics...');

  // Test 1: Kiểm tra danh sách Voucher mặc định
  {
    assert.ok(Array.isArray(marketingService.DEFAULT_COUPONS), 'Phải có DEFAULT_COUPONS');
    assert.equal(marketingService.DEFAULT_COUPONS.length, 6, 'DEFAULT_COUPONS phải có 6 voucher mẫu chuẩn.');
    const codes = marketingService.DEFAULT_COUPONS.map(c => c.code);
    assert.ok(codes.includes('LUMISPA10'), 'Phải có LUMISPA10');
    assert.ok(codes.includes('FREESHIP'), 'Phải có FREESHIP');
    assert.ok(codes.includes('LUMIVIP'), 'Phải có LUMIVIP');
    console.log('✅ PASS 1: DEFAULT_COUPONS đầy đủ mã khuyến mãi thương hiệu LUMI.');
  }

  // Test 2: Validation tạo Voucher
  {
    await assert.rejects(
      async () => {
        await marketingService.saveVoucher({ code: 'A', title: 'Test' });
      },
      /ít nhất 3 ký tự/,
      'Mã ngắn hơn 3 ký tự phải báo lỗi.'
    );

    await assert.rejects(
      async () => {
        await marketingService.saveVoucher({ code: 'TESTVOUCHER', title: '' });
      },
      /tiêu đề khuyến mãi/,
      'Không có tiêu đề phải báo lỗi.'
    );

    // Tạo voucher thành công
    const created = await marketingService.saveVoucher({
      code: 'SUMMER2026',
      title: 'Chào đón mùa hè',
      discountType: 'percent',
      percentDiscount: 0.15,
      maxDiscount: 150000,
      minOrder: 500000,
      usageLimit: 200,
    });
    assert.equal(created.success, true);
    assert.equal(created.voucher.code, 'SUMMER2026');
    assert.equal(created.voucher.percentDiscount, 0.15);
    console.log('✅ PASS 2: Validation và khởi tạo voucher hoạt động chính xác.');
  }

  // Test 3: Toggle trạng thái Voucher
  {
    const toggled = await marketingService.toggleVoucherStatus('SUMMER2026', false);
    assert.equal(toggled.success, true);
    assert.equal(toggled.isActive, false);
    console.log('✅ PASS 3: Toggle bật/tắt voucher thành công.');
  }

  // Test 4: Broadcast Marketing Campaign với phân khúc khách hàng
  {
    const campaign = await marketingService.broadcastMarketingCampaign({
      campaignName: 'Flash Sale Cuối Tuần',
      title: 'Dưỡng da căng bóng mùa lễ hội',
      body: 'Tặng ngay voucher giảm 20% khi đặt dịch vụ cuối tuần này!',
      segment: 'vip',
      voucherCode: 'LUMIVIP',
    });
    assert.equal(campaign.success, true);
    assert.ok(campaign.campaign.id.startsWith('camp_'));
    assert.equal(campaign.campaign.segment, 'vip');
    assert.equal(campaign.campaign.voucherCode, 'LUMIVIP');
    assert.ok(campaign.campaign.totalTargetUsers > 0);
    console.log('✅ PASS 4: Gửi chiến dịch marketing phân khúc khách hàng thành công.');
  }

  // Test 5: Analytics resolveDateRange
  {
    const rToday = analyticsService.resolveDateRange('today');
    assert.equal(rToday.start.getDate(), new Date().getDate());

    const r7d = analyticsService.resolveDateRange('last_7_days');
    const diffDays = Math.round((r7d.end.getTime() - r7d.start.getTime()) / 86400000);
    assert.ok(diffDays >= 6 && diffDays <= 7, 'Khoảng last_7_days xấp xỉ 7 ngày.');

    const rMonth = analyticsService.resolveDateRange('this_month');
    assert.equal(rMonth.start.getDate(), 1, 'Tháng này bắt đầu từ mùng 1.');
    console.log('✅ PASS 5: Bộ tính toán khoảng thời gian resolveDateRange hoàn toàn chính xác.');
  }

  // Test 6: Báo cáo Doanh thu & Lợi nhuận gộp Overview
  {
    const report = await analyticsService.getFinancialOverview({ period: 'last_30_days' });
    assert.ok(report.summary, 'Phải có summary');
    assert.ok(report.summary.totalRevenue > 0, 'Tổng doanh thu gộp > 0');
    assert.ok(report.summary.totalCogs > 0, 'Giá vốn hàng bán > 0');
    assert.ok(report.summary.grossProfit > 0, 'Lợi nhuận gộp > 0');
    
    // Kiểm tra công thức tài chính
    const computedGrossProfit = report.summary.totalRevenue - report.summary.totalCogs;
    assert.equal(report.summary.grossProfit, computedGrossProfit, 'Lợi nhuận gộp phải bằng Doanh thu trừ Giá vốn.');

    const sumRatio = Math.round(report.summary.retailRatio + report.summary.serviceRatio);
    assert.equal(sumRatio, 100, 'Tổng tỷ trọng Mỹ phẩm + Dịch vụ Spa phải bằng 100%.');

    assert.ok(Array.isArray(report.dailyTrend), 'Phải có dailyTrend');
    assert.ok(report.dailyTrend.length >= 28, 'Chuỗi ngày 30 ngày phải có ít nhất 28 ngày.');

    assert.ok(Array.isArray(report.topProducts), 'Phải có topProducts');
    assert.ok(report.topProducts.length <= 5, 'Top sản phẩm tối đa 5');
    assert.ok(Array.isArray(report.topServices), 'Phải có topServices');
    assert.ok(report.topServices.length <= 5, 'Top dịch vụ tối đa 5');

    console.log('✅ PASS 6: Báo cáo Doanh thu, Lợi nhuận gộp, COGS và tỷ trọng cơ cấu chính xác tuyệt đối.');
  }

  // Test 7: Phân quyền RBAC cho Marketing và Analytics
  {
    // Marketing broadcast: SuperAdmin, BranchManager, MarketingLead được phép; Specialist không được
    const reqMkt = { user: { uid: 'mkt1', role: 'marketing_lead' } };
    const resMkt = createMockRes();
    let nextMkt = false;
    requireRoles(['super_admin', 'branch_manager', 'marketing_lead'])(reqMkt, resMkt, () => { nextMkt = true; });
    assert.equal(nextMkt, true, 'Marketing lead được duyệt broadcast.');

    const reqSpec = { user: { uid: 'spec1', role: 'specialist' } };
    const resSpec = createMockRes();
    let nextSpec = false;
    requireRoles(['super_admin', 'branch_manager', 'marketing_lead'])(reqSpec, resSpec, () => { nextSpec = true; });
    assert.equal(nextSpec, false, 'Specialist không được duyệt marketing.');
    assert.equal(resSpec.statusCode, 403);

    // Analytics: Accountant & SuperAdmin được phép xem
    const reqAcc = { user: { uid: 'acc1', role: 'accountant' } };
    const resAcc = createMockRes();
    let nextAcc = false;
    requireRoles(['super_admin', 'branch_manager', 'accountant'])(reqAcc, resAcc, () => { nextAcc = true; });
    assert.equal(nextAcc, true, 'Accountant được xem báo cáo doanh thu.');
    console.log('✅ PASS 7: Phân quyền RBAC cho Marketing và Tài chính hoạt động chặt chẽ.');
  }

  console.log('🎉 TOÀN BỘ 7 BÀI TEST KIỂM THỬ BACKEND MARKETING & ANALYTICS ĐỀU VƯỢT QUA!');
}

runTests().catch(err => {
  console.error('❌ Kiểm thử thất bại:', err);
  process.exit(1);
});
