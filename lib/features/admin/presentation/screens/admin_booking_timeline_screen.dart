import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../booking/data/models/booking_item.dart';
import '../../data/admin_booking_repository.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_assign_technician_dialog.dart';
import '../widgets/admin_booking_detail_dialog.dart';
import '../widgets/admin_reject_reason_dialog.dart';
import '../widgets/admin_treatment_record_dialog.dart';

class AdminBookingTimelineScreen extends StatefulWidget {
  const AdminBookingTimelineScreen({super.key});

  @override
  State<AdminBookingTimelineScreen> createState() =>
      _AdminBookingTimelineScreenState();
}

class _AdminBookingTimelineScreenState
    extends State<AdminBookingTimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  int _viewMode = 0; // 0: Ma trận Timeline phòng & KTV, 1: Danh sách tiến độ
  bool _isLoadingAction = false;
  Map<String, dynamic>? _timelineData;
  bool _isFetchingTimeline = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  String get _formattedDateString {
    final y = _selectedDate.year.toString();
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadTimeline() async {
    if (_isFetchingTimeline) return;
    setState(() => _isFetchingTimeline = true);
    try {
      final res = await AdminBookingRepository.instance.fetchTimelineMatrixV2(
        date: _formattedDateString,
      );
      if (mounted) {
        setState(() {
          _timelineData = res;
          _isFetchingTimeline = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingTimeline = false);
    }
  }

  Future<void> _handleConfirm(BookingItem booking) async {
    final assignData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AdminAssignTechnicianDialog(booking: booking),
    );
    if (assignData == null || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminBookingRepository.instance.confirmBookingV2(
        appointmentId: booking.id,
        technicianId: assignData['technicianId'],
        roomId: assignData['roomId'],
        note: assignData['note'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Đã duyệt lịch và khóa KTV/phòng!',
          ),
          backgroundColor: AdminColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTimeline();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi duyệt lịch: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCheckIn(BookingItem booking) async {
    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminBookingRepository.instance.checkInBookingV2(
        appointmentId: booking.id,
        note: 'Tiếp nhận khách hàng tại quầy lễ tân',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Khách đã check-in thành công!',
          ),
          backgroundColor: AdminColors.cyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTimeline();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi check-in: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleTreatmentRecord(BookingItem booking) async {
    final clinicalData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AdminTreatmentRecordDialog(booking: booking),
    );
    if (clinicalData == null || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminBookingRepository.instance.updateTreatmentRecordV2(
        appointmentId: booking.id,
        userId: booking.userId,
        skinConditionBefore: clinicalData['skinConditionBefore'],
        treatmentStepsApplied:
            List<String>.from(clinicalData['treatmentStepsApplied'] ?? []),
        skinReactionAfter: clinicalData['skinReactionAfter'],
        homecareRecommendations: clinicalData['homecareRecommendations'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Đã lưu hồ sơ bệnh án da!',
          ),
          backgroundColor: AdminColors.cyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTimeline();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleComplete(BookingItem booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AdminColors.border),
        ),
        title: Text(
          'Hoàn Tất Liệu Trình?',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
          ),
        ),
        content: Text(
          'Xác nhận hoàn tất liệu trình "${booking.serviceName}" cho khách ${booking.contactName}?\n\nHệ thống sẽ tự động:\n1. Tích điểm thưởng cho khách hàng.\n2. Tính hoa hồng 10% cho Kỹ thuật viên.\n3. Giải phóng phòng và chuyên viên trong hệ thống.',
          style: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.5, color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminColors.emerald),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: Text('HOÀN TẤT & TÍNH HOA HỒNG', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminBookingRepository.instance.completeBookingV2(
        appointmentId: booking.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Hoàn tất liệu trình thành công!',
          ),
          backgroundColor: AdminColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTimeline();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCancel(BookingItem booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AdminRejectReasonDialog(booking: booking),
    );
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      final res = await AdminBookingRepository.instance.cancelBookingV2(
        appointmentId: booking.id,
        reason: reason.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Đã hủy lịch hẹn!'),
          backgroundColor: AdminColors.statusCancelled,
        ),
      );
      _loadTimeline();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy lịch: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Widget _buildOccupancyCard(Map<String, dynamic>? stats) {
    final total = stats?['totalAppointments'] ?? 0;
    final confirmed = stats?['confirmedCount'] ?? 0;
    final rate = stats?['occupancyRate'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.slateTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công Suất Phục Vụ Chi Nhánh',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày $_formattedDateString • $confirmed / $total lịch đã duyệt',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: rate > 80
                  ? Colors.red.shade900.withValues(alpha: 0.4)
                  : AdminColors.emerald.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rate > 80 ? Colors.red.shade400 : AdminColors.emerald,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 16,
                  color: rate > 80 ? Colors.red.shade300 : AdminColors.emerald,
                ),
                const SizedBox(width: 6),
                Text(
                  'Lấp đầy: $rate%',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: rate > 80 ? Colors.red.shade300 : AdminColors.emerald,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMatrix() {
    final hours = [9, 10, 11, 12, 13, 14, 15, 16, 17];
    final rooms = [
      'Phòng 01 (Sen Trắng)',
      'Phòng 02 (VIP Hoàng Lan)',
      'Phòng 03 (Đá Bazan)',
      'Phòng 04 (Dưỡng Sinh)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(160),
            border: TableBorder.all(color: AdminColors.border, width: 0.5),
            children: [
              // Header Row: Time slots
              TableRow(
                decoration: const BoxDecoration(color: AdminColors.deepTeal),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Phòng \\ Giờ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.softGold,
                      ),
                    ),
                  ),
                  ...hours.map(
                    (h) => Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Room Rows
              ...rooms.map(
                (room) => TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AdminColors.slateTeal,
                      child: Text(
                        room,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ),
                    ...hours.map(
                      (h) {
                        final isBooked = (room.contains('01') && h == 10) ||
                            (room.contains('02') && h == 14) ||
                            (room.contains('03') && h == 11);

                        return Container(
                          height: 70,
                          padding: const EdgeInsets.all(6),
                          color: isBooked
                              ? AdminColors.emerald.withValues(alpha: 0.15)
                              : AdminColors.background,
                          child: isBooked
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AdminColors.deepTeal,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AdminColors.emerald.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Khách: Minh Thảo',
                                        maxLines: 1,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.emerald,
                                        ),
                                      ),
                                      Text(
                                        'Trẻ Hóa Tế Bào (KTV. Thảo)',
                                        maxLines: 1,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 9,
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'Trống',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      color: AdminColors.textMuted.withValues(alpha: 0.5),
                                    ),
                                  ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.deepTeal,
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
                color: AdminColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AdminColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LỊCH HẸN DỊCH VỤ & ĐIỀU PHỐI PHÒNG',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  'Ma trận khung giờ x Chuyên viên trị liệu x Phòng spa theo ngày',
                  style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới lịch hẹn',
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.gold),
            onPressed: _loadTimeline,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Controls Bar: Date Picker & View Switcher
          Container(
            padding: const EdgeInsets.all(14),
            color: AdminColors.deepTeal,
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadTimeline();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AdminColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AdminColors.softGold),
                        const SizedBox(width: 8),
                        Text(
                          _formattedDateString,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: AdminColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.grid_view_rounded, size: 16),
                        label: Text('Ma trận phòng'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.view_agenda_outlined, size: 16),
                        label: Text('Tiến độ phục vụ'),
                      ),
                    ],
                    selected: {_viewMode},
                    style: SegmentedButton.styleFrom(
                      backgroundColor: AdminColors.cardSurface,
                      selectedBackgroundColor: AdminColors.emerald,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: AdminColors.textSecondary,
                      textStyle: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onSelectionChanged: (set) =>
                        setState(() => _viewMode = set.first),
                  ),
                ),
              ],
            ),
          ),

          // 2. Occupancy Rate Bar
          _buildOccupancyCard(_timelineData?['stats']),

          // 3. Main Content
          Expanded(
            child: _viewMode == 0
                ? _buildTimelineMatrix()
                : StreamBuilder<List<BookingItem>>(
                    stream: AdminBookingRepository.instance.streamAllBookings(),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      if (snapshot.connectionState == ConnectionState.waiting && list.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(color: AdminColors.emerald),
                        );
                      }

                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'Chưa có lịch hẹn nào.',
                            style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final booking = list[index];
                          final status = booking.status.toLowerCase();

                          return Card(
                            color: AdminColors.cardSurface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AdminColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        booking.serviceName,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        booking.displayPrice,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AdminColors.softGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 15, color: AdminColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        booking.contactName,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.phone_outlined,
                                          size: 15, color: AdminColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        booking.contactPhone,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 15, color: AdminColors.softGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Khung giờ: ${booking.formattedStartAt} (${booking.durationMinutes} phút)',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: AdminColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(color: AdminColors.border, height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) =>
                                                AdminBookingDetailDialog(
                                              booking: booking,
                                              onApprove: () => _handleConfirm(booking),
                                              onReject: () => _handleCancel(booking),
                                              onComplete: () => _handleComplete(booking),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.info_outline_rounded,
                                            size: 15, color: AdminColors.cyan),
                                        label: Text(
                                          'Chi tiết',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AdminColors.cyan,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (['pending', 'confirmed', 'approved'].contains(status))
                                            TextButton(
                                              onPressed: _isLoadingAction
                                                  ? null
                                                  : () => _handleCancel(booking),
                                              child: Text(
                                                'Hủy lịch',
                                                style: GoogleFonts.beVietnamPro(
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
                                                  : () => _handleConfirm(booking),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AdminColors.emerald,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                                              label: Text(
                                                'DUYỆT & GÁN KTV',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            )
                                          else if (['confirmed', 'approved'].contains(status))
                                            FilledButton.icon(
                                              onPressed: _isLoadingAction
                                                  ? null
                                                  : () => _handleCheckIn(booking),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AdminColors.cyan,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              icon: const Icon(Icons.login_rounded, size: 16),
                                              label: Text(
                                                'ĐÓN KHÁCH (CHECK-IN)',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            )
                                          else if (['checked_in', 'in_progress'].contains(status))
                                            Row(
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleTreatmentRecord(booking),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AdminColors.softGold,
                                                    side: const BorderSide(color: AdminColors.goldAccent),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                                                  label: Text(
                                                    'HỒ SƠ LIỆU TRÌNH',
                                                    style: GoogleFonts.beVietnamPro(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                FilledButton.icon(
                                                  onPressed: _isLoadingAction
                                                      ? null
                                                      : () => _handleComplete(booking),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: AdminColors.statusCompleted,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.task_alt_rounded, size: 16),
                                                  label: Text(
                                                    'HOÀN TẤT LIỆU TRÌNH',
                                                    style: GoogleFonts.beVietnamPro(
                                                      fontWeight: FontWeight.w700,
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
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
