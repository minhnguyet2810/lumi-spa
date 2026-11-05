import '../network/lumi_api_client.dart';
import 'lumi_order_store.dart';

class LumiAccountProfile {
  const LumiAccountProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
  });

  final String uid;
  final String displayName;
  final String email;
  final String phone;

  factory LumiAccountProfile.fromJson(Map<String, dynamic> json) =>
      LumiAccountProfile(
        uid: json['uid']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );
}

class LumiTierInfo {
  const LumiTierInfo({
    required this.id,
    required this.name,
    required this.label,
    required this.minPoints,
    this.maxPoints,
    required this.minSpent,
    this.maxSpent,
    required this.discountPercent,
    required this.color,
    required this.badge,
    required this.benefits,
  });

  final String id;
  final String name;
  final String label;
  final int minPoints;
  final int? maxPoints;
  final num minSpent;
  final num? maxSpent;
  final int discountPercent;
  final String color;
  final String badge;
  final List<String> benefits;

  factory LumiTierInfo.fromJson(Map<String, dynamic> json) => LumiTierInfo(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    minPoints: json['minPoints'] is num ? (json['minPoints'] as num).toInt() : 0,
    maxPoints: json['maxPoints'] is num ? (json['maxPoints'] as num).toInt() : null,
    minSpent: json['minSpent'] is num ? json['minSpent'] as num : 0,
    maxSpent: json['maxSpent'] is num ? json['maxSpent'] as num : null,
    discountPercent: json['discountPercent'] is num ? (json['discountPercent'] as num).toInt() : 0,
    color: json['color']?.toString() ?? '#C5A880',
    badge: json['badge']?.toString() ?? 'Bronze',
    benefits: (json['benefits'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}

class LumiMembership {
  const LumiMembership({
    required this.tier,
    required this.points,
    required this.totalSpent,
    required this.isDefault,
    this.tierLabel,
    this.nextTier,
    this.nextTierLabel,
    this.pointsToNextTier,
    this.spentToNextTier,
    this.progress,
    this.discountPercent,
    this.conversionRate = 1000,
    this.currentTierBenefits = const [],
    this.allTiers = const [],
  });

  final String? tier;
  final int? points;
  final num? totalSpent;
  final bool? isDefault;
  final String? tierLabel;
  final String? nextTier;
  final String? nextTierLabel;
  final int? pointsToNextTier;
  final num? spentToNextTier;
  final double? progress;
  final int? discountPercent;
  final int conversionRate;
  final List<String> currentTierBenefits;
  final List<LumiTierInfo> allTiers;

  factory LumiMembership.fromJson(Map<String, dynamic> json) {
    final rawTier = json['tier'];
    final rawPoints = json['points'];
    final rawTotalSpent = json['totalSpent'];
    final rawIsDefault = json['isDefault'];
    final points =
        rawPoints is num &&
            rawPoints.isFinite &&
            rawPoints >= 0 &&
            rawPoints == rawPoints.toInt()
        ? rawPoints.toInt()
        : null;
    final totalSpent =
        rawTotalSpent is num && rawTotalSpent.isFinite && rawTotalSpent >= 0
        ? rawTotalSpent
        : null;

    final rawProgress = json['progress'];
    final progress = rawProgress is num && rawProgress.isFinite
        ? rawProgress.toDouble()
        : null;

    final rawPointsToNext = json['pointsToNextTier'];
    final pointsToNextTier = rawPointsToNext is num && rawPointsToNext.isFinite
        ? rawPointsToNext.toInt()
        : null;

    final rawSpentToNext = json['spentToNextTier'];
    final spentToNextTier = rawSpentToNext is num && rawSpentToNext.isFinite
        ? rawSpentToNext
        : null;

    final rawDiscount = json['discountPercent'];
    final discountPercent = rawDiscount is num && rawDiscount.isFinite
        ? rawDiscount.toInt()
        : null;

    final rawConversionRate = json['conversionRate'];
    final conversionRate = rawConversionRate is num && rawConversionRate.isFinite
        ? rawConversionRate.toInt()
        : 1000;

    final rawBenefits = json['currentTierBenefits'] as List<dynamic>?;
    final currentTierBenefits = rawBenefits != null
        ? rawBenefits.map((e) => e.toString()).toList()
        : const <String>[];

    final rawAllTiers = json['allTiers'] as List<dynamic>?;
    final allTiers = rawAllTiers != null
        ? rawAllTiers
            .whereType<Map<String, dynamic>>()
            .map(LumiTierInfo.fromJson)
            .toList()
        : const <LumiTierInfo>[];

    return LumiMembership(
      tier: rawTier is String && rawTier.trim().isNotEmpty
          ? rawTier.trim()
          : null,
      points: points,
      totalSpent: totalSpent,
      isDefault: rawIsDefault is bool ? rawIsDefault : null,
      tierLabel: json['tierLabel']?.toString(),
      nextTier: json['nextTier']?.toString(),
      nextTierLabel: json['nextTierLabel']?.toString(),
      pointsToNextTier: pointsToNextTier,
      spentToNextTier: spentToNextTier,
      progress: progress,
      discountPercent: discountPercent,
      conversionRate: conversionRate,
      currentTierBenefits: currentTierBenefits,
      allTiers: allTiers,
    );
  }
}

class LumiNotificationItem {
  const LumiNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;
  final String type;

  factory LumiNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawMessage =
        json['message']?.toString() ??
        json['body']?.toString() ??
        json['description']?.toString() ??
        '';
    // Chuẩn hoá mã đơn hàng dạng #tP1Gacy3vsBAM7qBnnR3 thành LUMI - XXXXX
    final formattedMessage = rawMessage.replaceAllMapped(
      RegExp(r'#([A-Za-z0-9_-]{6,})'),
      (match) {
        final code = match.group(1) ?? '';
        return LumiOrderStore.formatOrderId(code);
      },
    );

    return LumiNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo từ LUMI',
      message: formattedMessage,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      isRead: json['isRead'] == true,
      type: (json['type'] ?? json['category'] ?? 'system').toString(),
    );
  }
}

class LumiRewardItem {
  final String id;
  final String type; // 'voucher' | 'gift' | 'spa'
  final String title;
  final String description;
  final int pointsRequired;
  final String badgeText;
  final int stock;
  final int redeemedCount;
  final int remainingStock;
  final bool isOutOfStock;
  final String? icon;
  final int? discountValue;
  final double? percentDiscount;
  final int? maxDiscount;
  final bool isFreeShipping;
  final int minOrder;

