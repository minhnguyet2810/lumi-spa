import 'package:flutter/material.dart';

/// Hệ thống lưới 8dp chuẩn UI/UX cho khoảng cách (Spacing) & bo góc (BorderRadius).
abstract final class AppSpacing {
  // ==========================================
  // SPACING VALUES (8dp Grid System)
  // ==========================================
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  // ==========================================
  // BORDER RADIUS TOKENS (12 - 16dp chuẩn hoá)
  // ==========================================
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // BorderRadius shapes
  static final BorderRadius roundedXs = BorderRadius.circular(radiusXs);
  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);

  // ==========================================
  // PRESET EDGE INSETS
  // ==========================================
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: 14);
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: md);

  // ==========================================
  // ELEVATION / SHADOW
  // ==========================================
  static List<BoxShadow> subtleShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> cardShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

