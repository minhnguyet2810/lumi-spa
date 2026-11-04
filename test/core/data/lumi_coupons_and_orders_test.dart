import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
