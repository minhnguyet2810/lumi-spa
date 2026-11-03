import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _auth = FirebaseAuth.instance;
  final _bookingsCol = FirebaseFirestore.instance.collection('bookings');

  Stream<List<BookingItem>> streamUserBookings(String userId) {
    if (userId.isEmpty || userId != _auth.currentUser?.uid) {
      return Stream.value([]);
    }
    return _bookingsCol.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs.map(BookingItem.fromFirestore).toList();
      list.sort(
        (a, b) =>
            (b.startAt ?? DateTime(0)).compareTo(a.startAt ?? DateTime(0)),
      );
      return list;
    });
  }

  Future<List<BookingItem>> getUserBookings(String userId) async {
    if (userId.isEmpty || userId != _auth.currentUser?.uid) {
      return [];
    }
    try {
      return await streamUserBookings(userId).first;
    } catch (_) {
      return BookingApiService.instance.getMyBookings();
    }
  }

  Future<List<SlotAvailability>> getAvailableSlots({
    required DateTime date,
    required String serviceId,
    String? categoryId,
    required int durationMinutes,
    String? currentUserId,
    DateTime? now,
  }) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final slots = await BookingApiService.instance.getAvailableSlots(
      day,
      serviceId,
    );
    if (slots.isEmpty) {
      throw BookingApiException('Chưa tải được khung giờ. Vui lòng thử lại.');
    }
    final own = currentUserId == null
        ? <BookingItem>[]
        : await getUserBookings(currentUserId);
    final personalSlots = BookingSlotCalculator.calculateSlots(
      date: date,
      durationMinutes: durationMinutes,
      categoryId: categoryId,
      existingBookings: own,
      currentUserId: currentUserId,
      now: now,
    );
    return slots.map((slot) {
      final hour = slot['hour'] as int;
      final status = SlotStatus.values.firstWhere(
        (s) => s.name == slot['status'],
        orElse: () => SlotStatus.fullyBooked,
      );
      final personal = personalSlots.where((s) => s.hour == hour);
      if (status == SlotStatus.available &&
          personal.isNotEmpty &&
          personal.first.status == SlotStatus.userConflict) {
        return personal.first;
      }
      return SlotAvailability(
        hour: hour,
        status: status,
        remainingCapacity: (slot['remainingCapacity'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<String?> checkUserConflict({
    required String userId,
    required DateTime slotStart,
    required int durationMinutes,
  }) async {
    for (final booking in await getUserBookings(userId)) {
      if (['pending', 'confirmed', 'approved'].contains(booking.status) &&
          booking.startAt != null &&
          BookingSlotCalculator.isOverlapping(
            start1: slotStart,
            durationMinutes1: durationMinutes,
            start2: booking.startAt!,
            durationMinutes2: booking.durationMinutes,
          )) {
        return 'Bạn đã có lịch hẹn trong khung giờ này. Vui lòng chọn giờ khác.';
      }
    }
    return null;
  }

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
    if (_auth.currentUser == null) {
      throw BookingApiException(
        'Vui lòng đăng nhập để đặt lịch.',
        statusCode: 401,
      );
    }
    final conflict = await checkUserConflict(
      userId: _auth.currentUser!.uid,
      slotStart: DateTime(date.year, date.month, date.day, hour),
      durationMinutes: durationMinutes,
    );
    if (conflict != null) {
      throw BookingConflictException(conflict);
    }
    try {
      return await BookingApiService.instance.createBooking(
        serviceId: serviceId,
        date:
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        hour: hour,
        contactName: contactName,
        contactPhone: contactPhone,
      );
    } on BookingApiException catch (error) {
      if (error.statusCode == 409) {
        throw BookingConflictException(error.message);
      }
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) =>
      BookingApiService.instance.cancelBooking(bookingId);
}
