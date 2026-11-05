import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../theme/admin_colors.dart';

class AdminEditCustomerDialog extends StatefulWidget {
  final String customerId;
  final String initialName;
  final String initialPhone;
  final String initialEmail;
  final String initialAddress;
  final String initialNotes;
  final VoidCallback? onUpdated;

  const AdminEditCustomerDialog({
    super.key,
    required this.customerId,
    this.initialName = '',
    this.initialPhone = '',
    this.initialEmail = '',
    this.initialAddress = '',
    this.initialNotes = '',
    this.onUpdated,
  });

  @override
  State<AdminEditCustomerDialog> createState() => _AdminEditCustomerDialogState();
}

class _AdminEditCustomerDialogState extends State<AdminEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _addressController = TextEditingController(text: widget.initialAddress);
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminCrmRepository.instance.updateCustomerProfile(
        customerId: widget.customerId,
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      widget.onUpdated?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ khách hàng thành công! ✨'),
          backgroundColor: AdminColors.emerald,
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
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminColors.peach,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AdminColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHỈNH SỬA HỒ SƠ KHÁCH HÀNG',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cập nhật thông tin liên lạc, địa chỉ và ghi chú nội bộ',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AdminColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AdminColors.border, height: 1),
                const SizedBox(height: 20),

                // Error alert if present
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Họ và tên
                _buildLabel('Họ và tên khách hàng *'),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                  decoration: _inputDecoration(
                    hint: 'Ví dụ: Nguyễn Thị Mai',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên khách hàng.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 2. Số điện thoại & Email (2 Cột)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Số điện thoại *'),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                            decoration: _inputDecoration(
                              hint: 'Ví dụ: 0901234567',
                              icon: Icons.phone_outlined,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Vui lòng nhập số điện thoại.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                            decoration: _inputDecoration(
                              hint: 'Ví dụ: mai.nguyen@gmail.com',
                              icon: Icons.email_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Địa chỉ nhận hàng / liên hệ
                _buildLabel('Địa chỉ liên lạc / nhận hàng'),
                TextFormField(
                  controller: _addressController,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                  decoration: _inputDecoration(
                    hint: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành...',
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Ghi chú nội bộ quản trị
                _buildLabel('Ghi chú quản lý khách hàng'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ghi chú về thói quen, dịch vụ yêu thích, yêu cầu đặc biệt của khách...',
                    hintStyle: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textMuted),
                    filled: true,
                    fillColor: AdminColors.elevatedSurface,
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
                      borderSide: const BorderSide(color: AdminColors.primary, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: Text(
                        'HỦY',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        _submitting ? 'ĐANG LƯU...' : 'LƯU HỒ SƠ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textMuted),
      prefixIcon: Icon(icon, color: AdminColors.textSecondary, size: 18),
      filled: true,
      fillColor: AdminColors.elevatedSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
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
        borderSide: const BorderSide(color: AdminColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}

