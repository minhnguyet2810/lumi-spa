import 'package:flutter/material.dart';

/// Bảng màu chuyên dụng cho Cổng quản trị LUMI SPA Admin Portal
/// Đồng bộ hoàn toàn theo tông Hồng Phấn / Kem Nude Spa của Trang Tổng Quan.
/// Loại bỏ toàn bộ nền tối, chuyển sang hệ màu sáng sủa, thanh lịch, sang trọng chuẩn ngành làm đẹp.
abstract final class AdminColors {
  // Backgrounds & Surfaces (Tông hồng phấn / kem nude nhạt của trang Tổng quan)
  static const Color background = Color(0xFFFFF8EF); // Signature Ivory
  static const Color deepTeal = Color(0xFFFBE4D6); // Peach ấm
  static const Color darkTeal = deepTeal;
  static const Color slateTeal = Color(0xFFFDF6F0); // Kem hồng sáng
  static const Color cardSurface = Color(0xFFFFFFFF); // Trắng sáng tinh khiết
  static const Color elevatedSurface = Color(0xFFFBEADB); // Hồng phấn nâng cao
  static const Color sidebarBackground = Color(0xFFFAF2EB); // Nền thanh menu dọc bên trái
  static const Color border = Color(0xFFEADDD3); // Viền mờ màu kem hồng pastel
  static const Color borderSubtle = Color(0xFFF3ECE6); // ultra-soft pastel border
  static const Color peachLight = Color(0xFFFDE8E1); // soft peach background

  // Brand Accents (Hồng đất / Hồng trà ấm Rose Gold / Dusty Pink)
  static const Color primary = Color(0xFFA5553E); // Primary Brand Rose
  static const Color goldAccent = Color(0xFFA5553E); // Điểm nhấn chính
  static const Color gold = goldAccent;
  static const Color softGold = Color(0xFF894A36); // Hồng trà sẫm
  static const Color peach = Color(0xFFFBE4D6); // Phấn đào
  static const Color emerald = Color(0xFF10B981); // Xanh ngọc hoàn tất
  static const Color cyan = Color(0xFF3B82F6); // Xanh lam điều hướng

  // Typography Colors (Tông màu nâu ấm / xám sẫm trầm tính)
  static const Color textPrimary = Color(0xFF403735); // Nâu ấm sắc nét
  static const Color textSecondary = Color(0xFF81726A); // Nâu xám sẫm
  static const Color textMuted = Color(0xFF9E8E87); // Chữ phụ mờ nhạt

  // Status Lifecycle Badges
  static const Color statusPending = Color(0xFFD97706); // Chờ duyệt / tiếp nhận
  static const Color statusConfirmed = Color(0xFF2563EB); // Đã xác nhận
  static const Color statusPackaging = Color(0xFF3B82F6); // Đang đóng gói
  static const Color statusShipping = Color(0xFF7C3AED); // Đang vận chuyển
  static const Color statusCompleted = Color(0xFF10B981); // Đã hoàn tất
  static const Color statusCancelled = Color(0xFFEF4444); // Đã hủy
  static const Color statusLowStock = Color(0xFFF59E0B); // warning amber

  // Elevation & Shadows
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F403735),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x0A403735),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];
}
