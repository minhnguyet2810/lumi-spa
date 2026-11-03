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

    test('parses rich membership fields and tiers progression', () {
      final membership = LumiMembership.fromJson({
        'tier': 'Silver',
        'tierLabel': 'Hạng Bạc',
        'points': 1500,
        'totalSpent': 1500000,
        'conversionRate': 1000,
        'discountPercent': 5,
        'nextTier': 'Gold',
        'nextTierLabel': 'Hạng Vàng',
        'pointsToNextTier': 3500,
        'spentToNextTier': 3500000,
        'progress': 0.125,
        'currentTierBenefits': [
          'Giảm 5% cho tất cả dịch vụ spa & mỹ phẩm',
          'Voucher sinh nhật 100.000 đ'
        ],
        'allTiers': [
          {
            'id': 'member',
            'name': 'Member',
            'label': 'Thành viên',
            'minPoints': 0,
            'maxPoints': 999,
            'minSpent': 0,
            'discountPercent': 0,
            'color': '#C5A880',
            'badge': 'Bronze',
            'benefits': ['Tích luỹ 1 điểm / 1.000 đ']
          },
          {
            'id': 'silver',
            'name': 'Silver',
            'label': 'Hạng Bạc',
            'minPoints': 1000,
            'maxPoints': 4999,
            'minSpent': 1000000,
            'discountPercent': 5,
            'color': '#94A3B8',
            'badge': 'Silver',
            'benefits': ['Giảm 5%']
          }
        ]
      });

      expect(membership.tier, 'Silver');
      expect(membership.tierLabel, 'Hạng Bạc');
      expect(membership.points, 1500);
      expect(membership.totalSpent, 1500000);
      expect(membership.conversionRate, 1000);
      expect(membership.discountPercent, 5);
      expect(membership.nextTier, 'Gold');
      expect(membership.nextTierLabel, 'Hạng Vàng');
      expect(membership.pointsToNextTier, 3500);
      expect(membership.spentToNextTier, 3500000);
      expect(membership.progress, 0.125);
      expect(membership.currentTierBenefits.length, 2);
      expect(membership.allTiers.length, 2);
      expect(membership.allTiers.first.name, 'Member');
      expect(membership.allTiers.last.discountPercent, 5);
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
