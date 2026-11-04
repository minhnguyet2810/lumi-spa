class LumiCoupon {
  final String code;
  final String title;
  final String description;
  final int minOrder;
  final int? fixedDiscount;
  final double? percentDiscount;
  final int? maxDiscount;
  final bool isFreeShipping;
  final String badgeText;

  const LumiCoupon({
    required this.code,
    required this.title,
    required this.description,
    this.minOrder = 0,
    this.fixedDiscount,
    this.percentDiscount,
    this.maxDiscount,
    this.isFreeShipping = false,
    required this.badgeText,
  });

  /// Tính số tiền giảm giá thực tế theo giá trị đơn hàng và phí ship
  int calculateDiscount({required int subtotal, required int shippingFee}) {
    if (subtotal < minOrder) return 0;
    if (isFreeShipping) {
      return shippingFee;
    }
    if (fixedDiscount != null) {
      return fixedDiscount! > subtotal ? subtotal : fixedDiscount!;
    }
    if (percentDiscount != null) {
      final discount = (subtotal * percentDiscount!).round();
      if (maxDiscount != null && discount > maxDiscount!) {
        return maxDiscount!;
      }
      return discount;
    }
    return 0;
  }
}

abstract final class LumiCouponStore {
  /// Danh sách các mã giảm giá có thể quy đổi / áp dụng trong app LUMI
  static const List<LumiCoupon> availableCoupons = [
    LumiCoupon(
      code: 'LUMISPA10',
      title: 'Giảm 10% đơn hàng',
      description: 'Áp dụng cho mọi đơn mua mỹ phẩm, giảm tối đa 100.000 đ.',
      minOrder: 0,
      percentDiscount: 0.10,
      maxDiscount: 100000,
      badgeText: 'GIẢM 10%',
    ),
    LumiCoupon(
      code: 'LUMISPA20',
      title: 'Giảm 20% cho đơn từ 500k',
      description: 'Áp dụng cho đơn hàng từ 500.000 đ, giảm tối đa 200.000 đ.',
      minOrder: 500000,
      percentDiscount: 0.20,
      maxDiscount: 200000,
      badgeText: 'GIẢM 20%',
    ),
    LumiCoupon(
      code: 'FREESHIP',
      title: 'Miễn phí giao hàng toàn quốc',
      description: 'Miễn phí vận chuyển 30.000 đ cho toàn bộ đơn hàng.',
      minOrder: 0,
      isFreeShipping: true,
      badgeText: 'FREESHIP',
    ),
    LumiCoupon(
      code: 'LUMI50K',
      title: 'Giảm trực tiếp 50.000 đ',
      description: 'Áp dụng cho đơn hàng từ 300.000 đ trở lên.',
      minOrder: 300000,
      fixedDiscount: 50000,
      badgeText: '-50.000 đ',
    ),
    LumiCoupon(
      code: 'LUMIVIP',
      title: 'Đặc quyền VIP giảm 100.000 đ',
      description: 'Ưu đãi tri ân khách hàng thân thiết cho đơn từ 600.000 đ.',
      minOrder: 600000,
      fixedDiscount: 100000,
      badgeText: '-100.000 đ',
    ),
    LumiCoupon(
      code: 'LUMIWELCOME',
      title: 'Chào đón bạn mới giảm 15%',
      description: 'Dành tặng khách hàng mới của LUMI SPA, giảm tối đa 80.000 đ.',
      minOrder: 0,
      percentDiscount: 0.15,
      maxDiscount: 80000,
      badgeText: 'BẠN MỚI',
    ),
  ];

  /// Tìm mã giảm giá theo chuỗi mã nhập vào
  static LumiCoupon? findCoupon(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return availableCoupons.firstWhere((c) => c.code == clean);
    } catch (_) {
      return null;
    }
  }

  static LumiCoupon? findByCode(String code) => findCoupon(code);
}
