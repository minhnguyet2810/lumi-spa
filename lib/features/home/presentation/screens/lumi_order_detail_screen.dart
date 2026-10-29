import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LumiOrderDetailScreen extends StatelessWidget {
  const LumiOrderDetailScreen({
    super.key,
    required this.order,
  });

  final Map<String, String> order;

  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);

  Color _statusColor(String status) {
    if (status == 'Đã giao') return Colors.green.shade700;
    if (status == 'Đã hủy') return Colors.red.shade700;
    if (status == 'Đang giao') return Colors.blue.shade700;
    return rose;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'Chờ xác nhận';
    final statusColor = _statusColor(status);

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
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: rose,
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  status,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Trạng thái đơn hàng hiện tại',
                  style: GoogleFonts.dmSans(
                    color: muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section(
            title: 'Thông tin đơn hàng',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _row('Mã đơn hàng', order['id'] ?? ''),
                _row('Ngày đặt', order['date'] ?? ''),
                _row('Phương thức thanh toán', 'COD'),
                _row('Tổng tiền', order['total'] ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _section(
            title: 'Sản phẩm',
            icon: Icons.shopping_bag_outlined,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: blush.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: blue,
                    child: Icon(
                      Icons.spa_outlined,
                      color: rose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sản phẩm chăm sóc da LUMI',
                      style: GoogleFonts.dmSans(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'x1',
                    style: GoogleFonts.dmSans(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          _section(
            title: 'Địa chỉ giao hàng',
            icon: Icons.location_on_outlined,
            child: Text(
              'Thông tin địa chỉ sẽ được cập nhật khi kết nối API đơn hàng.',
              style: GoogleFonts.dmSans(
                color: muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 25),
          if (status == 'Chờ xác nhận')
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chức năng hủy đơn đang được phát triển.',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('HỦY ĐƠN HÀNG'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: blush),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: rose, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }
}