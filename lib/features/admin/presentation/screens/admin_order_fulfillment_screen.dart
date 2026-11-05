import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_order_repository.dart';
import '../../data/models/admin_order_item.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_order_cancel_dialog.dart';
import '../widgets/admin_order_detail_dialog.dart';
import '../widgets/admin_shipping_dialog.dart';

class AdminOrderFulfillmentScreen extends StatefulWidget {
  const AdminOrderFulfillmentScreen({super.key});

  @override
  State<AdminOrderFulfillmentScreen> createState() =>
      _AdminOrderFulfillmentScreenState();
}

class _AdminOrderFulfillmentScreenState
    extends State<AdminOrderFulfillmentScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Chờ duyệt, 1: Đã xác nhận, 2: Đóng gói, 3: Đang giao, 4: Hoàn thành, 5: Đã hủy, 6: Tất cả
  bool _isLoadingAction = false;

  final List<String> _filterLabels = [
    'Chờ duyệt',
    'Đã xác nhận',
    'Đang đóng gói',
    'Đang giao',
    'Hoàn tất',
    'Đã hủy',
    'Tất cả',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm(AdminOrderItem order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AdminColors.border),
        ),
        title: Text(
          'Duyệt Đơn & Trừ Tồn Kho?',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
          ),
        ),
        content: Text(
          'Xác nhận duyệt đơn hàng #${order.displayId} (${order.displayTotal})?\n\nHệ thống sẽ kiểm tra số lượng và trừ tồn kho chi nhánh nguyên tử qua ACID Transaction.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            height: 1.5,
            color: AdminColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'HỦY',
              style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.emerald),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: Text(
              'DUYỆT & TRỪ KHO',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminOrderRepository.instance.confirmOrderV2(
        orderId: order.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Duyệt đơn và trừ kho thành công!',
          ),
          backgroundColor: AdminColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi duyệt đơn: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleTransition(AdminOrderItem order, String toStatus) async {
    if (toStatus == 'shipping') {
      final shippingData = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => AdminShippingDialog(orderId: order.displayId),
      );
      if (shippingData == null || !mounted) return;

      setState(() => _isLoadingAction = true);
      try {
        final res = await AdminOrderRepository.instance.transitionOrderV2(
          orderId: order.id,
          toStatus: 'shipping',
          note: shippingData['note'],
          trackingNumber: shippingData['trackingNumber'],
          shippingCarrier: shippingData['carrier'],
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Đã bàn giao đơn vị vận chuyển!',
            ),
            backgroundColor: AdminColors.statusShipping,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chuyển trạng thái: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoadingAction = false);
      }
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminOrderRepository.instance.transitionOrderV2(
        orderId: order.id,
        toStatus: toStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Cập nhật trạng thái thành công!',
          ),
          backgroundColor: AdminColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCancel(AdminOrderItem order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AdminOrderCancelDialog(order: order),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminOrderRepository.instance.cancelOrderV2(
        orderId: order.id,
        reason: reason.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Đã hủy đơn và hoàn trả tồn kho!',
          ),
          backgroundColor: AdminColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hủy đơn: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  List<AdminOrderItem> _filterList(List<AdminOrderItem> list) {
    var result = list;
    final term = _searchController.text.trim().toLowerCase();

    if (term.isNotEmpty) {
      result = result.where((o) {
        final idMatch = o.id.toLowerCase().contains(term) ||
            o.displayId.toLowerCase().contains(term);
        final nameMatch = o.customerName.toLowerCase().contains(term);
        final phoneMatch = o.phone.toLowerCase().contains(term);
        return idMatch || nameMatch || phoneMatch;
      }).toList();
    }

    switch (_selectedFilter) {
      case 0: // Chờ duyệt
        return result.where((o) => o.status.toLowerCase() == 'pending').toList();
      case 1: // Đã xác nhận
        return result
            .where((o) => ['confirmed', 'approved'].contains(o.status.toLowerCase()))
            .toList();
      case 2: // Đóng gói
        return result
            .where((o) => ['packaging', 'processing'].contains(o.status.toLowerCase()))
            .toList();
      case 3: // Đang giao
        return result
            .where((o) => ['shipping', 'delivering'].contains(o.status.toLowerCase()))
            .toList();
      case 4: // Hoàn tất
        return result
            .where((o) => o.status.toLowerCase() == 'completed')
            .toList();
      case 5: // Đã hủy
        return result
            .where((o) => ['cancelled', 'rejected'].contains(o.status.toLowerCase()))
            .toList();
      case 6: // Tất cả
      default:
        return result;
    }
  }

  Widget _buildStatPill(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.deepTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: AdminColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AdminColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = AdminColors.statusPending.withValues(alpha: 0.15);
        fg = AdminColors.statusPending;
        label = 'Chờ duyệt';
        break;
      case 'confirmed':
      case 'approved':
        bg = AdminColors.statusConfirmed.withValues(alpha: 0.15);
        fg = AdminColors.statusConfirmed;
        label = 'Đã xác nhận';
        break;
      case 'packaging':
      case 'processing':
        bg = AdminColors.statusPackaging.withValues(alpha: 0.15);
        fg = AdminColors.statusPackaging;
        label = 'Đóng gói';
        break;
      case 'shipping':
      case 'delivering':
        bg = AdminColors.statusShipping.withValues(alpha: 0.15);
        fg = AdminColors.statusShipping;
        label = 'Đang giao';
        break;
      case 'completed':
        bg = AdminColors.statusCompleted.withValues(alpha: 0.15);
        fg = AdminColors.statusCompleted;
        label = 'Hoàn tất';
        break;
      case 'cancelled':
      case 'rejected':
      default:
        bg = AdminColors.statusCancelled.withValues(alpha: 0.15);
        fg = AdminColors.statusCancelled;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: StreamBuilder<List<AdminOrderItem>>(
        stream: AdminOrderRepository.instance.streamAllOrders(),
        builder: (context, snapshot) {
          final allOrders = snapshot.data ?? [];
          final filtered = _filterList(allOrders);

          final pendingCount =
              allOrders.where((o) => o.status.toLowerCase() == 'pending').length;
          final shippingCount = allOrders
              .where((o) => ['shipping', 'delivering'].contains(o.status.toLowerCase()))
              .length;
          final completedRevenue = allOrders
              .where((o) => o.status.toLowerCase() == 'completed')
              .fold<num>(0, (sum, o) => sum + o.total);

          return Column(
            children: [
              // 1. Header KPIs Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AdminColors.slateTeal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatPill('Chờ duyệt trừ kho', '$pendingCount đơn',
                          AdminColors.statusPending, Icons.inventory_2_outlined),
                      const SizedBox(width: 10),
                      _buildStatPill('Đang vận chuyển', '$shippingCount đơn',
                          AdminColors.statusShipping, Icons.local_shipping_outlined),
                      const SizedBox(width: 10),
                      _buildStatPill(
                        'Doanh thu hoàn tất',
                        '${(completedRevenue / 1000).toInt()}k đ',
                        AdminColors.emerald,
                        Icons.attach_money_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(14),
                color: AdminColors.deepTeal,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.beVietnamPro(
                          color: AdminColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm mã đơn, tên khách, số điện thoại...',
                        hintStyle: GoogleFonts.beVietnamPro(
                            color: AdminColors.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            color: AdminColors.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AdminColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AdminColors.cardSurface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_filterLabels.length, (idx) {
                          final isSelected = _selectedFilter == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_filterLabels[idx]),
                              labelStyle: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AdminColors.textSecondary,
                              ),
                              selected: isSelected,
                              selectedColor: AdminColors.emerald,
                              backgroundColor: AdminColors.cardSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected
                                      ? AdminColors.emerald
                                      : AdminColors.border,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedFilter = idx),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Orders List
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting &&
                        allOrders.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AdminColors.emerald,
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inbox_outlined,
                                    size: 48, color: AdminColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy đơn hàng nào.',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AdminColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final order = filtered[index];
                              final status = order.status.toLowerCase();

                              return Card(
                                color: AdminColors.cardSurface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                      color: AdminColors.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top row: ID + Status + Total
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '#${order.displayId}',
                                                style:
                                                    GoogleFonts.beVietnamPro(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AdminColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatusChip(order.status),
                                            ],
                                          ),
                                          Text(
                                            order.displayTotal,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AdminColors.softGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Customer Info
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 16,
                                              color: AdminColors.textMuted),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.customerName,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AdminColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.phone_outlined,
                                              size: 15,
                                              color: AdminColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.phone,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              color:
                                                  AdminColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Address
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: AdminColors.textMuted),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.shippingAddress,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  GoogleFonts.beVietnamPro(
                                                fontSize: 12,
                                                color: AdminColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Item Count
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AdminColors.deepTeal,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Giỏ hàng (${order.items.length} mặt hàng)',
                                              style:
                                                  GoogleFonts.beVietnamPro(
                                                fontSize: 11,
                                                color:
                                                    AdminColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'PTTT: ${order.paymentMethod}',
                                              style:
                                                  GoogleFonts.beVietnamPro(
                                                fontSize: 11,
                                                color: AdminColors.softGold,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),
                                      const Divider(
                                          color: AdminColors.border,
                                          height: 1),
                                      const SizedBox(height: 12),

                                      // Fulfillment Actions
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) =>
                                                    AdminOrderDetailDialog(
                                                  order: order,
                                                  onUpdateStatus: (newStatus, {reason}) =>
                                                      (newStatus == 'cancelled' ? _handleCancel(order) : _handleTransition(order, newStatus)),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                                Icons.visibility_outlined,
                                                size: 15,
                                                color: AdminColors.cyan),
                                            label: Text(
                                              'Chi tiết',
                                              style:
                                                  GoogleFonts.beVietnamPro(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AdminColors.cyan,
                                              ),
                                            ),
                                          ),

                                          // Dynamic Action Button based on status
                                          Row(
                                            children: [
                                              if (['pending', 'confirmed', 'packaging', 'shipping'].contains(status))
                                                TextButton(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleCancel(order),
                                                  child: Text(
                                                    'Hủy đơn',
                                                    style:
                                                        GoogleFonts.beVietnamPro(
                                                      fontSize: 12,
                                                      color: Colors.red.shade400,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 6),

                                              if (status == 'pending')
                                                FilledButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleConfirm(order),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AdminColors.emerald,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                      Icons.check_rounded,
                                                      size: 16),
                                                  label: Text(
                                                    'DUYỆT & TRỪ KHO',
                                                    style: GoogleFonts
                                                        .beVietnamPro(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                )
                                              else if (status == 'confirmed')
                                                FilledButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleTransition(
                                                          order, 'packaging'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AdminColors.statusPackaging,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                      Icons.inventory_2_outlined,
                                                      size: 16),
                                                  label: Text(
                                                    'ĐÓNG GÓI',
                                                    style: GoogleFonts
                                                        .beVietnamPro(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                )
                                              else if (status == 'packaging')
                                                FilledButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleTransition(
                                                          order, 'shipping'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AdminColors.statusShipping,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                      Icons.local_shipping_outlined,
                                                      size: 16),
                                                  label: Text(
                                                    'GIAO BƯU CỤC',
                                                    style: GoogleFonts
                                                        .beVietnamPro(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                )
                                              else if (status == 'shipping')
                                                FilledButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleTransition(
                                                          order, 'completed'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AdminColors.statusCompleted,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                      Icons.done_all_rounded,
                                                      size: 16),
                                                  label: Text(
                                                    'ĐÃ GIAO HÀNG',
                                                    style: GoogleFonts
                                                        .beVietnamPro(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
