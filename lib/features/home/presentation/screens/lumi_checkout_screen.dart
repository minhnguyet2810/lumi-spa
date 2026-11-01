import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/lumi_order_store.dart';
import '../../../../core/network/lumi_api_client.dart';
import 'lumi_order_success_screen.dart';
import 'lumi_shop_catalog.dart';

class LumiCheckoutScreen extends StatefulWidget {
  const LumiCheckoutScreen({super.key, required this.cartItems});

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

  static const bankName = 'Vietinbank';
  static const bankAccount = '104882453416';
  static const bankOwner = 'Nha Doan LUMI SPA';

  String get _customerScope =>
      FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get savedNameKey => 'lumi_customer_name_$_customerScope';
  String get savedPhoneKey => 'lumi_customer_phone_$_customerScope';
  String get savedAddressKey => 'lumi_customer_address_$_customerScope';

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;
  String _paymentMethod = 'cod';

  @override
  void initState() {
    super.initState();
    _loadSavedCustomerInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCustomerInfo() async {
    final scope = _customerScope;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted || scope != _customerScope) {
      return;
    }

    _nameController.text = prefs.getString(savedNameKey) ?? '';

    _phoneController.text = prefs.getString(savedPhoneKey) ?? '';

    _addressController.text = prefs.getString(savedAddressKey) ?? '';

    setState(() {});
  }

  Future<void> _saveCustomerInfo({
    required String name,
    required String phone,
    required String address,
  }) async {
    final scope = _customerScope;
    final prefs = await SharedPreferences.getInstance();
    if (scope != _customerScope) {
      return;
    }
    await prefs.setString('lumi_customer_name_$scope', name);
    await prefs.setString('lumi_customer_phone_$scope', phone);
    await prefs.setString('lumi_customer_address_$scope', address);
  }

  num get subtotal {
    return widget.cartItems.fold<num>(0, (total, item) => total + item.total);
  }

  num get shippingFee {
    return subtotal >= 500000 ? 0 : 30000;
  }

  num get grandTotal {
    return subtotal + shippingFee;
  }

  String _money(num value) {
    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }

  String _productName(LumiCartItem item) {
    return item.product['name']?.toString() ?? 'Sản phẩm LUMI';
  }

