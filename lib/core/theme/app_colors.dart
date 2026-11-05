import 'package:flutter/material.dart';

/// Bảng màu trung tâm chuẩn WCAG cho LUMI SPA.
/// Thiết lập Single Source of Truth cho cả Light Mode và Dark Mode.
abstract final class AppColors {
  // ==========================================
  // BRAND COLOR TOKENS
  // ==========================================
  static const dustyRose = Color(0xFFA5553E); // Primary Brand Rose
  static const peach = Color(0xFFF5BEA5); // Luminous Peach Accent
  static const softPink = Color(0xFFF8D5C2); // Soft Blush
  static const mutedBlue = Color(0xFF557C90); // Ocean Slate
  static const aquaBlue = Color(0xFFA9CEDD); // Sky Aqua
  static const warmCream = Color(0xFFFFF8EF); // Signature Ivory

  // ==========================================
  // LIGHT MODE PALETTE (LUMI Ivory & Warm Plum)
  // ==========================================
  static const lightBackground = Color(0xFFFFF8EF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFFBF4F5);
  static const lightSurfaceHighlight = Color(0xFFFBE7DC);
  static const lightSurfaceBlue = Color(0xFFEAF3F7);
  static const lightOutline = Color(0xFFE2E8F0);
  static const lightOutlineVariant = Color(0xFFEADFD5);

  static const lightTextPrimary = Color(0xFF1E293B); // Slate 800: deep contrast
  static const lightTextSecondary = Color(0xFF64748B); // Slate 500: readable secondary
  static const lightTextTertiary = Color(0xFF94A3B8); // Slate 400
  static const lightTextBrand = dustyRose;

  // ==========================================
  // DARK MODE PALETTE (Charcoal Slate & Crisp Bright Text)
  // Chuẩn WCAG AA/AAA: Không bao giờ dùng xám tối gây chìm chữ
  // ==========================================
  static const darkBackground = Color(0xFF0F172A); // Slate 900: deep night
  static const darkSurface = Color(0xFF1E293B); // Slate 800: elevated card
  static const darkSurfaceContainer = Color(0xFF263345); // Elevated container
  static const darkSurfaceHighlight = Color(0xFF334155); // Slate 700: interactive hover
  static const darkOutline = Color(0xFF334155); // Slate 700
  static const darkOutlineVariant = Color(0xFF475569); // Slate 600

  static const darkTextPrimary = Color(0xFFF8FAFC); // Slate 50: sáng nét 100%
  static const darkTextSecondary = Color(0xFF94A3B8); // Slate 400: xám sáng rõ ràng
  static const darkTextTertiary = Color(0xFFCBD5E1); // Slate 300: nhãn phụ
  static const darkTextBrand = peach; // Sáng bừng trên nền tối

  // ==========================================
  // SEMANTIC STATUS TOKENS
  // ==========================================
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);
  static const errorDark = Color(0xFFF87171);
  static const info = Color(0xFF3B82F6);
  static const infoDark = Color(0xFF60A5FA);

  // ==========================================
  // COLOR SCHEMES (Material 3)
  // ==========================================
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: dustyRose,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDBCF),
    onPrimaryContainer: Color(0xFF380C03),
    secondary: mutedBlue,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: aquaBlue,
    onSecondaryContainer: Color(0xFF082E3F),
    tertiary: Color(0xFF936952),
    onTertiary: Color(0xFFFFFFFF),
    error: error,
    onError: Color(0xFFFFFFFF),
    surface: lightSurface,
    onSurface: lightTextPrimary,
    onSurfaceVariant: lightTextSecondary,
    outline: lightOutline,
    outlineVariant: lightOutlineVariant,
    shadow: Color(0x1A000000),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: peach,
    onPrimary: Color(0xFF40271D),
    primaryContainer: Color(0xFF56392F),
    onPrimaryContainer: Color(0xFFFFE5D6),
    secondary: aquaBlue,
    onSecondary: Color(0xFF0C2B38),
    secondaryContainer: Color(0xFF1F3A47),
    onSecondaryContainer: Color(0xFFDCEFF7),
    tertiary: Color(0xFFD4B09C),
    onTertiary: Color(0xFF372215),
    error: errorDark,
    onError: Color(0xFF450A0A),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    onSurfaceVariant: darkTextSecondary,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    shadow: Color(0x33000000),
  );
}

