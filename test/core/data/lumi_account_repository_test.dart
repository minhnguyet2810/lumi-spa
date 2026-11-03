import 'package:flutter_test/flutter_test.dart';

import 'package:lumi_spa/core/data/lumi_account_repository.dart';

void main() {
  group('LumiMembership.fromJson', () {
    test('parses valid backend membership values', () {
      final membership = LumiMembership.fromJson({
        'tier': 'Member',
        'points': 0,
        'totalSpent': 0,
        'isDefault': true,
      });

      expect(membership.tier, 'Member');
      expect(membership.points, 0);
      expect(membership.totalSpent, 0);
      expect(membership.isDefault, isTrue);
    });

    test('keeps invalid tier and points unavailable', () {
      final membership = LumiMembership.fromJson({
        'tier': '',
        'points': 'not-a-number',
        'totalSpent': -1,
        'isDefault': 'true',
      });

      expect(membership.tier, isNull);
      expect(membership.points, isNull);
      expect(membership.totalSpent, isNull);
      expect(membership.isDefault, isNull);
    });

    test('keeps valid fields when another field is invalid', () {
      final membership = LumiMembership.fromJson({
        'tier': 'Silver',
        'points': 42,
        'totalSpent': double.nan,
      });

      expect(membership.tier, 'Silver');
      expect(membership.points, 42);
      expect(membership.totalSpent, isNull);
    });
  });

  group('LumiAddressItem Tests', () {
    test('fromJson parses correctly and produces formatted display address', () {
      final address = LumiAddressItem.fromJson({
        'id': 'addr_1',
        'recipientName': 'Thanh Thảo',
        'phone': '0901234567',
        'street': '123 Lê Lợi',
        'ward': 'Phường Bến Nghé',
        'district': 'Quận 1',
        'province': 'TP. Hồ Chí Minh',
        'label': 'Nhà riêng',
        'isDefault': true,
      });

      expect(address.id, 'addr_1');
      expect(address.recipientName, 'Thanh Thảo');
      expect(address.phone, '0901234567');
      expect(address.street, '123 Lê Lợi');
      expect(address.label, 'Nhà riêng');
      expect(address.isDefault, isTrue);
      expect(address.displayAddress, '123 Lê Lợi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh');
    });

    test('displayAddress uses fullAddress if provided', () {
      const address = LumiAddressItem(
        id: 'addr_2',
        recipientName: 'Alice',
        phone: '0909998887',
        street: '456 Hai Bà Trưng',
        fullAddress: 'Tòa nhà Landmark 81, 720A Điện Biên Phủ, Phường 22, Bình Thạnh',
        label: 'Văn phòng',
        isDefault: false,
      );

      expect(address.displayAddress, 'Tòa nhà Landmark 81, 720A Điện Biên Phủ, Phường 22, Bình Thạnh');
      expect(address.label, 'Văn phòng');
      expect(address.isDefault, isFalse);
    });

    test('toJson and copyWith produce valid copies and payload', () {
      const address = LumiAddressItem(
        id: 'addr_3',
        recipientName: 'Bob',
        phone: '0901112223',
        street: '789 Nguyễn Huệ',
        province: 'TP. Hồ Chí Minh',
        label: 'Nhà riêng',
        isDefault: false,
      );

      final updated = address.copyWith(isDefault: true, label: 'Văn phòng');
      expect(updated.isDefault, isTrue);
      expect(updated.label, 'Văn phòng');
      expect(updated.recipientName, 'Bob');

      final json = updated.toJson();
      expect(json['id'], 'addr_3');
      expect(json['isDefault'], isTrue);
      expect(json['label'], 'Văn phòng');
    });
  });
}
