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
}
