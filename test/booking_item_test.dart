import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/core/network/api_config.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

void main() {
  group('ApiConfig Tests', () {
    test('Default endpoints are properly constructed', () {
      expect(ApiConfig.servicesUri.path, '/api/services');
      expect(ApiConfig.bookingsUri.path, '/api/bookings');
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
    test('fromJson parses correctly with pending status', () {
      final json = {
        'id': 'bk_test_1',
        'serviceId': 'facial_001',
        'serviceName': 'Signature Facial',
        'price': 650000,
        'durationMinutes': 60,
        'status': 'pending',
        'contactName': 'Thanh Thao',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      };

      final item = BookingItem.fromJson(json);

      expect(item.id, 'bk_test_1');
      expect(item.serviceName, 'Signature Facial');
      expect(item.status, 'pending');
      expect(item.statusLabel, 'Chờ xác nhận');
      expect(item.formattedPrice, '650.000 đ');
      expect(item.isCancellable, isTrue);
    });

    test('Cancelled and completed bookings cannot be cancelled again', () {
      final jsonCancelled = {
        'id': 'bk_2',
        'serviceId': 'massage_001',
        'serviceName': 'Body Massage',
        'price': 400000,
        'durationMinutes': 60,
        'status': 'cancelled',
        'contactName': 'Thanh Thao',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      final itemCancelled = BookingItem.fromJson(jsonCancelled);
      expect(itemCancelled.isCancellable, isFalse);
      expect(itemCancelled.statusLabel, 'Đã hủy');

      final jsonCompleted = {
        'id': 'bk_3',
        'serviceId': 'massage_001',
        'serviceName': 'Body Massage',
        'price': 400000,
        'durationMinutes': 60,
        'status': 'completed',
        'contactName': 'Thanh Thao',
        'contactPhone': '0901234567',
        'startAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };

      final itemCompleted = BookingItem.fromJson(jsonCompleted);
      expect(itemCompleted.isCancellable, isFalse);
      expect(itemCompleted.statusLabel, 'Đã hoàn thành');
    });
  });
}
