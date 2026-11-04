import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/data/lumi_order_store.dart';
import '../../../../core/data/lumi_coupons.dart';
import '../../../../core/network/lumi_api_client.dart';
import '../../../../core/data/lumi_account_repository.dart';
import '../../../profile/presentation/screens/addresses_screen.dart';
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
  final _couponController = TextEditingController();

  bool _isSubmitting = false;
  String _paymentMethod = 'cod';
  LumiAddressItem? _selectedAddress;
  bool _saveToAddressBook = true;
  LumiCoupon? _appliedCoupon;
  String? _couponError;

  Future<void> _chooseAddress() async {
    final picked = await Navigator.of(context).push<LumiAddressItem>(
      MaterialPageRoute<LumiAddressItem>(
        builder: (_) => AddressesScreen(
          isSelecting: true,
          selectedAddressId: _selectedAddress?.id,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedAddress = picked;
        _nameController.text = picked.recipientName;
        _phoneController.text = picked.phone;
        _addressController.text = picked.displayAddress;
      });
    }
  }

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
    _couponController.dispose();
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

  num get initialShippingFee {
    return subtotal >= 500000 ? 0 : 30000;
  }

  int get discountAmount {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.calculateDiscount(
      subtotal: subtotal.toInt(),
      shippingFee: initialShippingFee.toInt(),
    );
  }

  num get shippingFee {
    if (_appliedCoupon?.isFreeShipping == true) {
      return 0;
    }
    return initialShippingFee;
  }

  num get grandTotal {
    final net = subtotal - discountAmount;
    final base = net > 0 ? net : 0;
    return base + shippingFee;
  }

  void _applyCoupon(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'Vui lòng nhập mã giảm giá';
      });
      return;
    }
    final coupon = LumiCouponStore.findByCode(code);
    if (coupon == null) {
      setState(() {
        _couponError = 'Mã giảm giá không tồn tại';
      });
      return;
    }
    if (subtotal < coupon.minOrder) {
      final minStr = _money(coupon.minOrder);
      setState(() {
        _couponError = 'Đơn hàng tối thiểu $minStr để áp dụng mã này';
      });
      return;
    }

    setState(() {
      _appliedCoupon = coupon;
      _couponController.text = coupon.code;
      _couponError = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LumiAdaptive.text('Áp dụng mã ${coupon.code} thành công!'),
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponController.clear();
      _couponError = null;
    });
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
        GoogleFonts.beVietnamPro(color: LumiAdaptive.color(muted)),
      ),
      hintStyle: LumiAdaptive.style(
        GoogleFonts.beVietnamPro(
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
            GoogleFonts.beVietnamPro(
              color: LumiAdaptive.color(ink),
              fontSize: 18,
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
                    GoogleFonts.beVietnamPro(
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
                    GoogleFonts.beVietnamPro(
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
              GoogleFonts.beVietnamPro(
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
              GoogleFonts.beVietnamPro(
                color: LumiAdaptive.color(isTotal ? ink : muted),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            LumiAdaptive.text(value == 0 ? 'Miễn phí' : _money(value)),
            style: LumiAdaptive.style(
              GoogleFonts.beVietnamPro(
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
            GoogleFonts.beVietnamPro(
              color: LumiAdaptive.color(ink),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        subtitle: Text(
          LumiAdaptive.text(subtitle),
          style: LumiAdaptive.style(
            GoogleFonts.beVietnamPro(color: LumiAdaptive.color(muted), fontSize: 13),
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
                GoogleFonts.beVietnamPro(
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
                GoogleFonts.beVietnamPro(
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
              GoogleFonts.beVietnamPro(
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
              GoogleFonts.beVietnamPro(
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

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final formattedDate =
        '$hour:$minute ${now.day.toString().padLeft(2, '0')}/'
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
          if (_appliedCoupon != null) 'couponCode': _appliedCoupon!.code,
          if (discountAmount > 0) 'discount': discountAmount,
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
      couponCode: _appliedCoupon?.code,
      discount: discountAmount,
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

  void _showCouponSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: LumiAdaptive.color(cream, surface: true),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LumiAdaptive.color(muted.withValues(alpha: .3)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.discount_outlined, color: LumiAdaptive.color(rose)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LumiAdaptive.text('Mã giảm giá LUMI'),
                        style: LumiAdaptive.style(
                          GoogleFonts.beVietnamPro(
                            color: LumiAdaptive.color(ink),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: LumiCouponStore.availableCoupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final coupon = LumiCouponStore.availableCoupons[index];
                    final isApplied = _appliedCoupon?.code == coupon.code;
                    final isEligible = subtotal >= coupon.minOrder;
                    final discountEst = coupon.calculateDiscount(
                      subtotal: subtotal.toInt(),
                      shippingFee: initialShippingFee.toInt(),
                    );

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: LumiAdaptive.color(Colors.white, surface: true),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isApplied
                              ? LumiAdaptive.color(rose)
                              : LumiAdaptive.color(blush),
                          width: isApplied ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rose.withValues(alpha: .04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: LumiAdaptive.color(blush, surface: true),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.confirmation_number_outlined,
                                    color: LumiAdaptive.color(rose), size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  coupon.badgeText,
                                  style: GoogleFonts.beVietnamPro(
                                    color: LumiAdaptive.color(rose),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        coupon.code,
                                        style: const TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (discountEst > 0)
                                      Text(
                                        '- ${_money(discountEst)}',
                                        style: TextStyle(
                                          color: LumiAdaptive.color(rose),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  LumiAdaptive.text(coupon.title),
                                  style: LumiAdaptive.style(
                                    GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: LumiAdaptive.color(ink),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  LumiAdaptive.text(coupon.description),
                                  style: LumiAdaptive.style(
                                    GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: LumiAdaptive.color(muted),
                                    ),
                                  ),
                                ),
                                if (coupon.minOrder > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    LumiAdaptive.text('Đơn tối thiểu: ${_money(coupon.minOrder)}'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isEligible
                                          ? LumiAdaptive.color(muted)
                                          : Colors.redAccent,
                                      fontWeight: isEligible ? FontWeight.normal : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isApplied
                                  ? const Color(0xFF16A34A)
                                  : (isEligible
                                      ? LumiAdaptive.color(rose)
                                      : LumiAdaptive.color(muted.withValues(alpha: 0.4))),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: !isEligible
                                ? null
                                : () {
                                    if (isApplied) {
                                      _removeCoupon();
                                    } else {
                                      _applyCoupon(coupon.code);
                                    }
                                    Navigator.pop(bottomSheetContext);
                                  },
                            child: Text(
                              LumiAdaptive.text(isApplied ? 'Đã dùng' : 'Dùng'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _couponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Mã giảm giá', Icons.discount_outlined),
            TextButton.icon(
              onPressed: _showCouponSheet,
              icon: Icon(Icons.confirmation_number_outlined, size: 16, color: LumiAdaptive.color(rose)),
              label: Text(
                LumiAdaptive.text('Xem voucher'),
                style: TextStyle(
                  color: LumiAdaptive.color(rose),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_appliedCoupon != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _appliedCoupon!.code,
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBBF7D0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              LumiAdaptive.text(_appliedCoupon!.badgeText),
                              style: const TextStyle(
                                color: Color(0xFF14532D),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${LumiAdaptive.text(_appliedCoupon!.title)} (-${_money(discountAmount)})',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: LumiAdaptive.text('Gỡ bỏ'),
                  icon: const Icon(Icons.close, color: Color(0xFF15803D), size: 20),
                  onPressed: _removeCoupon,
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: LumiAdaptive.text('Nhập mã voucher (VD: LUMISPA10)'),
                    hintStyle: TextStyle(
                      color: LumiAdaptive.color(muted.withValues(alpha: .6)),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.confirmation_number_outlined,
                        color: LumiAdaptive.color(rose), size: 20),
                    filled: true,
                    fillColor: LumiAdaptive.color(Colors.white, surface: true),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: LumiAdaptive.color(blush)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: LumiAdaptive.color(rose), width: 1.5),
                    ),
                  ),
                  onSubmitted: _applyCoupon,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: LumiAdaptive.color(rose),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: () => _applyCoupon(_couponController.text),
                  child: Text(
                    LumiAdaptive.text('Áp dụng'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        if (_couponError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              LumiAdaptive.text(_couponError!),
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
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
            GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, letterSpacing: .4),
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
            GoogleFonts.beVietnamPro(
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
                  GoogleFonts.beVietnamPro(color: LumiAdaptive.color(muted)),
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
                  if (_selectedAddress != null)
                    InkWell(
                      onTap: _chooseAddress,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: LumiAdaptive.color(Colors.white, surface: true),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LumiAdaptive.color(rose), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: rose.withValues(alpha: .06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: LumiAdaptive.color(rose), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        LumiAdaptive.text('Địa chỉ nhận hàng (Shopee)'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: LumiAdaptive.color(muted),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        LumiAdaptive.text('Thay đổi'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: LumiAdaptive.color(rose),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: LumiAdaptive.color(rose)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        _selectedAddress!.recipientName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedAddress!.phone,
                                        style: TextStyle(fontSize: 14, color: LumiAdaptive.color(ink.withValues(alpha: .8))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress!.displayAddress,
                                    style: TextStyle(fontSize: 13, color: LumiAdaptive.color(ink.withValues(alpha: .85))),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (_selectedAddress!.isDefault) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFBE7DC),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: LumiAdaptive.color(rose)),
                                          ),
                                          child: Text(
                                            LumiAdaptive.text('Mặc định'),
                                            style: TextStyle(color: LumiAdaptive.color(rose), fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F1F5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          LumiAdaptive.text(_selectedAddress!.label),
                                          style: const TextStyle(color: Color(0xFF406779), fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (FirebaseAuth.instance.currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OutlinedButton.icon(
                        onPressed: _chooseAddress,
                        icon: const Icon(Icons.location_on_outlined, size: 18),
                        label: Text(LumiAdaptive.text('Chọn từ sổ địa chỉ nhận hàng')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LumiAdaptive.color(rose),
                          side: BorderSide(color: LumiAdaptive.color(rose.withValues(alpha: .5))),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
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
                  if (FirebaseAuth.instance.currentUser != null && _selectedAddress == null)
                    CheckboxListTile(
                      value: _saveToAddressBook,
                      onChanged: (val) => setState(() => _saveToAddressBook = val ?? true),
                      title: Text(
                        LumiAdaptive.text('Lưu địa chỉ này vào sổ địa chỉ nhận hàng của tôi'),
                        style: TextStyle(fontSize: 13, color: LumiAdaptive.color(ink)),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: LumiAdaptive.color(rose),
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
                  _couponSection(),
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
                        if (discountAmount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${LumiAdaptive.text('Giảm giá')} (${_appliedCoupon?.code ?? ''})',
                                  style: LumiAdaptive.style(
                                    GoogleFonts.beVietnamPro(
                                      color: const Color(0xFF16A34A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '- ${_money(discountAmount)}',
                                  style: LumiAdaptive.style(
                                    GoogleFonts.beVietnamPro(
                                      color: const Color(0xFF16A34A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      GoogleFonts.beVietnamPro(
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
