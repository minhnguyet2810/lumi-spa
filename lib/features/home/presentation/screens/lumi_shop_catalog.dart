import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_catalog_repository.dart';

class LumiCartItem {
  const LumiCartItem({
    required this.product,
    required this.quantity,
  });

  final Map<String, dynamic> product;
  final int quantity;

  num get total {
    final rawPrice = product['price'];
    final price = rawPrice is num
        ? rawPrice
        : num.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return price * quantity;
  }
}

class LumiShopCatalog extends StatefulWidget {
  static VoidCallback? openActiveCart;

  static final ValueNotifier<int> cartQuantityNotifier =
      ValueNotifier<int>(0);

  static final Map<String, LumiCartLine> sessionCart = {};

  static List<LumiCartItem> get currentCart {
    return sessionCart.values
        .map(
          (line) => LumiCartItem(
            product: line.product,
            quantity: line.quantity,
          ),
        )
        .toList();
  }

  static void clearCart() {
    sessionCart.clear();
    cartQuantityNotifier.value = 0;
  }

  const LumiShopCatalog({
    super.key,
    required this.onCheckout,
  });

  final VoidCallback onCheckout;

  @override
  State<LumiShopCatalog> createState() => _LumiShopCatalogState();
}

class _LumiShopCatalogState extends State<LumiShopCatalog> {
  static const rose = Color(0xFFB56F86);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF78676B);
  static const blue = Color(0xFFDDECEF);
  static const blush = Color(0xFFF4E4E8);
  static const cream = Color(0xFFFFFAF8);

  final search = TextEditingController();
  final Map<String, LumiCartLine> cart = LumiShopCatalog.sessionCart;

  String selected = 'Tất cả';
  // Bộ lọc sản phẩm LUMI: Dòng sản phẩm chính, Dung tích / Quy cách tự động theo sản phẩm
  String selectedSize = 'Tất cả';
  int minPrice = 0;
  int maxPrice = 1000000;
  String sortOrder = 'popular';
  bool _isFilterExpanded = false;
  late Future<List<Map<String, dynamic>>> products;

  @override
  void initState() {
    super.initState();
    products = _fetch();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() {
    return LumiCatalogRepository.fetchProducts();
  }

  Future<void> _refresh() async {
    final next = _fetch();

    setState(() {
      products = next;
    });

    try {
      await next;
    } catch (_) {}
  }

  String _name(Map<String, dynamic> item) {
    return (item['name'] ?? 'Sản phẩm LUMI').toString();
  }

  String _category(Map<String, dynamic> item) {
    final category = (
      item['category'] ??
      item['categoryName'] ??
      ''
    ).toString().trim();

    return category.isEmpty ? 'Khác' : category;
  }

  num? _amount(dynamic value) {
    if (value is num) {
      return value;
    }

    return num.tryParse(value?.toString() ?? '');
  }

  String _money(dynamic raw) {
    final value = _amount(raw);

    if (value == null || value <= 0) {
      return 'Liên hệ tư vấn';
    }

    final digits = value.toInt().toString();

    return '${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )} đ';
  }

  String _key(Map<String, dynamic> item) {
    return (
      item['_id'] ??
      item['id'] ??
      _name(item)
    ).toString();
  }

  String _size(Map<String, dynamic> item) {
    for (final field in [
      'size',
      'volume',
      'capacity',
      'dungTich',
      'quyCach',
      'packaging',
    ]) {
      final value = item[field]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Chưa rõ dung tích';
  }

  String _formatSizeForCategory(String category, String size) {
    if (size == 'Tất cả') return 'Tất cả dung tích / quy cách';

    if (category == 'Mặt nạ chăm sóc chuyên sâu') {
      if (size.contains('100g')) return 'Dạng hũ: $size (Mặt nạ đất sét / bùn)';
      if (size.contains('miếng')) return 'Dạng hộp: $size (Mặt nạ miếng sinh học)';
    }

    if (category == 'Chống nắng & Bảo vệ quang học') {
      if (size.contains('50ml')) return 'Dạng tuýp: $size (Kem / Gel chống nắng)';
      if (size.contains('15g')) return 'Dạng hộp: $size (Cushion phấn nước)';
    }

    if (category == 'Tinh chất đặc trị & Tế bào gốc') {
      if (size.contains('15ml')) return 'Dạng lọ: $size (Serum đặc trị mụn SOS)';
      if (size.contains('30ml')) return 'Dạng lọ: $size (Serum phục hồi & dưỡng trắng)';
      if (size.contains('50ml')) return 'Dạng chai: $size (Ampoule cấp ẩm B5)';
      if (size.contains('ống')) return 'Dạng vỉ: $size (Tế bào gốc EGF)';
    }

    if (category == 'Dưỡng ẩm & Khóa dưỡng') {
      if (size.contains('15ml')) return 'Dạng tuýp: $size (Kem mắt)';
      if (size.contains('30ml')) return 'Dạng lọ: $size (Dầu dưỡng da mặt)';
      if (size.contains('40ml')) return 'Dạng tuýp: $size (Balm phục hồi)';
      if (size.contains('50ml')) return 'Dạng tuýp: $size (Gel cream dưỡng ẩm)';
      if (size.contains('50g')) return 'Dạng hũ: $size (Kem dưỡng khóa ẩm / Đêm)';
      if (size.contains('80ml')) return 'Dạng chai: $size (Lotion kiềm dầu / Mặt nạ ngủ)';
    }

    if (category == 'Làm sạch & Cân bằng') {
      if (size.contains('70g')) return 'Dạng lọ bột: $size (Bột rửa mặt Enzyme)';
      if (size.contains('100ml')) return 'Dạng tuýp: $size (Gel tẩy da chết)';
      if (size.contains('150ml')) return 'Dạng chai: $size (Sữa rửa mặt bọt / Toner / Xịt khoáng)';
      if (size.contains('200ml')) return 'Dạng chai: $size (Dầu / Gel rửa mặt / Toner)';
      if (size.contains('300ml')) return 'Dạng chai: $size (Nước tẩy trang Micellar)';
    }

    if (category == 'Chăm sóc cơ thể & Dưỡng sinh') {
      if (size.contains('50ml')) return 'Dạng tuýp: $size (Kem dưỡng tay)';
      if (size.contains('100ml')) return 'Dạng chai: $size (Serum da đầu)';
      if (size.contains('150ml')) return 'Dạng chai: $size (Serum AHA dưỡng thể)';
      if (size.contains('200ml')) return 'Dạng chai: $size (Dầu massage / Kem ủ tóc)';
      if (size.contains('250ml')) return 'Dạng chai: $size (Sữa dưỡng thể)';
      if (size.contains('250g')) return 'Dạng hũ: $size (Muối tắm cà phê)';
      if (size.contains('300ml')) return 'Dạng chai: $size (Dầu gội thảo mộc)';
      if (size.contains('400g')) return 'Dạng hũ: $size (Muối ngâm chân gừng)';
      if (size.contains('2x10g')) return 'Dạng hũ đôi: $size (Sáp dưỡng & tẩy tế bào chết môi)';
    }

    final s = size.toLowerCase();
    if (s.contains('hũ')) return 'Dạng hũ: $size';
    if (s.contains('hộp') || s.contains('miếng')) return 'Dạng hộp: $size';
    if (s.contains('ống')) return 'Dạng vỉ / ống: $size';
    if (s.contains('g')) return 'Dạng hũ / lọ: $size';
    if (s.contains('ml')) return 'Dạng tuýp / chai: $size';
    return size;
  }

  Widget _filterPanel(List<Map<String, dynamic>> items) {
    final categories = ['Tất cả', ...items.map(_category).toSet().toList()..sort()];

    // Quy cách tự động lọc theo Dòng sản phẩm chính đang chọn ("theo sản phẩm")
    final categoryFilteredItems = selected == 'Tất cả'
        ? items
        : items.where((it) => _category(it) == selected).toList();

    final availableSizes = [
      'Tất cả',
      ...categoryFilteredItems.map(_size).toSet().toList()..sort(),
    ];

    final isFiltered = selected != 'Tất cả' ||
        selectedSize != 'Tất cả' ||
        minPrice > 0 ||
        maxPrice < 1000000 ||
        sortOrder != 'popular';

    int activeFilterCount = 0;
    if (selected != 'Tất cả') activeFilterCount++;
    if (selectedSize != 'Tất cả') activeFilterCount++;
    if (minPrice > 0 || maxPrice < 1000000) activeFilterCount++;
    if (sortOrder != 'popular') activeFilterCount++;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isFilterExpanded ? rose.withValues(alpha: 0.35) : const Color(0xFFEFE4E6),
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THANH NGANG GỌN GÀNG (Chạm vào để mở rộng/thu gọn menu filter)
          InkWell(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: blush,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: rose, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bộ lọc & Sắp xếp',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: ink,
                    ),
                  ),
                  if (isFiltered) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: rose,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Đang lọc ($activeFilterCount)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isFiltered) ...[
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setState(() {
                        selected = 'Tất cả';
                        selectedSize = 'Tất cả';
                        minPrice = 0;
                        maxPrice = 1000000;
                        sortOrder = 'popular';
                        search.clear();
                      }),
                      child: Text(
                        'Đặt lại',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: rose,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: rose,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PHẦN MỞ RỘNG KHI CHẠM VÀO
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEFE4E6)),
                const SizedBox(height: 14),

                // 1. Dòng sản phẩm chính
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dòng sản phẩm',
                      style: GoogleFonts.dmSans(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${categories.length - 1} dòng',
                      style: GoogleFonts.dmSans(color: muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('category_$selected'),
                  initialValue: categories.contains(selected) ? selected : 'Tất cả',
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category_outlined, color: rose, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                  ),
                  style: GoogleFonts.dmSans(color: ink, fontSize: 13),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontWeight: cat == selected ? FontWeight.w700 : FontWeight.w400,
                          color: cat == selected ? rose : ink,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selected = value;
                        selectedSize = 'Tất cả';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Dung tích & Quy cách theo sản phẩm
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dung tích / Quy cách (Theo sản phẩm)',
                        style: GoogleFonts.dmSans(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected != 'Tất cả')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: blush,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Theo $selected',
                          style: GoogleFonts.dmSans(
                            color: rose,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('size_${selected}_$selectedSize'),
                  initialValue: availableSizes.contains(selectedSize) ? selectedSize : 'Tất cả',
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.aspect_ratio_rounded, color: rose, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                  ),
                  style: GoogleFonts.dmSans(color: ink, fontSize: 13),
                  items: availableSizes.map((size) {
                    final displayLabel = _formatSizeForCategory(selected, size);
                    return DropdownMenuItem(
                      value: size,
                      child: Text(
                        displayLabel,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontWeight: size == selectedSize ? FontWeight.w700 : FontWeight.w400,
                          color: size == selectedSize ? rose : ink,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedSize = value);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 3. Khoảng giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khoảng giá',
                      style: GoogleFonts.dmSans(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_money(minPrice)} – ${_money(maxPrice)}',
                      style: GoogleFonts.dmSans(
                        color: rose,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(minPrice.toDouble(), maxPrice.toDouble()),
                  min: 0,
                  max: 1000000,
                  divisions: 20,
                  activeColor: rose,
                  inactiveColor: blush,
                  onChanged: (values) {
                    setState(() {
                      minPrice = values.start.round();
                      maxPrice = values.end.round();
                    });
                  },
                ),
                Row(
                  children: [
                    _priceChip('Tất cả', 0, 1000000),
                    const SizedBox(width: 6),
                    _priceChip('< 350k', 0, 350000),
                    const SizedBox(width: 6),
                    _priceChip('350k–500k', 350000, 500000),
                    const SizedBox(width: 6),
                    _priceChip('> 500k', 500000, 1000000),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Sắp xếp
                Text(
                  'Sắp xếp',
                  style: GoogleFonts.dmSans(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('sort_$sortOrder'),
                  initialValue: sortOrder,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.sort_rounded, color: rose, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                    ),
                  ),
                  style: GoogleFonts.dmSans(color: ink, fontSize: 13),
                  items: const [
                    DropdownMenuItem(
                      value: 'popular',
                      child: Text('Phổ biến nhất'),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Giá tăng dần (Thấp đến cao)'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('Giá giảm dần (Cao đến thấp)'),
                    ),
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Tên sản phẩm A–Z'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => sortOrder = value);
                  },
                ),
                const SizedBox(height: 16),

                // Nút thu gọn bộ lọc
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isFilterExpanded = false),
                    icon: const Icon(Icons.expand_less_rounded, size: 18, color: rose),
                    label: Text(
                      'Thu gọn bộ lọc',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rose,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: rose),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _priceChip(String label, int min, int max) {
    final isSelected = minPrice == min && maxPrice == max;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          minPrice = min;
          maxPrice = max;
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? rose : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? rose : const Color(0xFFE5DCDA),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : ink,
            ),
          ),
        ),
      ),
    );
  }

  String? _imageUrl(Map<String, dynamic> item) {
    final images = item['imageUrls'];
    if (images is List) {
      for (final image in images) {
        if (image is String && image.trim().isNotEmpty) {
          return image.trim();
        }
      }
    }

    for (final key in ['imageUrl', 'image', 'thumbnail']) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  Widget _photo(Map<String, dynamic> item, {double height = 145}) {
    final url = _imageUrl(item);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(17),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(Icons.spa_outlined, size: 55, color: rose)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.spa_outlined, size: 55, color: rose),
            ),
    );
  }

  void _updateCartBadge() {
    final quantity = cart.values.fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );

    LumiShopCatalog.cartQuantityNotifier.value = quantity;
  }

  void _add(Map<String, dynamic> item) {
    final key = _key(item);
    setState(() {
      final old = cart[key];
      if (old == null) {
        cart[key] = LumiCartLine(item, 1);
      } else {
        old.quantity++;
      }
    });

    _updateCartBadge();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng'),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext sheetContext,
    String key,
    VoidCallback refreshSheet,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa sản phẩm?'),
          content: const Text(
            'Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: rose,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) {
      return;
    }

    setState(() {
      cart.remove(key);
    });

    _updateCartBadge();
    refreshSheet();
  }

  Widget _emptyCartView(
    BuildContext sheetContext,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 65,
              color: rose,
            ),
            const SizedBox(height: 15),
            Text(
              'Giỏ hàng đang trống',
              style: GoogleFonts.dmSans(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá các sản phẩm chăm sóc da của LUMI.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: rose,
                side: const BorderSide(color: rose),
              ),
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        color: onPressed == null ? Colors.grey : rose,
      ),
    );
  }

  void _cartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refreshSheet) {
            final lines = cart.entries.toList();

            final total = lines.fold<num>(
              0,
              (sum, entry) {
                final price = _amount(
                      entry.value.product['price'],
                    ) ??
                    0;

                return sum + price * entry.value.quantity;
              },
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Giỏ hàng của bạn',
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (lines.isEmpty)
                      _emptyCartView(sheetContext)
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: lines.length,
                          separatorBuilder: (_, _) {
                            return const Divider(height: 10);
                          },
                          itemBuilder: (context, index) {
                            final entry = lines[index];
                            final line = entry.value;

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: blue,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _imageUrl(line.product) == null
                                      ? const Icon(
                                          Icons.spa_outlined,
                                          color: rose,
                                        )
                                      : Image.network(
                                          _imageUrl(line.product)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) {
                                            return const Icon(
                                              Icons.spa_outlined,
                                              color: rose,
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _name(line.product),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w600,
                                          color: ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _money(
                                          line.product['price'],
                                        ),
                                        style: GoogleFonts.dmSans(
                                          color: muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _quantityButton(
                                      icon: line.quantity == 1
                                          ? Icons.delete_outline
                                          : Icons.remove_circle_outline,
                                      onPressed: () {
                                        if (line.quantity == 1) {
                                          _confirmRemove(
                                            sheetContext,
                                            entry.key,
                                            () => refreshSheet(() {}),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          line.quantity--;
                                        });

                                        _updateCartBadge();
                                        refreshSheet(() {});
                                      },
                                    ),
                                    Text(
                                      '${line.quantity}',
                                      style: GoogleFonts.dmSans(
                                        color: ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    _quantityButton(
                                      icon: Icons.add_circle_outline,
                                      onPressed: () {
                                        setState(() {
                                          line.quantity++;
                                        });

                                        _updateCartBadge();
                                        refreshSheet(() {});
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _confirmRemove(
                                          sheetContext,
                                          entry.key,
                                          () => refreshSheet(() {}),
                                        );
                                      },
                                      visualDensity:
                                          VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính'),
                        Text(
                          _money(total),
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: lines.isEmpty
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                widget.onCheckout();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: rose,
                          disabledBackgroundColor:
                              Colors.grey.shade300,
                          padding: const EdgeInsets.all(17),
                        ),
                        child: const Text(
                          'Tiếp tục thanh toán',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giỏ hàng hiện chỉ lưu trong phiên sử dụng.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _details(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (detailContext) {
          return Scaffold(
            backgroundColor: cream,
            appBar: AppBar(
              title: const Text('Chi tiết sản phẩm'),
              backgroundColor: cream,
              foregroundColor: ink,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _photo(item, height: 260),
                        const SizedBox(height: 24),
                        Text(
                          'LUMI BEAUTY',
                          style: GoogleFonts.dmSans(
                            color: rose,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _name(item),
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 37,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _money(item['price']),
                          style: GoogleFonts.dmSans(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: rose,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Giới thiệu sản phẩm',
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          (
                            item['description'] ??
                            'Thông tin đang được cập nhật.'
                          ).toString(),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.6,
                            color: muted,
                          ),
                        ),
                        if ((item['ingredients'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Thành phần',
                            style: GoogleFonts.dmSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item['ingredients'].toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: muted,
                            ),
                          ),
                        ],
                        if ((item['usage'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Hướng dẫn sử dụng',
                            style: GoogleFonts.dmSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item['usage'].toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      18,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: rose,
                        ),
                        onPressed: () {
                          _add(item);
                          Navigator.of(detailContext).pop();
                        },
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                        ),
                        label: const Text(
                          'Thêm vào giỏ hàng',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(
    String title,
    String description, {
    bool retry = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 42,
            color: rose,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.5,
              color: muted,
            ),
          ),
          if (retry)
            TextButton(
              onPressed: _refresh,
              child: const Text('THỬ LẠI'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LumiShopCatalog.openActiveCart = _cartSheet;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: rose,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          115,
        ),
        children: [
          Text(
            'Chăm sóc da,\nnâng niu bản thân.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              height: 1.02,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Khám phá những sản phẩm chăm sóc da '
            'được lựa chọn dành cho bạn.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.4,
              color: muted,
            ),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: SizedBox(
              height: 165,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/welcome_spa_1.png',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xB0392630),
                          Color(0x44392630),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        Text(
                          'THE LUMI COLLECTION',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Đẹp từ những\nđiều dịu dàng.',
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.02,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: search,
            onChanged: (_) {
              setState(() {});
            },
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: ink,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm chăm sóc da...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: rose,
              ),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: blush),
              ),
            ),
          ),
          const SizedBox(height: 19),
          Text(
            'Bộ sưu tập LUMI',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: products,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: rose,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _empty(
                  'Chưa thể kết nối cửa hàng',
                  'Kiểm tra máy chủ LUMI API rồi thử lại.',
                  retry: true,
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return _empty(
                  'Bộ sưu tập đang được chuẩn bị',
                  'Các sản phẩm sẽ xuất hiện khi LUMI cập nhật dữ liệu.',
                );
              }

              final categories = [
                'Tất cả',
                ...items.map(_category).toSet(),
              ];

              final active = categories.contains(selected)
                  ? selected
                  : 'Tất cả';
final categoryFilteredItems = active == 'Tất cả'
                  ? items
                  : items.where((it) => _category(it) == active).toList();
              final availableSizes = [
                'Tất cả',
                ...categoryFilteredItems.map(_size).toSet(),
              ];
              final activeSize = availableSizes.contains(selectedSize)
                  ? selectedSize
                  : 'Tất cả';

              final filtered = items.where((item) {
                final matchesCategory =
                    active == 'Tất cả' || _category(item) == active;
                final itemSize = _size(item);
                final matchesSize =
                    activeSize == 'Tất cả' || itemSize == activeSize;
                final price = _amount(item['price']);
                final matchesPrice =
                    price != null && price >= minPrice && price <= maxPrice;
                final text = '${_name(item)} ${item['description'] ?? ''}'
                    .toLowerCase();

                return matchesCategory &&
                    matchesSize &&
                    matchesPrice &&
                    text.contains(
                      search.text.trim().toLowerCase(),
                    );
              }).toList();

              if (sortOrder == 'low') {
                filtered.sort(
                  (a, b) => (_amount(a['price']) ?? 0)
                      .compareTo(_amount(b['price']) ?? 0),
                );
              } else if (sortOrder == 'high') {
                filtered.sort(
                  (a, b) => (_amount(b['price']) ?? 0)
                      .compareTo(_amount(a['price']) ?? 0),
                );
              } else if (sortOrder == 'name') {
                filtered.sort(
                  (a, b) => _name(a)
                      .toLowerCase()
                      .compareTo(_name(b).toLowerCase()),
                );
              } else {
                // popular: sắp xếp theo thứ tự phổ biến
                filtered.sort((a, b) {
                  final orderA = int.tryParse(a['sortOrder']?.toString() ?? '') ?? 999;
                  final orderB = int.tryParse(b['sortOrder']?.toString() ?? '') ?? 999;
                  return orderA.compareTo(orderB);
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(width: 8);
                      },
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == active;

                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selected = category;
                            });
                          },
                          selectedColor: rose,
                          backgroundColor:
                              index.isEven ? blush : blue,
                          showCheckmark: false,
                          labelStyle: GoogleFonts.dmSans(
                            color: isSelected
                                ? Colors.white
                                : ink,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _filterPanel(items),
                  const SizedBox(height: 17),
                  Text(
                    '${filtered.length} sản phẩm',
                    style: GoogleFonts.dmSans(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    _empty(
                      'Không tìm thấy sản phẩm',
                      'Thử từ khóa hoặc danh mục khác.',
                    ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 315,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return InkWell(
                        onTap: () => _details(item),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: blush),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _photo(item, height: 135),
                              const SizedBox(height: 9),
                              Text(
                                _name(item),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _money(item['price']),
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: rose,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _details(item),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: rose,
                                    side: const BorderSide(
                                      color: rose,
                                    ),
                                  ),
                                  child: const Text(
                                    'Xem chi tiết',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'LUMI BEAUTY · Một chút chăm sóc, '
              'một chút yêu thương dành cho chính mình.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.5,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LumiCartLine {
  LumiCartLine(this.product, this.quantity);

  final Map<String, dynamic> product;
  int quantity;
}