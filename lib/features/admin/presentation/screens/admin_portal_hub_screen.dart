import 'package:flutter/material.dart';
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
import 'admin_order_screen.dart';
import 'admin_user_screen.dart';

class AdminPortalHubScreen extends StatefulWidget {
  const AdminPortalHubScreen({super.key});

  @override
  State<AdminPortalHubScreen> createState() => _AdminPortalHubScreenState();
}

class _AdminPortalHubScreenState extends State<AdminPortalHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: LumiStyle.plum,
          ),
        ),
        content: Text(
          'Hệ thống sẽ dọn dẹp các đơn hàng và lịch hẹn thử nghiệm cũ trong Firestore để bạn bắt đầu kiểm thử từ trạng thái sạch hoàn toàn.\n\n(Dữ liệu người dùng sẽ được giữ nguyên an toàn).',
          style: GoogleFonts.dmSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('HỦY', style: GoogleFonts.dmSans(color: LumiStyle.muted)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: Text('DỌN DẸP NGAY', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await AdminUserRepository.instance.clearTestData(target: 'all');
      LumiOrderStore.orders.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Đã dọn dẹp dữ liệu test thành công!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiStyle.ivory,
      appBar: AppBar(
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
          IconButton(
            tooltip: 'Dọn dẹp dữ liệu test (Reset)',
            icon: const Icon(Icons.cleaning_services_outlined, color: LumiStyle.muted, size: 20),
            onPressed: _handleClearTestData,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LumiStyle.line),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: LumiStyle.rose,
                    indicatorWeight: 3,
                    labelColor: LumiStyle.rose,
                    unselectedLabelColor: LumiStyle.muted,
                    labelStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      // Tab 1: Lịch Hẹn Spa
                      StreamBuilder<List<BookingItem>>(
                        stream: AdminBookingRepository.instance.streamPendingBookings(),
                        builder: (context, snapshot) {
                          final pendingCount = (snapshot.data ?? []).length;
                          return Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 18),
                                const SizedBox(width: 8),
                                const Text('Lịch Hẹn Spa'),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: LumiStyle.rose,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      pendingCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      // Tab 2: Đơn Hàng Mỹ Phẩm
                      StreamBuilder<List<AdminOrderItem>>(
                        stream: AdminOrderRepository.instance.streamPendingOrders(),
                        builder: (context, snapshot) {
                          final pendingCount = (snapshot.data ?? []).length;
                          return Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 18),
                                const SizedBox(width: 8),
                                const Text('Đơn Hàng'),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      pendingCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      // Tab 3: Khách Hàng / Người Dùng
                      StreamBuilder<List<AdminUserItem>>(
                        stream: AdminUserRepository.instance.streamAllUsers(),
                        builder: (context, snapshot) {
                          final count = (snapshot.data ?? []).length;
                          return Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 18),
                                const SizedBox(width: 8),
                                const Text('Người Dùng'),
                                if (count > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: LumiStyle.plum,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminBookingScreen(showAppBar: false),
          AdminOrderScreen(),
          AdminUserScreen(),
        ],
      ),
    );
  }
}
