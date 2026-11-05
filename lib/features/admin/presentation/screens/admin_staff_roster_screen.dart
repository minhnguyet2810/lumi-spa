import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_hrm_repository.dart';
import '../../data/models/admin_staff_shift_model.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_create_shift_dialog.dart';
import '../widgets/admin_shift_action_dialog.dart';
import '../widgets/admin_staff_list_dialog.dart';

class AdminStaffRosterScreen extends StatefulWidget {
  const AdminStaffRosterScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AdminStaffRosterScreen> createState() => _AdminStaffRosterScreenState();
}

class _AdminStaffRosterScreenState extends State<AdminStaffRosterScreen> {
  late DateTime _currentWeekStart; // Thứ Hai của tuần đang xem
  String _selectedRoleFilter = 'all'; // all, specialist, receptionist, branch_manager

  List<StaffMemberItem> _staffMembers = [];
  List<StaffShiftItem> _shifts = [];
  HrmKpiStats _stats = const HrmKpiStats();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Tìm Thứ Hai của tuần hiện tại (weekday: 1 là Thứ 2, 7 là CN)
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _fetchData();
  }

  String _formatDate(DateTime d) {
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime get _currentWeekEnd => _currentWeekStart.add(const Duration(days: 6));

  List<DateTime> get _daysOfWeek {
    return List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final startStr = _formatDate(_currentWeekStart);
      final endStr = _formatDate(_currentWeekEnd);

      final metricsFuture = AdminHrmRepository.instance.fetchHrmMetrics();
      final staffFuture = AdminHrmRepository.instance.fetchStaffMembers();
      final rosterFuture = AdminHrmRepository.instance.fetchRoster(startDate: startStr, endDate: endStr);

      final results = await Future.wait([metricsFuture, staffFuture, rosterFuture]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as HrmKpiStats;
        _staffMembers = results[1] as List<StaffMemberItem>;
        _shifts = results[2] as List<StaffShiftItem>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('StateError: ', '');
        _loading = false;
      });
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _fetchData();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _fetchData();
  }

  void _jumpToCurrentWeek() {
    final now = DateTime.now();
    setState(() {
      _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    });
    _fetchData();
  }

  void _openCreateShiftDialog({String? staffId, String? date}) {
    showDialog(
      context: context,
      builder: (_) => AdminCreateShiftDialog(
        staffList: _staffMembers,
        initialStaffId: staffId,
        initialDate: date,
        onCreated: _fetchData,
      ),
    );
  }

  void _openShiftActionDialog(StaffShiftItem shift) {
    showDialog(
      context: context,
      builder: (_) => AdminShiftActionDialog(
        shift: shift,
        onChanged: _fetchData,
      ),
    );
  }

  void _openStaffListDialog() {
    showDialog(
      context: context,
      builder: (_) => AdminStaffListDialog(
        initialStaff: _staffMembers,
        onStaffUpdated: _fetchData,
      ),
    );
  }

  List<StaffMemberItem> get _filteredStaff {
    if (_selectedRoleFilter == 'all') return _staffMembers;
    return _staffMembers.where((s) => s.role.toLowerCase() == _selectedRoleFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: Column(
          children: [
            // 1. Top KPI Metrics bar
            _buildKpiMetricsBar(),

            // 2. Navigation & Week Selector Toolbar
            _buildNavigationToolbar(),

            // 3. Interactive Weekly Schedule Roster Matrix
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
                  : _error != null
                      ? _buildErrorView()
                      : _buildWeeklyRosterMatrix(),
            ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Container(
        color: AdminColors.background,
        child: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.background,
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
                color: AdminColors.peach,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.border),
              ),
              child: const Icon(Icons.calendar_view_week_rounded, color: AdminColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐỘI NGŨ NHÂN SỰ & CA TRỰC',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  'Lịch phân ca làm việc, chấm công thực tế & duyệt nghỉ phép đa chi nhánh',
                  style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới lịch trực',
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.primary),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildKpiMetricsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.cardShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _kpiCard(
                title: 'Tổng Nhân Sự',
                value: '${_stats.totalStaff}',
                subtitle: '${_staffMembers.length} hồ sơ nhân viên',
                icon: Icons.badge_rounded,
                color: const Color(0xFF0284C7),
                width: isCompact ? constraints.maxWidth / 2 - 12 : 200,
              ),
              _kpiCard(
                title: 'Đang Trực Ca Hôm Nay',
                value: '${_stats.onDutyToday}',
                subtitle: '${_stats.completedToday} ca đã hoàn tất',
                icon: Icons.how_to_reg_rounded,
                color: AdminColors.emerald,
                width: isCompact ? constraints.maxWidth / 2 - 12 : 200,
              ),
              _kpiCard(
                title: 'Ca Đã Xếp Tuần Này',
                value: '${_shifts.length}',
                subtitle: 'Khung giờ sáng & chiều',
                icon: Icons.event_available_rounded,
                color: AdminColors.primary,
                width: isCompact ? constraints.maxWidth / 2 - 12 : 200,
              ),
              _kpiCard(
                title: 'Đơn Xin Nghỉ Chờ Duyệt',
                value: '${_stats.pendingLeaveCount}',
                subtitle: 'Cần quản trị phê duyệt',
                icon: Icons.pending_actions_rounded,
                color: AdminColors.statusPending,
                width: isCompact ? constraints.maxWidth / 2 - 12 : 200,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.elevatedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationToolbar() {
    final start = _currentWeekStart;
    final end = _currentWeekEnd;
    final rangeText = 'Tuần: ${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminColors.softShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Week Navigator Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AdminColors.primary),
                    tooltip: 'Tuần trước',
                    onPressed: _previousWeek,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AdminColors.peachLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Text(
                      rangeText,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AdminColors.primary),
                    tooltip: 'Tuần kế tiếp',
                    onPressed: _nextWeek,
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: _jumpToCurrentWeek,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.primary,
                      side: const BorderSide(color: AdminColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Hôm nay'),
                  ),
                ],
              ),

              // Role Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roleFilterChip('all', 'Tất cả (${_staffMembers.length})'),
                    _roleFilterChip('specialist', 'Kỹ thuật viên', color: const Color(0xFF16A34A)),
                    _roleFilterChip('receptionist', 'Lễ tân', color: const Color(0xFF0284C7)),
                    _roleFilterChip('branch_manager', 'Quản lý', color: AdminColors.primary),
                  ],
                ),
              ),

              // Action Buttons: Xếp ca & Quản lý nhân sự
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openStaffListDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.textPrimary,
                      side: const BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.badge_rounded, size: 16, color: AdminColors.primary),
                    label: Text('Nhân sự (${_staffMembers.length})', style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _openCreateShiftDialog(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: Text(
                      'XẾP CA MỚI',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roleFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedRoleFilter == key;
    final chipColor = color ?? AdminColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedRoleFilter = key);
        },
        selectedColor: AdminColors.peach,
        backgroundColor: AdminColors.cardSurface,
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? chipColor : AdminColors.textSecondary,
        ),
        side: BorderSide(color: isSelected ? chipColor : AdminColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildWeeklyRosterMatrix() {
    final staffList = _filteredStaff;
    final days = _daysOfWeek;
    final todayStr = _formatDate(DateTime.now());

    if (staffList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, size: 54, color: AdminColors.textMuted),
              const SizedBox(height: 12),
              Text('Chưa có nhân viên nào trong danh mục này.', style: GoogleFonts.beVietnamPro(fontSize: 14, color: AdminColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openStaffListDialog,
                style: FilledButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
                child: const Text('Thêm nhân viên ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: AdminColors.cardSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AdminColors.border),
                  boxShadow: AdminColors.cardShadow,
                ),
                child: Column(
                  children: [
                    // Matrix Header Row: Staff info + 7 Days
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: AdminColors.peachLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                        border: Border(bottom: BorderSide(color: AdminColors.border)),
                      ),
                      child: Row(
                        children: [
                          // Col 0: Staff title
                          Container(
                            width: 220,
                            padding: const EdgeInsets.only(left: 18),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'NHÂN VIÊN / CHỨC VỤ',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          // Cols 1-7: Days of week
                          ...days.map((day) {
                            final dateStr = _formatDate(day);
                            final isToday = dateStr == todayStr;
                            final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                            final dayName = dayNames[day.weekday - 1];

                            return Container(
                              width: 140,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isToday ? AdminColors.peach : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isToday ? AdminColors.primary : AdminColors.textPrimary,
                                        ),
                                      ),
                                      if (isToday) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AdminColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'HÔM NAY',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${day.day}/${day.month}',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      color: isToday ? AdminColors.primary : AdminColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Matrix Data Rows (Each staff member)
                    ...staffList.map((staff) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Staff Info Column
                            Container(
                              width: 220,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: staff.roleColor.withValues(alpha: 0.15),
                                    child: Text(
                                      staff.initials,
                                      style: TextStyle(
                                        color: staff.roleColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff.name,
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AdminColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          staff.roleLabel,
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 10,
                                            color: staff.roleColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 7 Day Cells
                            ...days.map((day) {
                              final dateStr = _formatDate(day);
                              final isToday = dateStr == todayStr;
                              final dayShifts = _shifts.where(
                                (s) => s.staffId == staff.id && s.date == dateStr,
                              ).toList();

                              return Container(
                                width: 140,
                                height: 86,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AdminColors.peachLight.withValues(alpha: 0.3)
                                      : null,
                                  border: const Border(
                                    left: BorderSide(color: AdminColors.borderSubtle, width: 0.8),
                                  ),
                                ),
                                child: dayShifts.isNotEmpty
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: dayShifts.map((sh) => _buildShiftBadge(sh)).toList(),
                                      )
                                    : Center(
                                        child: InkWell(
                                          onTap: () => _openCreateShiftDialog(staffId: staff.id, date: dateStr),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AdminColors.peachLight,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AdminColors.border),
                                            ),
                                            child: const Icon(Icons.add_rounded, size: 18, color: AdminColors.primary),
                                          ),
                                        ),
                                      ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShiftBadge(StaffShiftItem shift) {
    final statusColor = shift.statusColor;

    return InkWell(
      onTap: () => _openShiftActionDialog(shift),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: AdminColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shift.shiftTypeLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              shift.timeRange,
              style: GoogleFonts.beVietnamPro(
                fontSize: 8,
                color: AdminColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              shift.statusLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 8,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE74C3C)),
            const SizedBox(height: 14),
            Text(
              'Không thể tải lịch phân ca trực',
              style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(_error ?? 'Lỗi kết nối', style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _fetchData,
              style: FilledButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
