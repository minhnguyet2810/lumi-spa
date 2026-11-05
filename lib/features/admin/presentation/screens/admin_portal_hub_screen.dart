import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/lumi_api_client.dart';
import '../../../../core/data/lumi_order_store.dart';
import '../../../booking/data/models/booking_item.dart';
import '../../data/admin_booking_repository.dart';
import '../../data/admin_order_repository.dart';
import '../../data/admin_user_repository.dart';
import '../../data/models/admin_order_item.dart';
import '../theme/admin_colors.dart';
import 'admin_booking_timeline_screen.dart';
import 'admin_order_fulfillment_screen.dart';
import 'admin_product_inventory_screen.dart';
import 'admin_customer_360_screen.dart';
import 'admin_staff_roster_screen.dart';
import 'admin_marketing_center_screen.dart';
import 'admin_financial_analytics_screen.dart';

class AdminPortalHubScreen extends StatefulWidget {
  const AdminPortalHubScreen({super.key});

  @override
  State<AdminPortalHubScreen> createState() => _AdminPortalHubScreenState();
}

class _AdminPortalHubScreenState extends State<AdminPortalHubScreen> {
  int _currentMenuIndex = 0;
  bool _checkingApi = false;

  final List<_AdminMenuItem> _menuItems = const [
    _AdminMenuItem(
      title: 'Tổng quan hoạt động',
      subtitle: 'Bảng điều khiển chỉ số & giám sát vận hành',
      icon: Icons.space_dashboard_rounded,
    ),
    _AdminMenuItem(
      title: 'Lịch hẹn dịch vụ',
      subtitle: 'Ma trận khung giờ x Chuyên viên x Phòng spa',
      icon: Icons.calendar_month_rounded,
    ),
    _AdminMenuItem(
      title: 'Đơn hàng mỹ phẩm',
      subtitle: 'Quy trình trừ kho ACID & đóng gói giao hàng',
      icon: Icons.local_shipping_rounded,
    ),
    _AdminMenuItem(
      title: 'Sản phẩm & Kho hàng',
      subtitle: 'Định mức tồn kho & cảnh báo sắp hết hàng',
      icon: Icons.inventory_2_rounded,
    ),
    _AdminMenuItem(
      title: 'Hồ sơ khách hàng',
      subtitle: 'CRM 360°, da liễu & thăng hạng hội viên',
      icon: Icons.people_alt_rounded,
    ),
    _AdminMenuItem(
      title: 'Đội ngũ nhân sự & Ca trực',
      subtitle: 'Ma trận xếp ca tuần, chấm công & nghỉ phép',
      icon: Icons.badge_rounded,
    ),
    _AdminMenuItem(
      title: 'Chương trình ưu đãi',
      subtitle: 'Voucher khuyến mãi & chiến dịch tiếp thị',
      icon: Icons.loyalty_rounded,
    ),
    _AdminMenuItem(
      title: 'Báo cáo doanh thu',
      subtitle: 'Doanh thu thuần, giá vốn COGS & lợi nhuận gộp',
      icon: Icons.insights_rounded,
    ),
  ];

