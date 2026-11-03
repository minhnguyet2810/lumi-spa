import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_order_item.dart';

class AdminOrderDetailDialog extends StatelessWidget {
  const AdminOrderDetailDialog({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  final AdminOrderItem order;
  final void Function(String newStatus, {String? reason}) onUpdateStatus;

  String _formatVND(num amount) {
    final p = amount.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$p đ';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiStyle.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LumiStyle.blushSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: LumiStyle.rose,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Đơn Hàng #${order.id}',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: LumiStyle.plum,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: order.statusColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: order.statusColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                order.statusLabel.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: order.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian đặt: ${order.formattedCreatedAt}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: LumiStyle.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: LumiStyle.muted),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const Divider(height: 24, color: LumiStyle.line),

              // Scrollable content
              Expanded(
                child: ListView(
                  children: [
                    // Thông tin khách hàng & Giao hàng
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LumiStyle.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THÔNG TIN NGƯỜI NHẬN',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: LumiStyle.rose,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _infoRow(
                            Icons.person_outline,
                            'Khách hàng',
                            order.customerName,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.phone_outlined,
                            'Số điện thoại',
                            order.phone.isNotEmpty
                                ? order.phone
                                : 'Chưa cập nhật',
                          ),
                          if (order.customerEmail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.mail_outline,
                              'Email nhận thông báo',
                              order.customerEmail,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.location_on_outlined,
                            'Địa chỉ giao hàng',
                            order.shippingAddress,
                          ),
                          if (order.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _infoRow(
                              Icons.note_alt_outlined,
                              'Ghi chú của khách',
                              order.note,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.payment_outlined,
                            'Phương thức thanh toán',
                            order.paymentMethod,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lý do hủy nếu có
                    if (order.cancelReason != null &&
                        order.cancelReason!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lý do hủy đơn:',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.cancelReason!,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Danh sách sản phẩm
                    Text(
                      'SẢN PHẨM TRONG ĐƠN (${order.totalQuantity} món)',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LumiStyle.line),
                      ),
                      child: Column(
                        children: [
                          ...order.items.map((it) {
                            final name =
                                it['name'] ??
                                it['productName'] ??
                                'Sản phẩm LUMI';
                            final qty = it['quantity'] ?? 1;
                            final price = it['price'] ?? it['unitPrice'] ?? 0;
                            final totalLine =
                                (price is num
                                    ? price
                                    : num.tryParse(price.toString()) ?? 0) *
                                (qty is num ? qty : 1);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: LumiStyle.blushSurface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.spa_outlined,
                                          color: LumiStyle.rose,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: LumiStyle.plum,
                                              ),
                                            ),
                                            Text(
                                              'Đơn giá: ${_formatVND(price is num ? price : 0)}',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11.5,
                                                color: LumiStyle.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'x$qty',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: LumiStyle.rose,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        _formatVND(totalLine),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: LumiStyle.plum,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: LumiStyle.line),
                              ],
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng Tiền Thanh Toán:',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: LumiStyle.plum,
                                  ),
                                ),
                                Text(
                                  order.displayTotal,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: LumiStyle.rose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24, color: LumiStyle.line),

              // Bottom action bar
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LumiStyle.muted,
                      side: const BorderSide(color: LumiStyle.line),
                    ),
                    child: const Text('ĐÓNG'),
                  ),

                  // Nút Duyệt nếu đang Pending
                  if (order.status == 'pending') ...[
                    OutlinedButton.icon(
                      onPressed: () => onUpdateStatus('cancelled'),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text('HỦY ĐƠN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => onUpdateStatus('confirmed'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('DUYỆT ĐƠN & GỬI EMAIL'),
                      style: FilledButton.styleFrom(
                        backgroundColor: LumiStyle.rose,
                      ),
                    ),
                  ],

                  // Nút Giao Hàng nếu đã Confirmed
                  if (order.status == 'confirmed') ...[
                    OutlinedButton.icon(
                      onPressed: () => onUpdateStatus('cancelled'),
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text('HỦY ĐƠN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => onUpdateStatus('shipping'),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('BẮT ĐẦU GIAO HÀNG'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ],

                  // Nút Hoàn Tất nếu đang Shipping
                  if (order.status == 'shipping') ...[
                    FilledButton.icon(
                      onPressed: () => onUpdateStatus('completed'),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('XÁC NHẬN ĐÃ GIAO HÀNG'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: LumiStyle.rose),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
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
    );
  }
}
