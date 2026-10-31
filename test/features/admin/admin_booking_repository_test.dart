import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

void main() {
  group('Admin Booking Feature Tests', () {
    test('BookingItem correctly formats status for approved and rejected', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final approvedItem = BookingItem(
        id: 'book_001',
        serviceId: 'spa001',
        serviceName: 'Chăm sóc da mặt chuyên sâu',
        price: 490000,
        durationMinutes: 75,
        status: 'approved',
        contactName: 'Thanh Thao',
        contactPhone: '0901234567',
        startAt: futureDate,
      );

      final rejectedItem = BookingItem(
        id: 'book_002',
        serviceId: 'spa002',
        serviceName: 'Lấy nhân mụn chuẩn y khoa',
        price: 350000,
        durationMinutes: 60,
        status: 'rejected',
        contactName: 'Nguyen Van A',
        contactPhone: '0909888999',
        startAt: futureDate,
      );

      expect(approvedItem.statusLabel, equals('Đã duyệt'));
      expect(approvedItem.isUpcoming, isTrue);
      expect(approvedItem.isCancelled, isFalse);

      expect(rejectedItem.statusLabel, equals('Đã từ chối'));
      expect(rejectedItem.isCancelled, isTrue);
      expect(rejectedItem.isUpcoming, isFalse);
    });

    test('BookingItem copyWith preserves approved status correctly', () {
      final item = BookingItem(
        id: 'book_003',
        serviceId: 'spa001',
        serviceName: 'Chăm sóc da mặt',
        price: 400000,
        durationMinutes: 60,
        status: 'pending',
        contactName: 'Tran B',
        contactPhone: '0912345678',
        startAt: DateTime.now().add(const Duration(days: 2)),
      );

      final approved = item.copyWith(status: 'approved');
      expect(approved.status, equals('approved'));
      expect(approved.statusLabel, equals('Đã duyệt'));
      expect(approved.isUpcoming, isTrue);

      final rejected = item.copyWith(status: 'rejected');
      expect(rejected.status, equals('rejected'));
      expect(rejected.statusLabel, equals('Đã từ chối'));
      expect(rejected.isCancelled, isTrue);
    });
  });
}
