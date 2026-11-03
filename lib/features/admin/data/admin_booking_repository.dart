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
}
