import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/presentation/theme/admin_colors.dart';

void main() {
  group('AdminColors Design Tokens Tests', () {
    test('verifies all 5 required design tokens are correctly configured', () {
      // 1. cardShadow
      final cardShadow = AdminColors.cardShadow;
      expect(cardShadow, isNotEmpty);
      expect(cardShadow.first.blurRadius, equals(10));
      expect(cardShadow.first.offset, equals(const Offset(0, 4)));
      expect(cardShadow.first.color, equals(const Color(0x0F403735)));

      // 2. softShadow
      final softShadow = AdminColors.softShadow;
      expect(softShadow, isNotEmpty);
      expect(softShadow.first.blurRadius, equals(6));
      expect(softShadow.first.offset, equals(const Offset(0, 2)));
      expect(softShadow.first.color, equals(const Color(0x0A403735)));

      // 3. statusLowStock
      expect(AdminColors.statusLowStock, equals(const Color(0xFFF59E0B)));

      // 4. peachLight
      expect(AdminColors.peachLight, equals(const Color(0xFFFDE8E1)));

      // 5. borderSubtle
      expect(AdminColors.borderSubtle, equals(const Color(0xFFF3ECE6)));
    });

    test('verifies core spa nude pink theme palette constants', () {
      expect(AdminColors.background, equals(const Color(0xFFFFF8EF)));
      expect(AdminColors.cardSurface, equals(const Color(0xFFFFFFFF)));
      expect(AdminColors.sidebarBackground, equals(const Color(0xFFFAF2EB)));
      expect(AdminColors.border, equals(const Color(0xFFEADDD3)));
      expect(AdminColors.gold, equals(const Color(0xFFA5553E)));
      expect(AdminColors.textPrimary, equals(const Color(0xFF403735)));
    });
  });
}
