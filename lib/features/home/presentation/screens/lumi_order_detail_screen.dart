import 'lumi_order_ui.dart';
import '../../../../core/theme/lumi_adaptive.dart';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_order_store.dart';

class LumiOrderDetailScreen extends StatefulWidget {
  const LumiOrderDetailScreen({super.key, required this.order});

  final Map<String, String> order;

  @override
  State<LumiOrderDetailScreen> createState() => _LumiOrderDetailScreenState();
}

class _LumiOrderDetailScreenState extends State<LumiOrderDetailScreen> {
  static const rose = Color(0xFFA5553E);
  static const ink = Color(0xFF403735);
  static const muted = Color(0xFF756863);
  static const cream = Color(0xFFFFF8EF);
  static const blush = Color(0xFFFBE7DC);
  static const blue = Color(0xFFE1EFF5);

  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order['status'] ?? 'Chờ xác nhận';
  }

  String _money(num value) {
    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
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
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  String _statusMessage() {
    switch (currentStatus) {
      case 'Chờ xác nhận':
        return 'LUMI sẽ liên hệ với bạn để xác nhận '
            'đơn hàng trong thời gian sớm nhất.';

      case 'Đã xác nhận':
        return 'Đơn hàng đã được xác nhận và đang được '
            'chuẩn bị để giao đến bạn.';

      case 'Đang giao':
        return 'Đơn hàng đang trên đường giao đến bạn. '
            'Vui lòng giữ điện thoại để nhận cuộc gọi '
            'từ nhân viên giao hàng.';

      case 'Đã giao':
        return 'Đơn hàng đã được giao thành công. '
            'Cảm ơn bạn đã mua sắm tại LUMI.';

      case 'Đã hủy':
        return 'Đơn hàng này đã được hủy.';

      default:
        return 'LUMI đang cập nhật thông tin '
            'đơn hàng của bạn.';
    }
  }

  Widget _sectionTitle(String title, IconData icon) =>
      LumiOrderUi.title(context, title, icon);

  Widget _infoRow(String label, String value) =>
      LumiOrderUi.row(context, label, value);

  Widget _orderSummary() {
    final colors = Theme.of(context).colorScheme;
    return LumiOrderUi.panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumiOrderUi.badge(context, currentStatus),
          const SizedBox(height: 16),
          Text(
            widget.order['id'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.order['total'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Ngày đặt', widget.order['date'] ?? ''),
          _infoRow(
            'Thanh toán',
            widget.order['paymentMethod'] ?? 'Thanh toán khi nhận hàng',
          ),
        ],
      ),
      hero: true,
    );
  }

  Widget _customerInformation() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumiAdaptive.color(blush)),
      ),
      child: Column(
        children: [
          _infoRow('Người nhận', widget.order['customerName'] ?? ''),
          _infoRow('Số điện thoại', widget.order['phone'] ?? ''),
          _infoRow('Địa chỉ', widget.order['address'] ?? ''),
          if ((widget.order['note'] ?? '').trim().isNotEmpty)
            _infoRow('Ghi chú', widget.order['note'] ?? ''),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Sản phẩm LUMI';

    final quantity = _toNumber(item['quantity']).toInt();

    final price = _toNumber(item['price']);

    final total = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiAdaptive.color(blush)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: LumiAdaptive.color(blue, surface: true),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.spa_outlined,
              color: LumiAdaptive.color(rose),
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text(name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  LumiAdaptive.text('Số lượng: $quantity'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(muted),
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  LumiAdaptive.text('Đơn giá: ${_money(price)}'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(muted),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            LumiAdaptive.text(_money(total)),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(rose),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
        _sectionTitle('Sản phẩm trong đơn', Icons.shopping_bag_outlined),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(Colors.white, surface: true),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LumiAdaptive.color(blush)),
            ),
            child: Text(
              LumiAdaptive.text('Thông tin sản phẩm chưa được cập nhật.'),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(muted),
                  fontSize: 14,
                ),
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
          title: Text(LumiAdaptive.text('Hủy đơn hàng?')),
          content: Text(
            LumiAdaptive.text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(LumiAdaptive.text('Không')),
            ),
            FilledButton(
              style: LumiAdaptive.style(
                FilledButton.styleFrom(
                  backgroundColor: LumiAdaptive.color(
                    Colors.redAccent,
                    surface: true,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(LumiAdaptive.text('Hủy đơn')),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    final orderId = widget.order['id'] ?? '';

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()},
      );

      LumiOrderStore.cancelOrder(orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        currentStatus = 'Đã hủy';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LumiAdaptive.text('Đơn hàng đã được hủy'))),
      );
    } catch (error) {
      debugPrint('Cancel order error: $error');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LumiAdaptive.text('Không thể hủy đơn hàng. Vui lòng thử lại.'),
          ),
        ),
      );
    }
  }

  Widget _cancelButton() {
    final canCancel = currentStatus == 'Chờ xác nhận';

    if (!canCancel) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cancelOrder,
        icon: const Icon(Icons.cancel_outlined),
        label: Text(LumiAdaptive.text('HỦY ĐƠN HÀNG')),
        style: LumiAdaptive.style(
          OutlinedButton.styleFrom(
            foregroundColor: LumiAdaptive.color(Colors.redAccent),
            side: BorderSide(color: LumiAdaptive.color(Colors.redAccent)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    return Scaffold(
      backgroundColor: LumiAdaptive.color(cream, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(cream, surface: true),
        foregroundColor: LumiAdaptive.color(ink),
        elevation: 0,
        title: Text(
          LumiAdaptive.text('Chi tiết đơn hàng'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
        children: [
          _orderSummary(),
          const SizedBox(height: 20),
          _sectionTitle('Thông tin nhận hàng', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _customerInformation(),
          const SizedBox(height: 20),
          _productsSection(),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(blue, surface: true),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: LumiAdaptive.color(rose)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LumiAdaptive.text(_statusMessage()),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(ink),
                        fontSize: 15,
                        height: 1.5,
                      ),
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
