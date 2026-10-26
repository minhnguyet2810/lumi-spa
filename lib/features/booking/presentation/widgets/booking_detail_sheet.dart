import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../data/models/booking_item.dart';

class BookingDetailSheet extends StatelessWidget {
  final BookingItem booking;
  final VoidCallback? onCancel;

  const BookingDetailSheet({
    super.key,
    required this.booking,
    this.onCancel,
  });

  static const ivory = LumiStyle.ivory;
  static const plum = LumiStyle.plum;
  static const rose = LumiStyle.rose;
  static const blush = LumiStyle.softPink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: plum.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết lịch hẹn',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: plum,
                ),
              ),
              _statusBadge(booking),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFE8E8)),
            ),
            child: Column(
              children: [
                _row('Mã lịch hẹn:', '#${booking.id}'),
                const Divider(height: 20),
                _row('Dịch vụ:', booking.serviceName),
                const Divider(height: 20),
                _row('Thời gian:', booking.formattedDateTime),
                const Divider(height: 20),
                _row('Thời lượng:', '${booking.durationMinutes} phút'),
                const Divider(height: 20),
                _row('Giá dịch vụ:', booking.formattedPrice),
                const Divider(height: 20),
                _row('Khách hàng:', booking.contactName),
                const Divider(height: 20),
                _row('Số điện thoại:', booking.contactPhone),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (booking.isCancellable && onCancel != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: Text(
                  'HỦY LỊCH HẸN NÀY',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: plum.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: plum,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(BookingItem item) {
    Color bg;
    Color fg;
    switch (item.status) {
      case 'confirmed':
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF137333);
        break;
      case 'cancelled':
        bg = const Color(0xFFFCE8E6);
        fg = const Color(0xFFC5221F);
        break;
      case 'completed':
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF1A73E8);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF7E0);
        fg = const Color(0xFFB06000);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.statusLabel,
        style: GoogleFonts.dmSans(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
