import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/lumi_api_client.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_order_store.dart';
import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/models/booking_item.dart';
import '../../data/admin_booking_repository.dart';
import '../../data/admin_order_repository.dart';
import '../../data/admin_user_repository.dart';
import '../../data/models/admin_order_item.dart';
import '../../data/models/admin_user_item.dart';
import 'admin_booking_screen.dart';
import 'admin_booking_timeline_screen.dart';
import 'admin_order_fulfillment_screen.dart';
import 'admin_order_screen.dart';
import 'admin_user_screen.dart';
import 'admin_customer_360_screen.dart';
import 'admin_staff_roster_screen.dart';
import 'admin_marketing_center_screen.dart';
import 'admin_financial_analytics_screen.dart';

class AdminPortalHubScreen extends StatefulWidget {
  const AdminPortalHubScreen({super.key});

  @override
  State<AdminPortalHubScreen> createState() => _AdminPortalHubScreenState();
}

class _AdminPortalHubScreenState extends State<AdminPortalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _checkingApi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleClearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiStyle.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Dọn dẹp dữ liệu test?',
          style: GoogleFonts.beVietnamPro(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LumiStyle.plum,
          ),
        ),
        content: Text(
          'Hệ thống sẽ dọn dẹp các đơn hàng và lịch hẹn thử nghiệm cũ trong Firestore để bạn bắt đầu kiểm thử từ trạng thái sạch hoàn toàn.\n\n(Dữ liệu người dùng sẽ được giữ nguyên an toàn).',
          style: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'HỦY',
              style: GoogleFonts.beVietnamPro(color: LumiStyle.muted),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
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
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi dọn dẹp: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkApi() async {
    if (_checkingApi) {
      return;
    }
    setState(() {
      _checkingApi = true;
    });
    try {
      await LumiApiClient.instance.get('/api/admin/health');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API quản trị đã phản hồi. Xác thực admin hợp lệ.'),
          backgroundColor: Color(0xFF38644F),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa kết nối được API quản trị: $error'),
          backgroundColor: const Color(0xFF994B3D),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingApi = false;
        });
      }
    }
  }

  Future<void> _refreshAccess() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa làm mới được quyền. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Widget _destination(IconData icon, String label, int count) {
    return Tab(
      height: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA5553E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF403735);
    const peach = Color(0xFFFBE4D6);
    const blue = Color(0xFFE1EEF2);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: peach,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.spa_outlined,
                color: Color(0xFFA5553E),
                size: 24,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LUMI',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'TỔNG QUAN HOẠT ĐỘNG SPA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: const Color(0xFF81726A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tài khoản quản trị',
            icon: const Icon(Icons.more_horiz_rounded, color: ink),
            onSelected: (action) async {
              if (action == 'api') {
                await _checkApi();
              }
              if (action == 'refresh') {
                await _refreshAccess();
              }
              if (action == 'logout') {
                await FirebaseAuth.instance.signOut();
              }
              if (action == 'test') {
                await _handleClearTestData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'api',
                enabled: !_checkingApi,
                child: ListTile(
                  leading: const Icon(Icons.cloud_done_outlined),
                  title: Text(
                    _checkingApi
                        ? 'Đang kiểm tra API…'
                        : 'Kiểm tra kết nối API',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Làm mới quyền'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Đăng xuất'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (const bool.fromEnvironment('LUMI_ADMIN_TEST_TOOLS'))
                const PopupMenuItem(
                  value: 'test',
                  child: Text('Dọn dữ liệu thử nghiệm'),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [peach, Color(0xFFF0EBDF), blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA5553E).withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Không Gian Điều Hành LUMI SPA',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 21,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Theo dõi toàn diện lịch khách hẹn trong ngày, đơn hàng mỹ phẩm và hiệu suất vận hành.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                height: 1.5,
                                color: const Color(0xFF756863),
                              ),
                            ),
                          const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Lịch hẹn dịch vụ',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminBookingTimelineScreen()),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Đơn hàng mỹ phẩm',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminOrderFulfillmentScreen()),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Hồ sơ khách hàng',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminCustomer360Screen()),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Đội ngũ nhân sự & Ca trực',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminStaffRosterScreen()),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.loyalty_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Chương trình ưu đãi',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminMarketingCenterScreen()),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.insights_rounded, size: 16, color: Color(0xFF0D3B35)),
                                  label: Text(
                                    'Báo cáo doanh thu & Lợi nhuận',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0D3B35)),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF0D3B35), width: 1.2),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminFinancialAnalyticsScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.auto_awesome_outlined,
                        size: 30,
                        color: Color(0xFFA5553E),
                      ),
                    ],
                  ),
                ),
                // Khối Tóm Tắt Vận Hành Trực Quan (Xem nhanh lịch hẹn & đơn hàng)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<BookingItem>>(
                          stream: AdminBookingRepository.instance.streamPendingBookings(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return InkWell(
                              onTap: () => _tabController.animateTo(0),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEADDD3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ink.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF39C12).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFF39C12), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Lịch Chờ Tiếp Nhận',
                                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF81726A), fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$count lịch hẹn',
                                            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<List<AdminOrderItem>>(
                          stream: AdminOrderRepository.instance.streamPendingOrders(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return InkWell(
                              onTap: () => _tabController.animateTo(1),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEADDD3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ink.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3498DB).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF3498DB), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Đơn Mỹ Phẩm Mới',
                                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF81726A), fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$count đơn cần duyệt',
                                            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: const Color(0xFFEADDD3)),
                    boxShadow: [
                      BoxShadow(
                        color: ink.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [peach, Color(0xFFF5D2BD)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: const Color(0xFF894A36),
                    unselectedLabelColor: const Color(0xFF81726A),
                    labelStyle: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    tabs: [
                      StreamBuilder<List<BookingItem>>(
                        stream: AdminBookingRepository.instance
                            .streamPendingBookings(),
                        builder: (context, snapshot) => _destination(
                          Icons.calendar_month_outlined,
                          'Lịch hẹn dịch vụ',
                          snapshot.data?.length ?? 0,
                        ),
                      ),
                      StreamBuilder<List<AdminOrderItem>>(
                        stream: AdminOrderRepository.instance
                            .streamPendingOrders(),
                        builder: (context, snapshot) => _destination(
                          Icons.shopping_bag_outlined,
                          'Đơn hàng mỹ phẩm',
                          snapshot.data?.length ?? 0,
                        ),
                      ),
                      StreamBuilder<List<AdminUserItem>>(
                        stream: AdminUserRepository.instance.streamAllUsers(),
                        builder: (context, snapshot) => _destination(
                          Icons.people_outline_rounded,
                          'Hồ sơ khách hàng',
                          snapshot.data?.length ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      AdminBookingScreen(showAppBar: false),
                      AdminOrderScreen(),
                      AdminUserScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
