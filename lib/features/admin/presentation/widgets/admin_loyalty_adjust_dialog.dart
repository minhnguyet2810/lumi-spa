import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../../data/models/customer_360_model.dart';
import '../theme/admin_colors.dart';

class AdminLoyaltyAdjustDialog extends StatefulWidget {
  final CustomerListItem customer;
  final VoidCallback? onAdjusted;

  const AdminLoyaltyAdjustDialog({
    super.key,
    required this.customer,
    this.onAdjusted,
  });

  @override
  State<AdminLoyaltyAdjustDialog> createState() => _AdminLoyaltyAdjustDialogState();
}

class _AdminLoyaltyAdjustDialogState extends State<AdminLoyaltyAdjustDialog> {
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isDeduction = false;
  String _selectedTier = '';
  bool _submitting = false;
  String? _errorMessage;

  final List<String> _quickReasons = [
    'Đền bù trải nghiệm dịch vụ',
    'Tặng điểm sinh nhật tri ân',
    'Khuyến mãi chiến dịch VIP',
    'Điều chỉnh số dư thủ công',
    'Khắc phục sai lệch hệ thống',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.customer.tier.toLowerCase();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final rawPoints = int.tryParse(_pointsController.text.trim()) ?? 0;
    final pointsDelta = _isDeduction ? -rawPoints : rawPoints;
    final reason = _reasonController.text.trim();
    final tierChanged = _selectedTier != widget.customer.tier.toLowerCase();

    if (pointsDelta == 0 && !tierChanged) {
      setState(() {
        _errorMessage = 'Vui lòng nhập số điểm thay đổi hoặc chọn thứ hạng mới.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminCrmRepository.instance.adjustLoyalty(
        customerId: widget.customer.id,
        pointsDelta: pointsDelta,
        newTier: tierChanged ? _selectedTier : null,
        reason: reason.isNotEmpty ? reason : 'Quản trị viên điều chỉnh',
      );

      if (!mounted) return;
      widget.onAdjusted?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật điểm và hạng thành viên thành công!'),
          backgroundColor: Color(0xFF1ABC9C),
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
    final currentPoints = widget.customer.points;
    final delta = int.tryParse(_pointsController.text.trim()) ?? 0;
    final projectedPoints = _isDeduction
        ? (currentPoints - delta).clamp(0, 99999999)
        : (currentPoints + delta);

    return Dialog(
      backgroundColor: AdminColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      gradient: const LinearGradient(
                        colors: [AdminColors.gold, Color(0xFFB38F26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐIỀU CHỈNH LOYALTY & HẠNG',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${widget.customer.displayName} • ${widget.customer.phone}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AdminColors.gold,
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

              // Preview Current vs Projected Points
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminColors.slateTeal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm hiện tại',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$currentPoints điểm',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AdminColors.gold),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Sau điều chỉnh',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AdminColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$projectedPoints điểm',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mode: Cộng điểm (+) vs Trừ điểm (-)
              Text(
                'Thao tác điểm tích lũy',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isDeduction = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isDeduction
                              ? const Color(0xFF1ABC9C).withValues(alpha: 0.25)
                              : AdminColors.sidebarBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_isDeduction
                                ? const Color(0xFF1ABC9C)
                                : AdminColors.border,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded,
                                color: Color(0xFF1ABC9C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Cộng điểm (+)',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: !_isDeduction
                                    ? const Color(0xFF1ABC9C)
                                    : AdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isDeduction = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isDeduction
                              ? const Color(0xFFE74C3C).withValues(alpha: 0.25)
                              : AdminColors.sidebarBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isDeduction
                                ? const Color(0xFFE74C3C)
                                : AdminColors.border,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.remove_circle_outline_rounded,
                                color: Color(0xFFE74C3C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Trừ điểm (-)',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isDeduction
                                    ? const Color(0xFFE74C3C)
                                    : AdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Input Số điểm
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 15),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Nhập số điểm cần điều chỉnh...',
                  hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted),
                  filled: true,
                  fillColor: AdminColors.slateTeal,
                  prefixIcon: Icon(
                    _isDeduction ? Icons.remove_rounded : Icons.add_rounded,
                    color: _isDeduction ? const Color(0xFFE74C3C) : const Color(0xFF1ABC9C),
                  ),
                  suffixText: 'điểm',
                  suffixStyle: GoogleFonts.beVietnamPro(color: AdminColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AdminColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AdminColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AdminColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Lựa chọn Thăng / Hạ hạng trực tiếp
              Text(
                'Thứ hạng thành viên',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tierChip('bronze', 'Đồng', const Color(0xFFC5A880)),
                  _tierChip('silver', 'Bạc', const Color(0xFF94A3B8)),
                  _tierChip('gold', 'Vàng', const Color(0xFFF59E0B)),
                  _tierChip('diamond', 'Kim Cương', const Color(0xFF38BDF8)),
                ],
              ),
              const SizedBox(height: 18),

              // Lý do điều chỉnh & Quick chips
              Text(
                'Lý do điều chỉnh (Audit Log)',
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
                children: _quickReasons.map((r) {
                  final isSelected = _reasonController.text == r;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _reasonController.text = r;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AdminColors.gold.withValues(alpha: 0.2)
                            : AdminColors.sidebarBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AdminColors.gold : AdminColors.border,
                        ),
                      ),
                      child: Text(
                        r,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: isSelected ? AdminColors.gold : AdminColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập chi tiết lý do phục vụ kiểm toán hệ thống...',
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
                      backgroundColor: AdminColors.gold,
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
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _submitting ? 'ĐANG LƯU...' : 'XÁC NHẬN ĐIỀU CHỈNH',
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

  Widget _tierChip(String tierKey, String label, Color color) {
    final isSelected = _selectedTier == tierKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedTier = tierKey);
      },
      selectedColor: color.withValues(alpha: 0.3),
      backgroundColor: AdminColors.sidebarBackground,
      labelStyle: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? color : AdminColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? color : AdminColors.border,
        width: isSelected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

