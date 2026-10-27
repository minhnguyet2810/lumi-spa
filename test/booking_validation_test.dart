import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

void main() {
  group('Booking Validation & Appointments Tests', () {
    final phoneRegex = RegExp(r'^[0-9+().\s-]{8,20}$');

    test('Phone number validation accepts valid Vietnamese formats', () {
      expect(phoneRegex.hasMatch('0901234567'), isTrue);
      expect(phoneRegex.hasMatch('+84901234567'), isTrue);
      expect(phoneRegex.hasMatch('0912 345 678'), isTrue);
      expect(phoneRegex.hasMatch('028-3829-1234'), isTrue);
    });

    test('Phone number validation rejects invalid inputs', () {
      expect(phoneRegex.hasMatch(''), isFalse);
      expect(phoneRegex.hasMatch('1234567'), isFalse); // < 8
      expect(phoneRegex.hasMatch('0901234567890123456789'), isFalse); // > 20
      expect(phoneRegex.hasMatch('090123abcd'), isFalse); // contains letters
    });

    test('Contact name validation ensures non-empty string', () {
      bool isValidName(String name) => name.trim().isNotEmpty && name.trim().length <= 100;

      expect(isValidName('Thanh Thảo'), isTrue);
      expect(isValidName('   '), isFalse);
      expect(isValidName(''), isFalse);
    });

    test('Appointments Tab separation: Sắp tới, Lịch sử, Đã hủy', () {
      final now = DateTime.now();

      final upcoming = BookingItem(
        id: '1',
        serviceId: 's1',
        serviceName: 'Dịch vụ 1',
        price: 500000,
        durationMinutes: 60,
        status: 'confirmed',
        contactName: 'Thảo',
        contactPhone: '0901234567',
        startAt: now.add(const Duration(days: 3)),
      );

      final historyCompleted = BookingItem(
        id: '2',
        serviceId: 's2',
        serviceName: 'Dịch vụ 2',
        price: 400000,
        durationMinutes: 60,
        status: 'completed',
        contactName: 'Thảo',
        contactPhone: '0901234567',
        startAt: now.subtract(const Duration(days: 1)),
      );

      final historyPast = BookingItem(
        id: '3',
        serviceId: 's3',
        serviceName: 'Dịch vụ 3',
        price: 450000,
        durationMinutes: 60,
        status: 'confirmed', // not marked completed yet, but date has passed
        contactName: 'Thảo',
        contactPhone: '0901234567',
        startAt: now.subtract(const Duration(days: 5)),
      );

      final cancelled = BookingItem(
        id: '4',
        serviceId: 's4',
        serviceName: 'Dịch vụ 4',
        price: 350000,
        durationMinutes: 60,
        status: 'cancelled',
        contactName: 'Thảo',
        contactPhone: '0901234567',
        startAt: now.add(const Duration(days: 2)),
      );

      final allBookings = [upcoming, historyCompleted, historyPast, cancelled];

      final tabUpcoming = allBookings.where((b) => b.isUpcoming).toList();
      final tabHistory = allBookings.where((b) => b.isHistory).toList();
      final tabCancelled = allBookings.where((b) => b.isCancelled).toList();

      expect(tabUpcoming.map((b) => b.id), ['1']);
      expect(tabHistory.map((b) => b.id), ['2', '3']);
      expect(tabCancelled.map((b) => b.id), ['4']);
    });
  });
}

