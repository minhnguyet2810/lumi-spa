import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_catalog_repository.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_formatters.dart';

class AdminProductInventoryScreen extends StatefulWidget {
  const AdminProductInventoryScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AdminProductInventoryScreen> createState() =>
      _AdminProductInventoryScreenState();
}

class _AdminProductInventoryScreenState
    extends State<AdminProductInventoryScreen> {
  final _searchController = TextEditingController();
  final String _selectedCategory = 'all';
  String _stockFilter = 'all'; // all, low_stock, in_stock, out_of_stock

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await LumiCatalogRepository.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getStock(Map<String, dynamic> item) {
    final raw = item['stock'] ?? item['inventory'] ?? item['stockQuantity'] ?? 25;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 25;
  }

  num _getPrice(Map<String, dynamic> item) {
    final raw = item['price'] ?? 0;
    if (raw is num) return raw;
    return num.tryParse(raw.toString()) ?? 0;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var result = _products;
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((p) {
        final name = (p['name'] ?? p['title'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        return name.contains(query) || id.contains(query) || brand.contains(query);
      }).toList();
    }

    if (_selectedCategory != 'all') {
      result = result.where((p) {
        final cat = (p['category'] ?? '').toString().toLowerCase();
        return cat == _selectedCategory.toLowerCase();
      }).toList();
    }

    if (_stockFilter == 'low_stock') {
      result = result.where((p) {
        final s = _getStock(p);
        return s > 0 && s < 10;
      }).toList();
    } else if (_stockFilter == 'out_of_stock') {
      result = result.where((p) => _getStock(p) == 0).toList();
    } else if (_stockFilter == 'in_stock') {
      result = result.where((p) => _getStock(p) >= 10).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalProducts = _products.length;
    final lowStockCount = _products.where((p) {
      final s = _getStock(p);
      return s > 0 && s < 10;
    }).length;
    final outOfStockCount = _products.where((p) => _getStock(p) == 0).length;
    final totalInventoryUnits = _products.fold<int>(0, (sum, p) => sum + _getStock(p));

    final bodyContent = RefreshIndicator(
      onRefresh: _loadProducts,
      color: AdminColors.primary,
      backgroundColor: AdminColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildKpiCard(
                        title: 'Tổng Mã Mỹ Phẩm',
                        value: '$totalProducts sản phẩm',
                        subtitle: 'Đang niêm yết danh mục',
                        icon: Icons.inventory_2_rounded,
                        color: AdminColors.primary,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildKpiCard(
                        title: 'Tổng Tồn Khả Dụng',
                        value: '$totalInventoryUnits đơn vị',
                        subtitle: 'Sẵn sàng xuất kho & điều trị',
                        icon: Icons.warehouse_rounded,
                        color: AdminColors.emerald,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildKpiCard(
                        title: 'Cảnh Báo Sắp Hết Hàng',
                        value: '$lowStockCount mã cần nhập',
                        subtitle: 'Tồn dưới 10 hộp/chai',
                        icon: Icons.warning_amber_rounded,
                        color: AdminColors.statusLowStock,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildKpiCard(
                        title: 'Hết Hàng Trong Kho',
                        value: '$outOfStockCount mã',
                        subtitle: 'Cần bổ sung gấp từ kho tổng',
                        icon: Icons.production_quantity_limits_rounded,
                        color: AdminColors.statusCancelled,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Control & Search Toolbar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.border),
                boxShadow: AdminColors.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: AdminColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên sản phẩm, mã SKU, thương hiệu...',
                            hintStyle: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AdminColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AdminColors.primary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AdminColors.elevatedSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AdminColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      FilledButton.icon(
                        onPressed: _loadProducts,
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          'LÀM MỚI KHO',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Bộ lọc tồn kho: ',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                        _buildStockChip('all', 'Tất cả (${_products.length})'),
                        _buildStockChip('low_stock', 'Sắp hết hàng ($lowStockCount)', color: AdminColors.statusLowStock),
                        _buildStockChip('out_of_stock', 'Hết hàng ($outOfStockCount)', color: AdminColors.statusCancelled),
                        _buildStockChip('in_stock', 'Tồn dồi dào', color: AdminColors.emerald),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Products Data Table / Grid
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: AdminColors.primary),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Không thể tải kho: $_error', style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadProducts, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else if (_filteredProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 54, color: AdminColors.textMuted),
                      const SizedBox(height: 14),
                      Text(
                        'Không có sản phẩm nào phù hợp.',
                        style: GoogleFonts.beVietnamPro(fontSize: 14, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildProductTable(_filteredProducts),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Container(
        color: AdminColors.background,
        child: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminColors.peach,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.border),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: AdminColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SẢN PHẨM & KHO HÀNG',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  'Quản trị định mức tồn kho mỹ phẩm spa, giá bán niêm yết & cảnh báo sắp hết hàng',
                  style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới kho',
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.primary),
            onPressed: _loadProducts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(String value, String label, {Color? color}) {
    final isSelected = _stockFilter == value;
    final chipColor = color ?? AdminColors.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _stockFilter = value);
        },
        selectedColor: AdminColors.peach,
        backgroundColor: AdminColors.cardSurface,
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? chipColor : AdminColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected ? chipColor : AdminColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProductTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AdminColors.peachLight),
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: Text(
                    'MỸ PHẨM / DÒNG ĐẶC TRỊ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MÃ SKU',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PHÂN LOẠI',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'GIÁ NIÊM YẾT',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TỒN KHO KHẢ DỤNG',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'TRẠNG THÁI VẬN HÀNH',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              rows: items.map((product) {
                final id = product['id']?.toString() ?? '—';
                final name = product['name']?.toString() ?? product['title']?.toString() ?? 'Sản phẩm';
                final category = product['category']?.toString() ?? 'Mỹ phẩm';
                final price = _getPrice(product);
                final stock = _getStock(product);
                final imageUrl = product['imageUrl']?.toString();

                Widget statusBadge;
                if (stock == 0) {
                  statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.statusCancelled.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.statusCancelled.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Hết hàng',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.statusCancelled,
                      ),
                    ),
                  );
                } else if (stock < 10) {
                  statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.statusLowStock.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.statusLowStock.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 13, color: AdminColors.statusLowStock),
                        const SizedBox(width: 4),
                        Text(
                          'Cảnh báo sắp hết hàng',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.statusLowStock,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  statusBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Sẵn sàng phục vụ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.emerald,
                      ),
                    ),
                  );
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 38,
                                      height: 38,
                                      color: AdminColors.elevatedSurface,
                                      child: const Icon(Icons.spa_rounded, size: 18, color: AdminColors.primary),
                                    ),
                                  )
                                : Container(
                                    width: 38,
                                    height: 38,
                                    color: AdminColors.elevatedSurface,
                                    child: const Icon(Icons.spa_rounded, size: 18, color: AdminColors.primary),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              name,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        id.toUpperCase(),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AdminColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        AdminFormatters.formatCurrency(price),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$stock hộp/chai',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: stock < 10 ? AdminColors.statusLowStock : AdminColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(statusBadge),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