  Future<void> _handleClearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border),
        ),
        title: Text(
          'Dọn dẹp dữ liệu test?',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
          ),
        ),
        content: Text(
          'Hệ thống sẽ dọn dẹp các đơn hàng và lịch hẹn thử nghiệm cũ trong Firestore để bạn bắt đầu kiểm thử từ trạng thái sạch hoàn toàn.\n\n(Dữ liệu người dùng sẽ được giữ nguyên an toàn).',
          style: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.5, color: AdminColors.textSecondary),
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
            style: FilledButton.styleFrom(backgroundColor: AdminColors.statusCancelled),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text(
              'DỌN DẸP NGAY',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await AdminUserRepository.instance.clearTestData(
        target: 'all',
      );
      LumiOrderStore.orders.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Đã dọn dẹp dữ liệu test thành công!',
          ),
          backgroundColor: AdminColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi dọn dẹp: $e'),
          backgroundColor: AdminColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkApi() async {
    if (_checkingApi) return;
    setState(() => _checkingApi = true);
    try {
      await LumiApiClient.instance.get('/api/admin/health');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API quản trị đã phản hồi. Xác thực admin hợp lệ.'),
          backgroundColor: AdminColors.emerald,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa kết nối được API quản trị: $error'),
          backgroundColor: AdminColors.statusCancelled,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingApi = false);
    }
  }

  Future<void> _refreshAccess() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã làm mới quyền quản trị thành công.'),
          backgroundColor: AdminColors.emerald,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa làm mới được quyền. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          // 1. THANH ĐIỀU HƯỚNG BÊN TRÁI (LEFT SIDEBAR - 240px)
          _buildLeftSidebar(),

          // 2. KHU VỰC NỘI DUNG CHÍNH (MAIN CONTENT - EXPANDED)
          Expanded(
            child: Column(
              children: [
                // Thanh tiêu đề phía trên (Top Header Bar)
                _buildTopHeaderBar(),

                // Thân nội dung phân hệ tương ứng
                Expanded(
                  child: _buildMainContentView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AdminColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AdminColors.peach,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: AdminColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LUMI SPA',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textPrimary,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'CỔNG QUẢN TRỊ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AdminColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items List (8 Phân hệ)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _currentMenuIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => setState(() => _currentMenuIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected ? AdminColors.peach : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AdminColors.border, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? AdminColors.primary : AdminColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badges for pending items
                          if (index == 1) // Lịch hẹn
                            StreamBuilder<List<BookingItem>>(
                              stream: AdminBookingRepository.instance.streamPendingBookings(),
                              builder: (context, snap) {
                                final count = snap.data?.length ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return _menuBadge('$count', AdminColors.primary);
                              },
                            )
                          else if (index == 2) // Đơn hàng
                            StreamBuilder<List<AdminOrderItem>>(
                              stream: AdminOrderRepository.instance.streamPendingOrders(),
                              builder: (context, snap) {
                                final count = snap.data?.length ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return _menuBadge('$count', const Color(0xFF2563EB));
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Footer & Quick Action Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AdminColors.cardSurface,
              border: Border(top: BorderSide(color: AdminColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AdminColors.peach,
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AdminColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quản Trị Viên',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hệ thống trực tuyến',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          color: AdminColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn quản trị',
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AdminColors.textSecondary),
                  onSelected: (action) async {
                    if (action == 'api') await _checkApi();
                    if (action == 'refresh') await _refreshAccess();
                    if (action == 'test') await _handleClearTestData();
                    if (action == 'logout') await FirebaseAuth.instance.signOut();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'api',
                      child: ListTile(
                        leading: Icon(Icons.cloud_done_outlined, size: 18),
                        title: Text('Kiểm tra kết nối API'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh_rounded, size: 18),
                        title: Text('Làm mới quyền'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'test',
                      child: ListTile(
                        leading: Icon(Icons.cleaning_services_rounded, size: 18),
                        title: Text('Dọn dữ liệu test'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                        title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: GoogleFonts.beVietnamPro(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    final activeItem = _menuItems[_currentMenuIndex];

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.background,
        border: Border(
          bottom: BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Section Icon & Title
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminColors.peach,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminColors.border),
            ),
            child: Icon(activeItem.icon, color: AdminColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  activeItem.title.toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  activeItem.subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Realtime Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AdminColors.emerald,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Chi Nhánh Sẵn Sàng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Refresh Button
          IconButton(
            tooltip: 'Làm mới bảng điều khiển',
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.primary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentView() {
    switch (_currentMenuIndex) {
      case 0:
        return _buildExecutiveOverviewScreen();
      case 1:
        return const AdminBookingTimelineScreen(showAppBar: false);
      case 2:
        return const AdminOrderFulfillmentScreen(showAppBar: false);
      case 3:
        return const AdminProductInventoryScreen(showAppBar: false);
      case 4:
        return const AdminCustomer360Screen(showAppBar: false);
      case 5:
        return const AdminStaffRosterScreen(showAppBar: false);
      case 6:
        return const AdminMarketingCenterScreen(showAppBar: false);
      case 7:
        return const AdminFinancialAnalyticsScreen(showAppBar: false);
      default:
        return _buildExecutiveOverviewScreen();
    }
  }

  /// Trang 0: BẢNG TỔNG QUAN HOẠT ĐỘNG SPA
  Widget _buildExecutiveOverviewScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Chào Mừng & Điều Hành
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AdminColors.peach,
                  Color(0xFFFBF1E8),
                  Color(0xFFF3ECE4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.border),
              boxShadow: AdminColors.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không Gian Điều Hành Toàn Diện LUMI SPA',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Theo dõi đồng bộ tiến độ liệu trình phòng spa, quy trình xuất kho đơn mỹ phẩm và hiệu suất vận hành đa chi nhánh trong thời gian thực.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 28,
                    color: AdminColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Thẻ KPI Tóm Tắt Hoạt Động
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
                  // 1. Lịch Chờ Tiếp Nhận
                  SizedBox(
                    width: cardWidth,
                    child: StreamBuilder<List<BookingItem>>(
                      stream: AdminBookingRepository.instance.streamPendingBookings(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return _buildOverviewKpiCard(
                          title: 'Lịch Chờ Tiếp Nhận',
                          value: '$count lịch hẹn',
                          subtitle: 'Khách sắp đến hoặc đang chờ duyệt',
                          icon: Icons.alarm_on_rounded,
                          color: AdminColors.statusPending,
                          onTap: () => setState(() => _currentMenuIndex = 1),
                        );
                      },
                    ),
                  ),

                  // 2. Đơn Mỹ Phẩm Mới
                  SizedBox(
                    width: cardWidth,
                    child: StreamBuilder<List<AdminOrderItem>>(
                      stream: AdminOrderRepository.instance.streamPendingOrders(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return _buildOverviewKpiCard(
                          title: 'Đơn Mỹ Phẩm Chờ Duyệt',
                          value: '$count đơn mới',
                          subtitle: 'Cần xác nhận & xuất kho',
                          icon: Icons.shopping_bag_outlined,
                          color: AdminColors.statusConfirmed,
                          onTap: () => setState(() => _currentMenuIndex = 2),
                        );
                      },
                    ),
                  ),

                  // 3. Tồn Kho Cần Bổ Sung
                  SizedBox(
                    width: cardWidth,
                    child: _buildOverviewKpiCard(
                      title: 'Cảnh Báo Sắp Hết Hàng',
                      value: 'Kiểm tra kho',
                      subtitle: 'Định mức tồn dưới 10 hộp',
                      icon: Icons.warning_amber_rounded,
                      color: AdminColors.statusLowStock,
                      onTap: () => setState(() => _currentMenuIndex = 3),
                    ),
                  ),

                  // 4. Báo Cáo Doanh Thu
                  SizedBox(
                    width: cardWidth,
                    child: _buildOverviewKpiCard(
                      title: 'Doanh Thu & Lợi Nhuận',
                      value: 'Xem báo cáo',
                      subtitle: 'Chi tiết lợi nhuận gộp COGS',
                      icon: Icons.query_stats_rounded,
                      color: AdminColors.emerald,
                      onTap: () => setState(() => _currentMenuIndex = 7),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 2 Khối Giám Sát Chi Tiết Trực Quan (Row)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecentBookingsSection()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildRecentOrdersSection()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildRecentBookingsSection(),
                        const SizedBox(height: 20),
                        _buildRecentOrdersSection(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AdminColors.peach,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 18, color: AdminColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lịch Hẹn Cần Tiếp Nhận',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentMenuIndex = 1),
                child: Text('Xem toàn bộ', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BookingItem>>(
            stream: AdminBookingRepository.instance.streamPendingBookings(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('Không có lịch hẹn nào đang chờ tiếp nhận.', style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary, fontSize: 13)),
                  ),
                );
              }
              final displayList = list.take(4).toList();
              return Column(
                children: displayList.map((booking) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AdminColors.peach,
                          child: const Icon(Icons.person_rounded, size: 16, color: AdminColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.contactName,
                                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                              ),
                              Text(
                                '${booking.serviceName} • ${booking.formattedDateTime}',
                                style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminColors.statusPending.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Chờ tiếp nhận',
                            style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.statusPending),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AdminColors.peach,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 18, color: AdminColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đơn Mỹ Phẩm Chờ Duyệt',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentMenuIndex = 2),
                child: Text('Xem toàn bộ', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AdminOrderItem>>(
            stream: AdminOrderRepository.instance.streamPendingOrders(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('Không có đơn mỹ phẩm nào đang chờ duyệt.', style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary, fontSize: 13)),
                  ),
                );
              }
              final displayList = list.take(4).toList();
              return Column(
                children: displayList.map((order) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          child: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order.displayId} • ${order.customerName}',
                                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                              ),
                              Text(
                                '${order.displayTotal} • ${order.formattedCreatedAt}',
                                style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminColors.statusPending.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Chờ duyệt',
                            style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.statusPending),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
