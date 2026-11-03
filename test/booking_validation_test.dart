import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/core/data/lumi_catalog_repository.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';
import 'package:lumi_spa/features/booking/data/models/slot_availability.dart';

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
        userId: 'u1',
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
        userId: 'u1',
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
        userId: 'u1',
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
        userId: 'u1',
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

    test('SlotAvailability explanations provide clear guidance for all statuses', () {
      const avail = SlotAvailability(hour: 9, status: SlotStatus.available, remainingCapacity: 2);
      expect(avail.isAvailable, isTrue);
      expect(avail.statusBadge, 'Còn 2 slot');
      expect(avail.explanation, contains('còn trống'));

      const conflict = SlotAvailability(
        hour: 10,
        status: SlotStatus.userConflict,
        conflictReason: 'Trùng lịch chăm sóc da',
      );
      expect(conflict.isAvailable, isFalse);
      expect(conflict.statusBadge, 'Trùng lịch');
      expect(conflict.explanation, 'Trùng lịch chăm sóc da');

      const full = SlotAvailability(hour: 11, status: SlotStatus.fullyBooked);
      expect(full.isAvailable, isFalse);
      expect(full.statusBadge, 'Kín chỗ');
      expect(full.explanation, contains('kín phòng hoặc hết chuyên viên'));

      const past = SlotAvailability(hour: 12, status: SlotStatus.past);
      expect(past.isAvailable, isFalse);
      expect(past.statusBadge, 'Đã qua');

      const closed = SlotAvailability(hour: 17, status: SlotStatus.closedExceeded);
      expect(closed.isAvailable, isFalse);
      expect(closed.statusBadge, 'Quá 18:00');
    });

    test('LumiCatalogRepository withDemoImage properly decorates products with images', () {
      // 1. Specific product ID lookup
      final product1 = {'id': 'lumi-001', 'name': 'Cleansing Water'};
      final resolved1 = LumiCatalogRepository.withDemoImage(product1);
      expect(resolved1['imageUrl'], isNotNull);
      expect(resolved1['imageUrls'], isNotEmpty);
      expect(resolved1['imageUrl'], contains('unsplash.com'));

      // 2. Category fallback for unknown ID
      final productCategory = {
        'id': 'unknown-999',
        'name': 'Kem Dưỡng Thảo Mộc',
        'category': 'Dưỡng ẩm & Khóa dưỡng',
      };
      final resolvedCategory = LumiCatalogRepository.withDemoImage(productCategory);
      expect(resolvedCategory['imageUrl'], isNotNull);
      expect(resolvedCategory['imageUrls'], isNotEmpty);

      // 3. Existing image preservation
      final productWithImage = {
        'id': 'custom-01',
        'imageUrl': 'https://mycdn.com/custom.png',
      };
      final resolvedCustom = LumiCatalogRepository.withDemoImage(productWithImage);
      expect(resolvedCustom['imageUrl'], 'https://mycdn.com/custom.png');
    });
  });
}
