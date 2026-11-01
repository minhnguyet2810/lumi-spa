import '../../../../core/widgets/lumi_catalog_image.dart';
import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_catalog_repository.dart';

class LumiCartItem {
  const LumiCartItem({required this.product, required this.quantity});

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

  static final ValueNotifier<int> cartQuantityNotifier = ValueNotifier<int>(0);

  static final Map<String, LumiCartLine> sessionCart = {};

  static List<LumiCartItem> get currentCart {
    return sessionCart.values
        .map(
          (line) =>
              LumiCartItem(product: line.product, quantity: line.quantity),
        )
        .toList();
  }

  static void clearCart() {
    sessionCart.clear();
    cartQuantityNotifier.value = 0;
  }

  const LumiShopCatalog({super.key, required this.onCheckout});

  final VoidCallback onCheckout;

  @override
  State<LumiShopCatalog> createState() => _LumiShopCatalogState();
}

class _LumiShopCatalogState extends State<LumiShopCatalog> {
  static const rose = Color(0xFFA5553E);
  static const ink = Color(0xFF403735);
  static const muted = Color(0xFF756863);
  static const blue = Color(0xFFEAF3F7);
  static const blush = Color(0xFFFBE7DC);
  static const cream = Color(0xFFFFF8EF);
  final search = TextEditingController();
  // Giữ giỏ hàng khi đổi tab và khi quay lại từ Login trong phiên app.
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

  Future<List<Map<String, dynamic>>> _fetch() async {
    return LumiCatalogRepository.fetchProducts();
  }

  Future<void> _refresh() async {
    final next = _fetch();
    setState(() => products = next);
    try {
      await next;
    } catch (_) {
      // Error state is displayed by FutureBuilder.
    }
  }

  String _name(Map<String, dynamic> item) =>
      (item['name'] ?? 'Sản phẩm LUMI').toString();

