import 'package:flutter/material.dart';

/// Bảng màu chuyên dụng cho Cổng quản trị LUMI SPA Admin Portal
/// Chuẩn Dark-Mode Deep Teal / Slate (#0D3B35, #0E3E37)
abstract final class AdminColors {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF08201D);
  static const Color deepTeal = Color(0xFF0D3B35);
  static const Color darkTeal = deepTeal;
  static const Color slateTeal = Color(0xFF0E3E37);
  static const Color cardSurface = Color(0xFF134842);
  static const Color elevatedSurface = Color(0xFF175750);
  static const Color border = Color(0xFF1D6860);

  // Brand Accents
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color gold = goldAccent;
  static const Color softGold = Color(0xFFF1D888);
  static const Color emerald = Color(0xFF20C997);
  static const Color cyan = Color(0xFF17A2B8);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF2F7F6);
  static const Color textSecondary = Color(0xFFA2BEBB);
  static const Color textMuted = Color(0xFF709490);

  // Status Lifecycle Badges
  static const Color statusPending = Color(0xFFF39C12);
  static const Color statusConfirmed = Color(0xFF2ECC71);
  static const Color statusPackaging = Color(0xFF3498DB);
  static const Color statusShipping = Color(0xFF9B59B6);
  static const Color statusCompleted = Color(0xFF1ABC9C);
  static const Color statusCancelled = Color(0xFFE74C3C);
}

