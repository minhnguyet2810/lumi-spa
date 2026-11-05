import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/data/models/customer_360_model.dart';

void main() {
  group('Customer 360 Model Tests', () {
    test('LoyaltyProfile parsed from map calculates correctly', () {
      final map = {
        'points': 5200,
        'lifetimeSpent': 12500000,
        'tier': 'gold',
        'tierLabel': 'Hạng Vàng',
        'tierColor': '#F59E0B',
        'nextTier': 'diamond',
        'nextTierLabel': 'Kim Cương',
        'pointsToNextTier': 9800,
        'spentToNextTier': 2500000,
        'progress': 0.52,
        'benefits': ['Giảm 10%', 'Freeship'],
        'discountPercent': 10,
      };

      final loyalty = LoyaltyProfile.fromMap(map);
      expect(loyalty.points, 5200);
      expect(loyalty.lifetimeSpent, 12500000);
      expect(loyalty.tier, 'gold');
      expect(loyalty.tierLabel, 'Hạng Vàng');
      expect(loyalty.discountPercent, 10);
      expect(loyalty.benefits.length, 2);
      expect(loyalty.parsedColor.toARGB32(), 0xFFF59E0B);
    });

    test('SkinProfile identifies allergies and skin types correctly', () {
      final safeMap = {
        'skinType': 'combination',
        'concerns': ['acne', 'pores'],
        'knownAllergies': ['Alcohol Denat', 'Fragrance'],
        'contraindications': ['Mang thai'],
        'currentRoutine': 'B5 + Niacinamide',
      };

      final profile = SkinProfile.fromMap(safeMap);
      expect(profile.skinType, 'combination');
      expect(profile.skinTypeLabel, 'Da Hỗn Hợp');
      expect(profile.hasAllergies, isTrue);
      expect(profile.knownAllergies, contains('Alcohol Denat'));
      expect(profile.contraindications, contains('Mang thai'));
    });

    test('CustomerListItem parses properly and detects VIP status', () {
      final itemMap = {
        'id': 'cust_001',
        'displayName': 'Nguyễn Thảo',
        'email': 'thao@example.com',
        'phone': '0901234567',
        'role': 'customer',
        'status': 'active',
        'tier': 'diamond',
        'tierLabel': 'Kim Cương',
        'tierColor': '#38BDF8',
        'points': 18000,
        'lifetimeSpent': 28500000,
        'skinType': 'oily',
        'knownAllergies': ['Retinol'],
        'hasAllergyWarning': true,
      };

      final item = CustomerListItem.fromMap(itemMap, 'cust_001');
      expect(item.id, 'cust_001');
      expect(item.displayName, 'Nguyễn Thảo');
      expect(item.initials, 'NT');
      expect(item.isVip, isTrue);
      expect(item.isActive, isTrue);
      expect(item.isSuspended, isFalse);
      expect(item.hasAllergyWarning, isTrue);
      expect(item.displayLifetimeSpent, '28.500.000 đ');
      expect(item.parsedTierColor.toARGB32(), 0xFF38BDF8);
    });

    test('CustomerKpiStats parses aggregation counts and average spend', () {
      final statsMap = {
        'totalCustomers': 120,
        'activeCustomers': 115,
        'suspendedCustomers': 5,
        'vipCustomers': 38,
        'averageSpend': 3450000,
        'tierBreakdown': {
          'bronze': 60,
          'silver': 22,
          'gold': 26,
          'diamond': 12,
        },
      };

      final stats = CustomerKpiStats.fromMap(statsMap);
      expect(stats.totalCustomers, 120);
      expect(stats.activeCustomers, 115);
      expect(stats.suspendedCustomers, 5);
      expect(stats.vipCustomers, 38);
      expect(stats.displayAverageSpend, '3.450.000 đ');
      expect(stats.tierBreakdown['gold'], 26);
    });

    test('Customer360Profile compiles full 360 data including treatments and orders', () {
      final profileMap = {
        'customerId': 'cust_999',
        'displayName': 'Lê Minh',
        'email': 'leminh@example.com',
        'phone': '0912345678',
        'status': 'active',
        'loyalty': {
          'points': 6500,
          'lifetimeSpent': 8200000,
          'tier': 'gold',
        },
        'skinProfile': {
          'skinType': 'sensitive',
          'knownAllergies': ['AHA'],
        },
        'metrics': {
          'totalOrders': 5,
          'totalBookings': 8,
          'noShowRate': 12,
        },
        'treatmentRecords': [
          {
            'id': 'rec_01',
            'serviceName': 'Trẻ hóa tế bào Lumi',
            'skinConditionBefore': 'Da khô đỏ',
            'skinReactionAfter': 'Dịu da, căng bóng',
            'treatmentStepsApplied': ['Làm sạch', 'Đi điện di tinh chất'],
          }
        ],
        'recentOrders': [
          {
            'orderId': 'LUMI - ABC123',
            'total': 850000,
            'status': 'completed',
          }
        ],
        'recentBookings': [
          {
            'id': 'bk_01',
            'serviceName': 'Trẻ hóa tế bào Lumi',
            'price': 1800000,
            'status': 'completed',
          }
        ],
      };

      final profile = Customer360Profile.fromMap(profileMap);
      expect(profile.customerId, 'cust_999');
      expect(profile.loyalty.tier, 'gold');
      expect(profile.skinProfile.skinType, 'sensitive');
      expect(profile.skinProfile.skinTypeLabel, 'Da Nhạy Cảm');
      expect(profile.treatmentRecords.length, 1);
      expect(profile.treatmentRecords.first.serviceName, 'Trẻ hóa tế bào Lumi');
      expect(profile.recentOrders.length, 1);
      expect(profile.recentBookings.length, 1);
    });
  });
}

