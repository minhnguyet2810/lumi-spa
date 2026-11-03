import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';

class AdminBookingDetailDialog extends StatelessWidget {
  const AdminBookingDetailDialog({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  final BookingItem booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiStyle.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết đơn đặt lịch',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              _row('Mã đơn:', booking.id),
              _row('Khách hàng:', booking.contactName),
              _row('Số điện thoại:', booking.contactPhone),
              _row('Dịch vụ:', booking.serviceName),
              _row('Thời gian hẹn:', booking.formattedDateTime),
              _row('Thời lượng:', '${booking.durationMinutes} phút'),
              _row('Tổng chi phí:', booking.formattedPrice),
              _row('Trạng thái:', booking.statusLabel),
              if (booking.roomId != null)
                _row('Phòng phục vụ:', booking.roomId!),
              if (booking.staffId != null)
                _row('KTV phục vụ:', booking.staffId!),
              const SizedBox(height: 20),
              if (booking.status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onReject();
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          'TỪ CHỐI',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onApprove();
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text(
                          'DUYỆT ĐƠN',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: LumiStyle.rose,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: LumiStyle.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: LumiStyle.plum,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
