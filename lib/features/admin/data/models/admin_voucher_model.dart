import 'package:intl/intl.dart';

class AdminVoucherItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final int minOrder;
  final double? percentDiscount;
  final int? fixedDiscount;
  final int? maxDiscount;
  final bool isFreeShipping;
  final String badgeText;
  final int usageLimit;
  final int usedCount;
  final int discountAmountSponsored;
  final String? validFrom;
  final String? validTo;
  final bool isActive;
  final String targetAudience; // 'all', 'vip', 'new_customers', 'inactive_60d'
  final String? createdAt;
  final String? updatedAt;

  const AdminVoucherItem({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.minOrder = 0,
    this.percentDiscount,
    this.fixedDiscount,
    this.maxDiscount,
    this.isFreeShipping = false,
    this.badgeText = 'ƯU ĐÃI',
    this.usageLimit = 100,
    this.usedCount = 0,
    this.discountAmountSponsored = 0,
    this.validFrom,
    this.validTo,
    this.isActive = true,
    this.targetAudience = 'all',
    this.createdAt,
    this.updatedAt,
  });

  int get remainingUses => usageLimit > usedCount ? usageLimit - usedCount : 0;
  bool get isExhausted => remainingUses <= 0;
  
  bool get isExpired {
    if (validTo == null || validTo!.isEmpty) return false;
    try {
      final toDate = DateTime.parse(validTo!);
      return DateTime.now().isAfter(toDate);
    } catch (_) {
      return false;
    }
  }

  double get usagePercent {
    if (usageLimit <= 0) return 0.0;
    final pct = usedCount / usageLimit;
    return pct > 1.0 ? 1.0 : pct;
  }

  String get discountDisplayText {
    if (isFreeShipping) {
      return 'Miễn phí vận chuyển';
    }
    if (percentDiscount != null && percentDiscount! > 0) {
      final pct = (percentDiscount! * 100).toInt();
      if (maxDiscount != null && maxDiscount! > 0) {
        return 'Giảm $pct% (Tối đa ${_formatCurrency(maxDiscount!)})';
      }
      return 'Giảm $pct%';
    }
    if (fixedDiscount != null && fixedDiscount! > 0) {
      return 'Giảm ${_formatCurrency(fixedDiscount!)}';
    }
    return badgeText;
  }

  String get minOrderFormatted {
    if (minOrder <= 0) return 'Đơn từ 0đ';
    return 'Đơn từ ${_formatCurrency(minOrder)}';
  }

  String get audienceDisplayText {
    switch (targetAudience) {
      case 'vip':
        return 'VIP Gold & Diamond';
      case 'new_customers':
        return 'Khách hàng mới';
      case 'inactive_60d':
        return 'Khách không hoạt động > 60 ngày';
      default:
        return 'Tất cả khách hàng';
    }
  }

  String get validRangeFormatted {
    final f = DateFormat('dd/MM/yyyy');
    String from = '';
    String to = '';
    try {
      if (validFrom != null && validFrom!.isNotEmpty) {
        from = f.format(DateTime.parse(validFrom!));
      }
      if (validTo != null && validTo!.isNotEmpty) {
        to = f.format(DateTime.parse(validTo!));
      }
    } catch (_) {}

    if (from.isNotEmpty && to.isNotEmpty) return '$from - $to';
    if (to.isNotEmpty) return 'HSD: $to';
    return 'Không thời hạn';
  }

  static String _formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  factory AdminVoucherItem.fromJson(Map<String, dynamic> json, [String? docId]) {
    final code = (json['code'] ?? docId ?? '').toString().trim().toUpperCase();
    return AdminVoucherItem(
      id: docId ?? json['id']?.toString() ?? code,
      code: code,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      minOrder: (json['minOrder'] as num?)?.toInt() ?? 0,
      percentDiscount: (json['percentDiscount'] as num?)?.toDouble(),
      fixedDiscount: (json['fixedDiscount'] as num?)?.toInt(),
      maxDiscount: (json['maxDiscount'] as num?)?.toInt(),
      isFreeShipping: json['isFreeShipping'] == true,
      badgeText: json['badgeText']?.toString() ?? 'ƯU ĐÃI',
      usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 100,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      discountAmountSponsored: (json['discountAmountSponsored'] as num?)?.toInt() ?? 0,
      validFrom: json['validFrom']?.toString(),
      validTo: json['validTo']?.toString(),
      isActive: json['isActive'] != false,
      targetAudience: json['targetAudience']?.toString() ?? 'all',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'minOrder': minOrder,
      'percentDiscount': percentDiscount,
      'fixedDiscount': fixedDiscount,
      'maxDiscount': maxDiscount,
      'isFreeShipping': isFreeShipping,
      'badgeText': badgeText,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'discountAmountSponsored': discountAmountSponsored,
      'validFrom': validFrom,
      'validTo': validTo,
      'isActive': isActive,
      'targetAudience': targetAudience,
    };
  }

  AdminVoucherItem copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    int? minOrder,
    double? percentDiscount,
    int? fixedDiscount,
    int? maxDiscount,
    bool? isFreeShipping,
    String? badgeText,
    int? usageLimit,
    int? usedCount,
    int? discountAmountSponsored,
    String? validFrom,
    String? validTo,
    bool? isActive,
    String? targetAudience,
  }) {
    return AdminVoucherItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      minOrder: minOrder ?? this.minOrder,
      percentDiscount: percentDiscount ?? this.percentDiscount,
      fixedDiscount: fixedDiscount ?? this.fixedDiscount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      isFreeShipping: isFreeShipping ?? this.isFreeShipping,
      badgeText: badgeText ?? this.badgeText,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      discountAmountSponsored: discountAmountSponsored ?? this.discountAmountSponsored,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      isActive: isActive ?? this.isActive,
      targetAudience: targetAudience ?? this.targetAudience,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AdminMarketingKpi {
  final int totalVouchers;
  final int activeVouchers;
  final int totalUses;
  final int totalDiscountSponsored;
  final int totalCampaigns;
  final int totalPushSent;

  const AdminMarketingKpi({
    this.totalVouchers = 0,
    this.activeVouchers = 0,
    this.totalUses = 0,
    this.totalDiscountSponsored = 0,
    this.totalCampaigns = 0,
    this.totalPushSent = 0,
  });

  factory AdminMarketingKpi.fromJson(Map<String, dynamic> json) {
    return AdminMarketingKpi(
      totalVouchers: (json['totalVouchers'] as num?)?.toInt() ?? 0,
      activeVouchers: (json['activeVouchers'] as num?)?.toInt() ?? 0,
      totalUses: (json['totalUses'] as num?)?.toInt() ?? 0,
      totalDiscountSponsored: (json['totalDiscountSponsored'] as num?)?.toInt() ?? 0,
      totalCampaigns: (json['totalCampaigns'] as num?)?.toInt() ?? 0,
      totalPushSent: (json['totalPushSent'] as num?)?.toInt() ?? 0,
    );
  }
}
