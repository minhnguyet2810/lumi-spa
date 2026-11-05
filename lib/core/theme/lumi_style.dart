import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme.dart';
import 'app_typography.dart';
import 'lumi_adaptive.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_theme.dart';
export 'app_typography.dart';

/// LUMI Style & Design System facade.
/// Cung cấp các hằng số màu sắc, khoảng cách và Typography chuẩn hoá 'Be Vietnam Pro'
/// tương thích hoàn toàn với các màn hình hiện hữu.
abstract final class LumiStyle {
  // Brand color tokens
  static const ivory = AppColors.warmCream;
  static const plum = Color(0xFF403735);
  static const rose = AppColors.dustyRose;
  static const muted = Color(0xFF756863);

  // Brand accents
  static const dustyRose = AppColors.dustyRose;
  static const softPink = AppColors.softPink;
  static const mutedBlue = AppColors.mutedBlue;
  static const aquaBlue = AppColors.aquaBlue;
  static const peach = AppColors.peach;

  // Supporting surfaces and borders
  static const canvas = ivory;
  static const surface = AppColors.lightSurface;
  static const blushSurface = AppColors.lightSurfaceHighlight;
  static const blueSurface = AppColors.lightSurfaceBlue;
  static const line = AppColors.lightOutlineVariant;
  static const ink = AppColors.lightTextPrimary;

  // Spacing & Radius (8dp grid system)
  static const double radiusSmall = AppSpacing.radiusSm;
  static const double radiusMedium = AppSpacing.radiusLg;
  static const double radiusLarge = AppSpacing.radiusXl;
  static const double screenPadding = AppSpacing.lg;

  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionNormal = Duration(milliseconds: 320);
  static const Duration motionSlow = Duration(milliseconds: 520);
  static const Curve motionCurve = Curves.easeInOutCubic;

  // Typography sử dụng đồng nhất Be Vietnam Pro (chuẩn tiếng Việt không lỗi dấu)
  static TextStyle heading({double size = 48, Color color = plum}) =>
      AppTypography.font(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body({double size = 16, Color color = muted}) =>
      AppTypography.font(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle label({double size = 14, Color color = plum}) =>
      AppTypography.font(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );

  /// Single Source of Truth cho Theme hệ thống
  static ThemeData get darkTheme => AppTheme.dark;
  static ThemeData get theme => AppTheme.light;
}

/// Compatible with existing `LumiButton(label:, onPressed:, light:)` calls.
class LumiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool light;

  const LumiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = light ? colors.onSurface : colors.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: light ? colors.surface : colors.primary,
          foregroundColor: foreground,
          elevation: light ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: light ? BorderSide(color: colors.outlineVariant) : BorderSide.none,
          ),
        ),
        child: Text(
          LumiAdaptive.text(label),
          style: AppTypography.font(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
