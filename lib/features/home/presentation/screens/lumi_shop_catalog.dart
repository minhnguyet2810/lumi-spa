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
  String selectedSize = 'Tất cả';
  int maxPrice = 1000000;
  String sortOrder = 'popular';

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
    setState(() => products = next);

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
    if (value is num) return value;
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

  String? _imageUrl(Map<String, dynamic> item) {
    final images = item['imageUrls'];

    if (images is List) {
      for (final image in images) {
        if (image is String && image.trim().isNotEmpty) {
          return image.trim();
        }
      }
    }

    for (final key in [
      'imageUrl',
      'image',
      'thumbnail',
    ]) {
      final value = item[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  Widget _photo(
    Map<String, dynamic> item, {
    double height = 145,
  }) {
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
          ? const Icon(
              Icons.spa_outlined,
              size: 55,
              color: rose,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.spa_outlined,
                  size: 55,
                  color: rose,
                );
              },
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

  Widget _filterPanel(List<Map<String, dynamic>> items) {
    final sizes = [
      'Tất cả',
      ...items.map(_size).toSet().toList()..sort(),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: blush.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: rose,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Lọc sản phẩm',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    selected = 'Tất cả';
                    selectedSize = 'Tất cả';
                    maxPrice = 1000000;
                    sortOrder = 'popular';
                  });
                },
                child: const Text('Đặt lại'),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Dung tích / quy cách',
            style: GoogleFonts.dmSans(
              color: muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: sizes.map((size) {
              final isSelected = selectedSize == size;

              return ChoiceChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => selectedSize = size);
                },
                selectedColor: rose,
                backgroundColor: Colors.white,
                showCheckmark: false,
                labelStyle: GoogleFonts.dmSans(
                  color: isSelected ? Colors.white : ink,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Giá tối đa: ${_money(maxPrice)}',
            style: GoogleFonts.dmSans(
              color: ink,
              fontSize: 13,
            ),
          ),
          Slider(
            value: maxPrice.toDouble(),
            min: 0,
            max: 1000000,
            divisions: 20,
            activeColor: rose,
            onChanged: (value) {
              setState(() => maxPrice = value.round());
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: sortOrder,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Sắp xếp',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'popular',
                child: Text('Mặc định / phổ biến'),
              ),
              DropdownMenuItem(
                value: 'low',
                child: Text('Giá thấp đến cao'),
              ),
              DropdownMenuItem(
                value: 'high',
                child: Text('Giá cao đến thấp'),
              ),
              DropdownMenuItem(
                value: 'name',
                child: Text('Tên A–Z'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => sortOrder = value);
              }
            },
          ),
        ],
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
                    Text(
                      'Giỏ hàng của bạn',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 35,
                        ),
                        child: Center(
                          child: Text('Giỏ hàng đang trống.'),
                        ),
                      ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final entry = lines[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _name(entry.value.product),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            subtitle: Text(
                              _money(entry.value.product['price']),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      entry.value.quantity--;

                                      if (entry.value.quantity <= 0) {
                                        cart.remove(entry.key);
                                      }
                                    });

                                    _updateCartBadge();
                                    refreshSheet(() {});
                                  },
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                                Text('${entry.value.quantity}'),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      entry.value.quantity++;
                                    });

                                    _updateCartBadge();
                                    refreshSheet(() {});
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                  ),
                                ),
                              ],
                            ),
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
            onChanged: (_) => setState(() {}),
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

              final activeSize =
                  items.any((item) => _size(item) == selectedSize)
                      ? selectedSize
                      : 'Tất cả';

              final filtered = items.where((item) {
                final matchesCategory =
                    active == 'Tất cả' ||
                    _category(item) == active;

                final matchesSize =
                    activeSize == 'Tất cả' ||
                    _size(item) == activeSize;

                final price = _amount(item['price']);

                final matchesPrice =
                    price != null &&
                    price >= 0 &&
                    price <= maxPrice;

                final text =
                    '${_name(item)} '
                    '${item['description'] ?? ''}'.toLowerCase();

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
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == active;

                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => selected = category);
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