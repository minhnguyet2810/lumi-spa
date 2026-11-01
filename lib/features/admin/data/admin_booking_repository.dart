import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../booking/data/models/booking_item.dart';

class AdminBookingRepository {
  AdminBookingRepository._();
  static final AdminBookingRepository instance = AdminBookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

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
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-bookings',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
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

  /// 3. Duyệt Booking (Approve): Chuyển status thành 'approved'
  Future<void> approveBooking(BookingItem booking) async {
    try {
      final batch = _firestore.batch();
      final docRef = _bookingsCol.doc(booking.id);

      batch.update(docRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo real-time tới tài khoản của khách hàng
      if (booking.userId != null && booking.userId!.isNotEmpty) {
        final notifRef = _notificationsCol.doc();
        batch.set(notifRef, {
          'userId': booking.userId,
          'title': 'Lịch hẹn đã được duyệt ✨',
          'message':
              'Lịch hẹn "${booking.serviceName}" vào ${booking.formattedDateTime} đã được lễ tân duyệt thành công!',
          'type': 'appointment',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
        '✅ [Admin] Đã duyệt lịch hẹn Firestore thành công: ${booking.id}',
      );

      // Kích hoạt backend để gửi email xác nhận và FCM Push
      _callBackendStatusApi(booking.id, 'approved');
    } catch (e) {
      debugPrint(
        '⚠️ [Admin] Lỗi Firestore ($e), tự động chuyển sang gọi Backend API...',
      );
      // Fallback: Gọi trực tiếp Backend API (sử dụng Firebase Admin SDK không bị chặn quyền)
      await _callBackendStatusApi(booking.id, 'approved');
    }
  }

  /// 4. Từ chối Booking (Reject): Chuyển status thành 'rejected' kèm lý do
  Future<void> rejectBooking(BookingItem booking, {String? reason}) async {
    try {
      final batch = _firestore.batch();
      final docRef = _bookingsCol.doc(booking.id);

      final updatePayload = <String, dynamic>{
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null && reason.trim().isNotEmpty) {
        updatePayload['rejectionReason'] = reason.trim();
      }

      batch.update(docRef, updatePayload);

      // Gửi thông báo real-time cho khách
      if (booking.userId != null && booking.userId!.isNotEmpty) {
        final notifRef = _notificationsCol.doc();
        final reasonText = (reason != null && reason.trim().isNotEmpty)
            ? ' Lý do: ${reason.trim()}'
            : '';
        batch.set(notifRef, {
          'userId': booking.userId,
          'title': 'Lịch hẹn không thể tiếp nhận 🌸',
          'message':
              'Lịch hẹn "${booking.serviceName}" vào ${booking.formattedDateTime} không thể tiếp nhận.$reasonText Vui lòng chọn khung giờ khác.',
          'type': 'appointment',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ [Admin] Đã từ chối lịch hẹn Firestore: ${booking.id}');

      // Kích hoạt backend
      _callBackendStatusApi(booking.id, 'rejected', reason: reason);
    } catch (e) {
      debugPrint(
        '⚠️ [Admin] Lỗi Firestore ($e), tự động chuyển sang gọi Backend API...',
      );
      // Fallback: Gọi trực tiếp Backend API
      await _callBackendStatusApi(booking.id, 'rejected', reason: reason);
    }
  }

  Future<void> _callBackendStatusApi(
    String id,
    String status, {
    String? reason,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/admin-bookings/$id/status',
      );
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status, 'reason': reason ?? ''}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint(
          '✅ [Admin] Backend đã cập nhật trạng thái booking $id -> $status',
        );
      } else {
        debugPrint(
          '⚠️ [Admin] Backend cập nhật status code: ${res.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Admin] Không thể kết nối Backend API cho booking: $e');
    }
  }
}
