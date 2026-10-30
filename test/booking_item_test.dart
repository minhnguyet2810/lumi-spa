import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/core/network/api_config.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

void main() {
  group('ApiConfig Tests', () {
    test('Default endpoints are properly constructed', () {
      expect(ApiConfig.servicesUri.path, '/api/services');
      expect(ApiConfig.bookingsUri.path, '/api/bookings');
      expect(ApiConfig.slotsUri('2026-11-20', 'spa001').path, '/api/bookings/slots');
      expect(ApiConfig.serviceDetailUri('spa001').path, '/api/services/spa001');
      expect(ApiConfig.cancelBookingUri('bk123').path, '/api/bookings/bk123/cancel');
    });

    test('Custom base URL can be configured', () {
      ApiConfig.customBaseUrl = 'http://192.168.1.100:3000';
      expect(ApiConfig.baseUrl, 'http://192.168.1.100:3000');
      expect(ApiConfig.bookingsUri.toString(), 'http://192.168.1.100:3000/api/bookings');
      ApiConfig.customBaseUrl = null; // reset
    });
  });

  group('BookingItem Model Tests', () {
    test('fromJson parses correctly with pending status and userId', () {
      final json = {
        'id': 'bk_test_1',
        'userId': 'usr_thao_01',
        'serviceId': 'facial_001',
        'serviceName': 'Signature Facial',
        'categoryId': 'facial',
        'price': 650000,
        'durationMinutes': 60,
        'status': 'pending',
        'contactName': 'Thanh Thảo',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      };

      final item = BookingItem.fromJson(json);

      expect(item.id, 'bk_test_1');
      expect(item.userId, 'usr_thao_01');
      expect(item.serviceName, 'Signature Facial');
      expect(item.categoryId, 'facial');
      expect(item.status, 'pending');
      expect(item.statusLabel, 'Chờ xác nhận');
      expect(item.formattedPrice, '650.000 đ');
      expect(item.isCancellable, isTrue);
      expect(item.isUpcoming, isTrue);
      expect(item.isHistory, isFalse);
      expect(item.isCancelled, isFalse);
    });

    test('Cancelled and completed bookings categorizations', () {
      final jsonCancelled = {
        'id': 'bk_2',
        'serviceId': 'massage_001',
        'serviceName': 'Body Massage',
        'price': 400000,
        'durationMinutes': 60,
        'status': 'cancelled',
        'contactName': 'Thanh Thảo',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      final itemCancelled = BookingItem.fromJson(jsonCancelled);
      expect(itemCancelled.isCancellable, isFalse);
      expect(itemCancelled.statusLabel, 'Đã hủy');
      expect(itemCancelled.isCancelled, isTrue);
      expect(itemCancelled.isUpcoming, isFalse);
      expect(itemCancelled.isHistory, isFalse);

      final jsonCompleted = {
        'id': 'bk_3',
        'serviceId': 'massage_001',
        'serviceName': 'Body Massage',
        'price': 400000,
        'durationMinutes': 60,
        'status': 'completed',
        'contactName': 'Thanh Thảo',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };

      final itemCompleted = BookingItem.fromJson(jsonCompleted);
      expect(itemCompleted.isCancellable, isFalse);
      expect(itemCompleted.statusLabel, 'Đã hoàn thành');
      expect(itemCompleted.isHistory, isTrue);
      expect(itemCompleted.isUpcoming, isFalse);
    });

    test('Past uncancelled bookings are classified as History', () {
      final jsonPast = {
        'id': 'bk_past',
        'serviceId': 'spa001',
        'serviceName': 'Past Session',
        'price': 500000,
        'durationMinutes': 60,
        'status': 'confirmed',
        'contactName': 'Thanh Thảo',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      };

      final itemPast = BookingItem.fromJson(jsonPast);
      expect(itemPast.isUpcoming, isFalse);
      expect(itemPast.isHistory, isTrue);
      expect(itemPast.isCancellable, isFalse);
    });

    test('Formatted dates and prices are correctly produced', () {
      final start = DateTime(2026, 11, 20, 14, 30);
      final item = BookingItem(
        id: 'bk_format',
        userId: 'u_1',
        serviceId: 's1',
        serviceName: 'LUMI Glow',
        price: 1250000,
        durationMinutes: 75,
        status: 'pending',
        contactName: 'Thanh Thảo',
        contactPhone: '0987654321',
        startAt: start,
      );

      expect(item.formattedDate, '20/11/2026');
      expect(item.formattedTime, '14:30');
      expect(item.formattedDateTime, '14:30 · 20/11/2026');
      expect(item.formattedPrice, '1.250.000 đ');
    });

    test('copyWith updates fields while preserving existing values', () {
      final item = BookingItem(
        id: 'b1',
        userId: 'u1',
        serviceId: 's1',
        serviceName: 'Liệu trình 1',
        price: 300000,
        durationMinutes: 60,
        status: 'pending',
        contactName: 'Thảo',
        contactPhone: '0901234567',
      );

      final updated = item.copyWith(status: 'confirmed');
      expect(updated.id, 'b1');
      expect(updated.userId, 'u1');
      expect(updated.status, 'confirmed');
      expect(updated.serviceName, 'Liệu trình 1');
    });
  });
}
