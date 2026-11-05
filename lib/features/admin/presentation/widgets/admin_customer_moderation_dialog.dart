import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../../data/models/customer_360_model.dart';
import '../theme/admin_colors.dart';

class AdminCustomerModerationDialog extends StatefulWidget {
  final CustomerListItem customer;
  final VoidCallback? onModerated;

  const AdminCustomerModerationDialog({
    super.key,
    required this.customer,
    this.onModerated,
  });

  @override
  State<AdminCustomerModerationDialog> createState() => _AdminCustomerModerationDialogState();
}

class _AdminCustomerModerationDialogState extends State<AdminCustomerModerationDialog> {
  final _reasonController = TextEditingController();
  late String _targetStatus;
  bool _submitting = false;
  String? _errorMessage;

  final List<String> _commonSuspendReasons = [
    'Hủy lịch hẹn liên tiếp > 3 lần (No-show)',
    'Nghi vấn gian lận tích lũy điểm thưởng',
    'Giao dịch không hợp lệ hoặc bom hàng',
    'Yêu cầu tạm khóa từ phía khách hàng',
    'Tài khoản có dấu hiệu bị xâm phạm',
  ];

  @override
  void initState() {
    super.initState();
    _targetStatus = widget.customer.isActive ? 'suspended' : 'active';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final reason = _reasonController.text.trim();
    if (_targetStatus == 'suspended' && reason.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập lý do tạm khóa tài khoản để lưu vết kiểm toán.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminCrmRepository.instance.moderateCustomer(
        customerId: widget.customer.id,
        status: _targetStatus,
        reason: reason,
      );

      if (!mounted) return;
      widget.onModerated?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _targetStatus == 'suspended'
                ? 'Đã tạm khóa tài khoản khách hàng.'
                : 'Đã kích hoạt lại tài khoản khách hàng thành công.',
          ),
          backgroundColor: _targetStatus == 'suspended'
              ? const Color(0xFFE74C3C)
              : const Color(0xFF1ABC9C),
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
    final isSuspending = _targetStatus == 'suspended';

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
                      color: isSuspending
                          ? const Color(0xFFE74C3C).withValues(alpha: 0.2)
                          : const Color(0xFF1ABC9C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSuspending
                          ? Icons.lock_person_rounded
                          : Icons.lock_open_rounded,
                      color: isSuspending
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF1ABC9C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuspending
                              ? 'TẠM KHÓA TÀI KHOẢN'
                              : 'MỞ KHÓA TÀI KHOẢN',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          widget.customer.displayName,
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
              const SizedBox(height: 18),

              // Alert Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSuspending
                      ? const Color(0xFFE74C3C).withValues(alpha: 0.12)
                      : const Color(0xFF1ABC9C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSuspending
                        ? const Color(0xFFE74C3C).withValues(alpha: 0.4)
                        : const Color(0xFF1ABC9C).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSuspending
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: isSuspending
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF1ABC9C),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSuspending
                            ? 'Khách hàng sẽ không thể đặt lịch hẹn spa, mua hàng qua ứng dụng hoặc sử dụng voucher cho đến khi được mở khóa.'
                            : 'Tài khoản sẽ được khôi phục toàn bộ quyền đặt lịch, mua hàng và tích lũy điểm thưởng bình thường.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AdminColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (isSuspending) ...[
                Text(
                  'Lý do tạm khóa (Audit Trail)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonSuspendReasons.map((r) {
                    final isSelected = _reasonController.text == r;
                    return InkWell(
                      onTap: () => setState(() => _reasonController.text = r),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE74C3C).withValues(alpha: 0.25)
                              : AdminColors.sidebarBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE74C3C)
                                : AdminColors.border,
                          ),
                        ),
                        child: Text(
                          r,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: isSelected
                                ? const Color(0xFFE74C3C)
                                : AdminColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú chi tiết lý do phục vụ quản lý...',
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
              ] else if (widget.customer.suspendedReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.slateTeal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lý do bị khóa trước đây:',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AdminColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customer.suspendedReason!,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: const Color(0xFFE74C3C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFE74C3C), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: const Color(0xFFE74C3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'HỦY',
                      style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: isSuspending
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF1ABC9C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isSuspending
                                ? Icons.lock_person_rounded
                                : Icons.lock_open_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _submitting
                          ? 'ĐANG XỬ LÝ...'
                          : isSuspending
                              ? 'XÁC NHẬN KHÓA'
                              : 'XÁC NHẬN MỞ KHÓA',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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

