import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 1. Chi tiết Hạng Thành Viên & Điểm Tích Lũy
class LoyaltyProfile {
  final int points;
  final num lifetimeSpent;
  final String tier;
  final String tierLabel;
  final String tierColor;
  final String? nextTier;
  final String? nextTierLabel;
  final int pointsToNextTier;
  final num spentToNextTier;
  final double progress;
  final List<String> benefits;
  final int discountPercent;

  const LoyaltyProfile({
    this.points = 0,
    this.lifetimeSpent = 0,
    this.tier = 'bronze',
    this.tierLabel = 'Thành viên Đồng',
    this.tierColor = '#C5A880',
    this.nextTier,
    this.nextTierLabel,
    this.pointsToNextTier = 0,
    this.spentToNextTier = 0,
    this.progress = 0.0,
    this.benefits = const [],
    this.discountPercent = 0,
  });

  Color get parsedColor {
    try {
      final hex = tierColor.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFFC5A880);
    }
  }

  factory LoyaltyProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const LoyaltyProfile();

    return LoyaltyProfile(
      points: (data['points'] as num?)?.toInt() ?? 0,
      lifetimeSpent: (data['lifetimeSpent'] as num?) ?? (data['totalSpent'] as num?) ?? 0,
      tier: (data['tier']?.toString() ?? 'bronze').toLowerCase(),
      tierLabel: data['tierLabel']?.toString() ?? 'Thành viên Đồng',
      tierColor: data['tierColor']?.toString() ?? '#C5A880',
      nextTier: data['nextTier']?.toString(),
      nextTierLabel: data['nextTierLabel']?.toString(),
      pointsToNextTier: (data['pointsToNextTier'] as num?)?.toInt() ?? 0,
      spentToNextTier: (data['spentToNextTier'] as num?) ?? 0,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      benefits: (data['benefits'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 2. Hồ sơ Bệnh án Da Liễu Lâm Sàng & Dị ứng (Skin Profile)
class SkinProfile {
  final String skinType;
  final List<String> concerns;
  final List<String> knownAllergies;
  final List<String> contraindications;
  final String currentRoutine;
  final DateTime? lastConsultationAt;
  final String? consultedBy;

  const SkinProfile({
    this.skinType = 'normal',
    this.concerns = const [],
    this.knownAllergies = const [],
    this.contraindications = const [],
    this.currentRoutine = '',
    this.lastConsultationAt,
    this.consultedBy,
  });

  bool get hasAllergies => knownAllergies.isNotEmpty || contraindications.isNotEmpty;

  String get skinTypeLabel {
    switch (skinType.toLowerCase()) {
      case 'oily':
        return 'Da Dầu';
      case 'dry':
        return 'Da Khô';
      case 'combination':
        return 'Da Hỗn Hợp';
      case 'sensitive':
        return 'Da Nhạy Cảm';
      case 'normal':
      default:
        return 'Da Thường';
    }
  }

  Color get skinTypeColor {
    switch (skinType.toLowerCase()) {
      case 'oily':
        return const Color(0xFF0284C7);
      case 'dry':
        return const Color(0xFFD97706);
      case 'combination':
        return const Color(0xFF7C3AED);
      case 'sensitive':
        return const Color(0xFFDC2626);
      case 'normal':
      default:
        return const Color(0xFF059669);
    }
  }

  factory SkinProfile.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const SkinProfile();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return SkinProfile(
      skinType: (data['skinType']?.toString() ?? 'normal').toLowerCase(),
      concerns: (data['concerns'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      knownAllergies: (data['knownAllergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      contraindications: (data['contraindications'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      currentRoutine: data['currentRoutine']?.toString() ?? '',
      lastConsultationAt: parseDate(data['lastConsultationAt']),
      consultedBy: data['consultedBy']?.toString(),
    );
  }
}

/// 3. Chỉ số Tổng hợp 360 CRM (Metrics)
class CustomerMetrics {
  final int totalOrders;
  final int completedOrders;
  final num totalOrderSpend;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final num totalSpaSpend;
  final num lifetimeSpend;
  final int noShowRate;
  final int treatmentRecordsCount;

  const CustomerMetrics({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalOrderSpend = 0,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.totalSpaSpend = 0,
    this.lifetimeSpend = 0,
    this.noShowRate = 0,
    this.treatmentRecordsCount = 0,
  });

  factory CustomerMetrics.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CustomerMetrics();

    return CustomerMetrics(
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (data['completedOrders'] as num?)?.toInt() ?? 0,
      totalOrderSpend: (data['totalOrderSpend'] as num?) ?? 0,
      totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
      completedBookings: (data['completedBookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (data['cancelledBookings'] as num?)?.toInt() ?? 0,
      totalSpaSpend: (data['totalSpaSpend'] as num?) ?? 0,
      lifetimeSpend: (data['lifetimeSpend'] as num?) ?? 0,
      noShowRate: (data['noShowRate'] as num?)?.toInt() ?? 0,
      treatmentRecordsCount: (data['treatmentRecordsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 4. Bản ghi Bệnh án Liệu trình Lâm sàng (Treatment Record)
class CustomerTreatmentRecord {
  final String id;
  final String appointmentId;
  final String serviceName;
  final String technicianId;
  final String skinConditionBefore;
  final List<String> treatmentStepsApplied;
  final String skinReactionAfter;
  final String homecareRecommendations;
  final DateTime? scheduledAt;
  final DateTime? createdAt;

  const CustomerTreatmentRecord({
    required this.id,
    this.appointmentId = '',
    this.serviceName = 'Liệu trình Spa',
    this.technicianId = '',
    this.skinConditionBefore = '',
    this.treatmentStepsApplied = const [],
    this.skinReactionAfter = '',
    this.homecareRecommendations = '',
    this.scheduledAt,
    this.createdAt,
  });

  factory CustomerTreatmentRecord.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return CustomerTreatmentRecord(
      id: docId,
      appointmentId: data['appointmentId']?.toString() ?? '',
      serviceName: data['serviceName']?.toString() ?? 'Liệu trình Spa',
      technicianId: data['technicianId']?.toString() ?? '',
      skinConditionBefore: data['skinConditionBefore']?.toString() ?? '',
      treatmentStepsApplied: (data['treatmentStepsApplied'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      skinReactionAfter: data['skinReactionAfter']?.toString() ?? '',
      homecareRecommendations: data['homecareRecommendations']?.toString() ?? '',
      scheduledAt: parseDate(data['scheduledAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }
}

/// 5. Đơn hàng tóm tắt (Order Summary)
class CustomerOrderSummary {
  final String id;
  final String orderId;
  final num total;
  final String status;
  final DateTime? createdAt;
  final int itemCount;

  const CustomerOrderSummary({
    required this.id,
    required this.orderId,
    required this.total,
    required this.status,
    this.createdAt,
    this.itemCount = 1,
  });

  factory CustomerOrderSummary.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return CustomerOrderSummary(
      id: data['id']?.toString() ?? data['orderId']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? data['id']?.toString() ?? '',
      total: (data['total'] as num?) ?? 0,
      status: data['status']?.toString() ?? 'pending',
      createdAt: parseDate(data['createdAt']),
      itemCount: (data['items'] as List?)?.length ?? 1,
    );
  }
}

/// 6. Lịch hẹn tóm tắt (Booking Summary)
class CustomerBookingSummary {
  final String id;
  final String serviceName;
  final num price;
  final String status;
  final DateTime? startAt;
  final String technicianId;

  const CustomerBookingSummary({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.status,
    this.startAt,
    this.technicianId = '',
  });

  factory CustomerBookingSummary.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return CustomerBookingSummary(
      id: data['id']?.toString() ?? data['appointmentId']?.toString() ?? '',
      serviceName: data['serviceName']?.toString() ?? 'Dịch vụ Spa',
      price: (data['price'] as num?) ?? (data['billing']?['totalAmount'] as num?) ?? 0,
      status: data['status']?.toString() ?? 'pending',
      startAt: parseDate(data['startAt']),
      technicianId: data['technicianId']?.toString() ?? '',
    );
  }
}

/// 7. Hồ sơ 360 Toàn Diện (Full Customer 360 Profile)
class Customer360Profile {
  final String customerId;
  final String displayName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String role;
  final String status;
  final String? suspendedReason;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  final LoyaltyProfile loyalty;
  final SkinProfile skinProfile;
  final CustomerMetrics metrics;
  final List<CustomerTreatmentRecord> treatmentRecords;
  final List<CustomerOrderSummary> recentOrders;
  final List<CustomerBookingSummary> recentBookings;

  const Customer360Profile({
    required this.customerId,
    required this.displayName,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.role = 'customer',
    this.status = 'active',
    this.suspendedReason,
    this.suspendedAt,
    this.suspendedBy,
    this.address = '',
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.loyalty = const LoyaltyProfile(),
    this.skinProfile = const SkinProfile(),
    this.metrics = const CustomerMetrics(),
    this.treatmentRecords = const [],
    this.recentOrders = const [],
    this.recentBookings = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get hasAllergyWarning => skinProfile.hasAllergies;

  String get initials {
    if (displayName.trim().isEmpty) {
      if (email.isNotEmpty) return email.substring(0, 1).toUpperCase();
      return 'U';
    }
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get displayLifetimeSpent {
    final s = loyalty.lifetimeSpent.toInt().toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted đ';
  }

  factory Customer360Profile.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final trList = (data['treatmentRecords'] as List?)
            ?.map((e) => CustomerTreatmentRecord.fromMap(Map<String, dynamic>.from(e), e['id']?.toString() ?? ''))
            .toList() ??
        const [];

    final ordList = (data['recentOrders'] as List?)
            ?.map((e) => CustomerOrderSummary.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        const [];

    final bkList = (data['recentBookings'] as List?)
            ?.map((e) => CustomerBookingSummary.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        const [];

    return Customer360Profile(
      customerId: data['customerId']?.toString() ?? data['uid']?.toString() ?? data['id']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? 'Khách hàng LUMI',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString(),
      role: data['role']?.toString() ?? 'customer',
      status: data['status']?.toString() ?? 'active',
      suspendedReason: data['suspendedReason']?.toString(),
      suspendedAt: parseDate(data['suspendedAt']),
      suspendedBy: data['suspendedBy']?.toString(),
      address: data['address']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      lastLoginAt: parseDate(data['lastLoginAt']),
      loyalty: LoyaltyProfile.fromMap(data['loyalty'] as Map<String, dynamic>?),
      skinProfile: SkinProfile.fromMap(data['skinProfile'] as Map<String, dynamic>?),
      metrics: CustomerMetrics.fromMap(data['metrics'] as Map<String, dynamic>?),
      treatmentRecords: trList,
      recentOrders: ordList,
      recentBookings: bkList,
    );
  }
}

/// 8. Khách hàng trong danh sách gọn (Customer List Item)
class CustomerListItem {
  final String id;
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String role;
  final String status;
  final String? suspendedReason;
  final String address;
  final int points;
  final num lifetimeSpent;
  final String tier;
  final String tierLabel;
  final String tierColor;
  final String skinType;
  final List<String> knownAllergies;
  final List<String> contraindications;
  final bool hasAllergyWarning;
  final int bookingCount;
  final int orderCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerListItem({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.role = 'customer',
    this.status = 'active',
    this.suspendedReason,
    this.address = '',
    this.points = 0,
    this.lifetimeSpent = 0,
    this.tier = 'bronze',
    this.tierLabel = 'Thành viên Đồng',
    this.tierColor = '#C5A880',
    this.skinType = 'normal',
    this.knownAllergies = const [],
    this.contraindications = const [],
    this.hasAllergyWarning = false,
    this.bookingCount = 0,
    this.orderCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isVip => ['gold', 'diamond'].contains(tier.toLowerCase());

  Color get parsedTierColor {
    try {
      final hex = tierColor.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFFC5A880);
    }
  }

  String get initials {
    if (displayName.trim().isEmpty) {
      if (email.isNotEmpty) return email.substring(0, 1).toUpperCase();
      return 'U';
    }
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get displayLifetimeSpent {
    final s = lifetimeSpent.toInt().toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted đ';
  }

  factory CustomerListItem.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final id = data['id']?.toString() ?? data['uid']?.toString() ?? docId;
    final allergies = (data['knownAllergies'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final contras = (data['contraindications'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return CustomerListItem(
      id: id,
      uid: id,
      displayName: data['displayName']?.toString() ?? data['name']?.toString() ?? 'Khách hàng LUMI',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? data['avatarUrl']?.toString(),
      role: data['role']?.toString() ?? 'customer',
      status: data['status']?.toString() ?? 'active',
      suspendedReason: data['suspendedReason']?.toString(),
      address: data['address']?.toString() ?? data['shippingAddress']?.toString() ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      lifetimeSpent: (data['lifetimeSpent'] as num?) ?? (data['totalSpent'] as num?) ?? 0,
      tier: (data['tier']?.toString() ?? 'bronze').toLowerCase(),
      tierLabel: data['tierLabel']?.toString() ?? 'Thành viên Đồng',
      tierColor: data['tierColor']?.toString() ?? '#C5A880',
      skinType: (data['skinType']?.toString() ?? 'normal').toLowerCase(),
      knownAllergies: allergies,
      contraindications: contras,
      hasAllergyWarning: data['hasAllergyWarning'] == true || allergies.isNotEmpty || contras.isNotEmpty,
      bookingCount: (data['bookingCount'] as num?)?.toInt() ?? 0,
      orderCount: (data['orderCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  factory CustomerListItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CustomerListItem.fromMap(doc.data() ?? {}, doc.id);
  }
}

/// 9. Thống kê KPI CRM Toàn Diện (Customer KPI Stats)
class CustomerKpiStats {
  final int totalCustomers;
  final int activeCustomers;
  final int suspendedCustomers;
  final int vipCustomers;
  final num averageSpend;
  final Map<String, int> tierBreakdown;

  const CustomerKpiStats({
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.suspendedCustomers = 0,
    this.vipCustomers = 0,
    this.averageSpend = 0,
    this.tierBreakdown = const {'bronze': 0, 'silver': 0, 'gold': 0, 'diamond': 0},
  });

  String get displayAverageSpend {
    final s = averageSpend.toInt().toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted đ';
  }

  factory CustomerKpiStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CustomerKpiStats();

    final tb = data['tierBreakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = {
      'bronze': (tb['bronze'] as num?)?.toInt() ?? 0,
      'silver': (tb['silver'] as num?)?.toInt() ?? 0,
      'gold': (tb['gold'] as num?)?.toInt() ?? 0,
      'diamond': (tb['diamond'] as num?)?.toInt() ?? 0,
    };

    return CustomerKpiStats(
      totalCustomers: (data['totalCustomers'] as num?)?.toInt() ?? 0,
      activeCustomers: (data['activeCustomers'] as num?)?.toInt() ?? 0,
      suspendedCustomers: (data['suspendedCustomers'] as num?)?.toInt() ?? 0,
      vipCustomers: (data['vipCustomers'] as num?)?.toInt() ?? 0,
      averageSpend: (data['averageSpend'] as num?) ?? 0,
      tierBreakdown: breakdown,
    );
  }
}

