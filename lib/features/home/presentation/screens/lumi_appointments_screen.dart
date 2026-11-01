import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumi_spa/core/theme/lumi_style.dart';
import 'package:lumi_spa/features/booking/data/booking_repository.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';
import 'package:lumi_spa/features/booking/presentation/widgets/booking_card.dart';
import 'package:lumi_spa/features/booking/presentation/widgets/booking_detail_sheet.dart';

class LumiAppointmentsScreen extends StatefulWidget {
  const LumiAppointmentsScreen({
    super.key,
    required this.isLoggedIn,
    required this.onExploreServices,
    required this.onLogin,
  });

  final bool isLoggedIn;
  final VoidCallback onExploreServices;
  final VoidCallback onLogin;

  @override
  State<LumiAppointmentsScreen> createState() => _LumiAppointmentsScreenState();
}

class _LumiAppointmentsScreenState extends State<LumiAppointmentsScreen> {
  static const ink = LumiStyle.plum;
  static const plum = LumiStyle.plum;
  static const rose = LumiStyle.rose;
  static const blush = LumiStyle.softPink;
  static const muted = LumiStyle.muted;

  int _selectedTab = 0; // 0: Sắp tới, 1: Lịch sử, 2: Đã hủy
  bool _isLoading = false;
  String? _errorMessage;
  List<BookingItem> _bookings = [];
  StreamSubscription<List<BookingItem>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _listenToFirestoreBookings();
    }
  }

  @override
  void didUpdateWidget(covariant LumiAppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn) {
      if (widget.isLoggedIn) {
        _listenToFirestoreBookings();
      } else {
        _streamSubscription?.cancel();
        setState(() => _bookings = []);
      }
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// KẾT NỐI MY APPOINTMENTS VỚI FIRESTORE
  /// Lắng nghe cập nhật realtime từ Cloud Firestore
  void _listenToFirestoreBookings() {
    _streamSubscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _bookings = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _streamSubscription = BookingRepository.instance
        .streamUserBookings(user.uid)
        .listen(
          (list) {
            if (mounted) {
              setState(() {
                _bookings = list;
                _isLoading = false;
                _errorMessage = null;
              });
            }
          },
          onError: (e) {
            debugPrint(
              'Firestore stream error, fallback to one-time fetch: $e',
            );
            _fetchBookings();
          },
        );
  }

  /// Tải lại dữ liệu (kết nối Firestore + fallback API)
  Future<void> _fetchBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await BookingRepository.instance.getUserBookings(user.uid);
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<BookingItem> get _filteredBookings {
    switch (_selectedTab) {
      case 0: // Sắp tới: pending & confirmed trong tương lai
        return _bookings.where((b) => b.isUpcoming).toList();
      case 1: // Lịch sử: completed hoặc đã qua thời gian hẹn
        return _bookings.where((b) => b.isHistory).toList();
      case 2: // Đã hủy
        return _bookings.where((b) => b.isCancelled).toList();
      default:
        return _bookings;
    }
  }

  int get _upcomingCount => _bookings.where((b) => b.isUpcoming).length;
  int get _historyCount => _bookings.where((b) => b.isHistory).length;
  int get _cancelledCount => _bookings.where((b) => b.isCancelled).length;

  /// HỦY LỊCH HẸN
  Future<void> _confirmCancel(BookingItem booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LumiStyle.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hủy lịch hẹn?',
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: plum,
          ),
        ),
        content: Text(
          'Quý khách có chắc chắn muốn hủy lịch hẹn liệu trình "${booking.serviceName}" vào lúc ${booking.formattedDateTime} không?\n\nPhòng và chuyên viên sẽ được giải phóng trên hệ thống cho khách hàng khác.',
          style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: plum),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'GIỮ LỊCH',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'XÁC NHẬN HỦY',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _executeCancel(booking.id);
    }
  }

  Future<void> _executeCancel(String bookingId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: rose)),
    );

    try {
      await BookingRepository.instance.cancelBooking(bookingId);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
        _fetchBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy lịch hẹn thành công.'),
            backgroundColor: plum,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showDetail(BookingItem booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingDetailSheet(
        booking: booking,
        onCancel: booking.isCancellable ? () => _confirmCancel(booking) : null,
      ),
    );
  }

  Widget _tabButton(String title, int count, int index) {
    final selected = _selectedTab == index;
    final displayTitle = count > 0 ? '$title ($count)' : title;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: plum.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            displayTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? plum : muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    String title;
    String desc;

    if (!widget.isLoggedIn) {
      title = 'Đăng nhập để xem lịch hẹn';
      desc = 'Đăng nhập để theo dõi và quản lý những buổi chăm sóc của riêng bạn tại LUMI.';
    } else {
      switch (_selectedTab) {
        case 0:
          title = 'Chưa có lịch hẹn sắp tới';
          desc = 'Chọn dịch vụ để đặt lịch.';
          break;
        case 1:
          title = 'Chưa có lịch sử dịch vụ';
          desc = 'Các buổi chăm sóc sau khi hoàn thành hoặc qua ngày hẹn sẽ lưu trữ tại đây.';
          break;
        case 2:
        default:
          title = 'Chưa có lịch hẹn nào bị hủy';
          desc = 'Danh sách các lịch đã hủy sẽ hiển thị tại khu vực này.';
          break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E4E6)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: blush.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              !widget.isLoggedIn
                  ? Icons.login_rounded
                  : _selectedTab == 0
                  ? Icons.calendar_month_outlined
                  : _selectedTab == 1
                  ? Icons.history_rounded
                  : Icons.event_busy_outlined,
              color: plum,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.isLoggedIn
                  ? widget.onExploreServices
                  : widget.onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                widget.isLoggedIn ? Icons.spa_outlined : Icons.login_rounded,
                size: 18,
              ),
              label: Text(
                widget.isLoggedIn ? 'Chọn dịch vụ' : 'ĐĂNG NHẬP NGAY',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 14),
          Text(
            'Không thể tải lịch hẹn',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: plum,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Đã xảy ra sự cố kết nối với hệ thống Firestore.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (_errorMessage?.contains('đăng nhập') == true ||
              _errorMessage?.contains('Phiên') == true) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: widget.onLogin,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'ĐĂNG NHẬP LẠI',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: rose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _fetchBookings,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: rose),
            label: Text(
              'Thử lại',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: rose,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: rose),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBookings;

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      color: rose,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 115),
        children: [
          Text(
            'Lịch hẹn',
            style: GoogleFonts.dmSans(
              fontSize: 28,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: blush.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              children: [
                _tabButton('Sắp tới', _upcomingCount, 0),
                _tabButton('Lịch sử', _historyCount, 1),
                _tabButton('Đã hủy', _cancelledCount, 2),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!widget.isLoggedIn)
            _emptyState()
          else if (_isLoading && _bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: rose)),
            )
          else if (_errorMessage != null && _bookings.isEmpty)
            _errorState()
          else if (list.isEmpty)
            _emptyState()
          else
            for (final booking in list)
              BookingCard(
                booking: booking,
                onTap: () => _showDetail(booking),
                onCancel: booking.isCancellable
                    ? () => _confirmCancel(booking)
                    : null,
              ),
        ],
      ),
    );
  }
}
