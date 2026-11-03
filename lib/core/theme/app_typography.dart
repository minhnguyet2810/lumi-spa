import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Hệ thống Typography trung tâm của LUMI SPA.
/// Sử dụng đồng nhất font Google Fonts 'Be Vietnam Pro' hỗ trợ 100% tiếng Việt
/// với phân tầng TextTheme Material 3 chuẩn xác.
abstract final class AppTypography {
  /// Tên định danh font chuẩn của toàn bộ hệ thống
  static const String fontFamily = 'BeVietnamPro';

  /// Tạo TextTheme chuẩn Material 3 sử dụng GoogleFonts.beVietnamPro
  static TextTheme createTextTheme({
    required Color primaryText,
    required Color secondaryText,
  }) {
    return TextTheme(
      // --- DISPLAY (Tiêu đề cực lớn, số liệu nổi bật) ---
      displayLarge: GoogleFonts.beVietnamPro(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.25,
        color: primaryText,
      ),
      displayMedium: GoogleFonts.beVietnamPro(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        height: 1.16,
        letterSpacing: 0,
        color: primaryText,
      ),
      displaySmall: GoogleFonts.beVietnamPro(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: 0,
        color: primaryText,
      ),

      // --- HEADLINE (Tiêu đề màn hình chính 24–32sp, w600–w700) ---
      headlineLarge: GoogleFonts.beVietnamPro(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: primaryText,
      ),
      headlineMedium: GoogleFonts.beVietnamPro(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
        color: primaryText,
      ),
      headlineSmall: GoogleFonts.beVietnamPro(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
        color: primaryText,
      ),

      // --- TITLE (AppBar, Tiêu đề Card, nhóm mục 16–22sp, w500–w600) ---
      titleLarge: GoogleFonts.beVietnamPro(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
        color: primaryText,
      ),
      titleMedium: GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.15,
        color: primaryText,
      ),
      titleSmall: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
        color: primaryText,
      ),

      // --- BODY (Nội dung văn bản, mô tả chi tiết 12–16sp, line-height 1.4–1.5) ---
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: primaryText,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
        color: secondaryText,
      ),
      bodySmall: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.4,
        color: secondaryText,
      ),

      // --- LABEL (Nút bấm, nhãn tag, gợi ý nhỏ 11–14sp, w500–w600) ---
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
        color: primaryText,
      ),
      labelMedium: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
        color: primaryText,
      ),
      labelSmall: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
        color: secondaryText,
      ),
    );
  }

  /// TextTheme chuẩn cho Light Mode
  static final TextTheme lightTextTheme = createTextTheme(
    primaryText: AppColors.lightTextPrimary,
    secondaryText: AppColors.lightTextSecondary,
  );

  /// TextTheme chuẩn cho Dark Mode (chữ sáng rõ nét đạt chuẩn WCAG)
  static final TextTheme darkTextTheme = createTextTheme(
    primaryText: AppColors.darkTextPrimary,
    secondaryText: AppColors.darkTextSecondary,
  );

  /// Helper tiện ích tạo nhanh TextStyle chuẩn font Be Vietnam Pro
  static TextStyle font({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height = 1.5,
    double? letterSpacing,
  }) =>
      GoogleFonts.beVietnamPro(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
