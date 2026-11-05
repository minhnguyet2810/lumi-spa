import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi_spa/features/admin/presentation/theme/admin_colors.dart';
import 'package:lumi_spa/features/admin/presentation/theme/admin_formatters.dart';

void main() {
  group('Adversarial Verification: AdminColors Token Integrity', () {
    test('cardShadow exists, is non-null, has valid elevation parameters', () {
      final cardShadow = AdminColors.cardShadow;
      expect(cardShadow, isNotNull);
      expect(cardShadow, isA<List<BoxShadow>>());
      expect(cardShadow.isNotEmpty, isTrue);

      final shadow = cardShadow.first;
      expect(shadow.blurRadius, equals(10.0));
      expect(shadow.offset, equals(const Offset(0, 4)));
      expect(shadow.color, equals(const Color(0x0F403735)));
      expect(shadow.color, isNot(equals(Colors.transparent)));
    });

    test('softShadow exists, is non-null, has valid elevation parameters', () {
      final softShadow = AdminColors.softShadow;
      expect(softShadow, isNotNull);
      expect(softShadow, isA<List<BoxShadow>>());
      expect(softShadow.isNotEmpty, isTrue);

      final shadow = softShadow.first;
      expect(shadow.blurRadius, equals(6.0));
      expect(shadow.offset, equals(const Offset(0, 2)));
      expect(shadow.color, equals(const Color(0x0A403735)));
      expect(shadow.color, isNot(equals(Colors.transparent)));
    });

    test('statusLowStock exists, is non-null, matches warning amber Color', () {
      const color = AdminColors.statusLowStock;
      expect(color, isNotNull);
      expect(color, isA<Color>());
      expect(color, equals(const Color(0xFFF59E0B)));
    });

    test('peachLight exists, is non-null, matches light peach pastel Color', () {
      const color = AdminColors.peachLight;
      expect(color, isNotNull);
      expect(color, isA<Color>());
      expect(color, equals(const Color(0xFFFDE8E1)));
    });

    test('borderSubtle exists, is non-null, matches subtle pastel border Color', () {
      const color = AdminColors.borderSubtle;
      expect(color, isNotNull);
      expect(color, isA<Color>());
      expect(color, equals(const Color(0xFFF3ECE6)));
    });

    test('verifies core spa nude pink palette token integrity', () {
      expect(AdminColors.background, equals(const Color(0xFFFFF8EF)));
      expect(AdminColors.cardSurface, equals(const Color(0xFFFFFFFF)));
      expect(AdminColors.sidebarBackground, equals(const Color(0xFFFAF2EB)));
      expect(AdminColors.border, equals(const Color(0xFFEADDD3)));
      expect(AdminColors.gold, equals(const Color(0xFFA5553E)));
      expect(AdminColors.textPrimary, equals(const Color(0xFF403735)));
      expect(AdminColors.textSecondary, equals(const Color(0xFF81726A)));
    });
  });

  group('Adversarial Verification: AdminFormatters Currency Edge Cases', () {
    test('formatCurrency handles zero (0, 0.0, -0)', () {
      expect(AdminFormatters.formatCurrency(0), equals('0 đ'));
      expect(AdminFormatters.formatCurrency(0.0), equals('0 đ'));
    });

    test('formatCurrency handles small positive numbers (< 1000)', () {
      expect(AdminFormatters.formatCurrency(1), equals('1 đ'));
      expect(AdminFormatters.formatCurrency(500), equals('500 đ'));
      expect(AdminFormatters.formatCurrency(999), equals('999 đ'));
    });

    test('formatCurrency handles standard thousand separators (dot formatting in vi_VN)', () {
      expect(AdminFormatters.formatCurrency(1000), equals('1.000 đ'));
      expect(AdminFormatters.formatCurrency(50000), equals('50.000 đ'));
      expect(AdminFormatters.formatCurrency(150000), equals('150.000 đ'));
      expect(AdminFormatters.formatCurrency(1000000), equals('1.000.000 đ'));
      expect(AdminFormatters.formatCurrency(15000000), equals('15.000.000 đ'));
    });

    test('formatCurrency handles extreme large numbers (billions, trillions)', () {
      expect(AdminFormatters.formatCurrency(1000000000), equals('1.000.000.000 đ'));
      expect(AdminFormatters.formatCurrency(1234567890123), equals('1.234.567.890.123 đ'));
    });

    test('formatCurrency handles negative values properly', () {
      expect(AdminFormatters.formatCurrency(-500), equals('-500 đ'));
      expect(AdminFormatters.formatCurrency(-150000), equals('-150.000 đ'));
      expect(AdminFormatters.formatCurrency(-1000000000), equals('-1.000.000.000 đ'));
    });

    test('formatCurrency handles floating point numbers gracefully', () {
      final formatted = AdminFormatters.formatCurrency(150000.5);
      expect(formatted.endsWith(' đ'), isTrue);
      expect(formatted.contains('150'), isTrue);
    });

    test('formatShortCurrency stress tests KPI abbreviations across tiers', () {
      expect(AdminFormatters.formatShortCurrency(0), equals('0 đ'));
      expect(AdminFormatters.formatShortCurrency(500), equals('500 đ'));
      expect(AdminFormatters.formatShortCurrency(1000), equals('1k đ'));
      expect(AdminFormatters.formatShortCurrency(50000), equals('50k đ'));
      expect(AdminFormatters.formatShortCurrency(1000000), equals('1tr đ'));
      expect(AdminFormatters.formatShortCurrency(1500000), equals('1.5tr đ'));
      expect(AdminFormatters.formatShortCurrency(1000000000), equals('1.0 tỷ đ'));
      expect(AdminFormatters.formatShortCurrency(2500000000), equals('2.5 tỷ đ'));
    });
  });

  group('Adversarial Verification: AdminFormatters Date & Weekday Edge Cases', () {
    test('formatDate handles leap year leap day (Feb 29)', () {
      final leapDay = DateTime(2024, 2, 29);
      expect(AdminFormatters.formatDate(leapDay), equals('29/02/2024'));
    });

    test('formatDate handles month boundary transitions', () {
      final endOfJan = DateTime(2026, 1, 31);
      final startOfFeb = DateTime(2026, 2, 1);
      final endOfFeb = DateTime(2026, 2, 28);
      final startOfMar = DateTime(2026, 3, 1);

      expect(AdminFormatters.formatDate(endOfJan), equals('31/01/2026'));
      expect(AdminFormatters.formatDate(startOfFeb), equals('01/02/2026'));
      expect(AdminFormatters.formatDate(endOfFeb), equals('28/02/2026'));
      expect(AdminFormatters.formatDate(startOfMar), equals('01/03/2026'));
    });

    test('formatDate handles year-end transitions (Dec 31 -> Jan 1)', () {
      final newYearsEve = DateTime(2026, 12, 31, 23, 59, 59);
      final newYearsDay = DateTime(2027, 1, 1, 0, 0, 0);

      expect(AdminFormatters.formatDate(newYearsEve), equals('31/12/2026'));
      expect(AdminFormatters.formatDate(newYearsDay), equals('01/01/2027'));
    });

    test('formatDateWithWeekday correctly maps all Vietnamese weekdays', () {
      // 2026-11-02 was Monday, up to 2026-11-08 Sunday
      final monday = DateTime(2026, 11, 2);
      final tuesday = DateTime(2026, 11, 3);
      final wednesday = DateTime(2026, 11, 4);
      final thursday = DateTime(2026, 11, 5);
      final friday = DateTime(2026, 11, 6);
      final saturday = DateTime(2026, 11, 7);
      final sunday = DateTime(2026, 11, 8);

      expect(AdminFormatters.formatDateWithWeekday(monday), equals('Thứ Hai, 02/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(tuesday), equals('Thứ Ba, 03/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(wednesday), equals('Thứ Tư, 04/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(thursday), equals('Thứ Năm, 05/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(friday), equals('Thứ Sáu, 06/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(saturday), equals('Thứ Bảy, 07/11/2026'));
      expect(AdminFormatters.formatDateWithWeekday(sunday), equals('Chủ Nhật, 08/11/2026'));
    });

    test('formatDateWithWeekday handles leap year and year transition dates', () {
      final leapDay = DateTime(2024, 2, 29); // Thursday
      expect(AdminFormatters.formatDateWithWeekday(leapDay), equals('Thứ Năm, 29/02/2024'));

      final newYearsEve = DateTime(2026, 12, 31); // Thursday
      expect(AdminFormatters.formatDateWithWeekday(newYearsEve), equals('Thứ Năm, 31/12/2026'));

      final newYearsDay = DateTime(2027, 1, 1); // Friday
      expect(AdminFormatters.formatDateWithWeekday(newYearsDay), equals('Thứ Sáu, 01/01/2027'));
    });

    test('formatDateTime and formatTime handle edge boundary times', () {
      final midnight = DateTime(2026, 11, 5, 0, 0);
      final morningWithSingleDigits = DateTime(2026, 11, 5, 9, 5);
      final noon = DateTime(2026, 11, 5, 12, 0);
      final evening = DateTime(2026, 11, 5, 23, 59);

      expect(AdminFormatters.formatTime(midnight), equals('00:00'));
      expect(AdminFormatters.formatTime(morningWithSingleDigits), equals('09:05'));
      expect(AdminFormatters.formatTime(noon), equals('12:00'));
      expect(AdminFormatters.formatTime(evening), equals('23:59'));

      expect(AdminFormatters.formatDateTime(midnight), equals('00:00 - 05/11/2026'));
      expect(AdminFormatters.formatDateTime(morningWithSingleDigits), equals('09:05 - 05/11/2026'));
    });
  });
}
