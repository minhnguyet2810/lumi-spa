import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';

class AdminBookingCard extends StatelessWidget {
  const AdminBookingCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    required this.onTapDetail,
  });

  final BookingItem booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTapDetail;

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'pending';
    final isApproved =
        booking.status == 'approved' || booking.status == 'confirmed';
    final isRejected =
        booking.status == 'rejected' || booking.status == 'cancelled';

    Color badgeBg;
    Color badgeText;
    String badgeTitle = booking.statusLabel;

    if (isPending) {
      badgeBg = Colors.amber.shade50;
      badgeText = Colors.amber.shade900;
      badgeTitle = 'Chờ duyệt';
    } else if (isApproved) {
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade800;
      badgeTitle = 'Đã duyệt';
    } else if (isRejected) {
      badgeBg = Colors.red.shade50;
      badgeText = Colors.red.shade800;
      badgeTitle = 'Từ chối';
    } else {
      badgeBg = LumiStyle.blushSurface;
      badgeText = LumiStyle.plum;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumiStyle.line),
        boxShadow: [
          BoxShadow(
            color: LumiStyle.plum.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTapDetail,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Mã đơn & Badge trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: LumiStyle.blushSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: LumiStyle.rose,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MÃ: #${booking.id.length > 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase()}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: LumiStyle.plum,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badgeText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badgeTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Hàng 2: Tên khách hàng & Số điện thoại
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: LumiStyle.rose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.contactName.isNotEmpty
                            ? booking.contactName
                            : 'Khách hàng LUMI',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LumiStyle.plum,
                        ),
                      ),
                    ),
                    if (booking.contactPhone.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: LumiStyle.ivory,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.contactPhone,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LumiStyle.plum,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Hàng 3: Dịch vụ & Thời gian hẹn
                Row(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      size: 18,
                      color: LumiStyle.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: LumiStyle.plum,
                        ),
                      ),
                    ),
                    Text(
                      booking.formattedPrice,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.rose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Hàng 4: Thời gian đặt hẹn
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: LumiStyle.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.formattedDateTime,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: LumiStyle.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${booking.durationMinutes} phút)',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: LumiStyle.muted,
                      ),
                    ),
                  ],
                ),

                // Hàng 5: Nút hành động Duyệt / Từ chối (Nếu là đơn Pending)
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(
                            'TỪ CHỐI',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            'DUYỆT ĐƠN',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: LumiStyle.rose,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
