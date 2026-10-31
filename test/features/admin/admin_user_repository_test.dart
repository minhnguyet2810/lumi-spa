import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/data/models/admin_user_item.dart';

void main() {
  group('AdminUserItem Model Tests', () {
    test('Correctly parses user item from map with all fields', () {
      final map = {
        'id': 'user_001',
        'displayName': 'Nguyễn Thảo',
        'email': 'thao@gmail.com',
        'phone': '0901234567',
        'role': 'user',
        'bookingCount': 3,
        'orderCount': 2,
        'totalSpent': 750000,
        'createdAt': '2026-10-20T10:00:00.000Z',
      };

      final user = AdminUserItem.fromMap(map, 'user_001');

      expect(user.id, equals('user_001'));
      expect(user.displayName, equals('Nguyễn Thảo'));
      expect(user.email, equals('thao@gmail.com'));
      expect(user.phone, equals('0901234567'));
      expect(user.role, equals('user'));
      expect(user.isAdmin, isFalse);
      expect(user.roleLabel, equals('Khách hàng'));
      expect(user.initials, equals('NT'));
      expect(user.bookingCount, equals(3));
      expect(user.orderCount, equals(2));
      expect(user.totalSpent, equals(750000));
      expect(user.displayTotalSpent, equals('750.000 đ'));
    });

    test('Correctly identifies admin role and colors', () {
      final admin = AdminUserItem(
        id: 'admin_001',
        displayName: 'Admin Master',
        email: 'admin@lumispa.vn',
        phone: '0988776655',
        role: 'admin',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.roleLabel, equals('Quản trị viên'));
      expect(admin.roleColor, equals(const Color(0xFF7C3AED)));
      expect(admin.initials, equals('AM'));
    });

    test('Handles fallback initials when displayName has single word or is empty', () {
      final singleWord = AdminUserItem(
        id: 'u1',
        displayName: 'Thảo',
        email: 'thao@gmail.com',
        phone: '0123456789',
      );
      expect(singleWord.initials, equals('TH'));

      final emptyName = AdminUserItem(
        id: 'u2',
        displayName: '',
        email: 'contact@lumispa.vn',
        phone: '0123456789',
      );
      expect(emptyName.initials, equals('C'));
    });

    test('copyWith updates fields correctly', () {
      final user = AdminUserItem(
        id: 'user_002',
        displayName: 'Lê Văn B',
        email: 'b@gmail.com',
        phone: '0911223344',
        role: 'user',
        bookingCount: 1,
      );

      final updated = user.copyWith(
        role: 'admin',
        bookingCount: 5,
        totalSpent: 1200000,
      );

      expect(updated.role, equals('admin'));
      expect(updated.isAdmin, isTrue);
      expect(updated.bookingCount, equals(5));
      expect(updated.totalSpent, equals(1200000));
      expect(updated.displayTotalSpent, equals('1.200.000 đ'));
    });
  });
}
