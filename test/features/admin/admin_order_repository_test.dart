import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/data/models/admin_order_item.dart';
import 'package:lumi_spa/core/data/lumi_order_store.dart';

void main() {
  group('AdminOrderItem Model Tests', () {
    test('Correctly parses pending order from map', () {
      final map = {
        'id': 'LUMI-112233',
        'customerName': 'Nguyễn Văn A',
        'customerEmail': 'nguyenvana@gmail.com',
        'phone': '0901234567',
        'shippingAddress': '123 Lê Duẩn, Q1, TP. HCM',
        'note': 'Giao hàng nhẹ tay',
        'total': 450000,
        'formattedTotal': '450.000 đ',
        'paymentMethod': 'COD',
        'status': 'pending',
        'items': [
          {'name': 'Sữa rửa mặt', 'quantity': 2, 'price': 150000},
          {'name': 'Kem chống nắng', 'quantity': 1, 'price': 150000},
        ],
        'userId': 'user_123',
      };

      final order = AdminOrderItem.fromMap(map, 'doc_123');

      expect(order.id, equals('LUMI-112233'));
      expect(order.customerName, equals('Nguyễn Văn A'));
      expect(order.customerEmail, equals('nguyenvana@gmail.com'));
      expect(order.phone, equals('0901234567'));
      expect(order.total, equals(450000));
      expect(order.displayTotal, equals('450.000 đ'));
      expect(order.status, equals('pending'));
      expect(order.statusLabel, equals('Chờ duyệt'));
      expect(order.statusColor, equals(const Color(0xFFD97706)));
      expect(order.totalQuantity, equals(3));
      expect(order.itemsSummary, contains('Sữa rửa mặt (x2)'));
      expect(order.itemsSummary, contains('Kem chống nắng (x1)'));
    });

    test('Correctly maps status labels and colors for all states', () {
      final base = AdminOrderItem(
        id: 'LUMI-1',
        customerName: 'Test',
        customerEmail: 'test@gmail.com',
        phone: '0123456789',
        shippingAddress: 'Address',
        total: 100000,
      );

      final confirmed = base.copyWith(status: 'confirmed');
      expect(confirmed.statusLabel, equals('Đã duyệt (Đang chuẩn bị)'));
      expect(confirmed.statusColor, equals(const Color(0xFF2563EB)));

      final shipping = base.copyWith(status: 'shipping');
      expect(shipping.statusLabel, equals('Đang giao hàng'));
      expect(shipping.statusColor, equals(const Color(0xFF7C3AED)));

      final completed = base.copyWith(status: 'completed');
      expect(completed.statusLabel, equals('Đã giao thành công'));
      expect(completed.statusColor, equals(const Color(0xFF16A34A)));

      final cancelled = base.copyWith(status: 'cancelled', cancelReason: 'Khách đổi ý');
      expect(cancelled.statusLabel, equals('Đã hủy'));
      expect(cancelled.statusColor, equals(const Color(0xFFDC2626)));
      expect(cancelled.cancelReason, equals('Khách đổi ý'));
    });

    test('LumiOrderStore syncs order from Firestore map correctly', () {
      final firestoreData = {
        'id': 'LUMI-SYNC-999',
        'status': 'confirmed',
        'total': 350000,
        'formattedTotal': '350.000 đ',
        'customerName': 'Trần Thị B',
        'phone': '0988776655',
        'shippingAddress': '456 Hai Bà Trưng',
        'paymentMethod': 'Chuyển khoản ngân hàng',
      };

      LumiOrderStore.syncOrderFromFirestore(firestoreData, 'LUMI-SYNC-999');

      final found = LumiOrderStore.orders.firstWhere(
        (o) => o['id'] == 'LUMI-SYNC-999',
      );

      expect(found['customerName'], equals('Trần Thị B'));
      expect(found['total'], equals('350.000 đ'));
    });
  });
}
