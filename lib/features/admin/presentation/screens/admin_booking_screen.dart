import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _selectedFilter =
      0; // 0: Chờ duyệt (Pending), 1: Tất cả, 2: Đã duyệt, 3: Đã từ chối
  bool? _forceTableView; // null: auto-detect by screen width

  List<BookingItem>? _fallbackApiBookings;
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
      final list = await AdminBookingRepository.instance.fetchBookingsFromApi();
      if (!mounted) return;
      setState(() {
        _fallbackApiBookings = list;
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
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: LumiStyle.plum,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Truy cập Firebase Console -> Firestore Database -> Thẻ Rules.\n'
                  '2. Dán nội dung quy tắc bên dưới và nhấn "Publish" (Xuất bản).\n'
                  '3. Hệ thống sẽ ngay lập tức cho phép đọc/ghi real-time!',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
                    color: LumiStyle.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SelectableText('''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{id} { allow read, write: if true; }
    match /orders/{id} { allow read, write: if true; }
    match /notifications/{id} { allow read, write: if true; }
    match /{document=**} { allow read, write: if true; }
  }
}''', style: GoogleFonts.spaceMono(fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /bookings/{id} { allow read, write: if true; }
    match /orders/{id} { allow read, write: if true; }
    match /notifications/{id} { allow read, write: if true; }
    match /{document=**} { allow read, write: if true; }
  }
}''',
                ),
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép nội dung Rules vào bộ nhớ tạm!'),
                ),
              );
            },
            child: Text(
              'Sao chép Rules',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: LumiStyle.rose,
              ),
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
          content: Text(
            'Đã duyệt đơn #${booking.id.substring(0, 8).toUpperCase()} thành công!',
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Refresh API fallback if active
      if (_fallbackApiBookings != null) {
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

  Future<void> _handleReject(BookingItem booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AdminRejectReasonDialog(booking: booking),
    );

    if (reason == null || !mounted) return;

    try {
      await AdminBookingRepository.instance.rejectBooking(
        booking,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã từ chối đơn #${booking.id.substring(0, 8).toUpperCase()}!',
          ),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_fallbackApiBookings != null) {
        _fetchFallbackApi();
      }
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
    showDialog(
      context: context,
      builder: (_) => AdminBookingDetailDialog(
        booking: booking,
        onApprove: () {
          Navigator.of(context).pop();
          _handleApprove(booking);
        },
        onReject: () {
          Navigator.of(context).pop();
          _handleReject(booking);
        },
      ),
    );
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
          const Icon(
            Icons.cloud_sync_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang đồng bộ dữ liệu qua Backend API (Port 3000)',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final useTableView = _forceTableView ?? (screenWidth >= 768);

    return Scaffold(
      backgroundColor: LumiStyle.ivory,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: LumiStyle.ivory,
              elevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                  tooltip: useTableView
                      ? 'Xem dạng Thẻ (Cards)'
                      : 'Xem dạng Bảng (Table)',
                  onPressed: () {
                    setState(() {
                      _forceTableView = !useTableView;
                    });
                  },
                  icon: Icon(
                    useTableView
                        ? Icons.grid_view_rounded
                        : Icons.table_chart_rounded,
                    color: LumiStyle.plum,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: StreamBuilder<List<BookingItem>>(
        stream: AdminBookingRepository.instance.streamAllBookings(),
        builder: (context, snapshot) {
          List<BookingItem> allBookings = [];
          bool isUsingFallback = false;

          if (snapshot.connectionState == ConnectionState.waiting &&
              _fallbackApiBookings == null) {
            return const Center(
              child: CircularProgressIndicator(color: LumiStyle.rose),
            );
          }

          if (snapshot.hasError) {
            if (_fallbackApiBookings != null) {
              allBookings = _fallbackApiBookings!;
              isUsingFallback = true;
            } else {
              // Kích hoạt nạp dự phòng qua Backend API
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
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: LumiStyle.muted,
                        ),
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
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lỗi kết nối Firestore',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: LumiStyle.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            onPressed: _fetchFallbackApi,
                            style: FilledButton.styleFrom(
                              backgroundColor: LumiStyle.rose,
                            ),
                            icon: const Icon(
                              Icons.cloud_download_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'Tải qua Backend API',
                              style: GoogleFonts.dmSans(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _showRulesGuideDialog,
                            icon: const Icon(Icons.security_rounded, size: 16),
                            label: Text(
                              'Cách sửa Rules',
                              style: GoogleFonts.dmSans(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            allBookings = snapshot.data ?? [];
          }

          // Thống kê nhanh
          final pendingCount = allBookings
              .where((b) => b.status == 'pending')
              .length;
          final approvedCount = allBookings
              .where((b) => b.status == 'approved' || b.status == 'confirmed')
              .length;
          final rejectedCount = allBookings
              .where((b) => b.status == 'rejected' || b.status == 'cancelled')
              .length;

          // Lọc danh sách theo Tab
          List<BookingItem> filtered = allBookings;
          if (_selectedFilter == 0) {
            filtered = allBookings.where((b) => b.status == 'pending').toList();
          } else if (_selectedFilter == 2) {
            filtered = allBookings
                .where((b) => b.status == 'approved' || b.status == 'confirmed')
                .toList();
          } else if (_selectedFilter == 3) {
            filtered = allBookings
                .where((b) => b.status == 'rejected' || b.status == 'cancelled')
                .toList();
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
              if (isUsingFallback) _buildFallbackNoticeBanner(),

              // 1. Thẻ KPI Thống kê nhanh
              _buildKpiSection(
                pendingCount: pendingCount,
                approvedCount: approvedCount,
                rejectedCount: rejectedCount,
                totalCount: allBookings.length,
              ),
              const SizedBox(height: 20),

              // 2. Toolbar: Search bar & Tab lọc trạng thái
              _buildToolbar(
                pendingCount,
                allBookings.length,
                approvedCount,
                rejectedCount,
              ),
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
                      Icon(
                        Icons.inbox_outlined,
                        size: 54,
                        color: LumiStyle.line,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không tìm thấy lịch hẹn phù hợp',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: LumiStyle.muted,
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
        final isSmall = constraints.maxWidth < 600;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard(
              title: 'Chờ duyệt',
              count: pendingCount,
              icon: Icons.hourglass_top_rounded,
              color: Colors.amber.shade800,
              bgColor: Colors.amber.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Đã duyệt',
              count: approvedCount,
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green.shade800,
              bgColor: Colors.green.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Đã từ chối',
              count: rejectedCount,
              icon: Icons.cancel_outlined,
              color: Colors.red.shade800,
              bgColor: Colors.red.shade50,
              width: cardWidth,
            ),
            _kpiCard(
              title: 'Tổng số lịch',
              count: totalCount,
              icon: Icons.calendar_month_rounded,
              color: LumiStyle.plum,
              bgColor: LumiStyle.blushSurface,
              width: cardWidth,
            ),
          ],
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
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
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
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
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
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
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

  Widget _buildToolbar(
    int pendingCount,
    int totalCount,
    int approvedCount,
    int rejectedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Tìm kiếm theo tên khách, SĐT, dịch vụ hoặc mã lịch hẹn...',
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: LumiStyle.muted),
            prefixIcon: const Icon(
              Icons.search,
              color: LumiStyle.rose,
              size: 20,
            ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterTab(
                0,
                'Chờ duyệt ($pendingCount)',
                Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 8),
              _filterTab(1, 'Tất cả ($totalCount)', Icons.all_inbox_rounded),
              const SizedBox(width: 8),
              _filterTab(
                2,
                'Đã duyệt ($approvedCount)',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _filterTab(
                3,
                'Đã từ chối ($rejectedCount)',
                Icons.cancel_outlined,
              ),
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
          border: Border.all(color: selected ? LumiStyle.rose : LumiStyle.line),
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
