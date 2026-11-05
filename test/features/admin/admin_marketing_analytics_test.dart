import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/data/models/admin_voucher_model.dart';
import 'package:lumi_spa/features/admin/data/models/admin_financial_analytics_model.dart';

void main() {
  group('Admin Marketing & Voucher Model Tests', () {
    test('AdminVoucherItem parses percent discount correctly', () {
      final json = {
        'id': 'LUMISPA20',
        'code': 'LUMISPA20',
        'title': 'Tri ân khách hàng 20%',
        'description': 'Giảm 20% tối đa 200.000đ cho đơn hàng mỹ phẩm',
        'minOrder': 800000,
        'percentDiscount': 0.20,
        'maxDiscount': 200000,
        'badgeText': 'GIẢM 20%',
        'usageLimit': 50,
        'usedCount': 18,
        'discountAmountSponsored': 3200000,
        'targetAudience': 'vip',
        'isActive': true,
      };

      final v = AdminVoucherItem.fromJson(json);
      expect(v.code, 'LUMISPA20');
      expect(v.percentDiscount, 0.20);
      expect(v.maxDiscount, 200000);
      expect(v.remainingUses, 32);
      expect(v.isExhausted, isFalse);
      expect(v.usagePercent, closeTo(0.36, 0.01));
      expect(v.discountDisplayText, contains('Giảm 20%'));
      expect(v.minOrderFormatted, contains('800.000 đ'));
      expect(v.audienceDisplayText, 'VIP Gold & Diamond');
      expect(v.isActive, isTrue);
    });

    test('AdminVoucherItem parses free shipping and fixed discount', () {
      final freeShipJson = {
        'code': 'FREESHIP',
        'title': 'Miễn phí giao hàng',
        'isFreeShipping': true,
        'fixedDiscount': 30000,
        'usageLimit': 100,
        'usedCount': 100,
      };

      final freeShip = AdminVoucherItem.fromJson(freeShipJson);
      expect(freeShip.isFreeShipping, isTrue);
      expect(freeShip.discountDisplayText, 'Miễn phí vận chuyển');
      expect(freeShip.remainingUses, 0);
      expect(freeShip.isExhausted, isTrue);

      final fixedJson = {
        'code': 'LUMI50K',
        'title': 'Giảm 50k',
        'fixedDiscount': 50000,
        'usageLimit': 20,
        'usedCount': 5,
      };

      final fixed = AdminVoucherItem.fromJson(fixedJson);
      expect(fixed.fixedDiscount, 50000);
      expect(fixed.discountDisplayText, contains('50.000 đ'));
    });

    test('AdminMarketingKpi parses json accurately', () {
      final json = {
        'totalVouchers': 6,
        'activeVouchers': 5,
        'totalUses': 349,
        'totalDiscountSponsored': 21860000,
        'totalCampaigns': 8,
        'totalPushSent': 480,
      };

      final kpi = AdminMarketingKpi.fromJson(json);
      expect(kpi.totalVouchers, 6);
      expect(kpi.activeVouchers, 5);
      expect(kpi.totalUses, 349);
      expect(kpi.totalDiscountSponsored, 21860000);
      expect(kpi.totalCampaigns, 8);
      expect(kpi.totalPushSent, 480);
    });
  });

  group('Admin Financial Analytics Model Tests', () {
    test('FinancialSummary computes formulas and formats currency', () {
      final json = {
        'totalRevenue': 125400000,
        'retailRevenue': 43890000,
        'serviceRevenue': 81510000,
        'totalCogs': 37494600,
        'retailCogs': 22822800,
        'serviceCogs': 14671800,
        'grossProfit': 87905400,
        'grossMarginPercent': 70.1,
        'retailRatio': 35.0,
        'serviceRatio': 65.0,
        'ordersCount': 84,
        'bookingsCount': 132,
        'averageOrderValue': 522500,
        'averageBookingValue': 617500,
      };

      final s = FinancialSummary.fromJson(json);
      expect(s.totalRevenue, 125400000);
      expect(s.retailRevenue, 43890000);
      expect(s.serviceRevenue, 81510000);
      expect(s.totalRevenue, s.retailRevenue + s.serviceRevenue);
      expect(s.grossProfit, s.totalRevenue - s.totalCogs);
      expect(s.grossMarginPercent, 70.1);
      expect(s.retailRatio + s.serviceRatio, 100.0);
      expect(s.totalRevenueFormatted, contains('125.400.000 đ'));
      expect(s.grossProfitFormatted, contains('87.905.400 đ'));
    });

    test('DailyFinancialTrend formats short date correctly', () {
      final trend = DailyFinancialTrend.fromJson({
        'date': '2026-11-20',
        'retailRevenue': 1500000,
        'serviceRevenue': 3200000,
        'totalRevenue': 4700000,
        'totalCogs': 1356000,
        'grossProfit': 3344000,
        'ordersCount': 4,
        'bookingsCount': 6,
      });

      expect(trend.date, '2026-11-20');
      expect(trend.shortDate, '20/11');
      expect(trend.totalRevenue, 4700000);
      expect(trend.grossProfit, 3344000);
    });

    test('TopPerformerItem and FinancialReportData parse nested lists', () {
      final json = {
        'summary': {
          'totalRevenue': 50000000,
          'grossProfit': 35000000,
        },
        'dailyTrend': [
          {'date': '2026-11-01', 'totalRevenue': 5000000},
          {'date': '2026-11-02', 'totalRevenue': 6000000},
        ],
        'topProducts': [
          {'name': 'Serum B5', 'revenue': 12000000, 'unitsSold': 24, 'cogs': 6000000},
        ],
        'topServices': [
          {'name': 'Căng bóng DNA', 'revenue': 25000000, 'sessionsCount': 30, 'cogs': 4500000},
        ],
      };

      final report = FinancialReportData.fromJson(json);
      expect(report.summary.totalRevenue, 50000000);
      expect(report.dailyTrend.length, 2);
      expect(report.topProducts.length, 1);
      expect(report.topServices.length, 1);

      final p = report.topProducts.first;
      expect(p.name, 'Serum B5');
      expect(p.grossProfit, 6000000);
      expect(p.marginPercent, 50.0);

      final s = report.topServices.first;
      expect(s.name, 'Căng bóng DNA');
      expect(s.grossProfit, 20500000);
      expect(s.marginPercent, closeTo(82.0, 0.1));
    });
  });
}
