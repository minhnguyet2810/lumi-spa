import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_hrm_repository.dart';
import '../../data/models/admin_staff_shift_model.dart';
import '../theme/admin_colors.dart';

class AdminShiftActionDialog extends StatefulWidget {
  final StaffShiftItem shift;
  final VoidCallback? onChanged;

  const AdminShiftActionDialog({
    super.key,
    required this.shift,
    this.onChanged,
  });

  @override
  State<AdminShiftActionDialog> createState() => _AdminShiftActionDialogState();
}

class _AdminShiftActionDialogState extends State<AdminShiftActionDialog> {
  final _leaveReasonController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;
  bool _showLeaveInput = false;

  @override
  void dispose() {
    _leaveReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.checkInShift(widget.shift.id);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chấm công vào ca cho ${widget.shift.staffName}!'),
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

  Future<void> _handleCheckOut() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.checkOutShift(widget.shift.id);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hoàn tất ca trực cho ${widget.shift.staffName}!'),
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

  Future<void> _handleRequestLeave() async {
    final reason = _leaveReasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do xin nghỉ phép.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.requestLeave(shiftId: widget.shift.id, reason: reason);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu xin nghỉ phép đến quản lý!'),
          backgroundColor: Color(0xFFF59E0B),
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

  Future<void> _handleApproveLeave(bool approved) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.approveLeave(shiftId: widget.shift.id, approved: approved);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Đã phê duyệt nghỉ phép!' : 'Đã từ chối đơn xin nghỉ phép.'),
          backgroundColor: approved ? const Color(0xFFE74C3C) : const Color(0xFF38BDF8),
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

  Future<void> _handleDeleteShift() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.deepTeal,
        title: Text('Xác nhận xóa ca trực?', style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Ca trực này sẽ bị xóa khỏi bảng lịch làm việc.', style: GoogleFonts.beVietnamPro(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white60)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
            child: const Text('XÓA CA'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminHrmRepository.instance.deleteShift(widget.shift.id);
      if (!mounted) return;
      widget.onChanged?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa ca trực thành công!'),
          backgroundColor: Color(0xFFE74C3C),
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
    final shift = widget.shift;
    final statusColor = shift.statusColor;

    return Dialog(
      backgroundColor: AdminColors.deepTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF165B52), width: 1.2),
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
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.staffName,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${shift.shiftTypeLabel} • ${shift.timeRange}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AdminColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      shift.statusLabel,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Shift Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminColors.slateTeal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E6B60)),
                ),
                child: Column(
                  children: [
                    _infoRow('Ngày làm việc', shift.date),
                    const Divider(color: Color(0xFF1E6B60), height: 14),
                    _infoRow('Khung giờ chuẩn', shift.timeRange),
                    if (shift.actualCheckIn != null) ...[
                      const Divider(color: Color(0xFF1E6B60), height: 14),
                      _infoRow(
                        'Thời gian Check-in',
                        '${shift.actualCheckIn!.hour.toString().padLeft(2, '0')}:${shift.actualCheckIn!.minute.toString().padLeft(2, '0')} (${shift.actualCheckIn!.day}/${shift.actualCheckIn!.month})',
                        valueColor: const Color(0xFF1ABC9C),
                      ),
                    ],
                    if (shift.actualCheckOut != null) ...[
                      const Divider(color: Color(0xFF1E6B60), height: 14),
                      _infoRow(
                        'Thời gian Check-out',
                        '${shift.actualCheckOut!.hour.toString().padLeft(2, '0')}:${shift.actualCheckOut!.minute.toString().padLeft(2, '0')} (${shift.actualCheckOut!.day}/${shift.actualCheckOut!.month})',
                        valueColor: const Color(0xFF1ABC9C),
                      ),
                    ],
                    if (shift.notes.isNotEmpty) ...[
                      const Divider(color: Color(0xFF1E6B60), height: 14),
                      _infoRow('Ghi chú ca trực', shift.notes),
                    ],
                    if (shift.leaveReason != null && shift.leaveReason!.isNotEmpty) ...[
                      const Divider(color: Color(0xFF1E6B60), height: 14),
                      _infoRow('Lý do xin nghỉ', shift.leaveReason!, valueColor: const Color(0xFFF59E0B)),
                    ],
                  ],
                ),
              ),

              // Leave Input Form (if toggled)
              if (_showLeaveInput) ...[
                const SizedBox(height: 14),
                Text(
                  'Nhập lý do xin nghỉ phép:',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _leaveReasonController,
                  maxLines: 2,
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'VD: Việc gia đình, lý do sức khỏe...',
                    hintStyle: GoogleFonts.beVietnamPro(color: Colors.white38),
                    filled: true,
                    fillColor: AdminColors.slateTeal,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1E6B60)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _showLeaveInput = false),
                      child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white60)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submitting ? null : _handleRequestLeave,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                      child: const Text('GỬI ĐƠN NGHỈ'),
                    ),
                  ],
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
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

              const SizedBox(height: 20),

              // Action Buttons Bar
              if (!_showLeaveInput)
                Column(
                  children: [
                    // Main Attendance Actions (Check-in / Check-out)
                    Row(
                      children: [
                        if (shift.isScheduled)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _handleCheckIn,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1ABC9C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 16),
                              label: Text('CHẤM CÔNG VÀO CA', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ),
                        if (shift.isCheckedIn)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _handleCheckOut,
                              style: FilledButton.styleFrom(
                                backgroundColor: AdminColors.gold,
                                foregroundColor: const Color(0xFF08201D),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 16),
                              label: Text('KẾT THÚC CA TRỰC', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),

                    // Leave Approval Actions (if leave requested)
                    if (shift.isLeaveRequested) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : () => _handleApproveLeave(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE74C3C),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: Text('DUYỆT NGHỈ PHÉP', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : () => _handleApproveLeave(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: Text('TỪ CHỐI NGHỈ', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Secondary Actions: Xin nghỉ / Hủy ca
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (shift.isScheduled)
                          TextButton.icon(
                            onPressed: () => setState(() => _showLeaveInput = true),
                            icon: const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFFF59E0B)),
                            label: Text('Xin nghỉ phép', style: GoogleFonts.beVietnamPro(color: const Color(0xFFF59E0B), fontSize: 12)),
                          )
                        else
                          const SizedBox.shrink(),
                        TextButton.icon(
                          onPressed: _submitting ? null : _handleDeleteShift,
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE74C3C)),
                          label: Text('Xóa ca trực', style: GoogleFonts.beVietnamPro(color: const Color(0xFFE74C3C), fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60)),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
