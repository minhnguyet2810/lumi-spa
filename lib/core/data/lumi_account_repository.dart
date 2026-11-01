import '../network/lumi_api_client.dart';

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

class LumiMembership {
  const LumiMembership({
    required this.tier,
    required this.points,
    required this.totalSpent,
    required this.isDefault,
  });

  final String? tier;
  final int? points;
  final num? totalSpent;
  final bool? isDefault;

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

    return LumiMembership(
      tier: rawTier is String && rawTier.trim().isNotEmpty
          ? rawTier.trim()
          : null,
      points: points,
      totalSpent: totalSpent,
      isDefault: rawIsDefault is bool ? rawIsDefault : null,
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

  factory LumiNotificationItem.fromJson(Map<String, dynamic> json) =>
      LumiNotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Thông báo từ LUMI',
        message:
            json['message']?.toString() ??
            json['body']?.toString() ??
            json['description']?.toString() ??
            '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        isRead: json['isRead'] == true,
        type: (json['type'] ?? json['category'] ?? 'system').toString(),
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
}
