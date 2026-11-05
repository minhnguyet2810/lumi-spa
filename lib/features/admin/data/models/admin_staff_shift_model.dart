import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 1. Mô hình Thông tin Nhân viên (Staff Member)
class StaffMemberItem {
  final String id;
  final String staffId;
  final String name;
  final String role;
  final String phone;
  final String email;
  final String branchId;
  final List<String> categories;
  final bool isActive;
  final String status;
  final String? avatarUrl;
  final DateTime? createdAt;

  const StaffMemberItem({
    required this.id,
    required this.staffId,
    required this.name,
    this.role = 'specialist',
    this.phone = '',
    this.email = '',
    this.branchId = 'central_hub',
    this.categories = const ['facial'],
    this.isActive = true,
    this.status = 'active',
    this.avatarUrl,
    this.createdAt,
  });

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'branch_manager':
        return 'Quản lý Chi nhánh';
      case 'receptionist':
        return 'Lễ tân';
      case 'specialist':
      default:
        return 'Kỹ thuật viên';
    }
  }

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'branch_manager':
        return const Color(0xFFD4AF37); // Gold
      case 'receptionist':
        return const Color(0xFF38BDF8); // Cyan
      case 'specialist':
      default:
        return const Color(0xFF2ECC71); // Emerald
    }
  }

  String get initials {
    if (name.trim().isEmpty) return 'NV';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get displayCategories {
    if (categories.isEmpty) return 'Chăm sóc chung';
    return categories.map((c) {
      switch (c) {
        case 'facial':
          return 'Chăm sóc da mặt';
        case 'body':
          return 'Trị liệu toàn thân';
        case 'relaxation':
          return 'Thư giãn dưỡng sinh';
        case 'beauty':
          return 'Thẩm mỹ & Spa';
        default:
          return c;
      }
    }).join(', ');
  }

  factory StaffMemberItem.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final id = data['staffId']?.toString() ?? data['id']?.toString() ?? docId;
    return StaffMemberItem(
      id: id,
      staffId: id,
      name: data['name']?.toString() ?? 'Nhân viên LUMI',
      role: data['role']?.toString() ?? 'specialist',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      branchId: data['branchId']?.toString() ?? 'central_hub',
      categories: (data['categories'] as List?)?.map((e) => e.toString()).toList() ?? const ['facial'],
      isActive: data['isActive'] != false,
      status: data['status']?.toString() ?? 'active',
      avatarUrl: data['avatarUrl']?.toString() ?? data['photoUrl']?.toString(),
      createdAt: parseDate(data['createdAt']),
    );
  }

  factory StaffMemberItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return StaffMemberItem.fromMap(doc.data() ?? {}, doc.id);
  }
}

/// 2. Mô hình Ca làm việc (Staff Shift)
class StaffShiftItem {
  final String id;
  final String shiftId;
  final String staffId;
  final String staffName;
  final String role;
  final String branchId;
  final String date; // YYYY-MM-DD
  final String shiftType; // morning, afternoon, full
  final String shiftTypeLabel;
  final String timeRange;
  final String status; // scheduled, checked_in, completed, leave_requested, leave_approved
  final String notes;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final String? leaveReason;
  final DateTime? createdAt;

  const StaffShiftItem({
    required this.id,
    required this.shiftId,
    required this.staffId,
    required this.staffName,
    this.role = 'specialist',
    this.branchId = 'central_hub',
    required this.date,
    required this.shiftType,
    this.shiftTypeLabel = 'Ca Sáng',
    this.timeRange = '08:30 - 14:30',
    this.status = 'scheduled',
    this.notes = '',
    this.actualCheckIn,
    this.actualCheckOut,
    this.leaveReason,
    this.createdAt,
  });

  bool get isScheduled => status == 'scheduled';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCompleted => status == 'completed';
  bool get isLeaveRequested => status == 'leave_requested';
  bool get isLeaveApproved => status == 'leave_approved';

  String get statusLabel {
    switch (status) {
      case 'checked_in':
        return 'Đang trực';
      case 'completed':
        return 'Đã hoàn tất';
      case 'leave_requested':
        return 'Xin nghỉ phép';
      case 'leave_approved':
        return 'Đã duyệt nghỉ';
      case 'scheduled':
      default:
        return 'Đã xếp lịch';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'checked_in':
        return const Color(0xFF1ABC9C); // Emerald Teal
      case 'completed':
        return const Color(0xFF94A3B8); // Slate
      case 'leave_requested':
        return const Color(0xFFF59E0B); // Amber
      case 'leave_approved':
        return const Color(0xFFE74C3C); // Red
      case 'scheduled':
      default:
        return const Color(0xFF38BDF8); // Sky Blue
    }
  }

  factory StaffShiftItem.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final id = data['shiftId']?.toString() ?? data['id']?.toString() ?? docId;
    return StaffShiftItem(
      id: id,
      shiftId: id,
      staffId: data['staffId']?.toString() ?? '',
      staffName: data['staffName']?.toString() ?? 'Nhân viên LUMI',
      role: data['role']?.toString() ?? 'specialist',
      branchId: data['branchId']?.toString() ?? 'central_hub',
      date: data['date']?.toString() ?? '',
      shiftType: data['shiftType']?.toString() ?? 'morning',
      shiftTypeLabel: data['shiftTypeLabel']?.toString() ?? 'Ca Sáng',
      timeRange: data['timeRange']?.toString() ?? '08:30 - 14:30',
      status: data['status']?.toString() ?? 'scheduled',
      notes: data['notes']?.toString() ?? '',
      actualCheckIn: parseDate(data['actualCheckIn']),
      actualCheckOut: parseDate(data['actualCheckOut']),
      leaveReason: data['leaveReason']?.toString(),
      createdAt: parseDate(data['createdAt']),
    );
  }

  factory StaffShiftItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return StaffShiftItem.fromMap(doc.data() ?? {}, doc.id);
  }
}

/// 3. Thống kê KPI Quản trị Nhân sự & Ca trực (HRM KPI Stats)
class HrmKpiStats {
  final int totalStaff;
  final int onDutyToday;
  final int completedToday;
  final int onLeaveToday;
  final int pendingLeaveCount;
  final String targetDate;

  const HrmKpiStats({
    this.totalStaff = 0,
    this.onDutyToday = 0,
    this.completedToday = 0,
    this.onLeaveToday = 0,
    this.pendingLeaveCount = 0,
    this.targetDate = '',
  });

  factory HrmKpiStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const HrmKpiStats();

    return HrmKpiStats(
      totalStaff: (data['totalStaff'] as num?)?.toInt() ?? 0,
      onDutyToday: (data['onDutyToday'] as num?)?.toInt() ?? 0,
      completedToday: (data['completedToday'] as num?)?.toInt() ?? 0,
      onLeaveToday: (data['onLeaveToday'] as num?)?.toInt() ?? 0,
      pendingLeaveCount: (data['pendingLeaveCount'] as num?)?.toInt() ?? 0,
      targetDate: data['targetDate']?.toString() ?? '',
    );
  }
}
