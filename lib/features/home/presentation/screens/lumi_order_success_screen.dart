import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumi_my_orders_screen.dart';

class LumiOrderSuccessScreen extends StatelessWidget {
  const LumiOrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    required this.paymentMethod,
  });

  final String orderId;
  final num total;
  final String paymentMethod;

  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);

  String _money(num value) {
    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }

  void _continueShopping(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _viewOrders(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LumiMyOrdersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    return Scaffold(
      backgroundColor: LumiAdaptive.color(cream, surface: true),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: LumiAdaptive.color(cream, surface: true),
        elevation: 0,
        centerTitle: true,
        title: Text(
          LumiAdaptive.text('Đặt hàng thành công'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: LumiAdaptive.color(blush, surface: true),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 62,
                    color: LumiAdaptive.color(rose),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  LumiAdaptive.text('Cảm ơn bạn đã\nmua sắm tại LUMI'),
                  textAlign: TextAlign.center,
                  style: LumiAdaptive.style(
                    GoogleFonts.cormorantGaramond(
                      color: LumiAdaptive.color(ink),
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  LumiAdaptive.text(
                    'Đơn hàng của bạn đã được ghi nhận. '
                    'LUMI sẽ liên hệ để xác nhận đơn hàng sớm nhất.',
                  ),
                  textAlign: TextAlign.center,
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(muted),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LumiAdaptive.color(Colors.white, surface: true),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: LumiAdaptive.color(blush)),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Mã đơn hàng', orderId),
                      const Divider(height: 25),
                      _infoRow('Tổng thanh toán', _money(total)),
                      const Divider(height: 25),
                      _infoRow('Thanh toán', paymentMethod),
                      const Divider(height: 25),
                      _infoRow('Trạng thái', 'Chờ xác nhận'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: LumiAdaptive.color(blue, surface: true),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: LumiAdaptive.color(rose),
                        size: 25,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          LumiAdaptive.text(
                            'Đơn hàng sẽ được giao đến địa chỉ bạn đã cung cấp. '
                            'Vui lòng giữ điện thoại để nhận cuộc gọi xác nhận.',
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(ink),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _viewOrders(context),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      LumiAdaptive.text('XEM ĐƠN HÀNG'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    style: LumiAdaptive.style(
                      FilledButton.styleFrom(
                        backgroundColor: LumiAdaptive.color(
                          rose,
                          surface: true,
                        ),
                        foregroundColor: LumiAdaptive.color(Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => _continueShopping(context),
                    style: LumiAdaptive.style(
                      OutlinedButton.styleFrom(
                        foregroundColor: LumiAdaptive.color(rose),
                        side: BorderSide(color: LumiAdaptive.color(rose)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    child: Text(
                      LumiAdaptive.text('TIẾP TỤC MUA SẮM'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _continueShopping(context),
                  child: Text(
                    LumiAdaptive.text('Về trang chủ'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(rose),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LumiAdaptive.text(label),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(color: LumiAdaptive.color(muted), fontSize: 14),
          ),
        ),
        Flexible(
          child: Text(
            LumiAdaptive.text(value),
            textAlign: TextAlign.right,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(ink),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
