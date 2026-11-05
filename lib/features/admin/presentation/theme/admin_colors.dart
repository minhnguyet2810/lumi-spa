import 'package:flutter/material.dart';

/// Bảng màu chuyên dụng cho Cổng quản trị LUMI SPA Admin Portal.
/// Đồng bộ 100% theo tông Hồng Phấn / Kem Nude Spa của Trang Tổng Quan.
/// Loại bỏ hoàn toàn nền xanh đen sẫm, đưa về phong cách sang trọng, sáng sủa, thanh lịch.
abstract final class AdminColors {
  // Backgrounds & Surfaces (Tông hồng phấn / kem nude nhạt của trang Tổng quan)
  static const Color background = Color(0xFFFFF8EF); // LUMI Signature Warm Ivory
  static const Color sidebarBackground = Color(0xFFFAF2EB); // Nền thanh menu dọc bên trái
  static const Color cardSurface = Color(0xFFFFFFFF); // Trắng sáng tinh khiết
  static const Color elevatedSurface = Color(0xFFFDF6F0); // Kem hồng sáng
  static const Color border = Color(0xFFEADDD3); // Viền mờ màu kem hồng pastel
  static const Color borderSubtle = Color(0xFFF3ECE4); // Viền siêu mờ cho bảng dữ liệu

  // Aliases cho các thành phần cũ (đảm bảo không còn màu xanh sẫm)
  static const Color deepTeal = Color(0xFFFBE4D6); // Thay thế hoàn toàn xanh đen bằng Peach ấm
  static const Color darkTeal = Color(0xFFFFFFFF); // Thay thế hoàn toàn bằng cardSurface trắng
  static const Color slateTeal = Color(0xFFFDF6F0); // Thay thế bằng kem hồng sáng

  // Brand Accents (Hồng đất / Hồng trà ấm Rose Gold / Dusty Pink)
  static const Color primary = Color(0xFFA5553E); // Primary Brand Dusty Rose
  static const Color goldAccent = Color(0xFFA5553E); // Điểm nhấn chính
  static const Color gold = goldAccent; // Alias
  static const Color softGold = Color(0xFF894A36); // Hồng trà sẫm
  static const Color peach = Color(0xFFFBE4D6); // Phấn đào thanh thoát
  static const Color peachLight = Color(0xFFFFF2EB); // Phấn đào nhạt cho hover
  static const Color emerald = Color(0xFF10B981); // Xanh ngọc hoàn tất
  static const Color cyan = Color(0xFF3B82F6); // Xanh lam điều hướng

  // Typography Colors (Tông màu nâu ấm / xám sẫm trầm tính - không dùng chữ đen tương phản gắt)
  static const Color textPrimary = Color(0xFF403735); // Nâu ấm sắc nét
  static const Color textSecondary = Color(0xFF81726A); // Nâu xám sẫm
  static const Color textMuted = Color(0xFF9E8E87); // Chữ phụ mờ nhạt

  // Status Lifecycle Badges
  static const Color statusPending = Color(0xFFD97706); // Chờ tiếp nhận / chờ duyệt
  static const Color statusConfirmed = Color(0xFF2563EB); // Đã xác nhận
  static const Color statusPackaging = Color(0xFF3B82F6); // Đang đóng gói
  static const Color statusShipping = Color(0xFF7C3AED); // Đang giao
  static const Color statusInService = Color(0xFF8B5CF6); // Đang phục vụ tại phòng
  static const Color statusCompleted = Color(0xFF10B981); // Đã hoàn tất
  static const Color statusCancelled = Color(0xFFEF4444); // Đã hủy
  static const Color statusLowStock = Color(0xFFEA580C); // Cảnh báo sắp hết hàng

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFFA5553E).withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF403735).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
