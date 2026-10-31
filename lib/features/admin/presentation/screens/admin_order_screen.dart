import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../data/admin_order_repository.dart';
import '../../data/models/admin_order_item.dart';
import '../widgets/admin_order_cancel_dialog.dart';
import '../widgets/admin_order_card.dart';
import '../widgets/admin_order_detail_dialog.dart';
import '../widgets/admin_order_table.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Chờ duyệt, 1: Tất cả, 2: Đã duyệt, 3: Đang giao, 4: Đã giao, 5: Đã hủy
  bool? _forceTableView;

  List<AdminOrderItem>? _fallbackApiOrders;
  bool _isFetchingFallback = false;
  bool _fallbackFailed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFallbackApi() async {
    if (_isFetchingFallback) return;
    setState(() {
      _isFetchingFallback = true;
      _fallbackFailed = false;
    });

    try {
      final list = await AdminOrderRepository.instance.fetchOrdersFromApi();
      if (!mounted) return;
      setState(() {
        _fallbackApiOrders = list;
        _isFetchingFallback = false;
        _fallbackFailed = list.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFetchingFallback = false;
        _fallbackFailed = true;
      });
    }
  }

  void _showRulesGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiStyle.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cấu hình Firestore Security Rules',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LumiStyle.plum,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khi chưa đăng nhập tài khoản Firebase hoặc Security Rules bị khóa, Firestore sẽ báo lỗi [permission-denied].',
                  style: GoogleFonts.dmSans(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  '👉 Các bước khắc phục:',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: LumiStyle.plum),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Truy cập Firebase Console -> Firestore Database -> Thẻ Rules.\n'
                  '2. Dán nội dung quy tắc bên dưới và nhấn "Publish" (Xuất bản).\n'
                  '3. Hệ thống sẽ ngay lập tức cho phép đọc/ghi real-time!',
                  style: GoogleFonts.dmSans(fontSize: 12, height: 1.5, color: LumiStyle.muted),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SelectableText(
                    '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{id} { allow read, write: if true; }
    match /orders/{id} { allow read, write: if true; }
    match /notifications/{id} { allow read, write: if true; }
    match /{document=**} { allow read, write: if true; }
  }
}''',
                    style: GoogleFonts.spaceMono(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text: '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{id} { allow read, write: if true; }
    match /orders/{id} { allow read, write: if true; }
    match /notifications/{id} { allow read, write: if true; }
    match /{document=**} { allow read, write: if true; }
  }
}''',
              ));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép nội dung Rules vào bộ nhớ tạm!')),
              );
            },
            child: Text(
              'Sao chép Rules',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: LumiStyle.rose),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: LumiStyle.plum),
            child: Text('Đóng', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(AdminOrderItem order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiStyle.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Duyệt đơn hàng?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LumiStyle.plum,
          ),
        ),
        content: Text(
          'Xác nhận duyệt đơn hàng #${order.id} của khách ${order.customerName} (${order.displayTotal})?\nHệ thống sẽ tự động gửi email xác nhận và thông báo cho khách hàng.',
          style: GoogleFonts.dmSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('HỦY', style: GoogleFonts.dmSans(color: LumiStyle.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LumiStyle.rose),
            child: Text('DUYỆT & GỬI EMAIL', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminOrderRepository.instance.updateOrderStatus(
        order: order,
        newStatus: 'confirmed',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã duyệt đơn hàng #${order.id} và gửi Gmail thành công!'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_fallbackApiOrders != null) {
        _fetchFallbackApi();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi duyệt đơn: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancel(AdminOrderItem order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AdminOrderCancelDialog(order: order),
    );

    if (reason == null || !mounted) return;

    try {
      await AdminOrderRepository.instance.updateOrderStatus(
        order: order,
        newStatus: 'cancelled',
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy đơn hàng #${order.id} và thông báo cho khách hàng.'),
          backgroundColor: Colors.orange.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_fallbackApiOrders != null) {
        _fetchFallbackApi();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hủy đơn: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleUpdateStatus(AdminOrderItem order, String newStatus, {String? reason}) async {
    try {
      await AdminOrderRepository.instance.updateOrderStatus(
        order: order,
        newStatus: newStatus,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã chuyển trạng thái đơn #${order.id} sang "$newStatus"'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_fallbackApiOrders != null) {
        _fetchFallbackApi();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleViewDetail(AdminOrderItem order) {
    showDialog<void>(
      context: context,
      builder: (_) => AdminOrderDetailDialog(
        order: order,
        onUpdateStatus: (newStatus, {reason}) {
          Navigator.of(context).pop();
          if (newStatus == 'cancelled') {
            _handleCancel(order);
          } else {
            _handleUpdateStatus(order, newStatus, reason: reason);
          }
        },
      ),
    );
  }

  List<AdminOrderItem> _filterOrders(List<AdminOrderItem> allOrders) {
    var result = allOrders;

    switch (_selectedFilter) {
      case 0: // Chờ duyệt
        result = result.where((o) => o.status.toLowerCase() == 'pending').toList();
        break;
      case 1: // Tất cả
        break;
      case 2: // Đã duyệt
        result = result.where((o) => o.status.toLowerCase() == 'confirmed' || o.status.toLowerCase() == 'processing').toList();
        break;
      case 3: // Đang giao
        result = result.where((o) => o.status.toLowerCase() == 'shipping' || o.status.toLowerCase() == 'delivering').toList();
        break;
      case 4: // Đã giao
        result = result.where((o) => o.status.toLowerCase() == 'completed').toList();
        break;
      case 5: // Đã hủy
        result = result.where((o) => o.status.toLowerCase() == 'cancelled' || o.status.toLowerCase() == 'rejected').toList();
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((o) {
        return o.id.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query) ||
            o.phone.toLowerCase().contains(query) ||
            o.customerEmail.toLowerCase().contains(query) ||
            o.itemsSummary.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  Widget _buildFallbackNoticeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang đồng bộ đơn hàng qua Backend API (Port 3000)',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Firestore Security Rules hiện chặn quyền đọc trực tiếp từ máy khách.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _showRulesGuideDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB45309)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Cách sửa Rules',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminOrderItem>>(
      stream: AdminOrderRepository.instance.streamAllOrders(),
      builder: (context, snapshot) {
        List<AdminOrderItem> allOrders = [];
        bool isUsingFallback = false;

        if (snapshot.connectionState == ConnectionState.waiting && _fallbackApiOrders == null) {
          return const Center(
            child: CircularProgressIndicator(color: LumiStyle.rose),
          );
        }

        if (snapshot.hasError) {
          if (_fallbackApiOrders != null) {
            allOrders = _fallbackApiOrders!;
            isUsingFallback = true;
          } else {
            if (!_isFetchingFallback && !_fallbackFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchFallbackApi();
              });
            }

            if (_isFetchingFallback) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: LumiStyle.rose),
                    const SizedBox(height: 16),
                    Text(
                      'Phát hiện lỗi Firestore Rules. Đang chuyển sang nạp qua Backend API...',
                      style: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối đơn hàng Firestore',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: _fetchFallbackApi,
                          style: FilledButton.styleFrom(backgroundColor: LumiStyle.rose),
                          icon: const Icon(Icons.cloud_download_rounded, size: 16),
                          label: Text('Tải qua Backend API', style: GoogleFonts.dmSans()),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showRulesGuideDialog,
                          icon: const Icon(Icons.security_rounded, size: 16),
                          label: Text('Cách sửa Rules', style: GoogleFonts.dmSans()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          allOrders = snapshot.data ?? [];
        }

        final filteredOrders = _filterOrders(allOrders);

        final pendingCount = allOrders
            .where((o) => o.status.toLowerCase() == 'pending')
            .length;
        final confirmedCount = allOrders
            .where((o) => o.status.toLowerCase() == 'confirmed' || o.status.toLowerCase() == 'processing')
            .length;
        final shippingCount = allOrders
            .where((o) => o.status.toLowerCase() == 'shipping' || o.status.toLowerCase() == 'delivering')
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final showTableView = _forceTableView ?? isDesktop;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUsingFallback) _buildFallbackNoticeBanner(),

                        // KPI Quick Stats Row
                        Row(
                          children: [
                            _buildStatCard(
                              title: 'Chờ duyệt',
                              count: pendingCount,
                              color: const Color(0xFFD97706),
                              icon: Icons.hourglass_top_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Đang chuẩn bị',
                              count: confirmedCount,
                              color: const Color(0xFF2563EB),
                              icon: Icons.inventory_2_outlined,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Đang giao',
                              count: shippingCount,
                              color: const Color(0xFF7C3AED),
                              icon: Icons.local_shipping_outlined,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Tổng đơn hàng',
                              count: allOrders.length,
                              color: LumiStyle.plum,
                              icon: Icons.receipt_long_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search & View Mode Switcher
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm mã đơn, khách hàng, số điện thoại hoặc sản phẩm...',
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: LumiStyle.muted,
                                  ),
                                  prefixIcon: const Icon(Icons.search, color: LumiStyle.rose),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: LumiStyle.line),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: LumiStyle.line),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: LumiStyle.rose, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: LumiStyle.line),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Hiển thị dạng Bảng',
                                    icon: Icon(
                                      Icons.table_chart_rounded,
                                      color: showTableView ? LumiStyle.rose : LumiStyle.muted,
                                    ),
                                    onPressed: () => setState(() => _forceTableView = true),
                                  ),
                                  IconButton(
                                    tooltip: 'Hiển thị dạng Thẻ',
                                    icon: Icon(
                                      Icons.grid_view_rounded,
                                      color: !showTableView ? LumiStyle.rose : LumiStyle.muted,
                                    ),
                                    onPressed: () => setState(() => _forceTableView = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status Filter Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(0, 'Chờ duyệt', pendingCount),
                              _buildFilterChip(1, 'Tất cả', allOrders.length),
                              _buildFilterChip(2, 'Đã duyệt', confirmedCount),
                              _buildFilterChip(3, 'Đang giao', shippingCount),
                              _buildFilterChip(
                                4,
                                'Hoàn thành',
                                allOrders.where((o) => o.status.toLowerCase() == 'completed').length,
                              ),
                              _buildFilterChip(
                                5,
                                'Đã hủy',
                                allOrders.where((o) => o.status.toLowerCase() == 'cancelled' || o.status.toLowerCase() == 'rejected').length,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Orders List / Table
                if (filteredOrders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: LumiStyle.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Không có đơn hàng nào phù hợp',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: LumiStyle.plum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thử thay đổi bộ lọc trạng thái hoặc từ khóa tìm kiếm.',
                              style: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (showTableView)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: AdminOrderTable(
                        orders: filteredOrders,
                        onApprove: _handleApprove,
                        onCancel: _handleCancel,
                        onViewDetail: _handleViewDetail,
                        onUpdateStatus: (order, status) => _handleUpdateStatus(order, status),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = filteredOrders[index];
                          return AdminOrderCard(
                            order: order,
                            onApprove: () => _handleApprove(order),
                            onCancel: () => _handleCancel(order),
                            onViewDetail: () => _handleViewDetail(order),
                            onUpdateStatus: (newStatus) => _handleUpdateStatus(order, newStatus),
                          );
                        },
                        childCount: filteredOrders.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LumiStyle.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LumiStyle.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: LumiStyle.plum,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = index);
          }
        },
        selectedColor: LumiStyle.plum,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? LumiStyle.plum : LumiStyle.line,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : LumiStyle.plum,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
