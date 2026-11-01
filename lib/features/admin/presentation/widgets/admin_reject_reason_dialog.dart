import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';

class AdminRejectReasonDialog extends StatefulWidget {
  const AdminRejectReasonDialog({super.key, required this.booking});

  final BookingItem booking;

  @override
  State<AdminRejectReasonDialog> createState() =>
      _AdminRejectReasonDialogState();
}

class _AdminRejectReasonDialogState extends State<AdminRejectReasonDialog> {
  final _reasonController = TextEditingController();

  static const _quickReasons = [
    'Khung giờ này đã kín phòng dịch vụ.',
    'Chuyên viên phụ trách bận đột xuất.',
    'Spa bảo trì thiết bị vào khung giờ này.',
    'Khách liên hệ yêu cầu dời lịch khác.',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LumiStyle.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Từ chối lịch hẹn',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: LumiStyle.plum,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn của khách: ${widget.booking.contactName} (${widget.booking.contactPhone})',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LumiStyle.plum,
              ),
            ),
            Text(
              'Dịch vụ: ${widget.booking.serviceName} - ${widget.booking.formattedDateTime}',
              style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn lý do từ chối nhanh:',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LumiStyle.plum,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((r) {
                return ActionChip(
                  label: Text(r, style: GoogleFonts.dmSans(fontSize: 11)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: LumiStyle.line),
                  onPressed: () {
                    _reasonController.text = r;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: GoogleFonts.dmSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nhập lý do gửi đến khách hàng...',
                hintStyle: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: LumiStyle.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: LumiStyle.line),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'HỦY BỎ',
            style: GoogleFonts.dmSans(
              color: LumiStyle.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(_reasonController.text.trim());
          },
          icon: const Icon(Icons.close_rounded, size: 16),
          label: Text(
            'XÁC NHẬN TỪ CHỐI',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

