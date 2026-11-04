import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_user_item.dart';

class AdminUserDetailDialog extends StatelessWidget {
  const AdminUserDetailDialog({super.key, required this.user});

  final AdminUserItem user;

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiStyle.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: LumiStyle.plum,
                    backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Text(
                            user.initials,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: LumiStyle.plum,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: user.roleBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: user.roleColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                user.roleLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: user.roleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${user.id}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: LumiStyle.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: LumiStyle.line),
              const SizedBox(height: 16),

              // Thông tin liên hệ
              Text(
                'THÔNG TIN LIÊN HỆ',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: LumiStyle.muted,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email.isNotEmpty ? user.email : 'Chưa có email',
                onCopy: user.email.isNotEmpty ? () => _copy(context, user.email, 'Email') : null,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                onCopy: user.phone.isNotEmpty ? () => _copy(context, user.phone, 'Số điện thoại') : null,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày tham gia',
                value: user.formattedCreatedAt,
              ),
              const SizedBox(height: 20),

              // Thống kê hoạt động
              Text(
                'HOẠT ĐỘNG TẠI LUMI SPA',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: LumiStyle.muted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatBox(
                    label: 'Lịch hẹn Spa',
                    value: '${user.bookingCount}',
                    icon: Icons.calendar_month_outlined,
                    color: LumiStyle.rose,
                  ),
                  const SizedBox(width: 12),
                  _buildStatBox(
                    label: 'Đơn mua hàng',
                    value: '${user.orderCount}',
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 12),
                  _buildStatBox(
                    label: 'Tổng chi tiêu',
                    value: user.displayTotalSpent,
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nút đóng
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(backgroundColor: LumiStyle.plum),
                  child: Text('Đóng', style: GoogleFonts.dmSans()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: LumiStyle.muted),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LumiStyle.plum,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Sao chép',
            icon: const Icon(Icons.copy_rounded, size: 16, color: LumiStyle.rose),
            onPressed: onCopy,
          ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LumiStyle.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LumiStyle.plum,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, color: LumiStyle.muted),
            ),
          ],
        ),
      ),
    );
  }
}

