import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/booking/data/booking_slot_calculator.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';
import 'package:lumi_spa/features/booking/data/models/slot_availability.dart';

void main() {
  group('BookingSlotCalculator & Conflict Tests', () {
    final futureDate = DateTime(2026, 11, 20);
    final mockNow = DateTime(2026, 11, 20, 11, 30); // 11:30 AM

    test('Identifies past slots for the current day', () {
      final slots = BookingSlotCalculator.calculateSlots(
        date: futureDate,
        durationMinutes: 60,
        categoryId: 'facial',
        existingBookings: [],
        now: mockNow,
      );

      // 9:00, 10:00, 11:00 are before 11:30 -> Past
      final slot9 = slots.firstWhere((s) => s.hour == 9);
      final slot10 = slots.firstWhere((s) => s.hour == 10);
      final slot11 = slots.firstWhere((s) => s.hour == 11);
      final slot12 = slots.firstWhere((s) => s.hour == 12);

      expect(slot9.status, SlotStatus.past);
      expect(slot9.isAvailable, isFalse);
      expect(slot10.status, SlotStatus.past);
      expect(slot11.status, SlotStatus.past);

      // 12:00 is after 11:30 -> Available
      expect(slot12.status, SlotStatus.available);
      expect(slot12.isAvailable, isTrue);
    });

    test('Enforces 18:00 spa closing time for long services', () {
      // 75-minute service: 17:00 + 75min = 18:15 > 18:00 (Invalid)
      final slots75 = BookingSlotCalculator.calculateSlots(
        date: DateTime(2026, 11, 21),
        durationMinutes: 75,
        categoryId: 'facial',
        existingBookings: [],
        now: DateTime(2026, 11, 20, 8, 0),
      );

      final slot16 = slots75.firstWhere((s) => s.hour == 16);
      final slot17 = slots75.firstWhere((s) => s.hour == 17);

      // 16:00 + 75m = 17:15 <= 18:00 -> Available
      expect(slot16.status, SlotStatus.available);
      // 17:00 + 75m = 18:15 > 18:00 -> ClosedExceeded
      expect(slot17.status, SlotStatus.closedExceeded);
      expect(slot17.isAvailable, isFalse);
    });

    test('XỬ LÝ TRÙNG LỊCH: Detects user conflict (trùng lịch của khách)', () {
      final targetDate = DateTime(2026, 11, 22);
      final userBookingAt14 = BookingItem(
        id: 'bk_user_1',
        serviceId: 's_body',
        serviceName: 'Thư giãn toàn thân',
        price: 500000,
        durationMinutes: 60,
        status: 'pending',
        contactName: 'Thanh Thảo',
        contactPhone: '0901234567',
        startAt: DateTime(2026, 11, 22, 14, 0),
      );

      final slots = BookingSlotCalculator.calculateSlots(
        date: targetDate,
        durationMinutes: 60,
        categoryId: 'facial',
        existingBookings: [userBookingAt14],
        currentUserId: 'user_thao_123',
        now: DateTime(2026, 11, 20, 8, 0),
      );

      final slot14 = slots.firstWhere((s) => s.hour == 14);
      final slot15 = slots.firstWhere((s) => s.hour == 15);

      // Slot 14:00 is conflicted by user's own existing appointment
      expect(slot14.status, SlotStatus.userConflict);
      expect(slot14.isAvailable, isFalse);
      expect(slot14.conflictReason, contains('Thư giãn toàn thân'));
      expect(slot14.statusBadge, 'Trùng lịch');

      // Slot 15:00 is free
      expect(slot15.status, SlotStatus.available);
      expect(slot15.isAvailable, isTrue);
    });

    test('XỬ LÝ KÍN CHỖ: Detects spa capacity limit (kín phòng & chuyên viên)', () {
      final targetDate = DateTime(2026, 11, 23);

      // Category 'facial' has capacity of 2 concurrent bookings
      final booking1 = BookingItem(
        id: 'bk_other_1',
        serviceId: 's_facial_1',
        serviceName: 'Facial 1',
        categoryId: 'facial',
        price: 600000,
        durationMinutes: 60,
        status: 'confirmed',
        contactName: 'Khách 1',
        contactPhone: '0911111111',
        startAt: DateTime(2026, 11, 23, 10, 0),
      );

      final booking2 = BookingItem(
        id: 'bk_other_2',
        serviceId: 's_facial_2',
        serviceName: 'Facial 2',
        categoryId: 'facial',
        price: 600000,
        durationMinutes: 60,
        status: 'pending',
        contactName: 'Khách 2',
        contactPhone: '0922222222',
        startAt: DateTime(2026, 11, 23, 10, 0),
      );

      final slots = BookingSlotCalculator.calculateSlots(
        date: targetDate,
        durationMinutes: 60,
        categoryId: 'facial',
        existingBookings: [booking1, booking2],
        now: DateTime(2026, 11, 20, 8, 0),
      );

      final slot10 = slots.firstWhere((s) => s.hour == 10);
      final slot11 = slots.firstWhere((s) => s.hour == 11);

      // Slot 10:00 has reached capacity (2/2) -> fullyBooked
      expect(slot10.status, SlotStatus.fullyBooked);
      expect(slot10.remainingCapacity, 0);
      expect(slot10.isAvailable, isFalse);
      expect(slot10.statusBadge, 'Kín chỗ');

      // Slot 11:00 has capacity (2 available)
      expect(slot11.status, SlotStatus.available);
      expect(slot11.remainingCapacity, 2);
      expect(slot11.isAvailable, isTrue);
      expect(slot11.statusBadge, 'Còn 2 slot');
    });

    test('Cancelled bookings do NOT occupy spa slots', () {
      final targetDate = DateTime(2026, 11, 24);

      final cancelledBooking = BookingItem(
        id: 'bk_cancelled',
        serviceId: 's_beauty',
        serviceName: 'Chăm sóc móng',
        categoryId: 'beauty', // capacity: 1
        price: 300000,
        durationMinutes: 60,
        status: 'cancelled', // Already cancelled!
        contactName: 'Khách Cũ',
        contactPhone: '0933333333',
        startAt: DateTime(2026, 11, 24, 15, 0),
      );

      final slots = BookingSlotCalculator.calculateSlots(
        date: targetDate,
        durationMinutes: 60,
        categoryId: 'beauty',
        existingBookings: [cancelledBooking],
        now: DateTime(2026, 11, 20, 8, 0),
      );

      final slot15 = slots.firstWhere((s) => s.hour == 15);

      // Even though beauty capacity is 1, cancelled booking freed the slot!
      expect(slot15.status, SlotStatus.available);
      expect(slot15.remainingCapacity, 1);
      expect(slot15.isAvailable, isTrue);
    });
  });
}
