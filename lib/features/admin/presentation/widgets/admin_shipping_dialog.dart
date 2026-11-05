import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_colors.dart';

class AdminShippingDialog extends StatefulWidget {
  final String orderId;

  const AdminShippingDialog({super.key, required this.orderId});

  @override
  State<AdminShippingDialog> createState() => _AdminShippingDialogState();
}

class _AdminShippingDialogState extends State<AdminShippingDialog> {
  final _trackingController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCarrier = 'Giao Hàng Tiết Kiệm (GHTK)';

  final List<String> _carriers = [
    'Giao Hàng Tiết Kiệm (GHTK)',
    'Giao Hàng Nhanh (GHN)',
    'Viettel Post',
    'Ahamove / GrabExpress',
    'Shipper nội bộ LUMI',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.statusShipping.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AdminColors.statusShipping,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xuất kho & Vận chuyển',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Đơn hàng: #${widget.orderId}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Đơn vị vận chuyển',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AdminColors.deepTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCarrier,
                  isExpanded: true,
                  dropdownColor: AdminColors.cardSurface,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AdminColors.textSecondary),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AdminColors.textPrimary,
                  ),
                  items: _carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCarrier = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Mã vận đơn (Tracking Number)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _trackingController,
              style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'VD: GHTK10982348VN',
                hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AdminColors.deepTeal,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.emerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ghi chú bưu tá / giao hàng',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Hàng dễ vỡ, liên hệ khách trước khi giao...',
                hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AdminColors.deepTeal,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.emerald, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'HỦY',
                    style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    final tracking = _trackingController.text.trim();
                    Navigator.of(context).pop({
                      'carrier': _selectedCarrier,
                      'trackingNumber': tracking.isNotEmpty ? tracking : null,
                      'note': _noteController.text.trim(),
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.statusShipping,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'XÁC NHẬN GIAO HÀNG',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
