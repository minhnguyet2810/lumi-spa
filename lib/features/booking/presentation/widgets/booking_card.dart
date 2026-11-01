import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../data/models/booking_item.dart';

class BookingCard extends StatelessWidget {
  final BookingItem booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  static const plum = LumiStyle.plum;
  static const rose = LumiStyle.rose;
  static const blush = LumiStyle.softPink;

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumiAdaptive.color(const Color(0xFFF0E5E7))),
        boxShadow: [
          BoxShadow(
            color: LumiAdaptive.color(
              plum.withValues(alpha: 0.04),
              surface: true,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LumiAdaptive.color(
                        blush.withValues(alpha: 0.4),
                        surface: true,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.spa_outlined,
                      color: LumiAdaptive.color(rose),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LumiAdaptive.text(booking.serviceName),
                          style: LumiAdaptive.style(
                            GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(plum),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LumiAdaptive.text(
                            '${booking.durationMinutes} phút · ${booking.formattedPrice}',
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 12,
                              color: LumiAdaptive.color(
                                plum.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(booking),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: LumiAdaptive.color(Color(0xFFF4EBEC), surface: true),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: LumiAdaptive.color(rose),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LumiAdaptive.text(booking.formattedDateTime),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LumiAdaptive.color(plum),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onTap,
                        style: LumiAdaptive.style(
                          TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        child: Text(
                          LumiAdaptive.text('Chi tiết'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(rose),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      if (booking.isCancellable && onCancel != null) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: onCancel,
                          style: LumiAdaptive.style(
                            TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: LumiAdaptive.color(
                                Colors.red.shade600,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          child: Text(
                            LumiAdaptive.text('Hủy lịch'),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BookingItem item) {
    Color bg;
    Color fg;
    switch (item.status) {
      case 'confirmed':
      case 'approved':
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF137333);
        break;
      case 'cancelled':
      case 'rejected':
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(bg, surface: true),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        LumiAdaptive.text(item.statusLabel),
        style: LumiAdaptive.style(
          GoogleFonts.dmSans(
            color: LumiAdaptive.color(fg),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
