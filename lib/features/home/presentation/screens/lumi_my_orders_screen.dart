import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumi_order_detail_screen.dart';
import '../../../../core/data/lumi_order_store.dart';

class LumiMyOrdersScreen extends StatefulWidget {
  const LumiMyOrdersScreen({super.key});

  @override
  State<LumiMyOrdersScreen> createState() => _LumiMyOrdersScreenState();
}

class _LumiMyOrdersScreenState extends State<LumiMyOrdersScreen> {
  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);

  String selectedStatus = 'Tất cả';

  final List<String> statuses = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang giao',
    'Đã giao',
    'Đã hủy',
  ];

  List<Map<String, String>> get orders {
    return LumiOrderStore.orders;
  }

  List<Map<String, String>> get filteredOrders {
    if (selectedStatus == 'Tất cả') {
      return orders;
    }

    return orders
        .where((order) => order['status'] == selectedStatus)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Đã giao':
        return Colors.green.shade700;
      case 'Đã hủy':
        return Colors.red.shade700;
      case 'Đang giao':
        return Colors.blue.shade700;
      default:
        return rose;
    }
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 65,
            color: rose,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các đơn hàng của bạn sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: muted),
          ),
        ],
      ),
    );
  }

  Widget _statusFilter() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selectedStatus == status;

          return ChoiceChip(
            label: Text(status),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedStatus = status;
              });
            },
            selectedColor: rose,
            backgroundColor: Colors.white,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected ? rose : blush,
            ),
            labelStyle: GoogleFonts.dmSans(
              color: isSelected ? Colors.white : ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(
    BuildContext context,
    Map<String, String> order,
  ) {
    final status = order['status'] ?? 'Chờ xác nhận';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: blush),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: rose,
                size: 25,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order['id'] ?? '',
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          _infoRow('Ngày đặt', order['date'] ?? ''),
          const SizedBox(height: 8),
          _infoRow('Tổng tiền', order['total'] ?? ''),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LumiOrderDetailScreen(
                      order: order,
                    ),
                  ),
                );

                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: rose,
                side: const BorderSide(color: rose),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xem chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: muted,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOrders = orders.isNotEmpty;
    final hasFilteredOrders = filteredOrders.isNotEmpty;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        title: Text(
          'Đơn hàng của tôi',
          style: GoogleFonts.dmSans(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !hasOrders
          ? _emptyState('Bạn chưa có đơn hàng nào')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    'Theo dõi lịch sử mua sắm và trạng thái '
                    'các đơn hàng của bạn tại LUMI.',
                    style: GoogleFonts.dmSans(
                      color: ink,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _statusFilter(),
                const SizedBox(height: 20),
                if (!hasFilteredOrders)
                  SizedBox(
                    height: 300,
                    child: _emptyState(
                      'Chưa có đơn hàng ở trạng thái "$selectedStatus"',
                    ),
                  )
                else
                  ...filteredOrders.map(
                    (order) => _orderCard(context, order),
                  ),
              ],
            ),
    );
  }
}