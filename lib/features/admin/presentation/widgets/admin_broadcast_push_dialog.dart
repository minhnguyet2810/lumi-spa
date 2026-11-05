import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/admin_colors.dart';
import '../../data/models/admin_voucher_model.dart';
import '../../data/admin_marketing_repository.dart';

class AdminBroadcastPushDialog extends StatefulWidget {
  final List<AdminVoucherItem> availableVouchers;

  const AdminBroadcastPushDialog({
    super.key,
    this.availableVouchers = const [],
  });

  static Future<bool?> show(BuildContext context, {List<AdminVoucherItem> availableVouchers = const []}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminBroadcastPushDialog(availableVouchers: availableVouchers),
    );
  }

  @override
  State<AdminBroadcastPushDialog> createState() => _AdminBroadcastPushDialogState();
}

class _AdminBroadcastPushDialogState extends State<AdminBroadcastPushDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _campaignNameCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;

  String _segment = 'all'; // 'all', 'vip', 'inactive_60d', 'new_customers'
  String? _selectedVoucherCode;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _campaignNameCtrl = TextEditingController(text: 'Flash Sale Cuối Tuần');
    _titleCtrl = TextEditingController(text: '✨ Ưu Đãi Đặc Quyền Dành Riêng Cho Nàng!');
    _bodyCtrl = TextEditingController(text: 'Nhận ngay Voucher giảm giá độc quyền cho liệu trình chăm sóc da thư giãn cuối tuần tại LUMI SPA.');
    if (widget.availableVouchers.isNotEmpty) {
      _selectedVoucherCode = widget.availableVouchers.first.code;
    }
  }

  @override
  void dispose() {
    _campaignNameCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String _getAudienceCountEstimate() {
    switch (_segment) {
      case 'vip':
        return '~ 48 Hội viên Gold & Diamond';
      case 'inactive_60d':
        return '~ 115 Khách hàng ngủ quên';
      case 'new_customers':
        return '~ 62 Thành viên mới gia nhập';
      default:
        return '~ 540 Khách hàng toàn hệ thống';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final res = await AdminMarketingRepository.instance.broadcastCampaign(
        campaignName: _campaignNameCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        segment: _segment,
        voucherCode: _selectedVoucherCode,
      );

      if (mounted) {
        if (res['success'] == true) {
          final count = res['campaign']?['successCount'] ?? res['campaign']?['totalTargetUsers'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi thông báo thành công tới $count khách hàng!'),
              backgroundColor: AdminColors.emerald,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'Lỗi khi gửi thông báo.'),
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
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.deepTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AdminColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
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
                      color: AdminColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: AdminColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chiến Dịch Bắn Thông Báo Marketing & Push',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Gửi thông báo in-app và đẩy FCM tới phân khúc khách hàng mục tiêu',
                          style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textMuted),
                        ),
                      ],
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
                      // Tên chiến dịch
                      _buildTextField(
                        controller: _campaignNameCtrl,
                        label: 'Tên chiến dịch nội bộ (Campaign Name)*',
                        hint: 'VD: Tri ân cuối tuần, Khởi động tháng mới...',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 16),

                      // Chọn phân khúc khách hàng
                      Text(
                        'Phân khúc khách hàng nhận thông báo*',
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
                            value: _segment,
                            isExpanded: true,
                            dropdownColor: AdminColors.cardSurface,
                            style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Tất cả khách hàng (Toàn hệ thống)')),
                              DropdownMenuItem(value: 'vip', child: Text('Hội viên VIP (Hạng Gold & Diamond)')),
                              DropdownMenuItem(value: 'inactive_60d', child: Text('Khách hàng ngủ quên (> 60 ngày chưa quay lại)')),
                              DropdownMenuItem(value: 'new_customers', child: Text('Khách mới gia nhập (< 30 ngày)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _segment = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dự kiến tiếp cận: ${_getAudienceCountEstimate()}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AdminColors.goldAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tiêu đề Push
                      _buildTextField(
                        controller: _titleCtrl,
                        label: 'Tiêu đề thông báo hiển thị trên máy khách*',
                        hint: 'VD: Quà tặng 100k cho nàng làm đẹp hôm nay!',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Nội dung Push
                      _buildTextField(
                        controller: _bodyCtrl,
                        label: 'Nội dung thông báo (Body)*',
                        hint: 'VD: Nhập mã LUMISPA để nhận ngay ưu đãi chăm sóc da...',
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Đính kèm Voucher
                      Text(
                        'Đính kèm Voucher ưu đãi',
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
                          child: DropdownButton<String?>(
                            value: _selectedVoucherCode,
                            isExpanded: true,
                            dropdownColor: AdminColors.cardSurface,
                            style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 14),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Không đính kèm voucher'),
                              ),
                              ...widget.availableVouchers.map((v) => DropdownMenuItem<String?>(
                                    value: v.code,
                                    child: Text('[${v.code}] ${v.title} (${v.badgeText})'),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedVoucherCode = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Khung Xem Trước (Mobile Push Preview)
                      Text(
                        'Xem trước hiển thị trên thiết bị khách hàng (Push Preview)',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E242B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AdminColors.goldAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Center(
                                    child: Text('L', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LUMI SPA & CLINIC',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'vừa xong',
                                  style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.white38),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Tiêu đề thông báo...',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bodyCtrl.text.isNotEmpty ? _bodyCtrl.text : 'Nội dung thông báo đẩy đến điện thoại...',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                            if (_selectedVoucherCode != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AdminColors.goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AdminColors.goldAccent.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.confirmation_number_rounded, size: 14, color: AdminColors.goldAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mã ưu đãi: $_selectedVoucherCode',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
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
                    onPressed: _isSending ? null : _submit,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Bắn Thông Báo Ngay',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
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
          onChanged: onChanged,
          style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: AdminColors.cardSurface,
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
}
