import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    return _bookingsCol
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
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
      debugPrint('✅ [Admin] Đã duyệt lịch hẹn thành công: ${booking.id}');
    } catch (e) {
      debugPrint('❌ [Admin] Lỗi khi duyệt lịch hẹn: $e');
      rethrow;
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
      debugPrint('✅ [Admin] Đã từ chối lịch hẹn: ${booking.id}');
    } catch (e) {
      debugPrint('❌ [Admin] Lỗi khi từ chối lịch hẹn: $e');
      rethrow;
    }
  }
}

