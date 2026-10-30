import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'booking_api_service.dart';
import 'booking_slot_calculator.dart';
import 'models/booking_item.dart';
import 'models/slot_availability.dart';

class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);

  @override
  String toString() => message;
}

class BookingRepository {
  BookingRepository._();
  static final BookingRepository instance = BookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _firestore.collection('bookings');

  /// KẾT NỐI MY APPOINTMENTS VỚI FIRESTORE (Realtime Stream)
  Stream<List<BookingItem>> streamUserBookings(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _bookingsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return BookingItem.fromFirestore(doc);
      }).toList();

      // Sắp xếp lịch hẹn mới nhất lên đầu
      list.sort((a, b) {
        final dateA = a.startAt ?? DateTime(0);
        final dateB = b.startAt ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      return list;
    });
  }

  /// Lấy danh sách lịch hẹn của user (kết nối Firestore, fallback API)
  Future<List<BookingItem>> getUserBookings(String userId) async {
    try {
      final snapshot = await _bookingsCol
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) => BookingItem.fromFirestore(doc)).toList();
        list.sort((a, b) {
          final dateA = a.startAt ?? DateTime(0);
          final dateB = b.startAt ?? DateTime(0);
          return dateB.compareTo(dateA);
        });
        return list;
      }
    } catch (e) {
      debugPrint('Firestore fetch error, fallback to API: $e');
    }

    // Fallback qua Backend API
    return BookingApiService.instance.getMyBookings();
  }

  /// Lấy danh sách tất cả booking trong một ngày từ Firestore để tính toán slot
  Future<List<BookingItem>> getBookingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snapshot = await _bookingsCol
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) => BookingItem.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting bookings for date from Firestore: $e');
      return [];
    }
  }

  /// HIỂN THỊ SLOT CÒN TRỐNG
  /// Tính toán chi tiết từng khung giờ: Còn trống (và số chỗ), Trùng lịch, Kín chỗ, Đã qua
  Future<List<SlotAvailability>> getAvailableSlots({
    required DateTime date,
    required String serviceId,
    String? categoryId,
    required int durationMinutes,
    String? currentUserId,
    DateTime? now,
  }) async {
    final existingBookings = await getBookingsForDate(date);

    // Đảm bảo tích hợp cả lịch hẹn cá nhân của user trong ngày
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final userBookings = await getUserBookings(currentUserId);
      final userDayBookings = userBookings.where((b) {
        if (b.startAt == null) return false;
        return b.startAt!.year == date.year &&
            b.startAt!.month == date.month &&
            b.startAt!.day == date.day;
      }).toList();

      final existingIds = existingBookings.map((b) => b.id).toSet();
      for (final ub in userDayBookings) {
        if (!existingIds.contains(ub.id)) {
          existingBookings.add(ub);
        }
      }
    }

    return BookingSlotCalculator.calculateSlots(
      date: date,
      durationMinutes: durationMinutes,
      categoryId: categoryId,
      existingBookings: existingBookings,
      currentUserId: currentUserId,
      now: now,
    );
  }

  /// Kiểm tra xem người dùng hiện tại có bị trùng lịch hẹn nào khác không
  Future<String?> checkUserConflict({
    required String userId,
    required DateTime slotStart,
    required int durationMinutes,
  }) async {
    if (userId.isEmpty) return null;

    final userBookings = await getUserBookings(userId);
    final activeBookings = userBookings.where((b) {
      return b.status == 'pending' || b.status == 'confirmed';
    }).toList();

    for (final b in activeBookings) {
      if (b.startAt == null) continue;
      if (BookingSlotCalculator.isOverlapping(
        start1: slotStart,
        durationMinutes1: durationMinutes,
        start2: b.startAt!,
        durationMinutes2: b.durationMinutes,
      )) {
        return 'Quý khách đã có lịch hẹn "${b.serviceName}" vào lúc ${b.formattedTime} ngày ${b.formattedDate}. Vui lòng chọn khung giờ khác để tránh trùng lịch.';
      }
    }
    return null;
  }

  /// HOÀN THIỆN ĐẶT LỊCH: Kiểm tra trùng lịch, gọi API backend hoặc ghi Firestore
  Future<BookingItem> createBooking({
    required String serviceId,
    required String serviceName,
    String? categoryId,
    required num price,
    required int durationMinutes,
    required DateTime date,
    required int hour,
    required String contactName,
    required String contactPhone,
  }) async {
    final user = _auth.currentUser;
    final userId = user?.uid ?? '';

    final slotStart = DateTime(date.year, date.month, date.day, hour);

    // 1. Kiểm tra trùng lịch cá nhân trước khi gửi
    final conflictMsg = await checkUserConflict(
      userId: userId,
      slotStart: slotStart,
      durationMinutes: durationMinutes,
    );
    if (conflictMsg != null) {
      throw BookingConflictException(conflictMsg);
    }

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // 2. Gọi Backend API để xử lý transaction và lock resource_slots
    try {
      final result = await BookingApiService.instance.createBooking(
        serviceId: serviceId,
        date: dateStr,
        hour: hour,
        contactName: contactName,
        contactPhone: contactPhone,
      );
      return result;
    } on BookingApiException catch (apiEx) {
      // Nếu là lỗi conflict từ server (409)
      if (apiEx.statusCode == 409) {
        throw BookingConflictException(
          apiEx.message.isNotEmpty
              ? apiEx.message
              : 'Khung giờ này đã kín phòng hoặc không còn chuyên viên trống.',
        );
      }

      // Nếu lỗi kết nối backend (port 3000 chưa bật), fallback ghi trực tiếp Firestore
      if (apiEx.message.contains('Không thể kết nối') || apiEx.statusCode == null) {
        debugPrint('Backend unreachable, saving booking directly to Firestore: $apiEx');
        return await _createBookingDirectInFirestore(
          userId: userId,
          serviceId: serviceId,
          serviceName: serviceName,
          categoryId: categoryId,
          price: price,
          durationMinutes: durationMinutes,
          startAt: slotStart,
          contactName: contactName,
          contactPhone: contactPhone,
        );
      }
      rethrow;
    } catch (e) {
      // Fallback nếu có lỗi ngoại lệ khác về kết nối
      if (userId.isNotEmpty) {
        return await _createBookingDirectInFirestore(
          userId: userId,
          serviceId: serviceId,
          serviceName: serviceName,
          categoryId: categoryId,
          price: price,
          durationMinutes: durationMinutes,
          startAt: slotStart,
          contactName: contactName,
          contactPhone: contactPhone,
        );
      }
      rethrow;
    }
  }

  /// Ghi trực tiếp vào Firestore phòng khi Backend Node.js chưa chạy
  Future<BookingItem> _createBookingDirectInFirestore({
    required String userId,
    required String serviceId,
    required String serviceName,
    String? categoryId,
    required num price,
    required int durationMinutes,
    required DateTime startAt,
    required String contactName,
    required String contactPhone,
  }) async {
    final docRef = _bookingsCol.doc();
    final data = {
      'id': docRef.id,
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'categoryId': ?categoryId,
      'price': price,
      'durationMinutes': durationMinutes,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'startAt': Timestamp.fromDate(startAt),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);

    return BookingItem.fromJson({
      ...data,
      'startAt': startAt.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// HỦY LỊCH HẸN: Gọi backend API để giải phóng resource_slots, fallback Firestore update
  Future<void> cancelBooking(String bookingId) async {
    try {
      await BookingApiService.instance.cancelBooking(bookingId);
    } catch (e) {
      debugPrint('Backend cancel error, updating Firestore directly: $e');
      // Cập nhật trạng thái cancelled trực tiếp trên Firestore
      await _bookingsCol.doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
