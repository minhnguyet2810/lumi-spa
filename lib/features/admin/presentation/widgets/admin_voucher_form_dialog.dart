import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/admin_colors.dart';
import '../../data/models/admin_voucher_model.dart';
import '../../data/admin_marketing_repository.dart';

class AdminVoucherFormDialog extends StatefulWidget {
  final AdminVoucherItem? initialVoucher;

  const AdminVoucherFormDialog({
    super.key,
    this.initialVoucher,
  });

  static Future<bool?> show(BuildContext context, {AdminVoucherItem? initialVoucher}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminVoucherFormDialog(initialVoucher: initialVoucher),
    );
  }

  @override
  State<AdminVoucherFormDialog> createState() => _AdminVoucherFormDialogState();
}

class _AdminVoucherFormDialogState extends State<AdminVoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _discountValCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _usageLimitCtrl;
  late TextEditingController _badgeTextCtrl;

  String _discountType = 'percent'; // 'percent', 'fixed', 'free_shipping'
  String _targetAudience = 'all'; // 'all', 'vip', 'new_customers', 'inactive_60d'
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validTo;

  bool _isSubmitting = false;

  bool get isEditing => widget.initialVoucher != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVoucher;
    _codeCtrl = TextEditingController(text: v?.code ?? '');
    _titleCtrl = TextEditingController(text: v?.title ?? '');
    _descCtrl = TextEditingController(text: v?.description ?? '');

    if (v != null) {
      if (v.isFreeShipping) {
        _discountType = 'free_shipping';
        _discountValCtrl = TextEditingController(text: '${v.fixedDiscount ?? 30000}');
      } else if (v.percentDiscount != null) {
        _discountType = 'percent';
        _discountValCtrl = TextEditingController(text: '${(v.percentDiscount! * 100).toInt()}');
      } else {
        _discountType = 'fixed';
        _discountValCtrl = TextEditingController(text: '${v.fixedDiscount ?? 50000}');
      }
      _maxDiscountCtrl = TextEditingController(text: v.maxDiscount != null ? '${v.maxDiscount}' : '');
      _minOrderCtrl = TextEditingController(text: '${v.minOrder}');
      _usageLimitCtrl = TextEditingController(text: '${v.usageLimit}');
      _badgeTextCtrl = TextEditingController(text: v.badgeText);
      _targetAudience = v.targetAudience;
      _isActive = v.isActive;

      if (v.validFrom != null && v.validFrom!.isNotEmpty) {
        try {
          _validFrom = DateTime.parse(v.validFrom!);
        } catch (_) {}
      }
      if (v.validTo != null && v.validTo!.isNotEmpty) {
        try {
          _validTo = DateTime.parse(v.validTo!);
        } catch (_) {}
      }
    } else {
      _discountValCtrl = TextEditingController(text: '15');
      _maxDiscountCtrl = TextEditingController(text: '100000');
      _minOrderCtrl = TextEditingController(text: '300000');
      _usageLimitCtrl = TextEditingController(text: '100');
      _badgeTextCtrl = TextEditingController(text: 'GIẢM 15%');
      _validFrom = DateTime.now();
      _validTo = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _discountValCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _minOrderCtrl.dispose();
    _usageLimitCtrl.dispose();
    _badgeTextCtrl.dispose();
    super.dispose();
  }

  void _onDiscountTypeChanged(String newType) {
    setState(() {
      _discountType = newType;
      if (newType == 'percent') {
        _discountValCtrl.text = '15';
        _maxDiscountCtrl.text = '100000';
        _badgeTextCtrl.text = 'GIẢM 15%';
      } else if (newType == 'fixed') {
        _discountValCtrl.text = '50000';
        _maxDiscountCtrl.clear();
        _badgeTextCtrl.text = 'GIẢM 50K';
      } else if (newType == 'free_shipping') {
        _discountValCtrl.text = '30000';
        _maxDiscountCtrl.text = '30000';
        _badgeTextCtrl.text = 'FREESHIP';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      final minOrder = int.tryParse(_minOrderCtrl.text.trim()) ?? 0;
      final usageLimit = int.tryParse(_usageLimitCtrl.text.trim()) ?? 100;
      final badgeText = _badgeTextCtrl.text.trim().isNotEmpty ? _badgeTextCtrl.text.trim() : 'ƯU ĐÃI';

      double? percentDiscount;
      int? fixedDiscount;
      int? maxDiscount;
      bool isFreeShipping = false;

      if (_discountType == 'percent') {
        final pct = double.tryParse(_discountValCtrl.text.trim()) ?? 0;
        percentDiscount = pct > 1 ? pct / 100 : pct;
        maxDiscount = int.tryParse(_maxDiscountCtrl.text.trim());
      } else if (_discountType == 'free_shipping') {
        isFreeShipping = true;
        fixedDiscount = int.tryParse(_discountValCtrl.text.trim()) ?? 30000;
        maxDiscount = fixedDiscount;
      } else {
        fixedDiscount = int.tryParse(_discountValCtrl.text.trim()) ?? 0;
        maxDiscount = fixedDiscount;
      }

      final voucher = AdminVoucherItem(
        id: widget.initialVoucher?.id ?? code,
        code: code,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        minOrder: minOrder,
        percentDiscount: percentDiscount,
        fixedDiscount: fixedDiscount,
        maxDiscount: maxDiscount,
        isFreeShipping: isFreeShipping,
        badgeText: badgeText,
        usageLimit: usageLimit,
        usedCount: widget.initialVoucher?.usedCount ?? 0,
        discountAmountSponsored: widget.initialVoucher?.discountAmountSponsored ?? 0,
        validFrom: _validFrom?.toIso8601String(),
        validTo: _validTo?.toIso8601String(),
        isActive: _isActive,
        targetAudience: _targetAudience,
      );

      final success = await AdminMarketingRepository.instance.saveVoucher(voucher, discountType: _discountType);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Cập nhật voucher thành công!' : 'Tạo mới voucher thành công!'),
              backgroundColor: AdminColors.emerald,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu voucher. Vui lòng kiểm tra lại.'),
              backgroundColor: AdminColors.statusCancelled,
            ),
          );
        }
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $err'),
            backgroundColor: AdminColors.statusCancelled,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      backgroundColor: AdminColors.deepTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 740),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.confirmation_number_rounded, color: AdminColors.goldAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isEditing ? 'Cấu Hình Voucher: ${_codeCtrl.text}' : 'Tạo Mã Voucher Khuyến Mãi Mới',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AdminColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mã Voucher & Badge Text
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _codeCtrl,
                              label: 'Mã Voucher (Code)*',
                              hint: 'VD: LUMIHER2026',
                              readOnly: isEditing,
                              textCapitalization: TextCapitalization.characters,
                              validator: (val) {
                                if (val == null || val.trim().length < 3) {
                                  return 'Ít nhất 3 ký tự';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _badgeTextCtrl,
                              label: 'Nhãn Badge',
                              hint: 'VD: HOT DEAL',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tiêu đề khuyến mãi
                      _buildTextField(
                        controller: _titleCtrl,
                        label: 'Tiêu đề khuyến mãi*',
                        hint: 'VD: Giảm ngay 15% mừng mùa lễ hội',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề khuyến mãi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mô tả
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Mô tả chi tiết điều kiện áp dụng',
                        hint: 'VD: Áp dụng cho đơn hàng mỹ phẩm từ 300.000đ...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 18),

                      // Chọn loại ưu đãi
                      Text(
                        'Loại hình chiết khấu*',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTypeRadio('percent', 'Giảm theo %', Icons.percent_rounded),
                          const SizedBox(width: 12),
                          _buildTypeRadio('fixed', 'Giảm tiền mặt', Icons.attach_money_rounded),
                          const SizedBox(width: 12),
                          _buildTypeRadio('free_shipping', 'Miễn phí Ship', Icons.local_shipping_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mức giảm & Giảm tối đa
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _discountValCtrl,
                              label: _discountType == 'percent'
                                  ? 'Tỷ lệ giảm (%)*'
                                  : 'Mức tiền giảm (VNĐ)*',
                              hint: _discountType == 'percent' ? '15' : '50000',
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                                final n = num.tryParse(val.trim());
                                if (n == null || n <= 0) return 'Giá trị > 0';
                                if (_discountType == 'percent' && n > 100) return 'Tối đa 100%';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxDiscountCtrl,
                              label: 'Giảm tối đa (VNĐ)',
                              hint: 'Để trống nếu không giới hạn',
                              keyboardType: TextInputType.number,
                              enabled: _discountType == 'percent',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Đơn tối thiểu & Giới hạn số lượt
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _minOrderCtrl,
                              label: 'Đơn hàng tối thiểu (VNĐ)',
                              hint: '0',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _usageLimitCtrl,
                              label: 'Giới hạn số lượt sử dụng*',
                              hint: '100',
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                                final n = int.tryParse(val.trim());
                                if (n == null || n <= 0) return 'Tối thiểu 1';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Đối tượng áp dụng
                      Text(
                        'Phân khúc khách hàng áp dụng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AdminColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _targetAudience,
                            isExpanded: true,
                            dropdownColor: AdminColors.cardSurface,
                            style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả khách hàng (Toàn bộ)')),
                              DropdownMenuItem(value: 'vip', child: Text('Hội viên VIP (Gold & Diamond)')),
                              DropdownMenuItem(value: 'new_customers', child: Text('Thành viên mới đăng ký (< 30 ngày)')),
                              DropdownMenuItem(value: 'inactive_60d', child: Text('Khách hàng ngủ quên (> 60 ngày chưa giao dịch)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _targetAudience = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thời hạn hiệu lực
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTile(
                              label: 'Ngày bắt đầu',
                              date: _validFrom,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _validFrom ?? DateTime.now(),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _validFrom = d);
                              },
                              format: dateFormat,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateTile(
                              label: 'Ngày kết thúc (HSD)',
                              date: _validTo,
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _validTo ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _validTo = d);
                              },
                              format: dateFormat,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Switch Kích hoạt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kích hoạt Voucher ngay',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Khách hàng có thể nhìn thấy và áp dụng mã khi thanh toán',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: AdminColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              activeThumbColor: AdminColors.goldAccent,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.textSecondary,
                      side: const BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Hủy', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      isEditing ? 'Lưu Thay Đổi' : 'Tạo Voucher',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.goldAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeRadio(String value, String title, IconData icon) {
    final isSelected = _discountType == value;
    return Expanded(
      child: InkWell(
        onTap: () => _onDiscountTypeChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.goldAccent.withValues(alpha: 0.15) : AdminColors.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AdminColors.goldAccent : AdminColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AdminColors.goldAccent : AdminColors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AdminColors.goldAccent : AdminColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AdminColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          enabled: enabled,
          style: GoogleFonts.beVietnamPro(
            color: enabled ? AdminColors.textPrimary : AdminColors.textMuted,
            fontSize: 14,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: enabled ? AdminColors.cardSurface : AdminColors.deepTeal.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.goldAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AdminColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AdminColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? format.format(date) : 'Chọn ngày',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: date != null ? AdminColors.textPrimary : AdminColors.textMuted,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, size: 16, color: AdminColors.goldAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
