import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminOrderItem>>(
      stream: AdminOrderRepository.instance.streamAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: LumiStyle.rose),
          );
        }

        final allOrders = snapshot.data ?? [];
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
                              title: 'Đang giao hàng',
                              count: shippingCount,
                              color: const Color(0xFF7C3AED),
                              icon: Icons.local_shipping_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Search & View Toggle Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Tìm theo mã đơn, khách hàng, số điện thoại...',
                                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
                                  prefixIcon: const Icon(Icons.search, color: LumiStyle.rose, size: 20),
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: LumiStyle.line),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: LumiStyle.line),
                                  ),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Xem dạng Thẻ',
                                    icon: Icon(
                                      Icons.grid_view_rounded,
                                      color: !showTableView ? LumiStyle.rose : LumiStyle.muted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _forceTableView = false),
                                  ),
                                  IconButton(
                                    tooltip: 'Xem dạng Bảng',
                                    icon: Icon(
                                      Icons.table_chart_outlined,
                                      color: showTableView ? LumiStyle.rose : LumiStyle.muted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _forceTableView = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(0, 'Chờ duyệt ($pendingCount)'),
                              const SizedBox(width: 8),
                              _filterChip(1, 'Tất cả (${allOrders.length})'),
                              const SizedBox(width: 8),
                              _filterChip(2, 'Đã duyệt ($confirmedCount)'),
                              const SizedBox(width: 8),
                              _filterChip(3, 'Đang giao ($shippingCount)'),
                              const SizedBox(width: 8),
                              _filterChip(4, 'Đã giao'),
                              const SizedBox(width: 8),
                              _filterChip(5, 'Đã hủy'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                // Data Display Body
                if (filteredOrders.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 54, color: LumiStyle.muted),
                            const SizedBox(height: 14),
                            Text(
                              'Không tìm thấy đơn hàng nào',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: LumiStyle.plum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thử đổi bộ lọc hoặc từ khóa tìm kiếm',
                              style: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (showTableView)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: AdminOrderTable(
                        orders: filteredOrders,
                        onApprove: _handleApprove,
                        onCancel: _handleCancel,
                        onViewDetail: _handleViewDetail,
                        onUpdateStatus: _handleUpdateStatus,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = filteredOrders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AdminOrderCard(
                              order: order,
                              onApprove: () => _handleApprove(order),
                              onCancel: () => _handleCancel(order),
                              onViewDetail: () => _handleViewDetail(order),
                              onUpdateStatus: (newStatus) => _handleUpdateStatus(order, newStatus),
                            ),
                          );
                        },
                        childCount: filteredOrders.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LumiStyle.line),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.dmSans(fontSize: 11.5, color: LumiStyle.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = index),
      selectedColor: LumiStyle.rose,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? LumiStyle.rose : LumiStyle.line),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : LumiStyle.plum,
      ),
    );
  }
}
