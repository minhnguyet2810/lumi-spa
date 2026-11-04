import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumi_spa/core/data/lumi_account_repository.dart';
import 'package:lumi_spa/core/data/lumi_coupons.dart';
import 'package:lumi_spa/core/data/lumi_order_store.dart';
import 'package:lumi_spa/core/theme/lumi_adaptive.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LumiCoupon System Tests', () {
    test('Verify all 6 vouchers exist and are retrievable', () {
      expect(LumiCouponStore.availableCoupons.length, 6);
      expect(LumiCouponStore.findByCode('lumispa10')?.code, 'LUMISPA10');
      expect(LumiCouponStore.findByCode('LUMISPA20')?.code, 'LUMISPA20');
      expect(LumiCouponStore.findByCode('freeship')?.code, 'FREESHIP');
      expect(LumiCouponStore.findByCode('LUMI50K')?.code, 'LUMI50K');
      expect(LumiCouponStore.findByCode('LUMIVIP')?.code, 'LUMIVIP');
      expect(LumiCouponStore.findByCode('LUMIWELCOME')?.code, 'LUMIWELCOME');
      expect(LumiCouponStore.findByCode('INVALID'), isNull);
    });

    test('LUMISPA10: 10% discount capped at 100.000 đ', () {
      final coupon = LumiCouponStore.findByCode('LUMISPA10')!;
      // 500k -> 10% is 50k
      expect(coupon.calculateDiscount(subtotal: 500000, shippingFee: 30000), 50000);
      // 1.500k -> 10% is 150k but capped at 100k
      expect(coupon.calculateDiscount(subtotal: 1500000, shippingFee: 0), 100000);
    });

    test('LUMISPA20: 20% discount requires min order 500.000 đ, capped at 200.000 đ', () {
      final coupon = LumiCouponStore.findByCode('LUMISPA20')!;
      // 400k < 500k min order -> 0
      expect(coupon.calculateDiscount(subtotal: 400000, shippingFee: 30000), 0);
      // 600k >= 500k -> 20% is 120k
      expect(coupon.calculateDiscount(subtotal: 600000, shippingFee: 0), 120000);
      // 1.200k -> 20% is 240k but capped at 200k
      expect(coupon.calculateDiscount(subtotal: 1200000, shippingFee: 0), 200000);
    });

    test('FREESHIP: returns exact shipping fee', () {
      final coupon = LumiCouponStore.findByCode('FREESHIP')!;
      expect(coupon.calculateDiscount(subtotal: 300000, shippingFee: 30000), 30000);
      expect(coupon.calculateDiscount(subtotal: 600000, shippingFee: 0), 0);
    });

    test('LUMI50K: 50.000 đ discount for order >= 300.000 đ', () {
      final coupon = LumiCouponStore.findByCode('LUMI50K')!;
      expect(coupon.calculateDiscount(subtotal: 250000, shippingFee: 30000), 0);
      expect(coupon.calculateDiscount(subtotal: 350000, shippingFee: 30000), 50000);
    });

    test('LUMIVIP: 100.000 đ discount for order >= 600.000 đ', () {
      final coupon = LumiCouponStore.findByCode('LUMIVIP')!;
      expect(coupon.calculateDiscount(subtotal: 500000, shippingFee: 0), 0);
      expect(coupon.calculateDiscount(subtotal: 700000, shippingFee: 0), 100000);
    });

    test('LUMIWELCOME: 15% discount for new customers capped at 80.000 đ', () {
      final coupon = LumiCouponStore.findByCode('LUMIWELCOME')!;
      expect(coupon.calculateDiscount(subtotal: 200000, shippingFee: 30000), 30000);
      expect(coupon.calculateDiscount(subtotal: 800000, shippingFee: 0), 80000);
    });

    test('Coupon usage limit and exhaustion check', () {
      const activeCoupon = LumiCoupon(
        code: 'TESTLIMIT',
        title: 'Voucher giới hạn',
        description: 'Thử nghiệm',
        badgeText: 'TEST',
        usageLimit: 10,
        usedCount: 8,
      );
      expect(activeCoupon.remainingUses, 2);
      expect(activeCoupon.isExhausted, isFalse);

      const exhaustedCoupon = LumiCoupon(
        code: 'TESTFULL',
        title: 'Voucher hết lượt',
        description: 'Đã dùng hết',
        badgeText: 'TEST',
        usageLimit: 10,
        usedCount: 10,
        fixedDiscount: 50000,
      );
      expect(exhaustedCoupon.remainingUses, 0);
      expect(exhaustedCoupon.isExhausted, isTrue);
      // Exhausted voucher returns 0 discount
      expect(exhaustedCoupon.calculateDiscount(subtotal: 300000, shippingFee: 30000), 0);
    });

    test('LumiMembershipDiscount calculations for Bạc (5%), Vàng (10%), Kim Cương (15%)', () {
      expect(LumiMembershipDiscount.getDiscountPercent('Member'), 0);
      expect(LumiMembershipDiscount.getDiscountPercent('Thành viên'), 0);
      expect(LumiMembershipDiscount.getDiscountPercent('Silver'), 5);
      expect(LumiMembershipDiscount.getDiscountPercent('Bạc'), 5);
      expect(LumiMembershipDiscount.getDiscountPercent('Hạng Bạc'), 5);
      expect(LumiMembershipDiscount.getDiscountPercent('Gold'), 10);
      expect(LumiMembershipDiscount.getDiscountPercent('Vàng'), 10);
      expect(LumiMembershipDiscount.getDiscountPercent('Hạng Vàng'), 10);
      expect(LumiMembershipDiscount.getDiscountPercent('Diamond'), 15);
      expect(LumiMembershipDiscount.getDiscountPercent('Kim Cương'), 15);
      expect(LumiMembershipDiscount.getDiscountPercent('Hạng Kim Cương'), 15);

      // Order 500.000 đ:
      // Silver (5%) -> 25.000 đ
      final subtotal = 500000;
      final silverDiscount = ((subtotal * LumiMembershipDiscount.getDiscountPercent('Silver')) / 100).round();
      expect(silverDiscount, 25000);

      // Gold (10%) -> 50.000 đ
      final goldDiscount = ((subtotal * LumiMembershipDiscount.getDiscountPercent('Gold')) / 100).round();
      expect(goldDiscount, 50000);

      // Diamond (15%) -> 75.000 đ
      final diamondDiscount = ((subtotal * LumiMembershipDiscount.getDiscountPercent('Diamond')) / 100).round();
      expect(diamondDiscount, 75000);
    });
  });

  group('LumiOrderStore Format Tests', () {
    test('formatOrderId standardizes all raw IDs to LUMI - XXXXX', () {
      expect(LumiOrderStore.formatOrderId('xomwY6oMQsiBWiNV7QqJ'), 'LUMI - XOMWY6');
      expect(LumiOrderStore.formatOrderId('cE5nGxQd0sjNcJir4Vg1'), 'LUMI - CE5NGX');
      expect(LumiOrderStore.formatOrderId('LUMI-399817'), 'LUMI - 399817');
      expect(LumiOrderStore.formatOrderId('LUMI - 399817'), 'LUMI - 399817');
      expect(LumiOrderStore.formatOrderId('lumi-abcdef'), 'LUMI - ABCDEF');
      expect(LumiOrderStore.formatOrderId(''), 'LUMI - 000000');
      expect(LumiOrderStore.formatOrderId(null), 'LUMI - 000000');
    });

    test('formatCurrency always formats numbers with dots and trailing đ', () {
      expect(LumiOrderStore.formatCurrency(480000), '480.000 đ');
      expect(LumiOrderStore.formatCurrency(350000), '350.000 đ');
      expect(LumiOrderStore.formatCurrency(490000), '490.000 đ');
      expect(LumiOrderStore.formatCurrency(600000), '600.000 đ');
      expect(LumiOrderStore.formatCurrency(1000000), '1.000.000 đ');
      expect(LumiOrderStore.formatCurrency('480000 đ'), '480.000 đ');
      expect(LumiOrderStore.formatCurrency('350000'), '350.000 đ');
      expect(LumiOrderStore.formatCurrency(0), '0 đ');
      expect(LumiOrderStore.formatCurrency(null), '0 đ');
    });
  });

  group('LumiAdaptive Translations', () {
    test('Language translations for English and Vietnamese', () async {
      await AppPreferences.instance.setLanguage('vi');
      expect(LumiAdaptive.text('Hôm nay'), 'Hôm nay');
      expect(LumiAdaptive.text('Địa chỉ nhận hàng (Shopee)'), 'Địa chỉ nhận hàng (Shopee)');
      expect(LumiAdaptive.text('Mã giảm giá'), 'Mã giảm giá');

      await AppPreferences.instance.setLanguage('en');
      expect(LumiAdaptive.text('Hôm nay'), 'Today');
      expect(LumiAdaptive.text('Ngày mai'), 'Tomorrow');
      expect(LumiAdaptive.text('Địa chỉ nhận hàng (Shopee)'), 'Shipping address');
      expect(LumiAdaptive.text('Địa chỉ nhận hàng'), 'Shipping address');
      expect(LumiAdaptive.text('Sổ địa chỉ giao nhận (chuẩn Shopee)'), 'Address book');
      expect(LumiAdaptive.text('Mã giảm giá'), 'Promo code');
      expect(LumiAdaptive.text('Áp dụng'), 'Apply');
      expect(LumiAdaptive.text('Giảm giá'), 'Discount');
      expect(LumiAdaptive.text('Đơn hàng của tôi'), 'My orders');

      // Reset back to vi
      await AppPreferences.instance.setLanguage('vi');
    });
  });

  group('LumiRewardItem & Notification Order Formatting Tests', () {
    test('LumiNotificationItem fromJson formats raw order ID hash to LUMI - XXXXX', () {
      final notif1 = LumiNotificationItem.fromJson({
        'id': 'notif_1',
        'title': 'Đơn hàng hoàn tất 🎉',
        'message': 'Bạn đã xác nhận nhận hàng thành công cho đơn #tP1Gacy3vsBAM7qBnnR3. Cảm ơn bạn!',
        'type': 'order',
      });
      expect(notif1.message, contains('LUMI - TP1GAC'));
      expect(notif1.message, isNot(contains('tP1Gacy3vsBAM7qBnnR3')));

      final notif2 = LumiNotificationItem.fromJson({
        'id': 'notif_2',
        'title': 'Tích điểm thành công ✨',
        'message': 'Bạn nhận được +410 điểm từ đơn hàng #tP1Gacy3vsBAM7qBnnR3 (Quy đổi 1.000 VNĐ = 1 điểm).',
        'type': 'order',
      });
      expect(notif2.message, contains('LUMI - TP1GAC'));
    });

    test('LumiRewardItem parses reward info and calculates stock correctly', () {
      final reward = LumiRewardItem.fromJson({
        'id': 'voucher_50k',
        'type': 'voucher',
        'title': 'Voucher giảm 50.000 đ',
        'description': 'Áp dụng cho đơn từ 250.000 đ',
        'pointsRequired': 500,
        'badgeText': '-50.000 đ',
        'stock': 35,
        'redeemedCount': 5,
        'remainingStock': 30,
        'isOutOfStock': false,
        'discountValue': 50000,
        'minOrder': 250000,
      });

      expect(reward.id, 'voucher_50k');
      expect(reward.type, 'voucher');
      expect(reward.pointsRequired, 500);
      expect(reward.stock, 35);
      expect(reward.remainingStock, 30);
      expect(reward.isOutOfStock, isFalse);
      expect(reward.discountValue, 50000);
    });

    test('LumiCoupon parses isUserRedeemed correctly', () {
      final coupon = LumiCoupon.fromJson({
        'code': 'LUMI50K-1234',
        'title': 'Voucher đổi từ điểm',
        'description': 'Giảm 50.000 đ',
        'fixedDiscount': 50000,
        'badgeText': 'ĐỔI TỪ ĐIỂM',
        'isUserRedeemed': true,
      });

      expect(coupon.code, 'LUMI50K-1234');
      expect(coupon.isUserRedeemed, isTrue);
    });
  });
}
