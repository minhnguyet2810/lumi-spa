import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumi_shop_catalog.dart';
import 'lumi_order_success_screen.dart';
import '../../../../core/data/lumi_order_store.dart';

class LumiCheckoutScreen extends StatefulWidget {
  const LumiCheckoutScreen({
    super.key,
    required this.cartItems,
  });

  final List<LumiCartItem> cartItems;

  @override
  State<LumiCheckoutScreen> createState() => _LumiCheckoutScreenState();
}

class _LumiCheckoutScreenState extends State<LumiCheckoutScreen> {
  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  num get subtotal {
    return widget.cartItems.fold<num>(
      0,
      (sum, item) => sum + item.total,
    );
  }

  num get shippingFee {
    return subtotal >= 500000 ? 0 : 30000;
  }

  num get grandTotal {
    return subtotal + shippingFee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _money(num value) {
    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )} đ';
  }

  String _productName(LumiCartItem item) {
    return item.product['name']?.toString() ?? 'Sản phẩm LUMI';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: rose),
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.dmSans(color: muted),
      hintStyle: GoogleFonts.dmSans(color: muted.withValues(alpha: .65)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blush),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: rose, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: rose, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _productItem(LumiCartItem item) {
    final imageUrl = item.product['imageUrl']?.toString();
    final imageUrls = item.product['imageUrls'];

    String? firstImage;

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      firstImage = imageUrl;
    } else if (imageUrls is List && imageUrls.isNotEmpty) {
      final first = imageUrls.first;
      if (first is String && first.trim().isNotEmpty) {
        firstImage = first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: blush),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 64,
              height: 64,
              child: firstImage == null
                  ? const ColoredBox(
                      color: blue,
                      child: Icon(
                        Icons.spa_outlined,
                        color: rose,
                        size: 28,
                      ),
                    )
                  : Image.network(
                      firstImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: blue,
                        child: Icon(
                          Icons.spa_outlined,
                          color: rose,
                          size: 28,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productName(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: GoogleFonts.dmSans(
                    color: muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(item.total),
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

  Widget _priceRow(
    String title,
    num value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: isTotal ? ink : muted,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value == 0 ? 'Miễn phí' : _money(value),
            style: GoogleFonts.dmSans(
              color: isTotal ? rose : ink,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _placeOrder() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  FocusScope.of(context).unfocus();

  final orderId =
      'LUMI-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

  final orderTotal = grandTotal;

final now = DateTime.now();
final formattedDate =
    '${now.day.toString().padLeft(2, '0')}/'
    '${now.month.toString().padLeft(2, '0')}/'
    '${now.year}';

final items = widget.cartItems.map((item) {
  return <String, dynamic>{
    'productId': item.product['id']?.toString() ?? '',
    'name': item.product['name']?.toString() ??
        'Sản phẩm LUMI',
    'quantity': item.quantity,
    'price': item.product['price'] ?? 0,
  };
}).toList();

LumiOrderStore.addOrder(
  id: orderId,
  date: formattedDate,
  total: _money(orderTotal),
  customerName: _nameController.text.trim(),
  phone: _phoneController.text.trim(),
  address: _addressController.text.trim(),
  note: _noteController.text.trim(),
  items: items,
);

LumiShopCatalog.clearCart();

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => LumiOrderSuccessScreen(
        orderId: orderId,
        total: orderTotal,
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
          'Thanh toán',
          style: GoogleFonts.dmSans(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Text(
                'Giỏ hàng đang trống.',
                style: GoogleFonts.dmSans(color: muted),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  _sectionTitle(
                    'Thông tin nhận hàng',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                      hint: 'Nhập tên người nhận',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      hint: 'Nhập số điện thoại',
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';

                      if (phone.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }

                      if (phone.length < 9) {
                        return 'Số điện thoại không hợp lệ';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      label: 'Địa chỉ giao hàng',
                      icon: Icons.home_outlined,
                      hint: 'Số nhà, đường, phường/xã...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập địa chỉ giao hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      label: 'Ghi chú đơn hàng',
                      icon: Icons.note_alt_outlined,
                      hint: 'Ví dụ: giao giờ hành chính',
                    ),
                  ),
                  const SizedBox(height: 26),
                  _sectionTitle(
                    'Sản phẩm đã chọn',
                    Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 14),
                  ...widget.cartItems.map(_productItem),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    'Phương thức thanh toán',
                    Icons.payment_outlined,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: blush.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: rose),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_atm_outlined,
                          color: rose,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thanh toán khi nhận hàng',
                                style: GoogleFonts.dmSans(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'COD - trả tiền mặt khi nhận sản phẩm',
                                style: GoogleFonts.dmSans(
                                  color: muted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.radio_button_checked,
                          color: rose,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _sectionTitle(
                    'Tóm tắt đơn hàng',
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: blush),
                    ),
                    child: Column(
                      children: [
                        _priceRow('Tạm tính', subtotal),
                        _priceRow('Phí giao hàng', shippingFee),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 7),
                          child: Divider(),
                        ),
                        _priceRow(
                          'Tổng cộng',
                          grandTotal,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'ĐẶT HÀNG · ${_money(grandTotal)}',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: rose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đây là giao diện thử nghiệm. Đơn hàng chưa được lưu vào hệ thống backend.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}