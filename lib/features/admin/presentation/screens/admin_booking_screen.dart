import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';
import '../../data/admin_booking_repository.dart';
import '../widgets/admin_booking_card.dart';
import '../widgets/admin_booking_detail_dialog.dart';
import '../widgets/admin_booking_table.dart';
import '../widgets/admin_reject_reason_dialog.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Chờ duyệt (Pending), 1: Tất cả, 2: Đã duyệt, 3: Đã từ chối
  bool? _forceTableView; // null: auto-detect by screen width

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(BookingItem booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiStyle.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Duyệt lịch hẹn?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LumiStyle.plum,
          ),
        ),
        content: Text(
          'Xác nhận duyệt lịch hẹn "${booking.serviceName}" của khách ${booking.contactName} vào ${booking.formattedDateTime}?',
          style: GoogleFonts.dmSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'HỦY',
              style: GoogleFonts.dmSans(color: LumiStyle.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: LumiStyle.rose),
            child: Text(
              'DUYỆT NGAY',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AdminBookingRepository.instance.approveBooking(booking);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã duyệt đơn #${booking.id.substring(0, 8).toUpperCase()} thành công!'),
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

  Future<void> _handleReject(BookingItem booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AdminRejectReasonDialog(booking: booking),
    );

    if (reason == null || !mounted) return;

    try {
      await AdminBookingRepository.instance.rejectBooking(booking, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối đơn #${booking.id.substring(0, 8).toUpperCase()}'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi từ chối đơn: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDetail(BookingItem booking) {
    showDialog<void>(
      context: context,
      builder: (_) => AdminBookingDetailDialog(
        booking: booking,
        onApprove: () => _handleApprove(booking),
        onReject: () => _handleReject(booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = screenWidth >= 800;
    final useTableView = _forceTableView ?? isLargeScreen;

    return Scaffold(
      backgroundColor: LumiStyle.ivory,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: LumiStyle.blushSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: LumiStyle.rose,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'LUMI SPA — Portal Quản Trị',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: LumiStyle.plum,
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuyển đổi View: Table <-> Cards
          IconButton(
            tooltip: useTableView ? 'Xem dạng Thẻ (Cards)' : 'Xem dạng Bảng (Table)',
            onPressed: () {
              setState(() {
                _forceTableView = !useTableView;
              });
            },
            icon: Icon(
              useTableView ? Icons.grid_view_rounded : Icons.table_chart_rounded,
              color: LumiStyle.plum,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ) : null,
      body: StreamBuilder<List<BookingItem>>(
        // Lắng nghe real-time từ Cloud Firestore
        stream: AdminBookingRepository.instance.streamAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: LumiStyle.rose),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối Firestore',
                      style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 12, color: LumiStyle.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          final allBookings = snapshot.data ?? [];

          // Thống kê nhanh
          final pendingCount = allBookings.where((b) => b.status == 'pending').length;
          final approvedCount = allBookings.where((b) => b.status == 'approved' || b.status == 'confirmed').length;
          final rejectedCount = allBookings.where((b) => b.status == 'rejected' || b.status == 'cancelled').length;

          // Lọc danh sách theo Tab
          List<BookingItem> filtered = allBookings;
          if (_selectedFilter == 0) {
            filtered = allBookings.where((b) => b.status == 'pending').toList();
          } else if (_selectedFilter == 2) {
            filtered = allBookings.where((b) => b.status == 'approved' || b.status == 'confirmed').toList();
          } else if (_selectedFilter == 3) {
            filtered = allBookings.where((b) => b.status == 'rejected' || b.status == 'cancelled').toList();
          }

          // Tìm kiếm theo từ khóa
          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            filtered = filtered.where((b) {
              final idMatch = b.id.toLowerCase().contains(query);
              final nameMatch = b.contactName.toLowerCase().contains(query);
              final phoneMatch = b.contactPhone.toLowerCase().contains(query);
              final serviceMatch = b.serviceName.toLowerCase().contains(query);
              return idMatch || nameMatch || phoneMatch || serviceMatch;
            }).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Thẻ KPI Thống kê nhanh
              _buildKpiSection(
                pendingCount: pendingCount,
                approvedCount: approvedCount,
                rejectedCount: rejectedCount,
                totalCount: allBookings.length,
              ),
              const SizedBox(height: 20),

              // 2. Toolbar: Search bar & Tab lọc trạng thái
              _buildToolbar(pendingCount, allBookings.length, approvedCount, rejectedCount),
              const SizedBox(height: 16),

              // 3. Hiển thị danh sách: Dạng Bảng (DataTable) hoặc Dạng Thẻ (Card/ListView)
              if (useTableView)
                AdminBookingTable(
                  bookings: filtered,
                  onApprove: _handleApprove,
                  onReject: _handleReject,
                  onTapDetail: _showDetail,
                )
              else
                ...filtered.map((booking) {
                  return AdminBookingCard(
                    booking: booking,
                    onApprove: () => _handleApprove(booking),
                    onReject: () => _handleReject(booking),
                    onTapDetail: () => _showDetail(booking),
                  );
                }),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 54, color: LumiStyle.muted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilter == 0
                            ? 'Hiện không có lịch hẹn nào đang chờ duyệt!'
                            : 'Không tìm thấy lịch hẹn phù hợp.',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: LumiStyle.plum,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSection({
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required int totalCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = [
          _kpiCard(
            title: 'Chờ duyệt',
            count: pendingCount,
            icon: Icons.hourglass_top_rounded,
            color: Colors.amber.shade800,
            bgColor: Colors.amber.shade50,
          ),
          _kpiCard(
            title: 'Đã duyệt',
            count: approvedCount,
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade800,
            bgColor: Colors.green.shade50,
          ),
          _kpiCard(
            title: 'Đã từ chối',
            count: rejectedCount,
            icon: Icons.cancel_outlined,
            color: Colors.red.shade800,
            bgColor: Colors.red.shade50,
          ),
          _kpiCard(
            title: 'Tổng đơn',
            count: totalCount,
            icon: Icons.receipt_long_outlined,
            color: LumiStyle.plum,
            bgColor: LumiStyle.blushSurface,
          ),
        ];

        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: cards,
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumiStyle.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LumiStyle.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int pendingCount, int totalCount, int approvedCount, int rejectedCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LumiStyle.line),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo Mã đơn, Tên khách hàng, Số điện thoại, Dịch vụ...',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
              prefixIcon: const Icon(Icons.search_rounded, color: LumiStyle.rose, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterTab(0, 'Chờ duyệt ($pendingCount)', Icons.hourglass_empty_rounded),
              const SizedBox(width: 8),
              _filterTab(1, 'Tất cả ($totalCount)', Icons.list_alt_rounded),
              const SizedBox(width: 8),
              _filterTab(2, 'Đã duyệt ($approvedCount)', Icons.check_circle_outline_rounded),
              const SizedBox(width: 8),
              _filterTab(3, 'Đã từ chối ($rejectedCount)', Icons.cancel_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterTab(int index, String label, IconData icon) {
    final selected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LumiStyle.rose : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? LumiStyle.rose : LumiStyle.line,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: LumiStyle.rose.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : LumiStyle.plum,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : LumiStyle.plum,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

