import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_config.dart';
import 'models/admin_staff_shift_model.dart';

class AdminHrmRepository {
  AdminHrmRepository._();
  static final AdminHrmRepository instance = AdminHrmRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập quản trị.');
    }
    final result = await user.getIdTokenResult();
    final token = result.token;
    if (token == null) {
      throw StateError('Phiên làm việc hết hạn hoặc không hợp lệ.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  CollectionReference<Map<String, dynamic>> get _shiftsCol =>
      _firestore.collection('staff_shifts');

  CollectionReference<Map<String, dynamic>> get _staffCol =>
      _firestore.collection('staff');

  /// 1. Lắng nghe toàn bộ ca trực thời gian thực từ Firestore
  Stream<List<StaffShiftItem>> streamStaffShifts() {
    return _shiftsCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map(StaffShiftItem.fromFirestore).toList();
      list.sort((a, b) {
        if (a.date != b.date) return a.date.compareTo(b.date);
        return a.shiftType.compareTo(b.shiftType);
      });
      return list;
    });
  }

  /// 2. Lấy thống kê KPI HRM từ Backend API
  Future<HrmKpiStats> fetchHrmMetrics({String? branchId, String? date}) async {
    try {
      final queryParams = <String, String>{};
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        queryParams['branchId'] = branchId;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/metrics')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded['success'] == true && decoded['data'] is Map) {
          return HrmKpiStats.fromMap(Map<String, dynamic>.from(decoded['data']));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminHrmRepository] fetchHrmMetrics error: $e');
    }

    // Fallback: Tính toán trực tiếp
    try {
      final targetDate = date ?? DateTime.now().toIso8601String().substring(0, 10);
      final staffSnap = await _staffCol.get();
      final shiftSnap = await _shiftsCol.where('date', isEqualTo: targetDate).get();
      final pendingLeaves = await _shiftsCol.where('status', isEqualTo: 'leave_requested').get();

      final todayShifts = shiftSnap.docs.map((d) => d.data()).toList();
      return HrmKpiStats(
        totalStaff: staffSnap.size,
        onDutyToday: todayShifts.where((s) => ['scheduled', 'checked_in'].contains(s['status'])).length,
        completedToday: todayShifts.where((s) => s['status'] == 'completed').length,
        onLeaveToday: todayShifts.where((s) => ['leave_approved', 'leave_requested'].contains(s['status'])).length,
        pendingLeaveCount: pendingLeaves.size,
        targetDate: targetDate,
      );
    } catch (_) {
      return const HrmKpiStats();
    }
  }

  /// 3. Lấy danh sách nhân viên & chuyên môn
  Future<List<StaffMemberItem>> fetchStaffMembers({String? branchId, String? role, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        queryParams['branchId'] = branchId;
      }
      if (role != null && role.isNotEmpty && role != 'all') {
        queryParams['role'] = role;
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/members')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded['success'] == true && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => StaffMemberItem.fromMap(Map<String, dynamic>.from(e), e['id']?.toString() ?? ''))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminHrmRepository] fetchStaffMembers error: $e');
    }

    // Fallback: Firestore
    try {
      final snap = await _staffCol.get();
      return snap.docs.map(StaffMemberItem.fromFirestore).toList();
    } catch (_) {
      return <StaffMemberItem>[];
    }
  }

  /// 4. Thêm hoặc cập nhật thông tin nhân sự
  Future<StaffMemberItem> saveStaffMember({
    String? staffId,
    required String name,
    required String role,
    String phone = '',
    String email = '',
    String branchId = 'central_hub',
    List<String> categories = const ['facial'],
    bool isActive = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/members');
    final headers = await _authHeaders();
    final body = jsonEncode({
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
      'branchId': branchId,
      'categories': categories,
      'isActive': isActive,
    });

    final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && decoded['success'] == true) {
      return StaffMemberItem.fromMap(Map<String, dynamic>.from(decoded['data']), decoded['data']?['id']?.toString() ?? '');
    } else {
      throw StateError(decoded['message']?.toString() ?? 'Không thể lưu nhân viên.');
    }
  }

  /// 5. Lấy bảng phân ca theo khoảng ngày (Roster)
  Future<List<StaffShiftItem>> fetchRoster({
    String? branchId,
    String? startDate,
    String? endDate,
    String? staffId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        queryParams['branchId'] = branchId;
      }
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (staffId != null && staffId.isNotEmpty && staffId != 'all') {
        queryParams['staffId'] = staffId;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/roster')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final headers = await _authHeaders();
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded['success'] == true && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => StaffShiftItem.fromMap(Map<String, dynamic>.from(e), e['id']?.toString() ?? ''))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [AdminHrmRepository] fetchRoster error: $e');
    }

    // Fallback: Firestore
    try {
      final snap = await _shiftsCol.get();
      var list = snap.docs.map(StaffShiftItem.fromFirestore).toList();
      if (startDate != null) list = list.where((s) => s.date.compareTo(startDate) >= 0).toList();
      if (endDate != null) list = list.where((s) => s.date.compareTo(endDate) <= 0).toList();
      return list;
    } catch (_) {
      return <StaffShiftItem>[];
    }
  }

  /// 6. Xếp ca làm việc mới
  Future<StaffShiftItem> createShift({
    required String staffId,
    String? staffName,
    required String role,
    String branchId = 'central_hub',
    required String date,
    required String shiftType,
    String notes = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts');
    final headers = await _authHeaders();
    final body = jsonEncode({
      'staffId': staffId,
      'staffName': ?staffName,
      'role': role,
      'branchId': branchId,
      'date': date,
      'shiftType': shiftType,
      'notes': notes,
    });

    final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && decoded['success'] == true) {
      return StaffShiftItem.fromMap(Map<String, dynamic>.from(decoded['data']), decoded['data']?['id']?.toString() ?? '');
    } else {
      throw StateError(decoded['message']?.toString() ?? 'Không thể xếp ca làm việc.');
    }
  }

  /// 7. Hủy ca trực
  Future<void> deleteShift(String shiftId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts/$shiftId');
    final headers = await _authHeaders();
    final res = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200 || decoded['success'] != true) {
      throw StateError(decoded['message']?.toString() ?? 'Không thể xóa ca trực.');
    }
  }

  /// 8. Chấm công Vào ca (Check-in)
  Future<void> checkInShift(String shiftId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts/$shiftId/check-in');
    final headers = await _authHeaders();
    final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200 || decoded['success'] != true) {
      throw StateError(decoded['message']?.toString() ?? 'Không thể chấm công vào ca.');
    }
  }

  /// 9. Chấm công Kết ca (Check-out)
  Future<void> checkOutShift(String shiftId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts/$shiftId/check-out');
    final headers = await _authHeaders();
    final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200 || decoded['success'] != true) {
      throw StateError(decoded['message']?.toString() ?? 'Không thể kết thúc ca trực.');
    }
  }

  /// 10. Gửi yêu cầu xin nghỉ phép
  Future<void> requestLeave({required String shiftId, String reason = ''}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts/$shiftId/leave-request');
    final headers = await _authHeaders();
    final body = jsonEncode({'reason': reason});

    final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200 || decoded['success'] != true) {
      throw StateError(decoded['message']?.toString() ?? 'Không thể gửi yêu cầu xin nghỉ phép.');
    }
  }

  /// 11. Phê duyệt / Từ chối đơn xin nghỉ phép
  Future<void> approveLeave({required String shiftId, bool approved = true, String note = ''}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v2/admin/staff/shifts/$shiftId/leave-approval');
    final headers = await _authHeaders();
    final body = jsonEncode({'approved': approved, 'note': note});

    final res = await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode != 200 || decoded['success'] != true) {
      throw StateError(decoded['message']?.toString() ?? 'Không thể cập nhật trạng thái nghỉ phép.');
    }
  }
}
