import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Single Source of Truth cho toàn bộ Theme hệ thống LUMI SPA (Material 3).
abstract final class AppTheme {
  // ==========================================
  // LIGHT THEME CONFIGURATION
  // ==========================================
  static ThemeData get light {
    const colors = AppColors.lightColorScheme;
    final textTheme = AppTypography.lightTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,

      // --- APP BAR THEME ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // --- CARD THEME (Bo góc 16dp, Border tinh tế) ---
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),

      // --- FILLED BUTTON THEME ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- ELEVATED BUTTON THEME ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.peach,
          foregroundColor: colors.onSurface,
          elevation: 1,
          shadowColor: colors.shadow,
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- OUTLINED BUTTON THEME ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          side: BorderSide(color: colors.outline, width: 1.2),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- INPUT DECORATION THEME (Bo góc 14-16dp) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.error, width: 1.2),
        ),
      ),

      // --- CHIP THEME ---
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedFull,
        ),
        labelStyle: textTheme.labelMedium,
      ),

      // --- DIVIDER THEME ---
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // --- BOTTOM SHEET THEME ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // ==========================================
  // DARK THEME CONFIGURATION (Chuẩn WCAG cao cấp)
  // Nền tối than sâu (#0F172A), chữ sáng nét (#F8FAFC, #94A3B8)
  // ==========================================
  static ThemeData get dark {
    const colors = AppColors.darkColorScheme;
    final textTheme = AppTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,

      // --- APP BAR THEME ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // --- CARD THEME (Bo góc 16dp, Dark Surface nổi bật) ---
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: BorderSide(color: colors.outline, width: 1),
        ),
      ),

      // --- FILLED BUTTON THEME ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- ELEVATED BUTTON THEME ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- OUTLINED BUTTON THEME ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          minimumSize: const Size(48, 52),
          padding: AppSpacing.buttonPadding,
          side: BorderSide(color: colors.outlineVariant, width: 1.2),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),

      // --- INPUT DECORATION THEME (Bo góc 14-16dp) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: colors.error, width: 1.2),
        ),
      ),

      // --- CHIP THEME ---
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedFull,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurface,
        ),
      ),

      // --- DIVIDER THEME ---
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),

      // --- BOTTOM SHEET THEME ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