  const LumiRewardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.badgeText,
    required this.stock,
    this.redeemedCount = 0,
    this.remainingStock = 0,
    this.isOutOfStock = false,
    this.icon,
    this.discountValue,
    this.percentDiscount,
    this.maxDiscount,
    this.isFreeShipping = false,
    this.minOrder = 0,
  });

  factory LumiRewardItem.fromJson(Map<String, dynamic> json) {
    return LumiRewardItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'voucher',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pointsRequired: (json['pointsRequired'] as num?)?.toInt() ?? 0,
      badgeText: json['badgeText']?.toString() ?? 'ƯU ĐÃI',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      redeemedCount: (json['redeemedCount'] as num?)?.toInt() ?? 0,
      remainingStock: (json['remainingStock'] as num?)?.toInt() ?? 0,
      isOutOfStock: json['isOutOfStock'] == true,
      icon: json['icon']?.toString(),
      discountValue: (json['discountValue'] as num?)?.toInt(),
      percentDiscount: (json['percentDiscount'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toInt(),
      isFreeShipping: json['isFreeShipping'] == true,
      minOrder: (json['minOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class LumiRedemptionResult {
  final bool success;
  final String message;
  final String? code;
  final String? rewardType;
  final int? newPoints;

  const LumiRedemptionResult({
    required this.success,
    required this.message,
    this.code,
    this.rewardType,
    this.newPoints,
  });

  factory LumiRedemptionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return LumiRedemptionResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      code: data?['code']?.toString(),
      rewardType: data?['type']?.toString(),
      newPoints: (data?['newPoints'] as num?)?.toInt(),
    );
  }
}

class LumiMyRewardsData {
  final List<Map<String, dynamic>> vouchers;
  final List<Map<String, dynamic>> gifts;

  const LumiMyRewardsData({
    this.vouchers = const [],
    this.gifts = const [],
  });

  factory LumiMyRewardsData.fromJson(Map<String, dynamic> json) {
    final vList = json['vouchers'] as List<dynamic>?;
    final gList = json['gifts'] as List<dynamic>?;
    return LumiMyRewardsData(
      vouchers: vList != null
          ? vList.whereType<Map<String, dynamic>>().toList()
          : const [],
      gifts: gList != null
          ? gList.whereType<Map<String, dynamic>>().toList()
          : const [],
    );
  }
}

/// Dữ liệu địa chỉ giao nhận (chuẩn Shopee: Họ tên, SĐT, địa chỉ chi tiết, Tỉnh/Thành, Quận/Huyện, Phường/Xã, Nhãn, Mặc định)
class LumiAddressItem {
  const LumiAddressItem({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.street,
    this.province = '',
    this.district = '',
    this.ward = '',
    this.fullAddress = '',
    this.label = 'Nhà riêng',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String recipientName;
  final String phone;
  final String street;
  final String province;
  final String district;
  final String ward;
  final String fullAddress;
  final String label; // 'Nhà riêng' | 'Văn phòng' | 'Khác'
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayAddress {
    if (fullAddress.trim().isNotEmpty) return fullAddress.trim();
    final parts = [street, ward, district, province].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory LumiAddressItem.fromJson(Map<String, dynamic> json) => LumiAddressItem(
    id: json['id']?.toString() ?? '',
    recipientName: json['recipientName']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    street: json['street']?.toString() ?? '',
    province: json['province']?.toString() ?? '',
    district: json['district']?.toString() ?? '',
    ward: json['ward']?.toString() ?? '',
    fullAddress: json['fullAddress']?.toString() ?? '',
    label: (json['label']?.toString().isNotEmpty == true) ? json['label'].toString() : 'Nhà riêng',
    isDefault: json['isDefault'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'recipientName': recipientName,
    'phone': phone,
    'street': street,
    'province': province,
    'district': district,
    'ward': ward,
    'fullAddress': displayAddress,
    'label': label,
    'isDefault': isDefault,
  };

  LumiAddressItem copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? street,
    String? province,
    String? district,
    String? ward,
    String? fullAddress,
    String? label,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LumiAddressItem(
    id: id ?? this.id,
    recipientName: recipientName ?? this.recipientName,
    phone: phone ?? this.phone,
    street: street ?? this.street,
    province: province ?? this.province,
    district: district ?? this.district,
    ward: ward ?? this.ward,
    fullAddress: fullAddress ?? this.fullAddress,
    label: label ?? this.label,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

abstract final class LumiAccountRepository {
  static final _api = LumiApiClient.instance;

  static Future<LumiAccountProfile> fetchProfile() async {
    final payload = await _api.get('/api/me');
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const LumiApiException('Dữ liệu hồ sơ không hợp lệ.');
    }
    return LumiAccountProfile.fromJson(data);
  }

  static Future<void> updateProfile({
    required String displayName,
    required String phone,
  }) async {
    await _api.patch(
      '/api/me',
      body: {'displayName': displayName, 'phone': phone},
    );
  }

  static Future<LumiMembership> fetchMembership() async {
    final payload = await _api.get('/api/membership');
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const LumiApiException('Dữ liệu thành viên không hợp lệ.');
    }
    return LumiMembership.fromJson(data);
  }

  static Future<LumiMembership> syncMembership() async {
    final payload = await _api.post('/api/membership/sync');
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      return fetchMembership();
    }
    return LumiMembership.fromJson(data);
  }

  static Future<List<LumiRewardItem>> fetchRewardCatalog() async {
    final payload = await _api.get('/api/membership/rewards');
    final data = payload['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LumiRewardItem.fromJson)
        .toList();
  }

  static Future<LumiMyRewardsData> fetchMyRewards() async {
    final payload = await _api.get('/api/membership/my-rewards');
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return const LumiMyRewardsData();
    return LumiMyRewardsData.fromJson(data);
  }

  static Future<LumiRedemptionResult> redeemReward(String rewardId) async {
    final payload = await _api.post(
      '/api/membership/redeem',
      body: {'rewardId': rewardId},
    );
    return LumiRedemptionResult.fromJson(payload);
  }

  static Future<List<LumiNotificationItem>> fetchNotifications() async {
    final payload = await _api.get('/api/notifications');
    final data = payload['data'];
    if (data is! List) {
      throw const LumiApiException('Dữ liệu thông báo không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(LumiNotificationItem.fromJson)
        .toList();
  }

  static Future<void> markNotificationRead(String id) =>
      _api.patch('/api/notifications/${Uri.encodeComponent(id)}/read');

  static Future<void> markAllNotificationsRead() =>
      _api.patch('/api/notifications/read-all');

  static Future<void> deleteAllNotifications() =>
      _api.delete('/api/notifications');

  static Future<void> deleteNotification(String id) =>
      _api.delete('/api/notifications/${Uri.encodeComponent(id)}');

  // Quản lý địa chỉ giao nhận (Shopee style)
  static Future<List<LumiAddressItem>> fetchAddresses() async {
    final payload = await _api.get('/api/me/addresses');
    final data = payload['data'];
    if (data is! List) {
      throw const LumiApiException('Dữ liệu địa chỉ không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(LumiAddressItem.fromJson)
        .toList();
  }

  static Future<LumiAddressItem> addAddress(LumiAddressItem address) async {
    final payload = await _api.post('/api/me/addresses', body: address.toJson());
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const LumiApiException('Không thể lưu địa chỉ.');
    }
    return LumiAddressItem.fromJson(data);
  }

  static Future<void> updateAddress(LumiAddressItem address) async {
    await _api.put('/api/me/addresses/${Uri.encodeComponent(address.id)}', body: address.toJson());
  }

  static Future<void> deleteAddress(String id) async {
    await _api.delete('/api/me/addresses/${Uri.encodeComponent(id)}');
  }

  static Future<void> setDefaultAddress(String id) async {
    await _api.patch('/api/me/addresses/${Uri.encodeComponent(id)}/default');
  }
}
