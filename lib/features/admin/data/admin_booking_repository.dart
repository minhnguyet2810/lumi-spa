import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/lumi_api_client.dart';
import '../../booking/data/models/booking_item.dart';

class AdminBookingRepository {
  AdminBookingRepository._();
  static final AdminBookingRepository instance = AdminBookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập quản trị.');
    }
    final result = await user.getIdTokenResult();
    if (result.claims?['admin'] != true || result.token == null) {
      throw StateError('Bạn không có quyền quản trị.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${result.token}',
    };
  }

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _firestore.collection('bookings');

  /// 1. Lắng nghe real-time danh sách Booking có trạng thái 'pending' (Chờ duyệt)
  Stream<List<BookingItem>> streamPendingBookings() {
    return _bookingsCol.where('status', isEqualTo: 'pending').snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs.map(BookingItem.fromFirestore).toList();
      // Sắp xếp đơn mới tạo lên đầu
      list.sort((a, b) {
        final dateA = a.createdAt ?? a.startAt ?? DateTime(0);
        final dateB = b.createdAt ?? b.startAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 2. Lắng nghe real-time tất cả Booking (để Admin lọc theo nhiều trạng thái)
  Stream<List<BookingItem>> streamAllBookings() {
    return _bookingsCol.snapshots().map((snapshot) {
      final list = snapshot.docs.map(BookingItem.fromFirestore).toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? a.startAt ?? DateTime(0);
        final dateB = b.createdAt ?? b.startAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// 2.1 Tải danh sách Booking qua Backend API (dành cho Admin khi bị chặn quyền Firestore Rules)
  Future<List<BookingItem>> fetchBookingsFromApi({
    String? status,
    String? query,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-bookings',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .map(
                (item) => BookingItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️ [AdminBookingRepository] Không thể tải booking từ Backend API: $e',
      );
    }
    return [];
  }

  Future<void> approveBooking(BookingItem booking) async {
    await LumiApiClient.instance.patch(
      '/api/admin/bookings/${Uri.encodeComponent(booking.id)}/confirm',
    );
  }

  Future<void> rejectBooking(BookingItem booking, {String? reason}) async {
    await LumiApiClient.instance.patch(
      '/api/admin/bookings/${Uri.encodeComponent(booking.id)}/reject',
      body: {'reason': reason ?? ''},
    );
  }

  Future<void> completeBooking(BookingItem booking) async {
    await LumiApiClient.instance.patch(
      '/api/admin/bookings/${Uri.encodeComponent(booking.id)}/complete',
    );
  }
  /// V2: Lấy ma trận lịch hẹn Timeline & Calendar
  Future<Map<String, dynamic>> fetchTimelineMatrixV2({
    String? branchId,
    String? date,
    String? roomId,
    String? technicianId,
  }) async {
    final queryParams = <String, String>{};
    if (branchId != null) queryParams['branchId'] = branchId;
    if (date != null) queryParams['date'] = date;
    if (roomId != null) queryParams['roomId'] = roomId;
    if (technicianId != null) queryParams['technicianId'] = technicianId;
    final uri = Uri.parse('/api/v2/admin/bookings/timeline').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    return await LumiApiClient.instance.get(uri.toString());
  }

  /// V2: Duyệt lịch và khóa slot KTV / phòng
  Future<Map<String, dynamic>> confirmBookingV2({
    required String appointmentId,
    required String technicianId,
    required String roomId,
    String? branchId,
    String? note,
  }) async {
    return await LumiApiClient.instance.post(
      '/api/v2/admin/bookings/${Uri.encodeComponent(appointmentId)}/confirm',
      body: {
        'technicianId': technicianId,
        'roomId': roomId,
        'branchId': ?branchId,
        'note': ?note,
      },
    );
  }

  /// V2: Check-in tiếp nhận khách tại chỗ
  Future<Map<String, dynamic>> checkInBookingV2({
    required String appointmentId,
    String? note,
  }) async {
    return await LumiApiClient.instance.post(
      '/api/v2/admin/bookings/${Uri.encodeComponent(appointmentId)}/check-in',
      body: { 'note': ?note },
    );
  }

  /// V2: Ghi nhận hồ sơ bệnh án da & phác đồ điều trị
  Future<Map<String, dynamic>> updateTreatmentRecordV2({
    required String appointmentId,
    String? userId,
    String? skinConditionBefore,
    List<String>? treatmentStepsApplied,
    List<Map<String, dynamic>>? productsUsed,
    String? skinReactionAfter,
    String? homecareRecommendations,
  }) async {
    return await LumiApiClient.instance.post(
      '/api/v2/admin/bookings/${Uri.encodeComponent(appointmentId)}/treatment-record',
      body: {
        'userId': ?userId,
        'skinConditionBefore': ?skinConditionBefore,
        'treatmentStepsApplied': ?treatmentStepsApplied,
        'productsUsed': ?productsUsed,
        'skinReactionAfter': ?skinReactionAfter,
        'homecareRecommendations': ?homecareRecommendations,
      },
    );
  }

  /// V2: Hoàn tất liệu trình, tính hoa hồng KTV và tích điểm khách hàng
  Future<Map<String, dynamic>> completeBookingV2({
    required String appointmentId,
    num? tips,
    String? paymentMethod,
  }) async {
    return await LumiApiClient.instance.post(
      '/api/v2/admin/bookings/${Uri.encodeComponent(appointmentId)}/complete',
      body: {
        'tips': ?tips,
        'paymentMethod': ?paymentMethod,
      },
    );
  }

  /// V2: Hủy lịch hẹn và giải phóng khóa tài nguyên
  Future<Map<String, dynamic>> cancelBookingV2({
    required String appointmentId,
    required String reason,
  }) async {
    return await LumiApiClient.instance.post(
      '/api/v2/admin/bookings/${Uri.encodeComponent(appointmentId)}/cancel',
      body: {'reason': reason},
    );
  }
}
