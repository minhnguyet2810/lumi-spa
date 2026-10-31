import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_order_store.dart';

class LumiOrderDetailScreen extends StatefulWidget {
  const LumiOrderDetailScreen({
    super.key,
    required this.order,
  });

  final Map<String, String> order;

  @override
  State<LumiOrderDetailScreen> createState() =>
      _LumiOrderDetailScreenState();
}

class _LumiOrderDetailScreenState
    extends State<LumiOrderDetailScreen> {
  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);

  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus =
        widget.order['status'] ?? 'Chờ xác nhận';
  }

  String _money(num value) {
    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )} đ';
  }

  num _toNumber(dynamic value) {
    if (value is num) {
      return value;
    }

    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _orderItems() {
    final rawItems = widget.order['items'] ?? '[]';

    try {
      final decoded = jsonDecode(rawItems);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }
    } catch (_) {}

    return [];
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

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: rose,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: muted,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary() {
    final statusColor = _statusColor(currentStatus);

    return Container(
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
                  widget.order['id'] ?? '',
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 17,
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
                  currentStatus,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _infoRow(
            'Ngày đặt',
            widget.order['date'] ?? '',
          ),
          _infoRow(
            'Tổng tiền',
            widget.order['total'] ?? '',
          ),
          _infoRow(
            'Thanh toán',
            widget.order['paymentMethod'] ??
                'Thanh toán khi nhận hàng',
          ),
        ],
      ),
    );
  }

  Widget _customerInformation() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: blush),
      ),
      child: Column(
        children: [
          _infoRow(
            'Người nhận',
            widget.order['customerName'] ?? '',
          ),
          _infoRow(
            'Số điện thoại',
            widget.order['phone'] ?? '',
          ),
          _infoRow(
            'Địa chỉ',
            widget.order['address'] ?? '',
          ),
          if ((widget.order['note'] ?? '').trim().isNotEmpty)
            _infoRow(
              'Ghi chú',
              widget.order['note'] ?? '',
            ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ??
        'Sản phẩm LUMI';

    final quantity = _toNumber(
      item['quantity'],
    ).toInt();

    final price = _toNumber(
      item['price'],
    );

    final total = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: blush),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: rose,
              size: 27,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Số lượng: $quantity',
                  style: GoogleFonts.dmSans(
                    color: muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đơn giá: ${_money(price)}',
                  style: GoogleFonts.dmSans(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(total),
            style: GoogleFonts.dmSans(
              color: rose,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsSection() {
    final items = _orderItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Sản phẩm trong đơn',
          Icons.shopping_bag_outlined,
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: blush),
            ),
            child: Text(
              'Thông tin sản phẩm chưa được cập nhật.',
              style: GoogleFonts.dmSans(
                color: muted,
                fontSize: 14,
              ),
            ),
          )
        else
          ...items.map(_productCard),
      ],
    );
  }

  Future<void> _cancelOrder() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng?'),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đơn hàng này không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Không'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hủy đơn'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    final orderId = widget.order['id'] ?? '';

    LumiOrderStore.cancelOrder(orderId);

    setState(() {
      currentStatus = 'Đã hủy';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đơn hàng đã được hủy'),
      ),
    );
  }

  Widget _cancelButton() {
    final canCancel =
        currentStatus == 'Chờ xác nhận';

    if (!canCancel) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cancelOrder,
        icon: const Icon(
          Icons.cancel_outlined,
        ),
        label: const Text('HỦY ĐƠN HÀNG'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(
            color: Colors.redAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        title: Text(
          'Chi tiết đơn hàng',
          style: GoogleFonts.dmSans(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        children: [
          _orderSummary(),
          const SizedBox(height: 20),
          _sectionTitle(
            'Thông tin nhận hàng',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _customerInformation(),
          const SizedBox(height: 20),
          _productsSection(),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: rose,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentStatus == 'Đã hủy'
                        ? 'Đơn hàng này đã được hủy.'
                        : 'LUMI sẽ liên hệ với bạn để xác nhận '
                          'đơn hàng trong thời gian sớm nhất.',
                    style: GoogleFonts.dmSans(
                      color: ink,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _cancelButton(),
        ],
      ),
    );
  }
}