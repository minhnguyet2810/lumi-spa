import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_order_item.dart';

class AdminOrderCancelDialog extends StatefulWidget {
  const AdminOrderCancelDialog({super.key, required this.order});

  final AdminOrderItem order;

  @override
  State<AdminOrderCancelDialog> createState() => _AdminOrderCancelDialogState();
}

class _AdminOrderCancelDialogState extends State<AdminOrderCancelDialog> {
  final _reasonController = TextEditingController();
  String? _selectedQuickReason;

  static const List<String> _quickReasons = [
    'Sản phẩm tạm thời hết hàng tại kho',
    'Khách hàng chủ động yêu cầu hủy',
    'Không liên lạc được số điện thoại nhận hàng',
    'Địa chỉ giao hàng không hợp lệ / Ngoài vùng phục vụ',
    'Phát hiện trùng lặp đơn hàng',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiStyle.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hủy Đơn Hàng',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: LumiStyle.plum,
                          ),
                        ),
                        Text(
                          'Mã đơn: #${widget.order.id} · ${widget.order.customerName}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: LumiStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Lý do hủy đơn (sẽ được gửi qua Gmail và Thông báo cho khách):',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LumiStyle.plum,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickReasons.map((r) {
                  final isSelected = _selectedQuickReason == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedQuickReason = null;
                          _reasonController.clear();
                        } else {
                          _selectedQuickReason = r;
                          _reasonController.text = r;
                        }
                      });
                    },
                    selectedColor: Colors.red.shade100,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.red.shade700 : LumiStyle.line,
                    ),
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isSelected ? Colors.red.shade900 : LumiStyle.plum,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.plum),
                decoration: InputDecoration(
                  hintText:
                      'Nhập lý do cụ thể hoặc ghi chú thêm cho khách hàng...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: LumiStyle.muted,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: LumiStyle.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: LumiStyle.line),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'QUAY LẠI',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: LumiStyle.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      final reason = _reasonController.text.trim();
                      Navigator.of(context).pop(
                        reason.isNotEmpty
                            ? reason
                            : 'Đơn hàng bị hủy bởi Quản trị viên LUMI SPA',
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'XÁC NHẬN HỦY',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
