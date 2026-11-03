import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_adaptive.dart';

abstract final class LumiOrderUi {
  static Widget panel(BuildContext context, Widget child, {bool hero = false}) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: hero ? null : colors.surface,
        gradient: hero
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xFF604A3D), const Color(0xFF344E5B)]
                    : [
                        const Color(0xFFF8D5C2),
                        const Color(0xFFF3E7D9),
                        const Color(0xFFDCECF1),
                      ],
              )
            : null,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: dark ? 0.04 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget badge(BuildContext context, String status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = switch (status) {
      'Đã giao' => dark ? const Color(0xFFBBD8AF) : const Color(0xFF416B3D),
      'Đã xác nhận' ||
      'Đã duyệt' ||
      'Đang giao' => dark ? const Color(0xFFADD5E8) : const Color(0xFF365F75),
      'Đã hủy' => dark ? const Color(0xFFF4BAAE) : const Color(0xFF9D4537),
      _ => dark ? const Color(0xFFF5C49D) : const Color(0xFF8A542A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        LumiAdaptive.text(status),
        style: GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: tint,
        ),
      ),
    );
  }

  static Widget row(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colors = Theme.of(context).colorScheme;
            final left = Text(
              LumiAdaptive.text(label),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
            );
            final right = Text(
              LumiAdaptive.text(value.isEmpty ? 'Chưa cập nhật' : value),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                height: 1.5,
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            );
            if (constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(16) > 21) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 5), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: left),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Align(alignment: Alignment.centerRight, child: right),
                ),
              ],
            );
          },
        ),
      );
  static Widget title(BuildContext context, String label, IconData icon) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 23,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          LumiAdaptive.text(label),
          style: GoogleFonts.dmSans(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ],
  );
}
