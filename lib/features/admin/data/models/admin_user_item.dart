import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserItem {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int bookingCount;
  final int orderCount;
  final num totalSpent;

  const AdminUserItem({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
    this.bookingCount = 0,
    this.orderCount = 0,
    this.totalSpent = 0,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

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

  String get displayTotalSpent {
    final s = totalSpent.toInt().toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted đ';
  }

  String get formattedCreatedAt {
    if (createdAt == null) return 'Chưa cập nhật';
    final d = createdAt!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get roleLabel => isAdmin ? 'Quản trị viên' : 'Khách hàng';

  Color get roleColor =>
      isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);

  Color get roleBgColor =>
      isAdmin ? const Color(0xFFF5F3FF) : const Color(0xFFEFF6FF);

  factory AdminUserItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AdminUserItem.fromMap(data, doc.id);
  }

  factory AdminUserItem.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final id = data['uid']?.toString() ?? data['id']?.toString() ?? docId;
    final displayName =
        data['displayName']?.toString() ??
        data['name']?.toString() ??
        'Khách hàng';
    final email = data['email']?.toString() ?? '';
    final phone =
        data['phone']?.toString() ?? data['phoneNumber']?.toString() ?? '';
    final photoUrl =
        data['photoUrl']?.toString() ?? data['avatarUrl']?.toString();
    final role = data['role']?.toString() ?? 'user';

    return AdminUserItem(
      id: id,
      displayName: displayName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      role: role,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      bookingCount: (data['bookingCount'] as num?)?.toInt() ?? 0,
      orderCount: (data['orderCount'] as num?)?.toInt() ?? 0,
      totalSpent: (data['totalSpent'] as num?) ?? 0,
    );
  }

  AdminUserItem copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? bookingCount,
    int? orderCount,
    num? totalSpent,
  }) {
    return AdminUserItem(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingCount: bookingCount ?? this.bookingCount,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}