  String _category(Map<String, dynamic> item) {
    final raw = (item['category'] ?? item['categoryName'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return 'Khác';
    return raw;
  }

  num? _amount(dynamic raw) {
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  String _money(dynamic raw) {
    final value = _amount(raw);
    if (value == null || value <= 0) return 'Liên hệ tư vấn';
    final digits = value.toInt().toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';
  }

  String _key(Map<String, dynamic> item) =>
      (item['_id'] ?? item['id'] ?? _name(item)).toString();

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
      if (value.isNotEmpty) return value;
    }
    return 'Chưa rõ dung tích';
  }

  String _formatSizeForCategory(String category, String size) {
    if (size == 'Tất cả') return 'Tất cả dung tích / quy cách';

    if (category == 'Mặt nạ chăm sóc chuyên sâu') {
      if (size.contains('100g')) return 'Dạng hũ: $size (Mặt nạ đất sét / bùn)';
      if (size.contains('miếng')) {
        return 'Dạng hộp: $size (Mặt nạ miếng sinh học)';
      }
    }

    if (category == 'Chống nắng & Bảo vệ quang học') {
      if (size.contains('50ml')) {
        return 'Dạng tuýp: $size (Kem / Gel chống nắng)';
      }
      if (size.contains('15g')) return 'Dạng hộp: $size (Cushion phấn nước)';
    }

    if (category == 'Tinh chất đặc trị & Tế bào gốc') {
      if (size.contains('15ml')) {
        return 'Dạng lọ: $size (Serum đặc trị mụn SOS)';
      }
      if (size.contains('30ml')) {
        return 'Dạng lọ: $size (Serum phục hồi & dưỡng trắng)';
      }
      if (size.contains('50ml')) return 'Dạng chai: $size (Ampoule cấp ẩm B5)';
      if (size.contains('ống')) return 'Dạng vỉ: $size (Tế bào gốc EGF)';
    }

    if (category == 'Dưỡng ẩm & Khóa dưỡng') {
      if (size.contains('15ml')) return 'Dạng tuýp: $size (Kem mắt)';
      if (size.contains('30ml')) return 'Dạng lọ: $size (Dầu dưỡng da mặt)';
      if (size.contains('40ml')) return 'Dạng tuýp: $size (Balm phục hồi)';
      if (size.contains('50ml')) return 'Dạng tuýp: $size (Gel cream dưỡng ẩm)';
      if (size.contains('50g')) {
        return 'Dạng hũ: $size (Kem dưỡng khóa ẩm / Đêm)';
      }
      if (size.contains('80ml')) {
        return 'Dạng chai: $size (Lotion kiềm dầu / Mặt nạ ngủ)';
      }
    }

    if (category == 'Làm sạch & Cân bằng') {
      if (size.contains('70g')) {
        return 'Dạng lọ bột: $size (Bột rửa mặt Enzyme)';
      }
      if (size.contains('100ml')) return 'Dạng tuýp: $size (Gel tẩy da chết)';
      if (size.contains('150ml')) {
        return 'Dạng chai: $size (Sữa rửa mặt bọt / Toner / Xịt khoáng)';
      }
      if (size.contains('200ml')) {
        return 'Dạng chai: $size (Dầu / Gel rửa mặt / Toner)';
      }
      if (size.contains('300ml')) {
        return 'Dạng chai: $size (Nước tẩy trang Micellar)';
      }
    }

    if (category == 'Chăm sóc cơ thể & Dưỡng sinh') {
      if (size.contains('50ml')) return 'Dạng tuýp: $size (Kem dưỡng tay)';
      if (size.contains('100ml')) return 'Dạng chai: $size (Serum da đầu)';
      if (size.contains('150ml')) {
        return 'Dạng chai: $size (Serum AHA dưỡng thể)';
      }
      if (size.contains('200ml')) {
        return 'Dạng chai: $size (Dầu massage / Kem ủ tóc)';
      }
      if (size.contains('250ml')) return 'Dạng chai: $size (Sữa dưỡng thể)';
      if (size.contains('250g')) return 'Dạng hũ: $size (Muối tắm cà phê)';
      if (size.contains('300ml')) return 'Dạng chai: $size (Dầu gội thảo mộc)';
      if (size.contains('400g')) return 'Dạng hũ: $size (Muối ngâm chân gừng)';
      if (size.contains('2x10g')) {
        return 'Dạng hũ đôi: $size (Sáp dưỡng & tẩy tế bào chết môi)';
      }
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
    final categories = [
      'Tất cả',
      ...items.map(_category).toSet().toList()..sort(),
    ];

    // Quy cách tự động lọc theo Dòng sản phẩm chính đang chọn ("theo sản phẩm")
    final categoryFilteredItems = selected == 'Tất cả'
        ? items
        : items.where((it) => _category(it) == selected).toList();

    final availableSizes = [
      'Tất cả',
      ...categoryFilteredItems.map(_size).toSet().toList()..sort(),
    ];

    final isFiltered =
        selected != 'Tất cả' ||
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
        color: LumiAdaptive.color(const Color(0xFFFBF4F5), surface: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LumiAdaptive.color(
            _isFilterExpanded
                ? rose.withValues(alpha: 0.35)
                : const Color(0xFFEFE4E6),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: LumiAdaptive.color(
              ink.withValues(alpha: .03),
              surface: true,
            ),
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
                      color: LumiAdaptive.color(blush, surface: true),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: LumiAdaptive.color(rose),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    LumiAdaptive.text('Bộ lọc & Sắp xếp'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: LumiAdaptive.color(ink),
                      ),
                    ),
                  ),
                  if (isFiltered) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: LumiAdaptive.color(rose, surface: true),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        LumiAdaptive.text('Đang lọc ($activeFilterCount)'),
                        style: LumiAdaptive.style(
                          TextStyle(
                            color: LumiAdaptive.color(Colors.white),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isFiltered) ...[
                    TextButton(
                      style: LumiAdaptive.style(
                        TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
                        LumiAdaptive.text('Đặt lại'),
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: LumiAdaptive.color(rose),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: LumiAdaptive.color(ink),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MENU BỘ LỌC CHI TIẾT (Mở rộng khi chạm vào)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Divider(
                  color: LumiAdaptive.color(Color(0xFFEFE4E6), surface: true),
                  height: 1,
                ),
                const SizedBox(height: 14),

                // 1. Lọc theo từng dòng sản phẩm chính
                Text(
                  LumiAdaptive.text('Dòng sản phẩm chính'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('category_$selected'),
                  initialValue: categories.contains(selected)
                      ? selected
                      : 'Tất cả',
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.auto_awesome_outlined,
                      color: LumiAdaptive.color(rose),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: LumiAdaptive.color(Colors.white, surface: true),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                  ),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(
                        LumiAdaptive.text(
                          cat == 'Tất cả' ? 'Tất cả dòng sản phẩm' : cat,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selected = val;
                        selectedSize = 'Tất cả';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Dung tích & quy cách tự động hiện theo sản phẩm
                Text(
                  LumiAdaptive.text(
                    'Dung tích / Quy cách (tự động theo sản phẩm)',
                  ),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('size_${selected}_$selectedSize'),
                  initialValue: availableSizes.contains(selectedSize)
                      ? selectedSize
                      : 'Tất cả',
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.inventory_2_outlined,
                      color: LumiAdaptive.color(rose),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: LumiAdaptive.color(Colors.white, surface: true),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                  ),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                    ),
                  ),
                  items: availableSizes.map((size) {
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text(
                        LumiAdaptive.text(
                          _formatSizeForCategory(selected, size),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedSize = val);
                  },
                ),
                const SizedBox(height: 14),

                // 3. Khoảng giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LumiAdaptive.text('Khoảng giá'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          color: LumiAdaptive.color(ink),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      LumiAdaptive.text(
                        '${_money(minPrice)} – ${_money(maxPrice)}',
                      ),
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
                const SizedBox(height: 4),
                RangeSlider(
                  values: RangeValues(
                    minPrice.toDouble().clamp(0, 1000000),
                    maxPrice.toDouble().clamp(0, 1000000),
                  ),
                  min: 0,
                  max: 1000000,
                  divisions: 20,
                  activeColor: LumiAdaptive.color(rose),
                  inactiveColor: LumiAdaptive.color(const Color(0xFFE5DCDA)),
                  labels: RangeLabels(_money(minPrice), _money(maxPrice)),
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
                  LumiAdaptive.text('Sắp xếp'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey('sort_$sortOrder'),
                  initialValue: sortOrder,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.sort_rounded,
                      color: LumiAdaptive.color(rose),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: LumiAdaptive.color(Colors.white, surface: true),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                      ),
                    ),
                  ),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      color: LumiAdaptive.color(ink),
                      fontSize: 14,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'popular',
                      child: Text(LumiAdaptive.text('Phổ biến nhất')),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text(
                        LumiAdaptive.text('Giá tăng dần (Thấp đến cao)'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text(
                        LumiAdaptive.text('Giá giảm dần (Cao đến thấp)'),
                      ),
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
                    icon: Icon(
                      Icons.expand_less_rounded,
                      size: 18,
                      color: LumiAdaptive.color(rose),
                    ),
                    label: Text(
                      LumiAdaptive.text('Thu gọn bộ lọc'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LumiAdaptive.color(rose),
                        ),
                      ),
                    ),
                    style: LumiAdaptive.style(
                      OutlinedButton.styleFrom(
                        side: BorderSide(color: LumiAdaptive.color(rose)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
            color: LumiAdaptive.color(
              isSelected ? rose : Colors.white,
              surface: true,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: LumiAdaptive.color(
                isSelected ? rose : const Color(0xFFE5DCDA),
              ),
            ),
          ),
          child: Text(
            LumiAdaptive.text(label),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: LumiAdaptive.color(isSelected ? Colors.white : ink),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _imageUrl(Map<String, dynamic> item) {
    final urls = LumiImageSources.fromItem(item);
    return urls.isEmpty ? null : urls.first;
  }

  Widget _photo(Map<String, dynamic> item, {double height = 145}) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: LumiCatalogImage(item: item, height: height),
  );

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
      SnackBar(content: Text(LumiAdaptive.text('Đã thêm vào giỏ hàng'))),
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
          title: Text(LumiAdaptive.text('Xóa sản phẩm?')),
          content: Text(
            LumiAdaptive.text(
              'Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng không?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(LumiAdaptive.text('Hủy')),
            ),
            FilledButton(
              style: LumiAdaptive.style(
                FilledButton.styleFrom(
                  backgroundColor: LumiAdaptive.color(rose, surface: true),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(LumiAdaptive.text('Xóa')),
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

  Widget _emptyCartView(BuildContext sheetContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 65,
              color: LumiAdaptive.color(rose),
            ),
            const SizedBox(height: 15),
            Text(
              LumiAdaptive.text('Giỏ hàng đang trống'),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(ink),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LumiAdaptive.text(
                'Hãy khám phá các sản phẩm chăm sóc da của LUMI.',
              ),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(muted),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
              },
              style: LumiAdaptive.style(
                OutlinedButton.styleFrom(
                  foregroundColor: LumiAdaptive.color(rose),
                  side: BorderSide(color: LumiAdaptive.color(rose)),
                ),
              ),
              child: Text(LumiAdaptive.text('Tiếp tục mua sắm')),
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
        color: LumiAdaptive.color(onPressed == null ? Colors.grey : rose),
      ),
    );
  }

  void _cartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LumiAdaptive.color(cream, surface: true),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refreshSheet) {
            final lines = cart.entries.toList();

            final total = lines.fold<num>(0, (sum, entry) {
              final price = _amount(entry.value.product['price']) ?? 0;

              return sum + price * entry.value.quantity;
            });

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          LumiAdaptive.text('Giỏ hàng của bạn'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(ink),
                            ),
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: LumiAdaptive.color(
                                      blue,
                                      surface: true,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _imageUrl(line.product) == null
                                      ? Icon(
                                          Icons.spa_outlined,
                                          color: LumiAdaptive.color(rose),
                                        )
                                      : Image.network(
                                          _imageUrl(line.product)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) {
                                            return Icon(
                                              Icons.spa_outlined,
                                              color: LumiAdaptive.color(rose),
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
                                        LumiAdaptive.text(_name(line.product)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: LumiAdaptive.style(
                                          GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w600,
                                            color: LumiAdaptive.color(ink),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        LumiAdaptive.text(
                                          _money(line.product['price']),
                                        ),
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
                                      LumiAdaptive.text('${line.quantity}'),
                                      style: LumiAdaptive.style(
                                        GoogleFonts.dmSans(
                                          color: LumiAdaptive.color(ink),
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: LumiAdaptive.color(
                                          Colors.redAccent,
                                        ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LumiAdaptive.text('Tạm tính')),
                        Text(
                          LumiAdaptive.text(_money(total)),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(ink),
                            ),
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
                        style: LumiAdaptive.style(
                          FilledButton.styleFrom(
                            backgroundColor: LumiAdaptive.color(
                              rose,
                              surface: true,
                            ),
                            disabledBackgroundColor: LumiAdaptive.color(
                              Colors.grey.shade300,
                              surface: true,
                            ),
                            padding: const EdgeInsets.all(17),
                          ),
                        ),
                        child: Text(LumiAdaptive.text('Tiếp tục thanh toán')),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LumiAdaptive.text(
                        'Giỏ hàng hiện chỉ lưu trong phiên sử dụng.',
                      ),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 14,
                          color: LumiAdaptive.color(muted),
                        ),
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
            backgroundColor: LumiAdaptive.color(cream, surface: true),
            appBar: AppBar(
              title: Text(LumiAdaptive.text('Chi tiết sản phẩm')),
              backgroundColor: LumiAdaptive.color(cream, surface: true),
              foregroundColor: LumiAdaptive.color(ink),
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
                          LumiAdaptive.text('LUMI BEAUTY'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(rose),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LumiAdaptive.text(_name(item)),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 37,
                              fontWeight: FontWeight.w600,
                              color: LumiAdaptive.color(ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          LumiAdaptive.text(_money(item['price'])),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(rose),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          LumiAdaptive.text('Giới thiệu sản phẩm'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: LumiAdaptive.color(ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          LumiAdaptive.text(
                            (item['description'] ??
                                    'Thông tin đang được cập nhật.')
                                .toString(),
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 16,
                              height: 1.6,
                              color: LumiAdaptive.color(muted),
                            ),
                          ),
                        ),
                        if ((item['ingredients'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            LumiAdaptive.text('Thành phần'),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: LumiAdaptive.color(ink),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            LumiAdaptive.text(item['ingredients'].toString()),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 15,
                                color: LumiAdaptive.color(muted),
                              ),
                            ),
                          ),
                        ],
                        if ((item['usage'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            LumiAdaptive.text('Hướng dẫn sử dụng'),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: LumiAdaptive.color(ink),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            LumiAdaptive.text(item['usage'].toString()),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 15,
                                color: LumiAdaptive.color(muted),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: LumiAdaptive.style(
                          FilledButton.styleFrom(
                            backgroundColor: LumiAdaptive.color(
                              rose,
                              surface: true,
                            ),
                          ),
                        ),
                        onPressed: () {
                          _add(item);
                          Navigator.of(detailContext).pop();
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(LumiAdaptive.text('Thêm vào giỏ hàng')),
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

  Widget _empty(String title, String description, {bool retry = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(blue, surface: true),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 42,
            color: LumiAdaptive.color(rose),
          ),
          const SizedBox(height: 12),
          Text(
            LumiAdaptive.text(title),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LumiAdaptive.text(description),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.5,
                color: LumiAdaptive.color(muted),
              ),
            ),
          ),
          if (retry)
            TextButton(
              onPressed: _refresh,
              child: Text(LumiAdaptive.text('THỬ LẠI')),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    LumiShopCatalog.openActiveCart = _cartSheet;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: LumiAdaptive.color(rose, surface: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 115),
        children: [
          // LUMI V4: Cart in shared AppBar.
          Text(
            LumiAdaptive.text('Chăm sóc da mỗi ngày'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            LumiAdaptive.text(
              'Khám phá những sản phẩm chăm sóc da '
              'được lựa chọn dành cho bạn.',
            ),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                color: LumiAdaptive.color(muted),
              ),
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          LumiAdaptive.color(Color(0xB0392630), surface: true),
                          LumiAdaptive.color(Color(0x44392630), surface: true),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          LumiAdaptive.text('THE LUMI COLLECTION'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(Colors.white),
                              fontSize: 14,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          LumiAdaptive.text('Đẹp từ những\nđiều dịu dàng.'),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(Colors.white),
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
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
            onChanged: (_) => setState(() {}),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(fontSize: 16, color: LumiAdaptive.color(ink)),
            ),
            decoration: InputDecoration(
              hintText: LumiAdaptive.optionalText(
                'Tìm sản phẩm chăm sóc da...',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: LumiAdaptive.color(rose),
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
              fillColor: LumiAdaptive.color(Colors.white, surface: true),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: LumiAdaptive.color(blush)),
              ),
            ),
          ),
          const SizedBox(height: 19),
          Text(
            LumiAdaptive.text('Bộ sưu tập LUMI'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: products,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LumiAdaptive.color(rose),
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
                  'Các sản phẩm và giá chính thức sẽ xuất hiện khi LUMI cập nhật dữ liệu.',
                );
              }
              final categories = ['Tất cả', ...items.map(_category).toSet()];
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
                    text.contains(search.text.trim().toLowerCase());
              }).toList();
              if (sortOrder == 'low') {
                filtered.sort(
                  (a, b) => (_amount(a['price']) ?? 0).compareTo(
                    _amount(b['price']) ?? 0,
                  ),
                );
              } else if (sortOrder == 'high') {
                filtered.sort(
                  (a, b) => (_amount(b['price']) ?? 0).compareTo(
                    _amount(a['price']) ?? 0,
                  ),
                );
              } else {
                // popular: sắp xếp theo thứ tự phổ biến
                filtered.sort((a, b) {
                  final orderA =
                      int.tryParse(a['sortOrder']?.toString() ?? '') ?? 999;
                  final orderB =
                      int.tryParse(b['sortOrder']?.toString() ?? '') ?? 999;
                  return orderA.compareTo(orderB);
                });
              }

              // popular giữ thứ tự do API cung cấp; chưa có số lượt bán thực tế.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ChoiceChip(
                          label: Text(LumiAdaptive.text(category)),
                          selected: category == active,
                          onSelected: (_) =>
                              setState(() => selected = category),
                          selectedColor: LumiAdaptive.color(
                            rose,
                            surface: true,
                          ),
                          backgroundColor: LumiAdaptive.color(
                            index.isEven ? blush : blue,
                            surface: true,
                          ),
                          showCheckmark: false,
                          labelStyle: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(
                                category == active ? Colors.white : ink,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
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
                    LumiAdaptive.text('${filtered.length} sản phẩm'),
                    style: LumiAdaptive.style(
                      GoogleFonts.dmSans(
                        color: LumiAdaptive.color(muted),
                        fontSize: 14,
                      ),
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
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent:
                          345 +
                          (MediaQuery.textScalerOf(context).scale(16) - 16)
                                  .clamp(0.0, 80.0) *
                              5,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return InkWell(
                        onTap: () => _details(item),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: LumiAdaptive.color(
                              Colors.white,
                              surface: true,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: LumiAdaptive.color(blush),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _photo(item, height: 135),
                              const SizedBox(height: 9),
                              Text(
                                LumiAdaptive.text(_name(item)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: LumiAdaptive.color(ink),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                LumiAdaptive.text(_money(item['price'])),
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: LumiAdaptive.color(rose),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _details(item),
                                  style: LumiAdaptive.style(
                                    OutlinedButton.styleFrom(
                                      foregroundColor: LumiAdaptive.color(rose),
                                      side: BorderSide(
                                        color: LumiAdaptive.color(rose),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    LumiAdaptive.text('Xem chi tiết'),
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
              color: LumiAdaptive.color(blue, surface: true),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              LumiAdaptive.text(
                'LUMI BEAUTY · Một chút chăm sóc, một chút yêu thương dành cho chính mình.',
              ),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.5,
                  color: LumiAdaptive.color(ink),
                ),
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
