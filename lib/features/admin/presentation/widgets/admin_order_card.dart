import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_order_item.dart';

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onApprove,
    required this.onCancel,
    required this.onViewDetail,
    required this.onUpdateStatus,
  });

  final AdminOrderItem order;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onViewDetail;
  final void Function(String newStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status == 'pending'
              ? LumiStyle.rose.withValues(alpha: 0.45)
              : LumiStyle.line,
          width: order.status == 'pending' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: LumiStyle.plum.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Order Id + Status Badge
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
                      child: const Icon(Icons.shopping_bag_outlined, color: LumiStyle.rose, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${order.id}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: order.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: order.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: order.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Khách hàng & SĐT
            Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: LumiStyle.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LumiStyle.plum,
                    ),
                  ),
                ),
                if (order.phone.isNotEmpty) ...[
                  const Icon(Icons.phone_outlined, size: 14, color: LumiStyle.muted),
                  const SizedBox(width: 4),
                  Text(
                    order.phone,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: LumiStyle.plum),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Địa chỉ giao hàng
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: LumiStyle.rose),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.shippingAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: LumiStyle.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tóm tắt sản phẩm
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: LumiStyle.blushSurface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 15, color: LumiStyle.rose),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.plum),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tổng tiền & Thanh toán & Thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng thanh toán',
                      style: GoogleFonts.dmSans(fontSize: 11, color: LumiStyle.muted),
                    ),
                    Text(
                      order.displayTotal,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: LumiStyle.rose,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.paymentMethod,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: LumiStyle.plum,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.formattedCreatedAt,
                      style: GoogleFonts.dmSans(fontSize: 11, color: LumiStyle.muted),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, color: LumiStyle.line),

            // Actions row
            Row(
              children: [
                OutlinedButton(
                  onPressed: onViewDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LumiStyle.plum,
                    side: const BorderSide(color: LumiStyle.line),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Chi tiết'),
                ),
                const Spacer(),

                // Khi status == pending: Duyệt và Hủy
                if (order.status == 'pending') ...[
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 15, color: Colors.red),
                    label: Text(
                      'Hủy',
                      style: GoogleFonts.dmSans(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 15),
                    label: const Text('Duyệt đơn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LumiStyle.rose,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],

                // Khi status == confirmed: Giao hàng
                if (order.status == 'confirmed' || order.status == 'processing') ...[
                  FilledButton.icon(
                    onPressed: () => onUpdateStatus('shipping'),
                    icon: const Icon(Icons.local_shipping_outlined, size: 15),
                    label: const Text('Giao hàng'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],

                // Khi status == shipping: Hoàn tất
                if (order.status == 'shipping' || order.status == 'delivering') ...[
                  FilledButton.icon(
                    onPressed: () => onUpdateStatus('completed'),
                    icon: const Icon(Icons.done_all, size: 15),
                    label: const Text('Đã giao'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
