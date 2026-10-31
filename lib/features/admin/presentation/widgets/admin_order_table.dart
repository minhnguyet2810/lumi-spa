import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../data/models/admin_order_item.dart';

class AdminOrderTable extends StatelessWidget {
  const AdminOrderTable({
    super.key,
    required this.orders,
    required this.onApprove,
    required this.onCancel,
    required this.onViewDetail,
    required this.onUpdateStatus,
  });

  final List<AdminOrderItem> orders;
  final void Function(AdminOrderItem order) onApprove;
  final void Function(AdminOrderItem order) onCancel;
  final void Function(AdminOrderItem order) onViewDetail;
  final void Function(AdminOrderItem order, String newStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: LumiStyle.muted),
              const SizedBox(height: 12),
              Text(
                'Không có đơn hàng nào trong danh mục này',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LumiStyle.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LumiStyle.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(LumiStyle.blushSurface.withValues(alpha: 0.5)),
            headingTextStyle: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: LumiStyle.plum,
            ),
            dataTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: LumiStyle.plum,
            ),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('MÃ ĐƠN')),
              DataColumn(label: Text('NGÀY ĐẶT')),
              DataColumn(label: Text('KHÁCH HÀNG')),
              DataColumn(label: Text('SẢN PHẨM')),
              DataColumn(label: Text('TỔNG TIỀN')),
              DataColumn(label: Text('THANH TOÁN')),
              DataColumn(label: Text('TRẠNG THÁI')),
              DataColumn(label: Text('THAO TÁC')),
            ],
            rows: orders.map((order) {
              return DataRow(
                cells: [
                  // 1. Mã đơn
                  DataCell(
                    Text(
                      '#${order.id}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                  ),

                  // 2. Ngày đặt
                  DataCell(
                    Text(
                      order.formattedCreatedAt,
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
                    ),
                  ),

                  // 3. Khách hàng
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          order.customerName,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            color: LumiStyle.plum,
                          ),
                        ),
                        if (order.phone.isNotEmpty)
                          Text(
                            order.phone,
                            style: GoogleFonts.dmSans(fontSize: 11.5, color: LumiStyle.muted),
                          ),
                      ],
                    ),
                  ),

                  // 4. Sản phẩm tóm tắt
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        order.itemsSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 12),
                      ),
                    ),
                  ),

                  // 5. Tổng tiền
                  DataCell(
                    Text(
                      order.displayTotal,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.rose,
                      ),
                    ),
                  ),

                  // 6. Thanh toán
                  DataCell(
                    Text(
                      order.paymentMethod,
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
                    ),
                  ),

                  // 7. Trạng thái badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: order.statusColor.withValues(alpha: 0.35),
                        ),
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
                  ),

                  // 8. Thao tác
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút xem chi tiết
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          color: LumiStyle.plum,
                          tooltip: 'Xem chi tiết đơn hàng',
                          onPressed: () => onViewDetail(order),
                        ),

                        // Nút Duyệt nếu đang Pending
                        if (order.status == 'pending') ...[
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: () => onApprove(order),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Duyệt'),
                            style: FilledButton.styleFrom(
                              backgroundColor: LumiStyle.rose,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            tooltip: 'Hủy đơn',
                            onPressed: () => onCancel(order),
                          ),
                        ],

                        // Nút Giao hàng nếu Confirmed
                        if (order.status == 'confirmed' || order.status == 'processing') ...[
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: () => onUpdateStatus(order, 'shipping'),
                            icon: const Icon(Icons.local_shipping_outlined, size: 14),
                            label: const Text('Giao hàng'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            tooltip: 'Hủy đơn',
                            onPressed: () => onCancel(order),
                          ),
                        ],

                        // Nút Hoàn tất nếu Shipping
                        if (order.status == 'shipping' || order.status == 'delivering') ...[
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: () => onUpdateStatus(order, 'completed'),
                            icon: const Icon(Icons.done_all, size: 14),
                            label: const Text('Đã giao'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

