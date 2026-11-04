import '../network/lumi_api_client.dart';

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
  final int usageLimit;
  final int usedCount;
  final bool isUserRedeemed;

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
    this.usageLimit = 50,
    this.usedCount = 0,
    this.isUserRedeemed = false,
  });

  int get remainingUses => usageLimit > usedCount ? usageLimit - usedCount : 0;
  bool get isExhausted => remainingUses <= 0;

  /// Tính số tiền giảm giá thực tế theo giá trị đơn hàng và phí ship
  int calculateDiscount({required int subtotal, required int shippingFee}) {
    if (isExhausted || subtotal < minOrder) return 0;
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

  factory LumiCoupon.fromJson(Map<String, dynamic> json) {
    return LumiCoupon(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      minOrder: (json['minOrder'] as num?)?.toInt() ?? 0,
      fixedDiscount: (json['fixedDiscount'] as num?)?.toInt(),
      percentDiscount: (json['percentDiscount'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toInt(),
      isFreeShipping: json['isFreeShipping'] == true,
      badgeText: json['badgeText']?.toString() ?? 'ƯU ĐÃI',
      usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 50,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      isUserRedeemed: json['isUserRedeemed'] == true,
    );
  }

  /// Tiêu đề ngắn gọn, chuẩn phong cách Shopee (VD: "Miễn phí vận chuyển", "Giảm 10% Giảm tối đa 100k", "Giảm 50k Giảm trực tiếp")
  String get shopeeTitle {
    if (isFreeShipping) {
      return 'Miễn phí vận chuyển';
    }
    if (percentDiscount != null) {
      final pct = (percentDiscount! * 100).toInt();
      if (maxDiscount != null && maxDiscount! > 0) {
        return 'Giảm $pct% Giảm tối đa ${_shortAmount(maxDiscount!)}';
      }
      return 'Giảm $pct% đơn hàng';
    }
    if (fixedDiscount != null && fixedDiscount! > 0) {
      return 'Giảm ${_shortAmount(fixedDiscount!)} Giảm trực tiếp';
    }
    return title;
  }

  static String _shortAmount(int amount) {
    if (amount <= 0) return '0đ';
    if (amount >= 1000000) {
      final tr = amount / 1000000.0;
      return tr == tr.roundToDouble() ? '${tr.toInt()}tr' : '${tr.toStringAsFixed(1)}tr';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()}k';
    }
    return '$amountđ';
  }
}

/// Helper tính mức chiết khấu theo Hạng thành viên LUMI
abstract final class LumiMembershipDiscount {
  static int getDiscountPercent(String? tier) {
    if (tier == null) return 0;
    final t = tier.toLowerCase().trim();
    if (t == 'silver' || t == 'bạc' || t == 'hạng bạc') return 5;
    if (t == 'gold' || t == 'vàng' || t == 'hạng vàng') return 10;
    if (t == 'diamond' || t == 'kim cương' || t == 'hạng kim cương') return 15;
    return 0;
  }
}

abstract final class LumiCouponStore {
  /// Danh sách các mã giảm giá có thể quy đổi / áp dụng trong app LUMI (top 3 mã nổi bật ưu tiên)
  static const List<LumiCoupon> availableCoupons = [
    LumiCoupon(
      code: 'FREESHIP',
      title: 'Miễn phí giao hàng toàn quốc',
      description: 'Miễn phí vận chuyển 30.000 đ cho toàn bộ đơn hàng.',
      minOrder: 0,
      isFreeShipping: true,
      badgeText: 'FREESHIP',
      usageLimit: 100,
      usedCount: 0,
    ),
    LumiCoupon(
      code: 'LUMISPA10',
      title: 'Giảm 10% đơn hàng',
      description: 'Áp dụng cho mọi đơn mua mỹ phẩm, giảm tối đa 100.000 đ.',
      minOrder: 0,
      percentDiscount: 0.10,
      maxDiscount: 100000,
      badgeText: 'GIẢM 10%',
      usageLimit: 50,
      usedCount: 0,
    ),
    LumiCoupon(
      code: 'LUMI50K',
      title: 'Giảm trực tiếp 50.000 đ',
      description: 'Áp dụng cho đơn hàng từ 300.000 đ trở lên.',
      minOrder: 300000,
      fixedDiscount: 50000,
      badgeText: '-50.000 đ',
      usageLimit: 25,
      usedCount: 0,
    ),
    LumiCoupon(
      code: 'LUMISPA20',
      title: 'Giảm 20% cho đơn từ 500k',
      description: 'Áp dụng cho đơn hàng từ 500.000 đ, giảm tối đa 200.000 đ.',
      minOrder: 500000,
      percentDiscount: 0.20,
      maxDiscount: 200000,
      badgeText: 'GIẢM 20%',
      usageLimit: 30,
      usedCount: 0,
    ),
    LumiCoupon(
      code: 'LUMIVIP',
      title: 'Đặc quyền VIP giảm 100.000 đ',
      description: 'Ưu đãi tri ân khách hàng thân thiết cho đơn từ 600.000 đ.',
      minOrder: 600000,
      fixedDiscount: 100000,
      badgeText: '-100.000 đ',
      usageLimit: 10,
      usedCount: 0,
    ),
    LumiCoupon(
      code: 'LUMIWELCOME',
      title: 'Chào đón bạn mới giảm 15%',
      description: 'Dành tặng khách hàng mới của LUMI SPA, giảm tối đa 80.000 đ.',
      minOrder: 0,
      percentDiscount: 0.15,
      maxDiscount: 80000,
      badgeText: 'BẠN MỚI',
      usageLimit: 50,
      usedCount: 0,
    ),
  ];

  /// Giới hạn tối đa 3 mã ưu đãi hiển thị trong voucher sheet
  static List<LumiCoupon> get featuredCoupons => availableCoupons.take(3).toList();

  static List<LumiCoupon> _cachedCoupons = availableCoupons;
  static List<LumiCoupon> get currentCoupons => _cachedCoupons;

  /// Lấy danh sách mã giảm giá từ backend để cập nhật số lượt dùng thời gian thực
  static Future<List<LumiCoupon>> fetchAvailableCoupons() async {
    try {
      final res = await LumiApiClient.instance.get('/api/orders/coupons');
      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((c) => LumiCoupon.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
        if (list.isNotEmpty) {
          _cachedCoupons = list;
          return list;
        }
      }
    } catch (_) {}
    return availableCoupons;
  }

  /// Tìm mã giảm giá theo chuỗi mã nhập vào
  static LumiCoupon? findCoupon(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return _cachedCoupons.firstWhere((c) => c.code == clean);
    } catch (_) {
      try {
        return availableCoupons.firstWhere((c) => c.code == clean);
      } catch (_) {
        return null;
      }
    }
  }

  static LumiCoupon? findByCode(String code) => findCoupon(code);
}