  String? _getProductImage(LumiCartItem item) {
    final imageUrl = item.product['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return imageUrl.trim();
    }

    final imageUrls = item.product['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      final first = imageUrls.first;

      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: LumiAdaptive.optionalText(label),
      hintText: LumiAdaptive.optionalText(hint),
      prefixIcon: Icon(icon, color: LumiAdaptive.color(rose)),
      filled: true,
      fillColor: LumiAdaptive.color(Colors.white, surface: true),
      labelStyle: LumiAdaptive.style(
        GoogleFonts.dmSans(color: LumiAdaptive.color(muted)),
      ),
      hintStyle: LumiAdaptive.style(
        GoogleFonts.dmSans(
          color: LumiAdaptive.color(muted.withValues(alpha: .65)),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: LumiAdaptive.color(blush)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: LumiAdaptive.color(rose), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: LumiAdaptive.color(Colors.redAccent)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: LumiAdaptive.color(Colors.redAccent)),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: LumiAdaptive.color(rose), size: 21),
        const SizedBox(width: 8),
        Text(
          LumiAdaptive.text(title),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _productItem(LumiCartItem item) {
    final imageUrl = _getProductImage(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: LumiAdaptive.color(blush)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 64,
              height: 64,
              child: imageUrl == null
                  ? ColoredBox(
                      color: LumiAdaptive.color(blue),
                      child: Icon(
                        Icons.spa_outlined,
                        color: LumiAdaptive.color(rose),
                        size: 28,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return ColoredBox(
                          color: LumiAdaptive.color(blue),
                          child: Icon(
                            Icons.spa_outlined,
                            color: LumiAdaptive.color(rose),
                            size: 28,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text(_productName(item)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LumiAdaptive.text('Số lượng: ${item.quantity}'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(muted),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            LumiAdaptive.text(_money(item.total)),
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

  Widget _priceRow(String title, num value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LumiAdaptive.text(title),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(isTotal ? ink : muted),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            LumiAdaptive.text(value == 0 ? 'Miễn phí' : _money(value)),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(isTotal ? rose : ink),
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;

    return Container(
      decoration: BoxDecoration(
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: LumiAdaptive.color(isSelected ? rose : blush),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        title: Text(
          LumiAdaptive.text(title),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        subtitle: Text(
          LumiAdaptive.text(subtitle),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(color: LumiAdaptive.color(muted), fontSize: 13),
          ),
        ),
        secondary: Icon(
          icon,
          color: LumiAdaptive.color(isSelected ? rose : muted),
          size: 28,
        ),
        activeColor: LumiAdaptive.color(rose),
        selected: isSelected,
        enabled: !_isSubmitting,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _bankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              LumiAdaptive.text(label),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(muted),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              LumiAdaptive.text(value),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(ink),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankTransferInfo() {
    if (_paymentMethod != 'bank') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(blue, surface: true),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 210,
              height: 210,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LumiAdaptive.color(Colors.white, surface: true),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/images/lumi_bank_qr.jpg',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return Center(
                    child: Icon(
                      Icons.qr_code_2,
                      color: LumiAdaptive.color(rose),
                      size: 80,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LumiAdaptive.text('Thông tin chuyển khoản'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(ink),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _bankInfoRow('Ngân hàng', bankName),
          _bankInfoRow('Số tài khoản', bankAccount),
          _bankInfoRow('Chủ tài khoản', bankOwner),
          _bankInfoRow('Số tiền', _money(grandTotal)),
          _bankInfoRow('Nội dung', 'LUMI THANH TOAN'),
          const SizedBox(height: 5),
          Text(
            LumiAdaptive.text(
              'Sau khi chuyển khoản, vui lòng giữ lại ảnh '
              'chụp giao dịch để đối chiếu khi cần.',
            ),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(muted),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải gồm 10 số và bắt đầu bằng 0';
    }

    return null;
  }

  Future<void> _placeOrder() async {
    if (_isSubmitting) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    FocusScope.of(context).unfocus();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    late String orderId;
    late num orderTotal;
    final now = DateTime.now();

    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    var items = widget.cartItems.map((item) {
      return <String, dynamic>{
        'productId':
            item.product['id']?.toString() ??
            item.product['_id']?.toString() ??
            '',
        'name': item.product['name']?.toString() ?? 'Sản phẩm LUMI',
        'quantity': item.quantity,
        'price': item.product['price'] ?? 0,
      };
    }).toList();

    final customerName = _nameController.text.trim();
    final customerPhone = _phoneController.text.trim();
    final customerAddress = _addressController.text.trim();
    final customerNote = _noteController.text.trim();

    final paymentMethodLabel = _paymentMethod == 'bank'
        ? 'Chuyển khoản ngân hàng'
        : 'Thanh toán khi nhận hàng (COD)';

    try {
      final response = await LumiApiClient.instance.post(
        '/api/orders',
        body: {
          'items': items
              .map(
                (item) => {
                  'productId': item['productId'],
                  'quantity': item['quantity'],
                },
              )
              .toList(),
          'customerName': customerName,
          'phone': customerPhone,
          'shippingAddress': customerAddress,
          'note': customerNote,
          'paymentMethod': _paymentMethod,
        },
      );
      final receipt = Map<String, dynamic>.from(response['data'] as Map);
      orderId = receipt['id'] as String;
      orderTotal = receipt['total'] as num;
      items = (receipt['items'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      debugPrint('Lưu đơn hàng thất bại: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LumiAdaptive.text('Không thể tạo đơn hàng. Vui lòng thử lại.'),
          ),
        ),
      );

      return;
    }

    try {
      await _saveCustomerInfo(
        name: customerName,
        phone: customerPhone,
        address: customerAddress,
      );
    } catch (error) {
      debugPrint('Lưu thông tin khách hàng thất bại: $error');
    }

    LumiOrderStore.addOrder(
      id: orderId,
      date: formattedDate,
      total: _money(orderTotal),
      customerName: customerName,
      phone: customerPhone,
      address: customerAddress,
      note: customerNote,
      items: items,
      paymentMethod: paymentMethodLabel,
    );

    LumiShopCatalog.clearCart();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LumiOrderSuccessScreen(
          orderId: orderId,
          total: orderTotal,
          paymentMethod: _paymentMethod == 'bank'
              ? 'Chuyển khoản ngân hàng'
              : 'Thanh toán khi nhận hàng',
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _placeOrder,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LumiAdaptive.color(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          LumiAdaptive.text(
            _isSubmitting
                ? 'ĐANG XỬ LÝ...'
                : 'ĐẶT HÀNG · ${_money(grandTotal)}',
          ),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(fontWeight: FontWeight.w700, letterSpacing: .4),
          ),
        ),
        style: LumiAdaptive.style(
          FilledButton.styleFrom(
            backgroundColor: LumiAdaptive.color(rose, surface: true),
            disabledBackgroundColor: LumiAdaptive.color(
              rose.withValues(alpha: .65),
              surface: true,
            ),
            foregroundColor: LumiAdaptive.color(Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
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
          LumiAdaptive.text('Thanh toán'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Text(
                LumiAdaptive.text('Giỏ hàng đang trống.'),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(color: LumiAdaptive.color(muted)),
                ),
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
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Họ và tên',
                      icon: Icons.person_outline,
                      hint: 'Nhập tên người nhận',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }

                      if (value.trim().length < 2) {
                        return 'Họ và tên quá ngắn';
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
                    validator: _validatePhone,
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

                      if (value.trim().length < 5) {
                        return 'Địa chỉ giao hàng quá ngắn';
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
                  RadioGroup<String>(
                    groupValue: _paymentMethod,
                    onChanged: _isSubmitting
                        ? (_) {}
                        : (selectedValue) {
                            if (selectedValue == null) {
                              return;
                            }

                            setState(() {
                              _paymentMethod = selectedValue;
                            });
                          },
                    child: Column(
                      children: [
                        _paymentOption(
                          value: 'cod',
                          title: 'Thanh toán khi nhận hàng',
                          subtitle: 'COD - trả tiền mặt khi nhận sản phẩm',
                          icon: Icons.local_atm_outlined,
                        ),
                        const SizedBox(height: 12),
                        _paymentOption(
                          value: 'bank',
                          title: 'Chuyển khoản ngân hàng',
                          subtitle: 'Chuyển khoản trước khi nhận hàng',
                          icon: Icons.account_balance_outlined,
                        ),
                      ],
                    ),
                  ),
                  _bankTransferInfo(),
                  const SizedBox(height: 26),
                  _sectionTitle(
                    'Tóm tắt đơn hàng',
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: LumiAdaptive.color(Colors.white, surface: true),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: LumiAdaptive.color(blush)),
                    ),
                    child: Column(
                      children: [
                        _priceRow('Tạm tính', subtotal),
                        _priceRow('Phí giao hàng', shippingFee),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 7),
                          child: Divider(),
                        ),
                        _priceRow('Tổng cộng', grandTotal, isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _submitButton(),
                  const SizedBox(height: 12),
                  Text(
                    LumiAdaptive.text(
                      'Đơn hàng sẽ được lưu vào hệ thống sau khi '
                      'bạn hoàn tất đặt hàng.',
                    ),
                    textAlign: TextAlign.center,
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(muted),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
