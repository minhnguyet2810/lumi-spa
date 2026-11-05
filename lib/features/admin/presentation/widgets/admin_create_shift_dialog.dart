import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_hrm_repository.dart';
import '../../data/models/admin_staff_shift_model.dart';
import '../theme/admin_colors.dart';

class AdminCreateShiftDialog extends StatefulWidget {
  final List<StaffMemberItem> staffList;
  final String? initialDate;
  final String? initialStaffId;
  final VoidCallback? onCreated;

  const AdminCreateShiftDialog({
    super.key,
    required this.staffList,
    this.initialDate,
    this.initialStaffId,
    this.onCreated,
  });

  @override
  State<AdminCreateShiftDialog> createState() => _AdminCreateShiftDialogState();
}

class _AdminCreateShiftDialogState extends State<AdminCreateShiftDialog> {
  String? _selectedStaffId;
  late DateTime _selectedDate;
  String _selectedShiftType = 'morning';
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  final Map<String, ({String label, String timeRange, Color color})> _shiftOptions = {
    'morning': (label: 'Ca Sáng', timeRange: '08:30 - 14:30', color: const Color(0xFF38BDF8)),
    'afternoon': (label: 'Ca Chiều', timeRange: '13:30 - 19:30', color: const Color(0xFFF59E0B)),
    'full': (label: 'Cả Ngày (Hành chính)', timeRange: '09:00 - 18:00', color: const Color(0xFF2ECC71)),
  };

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.initialStaffId ??
        (widget.staffList.isNotEmpty ? widget.staffList.first.id : null);

    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _handleSubmit() async {
    if (_selectedStaffId == null) {
      setState(() => _errorMessage = 'Vui lòng chọn nhân viên.');
      return;
    }

    final staff = widget.staffList.firstWhere(
      (s) => s.id == _selectedStaffId,
      orElse: () => StaffMemberItem(id: _selectedStaffId!, staffId: _selectedStaffId!, name: 'Nhân viên'),
    );

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.createShift(
        staffId: staff.id,
        staffName: staff.name,
        role: staff.role,
        branchId: staff.branchId,
        date: _formatDate(_selectedDate),
        shiftType: _selectedShiftType,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      widget.onCreated?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xếp ca ${_shiftOptions[_selectedShiftType]?.label} cho ${staff.name} thành công!'),
          backgroundColor: const Color(0xFF1ABC9C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('StateError: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.more_time_rounded,
                      color: AdminColors.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XẾP CA LÀM VIỆC MỚI',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Phân bổ ca trực nhân sự chi nhánh',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AdminColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Chọn nhân viên
              Text(
                '1. Chọn nhân sự làm việc',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AdminColors.slateTeal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStaffId,
                    isExpanded: true,
                    dropdownColor: AdminColors.sidebarBackground,
                    style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                    items: widget.staffList.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: s.roleColor.withValues(alpha: 0.2),
                              child: Text(
                                s.initials,
                                style: TextStyle(color: s.roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text('(${s.roleLabel})', style: const TextStyle(color: AdminColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStaffId = val),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Chọn ngày làm việc
              Text(
                '2. Ngày làm việc',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AdminColors.gold,
                            surface: AdminColors.cardSurface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AdminColors.slateTeal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AdminColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Chọn loại ca
              Text(
                '3. Loại ca trực',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: _shiftOptions.entries.map((entry) {
                  final key = entry.key;
                  final info = entry.value;
                  final isSelected = _selectedShiftType == key;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedShiftType = key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? info.color.withValues(alpha: 0.2)
                              : AdminColors.slateTeal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? info.color : AdminColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? info.color : AdminColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              info.label,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminColors.sidebarBackground,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                info.timeRange,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: info.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 4. Ghi chú
              Text(
                '4. Ghi chú ca trực (Không bắt buộc)',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú hoặc yêu cầu bàn giao ca...',
                  hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted),
                  filled: true,
                  fillColor: AdminColors.slateTeal,
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

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE74C3C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE74C3C), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFFE74C3C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _submitting ? 'ĐANG LƯU...' : 'XÁC NHẬN XẾP CA',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
